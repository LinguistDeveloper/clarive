package BaselinerX::Model::J2EE::Dist;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
# use BaselinerX::Ktecho::CamUtils;
use Data::Dumper;
use Try::Tiny;

has 'bde_conf', is => 'rw', isa => 'HashRef', default => sub { config_get('config.bde') };
has 'log', is => 'ro', isa => 'Object', required   => 1;
has 'cam', is => 'rw', isa => 'Str';
# has 'inf', is => 'rw', isa => 'Object', lazy_build => 1;
has 'pass', is => 'ro', isa => 'Str';

my $balix_pool = BaselinerX::Dist::Utils::BalixPool->new;

# sub _build_inf { BaselinerX::Model::InfUtil->new(cam => shift->cam) }

my %PARAMS;
my %INSTAGING;
my %STA;             # Datos de staging.
my @antList;         # Listado de actividades de ant.
my %Dependencias;    # Dependencias de compilación.
my $Exito = 0;

sub _subapl
{
    my ($self, $subapl) = @_;
    $subapl =~ s{_*[A-Z|_]+$}{} if ($subapl ne uc($subapl));
    $subapl;
}

sub webBuild
{
    my $self     = shift;
    my $log      = $self->log;
    my $bde_conf = $self->bde_conf;

    local our %Dist;
    *Dist = shift();

    my %Elements = %{shift()};
    %PARAMS = %{shift()};

    my ($Pase, $PaseDir, $TipoPase, $EnvironmentName, $Entorno, $Sufijo) = ($Dist{pase}, $Dist{pasedir}, $Dist{tipopase}, $Dist{envname}, $Dist{entorno}, $Dist{sufijo});

    my ($cam, $CAM) = get_cam_uc($EnvironmentName);

    $self->cam($CAM);

    my %BUILDFILES;
    my (%EAR, %JAR, %WAR, %JARLIST, %EARLIST, %WARLIST, %EARFILES, %JARFILES, %EARPRJMAP);

    # RG: hay que resetear esto al principio, sino falla el rollback en mismo
    # pase por no llevar los elementos a staging (gdf 59042) obtengo las
    # opciones de compilación de la aplicación
    %INSTAGING = ();

    # TODO: esto debería estar en el formulario de Infraestructura

    my ($buildtype, $opt_javac) = ($bde_conf->{buildtype}, $bde_conf->{javac});
    my $opt_classpath;

    # DATOS DE STAGING
    my $inf = BaselinerX::Model::InfUtil->new(cam => $CAM);
    ($STA{maq}, $STA{puerto}, $STA{home}, $STA{user}) = $inf->get_staging_unix_active();

    die "Error de transferencia a Staging. No he encontrado datos de staging en la configuración SCM."
      if (!$STA{maq} or !$STA{puerto} or !$STA{home} or !$STA{user});
    $STA{buildhome} = "$STA{home}/pase/$Pase/$CAM/$Sufijo";

    # COMPROBACION DE APLICACIONES PUBLICAS OBSOLETAS
    my @apl_publicas_verobs = $inf->public_apps_j2ee($CAM);
    $log->debug("Aplicaciones publicas marcadas en el formulario: " . join ', ', @apl_publicas_verobs);
    my $verPublicaJ2EE = "";

    for my $verPublicaJ2EE (@apl_publicas_verobs)
    {
        $log->debug(" Comprobando version Publica $verPublicaJ2EE . Espere ..... ");
        my @EstadoVerPubJ2EE = $inf->obsolete_public_version($verPublicaJ2EE);
        my $ESTADO           = "";

        foreach $ESTADO (@EstadoVerPubJ2EE)
        {
            if ($ESTADO eq "Obsoleto")
            {
                $log->warn("La version publica $verPublicaJ2EE esta en estado OBSOLETO, por favor, actualice el formulario de la aplicacion");
            }
            elsif ($ESTADO eq "Borrado")
            {
                $log->warn("La version pública $verPublicaJ2EE ha sido borrada por los responsables de la aplicación si su pase hace uso de esta versión fallará el pase");
                $log->warn("Si necesita utilizar la versión pública $verPublicaJ2EE pongase en contacto con los Responsables de la aplicación");
            }
        }
    }

    # PUBLICAS CON CLASSPATH (NO IAS)
    my $pubver = $inf->get_inf(undef, [{column_name => 'J2EE_APL_PUB'}]);

    foreach my $pubv (@{$pubver})
    {
        next if ($pubv =~ /^IAS/);
        $opt_classpath .= "$STA{home}/$bde_conf->{pubname}/$pubv;";
    }

    # Quiero saber los proyectos web afectados:
    my %PRJS = _projects_from_elements(\%Elements, $EnvironmentName);
    my @PROYECTOS = keys %PRJS;

    # Quito los proyectos a ignorar, como los _BATCH:
    _log "Proyectos java a ignorar: " . join ', ', keys %{$PARAMS{proyectos_ignorar} || {}};
    $log->debug("Proyectos java a ignorar: ", join ', ', keys %{$PARAMS{proyectos_ignorar} || {}});
    @PROYECTOS = grep { !exists $PARAMS{proyectos_ignorar}{$_} } @PROYECTOS;

    # A lo mejor era solo IASBatch...
    if (@PROYECTOS)
    {
        $log->info("Proyecto(s) J2EE Identificado(s) para este pase: \n" . join("\n", @PROYECTOS));
    }
    else
    {
        $log->info("No se han detectado proyectos J2EE.");
        return 0;
    }

    # Investigo si hay build.xml, y utilizo el build encontrado en caso de que
    # haya.
    # hash de build.xml que corresponden a las subapls de este pase...
    my %buildfilesSUBAPL = ();
    my $cmd              = qq| find "$PaseDir/$CAM/$Sufijo" -name "build.xml |;
    _log "\nInvestigando si hay build.xml ...\ncmd: $cmd\n";
    my @buildfound = `$cmd`;
    @buildfound = _unique @buildfound;

    _log "\n\nbuilfound:" . Data::Dumper::Dumper \@buildfound;

    # El build.xml tiene que estar entre las subapl de los proyectos:
    foreach my $proy (@PROYECTOS)
    {
        my $subapl = $self->_subapl($proy);
        foreach (@buildfound)
        {
            if (/$PaseDir\/$CAM\/$Sufijo\/${subapl}_*[A-Z]+/)
            {
                if (!exists $buildfilesSUBAPL{$_})
                {
                    $log->info("Se utilizará el build.xml definido por el usuario (subaplicación '$subapl'): $_");
                    $buildfilesSUBAPL{$_} = 1;
                }
            }
            else
            {
                $log->debug("Descartado build.xml definido por el usuario (subaplicación '$subapl'): $_");
            }
        }
    }

    if ((keys %buildfilesSUBAPL) > 0)
    {
        _log "\nBuild proporcionado por el usuario.\n";
        $buildtype = "B";    # Build proporcionado por el usuario.

        foreach (keys %buildfilesSUBAPL)
        {
            chop;
            my $thisprojectname = $_;    # Nombre de proyecto eclipse de este build.xml
            $thisprojectname =~ s{^$PaseDir/$CAM/$Sufijo/(.*?)/.*$}{$1};
            my $buildhome = $_;
            $buildhome =~ s{^$PaseDir/$CAM/$Sufijo/(.*?)build.xml}{$1};
            $buildhome =~ s{/$}{};
            push @{$BUILDFILES{$thisprojectname}}, $buildhome;
            open BUI, "<$_";
            my @xmldata = <BUI>;
            close BUI;
            $log->info("Fichero build encontrado '$_' en el proyecto $thisprojectname (buildhome=$buildhome).", "@xmldata");
            my %props;
            $props{"was.lib"}    = "/home/aps/was/was6/lib";
            $props{"build.home"} = $STA{buildhome};
            $self->generateProps(\%props, "$PaseDir/$CAM/$Sufijo/$buildhome/build_harvest.properties");
            push @{$Dist{related_projects}{$self->_subapl($thisprojectname)}}, $thisprojectname;
        }
        foreach my $prj (keys %BUILDFILES)
        {    # Separado para que se envÃ­e a staging todo de golpe
            my $subapl = $self->_subapl($prj);    # Check if this is okay!
            _log "\nsubapl: $subapl\n";
            foreach my $buildhome (@{$BUILDFILES{$prj}})
            {
                $self->antBuild(\%Dist, "$buildhome/build.xml", "", $subapl, "clean build package", $buildtype);

                # En las publicas no trabajo con ficheros .ear
                if (!$PARAMS{PUB})
                {
                    my @EARANTPRJ = ();
                    if ($Dist{earant})
                    {

                        foreach my $earantfile (@{$Dist{earant}})
                        {
                            my $earantprj = $earantfile;
                            $earantprj =~ s/(.*?)\.ear/$1/g;
                            $log->debug("Proyecto EAR para el fichero $earantfile: $earantprj");

                            foreach my $paseprj (@PROYECTOS)
                            {
                                $log->info("Fichero EAR identificado para $paseprj: $earantprj\n");
                                push(@{$EARLIST{$earantprj}}, $paseprj);
                                $EARPRJMAP{$earantprj}{SUBAPL}   = $subapl;
                                $EARPRJMAP{$earantprj}{FILENAME} = $earantfile;
                                push @{$Dist{related_projects}{$subapl}}, $earantprj;
                            }
                            $EARFILES{$earantfile} = 1;
                        }
                    }
                }
            }
        }
        $Dist{nivel}   = 'EAR';
        $Dist{prjlist} = [keys %EARLIST];
        $Dist{files}   = [keys %EARFILES], $Dist{map} = \%EARPRJMAP;

        # Si fuera publica, sólo hay un fichero, 'publico.tar', que ya se ha
        # asignado a Dist{genfiles} en el antBuild{}:
        unless ($PARAMS{PUB})
        {
            $Dist{genfiles} = $Dist{earant};
        }
    }
    else
    {    # build.xml generado por Baseliner
        _log "\nTENGO QUE GENERAR EL BUILD.XML!\n";
        my $Workspace;
        try
        {
            _log "Instanciando workspace con buildhome: $Dist{buildhome}";
            $Workspace = BaselinerX::Eclipse::J2EE->parse(workspace => $Dist{buildhome});
        }
        catch
        {
            my $Workerr = shift();
            $log->error("Fallo al intentar parsear en los METADATOS. ", $Workerr);
            _throw "Error durante el parse del build.xml de J2EE.";
        };

        _log "\nDatos parseados.\n";

        my %SUBAPL;
        my @ANT = ();

        my @related_projects = $Workspace->getRelatedProjects(@PROYECTOS);

        # _log "related_projects :: " . Data::Dumper::Dumper \@related_projects; # OK

        _log "llamo a cutToSubset...";
        $Workspace->cutToSubset(@related_projects);

        _log "\nObteniendo EARS, WARS y EJBS...\n";
        my @EARS = $Workspace->getEarProjects();
        my @WARS = $Workspace->getWebProjects();
        my @EJBS = $Workspace->getEjbProjects();

        _log "EARS :: " . Data::Dumper::Dumper \@EARS;
        _log "WARS :: " . Data::Dumper::Dumper \@WARS;
        _log "EJBS :: " . Data::Dumper::Dumper \@EJBS;

        _log "\nLlamando a nivelDist...\n";
        my $nivel = $self->nivelDist(\%Dist, \%Elements, $Workspace, \@EARS, \@WARS, \@EJBS, @PROYECTOS);

        _log "\nnivel: $nivel\n";

        $log->info(
                   "Nivel de despliegue detectado: $nivel"
                     . (
                        $nivel ne 'EAR' && $self->earObligatorio($Entorno)
                        ? ", pero se generará un EAR (variable EAR_OBLIGATORIO=$bde_conf->{ear_obligatorio} )"
                        : ""
                       )
                  );

        $nivel = ($self->earObligatorio($Entorno) ? 'EAR' : $nivel);
        $Dist{nivel} = $nivel;

        # EAR
        if ($nivel eq 'EAR')
        {
            _log "qué vale el ear? :: " . Data::Dumper::Dumper \@EARS;
            foreach (@EARS)
            {
                $SUBAPL{$self->_subapl($_)} = $_;
            }
            $log->info("Subaplicaciones afectadas por el pase: " . join(', ', sort keys %SUBAPL));

            foreach my $subapl (keys %SUBAPL)
            {
                $opt_classpath .= $self->getClasspathWAS($CAM, $subapl, $Entorno);
                $opt_classpath .= ";";
                my $jdkVersion = $self->getJDKVersion($CAM, $Entorno, $subapl);
                $opt_javac = "source=\"$jdkVersion\"";

                my $earprj     = $SUBAPL{$subapl};
                my @SUBAPL_PRJ = $Workspace->getChildren($earprj);

                $log->info("Subaplicacion $subapl, Proyecto Ear=$earprj, Proyectos incluidos en el Ear= " . (join ', ', sort @SUBAPL_PRJ));

                my $buildxml = $Workspace->getBuildXML(
                    mode             => 'ear',
                    ear              => [$earprj],
                    classpath        => $opt_classpath,
                    javac_opts       => $opt_javac,
                    static_ext       => [$self->staticExtensions($EnvironmentName, $Entorno, $subapl, $nivel)],
                    static_file_type => 'tar',
                    projects         => [@SUBAPL_PRJ],
                    exclude          => qq{
                    <exclude name="**/hardist.xml" />
                    <exclude name="**/harvest.sig" />
                    <exclude name="**/.*" />
                },
                    ear_exclude => qq{
                    <exclude name="**/ibmconfig/**" />
                    <exclude name="**/application.xml" />
                 },
                );
                my $earfile            = $Workspace->genfile($earprj);
                my $buildfileBaseliner = "build_$subapl.xml";
                $buildxml->save($Dist{buildhome} . "/" . $buildfileBaseliner);
                $log->info("Fichero build.xml para la subaplicacion $subapl y los proyectos: " . (join ', ', @SUBAPL_PRJ), $buildxml->data);
                $log->info("Ficheros que se generarán en la construcción de $earprj: " . join ', ', $Workspace->genfiles());

                # BUILD
                my @OUTPUT = $Workspace->output();
                push @ANT, sub { $self->antBuild(\%Dist, $buildfileBaseliner, $earfile, $subapl, "clean build package", $buildtype, @OUTPUT); };

                # RETORNO
                $Dist{map}{$earprj}{SUBAPL}   = $subapl;
                $Dist{map}{$earprj}{FILENAME} = $earfile;
                $Dist{map}{$earprj}{WARS}     = [$Workspace->getWarsFromEAR($earprj)];
                $EARFILES{$earfile}           = 1;

                for ($Workspace->output())
                {
                    push(@{$Dist{tar}}, $_->{file}) if $_->{ext} eq 'TAR';
                }
                push @{$Dist{prjlist}},  $earprj;
                push @{$Dist{files}},    $earfile;
                push @{$Dist{genfiles}}, $Workspace->genfiles();

                $log->debug("Configuración de despliegue para $subapl: ", _dump(\%Dist));

                $Dist{related_projects}{$subapl} = [@SUBAPL_PRJ, $earprj];
            }
        }
        elsif ($nivel eq 'WAR')
        {
            $log->debug("Nivel $nivel: " . join ', ', @WARS);
            foreach my $war (@WARS)
            {
                if ($Dist{subapl_check})
                {    # El nombre del project xxx_WEB no indica la subapl, hay que chequear los nombres de los ears (p.ej.CLF)
                    my @EARS = $Workspace->getEarProjects($Workspace->getRelatedProjects($war));
                    $log->debug("Encontrado EARs relacionados al Proyecto Web '$war': " . join(', ', @EARS));
                    foreach my $ear (@EARS) { $SUBAPL{$self->_subapl($ear)} = $war }
                }
                else
                {
                    $SUBAPL{$self->_subapl($war)} = $war;
                }
            }
            $log->info("Subaplicaciones afectadas por el pase (WAR): " . join ', ', keys %SUBAPL);

            foreach my $subapl (keys %SUBAPL)
            {
                $opt_classpath .= $self->getClasspathWAS($CAM, $subapl, $Entorno);
                $opt_classpath .= ";";
                my $jdkVersion = $self->getJDKVersion($CAM, $Entorno, $subapl);
                $opt_javac = "source=\"$jdkVersion\"";

                # TODO: mirar si es nivel WAR-ContenidoEstatico o todo.
                my $warprj = $SUBAPL{$subapl};    # ej. cam_www_WEB
                my $buildxml = $Workspace->getBuildXML(
                    mode             => 'deps',
                    classpath        => $opt_classpath,
                    javac_opts       => $opt_javac,
                    static_ext       => [$self->staticExtensions($EnvironmentName, $Entorno, $subapl, $nivel)],
                    static_file_type => 'tar',
                    projects         => [$warprj],
                    exclude          => qq{
                    <exclude name="**/hardist.xml" />
                    <exclude name="**/harvest.sig" />
                    <exclude name=".*" />
                },
                );

                # BUILD.XML
                my $buildfileBaseliner = "build_$subapl.xml";
                $buildxml->save($Dist{buildhome} . "/" . $buildfileBaseliner);

                $log->info("Fichero $buildfileBaseliner para la subaplicacion $subapl y los proyectos: " . (join ', ', ($SUBAPL{$subapl})), $buildxml->data);
                $log->info("Ficheros que se generarán en la construcción: " . join ', ', $Workspace->genfiles());

                # BUILD
                my @OUTPUT = $Workspace->output();
                push @ANT, sub { $self->antBuild(\%Dist, $buildfileBaseliner, '', $subapl, "clean build package", $buildtype, @OUTPUT) };

                # OUTPUT
                my $warfile = $Workspace->genfile($warprj);
                $Dist{map}{$warprj}{SUBAPL}   = $subapl;
                $Dist{map}{$warprj}{FILENAME} = $warfile;
                push @{$Dist{map}{$warprj}{WARS}}, $warprj;

                for ($Workspace->output())
                {
                    push(@{$Dist{tar}}, $_->{file}) if $_->{ext} eq 'TAR';
                }
                push @{$Dist{prjlist}},  $warprj;
                push @{$Dist{genfiles}}, $Workspace->genfiles();

                $log->debug("Configuración de despliegue para $subapl: ", _dump(\%Dist));
            }
        }
        elsif ($nivel eq 'EJB')
        {
            $log->debug("Nivel EJB: " . join ', ', @EJBS);

            foreach my $ejb (@EJBS)
            {
                if ($Dist{subapl_check})
                {    # El nombre del project xxx_EJB no indica la subapl, hay que chequear los nombres de los ears (p.ej.CLF)
                    my @EARS = $Workspace->getEarProjects($Workspace->getRelatedProjects($ejb));
                    $log->debug("Encontrado EARs relacionados al Proyecto Ejb '$ejb': " . join(', ', @EARS));

                    foreach my $ear (@EARS)
                    {
                        $SUBAPL{$self->_subapl($ear)} = $ejb;
                    }
                }
                else
                {
                    $SUBAPL{$self->_subapl($ejb)} = $ejb;
                }
            }
            $log->debug("Subaplicaciones afectadas por el pase (EJB): " . join ', ', keys %SUBAPL);

            foreach my $subapl (keys %SUBAPL)
            {
                $opt_classpath .= $self->getClasspathWAS($CAM, $subapl, $Entorno);
                $opt_classpath .= ";";
                my $jdkVersion = $self->getJDKVersion($CAM, $Entorno, $subapl);
                $opt_javac = "source=\"$jdkVersion\"";

                my ($subapl) = sort keys %SUBAPL;    # Sólo puede ser una subaplicacion
                my $buildxml = $Workspace->getBuildXML(
                    mode             => 'single',
                    classpath        => $opt_classpath,
                    javac_opts       => $opt_javac,
                    static_ext       => [$self->staticExtensions($EnvironmentName, $Entorno, $subapl, $nivel)],
                    static_file_type => 'tar',
                    projects         => [@EJBS],
                    exclude          => qq{
                    <exclude name="**/hardist.xml" />
                    <exclude name="**/harvest.sig" />
                    <exclude name=".*" />
                },
                );

                # BUILD.XML
                my $buildfileBaseliner = "build_$subapl.xml";
                $buildxml->save($Dist{buildhome} . "/" . $buildfileBaseliner);
                $log->info("Fichero build.xml para la subaplicacion $subapl y los proyectos: " . (join ', ', @EJBS), $buildxml->data);
                $log->info("Ficheros que se generarán en la construcción: " . (join ', ', $Workspace->genfiles()));

                # BUILD
                my @OUTPUT = $Workspace->output();
                push @ANT, sub { $self->antBuild(\%Dist, $buildfileBaseliner, '', $subapl, "clean build package", $buildtype, @OUTPUT) };

                foreach my $ejbprj (@EJBS)
                {
                    my $ejbfile = $Workspace->genfile($ejbprj);

                    # RETORNO
                    $Dist{map}{$ejbprj}{SUBAPL}   = $subapl;
                    $Dist{map}{$ejbprj}{FILENAME} = $ejbfile;
                    $EARFILES{$ejbfile}           = 1;

                    for ($Workspace->output())
                    {
                        push(@{$Dist{tar}}, $_->{file}) if $_->{ext} eq 'TAR';
                    }
                    push @{$Dist{prjlist}},  $ejbprj;
                    push @{$Dist{files}},    $ejbfile;
                    push @{$Dist{genfiles}}, $Workspace->genfiles();
                }
                $log->debug("Configuración de despliegue para $subapl: ", _dump(\%Dist));
            }
        }
        elsif (($nivel eq 'CONF') || ($Dist{PrecompIAS} eq 'S'))
        {

            # Fichero de Config
            foreach my $warprj (@{$Dist{confwars}})
            {
                push @{$Dist{prjlist}}, $warprj;
                push @{$Dist{files}},   "$warprj/Config";
                $Dist{map}{$warprj}{SUBAPL}   = $self->_subapl($warprj);
                $Dist{map}{$warprj}{FILENAME} = "$warprj/Config";
                push @{$Dist{map}{$warprj}{WARS}}, $warprj;
                push @{$Dist{genfiles}}, "$warprj/Config";    # PRJMAP{$prj}{WARS}
            }
        }
        else
        {
            $log->error("No se ha podido determinar el nivel de despliegue (EAR, WAR o EJB).");
            _throw "Error durante la construcción de la aplicación";
        }
        &$_ foreach @ANT;                                     # Ejecuta todos los ants
        $Dist{genfiles} = [_unique @{$Dist{genfiles} || []}];
    }    # fin build.xml generado por webDist
    $balix_pool->purge;
    return 1;
}

# Calcula el nivel de despliegue: EAR, WAR, EJB
sub nivelDist
{
    my $self = shift;
    my $log  = $self->log;
    local our %Dist;
    *Dist = shift;
    my $pElements = shift();
    my %Elements  = %{$pElements} if $pElements;
    my $Workspace = shift();
    my $pEARS     = shift();
    my @EARS      = @{$pEARS} if $pEARS;
    my $pWARS     = shift();
    my @WARS      = @{$pWARS} if $pWARS;
    my $pEJBS     = shift();
    my @EJBS      = @{$pEJBS} if $pEJBS;

    my $nivel = '';

    my $fn = sub {    # Array -> Str
        join ', ', @_;
    };
    my $ears_str = $fn->(@EARS);
    my $wars_str = $fn->(@WARS);
    my $ejbs_str = $fn->(@EJBS);

    $log->debug("Inicio reglas de nivel de despliegue para: EARS=$ears_str, WARS=$wars_str, EJBS=$ejbs_str");

    # REGLAS por ciclo de vida
    # my %control_env;
    my $bde_conf = $self->bde_conf;

    # @control_env{split /,/, $bde_conf->{control_ear}};  <-- wtf?

    if (   $bde_conf->{control_ear} eq "1" 
        ## || ($control_env{$Dist{entorno}})
       )
    {
        my $last = $self->dist_entornos($Dist{CAM}, $Dist{entorno});
        $log->debug("Verificación de histórico de pases para el CAM activado (CONTROL_EAR=$bde_conf->{control_ear})", Dumper $last);

        # Si el MAX(ID) para el CAM_ENTORNO es un rollback (CICLO=R) o NULL (No hay datos): nivel=ear
        if (!$last || $last->{ciclo} eq 'R')
        {
            $log->debug("Nivel EAR detectado porque el último pase para $Dist{CAM}/$Dist{entorno} es un rollback (CICLO=R) o NULL");
            return 'EAR';
        }

        # Si el ciclo actual es distinto del último registro CAM-ENTORNO: nivel=ear
        if ($last->{ciclo} ne $Dist{ciclo})
        {
            $log->debug("Nivel EAR detectado porque el último pase para $Dist{CAM}/$Dist{entorno} porque el ciclo era distinto del actual ($last->{ciclo} <> $Dist{ciclo})");
            return 'EAR';
        }

        # Si el Project actual es distinto del último registro CAM-ENTORNO: nivel=ear
        if ($last->{environmentname} ne $Dist{envname})
        {
            $log->debug("Nivel EAR detectado porque el último pase para $Dist{CAM}/$Dist{entorno} ha sido para un Proyecto Harvest distinto ($last->{environmentname} <> $Dist{envname}) ");
            return 'EAR';
        }
    }

    # REGLAS de separación EAR, WAR, EJB
    my ($kEAR, $kWAR, $kEJB) = (0, 0, 0);

    foreach (@_)
    {
        if ($Workspace->isClass($_, 'EAR')) { $kEAR++; $nivel = 'EAR'; last; }
        if ($Workspace->isClass($_, 'WAR')) { $kWAR++; }
        if ($Workspace->isClass($_, 'EJB')) { $kEJB++; }
    }
    $log->debug("Resultado de la regla de número de módulos=$nivel (EAR=$kEAR, WAR=$kWAR, EJB=$kEJB)");

    if ($nivel ne 'EAR')
    {
        if ($kEJB == 1 && $kWAR == 0)
        {
            $nivel = 'EJB';
        }
        elsif (($kEJB == 0) && ($kWAR == 1))
        {
            $nivel = 'WAR';
        }

        _log "\n\nnivel: $nivel\n\n";

        if (scalar @EARS)
        {
            _log "\nElements: " . Data::Dumper::Dumper \%Elements;

            # Preparo un listado de proyectos
          ELEM:
            foreach my $VersionId (keys %Elements)
            {

                my $ElementPath = $Elements{$VersionId}->{ElementPath};

                _log "elpath: $ElementPath";

                # EAR - si hay cosas en META-INF, es EAR
                foreach my $earprj (@EARS)
                {

                    if (   $ElementPath =~ m{$earprj/META-INF/application.xml}
                        || $ElementPath =~ m{$earprj/META-INF/ibm})
                    {
                        $nivel = 'EAR';
                        _log "\nsalgo\n";
                        last ELEM;
                    }
                }
            }
        }
    }

    # PASES públicos con varios EJBs caen aquÃ­ y PASES de aplicaciones WEB
    # sin EAR caen aquÃ­ (sólo WARs y librerÃ­as)
    if ($nivel eq '')
    {
        _log "entro en cond1";
        do { $log->debug("RETURN 4"); return 'EJB' } if (@EJBS  && !@WARS);
        do { $log->debug("RETURN 5"); return 'WAR' } if (!@EJBS && @WARS);
        do { $log->debug("RETURN 6"); return 'EAR' } if (@EARS);    # Si hay EAR, hay EAR
    }

    _log "nivel: $nivel";

    # WAR - a lo mejor es sólo config...
    my %CONFWARS = ();
    if ($nivel eq 'WAR')
    {
        _log "\nentro en el otro bucle\n";

      ELEM:
        foreach my $VersionId (keys %Elements)
        {    # Preparo un listado de proyectos
            my $ElementPath = $Elements{$VersionId}->{ElementPath};

            # my $ElementPath = @{$Elements{$VersionId}}[10];
            foreach my $warprj (@WARS)
            {
                if ($ElementPath !~ m{$warprj/Config})
                {

                    # last ELEM;
                    # elemento no es de Config - fuera!
                    $log->debug("RETURN 7");
                    return 'WAR';
                }
                else
                {
                    $CONFWARS{$warprj} = ();
                }
            }
        }
        $log->debug("Conf Wars: " . join ', ', keys %CONFWARS);
        $nivel = 'CONF';                      # Si ha llegado aqui es CONF
        $Dist{confwars} = [keys %CONFWARS];
    }
    $log->debug("RETURN 8");
    return $nivel;
}

######################################################
##
##  webDist
##
sub webDist
{
    my $self     = shift;
    my $log      = $self->log;
    my $inf      = inf $self->cam;
    my $bde_conf = $self->bde_conf;

    # De programador vago, para evitar tener que escribir la flechita $Dist->{pase}, etc.
    local our %Dist;
    *Dist = shift;

    # Para compatibilidad backwards:
    my ($Pase, $PaseDir, $Entorno, $TipoPase, $EnvironmentName, $Sufijo) = ($Dist{pase}, $Dist{pasedir}, $Dist{entorno}, $Dist{tipopase}, $Dist{envname}, $Dist{sufijo});

    my ($cam, $CAM) = ($Dist{cam}, $Dist{CAM});

    if (@{$Dist{prjlist}})
    {

        # Trato proyectos generados:
        foreach my $prj (@{$Dist{prjlist}})
        {
            $log->debug("webDist: Trato proyecto $prj");
            my %PRJMAP = %{$Dist{map}} if $Dist{map};
            my $subapl = $PRJMAP{$prj}{SUBAPL};
            my $file   = $PRJMAP{$prj}{FILENAME};
            if ($subapl eq "")
            {    # No lo tengo! lo intento a mi manera
                $subapl = $self->_subapl($prj);
            }
            if ($subapl eq "")
            {
                $subapl = $cam;
                $log->warn("Aviso: no he podido determinar la subaplicación del proyecto EAR '$prj'. Subaplicación por defecto=$subapl.");
            }
            $log->info("Despliegue del proyecto $prj, fichero $file, subaplicación $subapl");

            # Destino de la subapl:
            my %DEST = $inf->get_inf_destinos($Entorno, $subapl);
            my $esIAS = $inf->inf_es_IAS($CAM, $subapl);
            my $har_db = BaselinerX::CA::Harvest::DB->new;
            $har_db->set_subapl($Pase, $subapl);

            # BACKUP - siempre se hace del ear, aunque se despliegue un ejb o war
            if (($TipoPase ne "B") and ($Entorno eq "PROD"))
            {

                # False, da igual y sigo; true, pase se interrumpe si no tiene backup.
                my ($sigoSinBackup) = getInf($CAM, "scm_seguir_sin_backup");
                try
                {
                    $self->backupWEB($EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subapl, \%DEST);
                }
                catch
                {
                    if ($sigoSinBackup =~ m/N/i)
                    {

                        # ups, tengo que parar el pase
                        _throw "Pase terminado por no poder generar el backup: " . shift();
                    }
                    else
                    {
                        $log->warn("Aviso: No he podido generar el EAR de backup de la aplicación actualmente desplegada: " . shift());
                    }
                }
            }

            # Despliegue:
            try
            {
                $self->despliegueWEB(\%Dist, $subapl, $prj, $file, \%PRJMAP);

                # $webNeedRollback = 1;  # TODO
            }
            catch
            {
                _throw "Error al desplegar EAR $prj ($file): " . shift();
            };

            # $webNeedRollback = 1;  # TODO
        }
    }

    # Contenido estatico
    if ($Dist{tar})
    {
        foreach my $htptar (@{$Dist{tar}})
        {
            my $prj = $htptar;
            $prj =~ s{(.*?).tar}{$1};

            # La subapl es parte del nombre del TAR: subaplWEB.tar
            my $subapl = $self->_subapl($prj);

            my $Red = $inf->get_inf_subred(substr($Entorno, 0, 1), $subapl);

            my $destinoEstatico = $inf->get_inf(
                {sub_apl => $subapl},
                [
                 {
                  column_name => 'WAS_STATIC_CONTENT',

                  #idred       => $Red,
                  #ident       => substr($Entorno, 0, 1)
                 }
                ]
            );

            # $log->debug("\$inf->get_inf({sub_apl => '$subapl'}, [{column_name => 'WAS_STATIC_CONTENT', idred => '$Red', ident => '$Entorno'}])");    # XXX

            # TODO Falta por leer nuevo campo con el directorio de contenido estático "${Entorno}_${Red}_xxxxxxxx"

            if ("WEB" eq uc($destinoEstatico))
            {
                $log->info("Contenido estático: $htptar (SUBAPL=$subapl, Destino=$destinoEstatico)");

                # Estatico normal:
                my %DEST = $inf->get_inf_destinos($Entorno, $subapl);
                my $balix = $balix_pool->conn_port($DEST{htp_maq}, $DEST{htp_puerto});
                $self->htpDist(\%Dist, $subapl, $htptar, \%DEST, $balix, $DEST{htp_maq});
                $balix->end() if ($balix);

                # Estatico a cluster:
                if ($DEST{htp_server_cluster})
                {
                    $log->debug("Conectando a $DEST{htp_server_cluster}, $DEST{htp_puerto}...");
                    my $balixCluster = $balix_pool->conn_port($DEST{htp_server_cluster}, $DEST{htp_puerto});
                    $self->htpDist(\%Dist, $subapl, $htptar, \%DEST, $balixCluster, $DEST{htp_server_cluster}, no_backup => 1);
                    $balixCluster->end() if ($balixCluster);
                    $log->debug("Ok. Conectado a $DEST{htp_server_cluster}, $DEST{htp_puerto}.");
                }
            }
            elsif ("WAS" eq uc($destinoEstatico))
            {    # va al WAS, separado del WAR (nivel eq 'TAR')
                if ($Dist{nivel} =~ /EAR|WAR/)
                {

                    # no deberÃ­a pasar por aquÃ­, el staticExtensions no deberÃ­a haber
                    # retornado la lista de estáticos
                    $log->debug("Nivel '$Dist{nivel}' - contenido estático ya está incluido en el .war");
                }
                else
                {

                    # GZIPO
                    $log->info("Contenido estático: $htptar (SUBAPL=$subapl, Destino=$destinoEstatico)");
                    $log->debug("Creo el fichero GZIP de despliegue de contenido estático en WAS: $htptar. Espere...");
                    my $tarfile   = "$Pase/$CAM/$Sufijo/$htptar";
                    my $RET       = `gzip "$tarfile" 2>&1`;
                    my $gztarfile = "$tarfile.gz";
                    if ($? eq 0)
                    {
                        $log->info("Fichero GZIP de contenido  estático WAS creado con éxito: $Pase/$CAM/$Sufijo/$htptar.", $RET);
                    }
                    else
                    {
                        $log->error("Error al crear fichero GZIP $Dist{buildhome}/$tarfile.gz para el despliegue de contenido estático (RC=$?). Verifique el espacio en disco de $bde_conf->{broker}:$Dist{buildhome}", $RET);
                        _throw "Error en la preparación para compilación";
                    }
                    $self->despliegueWEB(\%Dist, $subapl, $prj, $gztarfile);
                }
            }
            else
            {
                $log->warn("No reconozco el destino $destinoEstatico del campo WAS_STATIC_CONTENT en el formulario de infraestructura");
            }
        }
    }
}

# antBuild: Se encarga de llevar los fuentes a staging, ejecutar el build, y
#           traer los compilados de vuelta
sub antBuild
{
    my $self     = shift;
    my $log      = $self->log;
    my $inf      = inf $self->cam;
    my $bde_conf = $self->bde_conf;

    local our %Dist;
    *Dist = shift;

    $log->debug("Parms antBuild", _dump(\%Dist));

    my ($Pase, $EnvironmentName, $buildhome, $Entorno) = ($Dist{pase}, $Dist{envname}, $Dist{buildhome}, $Dist{entorno});
    my ($buildxml, $filename, $subapl, $param, $buildtype, @OUTPUT) = @_;
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);
    my @TARFILES = ();

    # _throw "Exit de conveniencia en antBuild.";

    $log->info("Iniciando construcción para '$CAM' subaplicación '$subapl' ($buildxml)");
    $log->debug("Ficheros de salida: " . join ', ', map { $_->{file} } @OUTPUT) if (@OUTPUT);

    # Envio de ficheros a staging:
    my $tarfile     = "${Pase}-$EnvironmentName-WEB.tar";
    my $sta_tarfile = "$STA{buildhome}/${tarfile}";
    my $esIAS       = $inf->inf_es_IAS($CAM, $subapl);
    my @EARANT      = ();

    (my $buildfilename = $buildxml) =~ s{^.*/(.*?)$}{$1};

    # Hay build.xml proporcionado x el usuario?
    if ($buildxml)
    {

        # Le meto la ruta de staging:
        $buildxml = "-buildfile '$STA{buildhome}/$buildxml'";
    }

    # Si ya no he enviado el TAR a Staging...
    if (!$INSTAGING{"$buildhome"})
    {

        #  TAR local
        my $RET = `cd ${buildhome} ; $bde_conf->{gnutar} -cvf "$tarfile" * ; gzip -f "$tarfile"`;
        if ($? eq 0)
        {
            $log->debug("Fichero tar creado con éxito.", $RET);
        }
        else
        {
            $log->error("Error al crear fichero TAR ${buildhome}/$tarfile para enviarlo al servidor de staging (RC=$?). Verifique el espacio en disco de $bde_conf->{broker}:${buildhome}", $RET);
            _throw "Error en la preparación para compilación";
        }
    }
    else
    {
        $log->debug("No se enviará a staging el TAR $tarfile. $buildhome ya se ha enviado anteriormente para este pase.");
    }
    my $balix;
    try
    {
        my $balix = $balix_pool->conn_port($STA{maq}, $STA{puerto});
        my ($RC, $RET);

        # Gestionamos los la variable del tar a utilizar:
        my $tarExecutable;

        ($RC, $RET) = $balix->executeas($STA{user}, qq| ls '$bde_conf->{tardestinosaix}' |);    #'

        # No tenemos tar especial en esta máquina, asÃ­ que nos llevamos uno.
        if ($RC ne 0)
        {
            $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
            $tarExecutable = "tar";
        }
        else
        {
            $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
            $tarExecutable = $bde_conf->{tardestinosaix};
        }

        if (!$INSTAGING{"$buildhome"})
        {

            # Creo el dir STA-BUILDHOME
            ($RC, $RET) = $balix->executeas($STA{user}, "mkdir -p $STA{buildhome}");
            if ($RC ne 0)
            {
                _throw "Error al crear el directorio de staging $STA{buildhome}: $RET";
            }
            else
            {
                $log->debug("Directorio de staging '$STA{buildhome}' creado: $RET");
            }

            # Envio TAR.GZ
            $log->info("Enviando ficheros de aplicación a staging. Espere...");

            ($RC, $RET) = $balix->sendFile("${buildhome}/${tarfile}.gz", "${sta_tarfile}.gz");

            if ($RC ne 0)
            {
                _throw "Error al enviar fichero tar ${sta_tarfile}: $RET";
            }
            else
            {
                $log->debug("Fichero '${sta_tarfile}' creado en staging: $RET");
            }

            # Cambio de permisos y owner
            ($RC, $RET) = $balix->execute(qq|chown $STA{user} "${sta_tarfile}.gz" ; chmod 750 "${sta_tarfile}.gz"|);
            if ($RC ne 0)
            {
                _throw "Error al cambiar permisos del fichero ${sta_tarfile}.gz: $RET";
            }
            else
            {
                $log->debug("Fichero '${sta_tarfile}'.gz con permisos para '$STA{user}': $RET");
            }

            # Descomprime
            ($RC, $RET) = $balix->executeas($STA{user}, qq|cd $STA{buildhome} ; rm -f "${sta_tarfile}"; gzip -f -d "${sta_tarfile}.gz" ; $tarExecutable xvf "${sta_tarfile}"; rm -f "${sta_tarfile}"|);

            if (($RC ne 0) or ($RET =~ m/unexpected/i) or ($RET =~ m/no space/i))
            {
                _throw "Error al descomprimir ${sta_tarfile}.gz (Â¿Falta espacio en disco en el servidor de staging $STA{maq}?): $RET";
            }
            else
            {
                $log->debug("Fichero '${sta_tarfile}'.gz descomprimido: $RET");
            }

            $INSTAGING{$buildhome} = 1;    # Doy por copiado este path.
        }

        # PUBLICO - Importo la parte pública de la aplicación
        my $pubname = $bde_conf->{pubname};
        my ($pubver);

        # Es IAS, investigo el fichero ias.jar a ver qué versión tiene:
        if ($esIAS)
        {
            _log "Es IAS version publico!";
            my $pubver = BaselinerX::J2EE::IAS->ias_version_publico(
                                                                    $log,
                                                                    pase      => $Pase,
                                                                    buildhome => $buildhome,
                                                                    subapl    => $subapl,
                                                                    fichero   => 'ias.jar',
                                                                    filter    => qr/_EAR|_WEB|_EJB/,
                                                                    prefix    => 'IAS'
                                                                   );

            # Esta apl utiliza elementos públicos, hay que incorporarlos:
            if ($pubver)
            {

                # Reemplaza por la version de PUBLICO:
                _log "Reemplazando por la version de PUBLICO";
                BaselinerX::J2EE::IAS->copy_publico(
                                                    $log,
                                                    harax     => $balix,
                                                    home      => $STA{home},
                                                    pubver    => $pubver,
                                                    buildhome => $STA{buildhome},
                                                    user      => $STA{user},
                                                    subapl    => $subapl,
                                                    folders   => [qw/EAR WEB EJB/],
                                                   );
            }
        }

        # ANT
        my $jdkVersion = $self->getJDKVersion($CAM, $Entorno, $subapl);
        my $jdkVar = "\$\{aix_jdk_$jdkVersion\}";

        my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
                                                              {
                                                               entorno => $Entorno,
                                                               sub_apl => $subapl,
                                                               cam     => $CAM
                                                              }
                                                             );
        my $jdkPath = $resolver->get_solved_value($jdkVar);

        if ((index $jdkPath, "java") > -1)
        {
            $log->debug("Versión de JDK usada para compilar $subapl: $jdkVersion. Path: $jdkPath");
        }
        else
        {
            $log->warn("No se pudo resolver el path para la versión de JDK especificada en el formulario: $jdkVersion, o bien su valor no es correcto. Se usará el JDK por defecto en esa máquina.");
            $jdkPath = "";
        }

        my $executeString = qq|ls "$jdkPath"|;
        ($RC, $RET) = $balix->executeas($STA{user}, $executeString);

        my $pathChange = "";

        if ($RC eq 0)
        {
            $pathChange = "PATH=$jdkPath:\\\$PATH ;";
        }
        else
        {
            $log->warn("El path especificado para buscar el JDK no se encuentra en la máquina de Staging de WAS. Se compila usando el JDK por defecto en esa máquina.");
        }

        # sem here TODO
        $log->debug("Generating semaphore request for $Pase in $Entorno");
        my $sem = Baseliner->model('Semaphores')->request(
                                                          sem => 'bde.j2ee.test',
                                                          bl  => $Entorno,
                                                          who => $Pase
                                                         );
        $log->debug("Please wait...");

        # $sem->wait_for;
        $log->debug("Slot granted!");
        $log->info("ANT compilando y empaquetando $buildxml (espere)...", "ant $param $buildxml");
        $executeString = qq|cd "$STA{buildhome}" ; $pathChange ant $param $buildxml 2>&1|;
        $log->debug("Comando a ejecutar:\n$executeString");

        ($RC, $RET) = $balix->executeas($STA{user}, $executeString);
        if ($RC ne 0)
        {
            $log->error("Ant terminado con error (RC=$RC)" . $RET);
            _throw "Error en la construcción ANT (RC=$RC)";
        }
        else
        {
            $log->info("Fin de la ejecución ANT (RC=$RC).", $RET);
        }
        $log->debug("Releasing slot");
        $sem->release;

        # sem release TODO

        # BUILD.XML del usuario - busco ficheros generados
        if ($filename =~ /\.ear/)
        {
            push @EARANT, $filename;
        }
        if ($buildtype eq "B")
        {
            $log->info("Buscando ficheros .ear generados por el build.xml del usuario en $STA{buildhome}");
            ($RC, $RET) = $balix->executeas($STA{user}, qq|cd "$STA{buildhome}" ; ls *.ear|);
            if ($RC ne 0)
            {
                $log->warn("No he encontrado ficheros .ear en $STA{buildhome}: $RET");
            }
            else
            {
                $RET =~ s/Usuario(.*?)\n//s;
                my @EARUSER = split /\n/, $RET;
                if (@EARUSER)
                {
                    $log->info("Ficheros .ear encontrados.", $RET);
                    push @EARANT, @EARUSER;
                }
                else
                {
                    $log->warn("No he encontrado ficheros .ear generados por el build.xml del usuario $buildxml");
                }
            }
        }

        # GET Baseliner genfiles
        if (@OUTPUT)
        {
            foreach (@OUTPUT)
            {
                my $genfile = $_->{file};
                (my $genfilename = $genfile) =~ s{.*/(.*?)$}{$1}g;
                if (   ($Dist{nivel} eq 'EAR') && ($_->{ext} eq 'EAR')
                    || ($Dist{nivel} eq 'WAR') && ($_->{ext} eq 'WAR')
                    || ($Dist{nivel} eq 'EJB') && ($_->{ext} eq 'JAR'))
                {
                    $log->info("Recuperando fichero $genfilename de staging ($genfile). Espere.");
                }
                else
                {
                    $log->debug("Recuperando fichero $genfilename de staging ($genfile). Espere.");
                }
                ($RC, $RET) = $balix->execute("ls '$STA{buildhome}/$genfile'");
                if ($RC ne 0)
                {
                    $log->debug("No encuentro el fichero $STA{buildhome}/$genfile (RC=$RC, RET=$RET). Ignorado.");
                    next;
                }
                ($RC, $RET) = $balix->getFile("$STA{buildhome}/$genfile", "$buildhome/$genfile");
                if ($RC ne 0)
                {
                    $log->error("Error al recuperar fichero de staging '$STA{buildhome}/$genfile' ($STA{maq}) a local '$buildhome/$genfile' (RC=$RC)", $RET);
                    _throw "Error en la recuperación de ficheros de Staging (RC=$RC)";
                }
                else
                {
                    $log->debug("Fin de transferencia: fichero EAR de staging '$STA{buildhome}/$genfile' ($STA{maq}) a local '$buildhome/$genfile' (RC=$RC).", $RET);
                }
                if (   ($Dist{nivel} eq 'EAR') && ($_->{ext} eq 'EAR')
                    || ($Dist{nivel} eq 'WAR') && ($_->{ext} eq 'WAR')
                    || ($Dist{nivel} eq 'EJB') && ($_->{ext} eq 'JAR'))
                {
                    $log->debug($buildhome, $genfilename, "Fichero $genfilename construido en Staging ok.");    # there is no logfile?
                }
                push @TARFILES, $genfilename if $_->{ext} eq 'TAR';
            }
        }
        else
        {

            # GET de los ficheros generados en staging ( para build.xml del usuario )
            foreach my $antearfile (@EARANT)
            {

                # GET EAR
                $log->info("Transfiriendo fichero $antearfile de staging. Espere.");
                ($RC, $RET) = $balix->getFile("$STA{buildhome}/$antearfile", "$buildhome/$antearfile");
                if ($RC ne 0)
                {
                    $log->error("Error al recuperar fichero de staging '$STA{buildhome}/$antearfile' ($STA{maq}) a local '$buildhome/$antearfile' (RC=$RC)", $RET);
                    _throw "Error en la recuperación de ficheros de Staging (RC=$RC)";
                }
                else
                {
                    $log->debug("Fin de transferencia: fichero EAR de staging '$STA{buildhome}/$antearfile' ($STA{maq}) a local '$buildhome/$antearfile' (RC=$RC).", $RET);
                }
                $log->debug($buildhome, $antearfile, "Fin de la ejecución de la construcción en Staging ok.");    # logfile?
                if ($buildtype eq "B")
                {

                    # Renombro ficheros .ear para que no los vuelva a pillar en otras ejecuciones del antBuild
                    ($RC, $RET) = $balix->executeas($STA{user}, qq|mv "$antearfile" "$antearfile".done|);
                }
            }

            # Get tar contenido estatico:
            foreach my $htptar (@TARFILES)
            {
                $log->debug("HTP: Busco a ver si se ha generado el fichero de contenido estático $STA{buildhome}/$htptar...");
                ($RC, $RET) = $balix->execute("ls '$STA{buildhome}/$htptar'");
                if ($RC ne 0)
                {
                    $log->debug("HTP: No está el contenido estático $STA{buildhome}/$htptar (RC=$RC, RET=$RET)");
                    next;
                }
                $log->info("Transfiriendo contenido estático $htptar de staging. Espere...");
                ($RC, $RET) = $balix->getFile("$STA{buildhome}/$htptar", "$buildhome/$htptar");
                if ($RC ne 0)
                {
                    $log->error("Error al recuperar fichero de staging '$STA{buildhome}/$htptar' ($STA{maq}) a local '$buildhome/$htptar' (RC=$RC)", $RET);
                    _throw "Error en la recuperación de ficheros de contenido estático de Staging (RC=$RC)";
                }
                else
                {
                    $log->debug("Fin de transferencia: fichero TAR de contenido estático de staging '$STA{buildhome}/$htptar' ($STA{maq}) a local '$buildhome/$htptar' (RC=$RC).", $RET);
                }
                $log->debug($buildhome, $htptar, "Contenido estático $htptar ok.");    # logfile...
            }

            # Get config si lo ha generado el build.xml de usuario:
            $log->debug("CONFIG: busco ficheros $STA{buildhome}/config_*tar en staging, por si lo ha generado el ant...");
            ($RC, $RET) = $balix->execute("ls $STA{buildhome}/config_*.tar");
            if ($RC eq 0)
            {
                my @ficheros = split /\n/, $RET;
                $log->debug("CONFIG: ficheros config_*tar encontrados: " . join ', ', @ficheros);

                for my $fich (@ficheros)
                {
                    use Path::Class;
                    my $fich_name = Path::Class::file($fich)->basename;
                    $log->info("CONFIG: recuperando fichero config '$fich_name' ('$fich')...");
                    ($RC, $RET) = $balix->getFile($fich, "$buildhome/$fich_name");
                    if ($RC ne 0)
                    {
                        $log->error("Error al recuperar fichero de staging '$fich' ($STA{maq}) a local '$buildhome/$fich_name' (RC=$RC)", $RET);
                        _throw "Error en la recuperación de ficheros de config de Staging (RC=$RC)";
                    }
                    else
                    {
                        $log->debug("Fin de transferencia: fichero TAR de config de staging '$fich' ($STA{maq}) a local '$buildhome/$fich_name' (RC=$RC).", $RET);
                    }
                }
            }
            else
            {
                $log->debug("CONFIG: no encontrados: RC=$RC, RET=$RET");
            }
        }

        # Publica - exporto la parte pública de esta aplicación:
        if ($PARAMS{PUB})
        {
            my $pubdir     = "$buildhome/../PUBLICO";
            my $sta_pubdir = "$STA{buildhome}/../PUBLICO";
            my $pubtar     = "publico.tar";
            $Dist{genfiles} = [$pubtar];
            my $sta_pubtar = "$sta_pubdir/$pubtar";

            # Gestionamos la variable del tar a utilizar:
            my $tarExecutable;
            ($RC, $RET) = $balix->executeas($STA{user}, qq| ls '$bde_conf->{destinosaix}' |);

            # No tenemos tar especial en esta máquina, asÃ­ que nos llevamos uno:
            if ($RC ne 0)
            {
                $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
                $tarExecutable = "tar";
            }
            else
            {
                $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
                $tarExecutable = $bde_conf->{tardestinosaix};
            }

            $log->info("Transfiriendo librerÃ­as públicas generadas por la aplicación $EnvironmentName en staging. Espere...");

            ($RC, $RET) = $balix->executeas($STA{user}, qq|cd "$sta_pubdir" ; $tarExecutable cvf "$pubtar" *|);

            if ($RC ne 0)
            {
                $log->error("Error al recuperar fichero de staging '$sta_pubtar' ($STA{maq}) a local '$buildhome/$pubtar' (RC=$RC)", $RET);
                _throw "Error en la recuperación de nuevos ficheros públicos de Staging (RC=$RC)";
            }
            else
            {
                $log->debug("Fin de transferencia: fichero TAR de nuevos elementos públicos de staging '$STA{buildhome}/$pubtar' ($STA{maq}) a local '$pubdir/$pubtar' (RC=$RC).", $RET);
            }
            mkdir $pubdir;

            ($RC, $RET) = $balix->getFile("$sta_pubtar", "$pubdir/$pubtar");
            if ($RC ne 0)
            {
                $log->error("Error al recuperar fichero de staging '$sta_pubtar' ($STA{maq}) a local '$pubdir/$pubtar' (RC=$RC)", $RET);
                _throw "Error en la recuperación de nuevos ficheros públicos de Staging (RC=$RC)";
            }
            else
            {
                $log->debug("Fin de transferencia: fichero TAR de nuevos elementos públicos de staging '$sta_pubtar' ($STA{maq}) a local '$pubdir/$pubtar' (RC=$RC).", $RET);
            }

            my @RET = `cd '$pubdir' ; $bde_conf->{gnutar} xvf '$pubtar' ; rm -f '$pubtar'`;
            if ($?)
            {
                $log->error("UNTAR: error al descomprimir fichero tar de staging", @RET);
                _throw "Error durante la transferencia de ficheros públicos generados en staging.";
            }
            else
            {
                $log->debug("UNTAR de elementos públicos generados en staging ok.", @RET);
            }
            push @{$Dist{genfiles}}, $pubtar;
        }

        # SQA
        #    if ($bde_conf->{sqa_activo}) {
        #      my $sqa_tar = BaselinerX::SQA::Tar->new(balix => $balix, log => $log);
        #      $sqa_tar->tar($balix,
        #                    {rem_dir  => $STA{buildhome},
        #                     pase_dir => $Dist{pasedir},
        #                     subapl   => $subapl,
        #                     entorno  => $Entorno,
        #                     cam      => $CAM,
        #                     pase     => $Pase,
        #                     nature   => 'J2EE'});
        #      # if $Dist{tipopase} eq 'N';
        #    }
    }
    catch
    {
        _throw "Error al transferir ficheros al nodo de staging $STA{maq}: " . shift();
    }
    finally
    {
        $balix->end() if ($balix);
    };
    $Dist{tar}    = [@TARFILES];
    $Dist{earant} = [@EARANT];
}

sub generateProps
{
    my $self     = shift;
    my $log      = $self->log;
    my $bde_conf = $self->bde_conf;
    my %props    = %{shift @_};
    my $path     = shift @_;
    my $RET;
    for (keys %props)
    {
        $RET .= "$_=$props{$_}\n";
    }

    # leer variables del distribuidor de tipo BUILD_PROPERTIES_*
    for my $var (keys %ENV)
    {
        if ($var =~ m/^BUILD_PROPERTIES_(.*)$/)
        {
            my $name  = lc $1;               # a minúsculas
            my $valor = $bde_conf->{$var};
            $RET .= "$name=$valor\n";
        }
    }

    $log->info("Creando fichero de propiedades $path.", $RET);
    open(PROPS, ">$path")
      or die "No he podido crear el fichero de propiedades '$path': $!";
    print PROPS $RET;
    close PROPS;

    return $RET;
}

sub fileSize
{
    my $self     = shift;
    my $filename = shift @_;
    open THISFILE, "<$filename";
    my $size = -s THISFILE;
    close THISFILE;
    $size;
}

######################################################################################################
##  BACKUP
######################################################################################################

# backup de EARs, Config y Estático
sub backupWEB
{
    my $self     = shift;
    my $log      = $self->log;
    my $bde_conf = $self->bde_conf;
    my ($EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subapl, $hDEST) = @_;
    my $localdir = "$PaseDir/backup";
    mkdir $localdir;
    my $retCode = 0;

    # Se conecta a la máquina destino (o la de staging windows) con harax:
    try
    {
        my %DEST = %{$hDEST} if ($hDEST);
        my $balix = $balix_pool->conn_port($DEST{maq}, $DEST{puerto});

        # CONFIG
        if (($DEST{tech} =~ /^IAS|^EDW4J|^J2EE_BDE/) && ($DEST{config_dir} ne ""))
        {    # es IAS
            my $filename  = "${Pase}_${Sufijo}_${subapl}_Config_backup.tar";
            my $localfile = "$localdir/$filename";
            my $remfile   = "/tmp/$filename";
            $log->info("Backup: guardando información del directorio de Configuración...", $DEST{config_dir});

            # Gestionamos los la variable del tar a utilizar:
            my $tarExecutable;
            my ($RC, $RET) = $balix->executeas($DEST{was_user}, qq| ls '$bde_conf->{tardestinosaix}' |);

            # No tenemos tar especial en esta máquina, asÃ­ que nos llevamos uno:
            if ($RC ne 0)
            {
                $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
                $tarExecutable = "tar";
            }
            else
            {
                $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
                $tarExecutable = $bde_conf->{tardestinosaix};
            }

            # TAR del directorio de Config:
            ($RC, $RET) = $balix->executeas($DEST{was_user}, "cd $DEST{config_dir} ; $tarExecutable cvf $remfile *");
            if ($RC ne 0)
            {
                $log->warn("Backup: error al recuperar el directorio de Config '$DEST{config_dir}'.", $RET);
                $retCode++;
            }

            # Recupero el TAR:
            ($RC, $RET) = $balix->getFile($remfile, $localfile);
            if ($RC ne 0)
            {
                $log->warn("Backup: error durante la transmisión del fichero TAR $DEST{maq}:$remfile.", $RET);
                $retCode++;
            }

            # Borro el fichero remoto:
            ($RC, $RET) = $balix->execute("rm -f '$remfile'");

            # Guardo el ear en la tabla:
            my ($idbak, $sizebak) = storeBackup($EnvironmentName, $Entorno, $subapl, $Sufijo, $Pase, "CONFIG", $localfile);

            $log->info("Backup: fichero de backup Config almacenado correctamente ($filename contiene ${sizebak} kb)", $idbak);

            # logfile($localdir,$filename,"Backup: fichero de backup almacenado correctamente.");
            # unlink $localfile;
        }

        # EAR
        if ($bde_conf->{was_script})
        {
            $log->info("Backup: recuperando EAR actualmente desplegado en $DEST{maq} ($DEST{puerto} con $DEST{was_user}). Espere...");
            my $filename  = "${Pase}_${Sufijo}_backup.ear";
            my $localfile = "$localdir/$filename";
            my $remfile   = "/tmp/$filename";
            my $script    = "$bde_conf->{was_script} $DEST{was_context_root} generateEAR $remfile $DEST{was_ver}";

            # Ejecuto el script:
            $log->debug("Backup: inicio del script: $script\n");
            my ($RC, $RET) = $balix->executeas($DEST{was_user}, $script);
            if ($RC eq 1)
            {
                $log->warn("Backup: error al recuperar el fichero EAR anterior (RC=$RC).", $RET);
                $retCode++;
            }
            $log->debug("Backup: fin de ejecución del script (RC=$RC).", $RET);

            # Recupero el fichero ear:
            $log->debug("Backup: transferencia del fichero remoto '$remfile' a local '$localfile'");
            ($RC, $RET) = $balix->getFile($remfile, $localfile);
            if ($RC ne 0)
            {
                $log->warn("Backup: error durante la transmisión del fichero.", $RET);
                $retCode++;
            }

            # Borro el fichero remoto:
            ($RC, $RET) = $balix->executeas($DEST{was_user}, "rm -f $remfile");

            # Guardo el ear en la tabla:
            my ($idbak, $sizebak) = storeBackup($EnvironmentName, $Entorno, $subapl, $Sufijo, $Pase, "EAR", $localfile);
            $log->info("Backup: fichero de backup de EAR almacenado correctamente ($filename contiene ${sizebak} kb)", $idbak);

            # logfile($localdir,$filename,"Backup: fichero de backup almacenado correctamente.");
            # unlink $localfile;
        }

        $balix->end;
    }
    catch
    {
        _throw "Error durante el backup: " . shift();
    };
    if ($retCode ne 0)
    {
        _throw "Error(es) durante el backup WEB (retcode=$retCode).";
    }
}

######################################################################################################
##  RESTORE
######################################################################################################

# restore de EARs, dir CONFIG, Estático
sub restoreWEB
{
    my $self     = shift;
    my $inf      = inf $self->cam;
    my $log      = $self->log;
    my $bde_conf = $self->bde_conf;
    my ($EnvironmentName, $Entorno, $Sufijo, $Pase, $PaseDir, $subapl) = @_;
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);
    my $localdir = $PaseDir . "/restore";

    mkdir $localdir;

    my %BACKUPS = get_backups($EnvironmentName, $Entorno, $Sufijo, $localdir, $subapl);

    $log->debug("Backups encontrados para '$EnvironmentName', '$Entorno', '$Sufijo', '$subapl'", _dump(%BACKUPS));

    my %DEST = $inf->get_inf_destinos($Entorno, $subapl);

    my $cnt = 0;
    if (keys %BACKUPS eq 0)
    {
        _throw "Restore: no hay backups disponibles para marcha atrás en la aplicación $EnvironmentName->$Entorno";
    }

    # Bucleamos ear a ear de este CAM...
    foreach my $localfilename (keys %BACKUPS)
    {
        $cnt++;
        my ($bakPase, $localfile, $tipo, $rootPath, $subapl) = @{$BACKUPS{$localfilename}};
        if ($localfile && -e $localfile)
        {
            my $remfile = "/tmp/${localfilename}";

            # EAR
            if (($tipo eq "EAR") && ($bde_conf->{was_script}))
            {
                my $accionWAS = $self->accionWAS($Entorno, $remfile);
                $log->info("Restore $cnt: localizado EAR de backup '$localfilename' (generado por el pase $bakPase)");
                my $script = "$bde_conf->{was_script} $DEST{was_context_root} $accionWAS $remfile $DEST{was_ver} $DEST{reinicio_web}";

                # Restore:
                try
                {
                    my $msg;
                    $log->info("Restore: desplegando fichero EAR de backup en $DEST{maq}. Espere...");
                    my $balix = $balix_pool->conn_port($DEST{maq}, $DEST{puerto});

                    # Recupero el fichero ear:
                    $log->debug("Restore $cnt: transferencia del fichero local '$localfile' a remoto '$DEST{maq}:$remfile'");
                    my ($RC, $RET) = $balix->sendFile($localfile, $remfile);
                    if ($RC ne 0)
                    {
                        my $msg = "Restore $cnt: error durante la transmisión del fichero EAR.";
                        $log->error($msg, $RET);
                        _throw $msg;
                        die;
                    }

                    # Permisos:
                    ($RC, $RET) = $balix->execute(qq|chmod 700 '$remfile' ; chown $DEST{was_user}:$DEST{was_group} '$remfile'|);
                    if ($RC ne 0)
                    {
                        $msg = "Restore $cnt: error al cambiar el permiso del EAR instalado $remfile ($DEST{was_user}:$DEST{was_group}:700).";
                        $log->info($msg, $RET);
                        _throw $msg;
                        die;
                    }

                    # Ejecuto el script:
                    ($RC, $RET) = $balix->executeas($DEST{was_user}, $script);
                    if (($RC ne 0) && ($RC ne 2) && ($RC ne 512))
                    {
                        $msg = "Restore $cnt: error al ejecutar el script de instalación del EAR.";
                        $log->info($msg, $RET);
                        _throw $msg;
                        die;
                    }

                    $log->info("Restore $cnt Despliegue OK: fichero de restore desplegado correctamente.", $RET);

                    # sem release TODO

                    # Borro el fichero remoto:
                    ($RC, $RET) = $balix->execute("rm -f '$remfile'");

                    # Recupero los logs:
                    $self->wasLogFiles($balix, $EnvironmentName, $Entorno, "LN", %DEST);
                    $balix->end();

                    # Enseño el ear desplegado al usuario en el log:
                    $log->info($localdir, $localfilename, "Restore $cnt: fichero EAR recuperado.");    # logfile...
                                                                                                       # unlink $localfile;
                }
                catch
                {
                    _throw "Restore: error durante la marcha atrás del EAR: " . shift();
                };
            }

            # CONFIG #
            # Modificar para restaurar en ambos nodos del cluster (si hay)
            elsif (($tipo eq "CONFIG") && ($DEST{config_dir}))
            {
                $log->info("Restore $cnt: identificado directorio de Config '$localfilename' (generado por el pase $bakPase)");
                try
                {
                    $log->info("Restore: desplegando directorio de Config en $DEST{maq}. Espere...");
                    my $balix = $balix_pool->conn_port($DEST{maq}, $DEST{puerto});
                    $self->configDist($balix, $DEST{was_user}, $DEST{was_group}, $DEST{config_dir}, $localfile, $remfile);
                    $balix->end;

                    # Enseño el ear desplegado al usuario en el log:
                    $log->info($localdir, $localfilename, "Restore $cnt OK: config IAS desplegado correctamente.");    # logfile!
                                                                                                                       # unlink $localfile;
                }
                catch
                {
                    _throw "Restore: error durante la marcha atrás del Config IAS: " . shift();
                };
                if ($DEST{server_cluster})
                {
                    try
                    {
                        $log->info("Restore: desplegando directorio de Config en máquina de cluster $DEST{server_cluster}. Espere...");
                        my $balix = $balix_pool->conn_port($DEST{server_cluster}, $DEST{puerto});
                        $self->configDist($balix, $DEST{was_user}, $DEST{was_group}, $DEST{config_dir}, $localfile, $remfile);
                        $balix->end;

                        # Enseño el config desplegado al usuario en el log:
                        $log->info($localdir, $localfilename, "Restore $cnt OK: config IAS desplegado correctamente.");    # logfile!
                                                                                                                           # unlink $localfile;
                    }
                    catch
                    {
                        $log->warn("Restore: error durante la marcha atrás del Config IAS en la máquina de cluster $DEST{server_cluster}: ");
                    };
                }
            }

            # Estáticos
            elsif (($tipo eq "HTP") && ($DEST{htp_dir}))
            {

                # Estatico normal:
                try
                {
                    $log->info("Restore $cnt: identificado fichero de estáticos '$localfilename' (generado por el pase $bakPase)");
                    $log->info("Conectando a $DEST{htp_maq}, $DEST{htp_puerto}...");
                    my $balix = $balix_pool->conn_port($DEST{htp_maq}, $DEST{puerto});
                    $log->debug("Ok. Conectado a $DEST{htp_maq}, $DEST{htp_puerto}.");
                    $self->htpDist(
                                   {
                                    pase     => $Pase,
                                    pasedir  => $PaseDir,
                                    tipopase => 'B',
                                    envname  => $EnvironmentName,
                                    entorno  => $Entorno,
                                    sufijo   => $Sufijo
                                   },
                                   $subapl,
                                   $localfile,
                                   \%DEST,
                                   $balix,
                                   $DEST{htp_maq}
                                  );
                    $balix->end() if ($balix);
                    $log->info($localdir, $localfilename, "Restore $cnt OK: fichero de estáticos desplegado correctamente en $DEST{htp_maq}.");    # logfile!
                }
                catch
                {
                    _throw "Restore: error durante la marcha atrás de estáticos: " . shift();
                };

                # Estatico a cluster
                if ($DEST{htp_server_cluster})
                {
                    try
                    {
                        $log->info("Restore $cnt: desplegando fichero de estáticos '$localfilename' en cluster $DEST{htp_server_cluster}");
                        $log->debug("Conectando a $DEST{htp_server_cluster}, $DEST{htp_puerto}...");
                        my $balixCluster = $balix_pool->conn_port($DEST{htp_server_cluster}, $DEST{htp_puerto});
                        $log->debug("Ok. Conectado a $DEST{htp_server_cluster}, $DEST{htp_puerto}.");
                        $self->htpDist(
                            {
                             pase     => $Pase,
                             pasedir  => $PaseDir,
                             tipopase => 'B',
                             envname  => $EnvironmentName,
                             entorno  => $Entorno,
                             sufijo   => $Sufijo
                            },
                            $subapl,
                            $localfile,
                            \%DEST,
                            $balixCluster,
                            $DEST{htp_server_cluster},
                            no_backup => 1,    # al ser cluster, no hace falta
                                      );
                        $balixCluster->end() if ($balixCluster);
                    }
                    catch
                    {
                        $log->warn("Restore: error durante la marcha atrás del Config IAS en la máquina de cluster $DEST{server_cluster}: ");
                    };
                }
            }
            else
            {
                $log->warn("Restore $cnt: tipo de backup '$tipo' no contemplado en la marcha atrás (fichero '$localfilename', generado por el pase $bakPase)");
            }
        }
        else
        {

            # Fichero no existe, señal de que el fichero restore no estaba en DISTBAK
            _throw "Restore: no existe un fichero de backup para $EnvironmentName->$Entorno.";
        }
    }
}

######################################################################################################
##  LOGS
######################################################################################################

# wasLogFiles: utilizado por el pase y el restore para recuperar los logs
#              stdout y stderr del was
#         obs: necesita una conexión de harax abierta
sub wasLogFiles
{
    my $self = shift;
    my $log  = $self->log;
    my $inf  = inf $self->cam;
    my ($balix, $EnvironmentName, $Entorno, $Red, %DEST) = @_;
    my ($dest_logdir, $dest_wasuser, $dest_maq, $dest_puerto) = ($DEST{was_log_dir}, $DEST{was_user}, $DEST{maq}, $DEST{puerto});
    my $subapl     = $DEST{sub_apl};
    my $directorio = '';

    # use Harax;
    use strict;
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);
    $log->debug("Buscando LOGS para $CAM, Entorno=$Entorno ($dest_maq:$dest_puerto)...");
    $Red = 'I' if ($Red eq q{});
    $log->debug("Ubicación de ficheros de log de aplicación: $dest_logdir");
    my $dest_waslogdir = '';
    $dest_waslogdir = $inf->get_inf({sub_apl => $subapl}, [{column_name => 'WAS_PATH_LOG_APP',      idred => $Red, ident => substr($Entorno, 0, 1)}]);
    $directorio     = $inf->get_inf({sub_apl => $subapl}, [{column_name => 'WAS_DIR_LOG_APPSERVER', idred => $Red, ident => substr($Entorno, 0, 1)}]);
    $log->debug("Ubicación de ficheros de log de WAS: $dest_waslogdir");

    # STDOUT
    my $logwas_stdout = "$dest_waslogdir" . "$directorio" . "/stdout*.log";

    # Cojo el último fichero de stdout
    my ($RC, $RET) = $balix->execute("ls -t $logwas_stdout");
    if ($RC ne 0)
    {
        $log->warn("No hay ficheros de log stdout de was en el directorio $dest_maq:$dest_waslogdir");
    }
    else
    {
        my @RET = split /\n/, $RET;
        my $ultimo_stdout = $RET[0];
        if ($ultimo_stdout eq "")
        {
            $log->debug("No he podido encontrar el último fichero stdout de WAS en $dest_maq:$dest_waslogdir");
        }
        else
        {
            ($RC, $RET) = $balix->executeas($dest_wasuser, "tail -1000 $ultimo_stdout");
            if ($RC ne 0)
            {
                $log->warn("Error al intentar leer el fichero de log de WAS $dest_maq:$ultimo_stdout", $RET);
            }
            else
            {
                if ($RET =~ /\n\[.+?\].{24}E.*?\n/)
                {
                    $log->warn("Fichero de log (stdout) de was para '$CAM' ($dest_maq:$ultimo_stdout) - contiene errores", $RET);
                }
                else
                {
                    $log->info("Fichero de log (stdout) de was para '$CAM' ($dest_maq:$ultimo_stdout)", $RET);
                }
            }
        }
    }

    # STDERR
    my $logwas_stderr = "$dest_waslogdir" . "$directorio" . "/stderr*.log";

    # Cojo el último fichero de stderr
    ($RC, $RET) = $balix->execute("ls -t $logwas_stderr");
    if ($RC ne 0)
    {
        $log->warn("No hay ficheros de log stderr de was en el directorio $dest_maq:$dest_waslogdir");
    }
    else
    {
        my @RET = split /\n/, $RET;
        my $ultimo_stderr = $RET[0];
        if ($ultimo_stderr eq "")
        {
            $log->warn("No he podido encontrar el último fichero stderr de WAS en $dest_maq:$dest_waslogdir");
        }
        else
        {
            ($RC, $RET) = $balix->executeas($dest_wasuser, "tail -1000 $ultimo_stderr");
            if ($RC ne 0)
            {
                $log->warn("Error al intentar leer el fichero de log de WAS $dest_maq:$ultimo_stderr", $RET);
            }
            else
            {
                if ($RET =~ /\n\[.+?\].{24}E.*?\n/)
                {
                    $log->warn("Fichero de log (stderr) de was para '$CAM' ($dest_maq:$ultimo_stderr) - contiene errores", $RET);
                }
                else
                {
                    $log->info("Fichero de log (stderr) de was para '$CAM' ($dest_maq:$ultimo_stderr)", $RET);
                }
            }
        }
    }

    # TRAZAS IAS (y otros logs de aplicación)
    if (length($dest_logdir) > 1)
    {    # que no sea root /
        my $logwas_trace = "$dest_logdir/*.log";
        ($RC, $RET) = $balix->execute("ls -t $dest_logdir/*.log");
        if ($RC ne 0)
        {
            $log->warn("No hay ficheros de log de aplicación (trazas) en el directorio $dest_maq:$dest_logdir");
        }
        else
        {
            my @RET = split /\n/, $RET;
            my $ultima_traza = $RET[0];
            if ($ultima_traza eq "")
            {
                $log->warn("No he podido encontrar el último fichero de log de aplicación (trazas) en $dest_maq:$dest_logdir");
            }
            else
            {
                ($RC, $RET) = $balix->executeas($dest_wasuser, "tail -1000 $ultima_traza");
                if ($RC ne 0)
                {
                    $log->warn("Error al intentar leer el fichero de log de aplicación '$dest_maq:$dest_logdir'", $RET);
                }
                else
                {
                    $log->info("$subapl: Fichero de log de aplicación para '$CAM' ($dest_maq:$ultima_traza)", $RET);
                }
            }
        }
    }
    else
    {
        $log->warn("AVISO: Campo 'Directorio de logs' de la subaplicación $subapl en el formulario de infraestructura está vacÃ­o. Rellénelo para leer logs de trazas.");
    }
}

######################################################################################################
##  CONFIG
######################################################################################################

# despliega el fichero TAR del Config de EDW4J e IAS
sub configDist
{
    my $self     = shift;
    my $log      = $self->log;
    my $bde_conf = $self->bde_conf;
    my ($balix, $dest_wasuser, $dest_wasgroup, $locConfig, $localfile, $remfile) = @_;
    if ($locConfig && $localfile && $remfile && (-e $localfile))
    {
        $log->info("Config: enviando ficheros de configuración a '$locConfig' ($dest_wasuser). Espere...");

        # ENVIO TAR
        my ($RC, $RET) = $balix->sendFile("$localfile", "$remfile");
        if ($RC ne 0)
        {
            _throw "Error al enviar fichero tar '$localfile' de config IAS a '$remfile': $RET";
        }
        else
        {
            $log->debug("Fichero tar de Config '$remfile' en destino: $RET");
        }

        # CHMOD TAR
        ($RC, $RET) = $balix->execute("chown $dest_wasuser:$dest_wasgroup '$remfile' ");
        if ($RC ne 0)
        {
            _throw "Error al cambiar permisos del fichero TAR de Config '$remfile': $RET";
        }
        else
        {
            $log->debug("Permisos de TAR cambiados: chown $dest_wasuser:$dest_wasgroup '$remfile': $RET");
        }

        # BORRO /config/*
        # TODO deberÃ­a hacer un backup pequenin localmente
        ($RC, $RET) = $balix->executeas($dest_wasuser, "rm -Rf '$locConfig'/*  ");
        if   ($RC ne 0) { _throw "Error al limpiar el contenido del directorio Config en '$locConfig': $RET"; }
        else            { $log->debug("Directorio de Config vaciado '$locConfig': $RET"); }

        # GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
        my $tarExecutable;

        ($RC, $RET) = $balix->executeas($dest_wasuser, qq| ls '$bde_conf->{tardestinosaix}' |);
        if ($RC ne 0)
        {    # No tenemos tar especial en esta máquina, asÃ­ que nos llevamos uno
            $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
            $tarExecutable = "tar";
        }
        else
        {
            $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
            $tarExecutable = $bde_conf->{tardestinosaix};
        }

        # DESCOMPRIMO
        ($RC, $RET) = $balix->executeas($dest_wasuser, "cd '$locConfig' ; $tarExecutable xvf '$remfile' ");
        if   ($RC ne 0) { _throw "Error al descomprimir Config en '$locConfig': $RET"; }
        else            { $log->debug("Config descomprimido en '$locConfig': $RET"); }

        # CHOWN
        ($RC, $RET) = $balix->execute("chown -R $dest_wasuser:$dest_wasgroup '$locConfig'/* ");
        if   ($RC ne 0) { _throw "Error al cambiar permisos de Config a $dest_wasuser:$dest_wasgroup en '$locConfig': $RET"; }
        else            { $log->debug("Config: permisos cambiados a $dest_wasuser:$dest_wasgroup en '$locConfig': $RET"); }

        # BORRO FICHERO TMP
        $balix->execute("rm -f '$remfile'");
    }
}

# investiga version de IAS en ias.jar
sub iasVersionPublico
{
    my $self     = shift;
    my $inf      = inf $self->cam;
    my $log      = $self->log;
    my $bde_conf = $self->bde_conf;
    my ($Pase, $buildhome, $subapl) = @_;
    my $iasversion = "";

    # Busca ias.jar
    # El sort asegura que las subapl más cortas vengan primero que las largas,
    # para evitar que se lea el ias.jar de otra subapl
    my @RET = `find "$buildhome" -name "ias.jar" | sort -f -A | grep "/$subapl"`;

    # con "/$subapl\\(_*EAR\\)" también filtra, pero es más restrictivo; si hace falta se utilizará.

    return "" if (!@RET);

    # lo abre en temporal, sacando versionXXXX.xml
    my $tmpdir = $bde_conf->{temp} . "/${Pase}.tmp/";
    $log->debug("ias.jar encontrado: " . join(", ", @RET));    # debug
    mkdir $tmpdir;
    chdir $tmpdir;
    foreach my $iasjar (@RET)
    {
        chop $iasjar;
        my ($VERXML) = `jar tf "$iasjar" 2>/dev/null | grep VERSION | grep xml`;
        chop $VERXML;
        if ($VERXML)
        {
            $log->debug("IAS: inspeccionando '$iasjar':" . `jar xvf "$iasjar" '$VERXML' 2>/dev/null`);    # debug
            open FXML, "<$VERXML" or die "Error al abrir fichero de versión de IAS: $VERXML";
            while (<FXML>)
            {
                if (/<version>(.*)<\/version>/)
                {                                                                                         # Bingo!
                    $iasversion = $1;
                    if ($iasversion)
                    {
                        $log->info("IAS: versión de arquitectura de ejecución IAS detectada en ias.jar: $iasversion");
                        my $VERSIONIAS = "IAS-$iasversion";
                        $log->debug(" Comprobando version Publica $VERSIONIAS  Espere ..... ");
                        my @EstadoVerPubIAS = $inf->obsolete_public_version($VERSIONIAS);
                        $log->debug('@EstadoVerPubIAS ' . Dumper \@EstadoVerPubIAS);
                        my $ESTADO = "";
                        foreach $ESTADO (@EstadoVerPubIAS)
                        {

                            if ($ESTADO eq "Obsoleto")
                            {
                                $log->warn("La version publica  $VERSIONIAS que SE ESTA UTILIZANDO esta OBSOLETA, por favor, actualice la aplicación");
                            }
                            elsif ($ESTADO eq "Borrado")
                            {
                                $log->warn("La versión pública $VERSIONIAS ha sido borrada por los responsables de la aplicación, si su pase hace uso de esta versión fallará el pase");
                                $log->warn("Si necesita utilizar la versión pública $VERSIONIAS, por favor pongase en contacto con los Responsables de la aplicación");
                            }
                        }
                        return "IAS-$iasversion";
                    }
                    else
                    {
                        $log->warn("IAS: fichero $VERXML no contiene la versión entre las etiquetas <version>...</version>");
                    }
                }
            }
            $log->warn("No he encontrado la etiqueta <version>....</version> dentro del fichero $VERXML");
            close FXML;
        }
        else
        {
            $log->warn("Fichero $iasjar no contiene xml de versión de tipo VERSIONxxxxxx.xml.");
        }
    }
    if ((-d $tmpdir) && ($tmpdir ne ""))
    {
        `rm -Rf '$tmpdir'`;
    }
    $log->warn("IAS: no he localizado la versión de IAS en ias.jar. Uso de librerÃ­as públicas de IAS descartado") if (!$iasversion);
    return "";

    # Â¿chequea si la release está disponible para este entorno?
}

sub staticExtensions
{
    my $self = shift;
    my $log  = $self->log;
    my $inf  = inf $self->cam;
    my ($EnvironmentName, $Entorno, $subapl, $nivel) = @_;

    # A ver si hay separacion entre cont estatico y dinam.
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);
    my $esEstatico = $inf->get_inf({sub_apl => $subapl}, [{column_name => "WAS_STATIC_CONTENT"}]);
    $log->debug("\$inf->get_inf({sub_apl => '$subapl'}, [{column_name => 'WAS_STATIC_CONTENT'}]) :: " . Dumper $esEstatico);    # XXX

    # Dame las extensiones
    my $EXT = $inf->get_inf(undef, [{column_name => "SCM_EXT_ESTATICAS", env => $EnvironmentName}]);
    $log->debug("\$inf->get_inf(undef, [{column_name => 'SCM_EXT_ESTATICAS', env => '$EnvironmentName'}]) :: " . Dumper $EXT);    # XXX
    my @EXT = ();
    if ($EXT)
    {
        @EXT = split ',', $EXT;
    }

    # Ahora: es inclusion o exclusion
    $log->debug("Ubicación Estáticos para $CAM:$subapl: $esEstatico");
    $log->debug("Extensiones estáticas $CAM:$subapl: $EXT");
    if ("WEB" eq uc($esEstatico))
    {
        return @EXT;                                                                                                              # inclusion
    }
    elsif ("WAS" eq uc($esEstatico))
    {
        if ($nivel =~ /EAR|WAR/)
        {                                                                                                                         # no hay exclusiones, ya van dentro del fichero EAR/WAR al Websphere
            return ();
        }
        else
        {
            return map { "-" . $_ } @EXT;                                                                                         # exclusion, -jsp, -class, -jar, -zip, etc.
        }
    }
    else
    {
        return ();
    }
}

# Distribución de contenido estático
sub htpDist
{
    my $self     = shift;
    my $log      = $self->log;
    my $bde_conf = shift;
    my ($dist, $subapl, $tarfile, $pDEST, $balix, $HTPMAQ, %p) = @_;
    my ($Pase, $PaseDir, $TipoPase, $EnvironmentName, $Entorno, $Sufijo) = ($dist->{pase}, $dist->{pasedir}, $dist->{tipopase}, $dist->{envname}, $dist->{entorno}, $dist->{sufijo});
    my ($cam, $CAM) = get_cam_uc($EnvironmentName);

    # Destino
    my %DEST = %{$pDEST || {}};
    if ($DEST{desplegar_flag} ne "Si")
    {
        $log->warn("El contenido estático no se distribuirá automáticamente a $HTPMAQ. " . "Se deberá realizar manualmente.");
        return;
    }
    if (!($HTPMAQ && $DEST{htp_dir}))
    {
        _throw "Error durante la distribución HTTP de contenido estático: faltan datos para distribuir. Máquina=$HTPMAQ, Directorio=$DEST{htp_dir}";
    }

    # Directorios
    my @tarinfo = File::Spec->splitpath($tarfile);    # just in case tarfile includes path
    my $localfile;
    if ($tarinfo[1])
    {
        $localfile = $tarfile;
        $tarfile   = $tarinfo[2];
    }
    else
    {
        $localfile = "$PaseDir/$CAM/$Sufijo/$tarfile";
    }
    my $localbakpath = "$PaseDir/$CAM/$Sufijo/bak";
    my $localbakfile = "$localbakpath/$tarfile";
    my $remfile      = "/tmp/$tarfile";
    my $rembakfile   = "/tmp/$tarfile.bak";
    if ((-e $localfile) && $tarfile)
    {
        $log->info("Contenido estático: desplegando ficheros en $HTPMAQ:$DEST{htp_dir}. Espere...");

        # PUT TAR
        my ($RC, $RET) = $balix->sendFile($localfile, $remfile);
        if   ($RC ne 0) { _throw "Contenido estático: Error al enviar fichero tar '$localfile' a '$remfile': $RET"; }
        else            { $log->debug("Contenido estático: Fichero '$remfile' en destino: $RET"); }

        # CHMOD TAR
        ($RC, $RET) = $balix->execute("chown $DEST{htp_user}:$DEST{htp_group} '$remfile'");
        if   ($RC ne 0) { _throw "Contenido estático: Error al cambiar permisos a $DEST{htp_user}:$DEST{htp_group} del fichero TAR '$remfile': $RET"; }
        else            { $log->debug("Contenido estático: Permisos de TAR cambiados: chown $DEST{htp_user}:$DEST{htp_group} '$remfile': $RET"); }

        # true si hay ficheros para hacer backup, si no el tar estará vacÃ­o y da
        # errores de todo tipo
        my $necesitaBackup = 0;

        if (($Entorno eq "PROD") && ($TipoPase ne 'B'))
        {

            # Check if backup needed
            # ret=0 si el dir existe y tiene contenido, <>0 si no '"
            ($RC, $RET) = $balix->executeas($DEST{htp_user}, qq| [ "\$(ls -A $DEST{htp_dir})" ] |);
            if ($RC ne 0)
            {
                $log->debug("Contenido estático: Directorio destino $HTPMAQ:$DEST{htp_dir} no tiene contenido. No necesita backup.");
            }
            else
            {
                $log->debug("Contenido estático: Directorio destino $HTPMAQ:$DEST{htp_dir} tiene contenido. Necesita backup.");
                $necesitaBackup = 1;

                # Gestionamos los la variable del tar a utilizar .
                my $tarExecutable;

                ($RC, $RET) = $balix->executeas($DEST{htp_user}, qq| ls '$bde_conf->{tardestinosaix}' |);
                if ($RC ne 0)
                {    # No tenemos tar especial en esta máquina, asÃ­ que nos llevamos uno
                    $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
                    $tarExecutable = "tar";
                }
                else
                {
                    $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
                    $tarExecutable = $bde_conf->{tardestinosaix};
                }

                # Create backup
                ($RC, $RET) = $balix->executeas($DEST{htp_user}, " cd '$DEST{htp_dir}' ; $tarExecutable cvf '$rembakfile' * 2>&1");
                if   ($RC ne 0) { _throw "Contenido estático: Error al crear fichero tar de backup '$rembakfile': $RET"; }
                else            { $log->info("Contenido estático: Fichero backup '$rembakfile' creado ok.", $RET); }
            }
        }

        # Mkdir
        ($RC, $RET) = $balix->executeas($DEST{htp_user}, " mkdir -p '$DEST{htp_dir}'");
        if ($RC > 0) { _throw "Contenido estático: Error al crear directorio '$DEST{htp_dir}' para desplegar estáticos (RC=$RC): $RET"; }

        # Gestionamos los la variable del tar a utilizar .
        my $tarExecutable;
        ($RC, $RET) = $balix->executeas($DEST{htp_user}, qq| ls '$bde_conf->{tardestinosaix}' |);
        if ($RC ne 0)
        {    # No tenemos tar especial en esta máquina, asÃ­ que nos llevamos uno
            $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
            $tarExecutable = "tar";
        }
        else
        {
            $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
            $tarExecutable = $bde_conf->{tardestinosaix};
        }

        # Mkdir untar
        ($RC, $RET) = $balix->executeas($DEST{htp_user}, " cd '$DEST{htp_dir}' ; rm -Rf '$DEST{htp_dir}'/* ; $tarExecutable xvf '$remfile' 2>&1");
        if   ($RC ne 0) { _throw "Contenido estático: Error al enviar fichero tar '$localfile' a '$remfile': $RET"; }
        else            { $log->info("Contenido estático: Fichero desplegado ok.", $RET); }

        # Borro fichero tmp
        $balix->execute("rm -f '$remfile'");

        # Get backup
        if (($TipoPase ne 'B') && ($Entorno eq "PROD") && ($necesitaBackup) && (!$p{no_backup}))
        {
            use File::Path;
            mkpath($localbakpath);    # crea el path incluso intermedios
            ($RC, $RET) = $balix->getFile($rembakfile, $localbakfile);
            if ($RC ne 0) { $log->warn("Contenido estático: Backup: no se ha podido recuperar el fichero tar '$rembakfile' a '$localbakfile'. Puede que no existiesen ficheros en la ubicación $HTPMAQ:$DEST{htp_dir} para hacer el backup.", $RET); }
            else          { $log->debug("Contenido estático: Backup: fichero '$rembakfile' recuperado: $RET"); }

            # Store backup
            if (-e $localbakfile)
            {
                my ($idbak, $sizebak) = store_backup($EnvironmentName, $Entorno, $subapl, $Sufijo, $Pase, "HTP", $localbakfile);
                $log->info("Contenido estático: Backup: fichero de backup HTTP almacenado correctamente ($tarfile contiene ${sizebak} kb)" . $idbak);    # text filie
            }
            else { $log->debug("Contenido estático: No hay ficheros de backup para almacenar."); }
        }

        $balix->execute("rm -f '$rembakfile'");
        $log->info("Contenido estático: Fin del envÃ­o de contenido estático.");
    }
    else
    {
        _throw "Error: no encuentro el fichero de contenido estático en local: '$localfile'";
    }
}
###################################################################
## despliegue en el servidor Destino
##
sub despliegueWEB
{
    my $self     = shift;
    my $log      = $self->log;
    my $inf      = inf $self->cam;
    my $bde_conf = $self->bde_conf;
    local our %Dist;
    *Dist = shift();
    my ($subapl, $prj, $file, $pPRJMAP) = @_;
    my ($Pase, $PaseDir, $Entorno, $TipoPase, $EnvironmentName, $Sufijo) = ($Dist{pase}, $Dist{pasedir}, $Dist{entorno}, $Dist{tipopase}, $Dist{envname}, $Dist{sufijo});
    my ($cam, $CAM) = ($Dist{cam}, $Dist{CAM});
    my %DEST         = $inf->get_inf_destinos($Entorno, $subapl);
    my %PRJMAP       = ();
    my $balixCluster = "";
    %PRJMAP = %{$pPRJMAP} if ($pPRJMAP);
    $log->info("Desplegando $CAM Subaplicación $subapl en $DEST{maq} ($DEST{user})...");

    # quita el ./ (punto-barra) del principio, que el script de was no lo traga
    $file =~ s{^\./}{}g;

    if ($subapl)
    {

        # my $Red = getInfSubRed($CAM, $Entorno, $subapl);
        my $Red = $inf->get_inf_subred($Entorno, $subapl);
        $log->info("Directorio de Config de Subaplicación $subapl: $DEST{config_dir}") if ($DEST{tech} =~ /^IAS|^EDW4J|^J2EE_BDE/);    # info
        if (($DEST{tech} =~ /^IAS|^EDW4J|^J2EE_BDE/) && ($DEST{config_dir} eq ""))
        {
            $log->error("Directorio de Configuración en blanco. Verifique el formulario de infraestructura, pestaña Java->[$subapl]->Servidor WAS->Dir. de Configuración.");
            _throw "Error: datos de infraestructura incompletos para la subaplicación $subapl.";
        }

        # HARAX conectado a servidor de WAS
        $log->debug("Conectando a $DEST{maq}, $DEST{puerto}...");
        my $balix = $balix_pool->conn_port($DEST{maq}, $DEST{puerto});
        $log->debug("Ok. Conectado a $DEST{maq}, $DEST{puerto}.");
        if ($DEST{server_cluster})
        {
            $log->debug("Conectando a $DEST{server_cluster}, $DEST{puerto}...");
            $balixCluster = $balix_pool->conn_port($DEST{server_cluster}, $DEST{puerto});
            $log->debug("Ok. Conectado a $DEST{server_cluster}, $DEST{puerto}.");
        }

        # Creo el dir destino:
        $log->debug("Creando directorio destino temporal de pase: mkdir -p $DEST{home} (con usuario $DEST{user})");
        my ($RC, $RET) = $balix->executeas($DEST{user}, "mkdir -p $DEST{home}");
        if ($RC ne 0)
        {
            _throw "Error al crear el directorio temporal de despliegue $DEST{home}: $RET";
        }
        else
        {
            $log->debug("Directorio de despliegue '$DEST{home}' creado: $RET");
        }

        # CONFIG
        if (($DEST{tech} =~ /^IAS|^EDW4J|^J2EE_BDE/) && ($DEST{config_dir} ne ""))
        {
            my $fichConfig = "config_${subapl}.tar";
            my $pathConfig = "$PaseDir/$CAM/$Sufijo/$fichConfig";

            # busco en carpetas de WEB si hay Config - si lo hay, lo tareo
            if ($PRJMAP{$prj}{WARS})
            {
                unlink $pathConfig;
                my @WARPRJS = @{$PRJMAP{$prj}{WARS}};
                foreach my $wardir (@WARPRJS)
                {
                    if ($wardir)
                    {

                        # TODO: el nombre del VP de config podrÃ­a cambiar.
                        my $configvp = "$PaseDir/$CAM/$Sufijo/$wardir/Config";
                        $log->debug("configvp => $configvp");

                        if (-e $configvp)
                        {
                            $log->debug("Config: incluyo el contenido del directorio '$configvp' en el tar de config '$pathConfig'...");
                            my @RET = `cd '$configvp' ; $bde_conf->{gnutar} -cvf '$pathConfig' *`;
                            $log->debug("Config: fichero tar de config construido ok. ", join('', @RET));
                        }
                        else
                        {
                            $log->warn("Config: no he encontrado el directorio config $configvp. No se desplegará fichero config para el proyecto $wardir.");
                        }
                    }
                }
            }

            # Busco a ver si hay un tar de config tipo config_subapl.tar y lo
            # despliego:
            $log->debug("Buscando fichero de config generado '$pathConfig'...");
            if (-e "$pathConfig")
            {
                $self->configDist($balix, $DEST{was_user}, $DEST{was_group}, $DEST{config_dir}, $pathConfig, "$DEST{home}/$fichConfig");
                $log->info("$PaseDir/$CAM/$Sufijo", $fichConfig, "Config desplegado ok ($DEST{config_dir}).");    # logfile!""
                                                                                                                  # $webNeedRollback = 1;  # TODO
                if ($balixCluster)
                {
                    $log->info("Desplegando directorio de config a la máquina de cluster $DEST{server_cluster}");
                    $self->configDist($balixCluster, $DEST{was_user}, $DEST{was_group}, $DEST{config_dir}, $pathConfig, "$DEST{home}/$fichConfig");
                    $balixCluster->end();
                    $log->info("Config desplegado ok en cluster.");
                }
            }
            else
            {
                $log->warn("Fichero Config '$PaseDir/$CAM/$Sufijo/$fichConfig' no encontrado.");
            }
        }

        # Si es sólo config, aqui lo dejo
        if ($Dist{nivel} ne 'CONF')
        {

            # Envio fichero
            ($RC, $RET) = $balix->sendFile("$PaseDir/$CAM/$Sufijo/$file", "$DEST{home}/$file");
            if ($RC ne 0)
            {
                _throw "Error al enviar fichero de la aplicación '$DEST{home}/${file}': $RET";
            }
            else
            {
                $log->debug("Fichero '$DEST{home}/${file}' creado en staging: $RET");
            }
            ($RC, $RET) = $balix->execute("chown $DEST{was_user}:$DEST{was_group} $DEST{home}/$file ; chmod 750 $DEST{home}/$file");
            if ($RC ne 0)
            {
                _throw "Error al cambiar permisos a '$DEST{user}' del fichero '$DEST{home}/$file': $RET";
            }
            else
            {
                $log->debug("Fichero '$DEST{home}/$file' con permisos para '$DEST{user}': $RET");
            }

            # Despliegue
            my $accionWAS = $self->accionWAS($Entorno, $file);

            $log->info("Configuracion del comando de Despliegue en WAS.\n" . "script de WAS --> $bde_conf->{was_script}\n" . "Contexto      --> $DEST{was_context_root}\n" . "Accion        --> $accionWAS\n" . "Fichero       --> $DEST{home}/$file\n" . "Version DMGR  --> $DEST{was_ver}\n" . "Reinicio      --> $DEST{reinicio_web}");

            $log->debug("Remaphore request for $Pase in $Entorno");
            my $sem = Baseliner->model('Semaphores')->request(
                                                              sem => 'bde.j2ee.test',
                                                              bl  => $Entorno,
                                                              who => $Pase
                                                             );
            $log->debug("Please wait...");

            # $sem->wait_for;
            $log->debug("Slot granted!");
            $log->info("Desplegando fichero '$DEST{home}/$file' en WAS. Espere...", qq| $bde_conf->{was_script} $DEST{was_context_root} $accionWAS '$DEST{home}/$file' $DEST{was_ver} $DEST{reinicio_web}  |);
            my $cmd = qq|cd $DEST{home} ; $bde_conf->{was_script} $DEST{was_context_root} $accionWAS '$DEST{home}/$file' $DEST{was_ver} $DEST{reinicio_web}|;
            $log->debug($cmd);
            ($RC, $RET) = $balix->executeas($DEST{was_user}, $cmd);
            $log->debug("Release slot");
            $sem->release;

            if (($RC != 0) && ($RC != 2) && ($RC != 512))
            {
                $log->error("Error al desplegar '$DEST{home}/$file' (RC=$RC)\n" . $RET);
                _throw "Error durante el despliegue '$DEST{home}/$file'";
            }
            else
            {
                my $msg = "Fichero '$DEST{home}/$file' desplegado " . ($RC eq 2 ? "con warnings " : "") . "(RC=$RC).";
                if (($RC == 2) || ($RC == 512))
                {
                    $log->warn($msg, $RET);
                }
                else
                {
                    $log->info($msg, $RET);
                }

                # $webNeedRollback = 1;  # TODO

                # borro el fichero
                ($RC, $RET) = $balix->executeas($DEST{was_user}, "rm -f '$DEST{home}/$file'");
                $log->debug("Fichero $DEST{maq}:$DEST{home}/$file borrado (RC=$RC).", $RET);
            }
        }

        # Reinicio
        if ($DEST{reinicio} eq 1)
        {

            # STOP WAS
            $log->debug("Parando la aplicación WAS...");

            ($RC, $RET) = $balix->executeas($DEST{was_user}, "$bde_conf->{was_script} $DEST{was_context_root} stopApplication $DEST{was_ver}");
            if ($RC != 0)
            {
                if ($RC == 512)
                {    # es que estaba caido, no problem
                    $log->warn("La aplicación ya estaba parada.", $RET);
                }
                else
                {

                    # Modificado de logerr a logwarn para no LIAR a los usuarios
                    $log->warn("No se ha podido parar la aplicación con $DEST{was_user}:'$bde_conf->{was_script} $DEST{was_context_root} stopApplication $DEST{was_ver}' (RC=$RC)", $RET);
                }
            }
            else
            {
                my $dest_clone = $RET;
                $dest_clone =~ s/.*Server(.*?) *de *(.*?) *en.*/$1-$2/s;
                my $msg = "Ok. WAS $dest_clone parado " . ($RC eq 2 ? "con warnings " : "") . " con usuario '$DEST{was_user}' (RC=$RC).";
                if ($RC eq 2)
                {
                    $log->warn($msg, $RET);
                }
                else
                {
                    $log->info($msg, $RET);
                }
            }

            # START WAS
            $log->info("Arrancando la aplicación WAS...");

            ($RC, $RET) = $balix->executeas($DEST{was_user}, "$bde_conf->{was_script} $DEST{was_context_root} startApplication $DEST{was_ver}");
            if ($RC != 0)
            {

                # Es que estaba caido, no problem:
                if ($RC == 512)
                {
                    $log->warn("La aplicación ya estaba arrancada.", $RET);
                }
                else
                {

                    # Modificado de logerr a logwarn para no LIAR a los usuarios.
                    $log->warn("No se ha podido arrancar la aplicación con $DEST{was_user}:'$$bde_conf->{was_script} $DEST{was_context_root} startApplication $DEST{was_ver}' (RC=$RC)", $RET);
                }
            }
            else
            {
                my $dest_clone = $RET;
                $dest_clone =~ s/.*Server(.*?) *de *(.*?) *en.*/$1-$2/s;
                my $msg = "Ok. WAS $dest_clone reiniciado " . ($RC eq 2 ? "con warnings " : "") . " con usuario '$DEST{was_user}' (RC=$RC).";
                if ($RC eq 2)
                {
                    $log->warn($msg, $RET);
                }
                else
                {
                    $log->info($msg, $RET);
                }
            }
        }

        # Logs de WAS
        $self->wasLogFiles($balix, $EnvironmentName, $Entorno, $Red, %DEST);
        $balix->end();

    }
    else
    {
        _throw "No he podido determinar la subaplicación para el proyecto '$prj'";
    }
}

sub accionWAS
{
    my $self    = shift;
    my $Entorno = shift();
    my $file    = shift();
    return 'updateEAR' if (!$file || $self->earObligatorio($Entorno));
    if ($file =~ m/\.tar$|\.tar\.gz$/i)
    {
        return 'updateFiles';
    }
    elsif ($file =~ m/.jar$/i)
    {
        return 'updateEJB';
    }
    elsif ($file =~ m/.war$/i)
    {
        return 'updateWAR';
    }
    elsif ($file =~ m/.ear$/i)
    {
        return 'updateEAR';
    }
    return 'udpateEAR';
}

sub earObligatorio
{
    my $self     = shift;
    my $bde_conf = $self->bde_conf;
    my $Entorno  = shift;
    return 1 if $bde_conf->{ear_obligatorio} eq "1";
    $bde_conf->{ear_obligatorio} =~ m/$Entorno/i ? 1 : 0;
}

sub getClasspathWAS
{
    my $self     = shift;
    my $log      = $self->log;
    my $inf      = inf $self->cam;
    my $bde_conf = $self->bde_conf;
    my $cam      = shift();
    my $subapl   = shift();
    my $Entorno  = shift();
    my $red      = $inf->get_inf_subred(substr($Entorno, 0, 1), $subapl);
    my $wasVersion = $inf->get_inf(
                                   {subapl => $subapl},
                                   [
                                    {
                                     column_name => "WAS_SERVER_VERSION",
                                     ident       => substr($Entorno, 0, 1),
                                     idred       => $red
                                    }
                                   ]
                                  );
    _log qq{
  	  my \$wasVersion = \$inf->get_inf({subapl => '$subapl'},
                                 [{column_name => "WAS_SERVER_VERSION",
                                   ident       => substr('$Entorno', 0, 1),
                                   idred       => '$red'}]);
  };
    $log->debug("\$wasVersion en getClasspathWAS => $wasVersion");

    my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
                                                          {
                                                           entorno => $Entorno,
                                                           sub_apl => $subapl,
                                                           cam     => $cam
                                                          }
                                                         );

    my $classpath = $resolver->get_solved_value("\$\{was_pathlib_$wasVersion\}");

    if ((index $classpath, "was") > -1 || (index $classpath, "WAS") > -1)
    {

        # ...
    }
    else
    {
        $classpath = $bde_conf->{classpath};
        $log->warn("No se pudo resolver el classpath para la versión de WAS especificada en el formulario: $wasVersion, o bien su valor no es correcto. Se usará el classpath por defecto $classpath");
    }
    $log->debug("Versión de librerías WAS usadas para compilar $subapl: $wasVersion. Path: $classpath");

    $log->debug("classpath: " . Dumper $classpath);

    return $classpath;
}

=head2 workspace_subapls( $workspace_dir, @proyectos )

Analiza el workspace, basándose en por lo menos un proyecto pasado como parámetro, y devuelve las subapls derivadas del nombre de EAR 

=cut

sub workspace_subapls
{
    my $self      = shift;
    my $buildhome = shift;

    my @subapls = @_;
    return () unless scalar @subapls;

    my %subapl_jar;
    my %subapl_ear;

    # J2EE EARs
    my $Workspace = BaselinerX::Eclipse::J2EE->parse(workspace => $buildhome);
    my @ear = $Workspace->getEarProjects($Workspace->getRelatedProjects(@_));

    for (@ear)
    {
        $subapl_ear{$self->_subapl($_)} = $_;
    }

    # Java JARs
    my $w = BaselinerX::Eclipse::Java->parse(workspace => $buildhome);
    $subapl_jar{$self->_subapl($_)} = $_ for grep { /_BATCH$/ } $w->getProjects(@_);

    return {
            ears => [keys %subapl_ear],
            jars => [keys %subapl_jar]
           };
}

sub getJDKVersion
{
    my $self = shift;
    my $log  = $self->log;
    my ($CAM, $Entorno, $subapl) = @_;
    my $inf = inf $self->cam;
    my $net = $inf->get_inf_subred(substr($Entorno, 0, 1), $subapl);

    $log->debug("\$inf->get_inf_subred(substr('$Entorno', 0, 1), '$subapl') :: " . Dumper $net);

    my $jdkVersion = $inf->get_inf(
                                   {sub_apl => $subapl},
                                   [
                                    {
                                     column_name => 'WAS_JDK_VERSION',
                                     ident       => substr($Entorno, 0, 1),
                                     idred       => $net
                                    }
                                   ]
                                  );

    # FIXME There are problems when the sub-aplication doesn't exist, as it
    # returns []. I'll put 1.5 as a default value since I'm just testing at the
    # moment. Delete or fix in the future.
    if (ref $jdkVersion eq 'ARRAY')
    {
        $jdkVersion = '1.6';
        $log->warn("WARNING: jdk_version not found, using $jdkVersion");
    }

    $log->debug("Versión de JDK detectada: $jdkVersion");
    $jdkVersion;
}

# Should be moved to utils oslt...
sub dist_entornos
{
    my ($self, $cam, $entorno) = @_;
    my $sql = qq{
    SELECT   ID, cam, entorno, environmentname, ciclo, vista_co, nivel
        FROM distentornos
       WHERE UPPER (cam) = UPPER ('$cam') AND UPPER (entorno) = UPPER ('$entorno')
    ORDER BY ID DESC
  };
    my $har  = BaselinerX::CA::Harvest::DB->new;
    my @rows = $har->db->array_hash($sql);
    if (@rows > 10)
    {
        for (10 .. $#rows)
        {
            my $id = $rows[$_]->{id};
            $har->db->do("DELETE FROM distentornos WHERE ID = $id");
        }
    }
    $rows[0];    # Row with highest ID.
}

1;
