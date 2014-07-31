package BaselinerX::CI::balix_agent;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _file _dir);
use v5.10;

has chunk_size     => qw(is rw lazy 1), default => sub{ 1024 * 1024 }; # 1M
has wait_frequency => qw(is rw default 5);

has user   => qw(is rw isa Str);
has key    => qw(is rw isa Str), default=>sub{
    return  Baseliner->model('ConfigStore')->get('balix_key', value=>1) 
        || 'TGtkaGZrYWpkaGxma2psS0tKT0tIT0l1a2xrbGRmai5kLC4yLjlka2ozdTQ4N29sa2hqZGtzZmhr';  
};
has port   => qw(is rw isa Num), default=>sub{
    return  Baseliner->model('ConfigStore')->get('balix_port', value=>1) 
        || 11800;
};
has _blow   => qw(is rw isa Any lazy 1), default => sub {
    my $self = shift;
    require Crypt::Blowfish::Mod;
    return Crypt::Blowfish::Mod->new( $self->key );
};
has _socket  => qw(is rw isa Any lazy 1), default => sub {
    my $self = shift;
    require IO::Socket;
    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->hostname,
        PeerPort => $self->port,
        Proto    => "tcp",
        Type     => IO::Socket->SOCK_STREAM
    ) ;
    _fail( _loc("balix: Error opening socket (host=%1, port=%2): %3", $self->hostname, $self->port, $!) ) unless $sock;
    return $sock;
};
sub socket { $_[0]->_socket };

has _ebc    => qw(is rw isa Any lazy 1), default=>sub{
    my $self = shift;
    require Convert::EBCDIC;
    return Convert::EBCDIC->new($Convert::EBCDIC::ccsid1047);
};

with 'Baseliner::Role::CI::Agent';

# MVS configuration and EBCDIC converter
has mvs    => qw(is rw isa Bool), default => sub {
    my ($self) = @_;
    return $self->os eq 'mvs';
};

sub error;
sub rmpath;

sub BUILD {
   my $self = shift;
   $self->os ($self->server->os);
};



method mkpath ( $path ) {
    if ( $self->is_win ) {
        $self->execute( \'md', $path );
        #$self->execute( \'cacls', $path, \'/e /c /g', $self->user ) if $self->user;
    } else {
        $self->execute( \'mkdir', \'-p', $path );
        $self->execute( 'chown', $self->user, $path ) if $self->user;
    }
    $self->rc and _fail _loc( "Could not create remote directory '%1': %2", $path, $self->output );
}

method chmod ( $mode, $path ) {
    if ( $self->is_win ) {
        $self->execute( \'attrib', \'/D', \$mode, $path ) if $self->user;
    } else {
        $self->execute( \'chmod', \$mode, $path );
    }
    $self->rc and _fail _loc( "Could not chmod '%1 %2': %3", $mode, $path, $self->output );
}

method chown ( $perms, $path ) {
    if ( $self->is_win ) {
        $self->execute( 'cacls', $path, '/e /c /g', $self->user ) if $self->user;
    } else {
        $self->execute( \'chown', \$perms, $path );
    }
    $self->rc and _fail _loc( "Could not chown '%1 %2': %3", $perms, $path, $self->output );
}

method execute( @cmd ) {
    my $tmout = $self->timeout;
    alarm $tmout if $tmout; 
    local $SIG{ALRM} = sub { _fail _loc 'balix agent error: timeout during execute (tmout=%1 sec)', $tmout } if $tmout;
    my $opts = shift @cmd if ref $cmd[0] eq 'HASH';
    if( $opts->{chdir} ) {
       @cmd = ( \'cd', $opts->{chdir}, \'&&', @cmd == 1 ? \$cmd[0] : @cmd );      
    }
    if( (my $user = $self->user) && !$self->is_win ) {
        @cmd = @cmd == 1 ? $cmd[0] : $self->_double_quote_cmd( @cmd ); # join params quoted 
        @cmd = (\'su', \'-', $user, \'-l', \'-c', "@cmd");
    }
    #_debug \@cmd;
    my $res = $self->_execute( @cmd );
    alarm 0;
    return $self->ret;
}

method put_dir( :$local, :$remote, :$group='', :$files=undef, :$user=$self->user  ) {
    my $tarfile = Util->_tmp_file( prefix=>'balix-put-dir', extension=>'tar' );
    my $tarfile_remote = _dir( $remote, _file( $tarfile)->basename );
    $self->mkpath( $remote );
    Util->tar_dir( source_dir=>$local, tarfile=>$tarfile, files=>$files ); 
    $self->put_file( local=>$tarfile, remote=>"$tarfile_remote" );
    $self->execute( \"cd '$remote' && ", \'tar', \'xvf', $tarfile_remote );
    $self->execute( rm => $tarfile_remote );
    unlink "$tarfile" if -e $tarfile;
    return $self->tuple;  
}

method get_dir( :$local, :$remote, :$group='', :$files=undef, :$user=$self->user  ) {
    my $tarfile = Util->_tmp_file( prefix=>'balix_get_dir', extension=>'tar' );
    my $tarfile_remote = _dir( $remote, _file( $tarfile)->basename );
    $self->execute( \"cd '$remote' && ", \'tar', \'cvf', $tarfile_remote, \'*' );
    Util->_mkpath( $local ) unless -d $local;
    _fail _loc("Could not find local directory to '%1'", $local) unless -d $local;
    $self->get_file( local=>$tarfile, remote=>"$tarfile_remote" );
    $self->execute( rm => $tarfile_remote );
    my $orig = Cwd::cwd;
    chdir $local;
    require Capture::Tiny;
    my ($out) = Capture::Tiny::capture_merged( sub { system 'tar', 'xvf', $tarfile });
    chdir $orig;
    $self->output( $out ),
    unlink "$tarfile" if -e $tarfile;
    return $self->tuple;  
}

method is_remote_dir( $dir ) {
    if( $self->is_win ) {
        my ($rc,$ret) = $self->_execute( \'PUSHD', $dir );
        return !$rc
    } else {
        my ($rc,$ret) = $self->_execute( 'test', '-d', $dir );
        return !$rc;
    }
}

method file_exists( $file_or_dir ) {
    my ($rc,$ret);
    if( $self->is_win ) {
        my ($rc,$ret) = $self->_execute( \'if', \'exist', $file_or_dir, \'echo', \'CLAX_EXIST');
        return !!( $ret =~ /CLAX_EXIST/s );
    } else {
        my ($rc,$ret) = $self->_execute( 'test', '-r', $file_or_dir ); # check it exists
        return !$rc; 
    }
}

method check_writeable( $file_or_dir ) {
    if( $self->is_win ) {
        # apparently, the only way to check is actually writing to it, so go ahead
        #  although this VBscript could do it: cscript //nologo check.vbs myfile
        #    Set objFS=CreateObject("Scripting.FileSystemObject")
        #    Set objArgs = WScript.Arguments
        #    strFile = objArgs(0)
        #    Set objFile = objFS.GetFile(strFile)
        #    If Not objFile.Attributes And 1 Then
        #       WScript.Echo "The file is Read/Write."
        #    Else
        #       WScript.Echo "The file is Read-only."
        #    End If
        return 0;  # this is backwards... use is_writeable
    } else {
        my ($rc,$ret) = $self->_execute( 'test', '-r', $file_or_dir ); # check it exists
        return (0,'') if $rc; # doesnt exist, it's writeable
        return $self->_execute( 'test', '-w', $file_or_dir ); # now check it's writeable
    }
}

method is_writeable( $file_or_dir ) {
    my ($rc,$ret) = $self->check_writeable( $file_or_dir );
    return 1 if !$rc;
}

# TODO data parameter support
method put_file( :$local, :$remote, :$group='', :$user=$self->user  ) {
    $remote = $self->normalize_path( $remote );
    # check if remote dir exists and is writeable
    if( my $remote_dir = ''. _file($remote)->dir ) {
        # exists?
        my $dir_exists = $self->file_exists( $remote_dir );
        _fail _loc("balix: can't send file: could not find remote dir `%1` (dir_exists: %2)", $remote_dir, $dir_exists)
            if !$dir_exists;
        # writeable?
        my $is_writeable = $self->is_writeable($remote_dir);
        _fail _loc("balix: can't send file: remote dir is not writeable '%1'", $remote_dir)
            if !$is_writeable;
    } else {
        _fail _loc("balix: can't send file: missing remote dir in '%1'", $remote);
    }
    # check file writeable
    my ($rc,$ret) = $self->check_writeable($remote);
    _fail _loc("balix: cannot send file: file not writeable `%1` (rc: %2)", $remote, $rc) if $rc;
    # check we are not trying to write a directory 
    my $is_dir = $self->is_remote_dir($remote);
    _fail _loc("balix: cannot send file: destination is a directory `%1`", $remote) if $is_dir;
    # send
    $self->_send_file( $local, $remote );
    if( $user ) {
        $self->_execute( 'chown', "${user}:${group}", $remote );
    }
    $self->_crc_match( $local, $remote )  
        or Util->_fail( Util->_loc("Failed CRC check for remote file '%1'", $remote ) );
    return $self->tuple;  
}

method get_file( :$local, :$remote, :$group='', :$user=$self->user  ) {
    $remote = $self->normalize_path( $remote );
    $self->_get_file( $remote, $local );
    return $self->tuple;  
}

method remote_eval( $code ) {
    my $id = Util->_nowstamp . "_$$";
    my $filepath = _file( $self->remote_temp, 'balix_remote_eval_' . $id . '.dump' );
    my $fpcode = $self->fatpack_perl_code( qq{
        use Storable;
        my \@ret = (do {
            $code 
        });
        open my \$ff, ">$filepath" or die "Could not open output file `$filepath`: \$!";
        binmode \$ff;
        print \$ff Storable::freeze([\@ret]);
        close \$ff; 
    });
    my $tmp_remote = _file( $self->remote_temp, 'balix_remote_eval_' . $id . ".pl" );
    $self->put_data( data=>$fpcode, remote=>$tmp_remote ); 
    $self->execute( $self->remote_perl, $tmp_remote );
    $self->execute( \'rm', $tmp_remote );
    my $dump = $self->get_data( remote=>$filepath );
    $self->execute( \'rm', $filepath );
    $dump = Storable::thaw( $dump );
}

method put_data( :$data, :$remote, :$group='', :$user=$self->user  ) {
    $self->_send_data( $data, $remote );
    if( $user ) {
        $self->_execute( 'chown', "${user}:${group}", $remote );
    }
}

method get_data( :$remote ) {
    return $self->_get_file( $remote );
}

####### private

sub _send_file {
    my ( $self, $local, $remote ) = @_;

    $remote = $local unless ($remote);
    Util->_fail( "balix: the local file '$local' doesn't exist" ) unless -e $local;
    CORE::open my $fin, "<$local"
      or Util->_fail( "balix: Error: could not open local file $local $!\n" );
    binmode $fin;
    my $data = "";
    $self->socket->print( $self->encodeCMD("F $remote") . $self->EOL );
    $self->_checkRC();

    $self->socket->print( $self->encodeCMD("D") . $self->EOL );

    my $chunk;
    _fail _loc 'Chunk size is zero for agent %1', $self->name unless $self->chunk_size;
    while( sysread $fin, $chunk, $self->chunk_size ) {
        $self->socket->print( $self->encodeDATA($chunk) );
    }
    $self->socket->print( $self->EOL );
    close $fin;
    my ( $RC, $RET ) = $self->_checkRC();
    $self->socket->print( $self->encodeCMD("C") . $self->EOL );
    ( $RC, $RET );
}

sub _send_file_check {
    my ( $self, $local, $remote ) = @_;
    my ($rc,$ret) = $self->_send_file( $local, $remote );
    unless( $rc ) {
        my $comp = $self->_crc_match( $local, $remote );
        $rc = 229 if !$comp;
    }
    return ($rc,$ret);
}

sub _send_data {
    my ( $self, $data, $rfile ) = @_;

    my $socket = $self->socket;
    $socket->print( $self->encodeCMD("F $rfile") . $self->EOL );
    
    $self->_checkRC();

    $socket->print( $self->encodeCMD("D") . $self->EOL . $self->encodeDATA($data) . $self->EOL );

    my ( $RC, $RET ) = $self->_checkRC();
    $socket->print( $self->encodeCMD("C") . $self->EOL );

    ( $RC, $RET );
}

sub _get_data {
    my ( $self, $rfile ) = @_;
    return $self->_get_file( $rfile );
}

sub _get_file {
    my ( $self, $remote, $local ) = @_;
    my $socket = $self->socket;

    if ( $self->is_win ) {
        $remote =~ s{\/}{\\}g;      ## subs de las barras palante
        $remote =~ s{\\\\}{\\}g;    ## normalizo las barras dobles, por si acaso
        $socket->print( $self->encodeCMD("X dir $remote") . $self->EOL );
    }
    elsif( $self->mvs ) {
        $socket->print( $self->encodeCMD("X /bin/ls $remote") . $self->EOL );
    }
    else {
        $socket->print( $self->encodeCMD("X ls $remote") . $self->EOL );
    }

    my ( $RC, $RET ) = $self->_checkRC();
    if ( $RC ne 0 ) {
        chop $RET;
        Util->_fail( Util->_loc( "Error reading file '%1' from '%2': %3", $remote, $self->hostname, $RET ) );
    }

    $socket->print( $self->encodeCMD("R $remote") . $self->EOL );
    my $default_blocksize = 128;
    my $blocksize         = $default_blocksize;
    my (
        $file,     $datos,     $block, $filesize,  $header,
        $filename, $bytesread, $char,  $remaining, $jj
    ) = ();
    while ( !$socket->eof() ) {    ##leo el HEADER
        $socket->read( $char, 1 );
        $char = $self->_ebc->toascii( $char ) if $self->mvs;
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
    if ($local) {
        CORE::open $fout, ">$local"
          or Util->_fail( Util->_loc( "Balix: get_file: could not open local file '%1': %2", $local, $@ ) );
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
        $block = $self->_ebc->toascii( $block ) if $self->mvs;
        $jj += $blocksize;
        $remaining -= $blocksize;

        #print "Y otro ".($jj/1024)." KB (len=".length($file).", remaining=$remaining)\n";

        my $pos = 0;
        $block = pack 'H*', $block;
        $block = $self->_ebc->toascii( $block ) if $self->mvs;
        if ($local) {
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

    if ($local) {
        close $fout;
        return ( 0, "" );
    }
    else {
        return ( 0, $datos );
    }
}

sub _crc {
    my ($self, $file ) = @_;
    $self->socket->print( $self->encodeCMD("Y $file") . $self->EOL );
    my ($crc, $ret ) = $self->_checkRC(1);
    return $crc;
}

sub _crc_local {
    my ($self, $file ) = @_;
    CORE::open( my $F,'<', $file ) or die $!;
    require String::CRC32;
    my $crc = String::CRC32::crc32( $F );
    close $F;
    return $crc;
}

sub _crc_match {
    my ($self, $local, $remote ) = @_;
    return 1 if $self->is_win; # XXX crc not matching in windows
    my $crc_local = $self->_crc_local( $local );
    my $crc_remote = $self->_crc( $remote );
    return $crc_local eq $crc_remote;
}

sub _execute {
    my ( $self, @cmd ) = @_;
    @cmd or Util->_fail('Missing argument cmd');
    my $rcmd = join ' ', ( @cmd == 1 ? ($cmd[0]) : ($self->_quote_cmd(@cmd)) ); 
    #_debug "BALIX CMD=$rcmd";
    $self->socket->print( $self->encodeCMD("X $rcmd") . $self->EOL );
    $self->_checkRC();
}

sub _checkRC {
    my ($self,$noshift) = @_;
    my ($buf,$ret); 
    my $socket = $self->socket;
    #warn "READ....";
    #my $ret    = <$socket>;
    sysread $socket, $buf, 1024;
    $buf = $self->_ebc->toascii( $buf ) if $self->mvs;
    $ret = $buf;
    while ( !( $ret =~ /HARAXE=([0-9]*)/ ) ) {
        sysread $socket, $buf, 1024;
        #$ret .= <$socket>;
        $buf = $self->_ebc->toascii( $buf ) if $self->mvs;
        $ret .= $buf;
    }
    my $rc = 0;
    if ( $ret =~ /HARAXE=([0-9]*)/ ) {
        $rc = $1;
        $ret =~ s/[\n]*HARAXE=([0-9]*)//g;
    }
    my $ret_parsed = $self->_parseReturn($ret);
    if( $self->os ne 'win' && !$noshift ) {
        $rc >>= 8;   
    }
    $self->rc( $rc );
    $self->ret( $ret_parsed );
    $self->output( $ret_parsed );
    return wantarray
        ? ( $rc, $ret_parsed )
        : { rc=>$rc, ret=>$ret_parsed };
}

sub _parseReturn {
    my $self = shift;
    my $RET = shift @_;
    $RET =~ s/who\:.0551.*shell//s;
    $RET;
}

sub EOL {
    my $self = shift;
    return $self->mvs ? $self->_ebc->toebcdic( "\n" ) : "\n";
}

sub encodeCMD {
    my ( $self, $cmd ) = @_;
    #print "\nencodeCMD: $cmd\n";
    my $ret = $self->_blow->encrypt($cmd);
    #print "encrypted=[$ret]\n";
    $ret = $self->mvs ? $self->_ebc->toebcdic($ret) : $ret;
    #print "encoded=[$ret]\n";
    return $ret;
}

sub decodeCMD {
    my ( $self, $cmd ) = @_;
    my $ret = $self->_blow->decrypt($cmd);
    $self->mvs ? $self->_ebc->toascii($ret) : $ret;
}

sub encodeDATA {
    my ($self, $data ) = @_;
    my $RET = "";
    # convert the data
    $data = $self->_ebc->toebcdic( $data ) if $self->mvs;
    # from char to HH uppercase hex codes
    my $ret = join( '', unpack( "H*", $data ) );
    # convert the hex stream
    $self->mvs ? $self->_ebc->toebcdic( $ret ) : $ret;
}


1;
