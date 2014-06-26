=head1 asset

asset is a file stored in Clarive's db.

An asset may be in many folders. May belong to projects. 
May be attached to topics.

=cut
package BaselinerX::CI::asset;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Item';

has id_data => qw(is rw isa Maybe[MongoDB::OID]);

sub icon { '/static/images/icons/file.gif' }
sub ci_form { '/ci/item.js' }

#has _lines => qw(is rw isa ArrayRef lazy 1), default=>sub{
#    my ($self)=@_;
#    my @lines = Util->_file( $self->path )->slurp ;
#    \@lines;
#};

#service 'view_source' => 'View Source' => sub {
#    my ($self) = @_;
#    $self->source;
#};

sub put_data {
    my ($self,$d)=@_;
    Util->_fail( Util->_loc( 'MID missing. To put asset data CI must be saved first' ) ) unless $self->mid;
    if( $self->id_data ) {
        mdb->grid->remove({ _id=>$self->id_data });
    }
    my $id = do { 
        if( ref $d eq 'GLOB' ) {
            mdb->grid->put( $d, { parent_mid=>$self->mid, parent_collection=>'asset' });
        } else {
            my $ass = mdb->asset( $d, parent_mid=>$self->mid, parent_collection=>'asset' );
            $ass->insert;
            $ass->id;
        }
    };
    Util->_fail( Util->_loc('Could not insert asset') ) unless $id;
    $self->update( id_data=>$id );
    return $id;
}

sub info {
    my($self)=@_;
    return {} unless $self->id_data;
    my $f = mdb->grid->get( $self->id_data );
    return {} unless $f;
    return $f->info // {};
}

sub slurp {
    my ($self)=@_;
    return unless $self->id_data;
    my $f = mdb->grid->get( $self->id_data );
    return unless $f;
    return $f->slurp;
}

sub done_slurping {
    my $self = shift;
    delete $self->{_body};
    $self->_lines([]);
}

sub source {
    my($self)=@_;
    return scalar $self->slurp;
}

sub filename { $_[0]->name }
sub filesize { 0 }   # XXX mdb

1;



