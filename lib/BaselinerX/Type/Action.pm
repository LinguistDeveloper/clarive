package BaselinerX::Type::Action;
use Moose;

with 'Baseliner::Role::Registrable';

use Baseliner::Core::Registry ':dsl';

register_class 'action' => __PACKAGE__;

my %CACHE = ();

has 'id' => ( is => 'rw', isa => 'Str', default => '' );
has 'name'        => ( is => 'rw', isa => 'Str' );
has 'description' => ( is => 'rw', isa => 'Str' );

has 'bounds'     => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'depends'    => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'extends'    => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'extensions' => ( is => 'rw', isa => 'ArrayRef', default => sub { my $self = shift; $CACHE{$self->key} // [] }, lazy => 1 );

sub BUILD {
    my $self = shift;

    if (my $parents = $self->extends) {
        foreach my $parent (@$parents) {
            my $instance = $self->registry->get($parent);
            next unless $instance && blessed $instance;

            push @{ $CACHE{$parent} }, $self->key;
        }
    }

    return $self;
}

sub add_extension {
    my $self = shift;
    my ($child) = @_;

    push @{ $self->extensions }, $child;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
