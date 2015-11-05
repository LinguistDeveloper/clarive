package BaselinerX::CI::TestParentClass;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI';

has_cis 'kids';

sub icon {'123'}

sub rel_type { { kids => [ from_mid => 'parent_kid' ], }, }

1;