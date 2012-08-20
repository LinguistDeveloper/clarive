package BaselinerX::Controller::Form::Sistemas;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
use BaselinerX::BdeUtils;
BEGIN { extends 'Catalyst::Controller' }

# register 'menu.admin.sysform' => {
#   label    => 'Formulario de Sistemas',
#   url_comp => '/form/sistemas/',
#   title    => 'Formulario de Sistemas',
#   icon     => 'static/images/icons/drive_disk.png'
# };

sub index : Path {
  my ($self, $c) = @_;
  my $params = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $params->{fid});
  $c->stash->{fid}      = $params->{fid};
  $c->stash->{template} = '/comp/form-sistemas.js';
  return;
}

# Gets data to populate comboboxes, textfields, etc...
sub main_data : Local {
  my ($self, $c) = @_;
  my $cam  = $c->request->parameters->{cam};
  my $data = $c->model('Form::Sistemas')->get_main_data($cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Checks if the selected item is catalogued in BDE_PAQUETE_SISTEMAS and
# returns the count of elements contained in the table
sub check_is_catalogued : Local {
  my ($self, $c) = @_;
  my $params       = $c->request->parameters;
  my $versionobjid = $params->{versionobjid};
  my $data = $c->model('Form::Sistemas')->check_is_catalogued($versionobjid);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Guess what it does?
sub get_owners : Local {
  my ($self, $c) = @_;
  my $cam  = $c->request->parameters->{cam};
  my $data = $c->model('Form::Sistemas')->get_owners($cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

# Inserts new row into BDE_PAQUETE_SISTEMAS
sub catalog : Local {
  my ($self, $c) = @_;
  my $cam      = 'SCT';
  my $env      = 'TEST';
  my $username = $c->username;
  my $params   = $c->request->parameters;
  $params->{sis_cam}         = $cam;
  $params->{environmentname} = $env;
  $c->model('Form::Sistemas')->update_or_create($params, $username);
  return;
}

sub get_grid_data : Local {
  my ($self, $c) = @_;
  my $data = $c->model('Form::Sistemas')->get_grid_data();
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_package_data : Local {
  my ($self, $c) = @_;
  my $params       = $c->request->parameters;
  my $versionobjid = $params->{versionobjid};
  my $data = $c->model('Form::Sistemas')->get_package_data($versionobjid);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub delete_row : Local {
  my ($self, $c) = @_;
  my $params       = $c->request->parameters;
  my $versionobjid = $params->{versionobjid};
  $c->model('Form::Sistemas')->delete_row($versionobjid);
  return;
}

1;

