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
        $ftp->login( $self->resource->user, $self->resource->password )
            or _fail $ftp->message;
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
    $self->ftp->cd( $p{remote} );
    $self->ftp->put( $p{local} );
    $self->ftp->message;
}

sub put_dir {
    my ($self, %p) = @_;
    $self->ftp->put( $p{local}, $p{remote} );
    $self->ftp->message;
}

sub get_file {
    my ($self, %p) = @_;
    $self->ftp->get( $p{remote}, $p{local} );
    $self->ftp->message;
}

sub get_dir {
    my ($self, %p) = @_;
    $self->ftp->get( $p{remote}, $p{local} );
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

