package BaselinerX::Controller::Form::OraProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use 5.010;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

# register 'menu.admin.proyecto_oracle_extjs' => {
#   label    => 'Proyectos ORACLE',
#   url_comp => '/form/oraprojects/cargar_prueba',
#   title    => 'Proyectos ORACLE',
#   icon     => 'static/images/icons/drive_disk.png'
# };

#sub index : Local {
#    my ( $self, $c ) = @_;
#
#    my $inf_data    = 'inf_data_inf';
#    my $inf_form    = 'inf_form_inf';
#    my $p           = $c->request->parameters;
#    my $fid         = $p->{fid};
#    my $accion      = $p->{accion};
#    my $fullname    = $p->{fullname};
#    my @param_names = ();
#    my $sql;
#    my $cam = 'SCT';
#    my $env;
#    undef my %data_hash;
#
#    my @entornos_redes = $c->model('Form::OraProjects')->get_entornos_redes($cam);
#
#    try {
#        if ($fid) {
#            my @envs = $c->model('Form::OraProjects')->get_envs(
#                {   fid      => $fid,
#                    inf_data => $inf_data,
#                    inf_form => $inf_form
#                }
#            );
#            ( $env, $cam ) = shift @envs;
#        }
#    }
#    catch {
#        print "Se ha producido un error al conectar a la base de datos.";
#    };
#
#    #  InfVariables infvar = new InfVariables();
#    #  infvar.setEntorno("[t|a|p]");
#    #  infvar.setCAM("cam");
#
#    if ($accion) {
#        try {
#            if ( $accion eq 'AC' ) {
#                $c->model('Form::OraProjects')->insert_bde_paquete(
#                    {   accion   => $accion,
#                        env      => $env,
#                        fullname => $fullname
#                    }
#                );
#            }
#            elsif ( $accion eq 'UC' ) {
#                @param_names = keys %{$p};
#                my $red    = $p->{red};
#                my $opcion = $p->{opcion};
#
#                $c->model('Form::OraProjects')->update_bde_paquete(
#                    {   opcion   => $opcion,
#                        red      => $red,
#                        env      => $env,
#                        fullname => $fullname
#                    }
#                );
#            }
#            elsif ( $accion eq 'D' ) {
#                $c->model('Form::OraProjects')->delete_bde_paquete(
#                    {   accion   => $accion,
#                        fullname => $fullname,
#                        env      => $env
#                    }
#                );
#            }
#            elsif ( $accion eq 'AO' ) {
#                foreach my $param_name (@param_names) {
#
#                    # Si termina en 'OWNER'...
#                    if ( $param_name =~ m/OWNER$/ ) {
#                        $c->model('Form::OraProjects')->delete_bde_paquete(
#                            {   accion     => $accion,
#                                env        => $env,
#                                param_name => $param_name
#                            }
#                        );
#
#                        # ¿Existe valor?
#                        if ( $p->{param_name} ) {
#                            $c->model('Form::OraProjects')->insert_bde_paquete(
#                                {   accion      => $accion,
#                                    param_name  => $param_name,
#                                    param_value => $p->{param_name}
#                                }
#                            );
#                        }    # --- end if --- #
#                    }    # --- end if --- #
#                }    # --- end foreach --- #
#            }    # --- end elsif --- #
#        }
#        catch {
#            print 'Error.';
#        }
#    }
#
#    try {
#         %data_hash = %{ $c->model('Form::OraProjects')->get_data_hash($cam) };
#        my $has_red = $c->model('Form::OraProjects')->_has_red( \%data_hash );
#        my $has_env = $c->model('Form::OraProjects')->_has_env( \%data_hash );
#    }
#    catch {
#        print 'Error.';
#    }
#
#    return;
#}

#sub tabla : Local {
#    my ( $self, $c ) = @_;
#
#    my $cam = 'SCT';
#
#    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
#    my $inf_db = BaselinerX::Ktecho::INF::DB->new;
#
#    # get entorno
#    my $sql = qq/
#        SELECT distinct mv.mv_valor entorno
#        FROM   inf_data id,
#            inf_data id2,
#            inf_data_mv mv
#        WHERE  id.column_name = 'MAIN_ENTORNOS'
#            AND id.cam = 'SCT' -- $cam
#            AND id.valor = '@#'
#                            || mv.id
#            AND id.idform = (SELECT MAX(IF.idform)
#                                FROM   inf_form IF
#                                WHERE  IF.cam = id.cam)
#            AND id2.column_name = 'TEC_ORACLE'
#            AND id2.cam = id.cam
#            AND id2.idform = id.idform
#    /;
#
#    my @entornos = $inf_db->db->array_hash($sql);
#
#    # get redes
#    $sql = qq/
#        SELECT distinct id2.idred
#        FROM   inf_data id,
#            inf_data id2,
#            inf_data_mv mv
#        WHERE  id.column_name = 'MAIN_ENTORNOS'
#            AND id.cam = 'SCT' -- $cam
#            AND id.valor = '@#'
#                            || mv.id
#            AND id.idform = (SELECT MAX(IF.idform)
#                                FROM   inf_form IF
#                                WHERE  IF.cam = id.cam)
#            AND id2.column_name = 'TEC_ORACLE'
#            AND id2.cam = id.cam
#            AND id2.idform = id.idform
#    /;
#
#    my @redes = $inf_db->db->array_hash($sql);
#
#    # get folders
#
#    $sql = qq/
#        SELECT pathfullname
#        FROM   harpathfullname
#        WHERE  pathfullnameupper LIKE '\\$cam\\ORACLE%'
#    /;
#
#    my @folders = $har_db->db->array_hash($sql);
#
#    $sql = qq/
#        SELECT bdeora.ora_entorno   entorno,
#            bdeora.ora_redes     red,
#            bdeora.ora_fullname  carpeta,
#            bdeora.ora_instancia instancia,
#            bdeora.ora_desplegar
#        FROM   bde_paquete_oracle bdeora
#        WHERE  bdeora.ora_prj = '$cam'
#        ORDER  BY 1,
#                2,
#                3,
#                4
#    /;
#
#    my @AoH = $har_db->db->array_hash($sql);
#
#    my $resolver = BaselinerX::Ktecho::INF::Resolver->new(
#        {   cam     => 'SCT',
#            sub_apl => 'soy una sub_apl',
#            entorno => 'T'
#        }
#    );
#
#    for my $ref (@AoH) {
#
#        # Parto por trozos...
#        my ( $foo, $user, $valor ) = split( /_/, $ref->{instancia} );
#
#        if ( $valor =~ m/([\$\[|\$\{].*?[\]|\}])/ ) {
#            while ( $valor =~ m/([\$\[|\$\{].*?[\]|\}])/ ) {
#                my $value = $resolver->get_solved_value($valor);
#                $valor =~ s/([\$\[|\$\{].*?[\]|\}])/$value/;
#            }
#            $ref->{instancia} = "$user en $valor";
#        }
#    }
#
#    # INSTANCIAS #
#
#    $sql = qq/
#        SELECT entorno,
#            red,
#            propietario owner,
#            instancia
#        FROM   inf_cam_orainst
#        WHERE  cam = 'SCT'
#        ORDER BY 1,
#                2,
#                3
#    /;
#
#    my @data = $har_db->db->array_hash($sql);
#
#    for my $ref (@data) {
#        my $valor = $ref->{instancia};
#
#        if ( $valor =~ m/([\$\[|\$\{].*?[\]|\}])/ ) {
#            while ( $valor =~ m/([\$\[|\$\{].*?[\]|\}])/ ) {
#                my $value = $resolver->get_solved_value($valor);
#                $valor =~ s/([\$\[|\$\{].*?[\]|\}])/$value/;
#            }
#            $ref->{instancia} = $valor;
#        }
#    }
#
#    $c->stash->{data}     = \@data;
#    $c->stash->{AoH}      = \@AoH;
#    $c->stash->{entornos} = \@entornos;
#    $c->stash->{redes}    = \@redes;
#    $c->stash->{folders}  = \@folders;
#    $c->stash->{template} = 'form/oratabla1.html';
#    $c->forward('View::Mason');
#
#    return;
#}

#sub prueba : Local {
#    my ( $self, $c ) = @_;
#
#    my $p = $c->request->parameters;
#
#    open my $file, '>', 'C:\dumper.txt';
#    use Data::Dumper;
#    print {$file} Dumper $p;
#
#    my $cam             = $p->{cam};
#    my $fid             = $p->{fid};
#    my $i_entorno       = $p->{i_entorno};
#    my $i_red           = $p->{i_red};
#    my $i_owner         = $p->{i_owner};
#    my $i_instancia     = $p->{i_instancia};
#    my $d_visible       = $p->{d_visible};
#    my $i_visible       = $p->{i_visible};
#    my $fullname        = $p->{fullname};
#    my $f_entorno       = $p->{f_entorno};
#    my $f_red           = $p->{f_red};
#    my $f_folder        = $p->{f_folder};
#    my $f_instancia     = $p->{f_instancia};
#    my $option          = $p->{option};
#    my $valor           = q{Si};
#    my $usuario_potente = 1;
#
#    $cam = 'SCT';
#
#    my @entornos_redes = $c->model('Form::OraProjects')->get_entornos_redes($cam);
#    my @entornos       = $c->model('Form::OraProjects')->get_entornos($cam);
#    my @redes          = $c->model('Form::OraProjects')->get_redes($cam);
#
#    my $args_ref       = $c->model('Form::OraProjects')->get_has_entornos_redes( \@entornos_redes );
#    my $has_entornos   = $args_ref->{has_entornos};
#    my $has_redes      = $args_ref->{has_redes};
#
#    # GET OWNERS
#    my @owners = ();
#    if ( $i_red and $i_entorno ) {
#        @owners = $c->model('Form::OraProjects')->get_owners(
#            {   cam       => $cam,
#                i_red     => $i_red,
#                i_entorno => $i_entorno
#            }
#        );
#    }
#
#    my @instancias      = $c->model('Form::OraProjects')->get_instancias( $i_entorno, $cam );
#    my @table_estancias = $c->model('Form::OraProjects')->get_configurar_estancias_table($cam);
#    my @folders         = $c->model('Form::OraProjects')->get_folders($cam);
#
#    my @entornos_filtered;
#    if ( $f_entorno and $f_red and $f_folder ) {
#        @entornos_filtered = $c->model('Form::OraProjects')->get_entornos_redes( $cam, $f_entorno );
#    }
#
#    my @tabla_despliegue = $c->model('Form::OraProjects')->get_tabla_config_despliegue($cam);
#
#    if ( $option eq 'DISTRIBUTION' ) {
#        $d_visible = 'visible';
#        $i_visible = 'hidden';
#    }
#    else {
#        $d_visible = 'hidden';
#        $i_visible = 'visible';
#    }
#
#    # Send parameters to Mason...
#    $c->stash->{i_entorno}         = $i_entorno;
#    $c->stash->{i_red}             = $i_red;
#    $c->stash->{i_owner}           = $i_owner;
#    $c->stash->{f_entorno}         = $f_entorno;
#    $c->stash->{f_red}             = $f_red;
#    $c->stash->{f_folder}          = $f_folder;
#    $c->stash->{f_instancia}       = $f_instancia;
#    $c->stash->{usuario_potente}   = $usuario_potente;
#    $c->stash->{has_entornos}      = $has_entornos;
#    $c->stash->{has_redes}         = $has_redes;
#    $c->stash->{cam}               = $cam;
#    $c->stash->{fullname}          = $fullname;
#    $c->stash->{i_visible}         = $i_visible;
#    $c->stash->{d_visible}         = $d_visible;
#    $c->stash->{option}            = $option;
#    $c->stash->{entornos_redes}    = \@entornos_redes;
#    $c->stash->{entornos}          = \@entornos;
#    $c->stash->{table_estancias}   = \@table_estancias;
#    $c->stash->{entornos}          = \@entornos;
#    $c->stash->{redes}             = \@redes;
#    $c->stash->{instancias}        = \@instancias;
#    $c->stash->{folders}           = \@folders;
#    $c->stash->{owners}            = \@owners;
#    $c->stash->{entornos_filtered} = \@entornos_filtered;
#    $c->stash->{tabla_despliegue}  = \@tabla_despliegue;
#    $c->stash->{template}          = 'form/ora_projects2.html';
#    $c->forward('View::Mason');
#
#    return;
#}

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
  my @grid_ins =
    $c->model('Form::OraProjects')->get_configurar_estancias_table($cam);

  $c->stash->{json} = {grid_ins => \@grid_ins};
  $c->forward('View::JSON');
  return;
}

sub grid_despliegue : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my @tabla_despliegue =
    $c->model('Form::OraProjects')->get_tabla_config_despliegue($cam);

  $c->stash->{json} = {data => \@tabla_despliegue};
  $c->forward('View::JSON');
  return;
}

sub grid_instancia : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $data =
    $c->model('Form::OraProjects')->get_configurar_estancias_table($cam);

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
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;
  my $env = $p->{env};
  my $data =
    $c->model('Form::OraProjects')->get_entornos_filtered($cam, $env);

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
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;
  $p->{cam} = $cam;
  my $data = $c->model('Form::OraProjects')->get_owners($p);

  $c->stash->{json} = {data => $data};
  $c->forward('View::JSON');
  return;
}

sub delete_des : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->params;
  $p->{ora_prj} = $cam;

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

  _log "\$p => " . Data::Dumper::Dumper $p; # XXX

  $c->model('Form::OraProjects')->add_instancia($p);

  return;
}

sub delete_ins : Local {
  my ($self, $c) = @_;
  my $cam = $c->request->parameters->{cam};
  my $p   = $c->request->parameters;
  $p->{cam} = $cam;

  $c->model('Form::OraProjects')->delete_ins($p);

  return;
}

1;

