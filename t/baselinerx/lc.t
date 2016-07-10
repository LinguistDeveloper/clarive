use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use_ok 'BaselinerX::Lc';

subtest 'lc_for_project: returns job node when user has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.view_monitor' } ] );
    my $user    = _create_user_with_actions( id_role => $id_role );

    my $lc = _build_lc();

    my $data = $lc->lc_for_project( $project->mid, $project, $user->username );

    my ($job_node) = grep { $_->{node} eq 'Jobs' } @$data;

    ok $job_node;
};

subtest 'lc_for_project: does not return job node when user does not have permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = _create_user_with_actions( id_role => $id_role );

    my $lc = _build_lc();

    my $data = $lc->lc_for_project( $project->mid, $project, $user->username );

    my ($job_node) = grep { $_->{node} eq 'Jobs' } @$data;

    ok !$job_node;
};

subtest 'lc_for_project: returns repos node when user has permission' => sub {
    _setup();

    my $repo = TestUtils->create_ci('GitRepository', name => 'Repo');
    my $project = TestUtils->create_ci_project(repositories => [$repo->mid]);
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.home.view_project_repos' } ] );
    my $user    = _create_user_with_actions( id_role => $id_role );

    my $lc = _build_lc();

    my $data = $lc->lc_for_project( $project->mid, $project, $user->username );

    my ($repo_node) = grep { $_->{node} eq 'Repo' } @$data;

    ok $repo_node;
};

subtest 'lc_for_project: does not return repos node when user does not have permission' => sub {
    _setup();

    my $repo = TestUtils->create_ci('GitRepository', name => 'Repo');
    my $project = TestUtils->create_ci_project(repositories => [$repo->mid]);
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = _create_user_with_actions( id_role => $id_role );

    my $lc = _build_lc();

    my $data = $lc->lc_for_project( $project->mid, $project, $user->username );

    my ($repo_node) = grep { $_->{node} eq 'Repo' } @$data;

    ok !$repo_node;
};

subtest 'lc_for_project: returns project topic states node when user has permission' => sub {
    _setup();

    my $bl = TestUtils->create_ci('bl', bl => 'QA');

    my $project = TestUtils->create_ci_project(bls => [$bl->mid]);
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.project.see_lc' } ] );
    my $user    = _create_user_with_actions( project => $project, id_role => $id_role );

    my $status_from = TestUtils->create_ci('status', name => 'New');
    my $status_to = TestUtils->create_ci('status', name => 'End', type => 'D', bls => [$bl->mid]);

    my $workflow =
      [ { id_role => $id_role, id_status_from => $status_from->mid, id_status_to => $status_to->mid, job_type => undef } ];
    my $id_category = TestSetup->create_category(
        workflow => $workflow,
        statuses => [ $status_from->mid, $status_to->mid ]
    );

    my $lc = _build_lc();

    my $data = $lc->lc_for_project( $project->mid, $project, $user->username );

    ok grep { $_->{type} eq 'state' && $_->{node} eq 'New' } @$data;
};

done_testing;

sub _build_lc {
    BaselinerX::Lc->new;
}

sub _create_user_with_actions {
    my (%params) = @_;

    my $project = $params{project} || TestUtils->create_ci('project');
    my $id_role = $params{id_role} || TestSetup->create_role( actions => delete $params{actions} || [] );

    return TestSetup->create_user( id_role => $id_role, project => $project, %params );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::CI',
        'BaselinerX::Events',          'BaselinerX::Type::Config',
        'BaselinerX::Type::Menu',      'BaselinerX::Job',
        'BaselinerX::Type::Action',    'BaselinerX::Type::Service',
        'BaselinerX::Type::Registor',  'BaselinerX::Type::Statement',
        'BaselinerX::Type::Fieldlet',  'Baseliner::Model::Topic',
        'BaselinerX::Fieldlets',       'Baseliner::Controller::Topic',
        'Baseliner::Controller::Root', 'Baseliner::Model::Rules',
        'BaselinerX::LcController',
    );

    TestUtils->cleanup_cis;

    mdb->role->drop;
}
