package BaselinerX::Controller::Form::NetProjects;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Data::Dumper;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub load_extjs : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-net.js';
  return;
}

sub combo_proyectos : Local {
  my ($self, $c) = @_;
  #my $fid  = $c->request->parameters->{fid};
  my $fid = 671;
  my $data = $c->model('Form::NetProjects')->net_get_cams($fid);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub tipo_distribucion : Local {
  my ($self, $c) = @_;
  my $data_ref = $c->model('Form::NetProjects')->get_tipos_distribucion();
  my @data     = @{$data_ref};
  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');
  return;
}

sub net_grid : Local {
  my ($self, $c) = @_;
  my @data = $c->model('Form::NetProjects')->net_get_project_env;

  # Formateo el tipo...
  for my $ref (@data) {
    $ref->{tipo} = ($ref->{tipo} eq 'CA') ? 'Cliente click-once IBM HTTP Server'
                 : ($ref->{tipo} eq 'CO') ? 'Cliente click-once IIS'
                 : ($ref->{tipo} eq 'CR') ? 'Cliente R:'
                 : ($ref->{tipo} eq 'SL') ? 'Biblioteca Servidor'
                 : ($ref->{tipo} eq 'RS') ? 'Cliente R: Sucursales'
                 :                          'Servidor IIS';
  }
  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');
  return;
}

sub delete_row : Local {
  my ($self, $c) = @_;
  # my $p = $c->request->parameters;
  # my $args;
  # $args->{env}           = $p->{env};
  # $args->{proyecto}      = $p->{proyecto};
  # $args->{subaplicacion} = $p->{subaplicacion};
  # $args->{tipo}          = $p->{tipo};
  # $c->model('Form::NetProjects')->delete_bde_paquete_proyectos_net($args);
  return;
}

1;

