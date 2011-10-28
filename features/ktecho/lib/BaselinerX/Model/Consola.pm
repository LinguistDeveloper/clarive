package BaselinerX::Model::Consola;
use strict;
use warnings;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use YAML;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub get_tar_dir {
    my ( $self, $args_ref ) = @_;
    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    my $balix      = $args_ref->{balix};
    my $dir_remoto = $args_ref->{dir_remoto};
    my $dir_local  = $args_ref->{dir_local};
    my $fichero    = $args_ref->{fichero};
    my $rem_tmp    = $args_ref->{rem_tmp};
    my $directo    = $args_ref->{directo};

    my $config_bde   = Baseliner->model('ConfigStore')->get('config.bde');
    my $consola_tail = $config_bde->{consola_tail};
    my $consola_dias = $config_bde->{consola_dias};

    my ( $dir, $dirlocal, $filename ) = ( $dir_remoto, $dir_local, $fichero );

    my $tail_lines = $consola_tail || $consola_tail || 4000;
    my $find_dias  = $consola_dias || $consola_dias || 7;

    unless ( $dir && $dirlocal && $filename && ( length($dir) > 4 ) ) {
        print "\nget_tar_dir: Error: falta algún parámetro.\n";
        print '*' x 95;
        print
          "\n** Posiblemente la aplicación no esté configurada para este tipo de log/config.\n";
        print '*' x 95;
        print "\n";
        die "Error en la generación del TAR ";
    }

    $dir = "$dir/";

    $log->debug("Consola: getTAR: $dir");

    my $canon = File::Spec::Unix->canonpath($dir);

    if ( length($dir) <= 1 || $canon eq '/' || length($canon) <= 1 ) {
        $log->error(
            "Consola: getTar: intento de leer del directorio root o vacío (dir='$dir',"
              . "canonpath='$canon')." );
        print "Consola: getTar: Directorio a leer inválido: $dir.";

        exit 1;
    }
    else {
        $log->info("Consola: OK. Inicio getTar del directorio '$dir'");
    }

    my ( $rc, $ret ) = $balix->execute("ls '$dir'");

    if ( $rc ne 0 ) {
        print "getTAR: $dir no existe: $ret\n";
        return q{};
    }
    else {

        #TODO otro `$p....`
        if ($directo) {

            # Comprueba si hay ficheros
            ( $rc, $ret ) = $balix->execute(qq{find "$dir" -type f});

            chomp $ret;

            unless ( $rc || $ret ) {
                print '*' x 80;
                print
                  "\nNo se ha encontrado ningún fichero en el directorio remoto.\n";
                print '*' x 80, "\n\n";
                return;
            }
            elsif ($rc) {
                print
                  "Error al intentar comprobar el contenido del directorio remoto '$dir': $ret";
                return;
            }
        }
        else {

            # Comprueba si hay fichero dentro del tiempo stipulado
            ( $rc, $ret )
              = $balix->execute(qq{find "$dir" -type f -mtime -$find_dias});

            chomp $ret;

            unless ( $rc || $ret ) {
                print '*' x 80;
                print
                  "\nNo hay actividad en la aplicación en los últimos $find_dias días.\n";
                print '*' x 80, "\n\n";
                return;
            }
            elsif ($rc) {
                print
                  "Error al intentar comprobar el contenido del directorio remoto '$dir': $ret";
                return;
            }
        }

        # Si no existe directorio lo crea
        ( $rc, $ret )
          = $balix->execute(
            qq{if [ ! -d "$rem_tmp" ]; then mkdir -p "$rem_tmp"; fi});
        if ( $rc ne 0 ) {
            print "Error creando directorio '$rem_tmp': $ret\n";
            return q{};
        }
        else {
            print "Creado directorio '$rem_tmp': $ret\n";
        }

        # Creacion del tar remoto
        if ($directo) {

            # la h indica al tar que siga enlaces simbólicos
            ( $rc, $ret )
              = $balix->execute(
                qq{cd "$dir" ; tar cvhf "$rem_tmp/$filename" * });
        }
        else {

            # directorio temporal del tar
            my $tempdir = "$rem_tmp/" . ahora_log();
            $log->debug("Consola: creando temporal $tempdir");

            print "Path temporal para el tar '$tempdir'\n";

            ( $rc, $ret ) = $balix->execute(qq{mkdir -p "$tempdir"});

            if ($rc) {
                print
                  "getTAR: no he podido crear el temporal para generar el tar-tail '$tempdir'"
                  . " (rc=$rc): $ret\n";

                return;
            }

            # hace un find  de los ficheros de menos de  x días,  crea la ruta
            # relativa en tempdir y los transporta al tempdir con un tail.  Es
            # la manera de hacerlo sin copy+tail de ficheros - que son enormes
            # y podrían llenar el $tempdir
            ( $rc, $ret ) = $balix->execute(
                qq{cd '$dir'; find . -type f -mtime -$find_dias | perl -MFile::Spec -n -e 'chomp;
						\@a=File::Spec->splitpath("$tempdir/\$_");
						print `mkdir -p \$a[1]`; 
						print `tail -$tail_lines \$_ > $tempdir/\$_`' 
					}
            );

            $log->info("Consola: getTAR salida (rc=$rc): $ret");

            if ( $rc ne 0 ) {
                print "getTAR: Error temporal tar: $ret\n";

                exit 1;
            }
            else {
                print "getTAR: OK temporal tar: $ret\n";
            }

            # ahora un tar de los ficheros en temporal
            $log->info(
                "Consola: creando tar '$rem_tmp/$filename' en $tempdir...");

            # la h indica al tar que siga enlaces simbólicos
            ( $rc, $ret )
              = $balix->execute(
                qq{cd "$tempdir" ; tar cvhf "$rem_tmp/$filename" * ; cd - ; rm -rf "$tempdir" }
              );
        }

        if ( $rc ne 0 ) {
            print
              "getTAR: error al generar el TAR en $rem_tmp/$filename: $ret\n";
            return q{};
        }

        else {
            ( $rc, $ret )
              = $balix->getFile( "$rem_tmp/$filename",
                "$dirlocal/$filename" );

            if ( $rc eq 0 ) {
                ( $rc, $ret ) = $balix->execute("rm '$rem_tmp/$filename'");
                print "getTAR: fichero $dirlocal/$filename transmitido ok.\n";

                return "$filename";
            }
            else {
                print
                  "getTAR: error al transmitir el fichero '$rem_tmp/$filename' a '$dirlocal/"
                  . "$filename':$ret\n";
            }
        }
    }

    return q{};
}

sub write_bin_log {
    my ( $self, $args_ref ) = @_;

    my $dbh      = $args_ref->{dbh};
    my $pase     = $args_ref->{pase};
    my $filedir  = $args_ref->{filedir};
    my $filename = $args_ref->{filename};
    my $cam      = $args_ref->{cam};

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    open FF, "<$filedir/$filename"
      or die
      "write_bin_log: Error: No he podido abrir el fichero $filedir/$filename: $!\n";

    binmode FF;

    my $filesize = sprintf( "%.2f", ( ( -s FF ) / 1024 ) );
    my $data = q{};
    $data .= $_ while (<FF>);

    close FF;

    my $iddat = $har_db->db->value( "
                    SELECT distlogdataseq.nextval 
                    FROM   dual " );

    my $idlog = $har_db->db->value( "
                    SELECT distlogseq.nextval 
                    FROM   dual  " );

    my $row = Baseliner->model('Harvest::Distlogdata')->create(
        {   dat_id               => $iddat,
            dat_logid            => $idlog,
            dat_pase             => $pase,
            dat_nombre           => $filename,
            dat_binary_contenido => $data } );

    return $idlog;
}

1;
