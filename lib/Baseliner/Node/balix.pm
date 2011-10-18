package Baseliner::Node::balix;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::Node::Filesys';

has ssh => ( is=>'rw', isa=>'BaselinerX::Comm::Balix', required=>1, lazy=>1,
    default => sub {
        my $self = shift;
        require BaselinerX::Comm::Balix;
        BaselinerX::Comm::Balix->new( $self->_build_uri );
    }
);

sub put_file {
    my ($self, %p) = @_;
}

sub get_file {
    my ($self, %p) = @_;
}

sub get_dir {
    my ($self, %p) = @_;
}

sub put_dir {
    my ($self, %p) = @_;
}

sub execute {
    my $self = shift;
    $self->ssh->system( @_ );
    ...
}

sub _build_uri {
    my ($self) = @_;
    my $uri = $self->uri;
    my ($conn) = $uri =~ m{//(.*?)(/.*)?$};
    return $conn if $conn;
    _throw _loc "Could not create connection from uri %1", $self->uri;
}

1;
