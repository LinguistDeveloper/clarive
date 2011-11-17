package BaselinerX::Service::NET::Prepare;
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

has 'suffix', is => 'ro', isa => 'Str', default => sub {'.NET'};
has 'subapl_check', is => 'ro', isa => 'Any', lazy_build => 1;

with 'Baseliner::Role::Service';

register 'service.net.prepare' => {
  name    => '.NET Prepare',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job         = $c->stash->{job};
  my $bl          = $job->job_data->{bl};
  my $log         = $job->logger;
  my $Sufijo      = $self->suffix;
  my @elements    = $self->_elements($job->job_stash->{elements}->{elements});
  my $packages    = BaselinerX::Model::Distribution->job_package_list($job->{jobid});
  my $EnvironmentName  = substr($job->job_stash->{elements}->{elements}->[0]->{package}, 0, 3);
  my $Entorno     = $job->job_data->{bl};
  my $Pase        = $job->job_data->{name};
  my $PaseDir     = $job->job_stash->{path};
  my $PaseToState = [values %{$job->job_stash->{rollback}->{transition}->{to_state}}]->[0];
  $job->job_stash->{to_state} = $PaseToState;    # This might be handy...
  my %params;
  my $harvest_db = BaselinerX::CA::Harvest::DB->new();
  my $HarvestState = bl_statename($Entorno);
  my $TipoPase = $job->job_data->{type};

#  my ($TipoPase) = @_;
#  my %Elements   = paseElements($Pase, $TipoPase, $Entorno, ".NET");

#=for TODO 
##    ### SQA
##    if ($PaseNodist)
##    {
##        if ($Sufijo ne $natureNodist)
##        {
##            $log->info "Naturaleza $Sufijo omitida para el pase.  Solo $natureNodist";
##            return 1;
##        }
##        $log->debug "Filtrando elementos del pase a la subaplicación " . $subappNodist;
##        filterElements(\%Elements, $subappNodist, $natureNodist);
##    }
##    ### FIN SQA
#=cut


  if (scalar @elements) { #if (%Elements) {

      my %Elements = 
        map +($_->{versiondataobjid} =>
              { FileName        => $_->{fullpath} =~ /\/.+\/(.+)/
              , ObjectName      => do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /(.+)\./; uc($1) }
              , PackageName     => $_->{package}
              , SystemName      => undef
              , SubSystemName   => undef
              , DSName          => 'INTERNA',  # TODO
              , Extension       => do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /\./ ? do { $_->{fullpath} =~ /\/.+\/(.+)/; $1 =~ /\.(.+)/ } : undef }
              , ElementState    => $_->{tag}
              , ElementVersion  => $_->{version}
              , ElementPriority => ' '
              , ElementPath     => $_->{path}
              , ElementID       => $_->{versiondataobjid}
              , ParCompIni      => ' '
              , NewID           => undef
              , HarvestProject  => $EnvironmentName
              , HarvestState    => $HarvestState
              , HarvestUser     => $_->{modifier}
              , ModifiedTime    => $_->{modified_on}
              , project         => $EnvironmentName
              , subapl          => _pathxs($_->{fullpath}, 3)
              }
            ), @elements;

            # _log Data::Dumper::Dumper \%Elements;

    # logstart($Pase, "NET");
    # setNaturaleza($Pase, $Sufijo);  # TODO ¿Esto hace falta?
#    $NATS{$Sufijo} = 1;
#    logElements(\%Elements);
#    $log->info "Inicio del procesamiento elementos .NET (Tipo=$TipoPase).";

    # logsection "Preparación";

    # solo se permite 1 unica release por pase
    my $Release  = "";
    my @Packages = @{$packages};
    # my @Packages = getPackagesFromElements(\%Elements);
    my %ENVS;

#    foreach my $pkg (@Packages) {
#      my ($EnvironmentName, $StateName) = getPackageInfo($pkg);
#      $ENVS{$EnvironmentName} = "";
#
#      # MIRO EL GRUPO DE PACKAGES PARA SABER EL NOMBRE DE LA RELEASE PARA EL SNAPSHOT DE PROD
#      # los pkggrps son el nombre de release de una aplicación
#      my @pkggrps = getPackageGroups($pkg);
#      if (@pkggrps > 0 && $Entorno eq "PROD") {
#        $Release = shift @pkggrps;
#      }
#    }

    # c/o y deploy en cada aplicacion
    # for my $EnvironmentName (keys %ENVS) {

      # semUp($Pase, "$Entorno-$Sufijo");  # TODO SEM
      my %subApplications = _projects_from_elements(\%Elements, $EnvironmentName);
      $log->debug("Subaplicaciones detectadas:" . join(",", keys %subApplications));
      my ($cam, $CAM) = get_cam_uc($EnvironmentName);

      # TODO this should be another service
#      unless ($PaseNodist) {
#        # SCRIPTS PRE
#        scriptsPre($EnvironmentName, $Entorno, ".NET");
#      }

#=for checkout
#      # CHECKOUT DE TODAS SUBAPL
#      $log->debug("Haciendo checkout con los siguientes datos: $EnvironmentName, $EntornoEstado{$Entorno},$Sufijo");
#      my $coState;
#      $coState = $EstadoCheckout{$PaseToState} or $coState = $EntornoEstado{$Entorno};
#      my $checkedout = checkOutStateDirect($EnvironmentName, $coState, $Sufijo);
#
#      if (($Vista =~ m/DESA/i) or ($TipoPase eq "E") or ($PaseToState =~ m/Correctivo/i)) {
#        my ($NEW, $DEL) = checkOutElements(\%Elements, $EnvironmentName);
#        $checkedout += @$NEW;
#        $checkedout += @$DEL;
#      }
#
#      if ($checkedout eq 0) {
#        $log->warn("No hay elementos disponibles (0 checkouts) para pasar en la aplicación '$EnvironmentName'.");
#        next;
#      }
#=cut
      my %dummy = ();

#      footprintElements(\%Elements, $PaseDir, $EnvironmentName, $Entorno, "$Sufijo", $Usuario, \%dummy);

#      renameElements($PaseDir, $EnvironmentName, $Entorno, "$Sufijo");

      # BUCLE SUBAPL
      for my $subApplication (keys %subApplications) {
        $log->info("Tratando subaplicacion $subApplication");

#=for TODO SQA
#        ## SQA - 28/03/2011
#        if ($ENV{SQA_ACTIVO}) {
#          my $run_sqa = `perl $ENV{UDPHOME}/getSQAValue.pl $CAM $Entorno .NET $subApplication config.sqa.run_sqa`;
#
#          $log->debug("<b>SQA</b>: Ejecutar sqa para $CAM $Entorno .NET $subApplication : $run_sqa");
#
#          if ($run_sqa eq 'Y' || $PaseNodist) {
#            my $sources = ();
#            push @{$sources}, $subApplication;
#            my $hashData = {subproject => $subApplication, nature => '.NET', sources => $sources};
#            $jobinfo->add_subproject(project => $EnvironmentName, data => $hashData);
#            $sources = undef;
#            $log->info("<b>SQA</b>: Contenido añadido al fichero de SQA", Dump($jobinfo));
#          }
#          if ($run_sqa eq 'N') {
#            $log->debug("<b>SQA</b>: No se ha añadido la subaplicación $subApplication para analizar la calidad por configuración (run_sqa = 'N')");
#          }
#        }
#        ## FIN SQA
#=cut

        $harvest_db->set_subapl($Pase, $subApplication);
        # setSubapl($Pase, $subApplication);

#=for TODO
#        if (($TipoPase eq "B") and ($Entorno eq "PROD")) {
#          logsection "Backout";
#
#          # false, da igual y sigo; true, pase se interrumpe si no tiene backup pa hacer el restore
#          my ($sigoSinRestore) = getInf($EnvironmentName, "SCM_SEGUIR_SIN_BACKUP");
#          my $inf = BaselinerX::Model::InfUtil->new({cam => 'SCT'});
#          my $sigoSinRestore = $inf->get_inf(undef, [{column_name => 'SCM_SEGUIR_SIN_BACKUP'}]);
#          try {
#            restoreNET($EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subApplication);
#
#            # al siguiente cam
#            next;
#          }
#          catch {
#
#            # Stop dist
#            if (!$sigoSinRestore eq "Si") {
#              _throw "Pase de backout terminado por no disponer del backup de la versión anterior (aplicación $CAM configurada para no permitir marcha atrás sin backup anterior): " . shift();
#            }
#            else {
#              $log->warn("Backout no ha podido utilizar backup de la aplicación $CAM. La marcha atrás continúa recompilando versión anterior en Harvest.", . shift());
#            }
#          };
#        }
#=cut

        my $dist =
          BaselinerX::Model::NET::Dist->new(cam          => $EnvironmentName,
                                            log          => $log,
                                            tipo_pase    => $TipoPase,
                                            pase_no_dist => 0);

        for my $PaseRed (qw/LN/) {
          $dist->netBuild(\%Elements, $Pase, $PaseDir, $PaseRed, $EnvironmentName, $Entorno, $Sufijo, $subApplication, $PaseRed, $TipoPase, @Packages);
        }

#        unless ($PaseNodist) {
#
#          # ROG 3/2009: para utilizar el nombre de release en Snapshot
#          $Release = $Dist{release};
#        }
      }

#=for POST
      ## SCRIPTS POST
#            unless ($PaseNodist)
#            {
#                scriptsPost($EnvironmentName, $Entorno, ".NET");
#            }
#=cut

      # semDown($Pase, "$Entorno-$Sufijo");  # TODO sem
      #}

    # logstart $Pase, "DIS";
  }
  else {
    $log->info("No hay elementos .NET.");
  }
}

sub _elements {
  my ($self, $ls) = @_;
  filter_elements(elements => $ls, 
                  suffix   => $self->suffix);
}

1;
