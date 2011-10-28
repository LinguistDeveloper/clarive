=head1 NAME

BaselinerX::Comm::Balix - Baseliner Agent Client Library

=head1 SYNOPSIS

    my $balix = Balix->new( host=>'pruxxx', port=>58765, key=>'...base64_key...' [ os=>'win' , ] [timeout=>99 ] );
      timeout de -1 desactiva el timeout

    my $balix = Baseliner::Comm::Balix->new( host=>'pruxxx', port=>58765, key=>'...base64_key...' [ os=>'win' , ] [timeout=>99 ] );
      timeout de -1 desactiva el timeout

=cut
package BaselinerX::Comm::Balix;
use strict;
use warnings;
use IO::Socket;
use Carp;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Time::HiRes qw/gettimeofday tv_interval/;
use Crypt::Blowfish::Mod;
use String::CRC32;

@ISA     = qw();
@EXPORT  = qw();
$VERSION = '1.0';

sub blow { shift->{blow}; }
sub os { shift->{os} }

=head2 new

The same as ->open, but with a ping + timeout.

    my $balix = Balix->new( host=>'pruxxx', port=>58765, [ os=>'win' , ] [ croak=>1 ] );

Options:

     croak=>1 (throws an exception instead of returning)

Do not use this with threads. A timeout throws an interpreter alarm.  

=cut
sub new {
    my $class = shift @_;
    my %p     = @_;
    $p{timeout} ||= $ENV{BALIX_TIMEOUT} || 10;
    my $self = { %p };
    $self->{debug}  = $p{debug} || 0;
    $self->{os}     = $p{os} || '';
    $self->{blow}   = Crypt::Blowfish::Mod->new( $p{key} );
    warn ts() . " - BALIX: connecting to $p{host}:$p{port} (timeout=$p{timeout})\n" if $self->{debug};
    $self->{socket} = IO::Socket::INET->new(
        PeerAddr => $p{host},
        PeerPort => $p{port},
        Proto    => "tcp",
        Type     => SOCK_STREAM
    ) or die "BALIX: Error opening socket: $!";
    if( $self->{verbose} ) {
        require Term::ReadKey;
    }
    if( $self->{os} eq 'mvs' ) {
        $self->{mvs} = 1;
        require Convert::EBCDIC;
        $self->{ebc} = Convert::EBCDIC->new($Convert::EBCDIC::ccsid1047);
        binmode $self->{socket};
        #$self->{ebc} = Convert::EBCDIC->new($Convert::EBCDIC::ccsid819);
    }
    if ( ref $self->{socket} ) {
        warn ts() . " - BALIX: connected to $p{host}:$p{port}\n" if $self->{debug};
    }
    else {
        warn ts() . " - BALIX: ERROR: could not connect to $p{host}:$p{port}\n" if $self->{debug};
        return undef;
    }
    $self = bless( $self, $class );
    unless( $self->{mvs} ) {
        eval {
            warn ts() . " - BALIX: ping started with timeout to $p{host}:$p{port}\n" if $self->{debug};
            local $SIG{ALRM} = sub {
                die "BALIX: Timeout. Max response time exceeded ($p{timeout} sec) while connecting to $p{host}:$p{port}.\n";
            };
            if ( $p{timeout} ne -1 ) {
                alarm $p{timeout};
            }
            my ( $rc, $ret ) = $self->execute("set");
            if( $ret =~ m/OS=(Win.*)$/i ) {
                print "BALIX OS detected: $1\n";
            }
            warn ts() . " - BALIX: end ping ok (rc=$rc) con timeout a $p{host}:$p{port}\n" if $self->{debug};
            alarm 0;
        };
        
        if ($@) {
            croak "Error on agent connection: $@";
        }
    }
    return $self;
}

sub ts {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    $year += 1900;
    $mon  += 1;
    sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour},
      ${min}, ${sec};
}

*ahora = \&ts;

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
        $SIG{ALRM} = sub { die "Timeout (${timeout} s) while connecting to agent $rm:$rport" };
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
        croak "Error connecting to $rm:$rport: $@";
    }
    return $conn;
}

sub open {
    my $class = shift @_;
    my $rm    = shift @_;
    my $rport = shift @_;
    my $os = shift @_;

    my $self;
    $self->{RM}    = $rm;
    $self->{RPORT} = $rport;
    $self->{blow}  = Crypt::Blowfish::Mod->new( $ENV{BLOWFISH_KEY} );
    my $socket = _open_socket( $rm, $rport )
      or croak
      "Balix: Error: connection to $rm:$rport failed: $@\n";

    #select($socket); $| = 1; select(stdout);
    $self->{socket} = $socket;
    bless( $self, $class );
}

sub create {
    my $class = shift @_;
    my $rm    = shift @_;
    my $rport = shift @_;
    my $os = shift @_;

    my $self;
    $self->{RM}    = $rm;
    $self->{RPORT} = $rport;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $rm,
        PeerPort => $rport,
        Proto    => "tcp",
        Type     => SOCK_STREAM
    );

    if ($socket) {
        $socket->autoflush(1);
        binmode $socket;
        $self->{socket} = $socket;
        $self->{os}     = $os;
        bless( $self, $class );
    }
}

sub key {
    my ($self,$key) = @_;   
    $self->{key} = $key;
}

sub checkRC {
    use Baseliner::Utils; # XXX
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
    my $ret_parsed = parseReturn($ret);
    return wantarray
        ? ( $rc, $ret_parsed )
        : { rc=>$rc, ret=>$ret_parsed };
}

sub createDir {
    my ( $self, $dirname ) = @_;
    my $socket = $self->{socket};
    print "BALIX: " . $self->encodeCMD("M $dirname") . "\n\n";
    print $socket $self->encodeCMD("M $dirname") . $self->EOL;
}

*send_file = \&sendFile;
sub sendFile {
    my ( $self, $localfile, $rfile ) = @_;

    $rfile = $localfile unless ($rfile);
    if ( !-e $localfile ) {
        croak "sendFile: the local file '$localfile' doesn't exist";
    }
    my $fin; 
    CORE::open $fin, "<$localfile"
      or croak
      "sendFile: Error: could not open local file $localfile: $!\n";
    binmode $fin;
    my $data = "";
    my $socket = $self->{socket};
    print $socket $self->encodeCMD("F $rfile") . $self->EOL;
    $self->checkRC();

    print $socket $self->encodeCMD("D") . $self->EOL;

    while (<$fin>) {
        print $socket $self->encodeDATA($_);
    }
    print $socket $self->EOL;
    close $fin;
    my ( $RC, $RET ) = $self->checkRC();
    print $socket $self->encodeCMD("C") . $self->EOL;
    ( $RC, $RET );
}

*send_file_check = \&sendFileCheck;
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
    elsif( $self->{mvs} ) {
        print $socket $self->encodeCMD("X /bin/ls $rfile") . $self->EOL;
    }
    else {
        print $socket $self->encodeCMD("X ls $rfile") . $self->EOL;
    }

    my ( $RC, $RET ) = $self->checkRC();
    if ( $RC ne 0 ) {
        chop $RET;
        croak "Error reading file '$rfile' from '$self->{RM}': $RET";
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

        my $fout;
    if ($localfile) {
        CORE::open $fout, ">$localfile"
          or croak "Balix: getFile: no he podido abrir el fichero local '$localfile': $@\n";
        binmode $fout;
    }

        # status bar prepare
        my $show_status = $self->{verbose};
        my ( $start, $totalsize, $fan, $width );

        if( $show_status ) {
                $start = [ gettimeofday() ];
                ($width) = Term::ReadKey::GetTerminalSize();
                $totalsize = $filesize * 2;
                $width-=20;
                $fan = '/';
    }

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
        $block = pack 'H*', $block;
        $block = $self->{ebc}->toascii( $block ) if $self->{mvs};
        if ($localfile) {
            print $fout $block;
        }
        else {
            $datos .= $block;
        }

        # status bar
        if ( $show_status && $width ) {
            unless ( $jj % 1048576 ) {
                my $pct   = int( ( $jj / $totalsize ) * $width );
                my $fil   = '=' x $pct;
                my $spa   = ' ' x ( $width - $pct - 1 );
                my $inter = tv_interval($start);
                $fan = $fan eq '/' ? '\\' : '/';
                print "\r[Speed " . int( $jj / $inter / 1024 ) . " KB/s $fil>$spa]$fan";
            }
        }

        if ( $remaining < 0 ) {    ##hemos acabado
            my $resto;
            $socket->read( $resto, 1 );    #no quiero dejarme el "C"
            last;
        }
    }

    if ($localfile) {
        close $fout;
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
    $self->checkRC();
}


=head2 execute_as

Executes a command as a sudo user.

Does not work on Windows - but will try it anyway.

=cut
*executeas = \&execute_as;
sub execute_as {
    my ( $self, $user, $rcmd ) = @_;
    if ( $user eq "" ) {
        return ( 99,
            "BALIX ERROR: empty remote user!" );
    }
    my $socket = $self->{socket};
    ## con el su -c hace falta escapar las comillas
    $rcmd =~ s/\"/\\\"/g;
    print $socket $self->encodeCMD(qq{X su - $user -c "$rcmd"}) . $self->EOL;
    $self->checkRC();
}

*close = \&end;
sub end {
    my ($self) = @_;
    my $socket = $self->{socket};
    no warnings; # print() on closed filehandle GEN0 
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
        $RET = "Incorrect response from Balix Agent. Please check installed version.";
        $RC = 1;
    }

    # hack para que no se quede bloqueado el socket
    close($socket);
    $self->{socket} = _open_socket( $self->{RM}, $self->{RPORT} );
    return ( $RC, $RET );
}

sub ping_timeout {
        my ($self) = @_;
        return unless $self->{timeout};
    eval {
        warn ts() . " - BALIX: ping started with timeout to $self->{host}:$self->{port}\n";
        local $SIG{ALRM} = sub {
            die "Timeout. Se ha sobrapasado el tiempo fijado ($self->{timeout} seg) para la conexión por agente a $self->{host}:$self->{port}.\n";
        };
        if ( $self->{timeout} ne -1 ) {
            alarm $self->{timeout};
        }
                my $os = $self->find_os_name;
        warn ts() . " - BALIX: end ping ok (os=$self->{os}) con timeout a $self->{host}:$self->{port}\n";
        alarm 0;
    };
        croak "BALIX: Error while connecting to agent: " . $@ if ($@);
}

sub find_os_name {
        my ($self)  = @_;
        my @a = $self->execute('echo %OS%'); # catch a windows os
        if( $a[1] =~ m/\%OS%/ ) {
                @a = $self->execute('uname -s'); # tipical unix
        }
        $self->{os} = $a[1];
        $self->{os} =~ s{\n|\r|\t}{}g;
        return $self->{os};
}

sub is_windows {
        my ($self, $force)  = @_;
        return $self->os =~ /win/i
                if !$force && defined $self->os;
        my @a = $self->execute('echo %OS%');
        my $os = $self->find_os_name;
                # alternative implementation
        #my ( $rc, $ret ) = $self->execute("set");
                #if( $ret =~ m/OS=(Win.*)$/i ) {
                #       print "OS detectado: $1\n";
                #}
        return $os =~ /win/i;
}

sub file_exists {
        my ($self, $path, $user )  = @_;
        my ( $RC, $RET );
        my $cmd = $self->is_windows ? 'dir' : 'ls';
        if( $user ) {
                ( $RC, $RET ) = $self->executeas( $user, qq{ $cmd '$path' } );
        } else {
                ( $RC, $RET ) = $self->execute( qq{ $cmd '$path' } );
        }
        return ! $RC;
}


1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 The Authors of Baseliner.org. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
