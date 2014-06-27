=head1 asset

asset is a file stored in Clarive's db.

An asset may be in many folders. May belong to projects. 
May be attached to topics.

=cut
package BaselinerX::CI::asset;
use Baseliner::Moose;

sub icon { '/static/images/icons/post.png' }

with 'Baseliner::Role::CI::Item';
with 'Baseliner::Role::CI::CCMDB';

has id_data => qw(is rw isa Maybe[MongoDB::OID]);

sub ci_form { '/ci/item.js' }

sub put_data {
    my ($self,$d)=@_;
    Util->_fail( Util->_loc( 'MID missing. To put asset data CI must be saved first' ) ) unless $self->mid;
    if( $self->id_data ) {
        mdb->grid->remove({ _id=>$self->id_data });
    }
    my $id = do { 
        if( ref($d) =~ /GLOB|IO::File/ ) {
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

method grid_file {
    mdb->grid->get( $self->id_data );
}

sub info {
    my($self)=@_;
    return {} unless $self->id_data;
    my $f = $self->grid_file;
    return {} unless $f;
    return $f->info // {};
}

sub filesize { shift->info->{length} }

sub slurp {
    my ($self)=@_;
    return unless $self->id_data;
    my $f = $self->grid_file;
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

=head2 checkout 

Used by ChangesetServices to checkout topic
attachments during a job.

=cut 
method checkout( :$dir ) {
    my $dest = Util->_file($dir,$self->path);
    $dest->dir->mkpath;
    open( my $ff, '>:raw', $dest) or Util->_fail( Util->_loc("Could not checkout topic file '%1'", $dest) );
    $self->grid_file->print( $ff );
    close $ff;
    1;
}

1;



