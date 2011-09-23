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
    warn ahora()
      . " - BALIX: conectando a $p{host}:$p{port} (timeout=$p{timeout})\n";
	$balix->{os}     = $p{os};
    $balix->{blow}   = Crypt::Blowfish::Mod->new( $p{key} );
    $balix->{socket} = IO::Socket::INET->new(
        PeerAddr => $p{host},
        PeerPort => $p{port},
        Proto    => "tcp",
        Type     => SOCK_STREAM
    ) or die "Error al abrir el socket: $!";
    if ( ref $balix->{socket} ) {
        warn ahora() . " - BALIX: conectado a $p{host}:$p{port}\n";
    }
    else {
        warn ahora()
          . " - BALIX: ERROR: no se ha podido conectar a $p{host}:$p{port}\n";
        return undef;
    }
    $balix = bless( $balix, $class );
    eval {
        warn ahora()
          . " - BALIX: inicio ping con timeout a $p{host}:$p{port}\n";
        local $SIG{ALRM} = sub {
            die "Timeout $p{timeout} seg while connection to agent $p{host}:$p{port}.\n";
        };
        if ( $p{timeout} ne -1 ) {
            alarm $p{timeout};
        }
        my ( $rc, $ret ) = $balix->execute("set");
		if( $ret =~ m/OS=(Win.*)$/i ) {
			print "OS detectado: $1\n";
		}
        warn ahora()
          . " - BALIX: fin ping ok (rc=$rc) con timeout a $p{host}:$p{port}\n";
        alarm 0;
    };
	
    if ($@) {
        croak "Error while connecting to agent: $@";
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
    #print "\nRET=[$ret]\n";
    $ret;
}

sub decodeCMD {
    my ( $self, $cmd ) = @_;
    return $self->blow->decrypt($cmd);
}

sub encodeDATA {
    my $RET = "";
    my ($data) = @_;
    join( '', unpack( "H*", $data ) );
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
      "Balix: Error: no he podido conectarme a la máquina $rm:$rport : $@\n";

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

 croak=>1 (lanza una excepción en lugar de retornar un $self vacio)
 
=cut

sub new_old {
    my $class = shift @_;
    my %p     = @_;
    my $self  = $class->open( $p{host}, $p{port}, $p{os} );
    if ($self) {
        my ( $rc, $ret ) = $self->ping('test');
        if ($rc) {
            warn ahora()
              . " - BALIX ERROR: ping a $p{host}:$p{port} ha fallado\n";
            if ( $p{croak} ) {
                croak "Error de conexión al agente en $p{host}:$p{port}";
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
    my ($balix) = @_;

    my $socket = $balix->{socket};
    my $ret    = <$socket>;

    while ( !( $ret =~ /HARAXE=([0-9]*)/ ) ) {
        $ret .= <$socket>;
    }
    my $rc = 0;
    if ( $ret =~ /HARAXE=([0-9]*)/ ) {
        $rc = $1;
        $ret =~ s/[\n]*HARAXE=([0-9]*)//g;
    }
    ( $rc, parseReturn($ret) );
}

sub createDir {
    my ( $balix, $dirname ) = @_;
    my $socket = $balix->{socket};
    print "BALIX: " . $balix->encodeCMD("M $dirname") . "\n\n";
    print $socket $balix->encodeCMD("M $dirname") . "\n";
}

sub sendFile {
    my ( $balix, $localfile, $rfile ) = @_;

    $rfile = $localfile unless ($rfile);
    if ( !-e $localfile ) {
        croak "sendFile: el fichero '$localfile' no existe.";
    }
    CORE::open FF, "<$localfile"
      or croak
      "sendFile: Error: No he podido abrir el fichero $localfile: $!\n";
    binmode FF;
    my $data = "";
    my $socket = $balix->{socket};
    print $socket $balix->encodeCMD("F $rfile") . "\n";
    $balix->checkRC();

    print $socket $balix->encodeCMD("D") . "\n";

    while (<FF>) {
        print $socket encodeDATA($_);
    }
    print $socket "\n";
    close FF;
    my ( $RC, $RET ) = $balix->checkRC();
    print $socket $balix->encodeCMD("C") . "\n";
    ( $RC, $RET );
}

sub sendFileCheck {
    my ( $balix, $localfile, $rfile ) = @_;
	my ($rc,$ret) = $balix->sendFile( $localfile, $rfile );
	unless( $rc ) {
		my $comp = $balix->crc_match( $localfile, $rfile );
		$rc = 229 if !$comp;
	}
	return ($rc,$ret);
}

sub sendData {
    my ( $balix, $data, $rfile ) = @_;

    my $socket = $balix->{socket};

    print $socket $balix->encodeCMD("F $rfile") . "\n";

    $balix->checkRC();

    print $socket $balix->encodeCMD("D") . "\n" . encodeDATA($data) . "\n";
    my ( $RC, $RET ) = $balix->checkRC();

    print $socket $balix->encodeCMD("C") . "\n";
    ( $RC, $RET );
}

sub getFile {
    my ( $balix, $rfile, $localfile, $os ) = @_;
    my $socket = $balix->{socket};
	$os ||= $balix->{os};

    if ( $os eq "win" ) {
        $rfile =~ s{\/}{\\}g;      ## subs de las barras palante
        $rfile =~ s{\\\\}{\\}g;    ## normalizo las barras dobles, por si acaso
        print $socket $balix->encodeCMD("X dir $rfile") . "\n";
    }
    else {
        print $socket $balix->encodeCMD("X ls $rfile") . "\n";
    }

    my ( $RC, $RET ) = $balix->checkRC();
    if ( $RC ne 0 ) {
        chop $RET;
        croak
"Error de lectura del fichero '$rfile' en la máquina '$balix->{RM}': $RET";
    }

    print $socket $balix->encodeCMD("R $rfile") . "\n";
    my $default_blocksize = 128;
    my $blocksize         = $default_blocksize;
    my (
        $file,     $datos,     $block, $filesize,  $header,
        $filename, $bytesread, $char,  $remaining, $jj
    ) = ();
    while ( !$socket->eof() ) {    ##leo el HEADER
        $socket->read( $char, 1 );
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
          or croak
"Balix: getFile: no he podido abrir el fichero local '$localfile': $@\n";
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
        $jj += $blocksize;
        $remaining -= $blocksize;

#print "Y otro ".($jj/1024)." KB (len=".length($file).", remaining=$remaining)\n";

        my $pos = 0;
        $block =~ s/(..)/$hh{$1}/g;
        if ($localfile) {
            print FOUT $block;
        }
        else {
            $datos .= $block;
        }

        if ( $remaining < 0 ) {    ##hemos acabado
            my $resto;
            $socket->read( $resto, 1 );    #no quiero dejar el "C"
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
    my ( $balix, $rcmd ) = @_;

    my $socket = $balix->{socket};
    print $socket $balix->encodeCMD("X $rcmd") . "\n";

    $balix->checkRC();
}

sub executeas {
####IMPRESCINDIBLE QUE BALIX SE EJECUTE COMO ROOT.  SI NO, PIDE PASSWORD.
    my ( $balix, $user, $rcmd ) = @_;
    if ( $user eq "" ) {
        return ( 99,
            "ERROR DE BALIX: usuario de ejecución remota está en blanco!" );
    }
    my $socket = $balix->{socket};
    ## con el su -c hace falta escapar las comillas
    $rcmd =~ s/\"/\\\"/g;
    print $socket $balix->encodeCMD(qq{X su - $user -c "$rcmd"}) . "\n";

    $balix->checkRC();
}

sub end {
    my ($balix) = @_;
    my $socket = $balix->{socket};
    print $socket $balix->encodeCMD("Q") . "\n";
    close($socket) if ($socket);
}

sub DESTROY {
    my ($balix) = @_;
    $balix->end();
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
    print $socket $self->encodeCMD("Y $file") . "\n";
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

sub ping_new {
    my ( $balix, $hostname ) = @_;
    my $socket = $balix->{socket};
    my $rcmd   = 'set';
    print $socket $balix->encodeCMD("X $rcmd") . "\n";

    $balix->checkRC();
}

sub ping {
    my ( $balix, $hostname ) = @_;
    my $socket = $balix->{socket};
    my $cmd    = $balix->encodeCMD("X  echo $hostname") . "\n";
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
    $balix->{socket} = _open_socket( $balix->{RM}, $balix->{RPORT} );
    return ( $RC, $RET );
}

1;

