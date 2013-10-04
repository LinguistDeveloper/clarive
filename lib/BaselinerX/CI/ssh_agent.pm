package BaselinerX::CI::ssh_agent;
use Baseliner::Moose;
use Baseliner::Utils;
#use namespace::autoclean;

has_ci 'server';
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
        Baseliner->debug and $Net::OpenSSH::debug |= 8;
        my $uri = $self->_build_uri;
        require Net::OpenSSH;
        my $n = Net::OpenSSH->new( $uri );
        $n->error and _throw "ssh: Could not connect to $uri: " . $n->error;
        $n;
    },
    handles => [ qw/error/ ],
);
has _method => qw(is ro isa Any default scp);  # for replacing scp with rsync on inheritance

with 'Baseliner::Role::CI::Agent';

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

sub chmod {
    my $self = shift;
    if( $self->os eq 'Win32' ) {
        _throw 'Unimplemented';
    } else {
        $self->execute( 'chmod',  @_ );
    }
}

sub make_writable {
    my $self = shift;
    $self->chmod( '-R', 'u+w', @_ );
}

sub get_file {
    shift->get_dir( @_ );
}

sub get_dir {
    my ($self, %p) = @_;
    my $local = delete $p{local} || $self->local || _throw "Missing parameter local";
    my $remote = delete $p{remote} || $self->home || _throw "Missing parameter remote";
    $p{recursive} = 1;
    $p{copy_attrs} = $self->copy_attrs; # copies attributes : may cause an error scp set mode: Not owner
    $p{glob} = 1; # allows for * 
    $p{stderr_to_stdout} = 1;
    $p{stdout_file} = _tmp_file;  # send output to tmp file
    ( $local, $remote ) = map { "$_" } $local, $remote;  # strigify possible Path::Class
    _mkpath( $local ) if ! -d $local && $self->mkpath_on; # create local path
    my $method = $self->_method . "_get";
    my $ret = $self->ssh->$method( \%p, $remote, $local ); 
    my $out = _slurp $p{stdout_file};
    unlink $p{stdout_file};
    $self->ret( "$out" );
    $self->_throw_on_error;
    $ret;
}

=head2 put_file

=cut
sub put_file {
    my $self = shift;
    $self->put_dir( @_ );
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
    $self->mkpath( $remote ) if $self->mkpath_on; # create remote path
    #$self->make_writable( $remote ) if $self->overwrite_on;
    my $method = $self->_method . "_put";

    # check if exists
    _throw _loc ( "put-dir error: local file/dir not found: %1", $local)
        if $local !~ /\*/ && ! -e $local;  # don't check if contains asterisks

    # run 
    _log "URI=" . $self->_build_uri . ", L=$local, R=$remote";
    my $ret = $self->ssh->$method( \%p, $local, $remote ); 

    my $out = _slurp $p{stdout_file};
    unlink $p{stdout_file};
    $self->ret( $out );
    $self->_throw_on_error;
    $ret;
}

sub execute {
    my $self = shift;
    local $SIG{CHLD};
    my %p = ( stderr_to_stdout => 1, );
    my @cmd = map { "$_" } @_ ; # stringify possible Path::Class
    $p{stdout_file} = _tmp_file;  # send output to tmp file

    my $ret; 
    my $rc; 
    my $timeout = length $self->{timeout} ? $self->{timeout} : 60;

    use Try::Tiny;
    try {
        local $SIG{ALRM} = sub { die "ssh timeout alarm\n" };
        alarm $timeout; 
        $ret = $self->ssh->system( \%p, @cmd );
        $rc = $?;
        alarm 0;
    } catch {
        alarm 0;
        my $err = shift;
        _fail _loc( 'Timeout %1 (%2)', $self->_build_uri, "@cmd" ) if $err =~ /ssh timeout alarm/; 
        _fail _loc( 'ssh_agent execute error %1 (%2): %3', $self->_build_uri, "@cmd", $err ) if $err =~ /ssh timeout alarm/; 
    };
    my $out = _slurp $p{stdout_file};
    unlink $p{stdout_file};
    $self->ret( "$out" );
    $self->_throw_on_error;
    $ret;
}

sub _build_uri {
    my ($self) = @_;
    if( $self->{user} ) {
        return sprintf('%s@%s', $self->{user}, $self->server->hostname ); 
    } 
    else {
        return $self->server->hostname; 
    }
}

1;

