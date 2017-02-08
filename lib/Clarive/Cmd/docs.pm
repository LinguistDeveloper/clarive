package Clarive::Cmd::docs;
use Mouse;
use Baseliner::Utils qw(_dir _file _dump);
use Baseliner::Model::Help;
use Text::Markdown 'markdown';
use Clarive::cache;
use v5.10;

extends 'Clarive::Cmd';

our $CAPTION = 'Manage the Clarive Documentation';

has doc_version => qw(is rw isa Str), default => '';
has doc_format  => qw(is rw isa Str default md);

has doc_lang    => qw(is rw isa Str), default => 'en';

has mkdocs_path => qw(is rw isa Str), default=>sub{
    '' . _dir(Clarive->app->home, '/mkdocs');
};

has site_dir => qw(is rw isa Str), default=>sub{
    '' . _dir(Clarive->app->home, './root/static/mkdocs');
};

sub run {
    my $self = shift;
    my %opts = @_;
    $self->run_export;
}

sub run_export {
    my $self = shift;
    my %opts = @_;

    my $mkdocs_path = $self->mkdocs_path;
    _dir( $mkdocs_path )->rmtree if -e $mkdocs_path;
    my $doc_dir = $self->site_dir;
    my @doc_dirs = Baseliner::Model::Help->docs_dirs( $self->doc_lang );

    my @tree = Baseliner::Model::Help->build_doc_tree(
        {
            query        => undef,
            user_lang    => $self->doc_lang,
            include_html => 1,
            include_body => 1,
            version      => $self->doc_version
        },
        @doc_dirs
    );

    my $dump_mkhelp;

    my @pages = $self->dump_mkhelp( @tree );

    # generate an index
    my $index_file = _file( $mkdocs_path, 'docs/index.md' );
    my $index_content = $self->index_content(0, @pages );
    $index_file->spew( qq{
# Welcome to the Clarive Documentation

This is the product documentation, automatically generated from the product Help for this given release.
$index_content
    });

    # create config file
    unshift @pages, { Home=>'index.md' };
    warn Util->_dump( \@pages );
    my $config = {
        pages     => \@pages,
        site_name => 'Clarive Docs',
        theme_dir => "$mkdocs_path/../root/static/readthedocs",
    };
    my $config_file = _file( $mkdocs_path, 'mkdocs.yml' );
    $config_file->spew( _dump($config) );

    # finally, build the static documentation
    system qq{cd "$mkdocs_path" && mkdocs build --clean -d "$doc_dir"};
}

sub dump_mkhelp {
    my $self = shift;
    my @nodes;
    for my $node ( @_ ) {
        my $chi = $node->{children};
        push @nodes, {
            $node->{text} => ($chi && @$chi
                ? [ $self->dump_mkhelp(@$chi) ]
                : $self->mkdocs_conv( $node )
            ),
        };
    }
    @nodes;
}

sub index_content {
    my $self = shift;
    my ($lev,@pages) = @_;
    my $lev_str = '#' x ($lev+2);
    my @content;
    for my $page ( @pages ) {
        for my $key ( keys %$page ) {
            if( !ref ( my $url = $page->{$key} ) ) {
                $url =~ s{\.(html|md)$}{}g;
                push @content, qq{- [$key]($url)};
            } else {
                push @content, qq{$lev_str $key};
                push @content, $self->index_content(1, @{ $page->{$key} } );
            }
        }
    }
    join "\n", @content;
}

sub mkdocs_conv {
    my $self = shift;
    my ($node) = @_;

    my $fpath = $node->{data}{path};
    my $md_orig = _file( 'docs/' . $self->doc_lang , $fpath );

    my $ext = $self->doc_format;
    $fpath =~ s{\.markdown$}{.$ext}g;

    my $md_dest = _file( $self->mkdocs_path, 'docs', $fpath );
    $md_dest = _file($md_dest);
    $md_dest->parent->mkpath;

    my $title = '<h1 class="doc-title">' . $node->{text} . "</h1>\n\n";

    if( $self->doc_format eq 'html' ) {
        $md_dest->spew("$title$node->{data}{html}" );
    } else {
        $md_dest->spew( iomode=>'>:utf8', $title . $node->{data}{body} );
    }
    return "$fpath";
}

1;
