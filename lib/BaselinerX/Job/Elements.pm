package BaselinerX::Job::Elements;
use Moose;
use Baseliner::Utils;
use Try::Tiny;

has 'elements' => ( is=>'rw', isa=>'ArrayRef', default=>sub{ [] } );

=head2 push_elements [@elements|$element]

Pushes an array or a single element into the collection. 
    
    my $es = new BaselinerX::Job::Elements;
    # either like this:
    $es->push_element(  new BaselinerX::Job::Element(path=>'/xx/yy/ww', mask=>'/app/nat/sub' ) );
    # or this:
    $es->push_elements( @elements );

=cut
sub push_element { push_elements(@_) }

sub push_elements {
    my $self = shift;
    $self->elements( [ _array($self->elements) , @_ ] )
		if( scalar @_ );
}

sub recent_elements {
	my ( $self ) = @_;
	my @elements;
	my %hash = $self->hash;
	for my $element ( @_ ) {
		if( $hash{ $element->long_path } ) {
			if( $self->is_more_recent( $element ) ) { 
				push @elements, $element;
			}
		} else {
			push @elements, $element;
		}
	}
	return @elements;
}

sub hash_by_path {
	my ( $self ) = @_;
	my %hash;
	for my $element ( _array $self->elements ) {
		my $key = $element->long_path;
		$hash{ $key } = $element;	
	}
	return %hash;
}

sub hash_by_version {
	my ( $self ) = @_;
	my %hash;
	for my $element ( _array $self->elements ) {
		my $key = $element->long_path;
		$hash{ $key } = $element;	
	}
	return %hash;
}

=head2 list_part

Returns an array of unique path parts based on the part name passed as argument.

    my $es = new BaselinerX::Job::Elements;
    $es->push_element(  new BaselinerX::Job::Element(path=>'/xx/yy/ww', mask=>'/app/nat/sub' ) );
    my @applications = $es->list_part('app');
    my @natures = $es->list_part('nat');

=cut
sub list_part {
    my $self = shift;
    my $part = shift;
    if( $part) {
        my @list;
        for my $e ( @{ $self->elements } ) {
            my %parts = $e->path_parts;
            push @list, $parts{$part} if $parts{$part};
            try {  ## may die if method $part doesn't exist
				if( $e->meta->has_method($part) ) {
					push @list, $e->$part;
				}
            } catch {};
        }
        return _unique @list; 
    } else {
        return @{ $self->elements || [] };
    }
}
sub list { list_part(@_) }

=head2 cut_to_subset (part, value)

Returns a new Elements collective reduced to a subset.

    my $elements = new BaselinerX::Job::Elements;
    $elements->cut_to_subset( 'nature', 'J2EE' );
    
=cut
sub cut_to_subset {
    my $self = shift;
    my $part = shift;
    my $value = shift;
    return __PACKAGE__->new( elements=>[ $self->subset( $part, $value ) ] );
}

=head2 count
    
Returns the number of elements.

=cut
sub count {
    my $self = shift;
    return scalar @{ $self->elements };
}

=head2 subset (part, value)

Returns an array of elements. 

=cut
sub subset {
    my ($self, $part, $value ) = @_;
    my @subset;
    for my $e ( @{ $self->elements } ) {
        my %parts = $e->path_parts;
        if( $parts{$part} eq $value ) {
            push @subset, $e;
        } else {
			next unless $e->meta->has_method($part);
            eval {  ## may die if method $part doesn't exist
                push @subset, $e if $e->$part eq $value;
            };
        }
    }
    return @subset;
}

=head2 split_by_extension

Given an array of extensions (without the dot), returns 2 lists,
the matching one, and the no-matching.

my( $elems_con, $elems_sin ) = $elements->split_by_extension( 'java', 'jar' );
if( $elems_con->count > 0 ) { hay ear }
elsif( $elems_sin->count > 0 ) { hay parcial }


=cut 

sub split_by_extension {
    my ($self, @exts ) = @_;
    my (@match,@unmatch);
	my $exts_str = '(.' . join( '$)|(.', @exts ) . ')';
	my $re = qr/$exts_str/;
    for my $e ( _array $self->elements ) {
		if( $e->name =~ $re ) { push( @match, $e ); next }
		push @unmatch, $e;
    }
    my $matching = __PACKAGE__->new( elements=>\@match );
    my $unmatching = __PACKAGE__->new( elements=>\@unmatch );
    return $matching, $unmatching;
}

1;
