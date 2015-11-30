package BaselinerX::CI::TestClass;
use Moose;

with 'Baseliner::Role::CI';

sub icon {'123'}

has something => qw(is rw isa Any default 111);

1;
