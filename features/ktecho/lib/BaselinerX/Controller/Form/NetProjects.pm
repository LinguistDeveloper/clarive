package BaselinerX::Controller::Form::NetProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use 5.010;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

# register 'menu.admin.proyecto_net_extjs' => {
#   label    => 'Proyectos NET',
#   url_comp => '/form/netprojects',
#   title    => 'Proyectos NET',
#   icon     => 'static/images/icons/drive_disk.png'
# };

# sub index : Local {
#   my ($self, $c) = @_;
#   my $user   = $c->username;
#   my $p      = $c->request->parameters;
#   my $fid    = $p->{fid};
#   my $accion = $p->{accion};
#   my $cam;

#   if ($accion) {
#     try {
#       my $fullname      = $p->{fullname};
#       my $cam           = $p->{cam};
#       my $project_type  = $p->{project_type};
#       my $subaplicacion = $p->{subaplicacion};
#       my $item          = $p->{item};

#       if ($accion eq 'A') {
#         $c->model('Form::NetProjects')->net_delete_bde_paquete(
#           { fullname     => $fullname,
#             cam          => $cam,
#             project_type => $project_type
#           }
#         );

#         $c->model('Form::NetProjects')->net_insert_bde_paquete(
#           { cam           => $cam,
#             fullname      => $fullname,
#             project_type  => $project_type,
#             subaplicacion => $subaplicacion,
#             item          => $item
#           }
#         );
#       }
#       elsif ($accion eq 'D') {
#         $c->model('Form::NetProjects')->net_delete_bde_paquete(
#           { fullname     => $fullname,
#             cam          => $cam,
#             project_type => $project_type
#           }
#         );
#       }
#     }
#   }
#   my $siguiente = 0;

#   my @entornos = $c->model('Form::NetProjects')->net_get_cams($fid);

#   # Por si no existe...
#   my $cam_reserva = $c->model('Form::NetProjects')->net_get_cam_reserva($fid);

#   my @project_envs = $c->model('Form::NetProjects')->net_get_project_env();

#   $c->stash->{entornos}     = \@entornos;
#   $c->stash->{cam_reserva}  = $cam_reserva;
#   $c->stash->{project_envs} = \@project_envs;
#   $c->stash->{cam}          = $cam;
#   $c->stash->{fid}          = $fid;
#   $c->stash->{template}     = '/form/net_projects.html';
#   $c->forward('View::Mason');
#   return;
# }

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
  my $fid  = $c->request->parameters->{fid};
  my @temp = $c->model('Form::NetProjects')->net_get_cams($fid);
  my @data = ();
  for my $ref (@temp) {
    push @data,
         { value => "$ref->{fullname}|$ref->{subaplicacion}|$ref->{item}",
           show  => "$ref->{subaplicacion} => $ref->{item}"
         };
  }
  $c->stash->{json} = {data => \@data};
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

