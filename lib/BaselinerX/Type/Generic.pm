package BaselinerX::Type::Generic;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

has 'config' => (is=>'rw', isa=>'Str', default=>'' );

1;
