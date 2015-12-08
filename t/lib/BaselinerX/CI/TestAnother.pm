package BaselinerX::CI::TestAnother;
use Moose;

with 'Baseliner::Role::CI';

sub icon {'icon_another'}

has something => qw(is rw isa Any default 333);

1;

