package Baseliner::Node::ftp;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::Node::Filesys';

has ftp => ( is=>'rw', isa=>'Net::FTP', required=>1, lazy=>1,
    default => sub {
        my $self = shift;
        require Net::FTP;
        my $ftp = Net::FTP->new( $self->resource->host )
            or _fail _loc "FTP: Could not connect to host %1", $self->resource->host;
        my ( $user, $password );
        if( defined $self->resource->user && defined $self->resource->password ) { 
            ( $user, $password )  = ( $self->resource->user, $self->resource->password );
        } else {
            require Net::Netrc;
            if( defined $self->resource->user ) {
                my $machine = Net::Netrc->lookup( $self->resource->host, $self->resource->user );
                ( $user, $password )  = ( $self->resource->user, $machine->password );
            } else {
                my $machine = Net::Netrc->lookup( $self->resource->host );
                ( $user, $password )  = ( $machine->login, $machine->password );
            }
        }
        $ftp->login( $user, $password ) or _fail $ftp->message;
        if(  length $self->resource->home ) {
            my $rc = $ftp->cwd( $self->resource->home );
            _fail _loc "FTP: Could not change home directory to %1: %2", $self->resource->home, $ftp->message
               unless $rc;
        }
        $ftp->binary;
        $ftp;
    }
);

sub error { 
    return shift->ftp->message;
}

sub chmod { }
sub mkpath { }
sub rmpath { }
sub rc { }

sub put_file {
    my ($self, %p) = @_;
    my $rc;
    if( ! -e "$p{local}" ) {
       $self->rc( 19 );
       _fail $self->ret( _loc "FTP: could not find local file %1", $p{local} );
    }
    $rc = $self->ftp->cwd( "$p{remote}" ) if defined $p{remote};
    $self->rc( $rc );
    $rc = $self->ftp->put( "$p{local}" );
    $self->rc( $rc );
    $self->_throw_on_error;
    $self->ret( $self->ftp->message );
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

sub execute {
    my $self = shift;
    _throw "FTP execute not implemented yet.";
}

# not used:
sub _build_uri {
    my ($self) = @_;
    my $uri = $self->uri;
    my ($conn) = $uri =~ m{//(.*?)(/.*)?$};
    return $conn if $conn;
    _throw _loc "Could not create connection from uri %1", $self->uri;
}

1;

