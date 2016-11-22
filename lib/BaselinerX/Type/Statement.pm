package BaselinerX::Type::Statement;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;

has palette_area => qw(is rw default control);
has dsl => ( is => 'rw', isa => 'CodeRef', required => 1 );

with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'statement' => __PACKAGE__;

sub service_noun { 'statement' }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
