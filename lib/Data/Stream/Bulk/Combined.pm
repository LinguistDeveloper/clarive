package Data::Stream::Bulk::Combined;
use Moose;
use MooseX::AttributeHelpers;

use namespace::clean -except => 'meta';
with 'Data::Stream::Bulk';

has '_current_stream' => ( is=>'rw', isa=>'Int', default=>-1 );

has 'streams' => (
      metaclass => 'Collection::List',
	  is=>'rw',
	  isa=>'ArrayRef[Any]',
	  default=>sub{[]}, 
	  provides => { 'count' => 'stream_count', }
);

has 'leftover' => (
      metaclass => 'Collection::Array',
	  is=>'rw',
	  isa=>'ArrayRef[Any]',
	  default=>sub{[]}, 
	  provides => { 'push' => 'push', }
);

has 'filters' => (
      metaclass => 'Collection::Array',
	  is=>'rw',
	  isa=>'ArrayRef[HashRef]',
	  default=>sub{[]}, 
	  provides => {
	  	   'push' => 'add_filter',
	  }
);

sub filter {
	my $self = shift;
	$self->add_filter({ @_ });
}


sub is_done {
	my $self = shift;
	for my $stream ( @{ $self->streams } ) {
		return 0 unless $stream->is_done;
	}
	return 1;
}

sub bulk {
	my $self = shift;
	my $rows = shift; 
	my @items = @_;

	my $total_streams = scalar( @{ $self->streams } );
	my $max_rows = ( $total_streams * $rows );

	# use leftover
	push @items, @{ $self->leftover };

	# grab max rows from all streams
	BULK: until( $self->is_done ) {
		foreach my $item ( $self->items ) {
			push @items, $item;
			last BULK if @items >= $max_rows;
		}
	}
	return @items;
}

sub page {
	my $self = shift;
	my %args = @_;
	my @items;

	# get max items
	@items = $self->bulk( $args{rows} );

	# filter them
	my @filtered = $self->run_filters( @items );

	# get topmost - which will be returned
	my @top = @filtered[ 0 .. $args{rows}-1 ];

	# extract topmost from the bottom
	my %index; @index{ @top }=(); 
	my @bottom = grep !exists($index{$_}), @items; 
	$self->leftover( \@bottom );

	return @top;
}

sub next_stream {
	my $self = shift;

	return () unless $self->stream_count;

	my $index = $self->_current_stream + 1;
	$self->_current_stream( $index == $self->stream_count ? 0 : $index );
	return $self->streams->[ $self->_current_stream ];
}

sub mesh {
	my $self = shift;

	# individual maxes
	my %limit; @limit{ @_ } = map $#$_, @_;

	# global max
    my $max = -1;
    $max < $_  &&  ($max = $_)  for values %limit;

    #$max < $#$_  &&  ($max = $#$_)  for @_;
    #map { my $ix = $_; map $_->[$ix], grep defined $_->[$ix], @_; } 0..$max; 
    map { my $ix = $_; map $_->[$ix], grep $ix <= $limit{$_}, @_; } 0..$max; 
}

sub next {
	my $self = shift;
	my @stream_items;
	for my $stream ( @{ $self->streams } ) {
		next if $stream->is_done;
		push @stream_items, $stream->next;
	}
	return [ $self->mesh( @stream_items ) ];
}	

sub run_filters {
	my $self = shift;
	my @items = @_;
	my @ret;
	foreach my $filter ( @{ $self->filters } ) {
		if( exists $filter->{'sort'} ) {
			my $coderef = $filter->{'sort'};
			next unless ref $coderef eq 'CODE';
			@items = sort { $coderef->($a,$b) } @items;
		}
		if( exists $filter->{'grep'} ) {
			my $coderef = $filter->{'grep'};
			next unless ref $coderef eq 'CODE';
			@items = grep { $coderef->($_) } @items;
		}
		if( exists $filter->{'map'} ) {
			my $coderef = $filter->{'grep'};
			next unless ref $coderef eq 'CODE';
			@items = map { $coderef->($_) } @items;
		}
	}
	return @items;
}

1; 
