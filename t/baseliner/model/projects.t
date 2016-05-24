use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils;

use_ok 'Baseliner::Model::Projects';

subtest 'get_all_projects: return all projects without bls' => sub {
    _setup();

    my $model = _build_model();
    TestUtils->create_ci_project();
    TestUtils->create_ci_project();

    my @projects = $model->get_all_projects();
    my $icon     = BaselinerX::CI::project->icon;

    cmp_deeply \@projects, [
        {
            'bl'      => '',
            'bls'     => [],
            'icon'    => $icon,
            'mid'     => ignore(),
            'moniker' => undef,
            'name'    => "Project",

        },
        {
            'bl'      => '',
            'bls'     => [],
            'icon'    => $icon,
            'mid'     => ignore(),
            'moniker' => undef,
            'name'    => "Project",
        },
    ];
};

subtest 'get_all_projects: return all projects with bls' => sub {
    _setup();

    my $model = _build_model();

    my $bl  = TestUtils->create_ci( 'bl', bl => 'TEST' );
    my $bl2 = TestUtils->create_ci( 'bl', bl => 'PRE' );
    TestUtils->create_ci_project( bls => [ $bl->mid ] );
    TestUtils->create_ci_project( bls => [ $bl2->mid ] );
    my @projects = $model->get_all_projects();
    my $icon     = BaselinerX::CI::project->icon;

    cmp_deeply \@projects, [
        {
            'bl'      => $bl->name,
            'bls'     => [ $bl->mid ],
            'icon'    => $icon,
            'mid'     => ignore(),
            'moniker' => undef,
            'name'    => "Project",

        },
        {
            'bl'      => $bl2->name,
            'bls'     => [ $bl2->mid ],
            'icon'    => $icon,
            'mid'     => ignore(),
            'moniker' => undef,
            'name'    => "Project",
        },
    ];
};

done_testing;

sub _setup {
    TestUtils->setup_registry('BaselinerX::CI');
    TestUtils->cleanup_cis();
    TestUtils->register_ci_events();
}

sub _build_model {
    return Baseliner::Model::Projects->new();
}
