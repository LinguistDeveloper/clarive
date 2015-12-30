package Baseliner::Controller::Help;
use Moose;

use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_array _load _throw _dump _loc _fail _log _warn _error _debug _dir _file);
use Baseliner::Model::Help;
use HTML::Strip;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

use experimental qw(autoderef);

sub docs_tree : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $query = $p->{query};
    my $user_lang = ci->user->find_one({name=>$c->username})->{language_pref} // config_get('config.user.global')->{language};
    my @tree = $self->_build_help->build_doc_tree({ query=>$query, user_lang => $user_lang }, $self->_build_help->docs_dirs($user_lang) );
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub get_doc : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $path = $p->{path};

    my $data;
    for my $docs ( $self->_build_help->docs_dirs ) {
        my $root = try { _file($docs, $path)->resolve } catch { undef };  # resolve dies on you if !exists
        next unless $root;
        next if( !$docs->contains($root) || $root->is_dir );  # don't want anyone to traverse up!
        $data = $self->_build_help->parse_body($root,$docs);
    }
    _fail _loc 'Invalid doc path: `%1`', $path unless $data; 
    #_warn( $data );
    $c->stash->{json} = { data=>$data };
    $c->forward('View::JSON');
}

sub _build_help {
    my $self = shift;
    return Baseliner::Model::Help->new;
}

1;
