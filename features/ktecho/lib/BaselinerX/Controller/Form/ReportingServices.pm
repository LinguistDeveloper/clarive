package BaselinerX::Controller::Form::ReportingServices;
use strict;
use warnings;
use Baseliner::Utils;
use Baseliner::Plug;
use BaselinerX::BdeUtils;
BEGIN { extends 'Catalyst::Controller' }

# register 'menu.admin.reportingservices' => {
#   label    => 'Reporting Services',
#   url_comp => '/form/reportingservices',
#   title    => 'Reporting Services',
#   icon     => 'static/images/icons/drive_disk.png'
# };

sub index : Path {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $c->stash->{cam}      = _cam_from(fid => $p->{fid});
  $c->stash->{fid}      = $p->{fid};
  $c->stash->{template} = '/comp/form-repser.js';
  return;
}

sub combo_recursos_data : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $data_ref = $c->model('Form::ReportingServices')
                       ->combo_recursos_data($cam);
  my @data = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');
  return;
}

sub grid_data : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};

  my $data_ref = $c->model('Form::ReportingServices')->_data_grid($cam);
  my @data     = @{$data_ref};

  $c->stash->{json} = {data => \@data};
  $c->forward('View::JSON');
  return;
}

sub delete_row : Local {
  my ($self, $c) = @_;
  my $p = $c->request->parameters;
  $p->{fullname} =~ s/\\\\/\\/g;
  $p->{item}     =~ s/\\\\/\\/g;

  my $where;
  $where->{rs_env}      = $p->{env};
  $where->{rs_fullname} = $p->{fullname};
  $where->{rs_elemento} = $p->{item};

  $c->model('Form::ReportingServices')->delete_bde_paquete_rs($where);
  return;
}

sub add_row : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;

  if ($p->{fullname} !~ m/\\/xi) {
    $p->{fullname} = '\\' . $p->{fullname};
  }
  my $args;
  $args->{rs_env}      = $cam;
  $args->{rs_elemento} = $p->{item};
  $args->{rs_fullname} = $p->{fullname};

  $c->model('Form::ReportingServices')->insert_bde_paquete_rs($args);
  return;
}

1;

