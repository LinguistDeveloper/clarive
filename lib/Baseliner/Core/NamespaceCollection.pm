package Baseliner::Core::NamespaceCollection;
=head1 DESCRIPTION

A collection of items with the namespace role.

=cut 
use Moose;
use Baseliner::Utils;

#TODO 1) BUILDARGS for creating a collection out of another collection
#TODO 2) create a rs pointer type collection, then invoke next on each one

has 'data' => ( is=>'rw', isa=>'ArrayRef[Baseliner::Role::Namespace]', default=>sub {[]} );
has 'total' => ( is=>'rw', isa=>'Int', default=>0 );
has 'count' => ( is=>'rw', isa=>'Int', default=>0 );

sub next {  }

=head2 search

Normal:
	$list->search( name => 'jack' );

Negate:
	$list->search( name => \'jack' );

=cut 
sub search {
	my ($self, %p ) = @_;
	return $self unless keys %p;
	my @ns;
	foreach my $key ( keys %p ) {
		my $negate = ref $p{$key} eq 'SCALAR' ;
		my $value = $negate ? ${$p{$key}} : $p{$key};
		my $is_attr = $key =~ s/^\{(.*)\}$/$1/g;
		push @ns, $is_attr
			? grep { $negate xor ( $_->{$key} =~ $value ) } $self->list
			: grep { $negate xor ( $_->$key =~ $value ) } $self->list;
	}
	return @ns if wantarray;
	return __PACKAGE__->new({ data=>\@ns, count=>scalar(@ns), total=>scalar(@ns) });
}

sub sort {
	my ($self, %p ) = @_;
	my $on = $p{on};
	my $reverse = $p{'reverse'};
	return $self unless $on;
	my $is_attr = $on =~ s/^\{(.*)\}$/$1/g;
	my $foo = $is_attr ? sub{ $a->{$on} cmp $b->{$on} } : sub{ $a->$on cmp $b->$on };
	my @ns = sort $foo $self->list;
	@ns = reverse @ns if $reverse;
	return @ns if wantarray;
	return __PACKAGE__->new({ data=>\@ns, count=>scalar(@ns), total=>scalar(@ns) });
}

sub list {
	my $self = shift;
	return _array( $self->data );
}

1;
