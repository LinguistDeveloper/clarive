package Baseliner::Controller::Help;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_load _dump _loc _fail _warn _error _debug _dir _file);
use Baseliner::Sugar;
use HTML::Strip;
use Text::Markdown 'markdown';
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }
use experimental qw(autoderef state);

sub docs_tree : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $path = $p->{path};

    my @tree;

    my $docs_root = $c->path_to('docs');
    my $root = _dir($docs_root, $path)->resolve;
    _fail _loc 'Invalid doc path' unless $docs_root->contains($root);  # don't want anyone to traverse up!
    my (@docs, @dirs);
    my %uniq_dirs; 
    while( my $dir_or_file = $root->next ) {
        my $name = $dir_or_file->basename;
        my $rel  = $dir_or_file->relative($docs_root);
        my $dir_markdown = $dir_or_file->basename . '.markdown';
        next if $name =~ /^\./; 
        if( $dir_or_file->is_dir ) {
            if( $dir_or_file->parent->contains(_file($dir_or_file->parent, $dir_markdown)) ) {
                my $md_file = _file($dir_or_file->parent,$dir_markdown);
                my $data = $self->parse_body( $md_file, $docs_root );
                $data->{rel} = "$rel";
                $uniq_dirs{ $data->{uniq_id} } = 1;
                push @dirs, { 
                    leaf => \0, 
                    index => $data->{index},
                    icon => '/static/images/icons/catalog-folder.png',
                    data => { path=>"$rel" },
                    text=> $data->{title}, 
                }
            } else {
                push @tree, { 
                    leaf => \0, 
                    icon => '/static/images/icons/catalog-folder.png',
                    data => { path=>"$rel" },
                    text=> $name, 
                }
            }
        } else {
            my $data = $self->parse_body( $dir_or_file, $docs_root );
            next if exists $uniq_dirs{ $data->{uniq_id} }; ## prevent dir markdown descriptors from showing up twice
            $data->{rel} = "$rel";
            push @docs, $data;
        }
        
    }
    push @tree, $_ for sort { $a->{index} <=> $b->{index} } @dirs;
    for my $doc ( sort { $a->{index} <=> $b->{index} } @docs ) {
        push @tree, { 
            leaf => \1, 
            icon => '/static/images/icons/page.png',
            data => { path=>$doc->{rel} },
            text=> $doc->{title},
        }
    }

    #_warn( \@tree );
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub get_doc : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $path = $p->{path};

    my $docs = $c->path_to('docs');
    my $root = _file($docs, $path)->resolve;
    _fail _loc 'Invalid doc path: `%1`', $root 
        if( !$docs->contains($root) || $root->is_dir );  # don't want anyone to traverse up!
    my $data = $self->parse_body($root,$docs);
    #_warn( $data );
    $c->stash->{json} = { data=>$data };
    $c->forward('View::JSON');
}

sub parse_body {
    my ($self,$path,$root) = @_;

    my ($id,$type) = $path->basename =~ /^([^\.]+)(?:\.(\w+))?$/;
    my ($uniq_id) = $path->relative($root) =~ /^([^\.]+)(?:\.(\w+))?$/;
    state $idx = 100;
    # in cache? 
    my $cache_key = { d=>'help-doc', path=>"$path" };
    if( my $cached =  cache->get( $cache_key ) ) {
        #return $cached;
    }
    $path = _file("$path.markdown") if -d $path;
    # no, so open it
    open my $ff,'<:encoding(utf-8)', "$path" 
        or _fail _loc "error opening content: %1 (path=%2): %3", $path->basename, $path, $!;
    my $contents = join '',<$ff>;
    close $ff;
    # parse 
    my ($yaml,$body) = $contents =~ /(---.+)---\n(.*)/s;
    # has a body head section in <template...>?
    #  $body =~ s{<template type="([^"]+)" tpl="([^"]+)">(.+?)</template>}{parse_template($1,$2,$3)}seg;
    # convert
    my $html = 
        !defined $type || $type eq 'html' ? $body
        : $type eq 'markdown' ? markdown($body) 
        : die "File type `$type` (extension) not found!";
    my $data = _load( $yaml ) // {};

    # strip html, for search, etc.
    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($html);
    utf8::decode( $clean_text );
    
    # index navigation
    #   my $dom = Mojo::DOM->new( $html );
    #   $$data{nav} = '';
    #   for my $t ( $dom->find('h1, h2, h3')->each ) {
    #       $$data{nav} .= $t;
    #   }
    if( my $tag_str = delete $$data{tags} ) {
        my @tags = map { s/^\s+//g; s/\s+$//g; { tag=>$_, id=>("$_"=~s/\s+/-/gr) } } split /,/, $tag_str;
        $$data{tags} = \@tags;
    } else {
        $$data{tags} = [];
    }
    
    $data = { id=>$id, uniq_id=>$uniq_id, name=>$id, title=>$id, body=>$body, yaml=>$yaml, text=>$clean_text, index=>$idx++, 
        html=>$html, tpl=>( $type eq 'html' ? 'raw' : 'default' ), %$data };
    # $$data{path} //= "/$$data{parent}/$$data{id}", 
    $$data{path} //= ''. $path->relative( Baseliner->path_to('docs') );
    # menu 
    cache->set( $cache_key, $data );
    return $data;
}

1;
