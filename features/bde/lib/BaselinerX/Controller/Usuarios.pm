package BaselinerX::Controller::Usuarios;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
use Try::Tiny;
use Baseliner::Core::DBI;
use parent qw/DBIx::Class::ResultSet/;
use Baseliner::Schema::Baseliner::Base::ResultSet;
use Baseliner::Model::Users;
BEGIN { extends 'Catalyst::Controller' }

register 'menu.admin.mostrar_usuarios' => {
    label    => 'Mostrar usuarios',
    url_comp => '/usuarios/mostrar_hash',
    title    => 'Lista de usuarios',
    icon     => 'static/images/scm/icons/approve_16.png'
};

sub mostrar_hash : Local {
    my ( $self, $c ) = @_;

    $c->stash->{template} = '/comp/json-grid-usuarios.js';

    return;
}

sub cargar_usuarios_grid : Local {
    my ( $self, $c ) = @_;
    my @data = $c->model('usuarios')->coger_todos_usuarios();

    $c->stash->{json} = { data => @data };
    $c->forward('View::JSON');

    return;
}

1;
