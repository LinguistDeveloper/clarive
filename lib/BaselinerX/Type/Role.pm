package BaselinerX::Type::Role;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

register_class 'role' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );



no Moose;
__PACKAGE__->meta->make_immutable;

1;
