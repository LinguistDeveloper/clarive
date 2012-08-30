package BaselinerX::Controller::Form::BizProjects;
use 5.010;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Data::Dumper;
BEGIN { extends 'Catalyst::Controller' }

# Default subroutine:
# Loads the .js component...
sub index : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-biztalk.js';
  return;
}

# Gets project grid data:
sub grid_proyectos : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};

  # Loads data from model...
  my $data = $c->model('Form::BizProjects')->get_grid_proyectos($cam);

  # Sends data to JSON...
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Gets combo distribucion data:
sub combo_distribucion : Local {
  my ($self, $c) = @_;

  # Loads data from model...
  my $data = $c->model('Form::BizProjects')->set_combo_tipo_distribucion();

  # Sends data to JSON...
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Gets combo almacen data:
sub combo_almacen : Local {
  my ($self, $c) = @_;

  # Loads data from model...
  my $data = $c->model('Form::BizProjects')->set_combo_almacen();

  # Sends data to JSON...
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Gets grid recursos data:
sub grid_recursos : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};

  # Loads data from model...
  my $data = $c->model('Form::BizProjects')->get_grid_recursos($cam);

  # Sends data to JSON...
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Deletes biztalk project:
sub delete_project : Local {
  my ($self, $c) = @_;

  # Gets params from ajax conn...
  my $params = $c->request->parameters;

  # Calls model to delete stuff...
  $c->model('Form::BizProjects')->delete_project($params);
  return;
}

# Gets combo proyecto data:
sub combo_proyecto : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};

  # Loads data from model...
  my $data = $c->model('Form::BizProjects')->get_combo_proyecto($cam);

  # Sends data to JSON...
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Adds a row in BDE_PAQUETE_BIZTALK:
sub add_project : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};

  # Gets params from catalyst...
  my $params = $c->request->parameters;
  $params->{prj_env} = $cam;

  $c->model('Form::BizProjects')->add_project($params);
  return;
}

# Adds a row in BDE_BTS_NET:
sub add_project_net : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  $c->model('Form::BizProjects')->add_project_net($cam);
  return;
}

# Modifies Biztalk Store:
sub mod_almacen : Local {
  my ($self, $c) = @_;
  my $cam    = $c->request->parameters->{cam};
  my $params = $c->request->parameters;
  $params->{prj_env} = $cam;
  $c->model('Form::BizProjects')->mod_almacen($params);
  return;
}

1;
