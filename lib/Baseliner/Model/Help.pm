package Baseliner::Model::Help;
use Moose;

use Try::Tiny;
use YAML::XS qw(Load);
use Text::Markdown 'markdown';
use HTML::Strip;
use Git;

use Baseliner::Utils qw(_array _throw _loc _fail _dir _file);

sub docs_dirs {
    my $self = shift;
    my ($user_lang) = @_;

    $user_lang //= 'en';

    return sort { $a=~/plugin|feature/ <=> $b=~/plugin|feature/ }
        Clarive->app->paths_to( 'docs/' . $user_lang );
}

sub build_doc_tree {
    my $self = shift;
    my ( $opts, @roots ) = @_;

    $opts //= {};

    my $query = $opts->{query};

    my @tree;
    for my $docs_root (@roots) {
        local $opts->{feature_root} = $docs_root unless $opts->{feature_root};
        my ( @docs, @dirs );
        my %uniq_dirs;

        # ->next does not reliably sort dir contents on every platform
        my @dir_or_file;
        while (my $dir_or_file = $docs_root->next ) {
            push @dir_or_file, $dir_or_file;
        }

        foreach my $dir_or_file (sort @dir_or_file) {
            my $name = $dir_or_file->basename;
            next if $name =~ /^\./;

            my $rel =
              $dir_or_file->relative( $opts->{feature_root} );    # always to main root, be it Clarive's or feature's
            if ( $dir_or_file->is_dir ) {

                my @children = $self->build_doc_tree( $opts, $dir_or_file );

                # determine if this dir has a .markdown
                my $dir_markdown = $dir_or_file->basename . '.markdown';
                my $md_file = _file( $dir_or_file->parent, $dir_markdown );
                my $dir_has_markdown = $dir_or_file->parent->contains( $md_file );
                if ( $dir_has_markdown ) {
                    my $data = $self->parse_body( $md_file, $docs_root, { rel=>$rel, %$opts } );
                    my $icon = Util->icon_path( $data->{icon} || '/static/images/icons/catalog-folder.png' );
                    $data->{rel} = "$rel";
                    $uniq_dirs{ $data->{uniq_id} } = 1;
                    my $dir_data = {
                        leaf     => \0,
                        expanded => \( $data->{expanded} // 1 ),
                        index    => $data->{index},
                        icon     => $icon,
                        data     => { path => "$rel" },
                        children => \@children,
                        text     => $data->{title},
                    };
                    $opts->{all_dirs}{$dir_markdown} = $dir_data;
                    push @dirs, $dir_data;
                }
                elsif( exists $opts->{all_dirs}{$dir_markdown} ) {
                    # the official dir node already exists, add to its children
                    push @{ $opts->{all_dirs}{$dir_markdown}{children} }, @children;
                }
                else {
                    # no previous, dir node present nor documented, create a "raw" (ugly) node
                    my $dir_data = {
                        leaf     => \0,
                        expanded => \1,
                        icon     => '/static/images/icons/catalog-folder.png',
                        data     => { path => "$rel" },
                        children => \@children,
                        text     => $name,
                    };
                    $opts->{all_dirs}{$dir_markdown} = $dir_data;
                    push @tree, $dir_data;
                }
            }
            else {
                my $data = $self->parse_body( $dir_or_file, $docs_root, { rel=>$rel, %$opts } );
                next if exists $uniq_dirs{ $data->{uniq_id} }; ## prevent dir markdown descriptors from showing up twice
                next unless $self->doc_matches( $data, $query );
                $data->{rel} = "$rel";
                push @docs, $data;
            }

        }
        my @docs_and_dirs =
          sort { $a->{index} <=> $b->{index} }
          sort { lc( $a->{title} // $a->{data}{path} ) cmp lc( $b->{title} // $b->{data}{path} ) } @dirs,
          @docs;
        for my $doc ( @docs_and_dirs ) {
            if( ref  $doc->{leaf} && ! ${ $doc->{leaf} } ) {  # it's a dir
                push @tree, $doc;
                next;
            }
            my $icon = Util->icon_path( $doc->{icon} || '/static/images/icons/page.png' );
            my $node_data = { path => "" . $doc->{rel} };
            $node_data->{html} = $doc->{html} if $opts->{include_html};
            $node_data->{body} = $doc->{body} if $opts->{include_body};
            push @tree,
              {
                leaf           => \1,
                icon           => $icon,
                data           => $node_data,
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
    my ( $path, $root, $opts ) = @_;

    $opts //= {};

    my ( $id, $type ) = $path->basename =~ /^([^\.]+)(?:\.(\w+))?$/;
    my ($uniq_id) = $path->relative($root) =~ /^([^\.]+)(?:\.(\w+))?$/;
    my $idx = 100;
    my $rel = $opts->{rel};

    # in cache?
    my $cache_key = { d => 'help-doc', path => "$path" };
    if ( my $cached = cache->get($cache_key) ) {
        return $cached;
    }
    $path = _file("$path.markdown") if -d $path;

    # no, so open it
    my $ff;
    if ( $opts->{version} ) {
        my $repo = Git->repository(Directory => $root);
        warn ">>>>>>>>>>>>> GIT: $root == $path == $rel ($id, $uniq_id)";
        ($ff) = $repo->command_output_pipe('show', $opts->{version} . ':"' . $rel . '"' );
    }
    else {
        open $ff, '<:encoding(utf-8)', "$path"
          or _fail _loc "error opening content: %1 (path=%2): %3",
          $path->basename, $path, $!;
    }
    my $contents = join '', <$ff>;
    close $ff;

    # parse
    my ( $yaml, $body ) = $contents =~ /(---.+?)---\n(.*)/s;

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
