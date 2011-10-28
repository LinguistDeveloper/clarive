package BaselinerX::Controller::Form::Vignette;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

# register 'menu.admin.vignette' => {
#   label    => 'Proyectos Vignette',
#   url_comp => '/form/vignette',
#   title    => 'Proyectos Vignette',
#   icon     => 'static/images/icons/drive_disk.png'
# };

sub index : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{template} = '/comp/form-vignette.js';
  return;
}

sub get_entornos : Local {
  my ($self, $c) = @_;
  my $data_ref = $c->model('Form::Vignette')->get_entornos();
  $c->stash->{json} = {data => $data_ref};
  $c->forward('View::JSON');
  return;
}

sub get_servers : Local {
  my ($self, $c) = @_;
  my $p        = $c->request->parameters;
  my $cam      = $p->{cam};
  my $data_ref = $c->model('Form::Vignette')->get_servers($cam);
  $c->stash->{json} = {data => $data_ref};
  $c->forward('View::JSON');
  return;
}

sub get_usuario_funcional : Local {
  my ($self, $c) = @_;
  my $p   = $c->request->parameters;
  my $cam = $p->{cam};
  my $data =
    $c->model('Form::Vignette')->get_usuario_funcional($cam, $p->{env});
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_grid : Local {
  my ($self, $c) = @_;
  my $p    = $c->request->parameters;
  my $env  = $p->{env};
  my $cam  = $p->{cam};
  my $data = $c->model('Form::Vignette')->get_grid($cam, $env);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub add_row : Local {
  my ($self, $c) = @_;
  my $p   = $c->request->parameters;
  my $cam = $p->{cam};
  $p->{vig_cam}  = $cam;
  $p->{vig_user} = $c->username;
  $c->model('Form::Vignette')->add_row($p);
  return;
}

sub delete_row : Local {
  my ($self, $c) = @_;
  my $p   = $c->request->parameters;
  my $cam = $p->{cam};
  $c->model('Form::Vignette')->delete_row($cam, $p);
  return;
}

sub raise_order : Local {
  my ($self, $c) = @_;
  my $p   = $c->request->parameters;
  my $cam = $p->{cam};
  $c->model('Form::Vignette')->raise_order($cam, $p);
  return;
}

sub update_row : Local {
  my ($self, $c) = @_;
  my $p   = $c->request->parameters;
  my $cam = $p->{cam};
  $c->model('Form::Vignette')->update_row($cam, $p);
  return;
}

1;
