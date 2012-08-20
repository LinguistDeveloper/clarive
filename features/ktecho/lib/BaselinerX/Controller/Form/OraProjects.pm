package BaselinerX::Controller::Form::OraProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use 5.010;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub cargar_prueba : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-oracle.js';
  return;
}

sub _JSON_data : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $m   = $c->model('Form::OraProjects');
  my @grid_ins = $m->get_configurar_estancias_table($cam);
  $c->stash->{json} = {grid_ins => \@grid_ins};
  $c->forward('View::JSON');
  return;
}

sub grid_despliegue : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $m = $c->model('Form::OraProjects');
  my @tabla_despliegue = $m->get_tabla_config_despliegue($cam);
  $c->stash->{json} = {data => \@tabla_despliegue};
  $c->forward('View::JSON');
  return;
}

sub grid_instancia : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $m = $c->model('Form::OraProjects');
  my $data = $m->get_configurar_estancias_table($cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_entornos : Local {
  my ($self, $c) = @_;
  my $data = $c->model('Form::OraProjects')->get_entorno;
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_redes : Local {
  my ($self, $c) = @_;
  my $cam  = $c->request->parameters->{cam};
  my $data = $c->model('Form::OraProjects')->get_redes($cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_folders : Local {
  my ($self, $c) = @_;
  my $cam  = $c->request->parameters->{cam};
  my @data = $c->model('Form::OraProjects')->get_folders($cam);
  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');
  return;
}

sub get_instancias_despliegue : Local {
  my ($self, $c) = @_;
  my $cam  = $c->request->parameters->{cam};
  my $p    = $c->request->parameters;
  my $env  = $p->{env};
  my $m    = $c->model('Form::OraProjects');
  my $data = $m->get_entornos_filtered($cam, $env);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_instancias : Local {
  my ($self, $c) = @_;
  my $cam  = $c->request->parameters->{cam};
  my $p    = $c->request->parameters;
  my $env  = $p->{env};
  my $data = $c->model('Form::OraProjects')->get_instancias($env, $cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_owners : Local {
  my ($self, $c) = @_;
  my $cam   = $c->request->parameters->{cam};
  my $p     = $c->request->parameters;
  $p->{cam} = $cam;
  my $data  = $c->model('Form::OraProjects')->get_owners($p);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub delete_des : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->params;
  $p->{ora_prj} = $cam;
  delete $p->{cam};
  $c->model('Form::OraProjects')->delete_des($p);
  return;
}

sub add_despliegue : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;
  $c->model('Form::OraProjects')->add_despliegue($cam, $p);
  return;
}

sub add_instancia : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;
  $p->{cam} = $cam;
  $c->model('Form::OraProjects')->add_instancia($p);
  return;
}

sub delete_ins : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;
  _log 'parameters :: ' . Data::Dumper::Dumper $p;
  $p->{cam} = $cam;
  $c->model('Form::OraProjects')->delete_ins($p);
  return;
}

1;

