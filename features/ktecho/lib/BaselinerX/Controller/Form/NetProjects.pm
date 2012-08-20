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

has 'fid', is => 'rw', isa => 'Int';

sub load_extjs : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $self->fid($p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-net.js';
  return;
}

sub combo_proyectos : Local {
  my ($self, $c) = @_;
  my $p    = $c->request->parameters;
  my $fid  = $p->{fid} || $self->fid || _throw "No tengo fid en Controller::combo_proyectos!";
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
  my $p    = $c->request->parameters;
  my $fid  = $p->{fid} || $self->fid || _throw "No tengo fid en Controller::net_grid!";
  my $cam  = _cam_from(fid => $fid);
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
  $c->stash->{json} = {data => [grep $_->{env} eq $cam, @data]};
  $c->forward('View::JSON');
  return;
}

sub delete_row : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  my $args;
  $args->{prj_env}           = $p->{env};
  $args->{prj_proyecto}      = $p->{proyecto};
  $args->{prj_subaplicacion} = $p->{subaplicacion};
  $args->{prj_tipo}          = do {
  	my $tipos = $c->model('Form::NetProjects')->get_tipos_distribucion;
  	my @ret = map { $_->{value} } grep($_->{show} eq $p->{tipo}, @{$tipos});
  	$ret[0];  # Force scalar context.
  };
  $c->model('Form::NetProjects')->delete_bde_paquete_proyectos_net($args);
  return;
}

sub add_row : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  ($p->{prj_fullname}, 
   $p->{prj_subaplicacion}, 
   $p->{prj_proyecto}
   ) = split '\|', $p->{multival};
  delete $p->{multival};  # We won't be needing this.
  
  # Add if value doesn't exist already.
  $c->model('Form::NetProjects')->add_row($p) 
    unless $c->model('Form::NetProjects')->existsp($p);
  return;
}

1;

