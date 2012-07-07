package BaselinerX::Job::Element;
use Moose::Role;
use Moose::Util::TypeConstraints;

has 'name' => ( is=>'rw', isa=>'Str', required=>1 );
has 'path' => ( is=>'rw', isa=>'Str', trigger=>sub { my ($self,$val)=@_; $val=~s{\\}{\/}g; $self->{path} = $val; }  );
has 'status' => (is=>'rw', isa=>enum([ qw(A M D R) ]), default=>'M' );  # Modified, Deleted, Renamed
has 'mask' => ( is=>'rw', isa=>'Str' );
has 'version' => ( is=>'rw', isa=>'Str' );
has 'modified_on' => ( is=>'rw', isa=>'DateTime' );
has 'mid' => ( is=>'rw', isa=>'Str' );
has 'handled_by' => (
	is=>'ro',
	isa=>'ArrayRef[Str]',
	default    => sub { [] },
	traits=>['Array'],
	handles => {
		'add_handler' => 'push',
		'count_handler' => 'count',
		'has_handler' => 'is_empty',
	}
);

sub path_parts {
    my $self = shift;
    my @mask = grep /.+/, split /\//, $self->mask;
    my @path = grep /.+/, split /\//, $self->path;
    my %parts;
    foreach my $m ( @mask ) {
        next unless $m;
        $parts{ $m } = shift @path;
    }
    return %parts;
}

=head2 long_path

Returns the full path to the file plus a semicolon plus the 
version number.

    /path/to/file.txt;23

=cut
sub long_path {
	my $self = shift;
	my $long_path = $self->path . '/' . $self->name . ';' . $self->version;
	$long_path =~ s{\\}{\/}g;
	return $long_path;
}


=head2 long_path

Returns a hash of path parts, according to the mask defined.

    filepath: /foo/java/testJava/file.java
    mask    : /app/tech/prj
    
Becomes:

    app   => 'foo',
    tech  => 'java',
    prj   => 'testJava',

B<DEPRECATION WARNING>: under consideration. The
mask system is unflexible and unreliable. Avoid this 
method whenever possible.

=cut
sub path_part {
    my ($self,$part) = @_;
    my %parts = $self->path_parts;
    return $parts{$part};
}

=head2 filepath

Returns the fullpath to the file, including the name

    /path/to/file.txt

=cut
sub filepath {
	my $self = shift;
    require File::Spec;
    return File::Spec::Unix->catfile( $self->path, $self->name );
}

1;
