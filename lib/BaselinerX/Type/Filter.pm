package BaselinerX::Type::Filter;
use Baseliner::Plug;
use Baseliner::Utils;
with 'Baseliner::Core::Registrable';
extends 'BaselinerX::Type::Service';
register_class 'filter' => __PACKAGE__;

sub service_noun { 'filter' };

1;
