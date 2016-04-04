package Baseliner::Role::CI::Asset;
use Moose::Role;
with 'Baseliner::Role::CI';

has id_data => qw(is rw isa Maybe[MongoDB::OID]);

use Encode ();

sub get_data {
    my ($self) = @_;

    return unless $self->id_data;

    # This returns bytes, so the client must decode
    return mdb->grid->get( $self->id_data );
}

sub put_data {
    my ( $self, $d ) = @_;

    Util->_fail( Util->_loc('MID missing. To put asset data CI must be saved first') ) unless $self->mid;

    if ( Encode::is_utf8($d) ) {
        $d = Encode::encode( 'UTF-8', $d );
    }

    if ( $self->id_data ) {
        mdb->grid->remove( { _id => $self->id_data } );
    }

    my $cn = Util->to_base_class($self);

    # This accepts bytes
    my $id = mdb->grid_add( $d, parent_mid => $self->mid, parent_collection => $cn );

    $self->update( id_data => $id );

    return $id;
}

1;
