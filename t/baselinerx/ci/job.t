use strict;
use warnings;

use Test::More;
use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

use Capture::Tiny qw(capture);

use_ok 'BaselinerX::CI::job';

subtest 'start_task: sets current_service' => sub {
    _setup();

    my $project = TestUtils->create_ci_project( );
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic(is_changeset => 1, username => $user->name );

    my $job = _build_ci(changesets => [$changeset]);

    capture {
        $job->save;
        $job->start_task('some_task')
    };

    is $job->current_service, 'some_task';
};

subtest 'start_task: creates job_log entry' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic(is_changeset => 1, username => $user->name );

    my $job = _build_ci(changesets => [$changeset]);

    capture {
        $job->save;
        $job->start_task('some_task', 123)
    };

    my $job_log = mdb->job_log->find_one({service_key => 'some_task'});

    ok $job_log;
    is $job_log->{milestone},  2;
    is $job_log->{stmt_level}, 123;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',     'Baseliner::Model::Jobs',
        'Baseliner::Model::Rules',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->job_log->drop;

    mdb->rule->insert(
        {
            id        => "1",
            rule_type => "pipeline",
            rule_when => 'promote',
        }
    );

}

sub _build_ci {
    BaselinerX::CI::job->new(@_);
}
