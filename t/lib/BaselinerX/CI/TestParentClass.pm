package BaselinerX::CI::TestParentClass;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI';

has_ci 'the_kid';
has_cis 'kids';

sub icon {'icon123'}

sub rel_type { { kids => [ from_mid => 'parent_kids' ], the_kid => [ from_mid => 'parent_kid' ], }, }

1;
