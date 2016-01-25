package Baseliner::Controller::Help;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use Clarive::ci;
use BaselinerX::Type::Model::ConfigStore;
use Baseliner::Model::Help;
use Baseliner::Utils qw(_loc _fail _file);

sub docs_tree : Local {
    my ( $self, $c ) = @_;

    my $p     = $c->req->params;
    my $query = $p->{query};

    my $user_lang = $self->_get_user_lang( $c->username );

    my @doc_dirs = $self->_build_help->docs_dirs($user_lang);
    my @tree = $self->_build_help->build_doc_tree( { query => $query, user_lang => $user_lang }, @doc_dirs );

    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub get_doc : Local {
    my ( $self, $c ) = @_;

    my $p    = $c->req->params;
    my $path = $p->{path};

    my $user_lang = $self->_get_user_lang( $c->username );

    my $data;
    for my $docs ( $self->_build_help->docs_dirs($user_lang) ) {

        # resolve dies on you if !exists
        my $root = try { _file( $docs, $path )->resolve } catch { undef };

        next unless $root;

        # Don't want anyone to traverse up!
        next if ( !$docs->contains($root) || $root->is_dir );

        $data = $self->_build_help->parse_body( $root, $docs );
    }

    _fail _loc 'Invalid doc path: `%1`', $path unless $data;

    $c->stash->{json} = { data => $data };
    $c->forward('View::JSON');
}

sub _get_user_lang {
    my $self = shift;
    my ($username) = @_;

    my $user_lang;

    my $user_ci = ci->user->find_one( { name => $username } );

    return ( $user_ci && $user_ci->{language_pref} )
      // BaselinerX::Type::Model::ConfigStore->new->get('config.user.global')->{language} // 'en';
}

sub _build_help {
    my $self = shift;

    return Baseliner::Model::Help->new;
}

1;
