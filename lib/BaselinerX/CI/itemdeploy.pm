package BaselinerX::CI::itemdeploy;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Mapping';

has name           => qw(is rw isa Maybe[Str]);
has bl             => qw(is rw isa Any);
has projects       => qw(is rw isa CIs coerce 1);
has workspace      => qw(is rw isa Maybe[Str]);
has deployments    => qw(is rw isa CIs coerce 1);
has scripts_multi  => qw(is rw isa CIs coerce 1);
has scripts_single => qw(is rw isa CIs coerce 1);
has exclude        => qw(is rw isa Any);
has include        => qw(is rw isa Any);
has order          => qw(is rw isa Num);
has no_paths       => qw(is rw isa BoolCheckbox coerce 1);
has path_deploy    => qw(is rw isa BoolCheckbox coerce 1);

sub rel_type {
    {
        deployments    => [ from_mid => 'itemdeploy_deployment' ],
        scripts_single => [ from_mid => 'itemdeploy_script_single' ],
        scripts_multi  => [ from_mid => 'itemdeploy_script_multi' ],
        projects       => [ to_mid   => 'project_itemdeploy' ],
    };
}

1;

