use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;
use Test::TempDir::Tiny;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils qw(:catalyst);
use TestSetup;
use Baseliner::Utils;


use_ok 'BaselinerX::Lc';

subtest 'lc_for_project: returns job node when user has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            { action => 'action.topics.changeset.view', },
            { action => 'action.topics.changeset.jobs', },
            { action => 'action.job.view_monitor', }
        ]
    );
    my $user = _create_user_with_actions( id_role => $id_role );
    my $status_new = TestUtils->create_ci(
        'status',
        name             => 'New',
        type             => 'I'
    );
    my $controller = _build_controller();
    my $c          = mock_catalyst_c(
        username => $user->username,
        req      => { params => { id_project => $project->mid } }
    );
    my $lc = $controller->new->lc_for_project( $project->mid, $project,
        $c->username );
    my $job_node;
    for my $node (@$lc) {
        next unless $node->{node} eq "Jobs";
        $job_node = $node->{menu};

    }
    my @job_node = _array_or_commas($job_node);

    is $job_node[0]->{comp}->{url}, "/job/monitor";
};

subtest 'lc_for_project: does not return job node when user does not have permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            { action => 'action.topics.changeset.view', },
            { action => 'action.topics.changeset.jobs', },
        ]
    );
    my $user = _create_user_with_actions( id_role => $id_role );
    my $status_new = TestUtils->create_ci(
        'status',
        name => 'New',
        type => 'I'
    );
    my $controller = _build_controller();
    my $c          = mock_catalyst_c(
        username => $user->username,
        req      => { params => { id_project => $project->mid } }
    );
    my $lc = $controller->new->lc_for_project( $project->mid, $project,
        $c->username );
    my $job_node;
    for my $node (@$lc) {
        next unless $node->{node} eq "Jobs";
        $job_node = $node->{menu};
    }

    is !defined($job_node), 1;
};

done_testing;

sub _build_controller {
    BaselinerX::Lc->new( application => '' );
}

sub _create_user_with_actions {
    my (%params) = @_;

    my $project = $params{project} || TestUtils->create_ci('project');
    my $id_role = $params{id_role} || TestSetup->create_role( actions => delete $params{actions} || [] );

    return TestSetup->create_user( id_role => $id_role, project => $project, %params );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::CI',
        'BaselinerX::Events',      'BaselinerX::Type::Fieldlet',
        'Baseliner::Model::Topic', 'BaselinerX::Fieldlets',
        'Baseliner::Controller::Topic', 'Baseliner::Model::Rules'
    );

    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->topic->drop;
    mdb->event->drop;
    mdb->rule->drop;
    mdb->role->drop;
}
