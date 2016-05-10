use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use Baseliner::Utils qw(_load);

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

subtest 'new: creates job and runs CHECK & INIT' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic(is_changeset => 1, username => $user->name );

    my $job;
    capture { $job = TestUtils->create_ci('job', changesets => [$changeset]) };

    is_deeply $job->step_status,
      {
        INIT  => 'FINISHED',
        CHECK => 'FINISHED',
      };
};

subtest 'new: saves rule versions for INIT & CHECK' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic(is_changeset => 1, username => $user->name );

    my $job;
    capture {
        $job = TestUtils->create_ci('job', changesets => [$changeset]);
    };

    cmp_deeply $job->rule_versions,
      [
        {
            INIT  => ignore(),
            CHECK => ignore(),
        }
      ];
};

subtest 'run: runs rule with version tag' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic(is_changeset => 1, username => $user->name );

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => '1',
        username => 'newuser',
    );

    my @versions = Baseliner::Model::Rules->new->list_versions('1');

    my $version_id = $versions[0]->{_id};

    my $rules = Baseliner::Model::Rules->new;
    $rules->tag_version( version_id => $version_id, version_tag => 'production' );

    my $job;
    capture {
        $job = TestUtils->create_ci('job', changesets => [$changeset], rule_version_tag => 'production');
    };

    cmp_deeply $job->rule_versions,
      [
        {
            INIT  => "$version_id (production)",
            CHECK => "$version_id (production)",
        }
      ];
};

subtest 'finish: create notify in event.job.end_step' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $job = _build_ci( changesets => [$changeset], bl => 'QA', projects => $project );

    capture {
        $job->finish('FINISHED');
    };

    my @event  = mdb->event->find_one( { event_key => 'event.job.end_step' } );
    my $event  = _load( $event[0]->{event_data} );
    my $notify = $event->{notify};

    is_deeply $notify,
        {
        status  => 'FINISHED',
        bl      => $bl->{mid},
        project => [ $project->{mid} ]
        };

};

subtest 'finish: create the notify in event.job.end' => sub {
    _setup();
    use Data::Dumper;
    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $job = _build_ci( changesets => [$changeset], bl => 'QA', step => 'POST', projects => $project );

    capture {
        $job->finish('CANCELLED');
    };

    my @event  = mdb->event->find_one( { event_key => 'event.job.end' } );
    my $event  = _load( $event[0]->{event_data} );
    my $notify = $event->{notify};

    is_deeply $notify,
        {
        status  => 'CANCELLED',
        bl      => $bl->{mid},
        project => [ $project->{mid} ]
        };

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
    mdb->rule_version->drop;
    mdb->job_log->drop;
    mdb->event->drop;

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
