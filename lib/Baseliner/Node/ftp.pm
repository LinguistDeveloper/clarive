package Baseliner::Node::ftp;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::Node::Filesys';

has ftp => ( is=>'rw', isa=>'Net::FTP', required=>1, lazy=>1,
    default => sub {
        my $self = shift;
        require Net::FTP;
        Net::FTP->new( $self->_build_uri ) or die $!;
    }
);

sub put_file {
    my ($self, %p) = @_;
    $self->ftp->put( $p{remote}, $p{local} );
}

sub get_file {
    my ($self, %p) = @_;
    $self->ftp->get( $p{local}, $p{remote} );
}

sub get_dir {
    my ($self, %p) = @_;
    $self->ftp->get( $p{local}, $p{remote} );
}

sub put_dir {
    my ($self, %p) = @_;
    $self->ftp->put( $p{remote}, $p{local} );
}

sub execute {
    my $self = shift;
    _throw "FTP execute not implemented yet.";
}

sub _build_uri {
    my ($self) = @_;
    my $uri = $self->uri;
    my ($conn) = $uri =~ m{//(.*?)(/.*)?$};
    return $conn if $conn;
    _throw _loc "Could not create connection from uri %1", $self->uri;
}

1;

