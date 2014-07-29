package BaselinerX::Type::Portlet;
use Baseliner::PlugMouse;
use Baseliner::Utils;

with 'Baseliner::Role::Registrable';

register_class 'portlet' => __PACKAGE__;

has 'id'=> (is=>'rw', isa=>'Str', default=>'');
has 'name' => ( is=> 'rw', isa=> 'Str' );
has 'url' => ( is=> 'rw', isa=> 'Str' );
has 'url_comp' => ( is=> 'rw', isa=> 'Str' );
has 'url_max' => ( is=> 'rw', isa=> 'Str' );
has 'title' => ( is=> 'rw', isa=> 'Str' );
has 'column' => ( is=> 'rw', isa=> 'Int', default=>0 );
has 'icon' => ( is=> 'rw', isa=> 'Str' );
has 'active' => (is=>'rw', isa=>'Bool', default=>1 );

1;

