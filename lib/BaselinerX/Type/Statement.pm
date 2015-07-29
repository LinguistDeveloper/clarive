package BaselinerX::Type::Statement;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'statement' => __PACKAGE__;

sub service_noun { 'statement' }

1;
