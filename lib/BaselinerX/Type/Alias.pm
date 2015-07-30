package BaselinerX::Type::Alias;
use Moose;
use Baseliner::Core::Registry ':dsl';
with 'Baseliner::Role::Registrable';

register_class 'alias' => __PACKAGE__;
has 'link' => ( is=>'rw', isa=>'Str', required=>1 );
no Moose;
__PACKAGE__->meta->make_immutable;

1;
