package BaselinerX::Job::Element;
use Moose::Role;

has 'name' => ( is=>'rw', isa=>'Str', required=>1 );
has 'path' => ( is=>'rw', isa=>'Str', trigger=>sub { my ($self,$val)=@_; $val=~s{\\}{\/}g; $self->{path} = $val; }  );
has 'mask' => ( is=>'rw', isa=>'Str' );
has 'version' => ( is=>'rw', isa=>'Str' );
has 'modified_on' => ( is=>'rw', isa=>'DateTime' );
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

sub long_path {
	my $self = shift;
	my $long_path = $self->path . '/' . $self->name . ';' . $self->version;
	$long_path =~ s{\\}{\/}g;
	return $long_path;
}


sub path_part {
    my ($self,$part) = @_;
    my %parts = $self->path_parts;
    return $parts{$part};
}

1;
