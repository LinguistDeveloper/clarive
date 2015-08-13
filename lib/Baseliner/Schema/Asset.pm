package Baseliner::Schema::Asset;
use Moose;
use Baseliner::Utils qw(_fail _loc _error _debug _throw _log _array _dump);

has fh       => qw(is rw isa Any required 1);
has grid     => qw(is rw isa Any required 1);
has id       => qw(is rw isa MongoDB::OID);
has filename => qw(is rw isa Str default noname);

has parent => qw(is rw isa Any), default=>'';
has parent_mid => qw(is rw isa Any), default=>'';
has parent_collection => qw(is rw isa Any), default=>'';

around BUILDARGS => sub {
    my ($orig,$self,$in,%opts) = @_;
    $in //= '';
    my $fh;
    if( !ref $in ) {
        # open the string like a file
        my $basic_fh;
        open($basic_fh, '<', \$in) or _fail _loc 'Error trying to open string asset: %1', $!;
        # turn the file handle into a FileHandle
        $fh = FileHandle->new;
        $fh->fdopen($basic_fh, 'r');
    }
    elsif( ref $in eq 'Path::Class::File' ) {
        $fh = $in->open('r');
    }
    elsif( ref $in eq 'GLOB' ) {
        $fh = $in;
    }
    else {
        # open the string like a file
        my $basic_fh;
        open($basic_fh, '<', \$in);
        # turn the file handle into a FileHandle
        $fh = FileHandle->new;
        $fh->fdopen($basic_fh, 'r');
    }
    
    _fail _loc 'Could not get filehandle for asset' unless $fh; 
    
    $self->$orig( fh=>$fh, %opts );
};

sub insert {         
    my ($self,%p) = @_;
    # $grid->insert($fh, {"filename" => "mydbfile"});
    # TODO match md5, add mid to asset in case it exists
    my $md5 = Util->_md5( $self->fh );
    my $id = $self->grid->insert($self->fh, { 
            filename=>$self->filename, 
            md5=>$md5, parent_mid=>$self->parent_mid, 
            parent_collection=>$self->parent_collection, 
            parent => $self->parent,
            %p });
    $self->id( $id );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
