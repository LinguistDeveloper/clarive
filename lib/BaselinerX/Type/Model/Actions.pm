package BaselinerX::Type::Model::Actions;
use Moose;

use Clarive::cache;
use Baseliner::Core::Registry;
use Baseliner::Utils qw(_array);

sub list {
    my $self = shift;

    my $cached = cache->get('roles:actions:');
    return _array $cached if $cached;

    my @actions = Baseliner::Core::Registry->search_for( key => 'action.' );

    cache->set( 'roles:actions:' => \@actions );

    return @actions;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

