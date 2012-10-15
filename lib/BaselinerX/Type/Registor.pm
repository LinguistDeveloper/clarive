package BaselinerX::Type::Registor;
use Baseliner::Plug;
with 'Baseliner::Core::Registrable';

register_class 'registor' => __PACKAGE__;

has id=> (is=>'rw', isa=>'Str', default=>'');
has name => ( is=> 'rw', isa=> 'Str' );
has generator => ( is=> 'rw', isa=> 'CodeRef' );

1;

