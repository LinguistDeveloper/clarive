package BaselinerX::Model::Oracle::Distribution;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use BaselinerX::SQL::Utils;
use Data::Dumper;
use Moose;
use Try::Tiny;
use utf8;
  
has 'AcrEnt',          is => 'rw', isa => 'Any',     lazy_build => 1;
has 'cam',             is => 'ro', isa => 'Str',     required   => 1;
has 'DatoDesp',        is => 'rw', isa => 'Any';
has 'env',             is => 'ro', isa => 'Str',     required   => 1;
has 'gnutar',          is => 'ro', isa => 'Str',     lazy_build => 1;
has 'inf',             is => 'rw',                   lazy_build => 1;
has 'log',             is => 'rw', isa => 'Object',  required   => 1;
has 'Objects',         is => 'rw', isa => 'Any';
has 'Objects',         is => 'rw';
has 'Objetos',         is => 'rw', isa => 'HashRef';
has 'OraInstancia',    is => 'rw', isa => 'Any';
has 'OraNetCode',      is => 'rw', isa => 'Any';
has 'OraOID',          is => 'rw', isa => 'Any';
has 'OraOwner',        is => 'rw', isa => 'Any';
has 'OraRed',          is => 'rw', isa => 'Str',     lazy_build => 1;
has 'OraServer',       is => 'rw', isa => 'Any';
has 'OraUser',         is => 'rw', isa => 'Any',     lazy_build => 1;
has 'PREFIX',          is => 'rw', isa => 'Any';
has 'resolver',        is => 'ro', isa => 'Object',  lazy_build => 1;
has 'sqlNeedRollback', is => 'rw', isa => 'Any';
has 'tar_dest_aix',    is => 'ro', isa => 'Str',     lazy_build => 1;
has 'Types',           is => 'ro', isa => 'HashRef', lazy_build => 1;
has 'TypesDDL',        is => 'ro', isa => 'HashRef', lazy_build => 1;

my $balix_pool = BaselinerX::Dist::Utils::BalixPool->new;

sub sqlBuild {
  my $self = shift;
  my $log = $self->log;
  my %Elements = %{shift @_};
  my ($Pase, $PaseDir, $EnvironmentName, $Entorno, $Sufijo, $pckref) = @_;
  my @Packages = @{$pckref};
  my ($cam, $CAM) = get_cam_uc($EnvironmentName);
  my $OraRed = $self->OraRed;

  if (length($OraRed) eq 0) {
    $log->error("No están configuradas las Redes en Infraestructura");
    _throw "Pase finalizado sin éxito";
  }
  $OraRed =~ s/[\$\[\]]//g;
  my $buildhome = "$PaseDir/$CAM/$Sufijo";
  my $sigoSinBackup = $self->inf->get_inf(undef, [{column_name => 'SCM_SEGUIR_SIN_BACKUP'}]);
  if ($self->ValidaDDL(\%Elements, $PaseDir) eq 0) {
    $log->info("Validados con éxito los elementos del pase $Pase");
    if ($self->GenerarScriptBackup(\%Elements, $PaseDir, $CAM, $Entorno, $Pase, $EnvironmentName, $sigoSinBackup) eq 0) {
      $log->info("BACKUP realizado con éxito\n");
    }
    else {
      if ($sigoSinBackup ne "Si") {
        $log->error("Errores al realizar BackUp de los DDL del pase\n");
        _throw "Pase finalizado sin éxito";
      }
      else {
        $log->warn("Errores al realizar BackUp de los DDL del pase\n");
      }
    }
    if ($self->GenerarScriptDeploy(\%Elements, $PaseDir, $CAM, $Entorno, $Pase, $EnvironmentName) ne 0) {
      $log->error("No se ha podido realizar el despliegue de los DDL's del pase\n");
      _throw "Pase finalizado sin éxito";
    }
  }
  else {
    $log->error("Se han producido errores durante la validación de los DDL's del pase\n");
    _throw "Pase finalizado sin éxito";
  }
  $balix_pool->purge;
  return 1;
}

sub ValidaDDL {
  my $self = shift;
  my $log = $self->log;
  my %Files        = %{shift @_};
  my $PaseDir      = shift @_;
  my ($ObjectName) = "";
  my ($CreateFnd, $Retorno, $BuscaComentarios, $ErrCnt, $BeginCnt, $i) = 0;
  my ($FindName, $Pattern, $Element, $FileName, @RET, $RET, $Carpeta, $Omitido, @Omitidos);
  $Retorno = 0;
  foreach $Element (keys %Files) {
    $ErrCnt = 0;
    my $FileName        = $Files{$Element}->{FileName}; 
    my $ObjectName      = $Files{$Element}->{ObjectName}; 
    my $PackageName     = $Files{$Element}->{PackageName}; 
    my $SystemName      = $Files{$Element}->{SystemName}; 
    my $SubSystemName   = $Files{$Element}->{SubSystemName}; 
    my $DSName          = $Files{$Element}->{DSName}; 
    my $Extension       = $Files{$Element}->{Extension}; 
    my $ElementState    = $Files{$Element}->{ElementState}; 
    my $ElementVersion  = $Files{$Element}->{ElementVersion}; 
    my $ElementPriority = $Files{$Element}->{ElementPriority}; 
    my $ElementPath     = $Files{$Element}->{ElementPath}; 
    my $ElementID       = $Files{$Element}->{ElementID}; 
    my $ParCompIni      = $Files{$Element}->{ParCompIni}; 
    my $NewID           = $Files{$Element}->{NewID}; 
    my $HarvestProject  = $Files{$Element}->{HarvestProject}; 
    my $HarvestState    = $Files{$Element}->{HarvestState}; 
    my $HarvestUser     = $Files{$Element}->{HarvestUser}; 
    my $ModifiedTime    = $Files{$Element}->{ModifiedTime}; 
    next if ($ElementState eq 'D');
    if ($Extension !~ m/PKG|PRC|FNC|TRG|VIW|SPC|BDY|SYN|VW|PKS|PKB|PCK|TYP|TPB|TPS/i) {
      push @Omitidos, "Extensión $Extension no soportada. Ignorado fichero $FileName\n";
      next;
    }
    $FileName   =~ s/{PROD}|{ANTE}|{TEST}//gi;
    $ObjectName =~ s/{PROD}|{ANTE}|{TEST}//gi;
    if ((!-e "$PaseDir$ElementPath/$FileName") && ($ElementState ne 'D')) { next; }  ## Fichero Renombrado que no pertenece a este entorno

    $BuscaComentarios             = 0;
    $BeginCnt                     = 0;
    $FindName                     = $ObjectName;
    my $Objetos = $self->Objetos;
    $Objetos->{$ObjectName} = "$FileName";
    $self->Objetos($Objetos); # This might be destroyed on further iterations!
    $self->Objects($self->Objects . "'" . $ObjectName . "',");
    my %Types = %{$self->Types};
    $Pattern = ' ' . $Types{lc($Extension)} . ' ';  ## Añado espacios para buscar por palabra completa y evitar que sea parte del nombre del objeto.
    open FileIN, "<$PaseDir$ElementPath/$FileName" or die "No puedo abrir el fichero $FileName \n";
    @RET = <FileIN>;

    foreach $RET (@RET) {
      if (($CreateFnd eq 0) && ($RET !~ m/--|CREATE[\s]*OR[\s]*REPLACE/i) && ($RET =~ m/\S/g)) {
        $log->debug("El script no comienza por CREATE OR REPLACE...\n");
        $ErrCnt++;
        last;
      }
      if (($RET =~ m/CREATE[\s]*OR[\s]*REPLACE/i) && ($RET !~ m/SYNONYM/i)) {
        $RET =~ s/\"//g;  ## Quito comillas.
        $CreateFnd++;
        $FindName =~ s/\$/\\\$/g;

        ## Verificamos que cree el objeto con el mismo nombre que el script.
        if ($RET !~ m/CREATE[\s]*or[\s]*REPLACE.*$Pattern.*$FindName/i) {
          $log->debug("La creación del objeto no se ajusta a la estructura CREATE OR REPLACE...$Types{$Extension} $ObjectName...\n");
          $ErrCnt++;
        }

        ## Verificamos que el objeto no es calificado con el owner.
        if (substr($RET, index(uc($RET), uc($FindName)) - 1, 1) eq '.') {              
          $log->debug("El objeto esta calificado\n");
          $ErrCnt++;
        }
      }
      if (($RET =~ m/BEGIN/i) || ($RET =~ m/PACKAGE BODY/i) || ($RET =~ m/TYPE BODY/i)) { $BeginCnt++; }
      if ($RET =~ m/END;/i && $BeginCnt gt 0) { $BeginCnt--; }

      if ((($RET =~ m/END;/i) && ($RET !~ m/\wEND;/i) && ($BeginCnt eq 0)) || ($BuscaComentarios eq 1)) {
        $BuscaComentarios = 1;
        $RET =~ s/  //g;        ## Quito espacios.
        $RET =~ s/^ //g;        ## Quito espacios al principio.
        $RET =~ s/\n|\r|\f//g;  ## Quito Saltos de línea.

        if ($RET =~ m/END;/i) {
          $i = index(uc($RET), 'END;') + 4;
        }
        else {
          $i = 0;
        }

        $i++ if substr($RET, $i, 1) eq ' ';
        if (length($RET) > $i) {
          if (
               substr($RET, $i, 2) ne '--'
            && substr($RET, $i, 1) ne '/'
            && ( (($RET !~ m/ALTER.*ENABLE|CREATE.*REPLACE.*SYNONYM|ALTER.*COMPILE/i) && $Extension =~ m/PRC|FNC|TRG|VIW|SPC|BDY|SYN|VW|PKS|PKB|TPS|TPB/i)
              || (($Extension =~ m/PKG|PCK/i) && ($RET !~ m/CREATE.*REPLACE.*PACKAGE BODY|ALTER.*COMPILE/i))
              || (($Extension =~ m/TYP/i) && ($RET !~ m/CREATE.*REPLACE.*TYPE BODY|ALTER.*COMPILE/i)))
            )
          {
            $log->debug("Hay caracteres no permitidos al final del script: $RET\n");
            $ErrCnt++;
          }
          if ( (($Extension =~ m/PKG|PCK/i) && ($RET !~ m/CREATE.*REPLACE.*PACKAGE BODY|ALTER.*COMPILE/i))
            || (($Extension =~ m/TYP/i) && ($RET !~ m/CREATE.*REPLACE.*TYPE BODY|ALTER.*COMPILE/i)))
          {
            $BuscaComentarios = 0;
          }
        }
      }
    }
    close FileIN;
    if   ($ErrCnt eq 0) { $log->info("DDL $FileName Validada con exito\n"); }
    else                { $log->warn("$ErrCnt errores encontrados en $FileName\n"); $Retorno++ }
  }
  if (@Omitidos ne 0) {
    my $Cadena    = "Se han ignorado ficheros por no estar soportados por la utilidad.\n Sólo se procesarán los ficheros con extensión: BDY, FNC, PCK, PKB, PKG, PKS, PRC, SPC, SYN, TRG, TYP, TPS, TPB, VIW ó VW",;
    my $CadenaLOG = "";
    foreach $Omitido (@Omitidos) { $CadenaLOG .= "- $Omitido\n"; }
    $log->debug("$Cadena", $CadenaLOG);
  }

  my $tempObjects = $self->Objects;
  chop $tempObjects;
  $self->Objects($tempObjects);
  if ($Retorno gt 0) {
    $log->error("Se han producido errores durante la validación de los scripts del pase");
    _throw "Se han producido errores durante la validación de los DDL's del pase\n";
  }
  return ($Retorno);
}

sub GenerarScriptBackup {
  my $self = shift;
  my $log = $self->log;
  my %Files           = %{shift @_};
  my $PaseDir         = shift @_;
  my $cam             = shift @_;
  my $Entorno         = shift @_;
  my $Pase            = shift @_;
  my $EnvironmentName = shift @_;
  my $SeguirSinBu     = shift @_;
  my $haraxDir        = "/tmp/$Pase/BackUp";
  my (@RET, $RET, $RC);
  my ($Element, $carpetaAnt, $OraRed, $OraRedES) = "";
  my (@redes, %redesatratar);
  my %Tratado;
  my ($harax, $puerto, $_log);
  my $UserExists = 1;
  my $LISTTAR;

  # _log "FILES => " . Dumper \%Files;

  my ($FileName,       $ObjectName,      $PackageName,    $SystemName,
      $SubSystemName,  $DSName,          $Extension,      $ElementState,
      $ElementVersion, $ElementPriority, $carpeta,        $ElementID,
      $ParCompIni,     $NewID,           $HarvestProject, $HarvestState,
      $HarvestUser,    $ModifiedTime,    $Instancias,     %DESPLIEGUES);

  $log->info("Generando script para realizar BACKUP del pase\n");
  mkdir "$PaseDir/BackUp";

  # Para cada objeto involucrado generamos una linea para trar su DDL
  foreach $Element (keys %Files) {    
    my $FileName        = $Files{$Element}->{FileName}; 
    my $ObjectName      = $Files{$Element}->{ObjectName}; 
    my $PackageName     = $Files{$Element}->{PackageName}; 
    my $SystemName      = $Files{$Element}->{SystemName}; 
    my $SubSystemName   = $Files{$Element}->{SubSystemName}; 
    my $DSName          = $Files{$Element}->{DSName}; 
    my $Extension       = $Files{$Element}->{Extension}; 
    my $ElementState    = $Files{$Element}->{ElementState}; 
    my $ElementVersion  = $Files{$Element}->{ElementVersion}; 
    my $ElementPriority = $Files{$Element}->{ElementPriority}; 
    my $ElementPath     = $Files{$Element}->{ElementPath};
    my $carpeta         = $Files{$Element}->{ElementPath};
    my $ElementID       = $Files{$Element}->{ElementID}; 
    my $ParCompIni      = $Files{$Element}->{ParCompIni}; 
    my $NewID           = $Files{$Element}->{NewID}; 
    my $HarvestProject  = $Files{$Element}->{HarvestProject}; 
    my $HarvestState    = $Files{$Element}->{HarvestState}; 
    my $HarvestUser     = $Files{$Element}->{HarvestUser}; 
    my $ModifiedTime    = $Files{$Element}->{ModifiedTime};

    next if ($Extension !~ m/PKG|PRC|FNC|TRG|VIW|SPC|BDY|SYN|VW|PKS|PKB|PCK|TYP|TPS|TPB/i);

    $FileName   =~ s/{PROD}|{ANTE}|{TEST}//gi;
    $ObjectName =~ s/{PROD}|{ANTE}|{TEST}//gi;

    ## Fichero Renombrado que no pertenece a este entorno
    next if ((!-e "$PaseDir$carpeta/$FileName") && ($ElementState ne 'D'));    

    if ($carpeta ne $carpetaAnt) {
      $Instancias = _folder_ora_data($cam, $carpeta, $Entorno);
      $carpetaAnt = $carpeta;

      if (scalar keys %$Instancias eq 0) {
        $log->warn("Los elementos de la carpeta $carpeta no se han distribuido en la red de destino.\n"
                 . "Si desea distribuirlos, entre en la pestaña Oracle del formulario del paquete harvest y configure la instancia destino de la carpeta $carpeta.");
        next;
      }
      else {
        my @Despliegues = ();
        for my $dato (keys %{$Instancias}) {
          if ($dato =~ m/^(.*)\_(.*)\_(.*)$/) {
            $self->OraNetCode($1);
            $self->OraOwner($2);
            $self->OraOID($3);
          }
          $OraRed = $self->resolver->get_solved_value($self->OraNetCode);
          $self->OraInstancia($self->resolver->get_solved_value($self->OraOID));

          my $msg = $self->OraOwner . " en " . $self->OraInstancia . " {$OraRed}";
          push @Despliegues, $msg;
          $DESPLIEGUES{$dato} = $$Instancias{$dato};
        }
        $log->debug("Los elementos de la carpeta $carpeta se distribuirán a los siguientes destinos:\n" . join("\n", @Despliegues));
      }
    }

    _log 'Instancias: ' . Dumper $Instancias; # XXX

    for my $dato (keys %$Instancias) {
      if ($dato =~ m/^(.*)\_(.*)\_(.*)$/) {
        $self->OraNetCode($1);
        $self->OraOwner($2);
        $self->OraOID($3);
      }
      $OraRed = $self->resolver->get_solved_value($self->OraNetCode);
      $self->OraInstancia($self->resolver->get_solved_value($self->OraOID));
      $self->OraServer($self->resolver->get_solved_value($$Instancias{$dato}));
      $self->PREFIX($self->OraServer. "\_" . substr($self->resolver->get_solved_value($dato), 3));
      _log 'instancias_dato: ' . $$Instancias{$dato};    # XXX
      _log 'OraServer: ' . $self->OraServer;             # XXX
      _log 'Dato: ' . $dato;                             # XXX
      _log 'PREFIX: ' . $self->PREFIX;                   # XXX
      $self->OraOwner(uc($self->OraOwner));

      if ($Tratado{$self->PREFIX . "\_$FileName"} ne "T") {
        open FBKOUT, ">>:encoding(iso-8859-15)", "$PaseDir/BackUp/" . $self->PREFIX . ".sql";
        if (-z "$PaseDir/Backup/" . $self->PREFIX . ".sql") {
          print FBKOUT "SET ECHO OFF NEWP 0 SPA 1 PAGES 0 LINES 4000 FEED OFF HEAD OFF TRIMS ON TERMOUT OFF DEFINE OFF VERIFY OFF EMBEDDED ON\n";
          print FBKOUT "SET SERVEROUTPUT ON\n";
          print FBKOUT "COLUMN TXT FORMAT a4000 WORD_WRAPPED\n";
          print FBKOUT "SET LONG 1048576\n";
          print FBKOUT "WHENEVER SQLERROR CONTINUE;\n";
          print FBKOUT "WHENEVER OSERROR CONTINUE;\n";
          print FBKOUT "EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);\n";
          print FBKOUT "EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);\n";
          print FBKOUT "EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);\n";
          print FBKOUT "EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'REF_CONSTRAINTS',false);\n";
        }
        print FBKOUT "SPOOL " . uc($self->PREFIX . "\_$FileName") . "\n";
        my %TypesDDL = %{$self->TypesDDL};

        ## Recuperamos el DDL
        print FBKOUT "SELECT DBMS_METADATA.get_ddl('$TypesDDL{lc($Extension)}','$ObjectName','" . $self->OraOwner . "') TXT FROM DUAL;\n";

        $Tratado{$self->PREFIX . "\_$FileName"} = "T";
        close FBKOUT;
      }
    }
  }

  for my $dato (sort keys %DESPLIEGUES) {
    if ($dato =~ m/^(.*)\_(.*)\_(.*)$/) {
      $self->OraNetCode($1);
      $self->OraOwner($2);
      $self->OraOID($3);
    }

    $OraRed = $self->resolver->get_solved_value($self->OraNetCode);
    $self->OraInstancia($self->resolver->get_solved_value($self->OraOID));
    $self->OraServer($self->resolver->get_solved_value($DESPLIEGUES{$dato}));
    $self->DatoDesp($self->resolver->get_solved_value($dato));
    $self->PREFIX($self->OraServer . "\_" . substr($self->DatoDesp, 3));

    open FBKOUT, ">>:encoding(iso-8859-15)", "$PaseDir/BackUp/" . $self->PREFIX . ".sql";
    print FBKOUT "SPOOL OFF\n";
    print FBKOUT "EXIT\n";
    close FBKOUT;

    $_log = "";

    open FileIN, "<$PaseDir/BackUp/" . $self->PREFIX . ".sql";
    $_log .= $_ for <FileIN>;
    close FileIN;

    my $cmd = "cd $PaseDir/BackUp ; " . $self->gnutar . " cvf " . $self->PREFIX . ".sql.tar " . $self->PREFIX . ".sql ; gzip -f " . $self->PREFIX . ".sql.tar";
    my $RET = system($cmd);
    $log->info("Generado fichero " . $self->PREFIX . ".sql para backup en " . $self->DatoDesp . " ", $_log);
    $log->debug($cmd);
  }

  my $retorno  = 0;
  my $RCBackUp = 0;

  for my $dato (sort keys %DESPLIEGUES) {

    if ($dato =~ m/^(.*)\_(.*)\_(.*)$/) {
      $self->OraNetCode($1);
      $self->OraOwner($2);
      $self->OraOID($3);
    }

    $OraRed = $self->resolver->get_solved_value("\$[" . $self->OraNetCode . "]");
    $self->OraInstancia($self->resolver->get_solved_value($self->OraOID));
    $self->OraServer($self->resolver->get_solved_value($DESPLIEGUES{$dato}));
    $self->DatoDesp($self->resolver->get_solved_value($dato));
    $self->PREFIX($self->OraServer . "\_" . substr($self->DatoDesp, 3));

    $puerto = $self->inf->get_unix_server_info({server => $self->OraServer, env => substr($self->env, 0, 1)}, 'HARAX_PORT');

    try {
      $log->debug("Intentando conexión a " . $self->OraServer . " por el puerto $puerto.\nInstancia ORACLE: " . $self->OraInstancia . "\nUsuario: " . $self->OraUser);
      # $balix_pool->conn($self->OraServer);
      _log "aaa";
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, qq{ echo "Testing sudo..." });
      _log "bbb";
      if ($RC ne 0) {
        $UserExists = undef;
        $log->error("Error al hacer sudo al usuario " . $self->OraUser . " en la máquina " . $self->OraServer . ".\n¿Está correctamente creado el usuario?", $RET);
        _throw "Error al hacer sudo al usuario " . $self->OraUser . " en la máquina " . $self->OraServer . ".:",                                             $RET;
      }

      $log->debug("Conexión a " . $self->OraServer . " por el puerto $puerto usando el usuario " . $self->OraUser . "\n");

      ## CREO EL DIR de PASE
      my $cmd = qq{ mkdir -p $haraxDir }; $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error al crear el directorio de $haraxDir: $RET");
          _throw "Error al crear el directorio de $haraxDir: $RET";
        }
        else {
          $retorno = $retorno + 1;
          $log->warn("Error al crear el directorio de $haraxDir: $RET");
        }
      }
      else {
        $log->debug("Directorio '$haraxDir' creado: $RET");
      }
      ## ENVIO TAR.GZ
      $log->info("Enviando DDL's al Servidor'. Espere...");
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->sendFile("$PaseDir/BackUp/" . $self->PREFIX . ".sql.tar.gz", "$haraxDir/" . $self->PREFIX . ".sql.tar.gz");
      if ($RC ne 0) {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error al enviar fichero tar " . $self->PREFIX . ".sql.tar.gz: $RET");
          _throw "Error al enviar fichero tar " . $self->PREFIX . ".sql.tar.gz: $RET";
        }
        else {
          $retorno = $retorno + 1;
          $log->warn("Error al enviar fichero tar " . $self->PREFIX . ".sql.tar.gz: $RET");
        }
      }
      else {
        $log->debug("Fichero '" . $self->PREFIX . ".sql.tar.gz' creado en servidor: $RET");
      }

      ## CAMBIO DE PERMISOS Y OWNER
      $cmd = "chown " . $self->OraUser . " \"$haraxDir/\"" . $self->PREFIX . "\".sql.tar.gz\" ; chmod 750 \"$haraxDir/\"" . $self->PREFIX . "\".sql.tar.gz\"";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->execute($cmd);
      if ($RC ne 0) {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error al cambiar permisos del fichero $haraxDir/" . $self->PREFIX . ".sql.tar.gz: $RET");
          _throw "Error al cambiar permisos del fichero $haraxDir/" . $self->PREFIX . ".sql.tar.gz: $RET";
        }
        else {
          $retorno = $retorno + 1;
          $log->warn("Error al cambiar permisos del fichero $haraxDir/" . $self->PREFIX . ".sql.tar.gz: $RET");
        }
      }
      else {
        $log->debug("Fichero '$haraxDir/" . $self->PREFIX . ".sql.tar.gz' con permisos para '" . $self->OraUser . "': $RET");
      }

      ## DESCOMPRIME
      $cmd = "cd $haraxDir ; rm -f \"$haraxDir/\"" . $self->PREFIX . "\".sql\"; gzip -f -d \"$haraxDir/\"" . $self->PREFIX . "\".sql.tar.gz\" ; tar xmvf \"$haraxDir/\"" . $self->PREFIX . "\".sql.tar\"; rm -f \"$haraxDir/\"" . $self->PREFIX . "\".sql.tar\"";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, $cmd);
      if (($RC ne 0) or ($RET =~ m/no space/i)) {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error al descomprimir " . $self->PREFIX . ".sql.tar.gz (¿Falta espacio en disco en el servidor " . $self->OraServer . "?): $RET");
          _throw "Error al descomprimir " . $self->PREFIX . ".sql.tar.gz (¿Falta espacio en disco en el servidor " . $self->OraServer. "?): $RET";
        }
        else {
          $retorno = $retorno + 1;
          $log->warn("Error al descomprimir " . $self->PREFIX . ".sql.tar.gz (¿Falta espacio en disco en el servidor " . $self->OraServer . "?): $RET");
        }
      }
      else {
        $log->info("Fichero " . $self->PREFIX . ".sql.tar.gz descomprimido: $RET");
      }
      my $RCSqlplus  = 0;
      my $RETSqlplus = "";

      ## EJECUTA SQLPLUS
      $log->info("Realizando BACKUP de los elementos del pase en " . $self->OraInstancia . " ($OraRed)");
      $cmd = " cd $haraxDir ; . /home/aps/dba/scripts/dbas001 " . $self->OraInstancia . " ; export NLS_LANG=SPANISH_SPAIN.UTF8 ; sqlplus -l / \@" . $self->PREFIX . ".sql ";
      $log->debug("Executing :: $cmd");
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, $cmd);
      $log->info("BACKUP finalizado.");

      if ($RC ne 0) {
        $RCSqlplus  = $RC;
        $RETSqlplus = $RET;
        if ($SeguirSinBu ne "Si") {
          $log->error("Error ejecutando script " . $self->PREFIX . ".sql", $RET);
        }
        else {
          $retorno = $retorno + 1;
          $log->error("Error ejecutando script " . $self->PREFIX . ".sql (RC: $RC)", $RET);
        }
      }
      else {
        $log->debug("Ejecutado el script " . $self->PREFIX . ".sql", $RET);
      }

      ## COMPRIME LAS SALIDAS DE SQLPLUS

      ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
      my $tarExecutable;

      $cmd = " ls '" . $self->tar_dest_aix . "' ";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        $log->info("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
        $tarExecutable = "tar";
        $LISTTAR       = "L";
      }
      else {
        $log->info("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
        $tarExecutable = $self->tar_dest_aix;
        $LISTTAR       = "T";
      }

      $cmd = " cd $haraxDir ; find . -type f ! \\( -name \"*.sql\" -o -name \"*.tar\" -o -name \"*.gz\" -o -name \"README\" \\) -exec echo {} > ./README \\; ";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error generando la lista de elementos de Backup:\n $RET");
          _throw "Error generando la lista de elementos de Backup";
        }
        else {
          $retorno = $retorno + 1;
          $log->error("Error generando la lista de elementos de Backup:\n $RET");
        }
      }
      $cmd = "cd $haraxDir ; $tarExecutable cvf$LISTTAR " . $self->PREFIX . ".tar ./README; gzip -f " . $self->PREFIX . ".tar";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        if ($SeguirSinBu ne "Si") {
          if ($RET !~ m/no existe/i) {
            $log->error("Error al comprimir ficheros de salida en " . $self->PREFIX . ".tar: $RET");
            _throw "Error al comprimir ficheros de salida en " . $self->PREFIX . ".tar: $RET";
          }
          else {
            $log->error("SQLPlus no ha generado ningún fichero de salida. ¿Fallo la conexión a ORACLE?:\n $RET");
            _throw "SQLPlus no ha generado ningún fichero de salida";
          }
        }
        else {
          $retorno = $retorno + 1;
          if ($RET !~ m/no existe/i) {
            $log->error("Error al comprimir ficheros de salida en " . $self->PREFIX . ".tar: $RET");
          }
          else {
            $log->error("SQLPlus no ha generado ningún fichero de salida. ¿Fallo la conexión a ORACLE?:\n $RET");
          }
        }
      }
      else {
        $log->info("Comprimidos los scripts de salida en " . $self->PREFIX . ".tar", $RET);
      }
      ## RECEPCION TAR.GZ
      $log->info("Recogiendo las salidas del Servidor'. Espere...");
      ($RC, $RET) = $balix_pool->conn($self->OraServer)->getFile("$haraxDir/" . $self->PREFIX . ".tar.gz", "$PaseDir/BackUp/" . $self->PREFIX . ".tar.gz");
      if ($RC ne 0) {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error al recoger el fichero tar " . $self->PREFIX . ".tar.gz: $RET");
          _throw "Error al enviar fichero tar " . $self->PREFIX . ".tar.gz: $RET";
        }
        else {
          $retorno = $retorno + 1;
          $log->warn("Error al recoger el fichero tar " . $self->PREFIX . ".tar.gz: $RET");
        }
      }
      else {
        my $RET = system(" mkdir -p $PaseDir/BackUp/tmp ; cd $PaseDir/BackUp/tmp ; cp -p ../" . $self->PREFIX . ".tar.gz . ; gunzip -f " . $self->PREFIX . ".tar.gz ; " . $self->gnutar . " cvf " . $self->PREFIX . ".tar ; rm -f " . $self->PREFIX . ".tar ");
        my $cnt = `cd $PaseDir/BackUp/tmp ; ls | wc -l`;
        my $data;
        foreach my $BUFile (`cd $PaseDir/BackUp/tmp ; ls`) {
          chop $BUFile;
          $data = "";
          open FIN, "<$PaseDir/BackUp/tmp/$BUFile";
          $data .= $_ for <FIN>;
          close FIN;
          $cnt-- if (($data =~ m/CREATE/i) || ($data =~ m/ORA\-31603/i));
        }

        $log->info("Nº Elementos erróneos en Backup de " . $self->PREFIX . ".sql: $cnt") if ($cnt > 0);
        $RCBackUp = $RCBackUp + $cnt if ($cnt > 0);
        $RET = system(qq ( rm -Rf "$PaseDir/BackUp/tmp" ));
      }

      ## Tratamiento de error de la ejecucion del comando sqlplus
      if ($RCSqlplus ne 0) {
        _throw "Error ejecutando script " . $self->PREFIX . ".sql: $RETSqlplus" if ($SeguirSinBu ne "Si");
      }
    }
    catch {
      if (!$UserExists) {
        _throw "No se puede continuar el despliegue de ORACLE. ";
      }
      else {
        if ($SeguirSinBu ne "Si") {
          $log->error("Error realizando el proceso de backup de la base de datos: ");
          _throw "Error realizando el proceso de backup de la base de datos: ";
        }
        else {
          $log->warn("Error realizando el proceso de backup de la base de datos: ");
          $retorno = $retorno + 1;
        }
      }
    }
  }

  if ($Entorno ne "TEST") {
    try {
      my $RET = system(" cd $PaseDir/BackUp ; find . -name \"*_????.tar.gz\" -exec " . $self->gnutar . " rvf $Pase.tar {} + ; gzip -f $Pase.tar ");
      my ($idBack, $dataSize) = store_backup($EnvironmentName, $Entorno, $EnvironmentName, "ORACLE", $Pase, "sql", "$PaseDir/BackUp/$Pase.tar.gz", "");
      $log->info("Backup realizado (Fichero:$Pase.tar.gz contiene $dataSize KB)", $idBack);
    }
    catch {
      $retorno = $retorno + 1;
      $log->error("Error al guardar el fichero de backup en la base de datos: ");
      _throw "Error al guardar el fichero de backup en la base de datos: ";
    }
  }

  if ($RCBackUp > 0) {
    if ($SeguirSinBu ne "Si") {
      _throw "Se han detectado errores en el proceso de Backup de $RCBackUp elementos del pase.\nRevise los LOGS.";
    }
    else {
      $log->warn("Se han detectado errores en el proceso de Backup de $RCBackUp elementos del pase.\nRevise los LOGS.");
    }
  }
  # $balix_pool->conn($self->OraServer)->end;
  return ($retorno);
}

sub AddHeader {
  my $self    = shift;
  my $FileDLL = shift @_;
  my $Owner   = shift @_;
  my $AddedLines;
  my $OWNER = uc($Owner);

  $AddedLines .= "ALTER SESSION SET CURRENT_SCHEMA=$OWNER\n";    ## Quitamos Formatos SQLPLus
  ##$AddedLines.="ALTER SESSION SET EVENTS = '20000 trace name errorstack level 3';";
  $AddedLines .= "/\n";
  $AddedLines .= "SET ECHO OFF NEWP 0 SPA 1 PAGES 0 LINES 9999 FEED OFF HEAD OFF TRIMS ON TERMOUT OFF DEFINE OFF\n";                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Quitamos Formatos SQLPLus
  $AddedLines .= "SET SERVEROUTPUT ON\n";
  $AddedLines .= "exec DBMS_OUTPUT.enable(10485760);\n";
  $AddedLines .= "WHENEVER SQLERROR EXIT FAILURE;\n";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## En caso de error abortamos el pase
  $AddedLines .= "SPOOL $FileDLL.PRE\n";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Sacamos el informe de estado a un fichero externo
  $AddedLines .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND STATUS = 'INVALID');\n";
  $AddedLines .= "SPOOL $FileDLL.OUT\n";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Sacamos el informe de estado a un fichero externo
  $AddedLines .= "exec DBMS_OUTPUT.put_line('Informe de elementos INVALIDOS antes del pase');\n";
  $AddedLines .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND STATUS = 'INVALID');\n";
  $AddedLines .= "SET TERMOUT ON;\n";
  $AddedLines .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Inicio del proceso de creacion de Objetos');\n";
  return ($AddedLines);
}

sub GenerarScriptDeploy {
  my $self            = shift;
  my $log = $self->log;
  my %Files           = %{shift @_};
  my $PaseDir         = shift @_;
  my $cam             = shift @_;
  my $Entorno         = shift @_;
  my $Pase            = shift @_;
  my $EnvironmentName = shift @_;
  my $haraxDir        = "/tmp/$Pase";
  my ($harax, $puerto);
  my (@RET,       $RET,        $RC,           $OraRed,
      @redes,     $carpetaAnt, $ObjectNameX,  $Servidor,
      $Instancia, $Owner,      %redesatratar, $OraRedES);
  my %Tratado;
  my ($Element, $Server, %RETFINAL);
  my $BeginCnt    = 0;
  my $StartTMSTMP = ahora();
  my $PatCR       = chr(13);
  my ($_log, $LOGPRE,  $LOGPOS);
  my ($Retorno, $Warn, $Cerrado, $nFich);
  my $RetornoFinal = 0;
  my $nRedes       = 0;
  my $Instancias;
  my $msg;
  my %DESPLIEGUES;
  my %Types = %{$self->Types};
  my ($FileName,       $ObjectName,      $PackageName,    $SystemName,
      $SubSystemName,  $DSName,          $Extension,      $ElementState,
      $ElementVersion, $ElementPriority, $carpeta,        $ElementID,
      $ParCompIni,     $NewID,           $HarvestProject, $HarvestState,
      $HarvestUser,    $ModifiedTime);
  $log->info("Generando script para realizar DEPLOY del pase\n");

  ## Ordeno por estado y por extension para primero borrar los objetos que haya que borrar y luego recuperar los elementos en el orden de compilación.
  $nFich = 0;
  foreach $Element (keys %Files) {
    my $FileName        = $Files{$Element}->{FileName}; 
    my $ObjectName      = $Files{$Element}->{ObjectName}; 
    my $PackageName     = $Files{$Element}->{PackageName}; 
    my $SystemName      = $Files{$Element}->{SystemName}; 
    my $SubSystemName   = $Files{$Element}->{SubSystemName}; 
    my $DSName          = $Files{$Element}->{DSName}; 
    my $Extension       = $Files{$Element}->{Extension}; 
    my $ElementState    = $Files{$Element}->{ElementState}; 
    my $ElementVersion  = $Files{$Element}->{ElementVersion}; 
    my $ElementPriority = $Files{$Element}->{ElementPriority}; 
    my $ElementPath     = $Files{$Element}->{ElementPath}; 
    $carpeta            = $Files{$Element}->{ElementPath};
    my $ElementID       = $Files{$Element}->{ElementID}; 
    my $ParCompIni      = $Files{$Element}->{ParCompIni}; 
    my $NewID           = $Files{$Element}->{NewID}; 
    my $HarvestProject  = $Files{$Element}->{HarvestProject}; 
    my $HarvestState    = $Files{$Element}->{HarvestState}; 
    my $HarvestUser     = $Files{$Element}->{HarvestUser}; 
    my $ModifiedTime    = $Files{$Element}->{ModifiedTime};
    next if ($Extension !~ m/PKG|PRC|FNC|TRG|VIW|SPC|BDY|SYN|VW|PKS|PKB|PCK|TYP|TPB|TPS/i);
    $nFich++;
    $FileName   =~ s/{PROD}|{ANTE}|{TEST}//gi;
    $ObjectName =~ s/{PROD}|{ANTE}|{TEST}//gi;

    ## Fichero Renombrado que no pertenece a este entorno
    do { $log->debug("$FileName no pertenece al entorno (Estado: $ElementState)"); next } if ((!-e "$PaseDir$carpeta/$FileName") && ($ElementState ne 'D'));
  
    if ($carpeta ne $carpetaAnt) {
      $Instancias = _folder_ora_data($cam, $carpeta, $Entorno);
      $carpetaAnt = $carpeta;

      if (scalar keys %$Instancias eq 0) {
        $log->warn("Los elementos de la carpeta $carpeta no se han distribuido en la red de destino.\n"
           . "Si desea distribuirlos, entre en la pestaña Oracle del formulario del paquete harvest y configure la instancia destino de la carpeta $carpeta.");
        next;
      }
      else {
        my @Despliegues = ();
        for my $dato (keys %$Instancias) {
          if ($dato =~ m/^(.*)\_(.*)\_(.*)$/) {
            $self->OraNetCode($1);
            $self->OraOwner($2);
            $self->OraOID($3);
          }
          $OraRed = $self->resolver->get_solved_value("\$[" . $self->OraNetCode . "]");
          $self->OraInstancia($self->resolver->get_solved_value($self->OraOID));

          $msg = $self->OraOwner . " en " . $self->OraInstancia . " {$OraRed}";
          push @Despliegues, $msg;
          $DESPLIEGUES{$dato} = $$Instancias{$dato};
        }
        $log->info("Los elementos de la carpeta $carpeta se distribuirán a los siguientes destinos:\n" . join("\n", @Despliegues));
      }
    }

    $nRedes = 0;

    for my $dato (keys %$Instancias) {
      if ($dato =~ m/^(.*)\_(.*)\_(.*)$/) {
        $self->OraNetCode($1);
        $self->OraOwner($2);
        $self->OraOID($3);
      }
      $OraRed = $self->resolver->get_solved_value("\$[" . $self->OraNetCode . "]");
      $self->OraInstancia($self->resolver->get_solved_value($self->OraOID));
      $self->OraServer($self->resolver->get_solved_value($$Instancias{$dato}));
      $self->PREFIX($self->OraServer . "\_" . substr($self->resolver->get_solved_value($dato), 3));
      $self->OraOwner(uc($self->OraOwner));

      $nRedes++;

      if ($RETFINAL{$self->PREFIX} eq "") {
        $log->info("Generando fichero " . $self->PREFIX . " para despliegue en la red $OraRed");
        $RETFINAL{$self->PREFIX} = $self->AddHeader($self->PREFIX . ".ora", $self->OraOwner);
      }
      $log->info("Preparando despliegue de $FileName ($ElementState) en $OraRed: " . $self->OraInstancia . " (" . $self->OraOwner . ")");
      if ($Tratado{$self->PREFIX . "\_$FileName"} eq "") {
        if ($ElementState eq 'D' && $Extension) {
          $RETFINAL{$self->PREFIX} .= "WHENEVER SQLERROR CONTINUE\n";
          $RETFINAL{$self->PREFIX} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Borrado del objeto ($Types{$Extension}): $ObjectName...');\n";
          $RETFINAL{$self->PREFIX} .= "DROP $Types{$Extension} " . $self->OraOwner . ".$ObjectName;\n";
          $RETFINAL{$self->PREFIX} .= "WHENEVER SQLERROR EXIT FAILURE;\n";
        }
        else {
          $BeginCnt = 0;
          $Cerrado  = 0;
          open FileIN, "<$PaseDir$carpeta/$FileName";
          $ObjectNameX = $ObjectName;
          $ObjectNameX =~ s/\$/\\\$/g;
          $RETFINAL{$self->PREFIX} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Creacion del objeto ($Types{$Extension}): $ObjectName...');\n";
          my $replace_OraOwner = $self->OraOwner;
          foreach $RET (<FileIN>) {
            next if ($RET =~ /^\s*$/);
            $RET =~ s/^\/$//g;                        ## Quito caracter de fin de instrucción - se pone despues.
            $RET =~ s/\/$//g if ($RET !~ m/\*\//i);   ## Quito caracter de fin de instrucción - se pone despues.
            $RET =~ s/"//g if ($RET =~ m/CREATE[\s]*or[\s]*REPLACE/i);
            $RET =~ s/$ObjectNameX/$replace_OraOwner.$ObjectName/gi if (($RET !~ m/SYNONYM|^\s*END /i) && ($RET =~ m/CREATE[\s]*or[\s]*REPLACE/i)); ## Reemplazar owner de los objetos
            $RETFINAL{$self->PREFIX} .= "\n/\n" if ($RET =~ m/CREATE OR REPLACE.*BODY.*$ObjectNameX/i);
            $RETFINAL{$self->PREFIX} .= $RET;
            $BeginCnt++ if ($RET =~ m/BEGIN/i);
          }

          $BeginCnt-- if ($RET =~ m/END /i);
          if (($RET =~ m/END ($ObjectNameX)/i) && ($BeginCnt le 0)) {
            $RETFINAL{$self->PREFIX} .= "\n/\n";
            $Cerrado = 1;
          }

          $RETFINAL{$self->PREFIX} .= "\n/\n" if ($Cerrado eq 0);
          close FileIN;
        }
        $Tratado{$self->PREFIX . "\_$FileName"} = "$OraRed";
      }
      open FileOUT, ">>:encoding(utf-8)", "$PaseDir/" . $self->PREFIX . ".ora";
      print FileOUT $RETFINAL{$self->PREFIX};
      close FileOUT;
      $RETFINAL{$self->PREFIX} = "\n";
    }
  }

  foreach $Element (keys %RETFINAL) {
    ($Servidor, $Owner, $Instancia) = split /\_/, $Element;
    my $OWNER = uc($Owner);
    $RETFINAL{$Element} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Fin del proceso de creacion de Objetos');\n";
    $RETFINAL{$Element} .= "\n";
    $RETFINAL{$Element} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Inicio del proceso de compilacion de los elementos del pase');\n";
    $RETFINAL{$Element} .= "exec DBMS_OUTPUT.put_line('');\n";
    $RETFINAL{$Element} .= "BEGIN\n";

    # $RETFINAL{$Element}.= "DBMS_UTILITY.compile_schema('".$OWNER."',FALSE);\n"; ## Compilación de Objetos INVALIDOS No compila vistas ni tipos NO SIRVE
    $RETFINAL{$Element} .= "FOR cur_rec IN (SELECT owner, object_name, object_type, DECODE(object_type, 'PACKAGE', 1, 'PACKAGE BODY', 2, 'TYPE', 3, 'TYPE BODY', 4,'PROCEDURE', 5, 'FUNCTION' ,6, 'TRIGGER', 7, 'VIEW', 8, 'SYNONYM', 99, 9) AS recompile_order FROM dba_objects WHERE OWNER = '$OWNER' AND STATUS <> 'VALID' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY', 'SYNONYM') UNION SELECT OWNER, SYNONYM_NAME, 'SYNONYM', 9 FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND TABLE_NAME IN (SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY', 'SYNONYM')) ORDER BY 4,1,2) LOOP \n";

    # $RETFINAL{$Element}.= "FOR cur_rec IN (SELECT owner, object_name, object_type, DECODE(object_type, 'PACKAGE', 1, 'PACKAGE BODY', 2, 'TYPE', 3, 'TYPE BODY', 4,'PROCEDURE', 5, 'FUNCTION' ,6, 'TRIGGER', 7, 'VIEW', 8, 'SYNONYM', 99, 9) AS recompile_order FROM dba_objects WHERE OWNER = '$OWNER' AND STATUS <> 'VALID' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'SYNONYM') UNION SELECT OWNER, SYNONYM_NAME, 'SYNONYM', 9 FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND TABLE_NAME IN (SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'SYNONYM')) ORDER BY 4,1,2) LOOP \n";
    $RETFINAL{$Element} .= "BEGIN\n";
    $RETFINAL{$Element} .= "IF cur_rec.object_type = 'PACKAGE BODY' THEN \n";
    $RETFINAL{$Element} .= "EXECUTE IMMEDIATE 'ALTER PACKAGE \"' || cur_rec.owner || '\".\"' || cur_rec.object_name || '\" COMPILE BODY';\n";
    $RETFINAL{$Element} .= "ELSE \n";
    $RETFINAL{$Element} .= "IF cur_rec.object_type = 'TYPE BODY' THEN \n";
    $RETFINAL{$Element} .= "EXECUTE IMMEDIATE 'ALTER TYPE \"' || cur_rec.owner || '\".\"' || cur_rec.object_name || '\" COMPILE BODY';\n";
    $RETFINAL{$Element} .= "ELSE \n";
    $RETFINAL{$Element} .= "EXECUTE IMMEDIATE 'ALTER ' || cur_rec.object_type || ' \"' || cur_rec.owner || '\".\"' || cur_rec.object_name || '\" COMPILE';\n";
    $RETFINAL{$Element} .= "END IF;\n";
    $RETFINAL{$Element} .= "END IF;\n";
    $RETFINAL{$Element} .= "DBMS_OUTPUT.put_line(rpad(cur_rec.object_type,15,' ') || ' ' || lpad(cur_rec.owner,10,' ') || '.' || rpad(cur_rec.object_name,25,' ') || ' VALID');\n";
    $RETFINAL{$Element} .= "EXCEPTION\n";
    $RETFINAL{$Element} .= "WHEN OTHERS THEN DBMS_OUTPUT.put_line(rpad(cur_rec.object_type,15,' ') || ' ' || lpad(cur_rec.owner,10,' ') || '.' || rpad(cur_rec.object_name,25,' ') || ' INVALID: ' || SQLCODE || ' ' || SQLERRM);\n";
    $RETFINAL{$Element} .= "END;\n";
    $RETFINAL{$Element} .= "END LOOP;\n";
    $RETFINAL{$Element} .= "FOR cur_rec IN (SELECT owner, object_name, object_type, DECODE(object_type, 'PACKAGE', 1, 'PACKAGE BODY', 2, 'TYPE', 3, 'TYPE BODY', 4,'PROCEDURE', 5, 'FUNCTION' ,6, 'TRIGGER', 7, 'VIEW', 8, 'SYNONYM', 9, 99) AS recompile_order FROM dba_objects WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY')) LOOP \n";
    $RETFINAL{$Element} .= "DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Se han detectado los siguientes errores en: ' || cur_rec.object_type || ': ' || cur_rec.object_name);\n";
    $RETFINAL{$Element} .= "FOR cur_err IN (SELECT SEQUENCE, LINE, POSITION, substr(TEXT,1,239) TEXT from dba_errors where owner = cur_rec.owner and name = cur_rec.object_name and type = cur_rec.object_type and text not like '%PL/SQL:%Statement ignored%') LOOP \n";
    $RETFINAL{$Element} .= "DBMS_OUTPUT.put_line( cur_err.line || ': ' || cur_err.position || ' >> ' || cur_err.text );\n";
    $RETFINAL{$Element} .= "END LOOP;\n";
    $RETFINAL{$Element} .= "END LOOP;\n";
    $RETFINAL{$Element} .= "END;\n";
    $RETFINAL{$Element} .= "/\n";
    $RETFINAL{$Element} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Fin del proceso de compilacion de los elementos del pase');\n";
    $RETFINAL{$Element} .= "\n";
    $RETFINAL{$Element} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Informe del estado de los objetos involucrados en el pase');\n";
    $RETFINAL{$Element} .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD(' OBJETO',40,' ') || ' ' || RPAD(' ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND TABLE_NAME IN (SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'VIEW', 'FUNCTION', 'SYNONYM')));\n";
    $RETFINAL{$Element} .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Informe de elementos INVALIDOS despues del pase');\n";
    $RETFINAL{$Element} .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND STATUS = 'INVALID');\n";
    $RETFINAL{$Element} .= "SPOOL $Servidor\_$Owner\_$Instancia.ora.POS\n";  ## Sacamos el informe de estado a un fichero externo
    $RETFINAL{$Element} .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND STATUS = 'INVALID');\n";
    $RETFINAL{$Element} .= "exit\n";
    $RETFINAL{$Element} .= "\n";

    open FileOUT, ">>:encoding(utf-8)", "$PaseDir/$Element.ora";
    print FileOUT $RETFINAL{$Element};
    close FileOUT;

    ## TRATAMIENTO CARACTER EURO
    $_log = "";
    open FileIN, "<$PaseDir/$Element.ora";
    @RET = <FileIN>;
    foreach $RET (@RET) {
      $RET =~ s/\xC2\x80/\xE2\x82\xAC/g;    ## Convierto caracter euro
      $_log .= $RET;
    }
    close FileIN;
    $log->info("$PaseDir/$Element.ora generado con éxito", $_log);
    open euroOUT, ">$PaseDir/$Element.ora";
    print euroOUT $_log;
    close euroOUT;

    $RET = system(" cd $PaseDir ; " . $self->gnutar . " cvf $Element.ora.tar $Element.ora ; gzip -f $Element.ora.tar ");
  }

  ## Llamada a harax para ejecutar en remoto el script

  $self->sqlNeedRollback(1);
  $RetornoFinal = 0;

  foreach $Element (keys %RETFINAL) {    
    ($Servidor, $Owner, $Instancia) = split /\_/, $Element;
    _log "Servidor: $Servidor";    # XXX
    _log "Element: $Element";      # XXX
    my $OWNER = uc($Owner);
    #($puerto) = getUnixServerInfo($Servidor, "HARAX_PORT");
    $puerto = $self->inf->get_unix_server_info({server => $Servidor, env => $self->env}, 'HARAX_PORT');
    $Retorno = 0;
    $Warn    = 0;
    try {
      $log->debug("Conexión a $Servidor por el puerto $puerto\n");

      ## CREO EL DIR de PASE
      my $cmd = "mkdir -p $haraxDir";
      ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        $log->eror("Error al crear el directorio de $haraxDir: $RET");
        _throw "Error al crear el directorio de $haraxDir: $RET";
      }
      else {
         $log->debug("Directorio '$haraxDir' creado: $RET");
      }
      ## ENVIO TAR.GZ
      $log->info("Enviando DDL's al Servidor'. Espere...");
      ($RC, $RET) = $balix_pool->conn($Servidor)->sendFile("$PaseDir/$Element.ora.tar.gz", "$haraxDir/$Element.ora.tar.gz");
      if ($RC ne 0) {
        $log->error("Error al enviar fichero tar $Element.ora.tar.gz: $RET");
        _throw "Error al enviar fichero tar $Element.ora.tar.gz: $RET";
      }
      else {
        $log->info("Fichero '$Element.ora.tar.gz' creado en servidor: $RET");
      }
      ## CAMBIO DE PERMISOS Y OWNER
      $cmd = " chown " . $self->OraUser . " \"$haraxDir/$Element.ora.tar.gz\" ; chmod 750 \"$haraxDir/$Element.ora.tar.gz\" ";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($Servidor)->execute($cmd);
      if ($RC ne 0) {
        $log->error("Error al cambiar permisos del fichero $haraxDir/$Element.ora.tar.gz: $RET");
        _throw "Error al cambiar permisos del fichero $haraxDir/$Element.ora.tar.gz: $RET";
      }
      else {
        $log->debug("Fichero '$haraxDir/$Element.ora.tar.gz' con permisos para '" . $self->OraUser . "': $RET");
      }
      ## DESCOMPRIME
      $cmd = qq{cd $haraxDir ; rm -f "$haraxDir/$Element.ora"; gzip -f -d "$haraxDir/$Element.ora.tar.gz" ; tar xmvf "$haraxDir/$Element.ora.tar"; rm -f "$haraxDir/$Element.ora.tar"};
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
      if (($RC ne 0) or ($RET =~ m/no space/i)) {
        $log->error("Error al descomprimir $Element.ora.tar.gz (¿Falta espacio en disco en el servidor $Server?): $RET");
        _throw "Error al descomprimir $Element.ora.tar.gz (¿Falta espacio en disco en el servidor $Server?): $RET";
      }
      else {
        $log->info("Fichero $Element.ora.tar.gz descomprimido: $RET");
      }
      ## EJECUTA SQLPLUS
      $log->info("Realizando DESPLIEGUE de los elementos del pase en $Instancia ($Owner)");
      sleep 5;
      $cmd = qq{cd $haraxDir ; . /home/aps/dba/scripts/dbas001 $Instancia ; export NLS_LANG=SPANISH_SPAIN.UTF8 ; sqlplus -l / \@$Element.ora};
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        $log->error("Error ejecutado el script $Element.ora || ", $RET);
        _throw "Error ejecutando script $Element.ora, $RET";
      }
      else {
        $log->info("Ejecutado el script $Element.ora", $RET);
      }
    }
    catch {
      $log->warn("Error durante la conexión al servidor");
      $Retorno++;
    }
    $RC = $RET = 0;
    $log->info("Recogiendo las salidas del Servidor. Espere...");

    ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
    my $tarExecutable;

    my $cmd = " ls '" . $self->tar_dest_aix . "' ";
    $log->debug($cmd);
    ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
    if ($RC ne 0) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
      $log->info("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
      $tarExecutable = "tar";
    }
    else {
      $log->info("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
      $tarExecutable = $self->tar_dest_aix;
    }

    ## COMPRIME LAS SALIDAS DE SQLPLUS
    $cmd = qq{cd $haraxDir ; $tarExecutable cvf $Element.tar $Element.ora.* ; gzip -f $Element.tar};
    $log->debug($cmd);
    ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
    if ($RC ne 0) {
      if ($RET !~ m/no existe/i) {
        $log->error("Error al comprimir ficheros de salida en $Element.tar: $RET");
        _throw "Error al comprimir ficheros de salida en $Element.tar: $RET";
      }
      else {
        $log->error("SQLPlus no ha generado ningún fichero de salida. ¿Fallo la conexión a ORACLE?:\n $RET");
        _throw "SQLPlus no ha generado ningún fichero de salida";
      }
    }
    else {
      $log->info("Comprimidos los scripts de salida en $Element.tar: $RET");
    }

    ## RECEPCION TAR.GZ
    ($RC, $RET) = $balix_pool->conn($Servidor)->getFile("$haraxDir/$Element.tar.gz", "$PaseDir/$Element.tar.gz");
    if ($RC ne 0) {
      $log->error("Error al recoger ficheros ");
      _throw "Error al recoger ficheros ";
    }
    else {
      $log->debug("Fichero $Element.tar.gz creado en servidor: $RET");
    }

    $log->info("Validando la ejecución del script de creación de objetos ORACLE");
    $RET = system(qq ( cd $PaseDir ; rm -f $Element.ora.OUT ; gunzip $Element.tar.gz ; tar xvof $Element.tar ));
    my $OutPut  = 0;
    my $pCab    = 0;
    my $ObjName = "";
    my $ObjType = "";

    $_log = "";
    $_log = "";

    if (-e "$PaseDir/$Element.ora.OUT") {
      open FileIN, "<$PaseDir/$Element.ora.OUT";

      foreach $RET (<FileIN>) {
        $OutPut = 1 if ($RET =~ m/involucrados/);
        $OutPut = 0 if ($RET =~ m/INVALIDOS/);

        $Retorno++ if ($OutPut gt 0 && $RET =~ m/ ERROR |ORA\-\d+/i);
        if ($OutPut gt 0 && $RET =~ m/ADVERTENCIA$|WARNING$|INVALID$/i) {
          $ObjName = substr($RET, index($RET, $OWNER) + 1 + length($OWNER), index($RET, " ", index($RET, $OWNER)) - (index($RET, $OWNER) + 1 + length($OWNER))) if (index($RET, $OWNER) ge 0);
          $ObjType = substr($RET, 0, index($RET, $OWNER));
          $ObjType =~ s/\s+$//;
          if (length($ObjName) gt 0) {
            if ($self->Objetos->{$ObjName} ne "") {
              $Retorno++;
              if ($pCab eq 0) {
                $pCab++;
                $_log = "ERROR: Los siguientes elementos involucrados en el pase quedaron en estado INVALIDO:\n";
              }
              $_log .= "{$ObjType} $ObjName\n";
            }
            else {
              $Warn++;
            }
          }
        }
      }
      $_log .= "\nNo se puede continuar el despliege" if (length($_log) gt 0);
      close FileIN;
    }

    $log->info($_log) if (length($_log) gt 0);

    $LOGPRE = "";
    if (-e "$PaseDir/$Element.ora.PRE") {
      open FileIN, "<$PaseDir/$Element.ora.PRE";
      $LOGPRE .= $_ for <FileIN>;
      close FileIN;
      $log->info("Recuperado informe de situación previa:\n", $LOGPRE);
    }

    $LOGPOS = "";
    if (-e "$PaseDir/$Element.ora.POS") {
      open FileIN, "<$PaseDir/$Element.ora.POS";
      $LOGPOS .= $_ for <FileIN>;
      close FileIN;
      $log->info("Recuperado informe de situación posterior:\n", $LOGPOS);
    }

    if ((-e "$PaseDir/$Element.ora.PRE") && (-e "$PaseDir/$Element.ora.POS")) {
      open FWSPRE, "<$PaseDir/$Element.ora.PRE";
      open FWSPOS, "<$PaseDir/$Element.ora.POS";

      my @PRE  = <FWSPRE>;
      my @POS  = <FWSPOS>;
      my $i    = 0;
      my $j    = 0;
      my $sPRE = "";
      my $sPOS = "";
      my @tPRE;
      my @tPOS;
      my $PRE;
      my $POS;

      $pCab = 0;
      while (($sPRE ne "___") || ($sPOS ne "___")) {
        $PRE = $PRE[$i];
        $PRE =~ s/PACKAGE BODY/PACKAGEBODY /ig;
        $PRE =~ s/TYPE BODY/TYPEBODY /ig;
        $POS = $POS[$j];
        $POS =~ s/PACKAGE BODY/PACKAGEBODY /ig;
        $POS =~ s/TYPE BODY/TYPEBODY /ig;

        if ($sPRE eq $sPOS) {
          if   ($i eq @PRE) { $sPRE = "___"; }
          else              { @tPRE = split(/\s+/, $PRE); $sPRE = $tPRE[1]; $i++; }
          if   ($j eq @POS) { $sPOS = "___"; }
          else              { @tPOS = split(/\s+/, $POS); $sPOS = $tPOS[1]; $j++; }
        }
        elsif (($sPRE lt $sPOS)) {
          if   ($i eq @PRE) { $sPRE = "___"; }
          else              { @tPRE = split(/\s+/, $PRE); $sPRE = $tPRE[1]; $i++; }
        }
        elsif (($sPRE ge $sPOS)) {
          if ($self->Objetos->{$tPOS[1]} ne "") {
            if ($pCab eq 0) { $pCab++; $log->error("ERROR: Los siguientes elementos no involucrados en el pase quedaron en estado INVALIDO:"); }
            $log->error("{$tPOS[0]} $tPOS[1]\n");
            $Retorno++;
          }
          if ($j eq @POS) { 
            $sPOS = "___"; 
          }
          else { 
            @tPOS = split(/\s+/, $POS);
            $sPOS = $tPOS[1];
            $j++; 
          }
        }

        $tPOS[0] =~ s/PACKAGEBODY/PACKAGE BODY/ig;
        $tPRE[0] =~ s/PACKAGEBODY/PACKAGE BODY/ig;
        $tPOS[0] =~ s/TYPEBODY/TYPE BODY/ig;
        $tPRE[0] =~ s/TYPEBODY/TYPE BODY/ig;
      }
      close FWSPRE;
      close FWSPOS;
    }
    else {
      $log->info("INFO: No se pueden comparar los informes de situación");
    }

    if ($Retorno gt 0) {
      $log->error("Se han producido errores en la ejecución del script de creación de objetos ORACLE. Revisar LOG.", $_log);
      _throw "Error realizando el proceso de despliegue de objetos ORACLE ($Instancia)";
      return ($Retorno);
    }
    elsif ($Warn gt 0) {
      $log->warn("Hay objetos en estado INVALIDO después de su creación en ORACLE ($Instancia). Revisar LOG.", $_log);
    }
    else {
      $log->info("Validada con éxito la ejecución del script de creación de objetos ORACLE ($Instancia)", $_log);
    }
    $RetornoFinal += $Retorno;
  }    ##foreach

  if (($nFich eq 0) || ($nRedes eq 0)) {
    $log->warn("El paquete no contiene ningún elemento ORACLE válido para su distribución.\nNo se ha realizado ninguna operación;");
  }
  else {
    $log->info("Procesados $nFich ficheros ORACLE.");
  }

  # $balix_pool->conn($Servidor)->end;
  return ($RetornoFinal);
}

sub restoreSQL {
  my $self = shift;
  my $log = $self->log;
  my $EnvironmentName = shift @_;
  my $Entorno         = shift @_;
  my $Sufijo          = shift @_;
  my $Pase            = shift @_;
  my $PaseDir         = shift @_;
  my %Types           = %{$self->Types};

  my (@ObjectName, $ObjectName, $Extension, $FileName, $RC,
      @RET,        $RET,        $RETFINAL,  @Files,    $File);
  my ($BeginCnt, $Retorno, $Cerrado, $Warn);
  $ObjectName = "";
  my ($Puerto, $Servidor, $Instancia, $Owner, $harax);
  my $localdir = $PaseDir . "/restore";
  my ($cadena, $cad);
  my $haraxDir    = "/tmp/$Pase/restore";
  my $StartTMSTMP = ahora();
  my ($_log, $LOGPRE, $LOGPOS);

  $log->info("Generando script para realizar RESTORE del pase\n");
  mkdir $localdir;
  my %BACKUPS = getBackups($EnvironmentName, $Entorno, $Sufijo, $localdir, $EnvironmentName);
  my $cnt = 0;

  if (keys %BACKUPS eq 0) {
    $log->warn("Restore: no hay backups disponibles para marcha atrás en la aplicación $EnvironmentName->$Entorno");
    _throw "Restore: no hay backups disponibles para marcha atrás en la aplicación $EnvironmentName->$Entorno";
  }

  foreach my $bu (keys %BACKUPS) {
    my $bufile = $1 if $bu =~ m/(.*).tar.gz/;
    my $cmd = "cd $localdir ; gzip -f -d \"./$bufile.tar.gz\" ; " . $self->gnutar . " xvf \"./$bufile.tar\"; rm -f \"./$bufile.tar\" ";
    $log->debug($cmd);
    my $RET = system($cmd);
  }

  opendir(BKDIR, "$localdir") or die "No puedo abrir el directorio de BACKUP";
  my @BKFiles = grep { !/^\./ && /tar\.gz$/ && -f "$localdir/$_" } readdir BKDIR;

  foreach $FileName (@BKFiles) {
    $RETFINAL = undef;
    $cadena = substr($FileName, 0, index $FileName, "\.");
    ($Servidor, $Owner, $Instancia) = split /\_/, $cadena;
    my $OWNER = uc($Owner);

    mkdir "$localdir/$cadena";

    my $cmd = " cd $localdir/$cadena ; gzip -f -d \"../$cadena.tar.gz\" ; " . $self->gnutar . " xvf \"../$cadena.tar\" ";
    $log->debug($cmd);
    my $RET = system($cmd);

    $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Inicio del proceso de creacion de Objetos');\n";
    $RETFINAL .= "WHENEVER SQLERROR CONTINUE;\n";
    opendir(BKDIR, "$localdir/$cadena") or die "No puedo abrir el directorio de BACKUP";
    @Files = grep { !/^\./ && -f "$localdir/$cadena/$_" } readdir BKDIR;
    $self->Objects("");
    foreach $File (@Files) {    ## Para cada objeto involucrado generamos una línea para tratar su DDL

      # _log "Procesando restore de $File";
      $Cerrado = 0;
      ($cad, $Extension) = split /\./, $File;    ##substr($FileName,0,index $FileName, "\.");
      ($Servidor, $Owner, $Instancia, @ObjectName) = split /\_/, $cad;
      my $OWNER = uc($Owner);
      $ObjectName = join '_', @ObjectName;
      $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Procesamiento del objeto ($Types{$Extension}): $ObjectName...');\n";
      open FileIN, "< $localdir/$cadena/$File";
      my $nLin    = 0;
      my $Dropped = 0;

      foreach $RET (<FileIN>) {
        next if ($RET =~ m/ERROR:/i);
        if ($RET =~ m/ORA-31603:/i) {
          $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Borrado del objeto ($Types{$Extension}): $ObjectName...');\n";
          $RETFINAL .= "DROP $Types{$Extension} $OWNER.$ObjectName;\n";
          $Dropped = 1;
          last;
        }
        last if ($RET =~ m/ORA-/i);
        last if ($RET =~ m/get_ddl/i);
        next if ($RET =~ m/^\s*\/\s*$/);
        next if ($RET =~ m/^\s*$/);
        $RET = "$1\n" if $RET =~ m/(.*;)\s*\//;
        $RETFINAL .= "/\n" if ($RET =~ m/CREATE\s*OR\s*REPLACE/ && $nLin gt 1 && $Dropped eq 0);
        $RETFINAL .= $RET if ($RET !~ m/ENABLE$/);

        if ($RET =~ m/END ($ObjectName)/i) {
          $RETFINAL .= "/\n";
          $Cerrado = 1;
        }
        $nLin += 1;
      }
      $RETFINAL .= "/" if $Dropped eq 0;
      $RETFINAL .= "\n";
      close FileIN;
      $self->Objects .= "'$ObjectName',";
    }
    $RETFINAL .= "WHENEVER SQLERROR EXIT FAILURE;\n";
    chop $self->Objects;

    $RETFINAL = $self->AddHeader("$cadena.sql", "$OWNER") . $RETFINAL;
    $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Fin del proceso de creacion de Objetos');\n";
    $RETFINAL .= "\n";
    $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Inicio del proceso de compilacion de los elementos del pase');\n";
    $RETFINAL .= "exec DBMS_OUTPUT.put_line('');\n";
    $RETFINAL .= "BEGIN\n";

    # $RETFINAL.= "DBMS_UTILITY.compile_schema('".$OWNER."',FALSE);\n"; ## Compilación de Objetos INVALIDOS No compila vistas ni tipos NO SIRVE
    $RETFINAL .= "FOR cur_rec IN (SELECT owner, object_name, object_type, DECODE(object_type, 'PACKAGE', 1, 'PACKAGE BODY', 2, 'TYPE', 3, 'TYPE BODY', 4,'PROCEDURE', 5, 'FUNCTION' ,6, 'TRIGGER', 7, 'VIEW', 8, 'SYNONYM', 99, 9) AS recompile_order FROM dba_objects WHERE OWNER = '$OWNER' AND STATUS <> 'VALID' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY', 'SYNONYM') UNION SELECT OWNER, SYNONYM_NAME, 'SYNONYM', 9 FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND TABLE_NAME IN (SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY', 'SYNONYM')) ORDER BY 4,1,2) LOOP \n";
    $RETFINAL .= "BEGIN\n";
    $RETFINAL .= "IF cur_rec.object_type = 'PACKAGE BODY' THEN \n";
    $RETFINAL .= "EXECUTE IMMEDIATE 'ALTER PACKAGE \"' || cur_rec.owner || '\".\"' || cur_rec.object_name || '\" COMPILE BODY';\n";
    $RETFINAL .= "ELSE \n";
    $RETFINAL .= "IF cur_rec.object_type = 'TYPE BODY' THEN \n";
    $RETFINAL .= "EXECUTE IMMEDIATE 'ALTER TYPE \"' || cur_rec.owner || '\".\"' || cur_rec.object_name || '\" COMPILE BODY';\n";
    $RETFINAL .= "ELSE \n";
    $RETFINAL .= "EXECUTE IMMEDIATE 'ALTER ' || cur_rec.object_type || ' \"' || cur_rec.owner || '\".\"' || cur_rec.object_name || '\" COMPILE';\n";
    $RETFINAL .= "END IF;\n";
    $RETFINAL .= "END IF;\n";
    $RETFINAL .= "DBMS_OUTPUT.put_line(rpad(cur_rec.object_type,15,' ') || ' ' || lpad(cur_rec.owner,10,' ') || '.' || rpad(cur_rec.object_name,25,' ') || ' VALID');\n";
    $RETFINAL .= "EXCEPTION\n";
    $RETFINAL .= "WHEN OTHERS THEN DBMS_OUTPUT.put_line(rpad(cur_rec.object_type,15,' ') || ' ' || lpad(cur_rec.owner,10,' ') || '.' || rpad(cur_rec.object_name,25,' ') || ' INVALID: ' || SQLCODE || ' ' || SQLERRM);\n";
    $RETFINAL .= "END;\n";
    $RETFINAL .= "END LOOP;\n";
    $RETFINAL .= "FOR cur_rec IN (SELECT owner, object_name, object_type, DECODE(object_type, 'PACKAGE', 1, 'PACKAGE BODY', 2, 'TYPE', 3, 'TYPE BODY', 4,'PROCEDURE', 5, 'FUNCTION' ,6, 'TRIGGER', 7, 'VIEW', 8, 'SYNONYM', 9, 99) AS recompile_order FROM dba_objects WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'TYPE', 'TYPE BODY') ORDER BY 4,1,2) LOOP \n";
    $RETFINAL .= "DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Se han detectado los siguientes errores en: ' || cur_rec.object_type || ': ' || cur_rec.object_name);\n";
    $RETFINAL .= "FOR cur_err IN (SELECT SEQUENCE, LINE, POSITION, substr(TEXT,1,239) TEXT from dba_errors where owner = cur_rec.owner and name = cur_rec.object_name and type = cur_rec.object_type and text not like '%PL/SQL:%Statement ignored%') LOOP \n";
    $RETFINAL .= "DBMS_OUTPUT.put_line( cur_err.line || ': ' || cur_err.position || ' >> ' || cur_err.text );\n";
    $RETFINAL .= "END LOOP;\n";
    $RETFINAL .= "END LOOP;\n";
    $RETFINAL .= "END;\n";
    $RETFINAL .= "/\n";
    $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Fin del proceso de compilacion de los elementos del pase');\n";
    $RETFINAL .= "\n";
    $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Informe del estado de los objetos involucrados en el pase');\n";
    $RETFINAL .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND TABLE_NAME IN (SELECT OBJECT_NAME FROM DBA_OBJECTS WHERE LAST_DDL_TIME >= TO_DATE('$StartTMSTMP', 'YYYY/MM/DD HH24:MI:SS') and object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'VIEW', 'FUNCTION', 'SYNONYM')));\n";
    $RETFINAL .= "exec DBMS_OUTPUT.put_line(to_char(sysdate,'yyyymmdd hh24:mi:ss') || ': Informe de elementos INVALIDOS despues del pase');\n";
    $RETFINAL .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND STATUS = 'INVALID');\n";
    $RETFINAL .= "SPOOL $cadena.sql.POS\n";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Sacamos el informe de estado a un fichero externo
    $RETFINAL .= "SELECT RPAD(' TIPO',13,' ') || ' ' || RPAD('OBJETO',40,' ') || ' ' || RPAD('ESTADO',10,' ') FROM DUAL UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OWNER = '$OWNER' AND STATUS = 'INVALID' UNION SELECT RPAD(OBJECT_TYPE,13,' ') || ' ' || RPAD(OWNER||'.'||OBJECT_NAME,40,' ') || ' ' || STATUS FROM DBA_OBJECTS WHERE OBJECT_TYPE = 'SYNONYM' AND OBJECT_NAME IN (SELECT SYNONYM_NAME FROM DBA_SYNONYMS WHERE TABLE_OWNER = '$OWNER' AND STATUS = 'INVALID');\n";
    $RETFINAL .= "exit\n";
    $RETFINAL .= "\n";

    open FileOUT, ">:encoding(iso-8859-15)", "$PaseDir/restore/$cadena.sql";
    print FileOUT $RETFINAL;
    close FileOUT;
    $_log = "";

    open FileIN, "<$PaseDir/restore/$cadena.sql";
    $_log .= $_ for <FileIN>;
    close FileIN;

    $log->debug("$PaseDir/restore/$cadena.sql generado con éxito", $_log);
    $RET = system("cd $PaseDir/restore ; " . $self->gnutar . " cvf \"$cadena.sql.tar\" \"$cadena.sql\" ; gzip -f \"$cadena.sql.tar\"");

    ## HARAX
    #($Puerto) = getUnixServerInfo($Servidor, "HARAX_PORT");
    $Puerto  = $self->inf->get_unix_server_info({server => $Servidor, env => substr($self->env, 0, 1)}, 'HARAX_PORT');
    $Retorno = 0;
    $Warn    = 0;
    try {
      $log->debug("Intentando conexión a $Servidor por el puerto $Puerto.\nInstancia ORACLE: $Instancia");
      # $harax = balix_unix($Servidor);
      $balix_pool->conn($Servidor);
      $log->debug("Conexión a $Servidor por el puerto $Puerto\n");
      ## CREO EL DIR de PASE
      my $cmd = "mkdir -p $haraxDir";
      ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
      # ($RC, $RET) = $harax->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        $log->error("Error al crear el directorio de $haraxDir: $RET");
        _throw "Error al crear el directorio de $haraxDir: $RET";
      }
      else {
        $log->debug("Directorio '$haraxDir' creado: $RET");
      }
      ## ENVIO TAR.GZ
      $log->info("Enviando DDL's al Servidor'. Espere...");
      ($RC, $RET) = $balix_pool->conn($Servidor)->sendFile("$PaseDir/restore/$cadena.sql.tar.gz", "$haraxDir/$cadena.sql.tar.gz");
      if ($RC ne 0) {
        $log->error("Error al enviar fichero tar $cadena.sql.tar.gz: $RET");
        _throw "Error al enviar fichero tar $cadena.sql.tar.gz: $RET";
      }
      else {
        $log->debug("Fichero '$cadena.sql.tar.gz' creado en servidor: $RET");
      }
      ## CAMBIO DE PERMISOS Y OWNER
      $cmd = "chown " . $self->OraUser . " \"$haraxDir/$cadena.sql.tar.gz\" ; chmod 750 \"$haraxDir/$cadena.sql.tar.gz\"";
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($Servidor)->execute($cmd);
      if ($RC ne 0) {
        $log->error("Error al cambiar permisos del fichero $haraxDir/$cadena.sql.tar.gz: $RET");
        _throw "Error al cambiar permisos del fichero $haraxDir/$cadena.sql.tar.gz: $RET";
      }
      else {
        $log->debug("Fichero '$haraxDir/$cadena.sql.tar.gz' con permisos para '" . $self->OraUser . "': $RET");
      }

      ## DESCOMPRIME
      $cmd = qq{cd $haraxDir ; rm -f "$haraxDir/$cadena.sql"; gzip -f -d "$haraxDir/$cadena.sql.tar.gz" ; tar xmvf "$haraxDir/$cadena.sql.tar"; rm -f "$haraxDir/$cadena.sql.tar"};
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
      # ($RC, $RET) = $harax->executeas($self->OraUser, $cmd);
      if (($RC ne 0) or ($RET =~ m/no space/i)) {
        $log->error("Error al descomprimir $cadena.sql.tar.gz (¿Falta espacio en disco en el servidor $Servidor?): $RET");
        _throw "Error al descomprimir $cadena.sql.tar.gz (¿Falta espacio en disco en el servidor $Servidor?): $RET";
      }
      else {
        $log->debug("Fichero $cadena.sql.tar.gz descomprimido: $RET");
      }
      ## EJECUTA SQLPLUS
      $log->info("Realizando RESTORE de los elementos del pase en $Instancia");
      $cmd = qq{cd $haraxDir ; . /home/aps/dba/scripts/dbas001 $Instancia ; export NLS_LANG=SPANISH_SPAIN.UTF8 ; sqlplus -l / \@$haraxDir/$cadena.sql};
      $log->debug($cmd);
      ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);
      if ($RC ne 0) {
        $log->error("Error ejecutando script $haraxDir/$cadena.sql:",   $RET);
        _throw "Error ejecutando script $haraxDir/$cadena.sql:", $RET;
      }
      else {
        $log->info("Ejecutado el script $haraxDir/$cadena.sql:", $RET);
      }
    }
    catch {
      $log->warn("Error durante el RESTORE de la Instancia ORACLE: $Instancia");
      $Retorno++;
    }
    $RC = $RET = 0;

    ## GESTIONAMOS LA VARIABLE DEL TAR A UTILIZAR .
    my $tarExecutable;

    $cmd = "ls " . $self->tar_dest_aix;
    $log->debug($cmd);
    ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);

    if ($RC ne 0) {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
      $log->info("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
      $tarExecutable = "tar";
    }
    else {
      $log->info("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
      $tarExecutable = $self->tar_dest_aix;
    }

    ## COMPRIME LAS SALIDAS DE SQLPLUS
    $cmd = qq{cd $haraxDir ; $tarExecutable cvf $cadena.sql.OUT.tar $cadena.sql.* ; gzip -f "$haraxDir/$cadena.sql.OUT.tar"};
    $log->debug($cmd);
    ($RC, $RET) = $balix_pool->conn($Servidor)->executeas($self->OraUser, $cmd);

    if ($RC ne 0) {
      if ($RET !~ m/no existe/i) {
        $log->error("Error al comprimir ficheros de salida en $cadena.sql.OUT.tar: $RET");
        _throw "Error al comprimir ficheros de salida en $cadena.sql.OUT.tar: $RET";
      }
      else {
        $log->error("SQLPlus no ha generado ningún fichero de salida. ¿Fallo la conexión a ORACLE?:\n $RET");
        _throw "SQLPlus no ha generado ningún fichero de salida";
      }
    }
    else {
      $log->info("Comprimidos los scripts de salida en $cadena.sql.OUT.tar: $RET");
    }

    if (($RC ne 0) && ($RET !~ m/no existe/i)) {
      $log->error("Error al comprimir ficheros de salida en $haraxDir/$cadena.sql.OUT.tar: $RET");
      _throw "Error al comprimir ficheros de salida en $haraxDir/$cadena.sql.OUT.tar: $RET";
    }
    elsif ($RET !~ m/no existe/i) {
      $log->info("Comprimidos los scripts de salida en $haraxDir/$cadena.sql.OUT.tar", $RET);
    }

    ## RECEPCION TAR.GZ
    $log->info("Recogiendo las salidas del Servidor'. Espere...");
    ($RC, $RET) = $balix_pool->conn($Servidor)->getFile("$haraxDir/$cadena.sql.OUT.tar.gz", "$PaseDir/restore/$cadena.sql.OUT.tar.gz");

    if ($RC ne 0) {
      $log->error("Error al enviar fichero tar $haraxDir/$cadena.sql.OUT.tar.gz: $RET");
      _throw "Error al enviar fichero tar $haraxDir/$cadena.sql.OUT.tar.gz: $RET";
    }
    else {
      $log->info("Fichero '$PaseDir/restore/$cadena.sql.OUT.tar.gz' creado en servidor: $RET");
    }

    $log->info("Validando la ejecución del script de creación de objetos ORACLE");
    $RET = system(qq ( cd $localdir ; rm -f "$cadena.sql.OUT" ; gunzip "$cadena.sql.OUT.tar.gz" ; tar xvof "$cadena.sql.OUT.tar" ));

    my $OutPut  = 0;
    my $pCab    = 0;
    my $ObjName = "";
    my $ObjType = "";

    $_log = "";
    $_log = "";

    if (-e "$PaseDir/restore/$cadena.sql.OUT") {
      open FileIN, "<$PaseDir/restore/$cadena.sql.OUT";
      foreach $RET (<FileIN>) {
        $_log .= $RET;

        $OutPut = 1 if ($RET =~ m/involucrados/);
        $OutPut = 0 if ($RET =~ m/INVALIDOS/);

        $Retorno++ if ($OutPut gt 0 && $RET =~ m/ERROR|ORA\-\d+/i);
        if ($OutPut gt 0 && $RET =~ m/ADVERTENCIA|WARNING|INVALID/i) {
          $ObjName = substr($RET, index($RET, $OWNER) + 1 + length($OWNER), index($RET, " ", index($RET, $OWNER)) - (index($RET, $OWNER) + 1 + length($OWNER))) if (index($RET, $OWNER) ge 0);
          $ObjType = substr($RET, 0, index($RET, $OWNER));
          $ObjType =~ s/\s+$//;
          if (length($ObjName) gt 0) {
            if ($self->Objetos->{$ObjName} ne "") {
              $Retorno++;
              if ($pCab eq 0) {
                $pCab++;
                $_log = "ERROR: Los siguientes elementos involucrados en el pase quedaron en estado INVALIDO:\n";
              }
              $_log .= "{$ObjType} $ObjName\n";
            }
            else {
              $Warn++;
            }
          }
        }
      }
      close FileIN;
    }
    $log->info($_log) if (length($_log) gt 0);

    $LOGPRE = "";
    if (-e "$PaseDir/restore/$cadena.sql.PRE") {
      open FileIN, "<$PaseDir/restore/$cadena.sql.PRE";
      $LOGPRE .= $_ for <FileIN>;
      close FileIN;
      $log->info("Recuperado informe de situación previa", $LOGPRE);
    }

    $LOGPOS = "";
    if (-e "$PaseDir/restore/$cadena.sql.POS") {
      open FileIN, "<$PaseDir/restore/$cadena.sql.POS";
      $LOGPOS .= $_ for <FileIN>;
      close FileIN;
      $log->info("Recuperado informe de situación posterior", $LOGPOS);
    }

    if ((-e "$PaseDir/restore/$cadena.sql.PRE") && (-e "$PaseDir/restore/$cadena.sql.POS")) {
      open FWSPRE, "<$PaseDir/restore/$cadena.sql.PRE";
      open FWSPOS, "<$PaseDir/restore/$cadena.sql.POS";

      my @PRE  = <FWSPRE>;
      my @POS  = <FWSPOS>;
      my $i    = 0;
      my $j    = 0;
      my $sPRE = "";
      my $sPOS = "";
      my @tPRE;
      my @tPOS;
      my $PRE;
      my $POS;

      $pCab = 0;
      while (($sPRE ne "___") || ($sPOS ne "___")) {
        $PRE = $PRE[$i];
        $PRE =~ s/PACKAGE BODY/PACKAGEBODY /ig;
        $POS = $POS[$j];
        $POS =~ s/PACKAGE BODY/PACKAGEBODY /ig;

        if ($sPRE eq $sPOS) {
          if   ($i eq @PRE) { $sPRE = "___"; }
          else              { @tPRE = split(/\s+/, $PRE); $sPRE = $tPRE[1]; $i++; }
          if   ($j eq @POS) { $sPOS = "___"; }
          else              { @tPOS = split(/\s+/, $POS); $sPOS = $tPOS[1]; $j++; }
        }
        elsif (($sPRE lt $sPOS)) {
          if   ($i eq @PRE) { $sPRE = "___"; }
          else              { @tPRE = split(/\s+/, $PRE); $sPRE = $tPRE[1]; $i++; }
        }
        elsif (($sPRE ge $sPOS)) {
          if ($self->Objetos->{$tPOS[1]} ne "") {
            if ($pCab eq 0) { $pCab++; $log->error("ERROR: Los siguientes elementos no involucrados en el pase quedaron en estado INVALIDO:") }
            $log->error( "{$tPOS[0]} $tPOS[1]\n" );
            $Retorno++;
          }
          if   ($j eq @POS) { $sPOS = "___"; }
          else              { @tPOS = split(/\s+/, $POS); $sPOS = $tPOS[1]; $j++; }
        }
        $tPOS[0] =~ s/PACKAGEBODY/PACKAGE BODY/ig;
        $tPRE[0] =~ s/PACKAGEBODY/PACKAGE BODY/ig;
      }

      close FWSPRE;
      close FWSPOS;
    }
    else {
      $log->info( "INFO: No se pueden comparar los informes de situación");
    }
    if ($Retorno gt 0) {
      $log->error("Se han producido errores en la ejecución del script de RESTORE de objetos ORACLE. Revisar LOG.", $_log);
      _throw "Error realizando el proceso de despliegue de objetos ORACLE ($Instancia)";
      return ($Retorno);
    }
    elsif ($Warn gt 0) {
      $log->warn( "Hay objetos en estado INVALIDO después del RESTORE ORACLE ($Instancia). Revisar LOG.", $_log);
    }
    else {
      $log->info( "Validada con éxito la ejecución del script de RESTORE de objetos ORACLE ($Instancia)", $_log);
    }
  }
  # $balix_pool->conn($Servidor)->end;
  return ($Retorno);
}

sub _build_Types {
  config_get('config.sql.types');
}

sub _build_TypesDDL {
  config_get('config.sql.types.dll');
}

sub _build_inf {
  my $self = shift;
  BaselinerX::Model::InfUtil->new(cam => $self->cam);
}

sub _build_resolver {
  my $self = shift;
  BaselinerX::Ktecho::Inf::Resolver->new({sub_apl => 'foo',
                                          entorno => $self->env,
                                          cam     => $self->cam});
}

sub _build_gnutar {
  config_get('config.bde')->{gnutar};
}

sub _build_tar_dest_aix {
  config_get('config.bde')->{tardestinosaix};
}

sub _build_OraUser {
  my $self = shift;
  my $oracle_unix_user = config_get('config.bde')->{oracle_unix_user};
  my $replace = $self->AcrEnt;
  $oracle_unix_user =~ s/\[t\|a\|p\]/$replace/g;
  $oracle_unix_user;
}

sub _build_AcrEnt {
  my $self = shift;
  lc(substr($self->env, 0, 1));
}

sub _build_OraRed {
  my $self = shift;
  BaselinerX::Model::InfUtil->new(cam => $self->cam)->nets_oracle_r7;
}

1;
