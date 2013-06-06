package Baseliner::Role::CI::Group;
use Moose::Role;

with 'Baseliner::Role::CI';

sub each {
    my ($self,$cb) = @_;
    for( @{ $self->children || [] } ) {
        $cb->( $_ );
    }
}



1;
