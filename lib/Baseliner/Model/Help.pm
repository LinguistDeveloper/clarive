package Baseliner::Model::Help;
use Moose;

use Try::Tiny;
use YAML::XS qw(Load);
use Text::Markdown 'markdown';
use HTML::Strip;
use Baseliner::Utils qw(_array _throw _loc _fail _dir _file);

sub docs_dirs {
    my $self = shift;
    my ($user_lang) = @_;

    $user_lang //= 'en';

    my @feature_dirs = grep { -d } map { _dir( $_->path, 'docs/' . $user_lang ) } _array( Clarive->features->list );
    return Clarive->app->path_to( 'docs/' . $user_lang ), @feature_dirs;
}

sub build_doc_tree {
    my $self = shift;
    my ( $opts, @roots ) = @_;

    my $query = $opts->{query};

    my @tree;
    for my $docs_root (@roots) {
        local $opts->{feature_root} = $docs_root unless $opts->{feature_root};
        my ( @docs, @dirs );
        my %uniq_dirs;
        while ( my $dir_or_file = $docs_root->next ) {
            my $name = $dir_or_file->basename;
            next if $name =~ /^\./;

            my $rel =
              $dir_or_file->relative( $opts->{feature_root} );    # always to main root, be it Clarive's or feature's
            if ( $dir_or_file->is_dir ) {
                my $dir_markdown = $dir_or_file->basename . '.markdown';
                my @children = $self->build_doc_tree( $opts, $dir_or_file );
                if ( $dir_or_file->parent->contains( _file( $dir_or_file->parent, $dir_markdown ) ) ) {
                    my $md_file = _file( $dir_or_file->parent, $dir_markdown );
                    my $data = $self->parse_body( $md_file, $docs_root );
                    my $icon = Util->icon_path( $data->{icon} || '/static/images/icons/catalog-folder.png' );
                    $data->{rel} = "$rel";
                    $uniq_dirs{ $data->{uniq_id} } = 1;
                    push @dirs,
                      {
                        leaf     => \0,
                        expanded => \1,
                        index    => $data->{index},
                        icon     => $icon,
                        data     => { path => "$rel" },
                        children => \@children,
                        text     => $data->{title},
                      };
                }
                else {
                    push @tree,
                      {
                        leaf     => \0,
                        expanded => \1,
                        icon     => '/static/images/icons/catalog-folder.png',
                        data     => { path => "$rel" },
                        children => \@children,
                        text     => $name,
                      };
                }
            }
            else {
                my $data = $self->parse_body( $dir_or_file, $docs_root );
                next if exists $uniq_dirs{ $data->{uniq_id} }; ## prevent dir markdown descriptors from showing up twice
                next unless $self->doc_matches( $data, $query );
                $data->{rel} = "$rel";
                push @docs, $data;
            }

        }
        push @tree, $_ for sort { $a->{index} <=> $b->{index} } @dirs;
        for my $doc ( sort { $a->{index} <=> $b->{index} } sort { lc $a->{title} cmp lc $b->{title} } @docs ) {
            my $icon = Util->icon_path( $doc->{icon} || '/static/images/icons/page.png' );
            push @tree,
              {
                leaf           => \1,
                icon           => $icon,
                data           => { path => "" . $doc->{rel} },
                search_results => {
                    found   => $doc->{found},
                    matches => $doc->{matches},
                },
                text => $doc->{title},
              };
        }
    }
    return @tree;
}

sub doc_matches {
    my $self = shift;
    my ( $doc, $query ) = @_;

    return 1 unless defined $query && length $query;

    return if exists $doc->{search} && !$doc->{search};

    my @found;
    my $doc_txt = $doc->{text};
    my $tmatch  = ( $doc->{title} =~ /($query)/gsi );
    while ( $doc_txt =~ /(?<bef>.{0,40})?(?<mat>$query)(?<aft>.{0,40})?/gsi ) {
        my ( $bef, $mat, $aft ) = ( $+{bef}, $+{mat}, $+{aft} );

        $bef =~ s/^\S+\s+(.*)$/$1/g;

        my $t = sprintf '%s<strong>%s</strong>%s', $bef, $mat, $aft;
        push @found, $t;
    }
    if ( $tmatch + @found ) {
        $doc->{found} = join( "...", @found ) . '...';
        $doc->{matches} = $tmatch * 20 + scalar @found;
        return 1;
    }
    return 0;
}

sub parse_body {
    my $self = shift;
    my ( $path, $root ) = @_;

    my ( $id, $type ) = $path->basename =~ /^([^\.]+)(?:\.(\w+))?$/;
    my ($uniq_id) = $path->relative($root) =~ /^([^\.]+)(?:\.(\w+))?$/;
    my $idx = 100;

    # in cache?
    my $cache_key = { d => 'help-doc', path => "$path" };
    if ( my $cached = cache->get($cache_key) ) {
        return $cached;
    }
    $path = _file("$path.markdown") if -d $path;

    # no, so open it
    open my $ff, '<:encoding(utf-8)', "$path"
      or _fail _loc "error opening content: %1 (path=%2): %3", $path->basename, $path, $!;
    my $contents = join '', <$ff>;
    close $ff;

    # parse
    my ( $yaml, $body ) = $contents =~ /(---.+?)---\r?\n(.*)/s;

    # convert
    my $html =
        !defined $type || $type eq 'html' ? $body
      : $type eq 'markdown' ? markdown($body)
      :                       die "File type `$type` (extension) not found!";

    my $data = try {
        YAML::XS::Load($yaml);
    }
    catch {
        my $err = shift;

        _throw _loc 'Help file `%1` header content YAML is invalid: %2', $path, $err;
    };

    $data //= {};

    # strip html, for search, etc.
    my $hs         = HTML::Strip->new();
    my $clean_text = $hs->parse($html);
    utf8::decode($clean_text);

    if ( my $tag_str = delete $data->{tags} ) {
        my @tags = map { s/^\s+//g; s/\s+$//g; { tag => $_, id => ( "$_" =~ s/\s+/-/gr ) } } split /,/, $tag_str;
        $data->{tags} = \@tags;
    }
    else {
        $data->{tags} = [];
    }

    $data = {
        id      => $id,
        uniq_id => $uniq_id,
        name    => $id,
        title   => $id,
        body    => $body,
        yaml    => $yaml,
        text    => $clean_text,
        index   => $idx,
        html    => $html,
        tpl     => ( $type eq 'html' ? 'raw' : 'default' ),
        %$data
    };

    $data->{path} //= '' . $path->relative( Clarive->app->path_to('docs') );

    cache->set( $cache_key, $data );

    return $data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
