package BaselinerX::Type::Alias;
use Baseliner::Plug;
with 'Baseliner::Role::Registrable';

register_class 'alias' => __PACKAGE__;
has 'link' => ( is=>'rw', isa=>'Str', required=>1 );
1;