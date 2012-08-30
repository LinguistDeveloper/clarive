package BaselinerX::Controller::Form::PrePost;
use strict;
use warnings;
use Baseliner::Utils;
use Baseliner::Plug;
use BaselinerX::BdeUtils;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

# register 'menu.admin.proyecto_prepost_extjs' => {
#   label    => 'Formulario Pre/Post',
#   url_comp => '/form/prepost/load_extjs',
#   title    => 'Formulario Pre/Post',
#   icon     => 'static/images/icons/drive_disk.png'
# };

sub load_extjs : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-prepost.js';
  return;
}

sub combo_entorno : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->combo_entornos_data();
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub combo_naturaleza : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->combo_naturaleza_data();
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub combo_os : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->combo_os_data();
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub combo_prepost : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->combo_prepost_data();
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub combo_server : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  my $args;
  $args->{cam} = $p->{cam};
  $args->{env} = $p->{entorno};
  my @data = @{$c->model('Form::PrePost')->combo_server_data($args)};
  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');
  return;
}

sub combo_query : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;

  my $where    = $c->model('Form::PrePost')->_where($p);
  my $data_ref = $c->model('Form::PrePost')->get_bde_paquete_prepost($where);
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub combo_block : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->combo_block_data();
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub grid_test : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->grid_data('TEST');
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub grid_ante : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->grid_data('ANTE');
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub grid_prod : Local {
  my ($self, $c) = @_;

  my $data_ref = $c->model('Form::PrePost')->grid_data('PROD');
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');

  return;
}

sub delete_row : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;

  my $args;
  $args->{cam}        = $p->{cam};
  $args->{entorno}    = $p->{p_entorno} if $p->{p_entorno};
  $args->{prepost}    = $p->{p_prepost} if $p->{p_prepost};
  $args->{exec}       = $p->{p_exec} if $p->{p_exec};
  $args->{naturaleza} = $p->{p_naturaleza} if $p->{p_naturaleza};

  if ($p->{p_usumaq} =~ m/(.*)@(.*)/xi) {
    $args->{user} = $1;
    $args->{maq}  = $2;
  }

  $c->model('Form::PrePost')->delete_bde_prepost($args);

  return;
}

sub create_row : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  my $args;
  $args->{pp_cam}  = $p->{cam};
  $args->{pp_exec} = $p->{insert_programa} if exists $p->{insert_programa};
  $args->{pp_env}  = $p->{insert_proyecto} if exists $p->{insert_proyecto};
  $args->{pp_naturaleza} = $p->{insert_naturaleza}
    if exists $p->{insert_naturaleza};
  $args->{pp_prepost} = $p->{insert_prepost}  if exists $p->{insert_prepost};
  $args->{pp_maq}     = $p->{insert_servidor} if exists $p->{insert_servidor};
  $args->{pp_usu}     = $p->{insert_usuario}  if exists $p->{insert_usuario};
  $args->{pp_block}   = $p->{insert_bloquear} if exists $p->{insert_bloquear};
  $args->{pp_os}      = $p->{insert_so}       if exists $p->{insert_so};

  $c->model('Form::PrePost')->create_bde_prepost($args);
  return;
}

1;
