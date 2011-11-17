package BaselinerX::BdeUtils;
use strict;
use warnings;
use Baseliner::Utils;
use Baseliner::Sugar;
use utf8;
use Exporter::Tidy default => [
  qw(get_package_dependencies list_package_dependencies check_package_state
  check_package_state_do_or_die get_cam_uc envia_correo_pase paquetes_html
  get_token lifecycle_for_packagename _cam _cam_from store_backup bl_statename
  ahora _projects_from_elements hardistXML _bde_conf get_backups inf fix_net
  net_version clickonce_version)];

sub get_package_dependencies {
    my ( $proyecto, $tipo_pase, $paquetes_ref ) = @_;
    my @paquetes    = _array($paquetes_ref);
    my $hardb       = BaselinerX::Ktecho::Harvest::DB->new;
    my $paquetes_in = "('" . join( "','", @paquetes ) . "')";
    my $sql         = q{};
    my $comparacion = q{};

    if ( $tipo_pase eq "N" ) {
        $comparacion = "<";
    }
    else {
        $comparacion = ">";
    }

    my %args = (
        'proyecto'    => $proyecto,
        'paquetes_in' => $paquetes_in,
        'comparacion' => $comparacion
    );
    my %dependencias = $hardb->get_dependencias( \%args );

    return %dependencias;
}

sub list_package_dependencies {
    my ( $proyecto, $tipo_pase, $paquetes_ref ) = @_;
    my @paquetes     = _array($paquetes_ref);
    my %dependencias = ();
    my $mensaje      = q{};

    $mensaje .= "|\nDEPENDENCIAS DE LOS PAQUETES " . join( ", ", @paquetes ) . ":\n";

    %dependencias = get_package_dependencies( $proyecto, $tipo_pase, \@paquetes );

    if (%dependencias) {

        my $paquete_dep_anterior = "";
        foreach ( sort( keys %dependencias ) ) {
            my ( $paquete_dep, $item, $version ) = @{ $dependencias{$_} };
            if ( $paquete_dep ne $paquete_dep_anterior ) {
                $mensaje .= "|      \n|----$paquete_dep\n|     |\n";
                $paquete_dep_anterior = $paquete_dep;
            }
            $mensaje .= "|     |----$item: versión $version\n";
        }

    }
    else {
        $mensaje .= "|      \n|----NO hay dependencias\n";
    }

    return $mensaje . "|\n";
}

sub check_package_state {
    use strict;

    my $env   = shift;    # aqui puede venir un '%' desde pase.pm
    my $state = shift;

    my $db = Baseliner::Core::DBI->new( { model => 'Harvest' } );

    my @states;
    push @states, uc($state);
    push @states, 'PRUEBAS'
        if $state =~ /Preprodu/i;    ## en ciclos de vida cortos pueden venir por ahi

    my $pkgin = "'" . join( "','", @_ ) . "'";
    my $state_in = "upper('" . join( "'),upper('", @states ) . "')";

    return $db->array( "
        SELECT TRIM(packagename)
                || ' ('
                || TRIM(statename)
                || ')'
        FROM   harpackage p,
               harstate s,
               harenvironment e
        WHERE  p.stateobjid = s.stateobjid
               AND TRIM(packagename) IN ( $pkgin )
               AND Upper(TRIM(p.status)) = 'IDLE'
               AND s.envobjid = e.envobjid
               AND e.environmentname LIKE '$env'
               AND Upper(TRIM(statename)) NOT IN ( $state_in )
        " );
}

sub check_package_state_do_or_die {
    use strict;
    use feature qw(say);

    my ( $env, $state, @packages ) = @_;

    my $config_bde           = Baseliner->model('ConfigStore')->get('config.bde');
    my $package_promote_wait = $config_bde->{package_promote_wait};

    if ( my @package_state = check_package_state( $env, $state, @packages ) ) {
        say "*** AVISO: Los paquetes no estan en el estado ($state) que les corresponde para iniciar el pase.: ";
        say $_ for @package_state;

        my $delay = $package_promote_wait;
        say "Esperando $delay segundos para un nuevo intento...\n";
        sleep $delay;

        if ( my @package_state = check_package_state( $env, $state, @_ ) ) {
            die "*** ERROR (segundo intento): los paquetes no están en el estado ($state) que les corresponde para iniciar el pase.: ";
            say $_ for @package_state;
        }
        else {
            say "OK. paquetes están en su estado correspondiente (tras una espera de ${delay}s).\n";
        }
    }
    else {
        say "Comprobando que los paquetes están en su estado correspondiente... Espere... \n";
    }

    return;
}

# Convierte de $env_name a $cam y $cam_uc (mayusc. y minúsc.)
sub get_cam_uc {
    my ($env_name) = @_;
    my $cam = lc( substr( $env_name, 0, 3 ) );
    my $cam_uc = uc($cam);

    return ( $cam, $cam_uc );
}

sub _cam {
  uc substr(shift(), 0, 3);
}

sub envia_correo_pase {
    use strict;

    # Parámetros (en HASH)
    my %params     = @_;
    my $pase       = $params{pase};
    my $message    = $params{message};
    my $usuario    = $params{usuario};
    my $entorno    = $params{entorno};
    my $tipo_pase  = $params{tipo_pase};
    my $aplicacion = $params{aplicacion};
    my $accion     = $params{accion};
    my $alone      = $params{alone};

    my $har_db        = BaselinerX::Ktecho::Harvest::DB->new;
    my @paquetes      = $har_db->get_pass_packages($pase);
    my $paquetes_html = paquetes_html(@paquetes);

	my @cc_users;
	my @cc_emails;

	# TO : usuario que ha lanzado el pase + propietarios de los paquetes del pase
    my @propietarios = $har_db->get_owners(@paquetes);

	push @propietarios, $usuario; 	## añado el usuario que ha lanzado el pase

	# CC : RAs (siempre) y RPTs (PROD)
	if( ($entorno eq "PROD") or ($entorno eq "ANTE")) {
        foreach my $env_name ( $har_db->get_pass_projects($pase) ) {
            if ($alone) {
                push @cc_users, $har_db->get_ra_alone($env_name);
            }
            else {
                push @cc_users, $har_db->get_ra($env_name);
            }
        }
	}

    if ( ( $entorno eq "PROD" ) and ( $params{nats} ) ) {
        foreach my $nat ( @{ $params{nats} } ) {
            push( @cc_emails, $har_db->get_email_rpt("RPT-WAS") ) if ( $nat =~ m/J2EE/i );
            push( @cc_emails, $har_db->get_email_rpt("RPT-WIN") ) if ( $nat =~ m/NET/i );
        }
    }

    #TODO logdebug "pase $pase: Enviando correo a TO: @propietarios, CC: @cc_users @cc_emails";

    if ( scm_entorno() ne 'PROD' ) {
        @cc_users  = ();
        @cc_emails = ();

        #TODO logdebug "pase $pase: Por estar en TEST envío correo a TO: @propietarios, "
        #TODO     . "CC: @cc_users @cc_emails";
    }

    notify(
        option        => "P",
        template      => "pase.html",
        subject       => "$message: $pase",
        silent        => 1,
        usuario       => "$usuario",
        usuario_largo => $har_db->get_real_name($usuario),
        paquetes      => $paquetes_html,
        mensaje       => $message,
        entorno       => $entorno,
        tipo_pase     => $tipo_pase,
        pase          => $pase,
        aplicacion    => $aplicacion,
        accion        => $accion,
        to_users      => [@propietarios],
        cc_users      => [@cc_users],
        cc_emails     => [@cc_emails]
    );
}

sub paquetes_html {
    my $html;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    foreach my $package_new (@_) {
        my ( $tipo_cambio, $detalle_cambio ) = $har_db->get_paquete_motivo($package_new);

        $html
            .= '<LI>' . "<B>"
            . $package_new . "</B>" . " ("
            . $tipo_cambio . ": "
            . $detalle_cambio
            . ")</LI>";
    }

    return "<UL>$html</UL>";
}

sub chm_token {
    my $agent_port = 58765;  # TODO
    my $bx = new BaselinerX::Comm::Balix(
       key=>config_get( 'config.harax' )->{$agent_port},
       host => 'expsv011',
       port => $agent_port,
    );

    my $ret = $bx->executeas( 'vpchm', 'racxtk 01 vpchm batchp prue' );
    my $pw = [split( /\n/, $ret->{ret} )]->[1];
}

=head2 get_token ( user=>Str, service=>Str (ftp|batchp|...), server=>Str )

Get token connection.

=cut

sub get_token {
    my $p       = shift;
    my $user    = $p->{user};
    my $service = $p->{service};
    my $server  = $p->{server};

    _log "getting token for user $user to do $service to $server";

    my $agent_port = 58765;  # TODO
    my $key = config_get('config.harax')->{$agent_port};
    my $host = 'expsv011';

    my $bx = BaselinerX::Comm::Balix->new(key  => $key,
                                          host => $host,
                                          port => $agent_port);

    my $ret = $bx->executeas(qq{$user}, qq{racxtk 01 $user $service $server});
    my $pw  = $1 if $ret->{ret} =~ m{.*\n(.*?)\n$}s;
    $pw;
}

sub lifecycle_for_packagename {
    my $package = shift;
    my $config  = config_get 'config.bde.lifecycle';
    my $type    = lc_char_packagename($package);
    $config->{$type};
}

sub lc_char_packagename {
    my $package = shift;
    substr($package, 4, 1);
}

sub _cam_from {
    my %p = @_;
    my @current_vals = (q/fid/);
    if (exists $p{fid}) {
        my $formobjid = $p{fid};
        my $pkg = Baseliner->model('Harvest::Harassocpkg')
                   ->search({formobjid => $formobjid})
                      ->first->assocpkgid;
        my $env = $pkg->envobjid;
        return substr($env->environmentname, 0, 3);
    }
    _throw "Give proper parameters: @current_vals";
    return;
}

sub store_backup {
  my %p        = @_;
  my $filename = $p{file_path};    # File name without path.
  $filename =~ s/.*\/(.*?)/$1/g;

  # Read file.
  open FF, "<$p{file_path}";
  binmode FF;
  my $data = "";
  $data .= $_ while (<FF>);
  close FF;

  my $har_db = BaselinerX::CA::Harvest::DB->db;

  # Delete last row in DISTBAK.
  $har_db->do("
    DELETE FROM distbak
          WHERE environmentname = '$p{env_name}'
            AND entorno = '$p{entorno}'
            AND subapl = '$p{sub_apl}'
            AND naturaleza = '$p{suffix}'
            AND tipo = '$p{type}'
  ");

  my $seq = $har_db->value("
    SELECT distbakseq.NEXTVAL
      FROM DUAL
  ");

  # Store in blob DISTBAK
  my $sql = $har_db->prepare("
    INSERT INTO distbak
                (ID, pas_codigo, naturaleza, filename, entorno, subapl,
                 environmentname, tipo, root_path, BACKUP
                )
         VALUES (?, ?, ?, ?, ?, ?,
                 ?, ?, ?, ?
                )
  ");
  my $sth = $har_db->prepare($sql);
  $sth->bind_param(1,  $seq,          {TYPE     => 'SQL_INTEGER'});
  $sth->bind_param(2,  $p{pass},      {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(3,  $p{suffix},    {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(4,  $filename,     {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(5,  $p{entorno},   {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(6,  $p{sub_apl},   {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(7,  $p{env_name},  {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(8,  $p{type},      {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(9,  $p{root_path}, {TYPE     => 'SQL_VARCHAR'});
  $sth->bind_param(10, $data,         {ora_type => 'ORA_BLOB'   });
  $sth->execute;
  $har_db->commit;
  my $datasize = sprintf("%.2f", (length($data) / 1024));
  undef $data;
  ($seq, $datasize);
}

### bl_statename : Str -> Str
sub bl_statename {
  my $where = {bl => shift()};
  my $args = {select => 'name'};
  my $rs = Baseliner->model('Baseliner::BaliBaseline')->search( $where, $args );
  rs_hashref($rs);
  $rs->first->{name};
}

sub ahora {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
  $year += 1900;
  $mon  += 1;
  sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour}, ${min}, ${sec};
}

sub _projects_from_elements {
  my %elements = %{shift @_};
  my $env_name = shift @_;
  my $version_id;
  my %projects;
  foreach $version_id (keys %elements) {    ## preparo un listado de proyectos
    my $element          = $elements{$version_id}->{FileName};
    my $element_name     = $elements{$version_id}->{FileName};
    my $package_new      = $elements{$version_id}->{PackageName};
    my $system_name      = ' ';
    my $subsystem_name   = $elements{$version_id}->{SubSystemName};
    my $ds_name          = $elements{$version_id}->{DSName};
    my $element_type     = ($element =~ m/.+\.(.+)/);
    my $element_state    = $elements{$version_id}->{ElementState};
    my $element_version  = $elements{$version_id}->{ElementVersion};
    my $element_priority = $elements{$version_id}->{ElementPriority};
    my $element_path     = $elements{$version_id}->{ElementPath};
    my $element_id       = $elements{$version_id}->{ElementID};
    my $par_comp_ini     = $elements{$version_id}->{ParCompIni};
    my $IID              = $elements{$version_id}->{ElementID};
    my $project          = $elements{$version_id}->{HarvestProject};
    if (($env_name ne "") && ($env_name ne $project)) {
      ##quieren filtrarme por nombre de environment y este no está en este environment: ignoro fila
      next;
    }
    my $project_name = (split(/\//, $element_path))[3];
    $projects{$project_name} = "1";
  }
  %projects;
}

sub hardistXML {
  my $log = shift;
  my $EstadoEntorno = config_get('config.bde')->{estado_entorno};
  my ($option, $PaseDir, $Entorno, $EnvironmentName, $Sufijo, $Project) = @_;
  my ($op_in, $op_ex, $op_msg) = (0, 0, 0);
  my @INRUTA = ();
  my %Inclusiones;
  my ($cam, $CAM) = get_cam_uc($EnvironmentName);

  #identifico la opcion enviada
  if ($option eq "IN") {
    $op_in  = 1;
    $op_msg = "inclusiones";
  }
  elsif ($option eq "EX") {
    $op_ex  = 1;
    $op_msg = "exclusiones";
  }
  else {
    $op_in  = 1;
    $op_ex  = 1;
    $op_msg = "inclusiones/exclusiones";
  }
  $Project = "/$Project" if ($Project);
  _log "PaseDir: $PaseDir";
  _log "CAM:     $CAM";
  _log "Sufijo:  $Sufijo";
  _log "Project: $Project";
  my $cmd = qq| find "$PaseDir/$CAM/${Sufijo}${Project}" -name "scm.xml" |;
  _log "\nObteniendo \@HARDIST ...\n cmd: $cmd";
  my @HARDIST = `$cmd`;
  _log "\n\@HARDIST:" . Data::Dumper::Dumper \@HARDIST;
  my $INEXLOG = "";
  foreach my $hardistxml (@HARDIST) {
    chop $hardistxml;
    my $xmlproject = $hardistxml;
    $xmlproject =~ s/(.*)\/scm\.xml$/$1/g;
    if ($hardistxml) {
      my $XML = XML::Smart->new($hardistxml);
      if ($XML) {    ##hay fichero XML
        $log->info("Procesando <b>$op_msg</b> en el fichero XML <b>'$hardistxml'</b>");
        if ($op_in) {
          ## INCLUSIONES ##
          my @INAPL = $XML->{scm}{inclusiones}{proyecto}('[@]', 'nombre');
          $INEXLOG = "---------Log de Inclusiones--------\n" if (@INAPL);
          foreach my $inapl (@INAPL) {
            if ($inapl ne "") {
              $INEXLOG .= "Aplicación: $inapl\n";
              my @INTIPO = $XML->{scm}{inclusiones}{proyecto}('nombre', 'eq', $inapl) {'tipo'}
              ('[@]', 'nombre');
              foreach my $intipo (@INTIPO) {
                $INEXLOG .= "Tipo: $intipo\n";
                my @INPRO = @{
                  $XML->{scm}{inclusiones}{proyecto}('nombre', 'eq', $inapl)
                  {'tipo'}
                  ('nombre', 'eq', $intipo) {'proyecto'}
                  };
                foreach my $inpro (@INPRO) {
                  $INEXLOG .= "Proyecto para incluir: $inpro\n";
                  push @INRUTA, "\\$inapl\\$intipo\\$inpro";
                }
              }
            }
          }
          foreach my $inruta (@INRUTA) {
            $log->info("Inciando checkout de proyecto incluido: <b>'$inruta'</b>...");
            my ($nada, $inapl, $intipo, $inpro) = split(/\\/, $inruta);
            $Inclusiones{"$PaseDir/$CAM/$Sufijo/$inpro"} = "$PaseDir/$inapl/$intipo";
            my $ret = checkOutState($inapl, $EstadoEntorno->{$Entorno}, $intipo, $inpro, "$PaseDir/$CAM/$Sufijo/$inpro");
            hardistXML($log, "EX", $PaseDir, $Entorno, $EnvironmentName, $Sufijo, $inpro) if ($op_ex);
          }
        }    #fin inclusiones

        if ($op_ex) {
          ## EXCLUSIONES ##
          my $EXAPL = $XML->{scm}{exclusiones}{proyecto}[0];
          if ($EXAPL eq 1) {
            my $RET = `mv '$xmlproject' '$PaseDir/tmp'`;
            $log->warn("<b>scm.xml</b>: Proyecto <b>'$xmlproject'</b> suprimido de la construcción/distribución.", $RET);
          }
          else {
            ## directorios
            my @EXDIR = @{$XML->{scm}{exclusiones}{excluir}};
            $INEXLOG .= "---------Log de Exclusiones (Directorios y Ficheros)--------\n" if (@EXDIR);
            $log->debug("Exclusión de directorios en '$EnvironmentName/$Sufijo': @EXDIR");
            for (@EXDIR) {
              $INEXLOG .= "Directorio: $_\n";
              if ($_ ne "") {
                if (/\.\.|\'|\"/) {
                  $log->warn("<b>scm.xml</b> (directorio / fichero '$_') contiene caracteres inválidos ('..', ''', '\"'). Directorio no excluido. (Fichero XML: $hardistxml)");
                }
                else {
                  my $dir = $_;
                  $dir =~ s/\*/\'\*\'/g;
                  $dir =~ s/\?/\'\?\'/g;
                  my $nombre = $dir;
                  $nombre =~ s{.*/(.*?)}{$1};
                  if ($dir) {
                    my $RET = `mv '$xmlproject/$dir' '$PaseDir/tmp/' 2>&1`;
                    if ($? eq 0) {
                      $log->debug("Excluido directorio/fichero '$xmlproject/$_'", $RET);
                    }
                    else {
                      $log->debug("Exclusión del directorio/fichero '$xmlproject/$_' no ha podido realizarse: $RET");
                    }
                    $INEXLOG .= "Excluido directorio/fichero '$xmlproject/$_' :\n\t$RET\n";
                  }
                }
              }
            }
            ## ficheros
            my @EXFIL = @{$XML->{scm}{exclusiones}{fichero}};
            $INEXLOG .= "---------Log de Exclusiones (Ficheros)--------\n" if (@EXFIL);
            for (@EXFIL) {
              if ($_ ne "") {
                if (/\.\.|\'|\"/) {
                  $log->warn("<b>scm.xml</b> (fichero de exclusion '$_') contiene caracteres inválidos ('..', ''', '\"'). Fichero no excluido. (Fichero XML: $hardistxml)");
                }
                else {
                  my $fich = $_;
                  $fich =~ s/\*/\'\*\'/g;
                  $fich =~ s/\?/\'\?\'/g;
                  if ($fich) {
                    my $RET = `mv '$xmlproject/$fich' '$PaseDir/tmp' 2>&1`;
                    if ($? eq 0) {
                      $log->debug("Excluido fichero '$xmlproject/$_'", $RET);
                    }
                    else {
                      $log->debug("Exclusión del fichero '$xmlproject/$_' no ha podido realizarse: $RET");
                    }
                    $INEXLOG .= "Excluido Fichero: '$xmlproject/$_' :\n\t$RET\n";
                  }
                }
              }
            }
          }
        }    #fin exclusiones
      }
      else {
        $log->warn("No he podido abrir el fichero xml del proyecto $xmlproject.");
      }
    }
  }
  $log->info("Inclusiones/Exclusiones finalizado.\n" . join("\n", @INRUTA), $INEXLOG) if ($INEXLOG);
  
  _log "\n inclusiones en hardistXML => " . Data::Dumper::Dumper \%Inclusiones;

  ##### fin scm.xml
  return %Inclusiones;
}

sub config { 'config.bde' }

sub _bde_conf { # Str -> Str
  config_get(config())->{shift()};
}

sub get_backups {
  my ($env_name, $env, $suffix, $file_dir, $sub_apl) = @_;
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  my $sql = qq{
    SELECT ID, pas_codigo, filename, tipo, BACKUP, root_path, subapl
    FROM distbak
    WHERE TRIM (environmentname) = '$env_name'
    AND TRIM (entorno) = '$env'
    AND TRIM (naturaleza) = '$suffix'
  };

  if ($sub_apl) {
    $sql .= " AND trim(upper(subapl)) = '" . uc($sub_apl) . "'";
  }

  $sql .= " ORDER BY 1";

  my @backups = $har_db->db->array_hash($sql);
  my %RET     = ();

  while (@backups) {
    my ($id, $pass, $filename, $tipo, $data, $rootPath, $subapl) = (
      shift @backups,
      shift @backups,
      shift @backups,
      shift @backups,
      shift @backups,
      shift @backups,
      shift @backups
    );
    if ($filename && $data) {
      my $file_path = $file_dir . "/" . $filename;
      open FF, ">$file_path";
      binmode FF;
      print FF $data;
      close FF;
      undef $data;
      @{$RET{$filename}} = ($pass, $file_path, $tipo, $rootPath, $subapl);
    }
    print "Encontrado fichero de backup $filename\n";
  }
  %RET;
}

sub inf { BaselinerX::Model::InfUtil->new(cam => shift) }

sub fix_net {
  my $net = shift;
  my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 7;
  if ($ver == 7) {
    $net = 'LN' if $net eq 'I';
    $net = 'W3' if $net eq 'W';
  }
  $net;
}

sub net_version {
  my $fileName    = shift @_;
  my @fileContent = ();
  my $version     = "";

  open(SLN, "<$fileName");
  @fileContent = <SLN>;
  close(SLN);

  if (grep(/Microsoft Visual Studio Solution File, Format Version 8.00/, @fileContent)) {
    $version = "2003";
  }
  else {
    $version = "20XX";
  }
  return $version;
}

sub clickonce_version {
  my $fileName    = shift @_;
  my @fileContent = ();
  my $version     = "";
  my $incremento  = "";

  open(PRJ, "<$fileName");
  my $linea = "";
  foreach $linea (<PRJ>) {
    if ($linea =~ /<ApplicationVersion>(.*)\.(.*)\.(.*)\.(.*)<\/ApplicationVersion>/) {
      $version = $1 . "_" . $2 . "_" . $3;
      if ($4 =~ /^\%.*/) {
        $incremento = "si";
        _log "Detectado incremento de version en el fichero de proyecto";
      }
      else {
        $incremento = "no";
        $version .= "_" . $4;
        _log "Detectada version fija en el fichero de proyecto";
      }
      last;
    }
  }
  close(PRJ);
  return ($version, $incremento);
}

1;

__DATA__

=head2 _bde_conf
  my $stawin = _bde_conf 'stawin';
=cut
