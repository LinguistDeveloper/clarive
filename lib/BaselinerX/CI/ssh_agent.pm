package BaselinerX::CI::ssh_agent;
use Baseliner::Moose;
use Baseliner::Utils;
use Baseliner::CommandRunner;
use Try::Tiny;
#use namespace::autoclean;

has_ci 'server';
has user   => qw(is rw isa Maybe[Str]);
has port_num   => qw(is rw isa Any);
has private_key => qw(is rw isa Any);

has 'local' => qw(is rw isa Path::Class::Dir lazy 1), default => sub { require Cwd; _dir( Cwd::cwd() ) };
has ssh     => (
    is       => 'rw',
    isa      => 'Net::OpenSSH',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;

        Clarive->debug and $Net::OpenSSH::debug |= 8;

        my $uri = $self->_build_uri;

        my $n = $self->_build_openssh( $uri,
            master_opts      => [ @{ $self->_options } ],
            default_ssh_opts => [ -F => '/dev/null' ]
        );
        $n->error and _throw "ssh: Could not connect to $uri: " . $n->error;
        $n;
    },
    handles => [ qw/error/ ],
);
has _method => qw(is ro isa Any default scp);  # for replacing scp with rsync on inheritance

with 'Baseliner::Role::CI::Agent';

sub _options {
    my $self = shift;

    my $options = [
        -F => '/dev/null',
        -o => 'StrictHostKeyChecking=no',
        -o => 'PasswordAuthentication=no',
        -o => 'UserKnownHostsFile=/dev/null'
    ];
    push @$options, -i => $self->private_key if $self->private_key;

    return $options;
}

sub rel_type {
    {
        server    => [ from_mid => 'ssh_agent_server' ],
    };
}

sub rc {
    my $self = shift;
    $self->error ? 1 : 0;
}

sub mkpath {
    my $self = shift;
    if( $self->os eq 'Win32' ) {
        _throw 'Unimplemented';
    } else {
        $self->execute( 'mkdir', '-p', @_ );
    }
}

sub rmpath {
    my $self = shift;
    if( $self->os eq 'Win32' ) {
        _throw 'Unimplemented';
    } else {
        $self->execute( 'rm', '-rf', @_ );
    }
}

method chmod ( $mode, $path ) {
    $self->execute( 'chmod', $mode, $path );
    $self->rc and _fail _loc( "Could not chmod '%1 %2': %3", $mode, $path, $self->output );
}

method chown ( $perms, $path ) {
    $self->execute( 'chown', $perms, $path );
    $self->rc and _fail _loc( "Could not chown '%1 %2': %3", $perms, $path, $self->output );
}

sub make_writable {
    my $self = shift;
    $self->chmod( '-R', 'u+w', @_ );
}

method file_exists( $file_or_dir ) {
    my ($rc,$ret) = $self->execute( 'test', '-r', $file_or_dir ); # check it exists
    return !$rc;
}

sub get_file {
    shift->get_dir( @_, file_to_file=>1 );
}

sub get_dir {
    my ($self, %p) = @_;
    my $file_to_file = delete $p{file_to_file};
    my $local = delete $p{local} || $self->local || _throw "Missing parameter local";
    my $remote = delete $p{remote} || $self->home || _throw "Missing parameter remote";
    $p{recursive} = 1;
    $p{copy_attrs} = $self->copy_attrs; # copies attributes : may cause an error scp set mode: Not owner
    $p{glob} = 1; # allows for *
    $p{stderr_to_stdout} = 1;
    $p{stdout_file} = _tmp_file;  # send output to tmp file
    ( $local, $remote ) = map { "$_" } $local, $remote;  # strigify possible Path::Class
    _mkpath( $local ) if !-d $local && !$file_to_file && $self->mkpath_on; # create local path
    my $method = $self->_method . "_get";
    my $ret = $self->ssh->$method( \%p, $remote, $local );
    my $out = Util->_slurp( $p{stdout_file} );
    unlink $p{stdout_file};
    $self->ret( "$out" );
    $self->_throw_on_error;
    $ret;
}

=head2 put_file

=cut
sub put_file {
    my $self = shift;
    $self->put_dir( @_, file_to_file=>1 );
}

sub put_data {
    my ($self, %p) = @_;
    my $data = $p{data};
    my $remote = $p{remote};
    my $local = _file(sprintf '%s/%s_weblogic_%s_%s.sh', _tmp_dir, $self->server->hostname, $self->server->mid, Util->_md5);
    $local->spew(iomode => '>:raw', $data);
    if (-e $local){
        $self->put_file(local => $local, remote => $remote);
    } else {
        _throw _loc("File %1 not found",$local->{file});
    }
}

sub delete_file {
    my $self = shift;
    my %p = @_;
    my $server = $p{server};
    my $file = $p{remote};
    $self->execute( 'ssh', $server, 'rm', $file );
}

=head2 put_dir

General method to copy files.

Parameters:

    local     => local file or dir
    remote    => remote file dir
    add_path  => path to add to remote
    recusive  => copy recurse ( default: 1 )

=cut
sub put_dir {
    my ($self, %p) = @_;
    my $file_to_file = delete $p{file_to_file};
    my $local = delete $p{local} || $self->local || _throw "Missing local";
    my $remote = delete $p{remote} || $self->home || _throw "Missing remote";
    if( ! (-e $local) && ($local !~ /.*\*$/) ) {
        $self->ret( _loc('File skipped: %1', $local ) );
        return {};
    }
    length $p{add_path} and $remote = _dir( $remote, $p{add_path} );
    delete $p{add_path};
    $p{recursive} //= 1;
    $p{copy_attrs} //= $self->copy_attrs; # copies attributes : may cause an error scp set mode: Not owner
    $p{glob} //= 1; # allows for *
    $p{stderr_to_stdout} //= 1;
    $p{stdout_file} //= _tmp_file;  # send output to tmp file
    ( $local, $remote ) = map { "$_" } $local, $remote;  # strigify possible Path::Class
    $self->mkpath( $remote ) if !$file_to_file && $self->mkpath_on; # create remote path
    #$self->make_writable( $remote ) if $self->overwrite_on;
    my $method = $self->_method . "_put";

    # check if exists
    _throw _loc( "put-dir error: local file/dir not found: %1", $local)
        if $local !~ /\*/ && ! -e $local;  # don't check if contains asterisks

    # run
    _log "URI=" . $self->_build_uri . ", L=$local, R=$remote";
    my $ret = $self->ssh->$method( \%p, $local, $remote );
    $ret = defined $ret ? $ret : 127;

    my $out = Util->_slurp( $p{stdout_file} );
    unlink $p{stdout_file};
    $self->ret( $out );
    $self->_throw_on_error;
    $ret;
}

sub execute {
    my $self = shift;
    my $opts = shift @_ if ref $_[0] eq 'HASH';
    local $SIG{CHLD};
    my %p = ( stderr_to_stdout => 1, );
    my @cmd = map { "$_" } @_ ; # stringify possible Path::Class
    $p{stdout_file} = _tmp_file;  # send output to tmp file

    # TODO alternative: send a shell file (or .bat) to remote and execute it?
    my $cmd_quoted;
    if( length( join('', @cmd) ) > 65_536 ) {  # 64K TODO use getconf ARG_MAX - length(join '',%ENV)
        $cmd_quoted = join ' ', $self->_double_quote_cmd( @cmd ); # command is too large, so we use a quoted version
    }
    my $ret;
    my $rc;
    my $timeout = length $self->{timeout} ? $self->{timeout} : 60;

    try {
        local $SIG{ALRM} = sub { die "ssh timeout alarm\n" };
        alarm $timeout;
        if( !$cmd_quoted ) {
            $ret = $self->ssh->system( \%p, @cmd );
        } else {
            $ret = $self->ssh->system({ %p, tty=>0, stdin_data=>$cmd_quoted });
        }
        $rc = $?;
        alarm 0;
    } catch {
        alarm 0;
        my $err = shift;
        my $msg = _loc( 'ssh_agent execute error %1 (%2): %3', $self->_build_uri, "@cmd", $err );
        _fail $msg if $self->throw_errors;
        $ret = $msg;
        $rc = $?>0 ? $? : 99;
        #_fail _loc( 'Timeout %1 (%2)', $self->_build_uri, "@cmd" ) if $err =~ /ssh timeout alarm/;
        #_fail _loc( 'ssh_agent execute error %1 (%2): %3', $self->_build_uri, "@cmd", $err ) if $err =~ /ssh timeout alarm/;
    };
    my $out = Util->_slurp( $p{stdout_file} );
    $out //= '';
    unlink $p{stdout_file};
    $self->ret( "$out" );
    $self->rc( $rc );
    $self->_throw_on_error;
    ($rc, $ret);
}

sub sync_dir {
    my ( $self, %p ) = @_;

    my $remote            = $p{remote}            // _throw 'Missing remote parameter';
    my $local             = $p{local}             // _throw 'Missing local parameter';
    my $direction         = $p{direction}         // 'local-to-remote';
    my $delete_extraneous = $p{delete_extraneous} // 0;

    my $server = $self->_build_uri;
    my $port;
    if ($server =~ s{:(\d+)$}{}) {
        $port = $1;
    }
    $remote = "$server:$remote";

    my ( $from, $to ) = $direction eq 'local-to-remote' ? ( $local, $remote ) : ( $remote, $local );

    my $command_runner = $self->_build_command_runner;

    my @ssh_opts = @{ $self->_options };
    if ($port) {
        push @ssh_opts, '-p', $port;
    }

    my @options;
    push @options, '-e', "ssh @ssh_opts";

    if ($delete_extraneous) {
        push @options, '--delete';
    }

    my $ret = $command_runner->run('rsync', '-avz', @options, $from, $to);

    $self->ret( $ret->{output} );
    $self->rc( $ret->{exit_code} );

    $self->_throw_on_error;

    return ( $ret->{exit_code}, $ret->{output} );
}

sub _build_openssh {
    my $self = shift;

    require Net::OpenSSH;
    return Net::OpenSSH->new(@_);
}

sub _build_command_runner {
    return Baseliner::CommandRunner->new;
}

sub _build_uri {
    my $self = shift;

    my $uri;
    if ( $self->user ) {
        $uri = join '@', $self->user, $self->server->hostname;
    }
    else {
        $uri = $self->server->hostname;
    }

    if ( $self->port_num ) {
        $uri .= ':' . $self->port_num;
    }
    elsif ( Clarive->config->{ssh_port} ) {
        $uri .= ':' . Clarive->config->{ssh_port} // 22;
    }

    return $uri;
}

1;
