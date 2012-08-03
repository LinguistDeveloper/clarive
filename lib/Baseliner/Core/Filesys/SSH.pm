package Baseliner::Core::Filesys::SSH;
use Moose;
use Baseliner::Utils;
use File::Spec;
use Filesys::Virtual::SSH;
require File::Find; 

has ret    => qw/is rw isa Any/;
has rc     => qw/is rw isa Any/;
has scp    => qw/is rw isa Net::SCP::Port/;
has ssh    => qw/is rw isa Filesys::Virtual::SSH/;
has remote => qw/is rw isa Any/;

our $VERSION='1.00';
our %cache;  ## to store host details in between instances

# register implementation
with 'Baseliner::Role::Filesys';

# monkey patch 
use String::ShellQuote;
sub Filesys::Virtual::SSH::shell_quote {
    my $sh = String::ShellQuote::shell_quote(@_);
    if( $^O eq 'MSWin32' ) {
        $sh =~ s{"}{¡}g;
        $sh =~ s{'}{"}g;
        $sh =~ s{¡}{\"}g;
    }
    warn "SH==$sh";
    return $sh;
}

sub new {
    my $class=shift;
    my %P = @_;
    
    ## home dir stuff
    my $home = $P{home};
    _log "HOME1=$home";
    my $host = '';  ## machine
    my $port = 53255;
    my $user = '';  ## usr
    my $conn = '';  ## usr@machine
    my $remote = '';  ## bool
    $home =~ s{\\}{/}g;   ## everything is slash forward
    $home =~ s/^localhost://g;  ## localhost without a user is meaningless
    if( !$P{"local"} && $home =~ /^(.*?)=(.*?)$/ ) {  ## remote?
          $conn=$1;
          $home=$2;
          $remote = 1;
    }
    if( $conn =~ /^(.*?)\@(.*?)$/ ) {
        $user = $1;
        $host = $2;
    }
    if( $host =~ m/^(.*?)\:(.*?)$/ ) {
        $host=$1;
        $port=$2;
        $conn= "-p $port $user\@$host";
    }
    _log "HOST=$host";
    _log "PORT=$port";
    _log "HOME=$home";
    _log "CONN=$conn";
    my $self = {
        remote=>$remote,  ## boolean 
        user=>$user,	## just a user
        host=>$host,	## just a host
        port=>$port,
        home=>$home,	## just a path
        conn=>$conn,	## usr@host, or just host
        os=>$P{os}
    };
    
    $self = bless( $self, $class);
    
    if( $self->{remote} ) {
        ## SSH initialization
        $self->{ssh} = Filesys::Virtual::SSH->new({
             host      => $conn,  
             cwd       => '/',
             root_path => '/',
             home_path => "$ENV{HOME}",
        }) or _throw _loc("Error creating ssh connection: %1",$!);
        
        ## SCP initialization
        $self->{scp} = Net::SCP::Port->new( { host=>$host, user=>$user, port=>$port } )
            or _throw _loc("Error creating scp connection: %1", $self->{scp}->{errstr});
        _throw _loc("Error creating scp connection (obj does not exist): %1", $self->{scp}->{errstr}) unless $self->{scp};			
    }

    unless( $self->{os} ) {
        my ($rc,$ret) = $self->_execute('set 2>&1' );
        if( $ret && $ret=~ m/OS=(\w*)/si ) {
            $self->{os_name} = $1;
            if( $1 =~ /win/i ) {
                $self->{os} = 'win';
            } else {
                $self->{os} = 'unix';				
            }
        } else {
            my ($rc,$ret)=$self->_execute("uname");
            $self->{os} = 'unix';
            ($self->{os_name} = $ret )=~ s{\n|\r}{}g; 
        } 
    } 

    return $self;	
}

sub home {
    my $self=shift;
    return $self->slashes($self->{home});
}

sub cd {
    my ($self, $path) = @_;
    $path ||= $self->{home};  
    $self->{ssh}->chdir( slashFwd( $path ) ) 
        or _throw _loc("Error in ssh: could not change dir to '%1': %2", slashFwd($path), $!);	
    $self->{scp}->cwd( slashFwd( $path ) ) 
        or _throw _loc("Error in scp: could not change dir to '%1': %2", slashFwd($path), $self->{scp}->{errstr});
    return;	
}

sub _execute {
    my ($self,$cmd) = @_;
    
    if( $self->{remote} ) {
        $cmd =~ s{\"(.*?)\"}{$1}g if $self->is_win;
        $ENV{BASELINER_DEBUG} and warn "EXEC REMOTE=$cmd\n";        
        $self->{ret} = $self->{ssh}->_remotely($cmd);
        $self->{rc} = $? >> 8;
    } else {
        $ENV{BASELINER_DEBUG} and warn "EXEC LOCAL=$cmd\n";     
        $self->{ret} = `$cmd`;
        $self->{rc} = $? >> 8;
    }	
    return( $self->{rc}, $self->{ret} ) if wantarray;
}

sub execute {
    my $self = shift;
    my %p  =  %{ shift() } if ref $_[0];
    my @cmd_list = defined $p{cmd} ? _array($p{cmd}) : @_;
    my @cmds;
    my $pre_cd = '';
    $pre_cd = $self->is_win() ? qq{cd /D "}.$self->home.qq{"} : qq{cd "$self->{home}"} unless( $p{no_cd} );
    for my $rcmd ( $pre_cd, @cmd_list ) {
        next if !$rcmd;
        my $cc=$rcmd;
        if( $self->{remote} ) {
            #$cc=~s{\\}{\\\\}g if( !$p{pure} && $self->is_win );	
            ##$cc=~s{"}{""}g if( !$p{pure} && $self->is_win );	
            ## /bin/switch: $cc=~s{\\}{\\\\\\\\}g if( !$P{pure} && $self->is_win );	
            ## /bin/switch: $cc=~s{"}{\\"}g if(  !$P{pure} &&  $self->is_win );
            ## /bin/switch: $cc="cmd /c $cc" if(  !$P{pure} && $self->is_win && $cc =~ m{^dir}i );
            $cc.=' 2>&1' if !$p{pure};
            push @cmds, $cc;
        } else {
            $cc .= ' 2>&1' unless $p{pure};
            push @cmds, $cc;
        }		
    }
    if( $self->is_win() ) {
        $self->_execute( join(' && ',@cmds) );
        if( @cmds > 1 ) {
            #$self->_execute( 'cmd /c "'.join(' && ',@cmds).'"' );		
        } else {
            #$self->_execute( 'cmd /c '.join(' && ',@cmds) );					
        }
        
    } else {
        $self->_execute( join ' ; ',@cmds );
        
    }
    if( wantarray ) {
        return ( $self->{rc}, $self->{ret} );
    } else {
        return $self->{ret}
    }
}

sub rel_path {
    my ($self,$file)=@_;
    my $path = $self->slashes( $self->path( $self->{home}, $file ) );
    $path=~ s{\\\\}{\\}g;	
    $path;
}

sub path {
    my $self=shift;
    my $slash = ( $self->is_win ? "\\" : '/' );
    join $slash, @_;
}

sub is_win {
    my $self=shift;
    $self->{os} =~ m/win/i;
}

sub slashes {
    my ($self, $path) = @_;
    if( $self->is_win ) {
        $path=~ s{/}{\\}g;	
    }
    else {
        $path=~ s{\\}{/}g;	
    }
    $path;
}

sub find {
    my $self=shift;
    my %ret = ();
    my %P = @_;
    
    my $dir = $P{dir} || $self->{home} || '.';
    my $dir_len = length( $dir );
    my $filter = $P{filter} || $self->{filter};
    my $rel_path = $P{rel_path};
    my @rel_keys=();
    if( $rel_path ) {
        @rel_keys=split /\//, $rel_path;
    }
    
    my $callback = $P{callback} || sub { 
            my $full= slashFwd("$File::Find::dir/$_");
            my $full_len = length($full);
            my $path = slashFwd($File::Find::name);
            my $rel=substr($path, $dir_len );
            next if( $filter && $full !~ m{$filter} ); 
            $ret{$full}{name}=$File::Find::name;
            $ret{$full}{dir}=$File::Find::dir;
            $ret{$full}{rel}=$rel;
            $ret{$full}{is_dir}= -d $File::Find::name;
            if( $rel_path ) {
                my @paths = split /\//, $rel;
                for( @rel_keys ) {
                    my $s = shift @paths;
                    next if !$s;
                    $ret{$full}{$_}=$s;
                    $ret{$full}{rel_left}.= "/$s"; 
                }
                for( @paths ) {
                    $ret{$full}{rel_right}.= "/$_"; 
                }
                #$ret{$full}{rel_root}= substr( $full, 0, index($full, $ret{$full}{rel_left})  );
            }
        };  ## if no callback provided, one is provided for you
        
    if( $self->{remote} ) {  ## use OS specific find
        
        ## remote find
        
        ## iterate over callback 
        
    } else {
        File::Find::find( 
            $callback,
            $dir );
    }
    %ret;
}

sub read {
    my $self=shift;
    my %P=@_;
    my $file=$P{file};
    my $encoding = $P{encoding} || ':raw';
    my $ret='';
    if( $self->{remote} ) {
        
    } else {
        open FF, "<$encoding", "$file" or _throw(_loc("Error opening file '%1' for reading (encoding: '%2'): %3", $file,$encoding, $!));
        $ret .=$_ for(<FF>);
        close FF;
    }
    $ret;
}

sub write {
    my ($self, %P) = @_;
    _throw _loc( "Missing file or path parameter" ) unless( $P{file} || $P{path} );
    my $file=$P{file};  ## file gets concat with the home path
    my $encoding = $P{encoding} || ':raw';
    my $path = $P{path} || $self->home.'/'.$file; ## path is absolute
    $path=$self->slashes($path);
    if( $self->{remote} ) {
        _throw _loc "write file on remote location not implemented yet.";
    } else {		
        open FF, ">$encoding", "$path" or _throw(_loc("Error opening file '%1' for writing (encoding: '%2'): %3", $path,$encoding, $!));
        print FF $P{data};
        close FF;
    }
    $path;
}

sub get {  ## copy from somewhere else to my filesystem
    my ($self, %P)=@_;
    my $from = $P{from} || _throw _loc( "Invalid blank origin on put" );
    my $to = $P{to} || $self->{home};  ## optional
    my $origfs = ( ref $from ? $from : __PACKAGE__->new( home=>$from ) ); 
    if( $self->{remote} ) {
        if( $origfs->{remote} ) {  	## from remote to remote
            _throw _loc "put from remote destinations not implemented yet.";
            ## get a tmp
            ## put to dest
        } else {  					## from local to remote
            $self->mkdir($to); 
            my $from = slashFwd($origfs->home);
            my $to = _subpath( $to, -1);
            $self->{scp}->put( $from, $to ) 
                or _throw _loc( "Error putting files from '%1' to '%2': %3", $from, $to, $self->{scp}->{errstr});
        }
    } else {
        if( $origfs->{remote} ) {  	## from remote to local
            $origfs->{scp}->get( $origfs->slashes( $origfs->home ), $to );
        } else {  					## from local to local
            $self->copy( $origfs->home, $to ); 
        }
    }	  
}

sub put {  ## copy from my filesystem to somewhere else
    my ($self, %P)=@_;
    $P{to_file} and $P{to} = $P{to_file}; # to_file - does not mkdir
    my $to = $P{to} || _throw _loc( "Invalid blank destination 'to' on put" );
    my $from = $P{from} || $self->{home};  ## optional
    my $destfs = ( ref $to ? $to : __PACKAGE__->new( home=>$to ) ); 
    if( $self->{remote} ) {
        if( $destfs->{remote} ) {  	## from remote to remote
            _throw _loc "get to remote destinations not implemented yet.";
            ## get a tmp
            ## put to dest
        } else {  					## from local to remote
            $destfs->mkdir($destfs->home) unless $P{to_file}; 
            my $topath = $destfs->slashes($destfs->home);
            my $frompath = slashFwd($from);
            $self->{scp}->put( $frompath, $topath ) 
                or _throw _loc( "Error getting files from '%1' to '%2': %3", $frompath, $topath, $self->{scp}->{errstr});
        }
    } else {
        if( $destfs->{remote} ) {  	## from remote to local
            $destfs->{scp}->get( slashFwd($from), slashFwd( $destfs->home ) );
        } else {  					## from local to local
            $self->copy( $from , $destfs->home ); 
        }
    }	  
}

sub copy {
    ## copies from one point to the next in the same filesystem
    my ($self, $from, $to ) =@_;
    if( $self->is_win ) {
        $self->execute( qq{xcopy /Y /E "$from" "$to"} );					
    } else {
        $self->execute( qq{cp -R "$from" "$to"} );		
    }
}

sub mkdir_home {
    my ($self)=@_;
    $self->mkdir($self->{home} );
}

sub mkdir {
    my ($self, $dir)=@_;
    $dir||=$self->home;
    if( $self->{remote} ) {
        if( $self->is_win ) {
            $dir = $self->slashes( $dir);
            _log "mkdir-win '$dir'";
            my ($rc,$ret) = $self->execute({no_cd=>1}, qq{md "$dir"});
            _throw _loc("Error in mkdir (code=$rc) '%1': %2", $dir, $ret) if $rc && !$self->is_win; ## can't on windows, sometimes it's just 'already exists'		
        } else {
            _log "mkdir '$dir'";
            $dir = $self->slashes( $dir);
            $self->{scp}->mkdir( $dir ) or _throw _loc("Error in mkdir scp '%1': %2", $dir, $self->{scp}->{errstr});
        }
    } else {
        _log "mkdir-local '$dir'";
        mkdir $self->{home};
    }			
}

sub chmod {
    my ($self, %P)=@_;
    $P{path} ||= $self->{home};
    $P{mode} ||= ( $self->is_win ? '+A' : 'u+w' );
    $P{recursive} ||= 1;
    my $cmd;
    if( $self->is_win ) {
        $cmd = ( $P{recursive} ? 'attrib /S /D' :  'cmd /c attrib /D' );
    } else {
        $cmd = ( $P{recursive} ? 'chmod -R' :  'chmod' );
    }
    $cmd .= ' '.$P{mode}.' "'.$P{path}.'"';
    $self->execute( $cmd );
}

sub chown {
    my ($self, %P)=@_;
    $P{path} ||= $self->{home};
    $P{owner} ||= $self->{user};
    $P{recursive} ||= 1;
    my $cmd;
    if( $self->is_win ) {
        $cmd = ( $P{recursive} 
            ? qq{cacls "$P{path}" /t /e /c /g $P{owner}} 
            : qq{cacls "$P{path}" /e /c /g $P{owner}} 
            ); #"
    } else {
        $cmd = ( $P{recursive} 
            ? qq{chown -R $P{owner} "$P{path}"} 
            : qq{chown $P{owner} "$P{path}"} );
    }
    $self->execute( $cmd );
    _throw _loc("Error during chown '%1' of path '%2': %3", $P{owner}, $P{path}, $self->ret ) if $self->rc;
}

sub unc {
    my ($self, %P)=@_;
    my $path = $P{path} || $self->{home};
    my $host= $self->{host} || 'localhost';
    $path=~ s{([A-Za-z])\:}{$1\$}gi;
    $path = slashBack( $path );
    $path = "\\$host\\$path";
    $path = slashSingle( $path );
    return "\\".$path;
}

sub _subpath {  ## subtracts $i tokens from the path 
    my ( $path, $i ) = @_;
    my $sp = $path;
    $sp = slashFwd($sp);
    my ($head,$tail)=();
    $head=substr($path,0,1) if $sp=~s{^/}{}g;
    $tail=substr($path,length($path)-1) if $sp=~s{/$}{}g;
    my @p=split/\//,$sp;
    if( $i > 0 ) {  ## from the frontend
        my @r;
        push @r,shift @p for(1..$i);		
        my $len=length join',',@r; 
        return $head.substr($path,$len+1+($head?1:0));
    } else {   ## from the backend
        pop @p for(1..abs $i);
        my $len=length join',',@p; 
        return $head.substr($path,($head?1:0),$len ).$tail;
    }
}

sub end { ## not needed, backward compatibility
    my $self=shift;
    $self->{scp} && $self->{scp}->quit();  ## does nothing
}

sub mkpath {
    my ($self, $path)=@_;
    $path = _dir( $self->{home}, $path );
    $self->execute( qq{mkdir -p "$path"} );
}

{
    package Net::SCP::Port;
    use base 'Net::SCP';
    use IO::Handle;
    use IPC::Open3;
    our $scp = 'scp';

    sub scp {
        my $self = ref($_[0]) ? shift : {};
        my($src, $dest, $interact) = @_;
        my $port = exists $self->{port} ? '-P '. $self->{port} : '';
        my $flags = '-p';
        $flags .= 'r' unless &Net::SCP::_islocal($src) && ! -d $src;
        my @cmd;
        if ( ( defined($interact) && $interact )
                || ( defined($self->{interactive}) && $self->{interactive} ) ) {
            @cmd = ( $scp, $flags, $port, $src, $dest );
            #print join(' ', @cmd), "\n";
            unless ( &_yesno ) {
                $self->{errstr} = "User declined";
                return 0;
            }
        } else {
            $flags .= 'qB';
            @cmd = ( $scp, $flags, $port, $src, $dest );
        }

        my($reader, $writer, $error ) =
            ( new IO::Handle, new IO::Handle, new IO::Handle );
        $writer->autoflush(1);#  $error->autoflush(1);
        local $SIG{CHLD} = 'DEFAULT';
        warn "******** SCP> " . join ',',@cmd;
        my $pid = open3($writer, $reader, $error, @cmd );
        waitpid $pid, 0;
        if ( $? >> 8 ) {
            my $errstr = join('', <$error>);
            #chomp(my $errstr = <$error>);
            $self->{errstr} = $errstr;
            0;
        } else {
            1;
        }
    }
    
}


1;
