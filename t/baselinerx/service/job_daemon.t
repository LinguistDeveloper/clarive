use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestSetup;

use Capture::Tiny qw(capture);

use Baseliner::RuleCompiler;

use_ok 'BaselinerX::Service::JobDaemon';

subtest 'precompile_rule: precompiles rule' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule;

    my $service = _build_service();

    $service->precompile_rule($id_rule);

    my $rule = mdb->rule->find_one( { id => $id_rule } );
    ok( Baseliner::RuleCompiler->new( id_rule => $id_rule, version_id => '' . $rule->{_id} )->is_loaded );
};

subtest 'job_daemon: creates event when status job change to expired' => sub {
    _setup();

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.job.daemon.mode', value => 'detach' );

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = TestSetup->create_job( changesets => [$changeset] );
    $job->step('RUN');
    $job->maxstarttime('2015-10-26 03:21:20');
    $job->status('APPROVAL');
    capture { $job->save() };

    my $service = _build_service( job => $job );
    capture { $service->job_daemon( undef, { id => '123', frequency => '1', iterations => 1 } ) };

    my $exist_event = mdb->event->find_one( { event_key => 'event.job.expired' } );

    ok $exist_event;
};

subtest 'job_daemon: runs job when step pre finishs ok in rollback mode' => sub {
    _setup();

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.job.daemon.mode', value => 'detach' );

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = TestSetup->create_job( changesets => [$changeset] );
    $job->step('RUN');
    $job->status('READY');
    $job->rollback('1');
    capture { $job->save() };

    my $service = _build_service( job => $job );
    $service->job_daemon( undef, { id => '123', frequency => '1', iterations => 1 } );

    ok $service->mocked_called('runner_fork');
};

subtest 'job_daemon: runs scheduled job immediately when step pre finishs ok in rollback mode ' => sub {
    _setup();

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.job.daemon.mode', value => 'detach' );

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $tday      = Class::Date->now;
    my $schedtime = Class::Date->new( $tday + '1D' )->string;
    my $job       = TestSetup->create_job( changesets => [$changeset], schedtime => $schedtime );
    $job->step('RUN');
    $job->status('READY');
    $job->rollback('1');
    capture { $job->save() };

    my $service = _build_service( job => $job );
    $service->job_daemon( undef, { id => '123', frequency => '1', iterations => 1 } );

    ok $service->mocked_called('runner_fork');
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Menu',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'BaselinerX::Job',
        'Baseliner::Model::Jobs',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Topic',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
}

sub _build_service {
    my (%params) = @_;
    my $job = $params{job};

    my $job_daemon = BaselinerX::Service::JobDaemon->new();
    $job_daemon = Test::MonkeyMock->new($job_daemon);
    $job_daemon->mock( runner_fork => sub { } );
    return $job_daemon;
}
