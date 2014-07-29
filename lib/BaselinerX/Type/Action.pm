package BaselinerX::Type::Action;
use Baseliner::PlugMouse;
with 'Baseliner::Role::Registrable';

register_class 'action' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'description' => ( is=> 'rw', isa=> 'Str' );



1;
