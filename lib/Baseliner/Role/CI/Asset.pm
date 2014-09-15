package Baseliner::Role::CI::Asset;
use Moose::Role;
with 'Baseliner::Role::CI';

has id_data => qw(is rw isa Maybe[MongoDB::OID]);

sub get_data {
    my ($self)=@_;
    return unless $self->id_data;
    return mdb->grid->get( $self->id_data );  # may have utf8 issues and need a utf8::decode? see post.pm
}

sub put_data {
    my ($self,$d)=@_;
    Util->_fail( Util->_loc( 'MID missing. To put asset data CI must be saved first' ) ) unless $self->mid;
    if( $self->id_data ) {
        mdb->grid->remove({ _id=>$self->id_data });
    }
    my $cn = Util->to_base_class( $self );
    my $ass = mdb->asset( $d, parent_mid=>$self->mid, parent_collection=>$cn );
    $ass->insert;
    my $id = $ass->id;
    $self->update( id_data=>$id );
    return $id;
}

1;
