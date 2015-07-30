package BaselinerX::Type::Generic;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

has 'config' => (is=>'rw', isa=>'Str', default=>'' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
