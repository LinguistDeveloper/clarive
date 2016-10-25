use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

use Capture::Tiny qw(capture);
use Baseliner::Utils qw(_load);

use_ok 'BaselinerX::CI::job';

subtest 'trap_action: creates event when status job is changed to trappedpause' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );
    my $job_ci;

    capture {
        $job_ci = TestSetup->create_job(
            changesets => [$changeset],
            name       => 'job'
        );
        $job_ci->status('TRAPPED');
        $job_ci->save;

        $job_ci->trap_action( { comments => 'change status for job to trappedpause', action => 'pause' } );
    };

    my @event    = mdb->event->find_one( { event_key => 'event.job.trappedpause' } );
    my $event    = _load( $event[0]->{event_data} );
    my $comments = $event->{comments};

    is $comments, 'change status for job to trappedpause';
};

subtest 'trap_action: creates event when status job is changed to untrapped' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );
    my $job_ci;

    capture {
        $job_ci = TestSetup->create_job(
            changesets => [$changeset],
            name       => 'job'
        );
        $job_ci->status('TRAPPED');
        $job_ci->save;

        $job_ci->trap_action( { comments => 'change status for job to untrapped', action => 'skip' } );
    };

    my @event    = mdb->event->find_one( { event_key => 'event.job.untrapped' } );
    my $event    = _load( $event[0]->{event_data} );
    my $comments = $event->{comments};

    is $comments, 'change status for job to untrapped';
};

subtest 'pause: creates event when status job is changed to pause' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );
    my $job_ci;

    capture {
        $job_ci = TestSetup->create_job(
            changesets => [$changeset],
            name       => 'job'
        );
        $job_ci->step('PRE');
        $job_ci->save;
        $job_ci->pause( reason => 'job are paused', timeout => 1, frequency => 1, no_fail => 1 );

    };

    my $exist_event = mdb->event->find_one( { event_key => 'event.job.paused' } );

    ok $exist_event ;
};

subtest 'resume: creates event when status job is restarted' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );
    my $job_ci;

    capture {
        $job_ci = TestSetup->create_job(
            changesets => [$changeset],
            name       => 'job'
        );
        $job_ci->status('PAUSED');
        $job_ci->save;
        $job_ci->resume( { username => $user->{username} } );
    };

    my $exist_event = mdb->event->find_one( { event_key => 'event.job.unpaused' } );

    ok $exist_event;
};

subtest 'start_task: sets current_service' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset] );

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
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset] );

    capture {
        $job->save;
        $job->start_task( 'some_task', 123 )
    };

    my $job_log = mdb->job_log->find_one( { service_key => 'some_task' } );

    ok $job_log;
    is $job_log->{milestone},  2;
    is $job_log->{stmt_level}, 123;
};

subtest 'new: creates job and runs CHECK & INIT' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job;
    capture { $job = TestUtils->create_ci( 'job', changesets => [$changeset] ) };

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
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );
    my $job;
    capture {
        $job = TestUtils->create_ci( 'job', changesets => [$changeset] );
    };

    cmp_deeply $job->rule_versions,
        [
        {   INIT  => ignore(),
            CHECK => ignore(),
        }
        ];
};

subtest 'run: runs rule with version tag' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

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
        $job = TestUtils->create_ci( 'job', changesets => [$changeset], rule_version_tag => 'production' );
    };

    cmp_deeply $job->rule_versions,
        [
        {   INIT  => "$version_id (production)",
            CHECK => "$version_id (production)",
        }
        ];
};

subtest 'run: creates notify with job step in event.job.end_step' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $job = _build_ci( changesets => [$changeset], bl => 'QA' );

    capture {
        $job->run();
    };

    my @event  = mdb->event->find_one( { event_key => 'event.job.end_step' } );
    my $event  = _load( $event[0]->{event_data} );
    my $notify = $event->{notify};

    is $notify->{step}, 'CHECK';
};

subtest 'run: creates notify with job step in event.job.end' => sub {
    _setup();

    my $project       = TestUtils->create_ci_project();
    my $id_role       = TestSetup->create_role();
    my $user          = TestSetup->create_user( id_role => $id_role, project => $project );
    my $bl            = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $changeset_mid = TestSetup->create_changeset();
    my $job           = _build_ci( changesets => [$changeset_mid], bl => 'QA', projects => $project );

    capture {
        $job->run();
        $job->run();
        $job->run();
    };
    my @event  = mdb->event->find_one( { event_key => 'event.job.end' } );
    my $event  = _load( $event[0]->{event_data} );
    my $notify = $event->{notify};

    is $notify->{step}, 'POST';
};

subtest 'reset: creates correct event event.job.rerun with parameters step POST and last_finish_status ERROR' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset] );

    capture {
        $job->save;

        $job->reset( { username => $user->name, step => 'POST', last_finish_status => 'ERROR' } );
    };

    my $events = _build_events_model();

    my $event_data = _load $events->find_by_key('event.job.rerun')->[0]->{event_data};

    is $event_data->{job}->{last_finish_status}, 'ERROR';
    is $event_data->{job}->{step},               'POST';
};

subtest 'reset: creates correct event event.job.rerun with parameters step POST and last_finish_status OK' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset] );

    capture {
        $job->save;

        $job->reset( { username => $user->name, step => 'POST', last_finish_status => 'OK' } );
    };

    my $events = _build_events_model();

    my $event_data = _load $events->find_by_key('event.job.rerun')->[0]->{event_data};

    is $event_data->{job}->{last_finish_status}, 'OK';
    is $event_data->{job}->{step},               'POST';
};

subtest 'run: creates notify with job step in event.job.start_step' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project();
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $job = _build_ci( changesets => [$changeset], bl => 'QA' );

    capture {
        $job->run();
    };

    my @event  = mdb->event->find_one( { event_key => 'event.job.start_step' } );
    my $event  = _load( $event[0]->{event_data} );
    my $notify = $event->{notify};

    is $notify->{step}, 'CHECK';
};

subtest 'steps: returns list of steps' => sub {
    _setup();

    my $job = _build_ci();

    my @steps = $job->steps();

    is_deeply \@steps, [ 'CHECK', 'INIT', 'PRE', 'RUN', 'POST' ];
};

subtest 'save: throws an error when the job is already created' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_changeset();
    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $job;
    capture {
        $job = BaselinerX::CI::job->new( changesets => [$changeset], bl => 'QA' )->save;
    };

    like exception { BaselinerX::CI::job->new( changesets => [$changeset], bl => 'QA' )->save },
        qr/is in an active job to bl QA/;
};

subtest 'run_inproc: runs job in process' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.run_in_proc' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job;
    capture {
        $job = TestUtils->create_ci( 'job', changesets => [$changeset] );
    };

    $job = Test::MonkeyMock->new($job);
    $job->mock( run => sub { } );

    capture { $job->run_inproc( { username => $user->name } ) };

    ok $job->mocked_called('run');
};

subtest 'run_inproc: throws when user does not have permission' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job;
    capture {
        $job = TestUtils->create_ci( 'job', changesets => [$changeset] );
    };

    like exception { $job->run_inproc( { username => $user->name } ) },
        qr/User .*? does not have permissions to start jobs in process/;
};

subtest 'is_rollback_needed: returns flag true or false if job has steps with rollback' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $changeset_mid = TestSetup->create_changeset();

    my $job = _build_ci( changesets => [$changeset_mid], bl => 'QA', projects => $project );

    capture {
        $job->run();
    };

    ok $job->is_rollback_needed;
};

subtest 'rollback_steps: returns an array with all rollback steps' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $changeset_mid = TestSetup->create_changeset();

    my $job = _build_ci( changesets => [$changeset_mid], bl => 'QA', projects => $project );

    capture {
        $job->run();
    };

    my @rollback_steps = $job->rollback_steps;

    is $rollback_steps[0], 'PRE';
};

subtest 'start_rollback: starts job in rollback mode' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $bl = TestUtils->create_ci( 'bl', name => 'QA', bl => 'QA' );
    my $changeset_mid = TestSetup->create_changeset();

    my $job = _build_ci( changesets => [$changeset_mid], bl => 'QA', projects => $project );

    capture {
        $job->run();
        $job->start_rollback;
    };

    is $job->step,     'PRE';
    is $job->rollback, '1';
    is $job->status,   'READY';
};

subtest 'reschedule: updates time and date of the job' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset] );

    capture {
        $job->save;
        $job->reschedule( { username => $user->name, date => '2022-05-18', time => '15:15:00' } );
    };

    is $job->{schedtime}, '2022-05-18 15:15:00';
};

subtest 'reschedule: updates comment of the job' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset] );

    capture {
        $job->save;
        $job->reschedule(
            { username => $user->name, date => '2022-05-18', time => '15:15:00', comments => "new comment" } );
    };

    is $job->{comments}, 'new comment';
};

subtest 'reschedule: concatenates comments, and the last comment is in the first line' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $job = _build_ci( changesets => [$changeset], comments => "First comment" );

    capture {
        $job->save;
        $job->reschedule(
            { username => $user->name, date => '2022-05-18', time => '15:15:00', comments => "Second comment" } );
    };

    is $job->{comments}, "Second comment\nFirst comment";
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Registor',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Menu',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',   'Baseliner::Model::Topic',
        'Baseliner::Model::Rules', 'Baseliner::Model::Jobs',
        'Baseliner::Controller::Job',
        'BaselinerX::Job'
    );

    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->event->drop;
    mdb->job_log->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->rule_version->drop;
    mdb->topic->drop;

    TestSetup->create_rule_pipeline( id => "1" );
}

sub _build_ci {
    BaselinerX::CI::job->new(@_);
}

sub _build_events_model {
    return Baseliner::Model::Events->new();
}
