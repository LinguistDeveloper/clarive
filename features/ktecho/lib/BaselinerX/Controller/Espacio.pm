package BaselinerX::Controller::Espacio;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

register 'menu.admin.espacio' => {
    label    => 'Informe de Espacio',
    url_comp => '/espacio/cargar_prueba',
    title    => 'Informe de Espacio',
    icon     => 'static/images/icons/drive_disk.png'    
};

sub cargar_prueba : Local {
  my ( $self, $c ) = @_;
  $c->stash->{template} = '/comp/informe_espacio.js';
  return }

sub load : Local {
    my ( $self, $c ) = @_;

    my $p       = $c->request->parameters;
    my $p_sort  = $p->{sort};
    my $p_dir   = $p->{dir};
    my $p_query = $p->{query};
    my $p_hist  = $p->{hist};
    my @data    = $c->model('Espacio')->get_data(
        {   sort  => $p_sort,
            dir   => $p_dir,
            query => $p_query,
            hist  => $p_hist
        }
    );

    $c->stash->{json} = { data => \@data };
    $c->forward('View::JSON');

    return;
}

sub load_path : Local {
    my ( $self, $c ) = @_;

    my $p         = $c->request->parameters;
    my $p_project = $p->{project};
    my $p_sort    = $p->{sort};
    my $p_dir     = $p->{dir};
    my $p_cmd     = $c->session->{usuario};
    my @data = $c->model('Espacio')->get_data_path(
        {   project => $p_project,
            sort    => $p_sort,
            dir     => $p_dir
        }
    );

    $c->stash->{json} = { data => \@data };
    $c->forward('View::JSON');

    return;
}

sub load_total : Local {
    my ( $self, $c ) = @_;

    $c->stash->{total_compress} = $c->model('Espacio')->get_total_compress_size();
    $c->stash->{total}          = $c->model('Espacio')->get_total_size();
    $c->stash->{total_item}     = $c->model('Espacio')->get_total_item_size();
    $c->stash->{total_ver}      = $c->model('Espacio')->get_total_ver_size();
    $c->stash->{template}       = 'espacio_total.html';

    $c->forward('View::Mason');

    return;
}

1;
