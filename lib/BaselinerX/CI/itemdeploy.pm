package BaselinerX::CI::itemdeploy;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Mapping';

has projects => qw(is rw isa CIs coerce 1);
has deployments => qw(is rw isa CIs coerce 1);

#sub storage { 'BaliRepo' }

#has repositories => qw(is rw isa CIs coerce 1);
sub rel_type { { deployments => [ from_mid => 'itemdeploy_deployment' ], projects => [ to_mid=>'project_itemdeploy' ] } }

1;

