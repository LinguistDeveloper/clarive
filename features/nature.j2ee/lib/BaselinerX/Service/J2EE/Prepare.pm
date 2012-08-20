package BaselinerX::Service::J2EE::Prepare;
use 5.010;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Data::Dumper;
use utf8;
use YAML;

has 'suffix',       is => 'ro', isa => 'Str',  default    => sub { 'J2EE' };
has 'subapl_check', is => 'ro', isa => 'Any',  lazy_build => 1;

with 'Baseliner::Role::Service';

register 'service.j2ee.prepare' => {
  name    => 'J2EE Prepare',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $bl       = $job->job_data->{bl};
  my $log      = $job->logger;
  my $suffix   = $self->suffix;
  my @elements = $self->j2ee_elements($job->job_stash->{elements}->{elements});
  my $packages = BaselinerX::Model::Distribution->job_package_list($job->{jobid});
  my $env_name = substr($job->job_stash->{elements}->{elements}->[0]->{package}, 0, 3);
  my $env      = $job->job_data->{bl};
  my $pass     = $job->job_data->{name};
  my $path     = $job->job_stash->{path};
  my $to_state = [values %{$job->job_stash->{rollback}->{transition}->{to_state}}]->[0];
  $job->job_stash->{to_state} = $to_state;  # This might be handy...
  my %params;
  my $harvest_db = BaselinerX::CA::Harvest::DB->new();

  if (scalar @elements) {
    $log->info('Inicio de distribución de elementos J2EE');
    $log->debug("Listado elementos de pase J2EE:\n" . 
                join("\n", map($_->{fullpath},
                               grep($_->{fullpath} =~ /$suffix/i, 
                                    @elements))));
  }
  else { 
    _throw "No existen elementos J2EE";
  }

  scalar @$packages
    ? $log->debug("Listado de paquetes del pase:\n" . join("\n", @{$packages}))
    : _throw "¡No hay paquetes!";

  unless ("/home/aps/was/scripts/gen/${env_name}/j2eeTools${env_name}.sh") {  # Does this ever fail?
    my $err = "Error al iniciar el pase: No tengo el script de despliegue configurado en el formulario de infraestructura (campo ${env}_SCRIPT_DESPLIEGUE)";
    $log->error($err);
    _throw $err;
  }

  my $loc_config = "/home/grp/was/j2eeaps/$env_name/config/";
  $log->debug("\$loc_config => $loc_config");

  my %hdist = {
    JDK => q{}, 
    PUB => (sub { BaselinerX::Model::InfUtil->new(cam => shift)->is_public_bool })->($env_name) 
  };
  $log->debug($hdist{JDK} eq q{} ? "JDK no configurado" : $hdist{JDK});
  $log->debug($hdist{PUB} == 0 ? "$env_name no es pública" : "$env_name es pública");

  my $HarvestState = bl_statename($env);
  $log->debug("\$HarvestState => $HarvestState");

  # Sub-apl listing
  my $build_home = "$path/$env_name/$suffix";
  $log->debug("\$build_home => $build_home");

  # Check for Eclipse projects.
  $log->warn("Ignorado $env_name. No hay proyectos Eclipse (con ficheros .project) en el directorio $build_home")
    unless (glob "$build_home/*/.project");

  my %data = 
    map +($_->{versiondataobjid} =>
          { FileName        => $_->{fullpath} =~ /\/.+\/(.+)/
          , ObjectName      => do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /(.+)\./; uc($1) }
          , PackageName     => $_->{package}
          , SystemName      => undef
          , SubSystemName   => undef
          , DSName          => do { my @a = _pathxs($_->{path}); join '\\', @a[3..$#a] }
          , Extension       => do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /\./ ? do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /\.(.+)/ } : undef }
          , ElementState    => $_->{tag}
          , ElementVersion  => $_->{version}
          , ElementPriority => ' '
          , ElementPath     => $_->{path}
          , ElementID       => $_->{versiondataobjid}
          , ParCompIni      => ' '
          , NewID           => undef
          , HarvestProject  => $env_name
          , HarvestState    => $HarvestState
          , HarvestUser     => $_->{modifier}
          , ModifiedTime    => $_->{modified_on}
          , project         => _pathxs($_->{path}, 3)
          , subapl          => do { my $a = _pathxs($_->{path}, 3); my $ret; if ($a =~ /(.+)_BATCH$/) { $ret = $1; } else { $ret = $a; } $ret; }
          , Element         => $_->{fullpath} =~ /\/.+\/(.+)/
          }
         ), @elements;

  my @subapls;

  my %projects  = _projects_from_elements(\%data, $env_name);
  
  _log "\nprojects => " . Data::Dumper::Dumper \%projects;

  $log->debug("Inicio de verificación de subapls j2ee en '$build_home' para los proyectos: " . join ', ', keys %projects);

  my $dist = BaselinerX::Model::J2EE::Dist->new(log => $log);

  my $subapl_types = $dist->workspace_subapls($build_home, keys %projects);
  
  my @subapl_from_ears = @{$subapl_types->{ears} || []};
  my @subapl_from_jars = @{$subapl_types->{jars} || []};
  my @subapl_j2ee_java = _unique @subapl_from_ears, @subapl_from_jars;
  $log->info("Subaplicaciones detectadas en el workspace: " . join ', ', @subapl_j2ee_java);

  # Check job sub-apls.
  my %inf_subapl;
  my $is_checkeable = $self->_is_checkeable($env_name);
  $log->debug("\$is_checkeable => $is_checkeable");

  if ($is_checkeable) {
    $log->debug("SUBAPL_CHECK = (" . $self->subapl_check . "): Se verificará si las subaplicaciones del pase están definidas en el formulario de inf. de la aplicación '$env_name'");
    %inf_subapl = map { $_ => 1 } (sub { my $cam = shift; my $inf = BaselinerX::Model::InfUtil->new(cam => $cam); ($inf->get_inf_sub_apl('J2EE'), $inf->get_inf_sub_apl('IASBATCH')) })->($env_name);
    
    _log "\ninf_subapl:" . Data::Dumper::Dumper \%inf_subapl;
    
    $log->debug("Subaplicaciones definidas en el formulario de infraestructura para '$env_name': " . (join ', ', keys %inf_subapl));
    for my $ref (@subapl_j2ee_java) {
      if ($ref && $inf_subapl{$ref}) {
        $log->debug("Subaplicación $ref definida en el formulario de infraestructura.");
        push @subapls, $ref;
      }
      else {
        $log->debug("Se ignorará la subaplicación $ref al no estar definida en el formulario de infraestructura");
      }
    }
  }
  else {
    $log->debug("Se incorporarán todas las subaplicaciones de este pase (variable SUBAPL_CHECK nula)");
    @subapls = @subapl_j2ee_java;
    $harvest_db->set_subapl($pass, $_) foreach @subapls;
    
    _log "\n\nparams antes de comprobación IAS: " . Data::Dumper::Dumper \%params;

    # Is it defined as IAS?
    my $inf = BaselinerX::Model::InfUtil->new(cam => $env_name);
    for my $ref (@subapls) {
      if ($inf->inf_es_IAS($env_name, $ref)) {
      	$params{IAS} = 1;
      	last;
      }
    }
    
    _log "\n\nparams después de comprobación IAS: " . Data::Dumper::Dumper \%params;

    # Batch?
    $params{IAS} ||= grep /_BATCH$/, keys %projects;
    
    _log "\n\nparams tras hacer grep: " . Data::Dumper::Dumper \%params;
    _log "\n\ndump de projects: " . Data::Dumper::Dumper \%projects;
    
    $log->info("Atributos especiales de aplicación: " . join(', ', keys %params)) if keys %params;
  }

  # Backout!
  if ($job->job_data->{type} eq 'demote') {
    my $no_restore = 0;  # This makes no sense!
    try {
      $log->info("Recuperación: Subaplicaciones detectadas para el pase:" . join ', ', keys %projects);
      for my $sub_apl (keys %projects) {
        $harvest_db->set_subapl($pass, $sub_apl);
        $dist->restoreWEB($env_name, $env, $self->suffix, $pass, $path, $sub_apl, %params);
      }
      $harvest_db->dist_entornos_write(cam      => $env_name,
                                       entorno  => $env,
                                       envname  => $env_name,  # check this, it's probably not the env but this whole 'Desarrollo' thing
                                       ciclo    => 'R',
                                       vista_co => $env,
                                       nivel    => 'EAR');
      next;
    }
    catch {
      unless ($no_restore) {  # But it doesn't ever change???
        _throw "Pase de backout terminado por no disponer del EAR de la versión anterior (aplicación $env_name configurada para no permitir marcha atrás sin EAR anterior): " . shift();
      }
      else {
        $log->warn("Backout no ha podido utilizar el ear de backup de la aplicación $env_name. Marcha atrás sigue, pero recompilando versión en Harvest");
      }
    };
  }

  # Files
  _log "\nLlamando a hardistXML ...\n";
  my %inclusions = hardistXML($log, "IN-EX", $path, $env, $env_name, $self->suffix);
  _log "\n\ninclusions: " . Data::Dumper::Dumper \%inclusions;
  my $precompilacion = 'N';

  # footprintElements already done!
  # renameElements already done!

  if ($params{IAS}) {
    my $IAS_dir_pass = "'$path/$env_name/" . $self->suffix . "'/???*_SCM";
    $log->debug("Directorio pase IAS => $IAS_dir_pass");
    my $IAS_dir_dest = "$path/$env_name/$env/" . $self->suffix . "/.";
    $log->debug("Directorio destino IAS => $IAS_dir_dest");
    my $cmd = "ls $IAS_dir_pass 2>/dev/null";
    _log "\ncmd: $cmd\n";

    my $ls_cmd = "ls $path/$env_name/" . $self->suffix;
    _log "ls_cmd $ls_cmd";
    my @ls_ret = `$ls_cmd`;
    _log "\n\nls_ret: " . Data::Dumper::Dumper \@ls_ret;

    my @ret = `$cmd`;
    _log "\n\nretorno: " . Data::Dumper::Dumper \@ret;

    if ((my @iaspase = `$cmd`) > 0) {
      my $cmd_ret = "cp -Rf $IAS_dir_pass/" . "$IAS_dir_dest" . " 2>&1";
      _log "\ncmd: $cmd_ret\n";
      my @RET = `cp -Rf $IAS_dir_pass/. "$IAS_dir_dest" 2>&1`;
      if ($? ne 0) {
        $log->warn("IAS: no ha sido posible copiar los ficheros del directorio '$IAS_dir_pass' a '$IAS_dir_dest'", join('', @RET));
      }
      $log->info("IAS: directorio de pase '$IAS_dir_pass' copiado a '$IAS_dir_dest'", join('', @RET));
    }
    else {
      $log->warn("IAS: directorio de pase no existe o está vacío '$IAS_dir_pass'. Copia ignorada");
    }

    # TODO
    # PONGO EL SEMAFORO PARA QUE NO HAYA DISTRIBUCION PLUGIN ECLIPSE
    #  semUp($Pase, "$Entorno-ECLIPSE");  NO
    ## GENERAR proyecto de pase - parte de eclipseDist.pm
    _log "\n\nInstancio dispatcher eclipse...\n";
    my $eclipse_dist = BaselinerX::Model::Eclipse::Dist->new(log => $log, pase => $pass);
    _log "\n\nLlamo a generaProyectoPase...\n";
    my ($pGen, $pDir) = $eclipse_dist->generaProyectoPase(\%data, $path, $env_name, $env, $self->suffix, "", "J2EE");
    _log "\n\nOK!\n";
    my @generado = ();
    @generado = @{$pGen};    ## listado de proyectos generados
    my @dirpase = ();
    @dirpase = @{$pDir};     ## listado de proyectos con directorio de pase _SCM
    $log->info("<li>Proyectos _WEB precompilados IAS: @generado");;

    # QUITO EL SEMAFORO PARA DISTRIBUCION PLUGIN ECLIPSE
    #  semDown($Pase, "$Entorno-ECLIPSE");
    $precompilacion = 'S';
  }

  # meter esto en un servicio!
  ## SCRIPTS PRE
  # TODO SQA
  # unless ($PaseNodist){
  # BaselinerX::Model::ScriptsPrePost->new(log      => $log,
  #                                        pass     => $pass, 
  #                                        step     => 'PRE', 
  #                                        suffix   => $suffix,
  #                                        env      => $env,
  #                                        env_name => $env_name)->initialize;
  # }                                         

  my %estado_vista    = %{&config_get('config.bde.estado_vista')};
  my %estado_checkout = %{&config_get('config.bde.estado_checkout')};
  my %entorno_estado  = %{&config_get('config.bde.entorno_estado')};

  ## Estructura de retorno:
  my %DIST = ();
  $DIST{pase}         = $pass;
  $DIST{pasedir}      = $path;
  $DIST{entorno}      = $env;
  $DIST{sufijo}       = $self->suffix;
  $DIST{envname}      = $env_name;
# $DIST{tipopase}     = $job->job_data->{type};
  $DIST{tipopase}     = substr($pass, 0, 1);
  $DIST{subapl_check} = $is_checkeable;
  $DIST{inf_subapl}   = \%inf_subapl;
  $DIST{buildhome}    = $build_home;
  $DIST{cam}          = lc($env_name);
  $DIST{CAM}          = uc($env_name);
  $DIST{vista_co}     = $estado_vista{$estado_checkout{$to_state} || $entorno_estado{$env}};
  $DIST{ciclo}        = ($to_state =~ m/Correctivo/i ? 'C' : 'N');
  $DIST{PrecompIAS}   = $precompilacion eq 'S' ? 'S' : 'N';
  $DIST{nodist}       = 0;  # XXX
  # $DIST{nodist}       = $PaseNodist;  # TODO

  ## IAS-BATCH
  my @proyectos_batch;
  my $ias_batch_activo = config_get('config.bde')->{ias_batch_activo};
  if ($ias_batch_activo) {
    @proyectos_batch =
     BaselinerX::J2EE::IAS->ias_batch_build($log,
                                            {dist     => \%DIST,
                                             elements => \%data,
                                             params   => \%params});
    $params{proyectos_ignorar}{$_} = 1 foreach (@proyectos_batch);
  }

  ## BUILD
  $dist->webBuild(\%DIST, \%data, \%params);
  _log "Configuración final de despliegue" . Data::Dumper::Dumper \%DIST;
  $log->debug("Configuración final de despliegue", Dumper \%DIST);
  $log->debug("Proyectos procesados: " . join(',', @{$DIST{prjlist}})) if ($DIST{prjlist} && @{$DIST{prjlist}});
  $log->debug("Archivos creados: " . join(',', @{$DIST{genfiles}})) if ($DIST{genfiles} && @{$DIST{genfiles}});

  # TODO SQA

  # DEPLOY
  _log "Deployment...";

  if (_bde_conf 'ias_batch_activo') {
    _log "ias activo, llamamos a ias_batch_dist...";
    BaselinerX::J2EE::IAS->ias_batch_dist($log,
                                          {dist      => \%DIST,
                                           elements  => \%data,
                                           params    => \%params,
                                           proyectos => \@proyectos_batch});
    _log "everything ok!";
  }

  # ficheros de configuración no tienen genfiles.
  $log->debug("Comprobando si los ficheros de configuracion tienen genfiles...");
  if ((!$DIST{genfiles}) || (!@{$DIST{genfiles}})) {    
    $log->warn("No hay ficheros J2EE generados en la construcción. Distribución J2EE terminada.");
  }
  else {
    ## PUBLICA
    if ($params{PUB}) {
      _log "La aplicacion es publica";
      _log "Iniciando release...";
      my @release;
      my $har_db = BaselinerX::CA::Harvest::DB->new;
      _log "Llamando a get_package_groups...";
      push @release, $har_db->get_package_groups($_) foreach @{$packages};
      my %saw;
      @saw{@release} = ();
      _log "Ordeno release...";
      @release = sort keys %saw;    ##nombres de pkggroup unicos
      if (@release > 1) {
      	$log->error("Error: aplicación $env_name tiene más de una release (package group) asociada: " . join(', ', @release));
        _throw "Error: aplicación $env_name tiene más de una release (package group) asociada: @release";
      }
      elsif (!@release) {
      	$log->error("Error: aplicación $env_name no tiene una release asociada a los paquetes del pase");
      	_throw "Error: aplicación $env_name no tiene una release asociada a los paquetes del pase";
      }
      my $release = $release[0];
      $log->debug("Llamando a distribucion publica");
      # pubDist($path, $env_name, $env, "PUBLICO", $release, "J2EE");
      $c->launch('service.public.distribute', data => {path => $path, env_name => $env_name, env => $env, suffix => "PUBLICO", release => $release, tipos => "J2EE"});
    }
    elsif (($DIST{nivel} eq 'EAR') && (!@{$DIST{prjlist}})) {
      $log->warn("No tengo aplicaciones de empresa para generar un EAR para la aplicación '$env_name'.");
    }
    ## DEPLOY
    $DIST{pub} = $params{PUB};
    $dist->webDist(\%DIST);  # ???
    _log "Llamando a dist_entornos_write...";
    $harvest_db->dist_entornos_write(%DIST); # Meter esto en otro servicio?
    $log->debug("Registrado información histórica de despliegues", Dumper \%DIST);
  }
  ## SCRIPTS POST
  # scriptsPost($env_name, $env, "J2EE");

  return 1;
}

sub j2ee_elements {
  my ($self, $ls) = @_;
  filter_elements(elements => $ls, 
                  suffix   => $self->suffix);
}

sub _is_checkeable {
  my ($self, $env_name) = @_;
  my $subapl_check = $self->subapl_check;
  my $is_checkeable = $subapl_check eq '*'
                        ? 1
                        : $subapl_check
                            ? do { my %check_subapl = map { $_ => 1 } split /,/, $subapl_check; 
                                   $check_subapl{$env_name} }
                            : 0;
}

sub _build_subapl_check { config_get('config.bde')->{subapl_check} }

1;

__END__

=head1 Description

This is the first step for the J2EE distribution.

=head1 Usage

  $c->launch('service.j2ee.prepare');

Or basically do nothing since the runner is the one supossed to run it.

=cut
