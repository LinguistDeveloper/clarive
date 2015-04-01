package BaselinerX::Type::Statement;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Registrable';
with 'Baseliner::Role::Palette';

register_class 'statement' => __PACKAGE__;

sub service_noun { 'statement' }

1;
