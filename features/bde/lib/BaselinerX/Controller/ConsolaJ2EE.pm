package BaselinerX::Controller::ConsolaJ2EE;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;
BEGIN { extends 'Catalyst::Controller' }

register 'menu.nature.consola' => {
  label    => 'Consola de aplicaciones J2EE',
  url_comp => 'consolaj2ee/load_extjs',
  title    => 'Consola de aplicaciones J2EE',
  icon     => 'static/images/icons/application_double.png',
  action   => 'action.bde.view_j2ee_console'
};

sub load_extjs : Local {
  my ($self, $c) = @_;
  $c->stash->{template} = '/comp/consola-j2ee.js';

  return;
}

sub get_list_of_cams : Local {
  my ($self, $c) = @_;
  my $data = $c->model('ConsolaJ2EE')->get_list_of_cams();
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');

  return;
}

sub has_java : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  use BaselinerX::Ktecho::CamUtils;
  my $data = [{value => tiene_java $p->{cam}}];
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');

  return;
}

sub get_sub_appl : Local {
  my ($self, $c) = @_;
  my $p    = $c->request->parameters;
  my $cam  = $p->{cam};
  my $data = $c->model('ConsolaJ2EE')->get_sub_appl($cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');

  return;
}

sub get_entornos : Local {
  my ($self, $c) = @_;
  my $p    = $c->request->parameters;
  my $cam  = $p->{cam};
  my $data = $c->model('ConsolaJ2EE')->get_entornos($cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');

  return;
}

1;
