package BaselinerX::Controller::Form::Main;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Data::Dumper;
use utf8;
BEGIN { extends 'Catalyst::Controller' }

sub index : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-main.js';
  return;
}

sub load_inc : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = $p->{cam};
  $c->stash->{template} = '/comp/form-main-inc.js';
  return;
}

sub load_hsp : Local {
  my ($self, $c) = @_;
  my $params = $c->request->parameters;
  $c->stash->{tipo}     = $params->{tipo};
  $c->stash->{template} = '/comp/form-main-hsp.js';
  return;
}

sub get_main_data : Local {
  my ($self, $c) = @_;
  my $p         = $c->request->parameters;
  my $cam       = $p->{cam} || _throw "No CAM at Controller::get_main_data";
  my $formobjid = $p->{fid} || _throw "No Fid at Controller::get_main_data";
  my $username  = $c->username;
  my $where     = {'trim(username)' => $username};
  my $args      = {select => 'usrobjid'};
  my $rs        = Baseliner->model('Harvest::Haruser')->search($where, $args);
  rs_hashref($rs);
  my $usrobjid = $rs->next->{usrobjid};
  my $data = $c->model('Form::Main')->get_main_data($formobjid,
                                                    $usrobjid,
                                                    $username,
                                                    $cam);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_natures : Local {
  my ($self, $c) = @_;
  my $params   = $c->request->parameters;
  my $envobjid = $params->{envobjid};
  my $cam      = $params->{cam};
  my $data     = $c->model('Form::Main')->get_natures($cam, $envobjid);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_combo_ciclo_vida_data : Local {
  my ($self, $c) = @_;
  my $params = $c->request->parameters;
  my $data   = $c->model('Form::Main')->get_combo_ciclo_vida_data($params);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_combo_cambio_data : Local {
  my ($self, $c) = @_;
  my $data = $c->model('Form::Main')->get_combo_cambio_data();
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub get_combo_tipologia_data : Local {
  my ($self, $c) = @_;
  my $params = $c->request->parameters;
  my $data   = $c->model('Form::Main')->get_combo_tipologia_data($params);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub update_textareas : Local {
  my ($self, $c) = @_;
  my $params = $c->request->parameters;
  $c->model('Form::Main')->update_textareas($params);
  return;
}

sub load_grid_inc : Local {
  my ($self, $c) = @_;
  my $link_USD = 'BDE_SCM_USD@USD';
  my $params   = $c->request->parameters;
  my $cam      = $params->{cam};
  my $username = $c->username;
  my $data = $c->model('Form::Main')->load_grid_inc($cam,
                                                    $username,
                                                    $link_USD,
                                                    $params->{query});
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub load_grid_hsp : Local {
  my ($self, $c) = @_;
  my $params   = $c->request->parameters;
  my $tipo     = $params->{tipo};
  my $username = $c->username;
  my $data     = $c->model('Form::Main')->load_grid_hsp($tipo, $username);
  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

1;

