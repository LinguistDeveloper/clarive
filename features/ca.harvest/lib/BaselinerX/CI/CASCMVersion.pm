package BaselinerX::CI::CASCMVersion;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Item';
with 'Baseliner::Role::Service';

has itemobjid        => qw(is rw isa Num required 1);
has versionobjid     => qw(is rw isa Num required 1);
has viewpath         => qw(is rw isa Str required 1);
has versionobjid     => qw(is rw isa Num required 1);
has versiondataobjid => qw(is rw isa Num required 1);
has compressed       => qw(is rw isa Bool default 1);

service 'view_source' => 'View Source' => sub {
    my ($self) = @_;
    $self->source;
};

sub source {
    my ($self) = @_;
    my $db = Baseliner::Core::DBI->new( model=>'Harvest' );
    # retrieve file contents
    my $data = $db->value(q{select versiondata from harversiondata where versiondataobjid = ?}, $self->versiondataobjid );
    if( $self->compressed ) {
        require Compress::Zlib;
        $data = Compress::Zlib::uncompress($data);
    }
    return $data;
}

1;
