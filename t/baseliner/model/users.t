use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::Model::Users';

subtest 'get_projectnames_and_descriptions_from_user: return a project name with description' => sub {
    _setup();

    my $model = _build_model();

    my $project       = TestUtils->create_ci_project( description => 'test project description' );
    my $id_role       = TestSetup->create_role();
    my $user          = TestSetup->create_user( id_role => $id_role, project => $project );
    my @project_names = $model->get_projectnames_and_descriptions_from_user( $user->name, 'project' );

    cmp_deeply \@project_names,
      [
        {
            'bl'          => ignore(),
            'bls'         => ignore(),
            'icon'        => ignore(),
            'mid'         => ignore(),
            'moniker'     => ignore(),
            'collection'  => "project",
            'name'        => "Project",
            'description' => "test project description",
        },
      ];
};

subtest 'get_projectnames_and_descriptions_from_user: return a project and description with for project and area' =>
  sub {
    _setup();

    my $model = _build_model();

    my $project = TestUtils->create_ci_project( description => 'test project description' );
    my $area    = TestUtils->create_ci( 'area', name => "Area", description => 'test area description' );
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user(
        id_role          => $id_role,
        project          => $project,
        project_security => {
            $id_role => {
                project => [ $project->mid ],
                area    => [ $area->mid ]
            }
        }
    );

    my @project_names = $model->get_projectnames_and_descriptions_from_user( $user->name, 'project,area' );

    cmp_deeply \@project_names,
      [
        {
            'bl'          => ignore(),
            'bls'         => ignore(),
            'icon'        => ignore(),
            'mid'         => ignore(),
            'moniker'     => ignore(),
            'collection'  => "area",
            'name'        => "Area",
            'description' => "test area description",
        },
        {
            'bl'          => ignore(),
            'bls'         => ignore(),
            'icon'        => ignore(),
            'mid'         => ignore(),
            'moniker'     => ignore(),
            'collection'  => "project",
            'name'        => "Project",
            'description' => "test project description",
        }
      ];
  };

done_testing;

sub _setup {
    TestUtils->setup_registry('BaselinerX::CI');
    TestUtils->cleanup_cis();
    TestUtils->register_ci_events();
}

sub _build_model {
    return Baseliner::Model::Users->new();
}
