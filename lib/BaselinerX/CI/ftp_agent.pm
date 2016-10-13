package BaselinerX::CI::ftp_agent;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Agent';

use Baseliner::Utils qw(_fail _loc _throw _file);

has_ci 'server';

has user     => qw(is rw isa Maybe[Str]);
has password => qw(is rw isa Maybe[Str]);
has port_num => qw(is rw isa Any);
has home     => qw(is rw isa Any);

has ftp => (
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift;

        my $hostname = $self->server->hostname;
        my $user     = $self->user;
        my $password = $self->password;
        my $home     = $self->home;

        my $ftp = $self->_build_ftp($hostname)
          or _fail _loc("FTP: Could not connect to host %1", $hostname);

        my $is_anonymous = $user && $user eq 'anonymous' ? 1 : 0;

        if ( !$is_anonymous && (!defined $user || !defined $password) ) {
            my $machine = $self->_netrc_lookup( $hostname, $user );
            if ($machine) {
                ( $user, $password ) = ( $user // $machine->login, $machine->password );
            }
        }

        _fail _loc('FTP: No username/password were provided or could not be discovered')
          unless $is_anonymous || ($user && $password);

        $ftp->login( $user, $password ) or _fail _loc('FTP: Could not login: %1',$ftp->message);

        if ( length $home ) {
            my $rc = $ftp->cwd($home);
            _fail _loc("FTP: Could not change home directory to %1: %2", $home, $ftp->message)
              unless $rc;
        }

        $ftp->binary;

        return $ftp;
    }
);

sub ping {
    my $self = shift;

    $self->ls;

    return 1;
}

sub error {
    return shift->ftp->message;
}

sub chmod { }
sub mkpath { }
sub rmpath { }
sub rc { }

sub put_file {
    my ($self, %p) = @_;

    my $local  = "$p{local}";
    my $remote = "$p{remote}";

    if( ! -e $local ) {
       $self->rc( 19 );
       _fail $self->ret( _loc("FTP: could not find local file %1", $local ) );
    }

    if (defined $remote && length $remote) {
        $self->ftp->cwd( _file("$remote")->dir ) or _fail _loc('FTP: could not cwd to %1', $remote);
    }

    if (!$self->ftp->put( "$local" )) {
        $self->rc( 19 );
        $self->ret( $self->ftp->message );
    }

    $self->_throw_on_error;

    return $self->tuple;
}

sub put_dir {
    my ($self, %p) = @_;
    $self->ftp->put( "$p{local}", "$p{remote}" );
    $self->ftp->message;
}

sub get_file {
    my ($self, %p) = @_;
    $self->ftp->get( "$p{remote}", "$p{local}" );
    $self->ftp->message;
}

sub get_dir {
    my ($self, %p) = @_;
    $self->ftp->get( "$p{remote}", "$p{local}" );
    $self->ftp->message;
}

sub pwd {
    my ($self, %p) = @_;
    $self->ftp->pwd();
    $self->ftp->message;
}

sub ls {
    my ($self, %p) = @_;

    $p{remote} //= '/';

    my @files=$self->ftp->ls( "$p{remote}" );
    return ({files=>[@files], message=>$self->ftp->message});
}

sub dir {
    my ($self, %p) = @_;
    my @files=$self->ftp->dir( "$p{remote}" );
    return ({files=>[@files], message=>$self->ftp->message});
}

sub cd {
    my ($self, %p) = @_;

    $self->ftp->cwd( "$p{remote}" );
    $self->ftp->message;
}

sub delete {
    my ($self, %p) = @_;

    $self->ftp->delete( "$p{remote}" );
    $self->ftp->message;
}

sub rename {
    my ($self, %p) = @_;

    $self->ftp->rename( "$p{old}", "$p{new}" );
    $self->ftp->message;
}

sub close {
    my ($self, %p) = @_;

    $self->ftp->close();
    $self->ftp->message;
}

method file_exists( $file_or_dir ) {
    $self->ftp->ls($file_or_dir);

    if ($self->ftp->message =~ m/no such file or directory/i) {
        return 0;
    }

    return 1;
}

sub execute {
    my $self = shift;
    _throw "FTP execute not implemented yet.";
}

sub sync_dir { _throw 'sync_dir not supported' }

sub _build_ftp {
    my $self = shift;
    my ($hostname) = @_;

    require Net::FTP;
    return Net::FTP->new( $hostname, Timeout => 15 )
}

sub _netrc_lookup {
    my $self = shift;
    my (@params) = @_;

    require Net::Netrc;
    return Net::Netrc->lookup( @params );
}

1;
