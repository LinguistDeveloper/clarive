package BaselinerX::Type::Registor;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

register_class 'registor' => __PACKAGE__;

has id=> (is=>'rw', isa=>'Str', default=>'');
has name => ( is=> 'rw', isa=> 'Str' );
has generator => ( is=> 'rw', isa=> 'CodeRef' );

1;

