package Baseliner::Node::ssh;
use Moose;
use Baseliner::Utils;
use Cwd;
use Net::OpenSSH;
use namespace::autoclean;

has 'local' => qw(is rw isa Path::Class::Dir lazy 1), default => sub { _dir( Cwd::cwd() ) };
has ssh     => (
    is       => 'rw',
    isa      => 'Net::OpenSSH',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->debug and $Net::OpenSSH::debug |= 8;
        my $uri = $self->_build_uri;
        my $n = Net::OpenSSH->new( $uri );
        $n->error and _throw "ssh: Could not connect to $uri: " . $n->error;
        $n;
    },
    handles => [ qw/error/ ],
);
has _method => qw(is ro default scp);  # for replacing scp with rsync on inheritance

with 'Baseliner::Role::Node::Filesys';

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
    $self->ret( $out );
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
    _log "URI=" . $self->uri . ", L=$local, R=$remote";
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

    my $ret = $self->ssh->system( \%p, @cmd );
    my $rc = $?;

    my $out = _slurp $p{stdout_file};
    unlink $p{stdout_file};
    $self->ret( $out );
    $self->_throw_on_error;
    $ret;
}

sub _build_uri {
    my ($self) = @_;
    my $uri = $self->uri;
    my ($conn) = $uri =~ m{//(.*?)(/.*)?$};
    return $conn if $conn;
    _throw _loc "Could not create connection from uri %1", $self->uri;
}

1;
