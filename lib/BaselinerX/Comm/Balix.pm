#############################################################
#
# Balix
#
#
#    my $balix = Balix->new( host=>'pruxxx', port=>58765, key=>'...base64_key...' [ os=>'win' , ] [timeout=>99 ] );
#      timeout de -1 desactiva el timeout
#
package BaselinerX::Comm::Balix;
use strict;
use IO::Socket;
use Carp;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Crypt::Blowfish::Mod;
use String::CRC32;
use Convert::EBCDIC qw/ascii2ebcdic ebcdic2ascii/;

@ISA     = qw();
@EXPORT  = qw();
$VERSION = '1.0';

my ( $RM, $RPORT, $RUSR, $RPWD ) = ();
my %PARAMS = ();

sub blow { shift->{blow}; }

# new_timeout: lo mismo que ->open, pero con timeout
#     problema: el timeout con threads es peligroso - volatiza la ejecucion
sub new {
    my $class = shift @_;
    my %p     = @_;
    $p{timeout} ||= $ENV{BALIX_TIMEOUT} || 10;
    my $balix = {};
    $balix->{debug}  = $p{debug} || 0;
	$balix->{os}     = $p{os};
    $balix->{blow}   = Crypt::Blowfish::Mod->new( $p{key} );
    warn ahora() . " - BALIX: conectando a $p{host}:$p{port} (timeout=$p{timeout})\n" if $balix->{debug};
    $balix->{socket} = IO::Socket::INET->new(
        PeerAddr => $p{host},
        PeerPort => $p{port},
        Proto    => "tcp",
        Type     => SOCK_STREAM
    ) or die "Error al abrir el socket: $!";
    if( $p{os} eq 'mvs' ) {
        $balix->{mvs} = 1;
        $balix->{ebc} = Convert::EBCDIC->new($Convert::EBCDIC::ccsid1047);
        binmode $balix->{socket};
        #$balix->{ebc} = Convert::EBCDIC->new($Convert::EBCDIC::ccsid819);
    }
    if ( ref $balix->{socket} ) {
        warn ahora() . " - BALIX: conectado a $p{host}:$p{port}\n" if $balix->{debug};
    }
    else {
        warn ahora() . " - BALIX: ERROR: no se ha podido conectar a $p{host}:$p{port}\n" if $balix->{debug};
        return undef;
    }
    $balix = bless( $balix, $class );
    eval {
        warn ahora() . " - BALIX: inicio ping con timeout a $p{host}:$p{port}\n" if $balix->{debug};
        local $SIG{ALRM} = sub {
            die "Timeout. Se ha sobrapasado el tiempo fijado ($p{timeout} seg) para la conexi�n por agente a $p{host}:$p{port}.\n";
        };
        if ( $p{timeout} ne -1 ) {
            alarm $p{timeout};
        }
        my ( $rc, $ret ) = $balix->execute("set");
		if( $ret =~ m/OS=(Win.*)$/i ) {
			print "OS detectado: $1\n";
		}
        warn ahora() . " - BALIX: fin ping ok (rc=$rc) con timeout a $p{host}:$p{port}\n" if $balix->{debug};
        alarm 0;
    };
	
    if ($@) {
        croak "Error de conexi�n por agente: $@";
    }
    return $balix;
}

sub ahora {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    $year += 1900;
    $mon  += 1;
    sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour},
      ${min}, ${sec};
}

sub ahora_log {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon  += 1;
    sprintf "%04d%02d%02d%02d%02d%02d", ${year},${mon},${mday},${hour},${min},${sec};
};          # NUEVO

sub encodeCMD {
    my ( $self, $cmd ) = @_;
    #print "\nencodeCMD: $cmd\n";
    my $ret = $self->blow->encrypt($cmd);
    #print "encrypted=[$ret]\n";
    $ret = $self->{mvs} ? $self->{ebc}->toebcdic($ret) : $ret;
    #print "encoded=[$ret]\n";
    return $ret;
}

sub decodeCMD {
    my ( $self, $cmd ) = @_;
    my $ret = $self->blow->decrypt($cmd);
    $self->{mvs} ? $self->{ebc}->toascii($ret) : $ret;
}

sub encodeDATA {
    my ($self, $data ) = @_;
    my $RET = "";
    # convert the data
    $data = $self->{ebc}->toebcdic( $data ) if $self->{mvs};
    # from char to HH uppercase hex codes
    my $ret = join( '', unpack( "H*", $data ) );
    # convert the hex stream
    $self->{mvs} ? $self->{ebc}->toebcdic( $ret ) : $ret;
}

sub _open_socket {
    my ( $rm, $rport ) = @_;
    my $conn;
    my $timeout = $ENV{TIMEOUT_BALIX_OPEN} || 20;
    eval {
        $SIG{ALRM} = sub { die "Timeout de conexion a agente $rm:$rport" };
        alarm $timeout;
        $conn = IO::Socket::INET->new(
            PeerAddr => $rm,
            PeerPort => $rport,
            Proto    => "tcp",
            Type     => SOCK_STREAM
        );
        $conn or die $!;
        alarm 0;    # desactiva
    };
    if ($@) {
        alarm 0;    # desactiva
        croak "Error de conexion a $rm:$rport: $@";
    }
    return $conn;
}

sub open {
    my $class = shift @_;
    my $rm    = shift @_;
    my $rport = shift @_;
    $PARAMS{OS} = shift @_;

    # foreach (keys %PARAMS) {
    #  print "Después -> $_=$PARAMS{$_}\n";
    # }

    my $balix;
    $balix->{RM}    = $rm;
    $balix->{RPORT} = $rport;
    $balix->{blow}  = Crypt::Blowfish::Mod->new( $ENV{BLOWFISH_KEY} );
    my $socket = _open_socket( $rm, $rport )
      or croak
      "Balix: Error: no he podido conectarme a la maquina $rm:$rport : $@\n";

    #select($socket); $| = 1; select(stdout);
    $balix->{socket} = $socket;
    bless( $balix, $class );
}

sub create {
    my $class = shift @_;
    my $rm    = shift @_;
    my $rport = shift @_;
    $PARAMS{OS} = shift @_;

    # foreach (keys %PARAMS) {
    #  print "Después -> $_=$PARAMS{$_}\n";
    # }

    my $balix;
    $balix->{RM}    = $rm;
    $balix->{RPORT} = $rport;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $rm,
        PeerPort => $rport,
        Proto    => "tcp",
        Type     => SOCK_STREAM
    );

#or croak "Balix: Error: no he podido conectarme a la máquina $rm:$rport : $@\n";
#select($socket); $| = 1; select(stdout);
    if ($socket) {
        $socket->autoflush(1);
        binmode $socket;
        $balix->{socket} = $socket;
        $balix->{os}     = $PARAMS{OS};
        bless( $balix, $class );
    }
}

=head2 new

Lo mismo que ->open, pero con ping posterior

    my $balix = Balix->new( host=>'pruxxx', port=>58765, [ os=>'win' , ] [ croak=>1 ] );

Opciones:

 croak=>1 (lanza una excepcion en lugar de retornar un $self vacio)
 
=cut

sub new_old {
    my $class = shift @_;
    my %p     = @_;
    my $self  = $class->open( $p{host}, $p{port}, $p{os} );
    if ($self) {
        my ( $rc, $ret ) = $self->ping('test');
        if ($rc) {
            warn ahora() . " - BALIX ERROR: ping a $p{host}:$p{port} ha fallado\n" if $self->{debug};
            if ( $p{croak} ) {
                croak "Error de conexion al agente en $p{host}:$p{port}";
            }
            else {
                return undef;
            }
        }
    }
    return $self;
}

sub key {
	my ($self,$key) = @_;	
	$self->{key} = $key;
}

sub checkRC {
    my ($self) = @_;
    my ($buf,$ret); 
    my $socket = $self->{socket};
    #warn "READ....";
    #my $ret    = <$socket>;
    sysread $socket, $buf, 1024;
    $buf = $self->{ebc}->toascii( $buf ) if $self->{mvs};
    $ret = $buf;
    #warn "READ OK!!!!!!!!!!!";
    while ( !( $ret =~ /HARAXE=([0-9]*)/ ) ) {
        sysread $socket, $buf, 1024;
        #$ret .= <$socket>;
        $buf = $self->{ebc}->toascii( $buf ) if $self->{mvs};
        $ret .= $buf;
    }
    #warn "FIN READ OK!!!!!!!!!!!";
    my $rc = 0;
    if ( $ret =~ /HARAXE=([0-9]*)/ ) {
        $rc = $1;
        $ret =~ s/[\n]*HARAXE=([0-9]*)//g;
    }
    ( $rc, parseReturn($ret) );
}

sub createDir {
    my ( $self, $dirname ) = @_;
    my $socket = $self->{socket};
    print "BALIX: " . $self->encodeCMD("M $dirname") . "\n\n";
    print $socket $self->encodeCMD("M $dirname") . $self->EOL;
}

sub sendFile {
    my ( $self, $localfile, $rfile ) = @_;

    $rfile = $localfile unless ($rfile);
    if ( !-e $localfile ) {
        croak "sendFile: el fichero '$localfile' no existe.";
    }
    CORE::open FF, "<$localfile"
      or croak
      "sendFile: Error: No he podido abrir el fichero $localfile: $!\n";
    binmode FF;
    my $data = "";
    my $socket = $self->{socket};
    print $socket $self->encodeCMD("F $rfile") . $self->EOL;
    $self->checkRC();

    print $socket $self->encodeCMD("D") . $self->EOL;

    while (<FF>) {
        print $socket $self->encodeDATA($_);
    }
    print $socket $self->EOL;
    close FF;
    my ( $RC, $RET ) = $self->checkRC();
    print $socket $self->encodeCMD("C") . $self->EOL;
    ( $RC, $RET );
}

sub sendFileCheck {
    my ( $self, $localfile, $rfile ) = @_;
	my ($rc,$ret) = $self->sendFile( $localfile, $rfile );
	unless( $rc ) {
		my $comp = $self->crc_match( $localfile, $rfile );
		$rc = 229 if !$comp;
	}
	return ($rc,$ret);
}

sub sendData {
    my ( $self, $data, $rfile ) = @_;

    my $socket = $self->{socket};

    print $socket $self->encodeCMD("F $rfile") . $self->EOL;

    $self->checkRC();

    print $socket $self->encodeCMD("D") . $self->EOL . $self->encodeDATA($data) . $self->EOL;
    my ( $RC, $RET ) = $self->checkRC();

    print $socket $self->encodeCMD("C") . $self->EOL;
    ( $RC, $RET );
}

sub getFile {
    my ( $self, $rfile, $localfile, $os ) = @_;
    my $socket = $self->{socket};
	$os ||= $self->{os};

    if ( $os eq "win" ) {
        $rfile =~ s{\/}{\\}g;      ## subs de las barras palante
        $rfile =~ s{\\\\}{\\}g;    ## normalizo las barras dobles, por si acaso
        print $socket $self->encodeCMD("X dir $rfile") . $self->EOL;
    }
    elsif( $os eq 'mvs' ) {
        print $socket $self->encodeCMD("X /bin/ls $rfile") . $self->EOL;
    }
    else {
        print $socket $self->encodeCMD("X ls $rfile") . $self->EOL;
    }

    my ( $RC, $RET ) = $self->checkRC();
    if ( $RC ne 0 ) {
        chop $RET;
        croak "Error de lectura del fichero '$rfile' en la máquina '$self->{RM}': $RET";
    }

    print $socket $self->encodeCMD("R $rfile") . $self->EOL;
    my $default_blocksize = 128;
    my $blocksize         = $default_blocksize;
    my (
        $file,     $datos,     $block, $filesize,  $header,
        $filename, $bytesread, $char,  $remaining, $jj
    ) = ();
    while ( !$socket->eof() ) {    ##leo el HEADER
        $socket->read( $char, 1 );
        $char = $self->{ebc}->toascii( $char ) if $self->{mvs};
        $header .= $char;
        if ( $header =~ /\$D / ) {
            ( $filename, $filesize, $header ) = split( /\$/, $header );
            $filesize =~ s/^B (.*?)/$1/g;
            $filename =~ s/^F (.*?)/$1/g;
            $remaining = $filesize * 2;
            $remaining--;
            last;
        }
    }
    my @bytes = ();

    if ($localfile) {
        CORE::open FOUT, ">$localfile"
          or croak "Balix: getFile: no he podido abrir el fichero local '$localfile': $@\n";
        binmode FOUT;
    }

    my %hh;
    $hh{ sprintf( '%02x', $_ ) } = chr($_)
      for ( 0 .. 255 );    ##creo tabla de hex->char

    while ( !$socket->eof() ) {    ##LEO LOS DATOS
        $blocksize =
            ( $remaining < $default_blocksize )
          ? ( $remaining + 1 )
          : $default_blocksize;
        $socket->read( $block, $blocksize );
        $block = $self->{ebc}->toascii( $block ) if $self->{mvs};
        $jj += $blocksize;
        $remaining -= $blocksize;

        #print "Y otro ".($jj/1024)." KB (len=".length($file).", remaining=$remaining)\n";

        my $pos = 0;
        $block =~ s/(..)/$hh{$1}/g;
        $block = $self->{ebc}->toascii( $block ) if $self->{mvs};
        if ($localfile) {
            print FOUT $block;
        }
        else {
            $datos .= $block;
        }

        if ( $remaining < 0 ) {    ##hemos acabado
            my $resto;
            $socket->read( $resto, 1 );    #no quiero dejarme el "C"
            last;
        }
    }

    if ($localfile) {
        close FOUT;
        return ( 0, "" );
    }
    else {
        return ( 0, $datos );
    }
}

sub execute {
    my ( $self, $rcmd ) = @_;
    my $socket = $self->{socket};
    #print join',', map { ord } split //, $self->encodeCMD("X $rcmd") . $self->EOL;
    print $socket $self->encodeCMD("X $rcmd") . $self->EOL;
    #warn "RET!!!!";
    $self->checkRC();
}

sub executeas {
####IMPRESCINDIBLE QUE BALIX SE EJECUTE COMO ROOT.  SI NO, PIDE PASSWORD.
    my ( $self, $user, $rcmd ) = @_;
    if ( $user eq "" ) {
        return ( 99,
            "ERROR DE BALIX: usuario de ejecucion remota esta en blanco!" );
    }
    my $socket = $self->{socket};
    ## con el su -c hace falta escapar las comillas
    $rcmd =~ s/\"/\\\"/g;
    print $socket $self->encodeCMD(qq{X su - $user -c "$rcmd"}) . $self->EOL;

    $self->checkRC();
}

sub end {
    my ($self) = @_;
    my $socket = $self->{socket};
    print $socket $self->encodeCMD("Q") . $self->EOL;
    close($socket) if ($socket);
}

sub DESTROY {
    my ($self) = @_;
    $self->end();
}

sub parseReturn {
    my $RET = shift @_;
    $RET =~ s/who\:.0551.*shell//s;
    $RET;
}

# returns the crc, or 0 if failed
sub crc {
	my ($self, $file ) = @_;
    my $socket = $self->{socket};
    print $socket $self->encodeCMD("Y $file") . $self->EOL;
	my ($crc, $ret ) = $self->checkRC();
	return $crc;
}

sub crc_local {
	my ($self, $file ) = @_;
	CORE::open( my $F,'<', $file ) or die $!;
	my $crc = String::CRC32::crc32( $F ) or die $!;
	close $F;
	return $crc;
}

# returns 1 if equal, 0 if different
sub crc_match {
	my ($self, $local, $remote ) = @_;
	my $crc_local = $self->crc_local( $local );
	my $crc_remote = $self->crc( $remote );
	return $crc_local eq $crc_remote;
}

sub EOL {
    my $self = shift;
    return $self->{mvs} ? $self->{ebc}->toebcdic( "\n" ) : "\n";
}

sub ping_new {
    my ( $self, $hostname ) = @_;
    my $socket = $self->{socket};
    my $rcmd   = 'set';
    print $socket $self->encodeCMD("X $rcmd") . $self->EOL;

    $self->checkRC();
}

sub ping {
    my ( $self, $hostname ) = @_;
    my $socket = $self->{socket};
    my $cmd    = $self->encodeCMD("X  echo $hostname") . $self->EOL;
    my $buffer;
    my $RC  = 0;
    my $RET = "";
    my $bytesRead;
    print $socket $cmd;

    read( $socket, $buffer, 1 );
    my $byte = substr( $buffer, 0, 1 );
    if ( $byte ne substr( $hostname, 0, 1 ) ) {
        $RET =
"El servidor no responde correctamente.  Verifique la versión de balix instalada";
        $RC = 1;
    }

    # hack para que no se quede bloqueado el socket
    close($socket);
    $self->{socket} = _open_socket( $self->{RM}, $self->{RPORT} );
    return ( $RC, $RET );
}

# usuario de ejecucion del Distribuidor para un entorno
# uso: my $usuario = scm_usuario('TEST');  
# devuelve 'vtscm'
sub scm_usuario {
	use strict;

    my $entorno = @_;

    #XXX DELME XXX
    my $usuario;
    #XXX DELME XXX

    # entorno_usuario??????
    #FIXME my $usuario = $entorno_usuario{$entorno}
    #FIXME     or die "scm_usuario: error: no tengo mapeado un usuario para el entorno '$entorno'";

	return $usuario;
}


1;

