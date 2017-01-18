use strict;
use warnings;

use Test::Deep;
use Test::MonkeyMock;
use Test::More;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils qw(mock_time);
use TestSetup;

use Capture::Tiny qw(capture);
use Baseliner::Utils qw(_now);

use_ok 'BaselinerX::Service::Purge';

subtest 'run_once: purges debug job log' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    _set_config( 'config.purge.keep_jobs_ok' => '1D' );

    my $job = _create_job();
    my $not_debug_logs_before = mdb->job_log->find( { lev => { '$ne' => 'debug' } } )->count;

    my $service = _build_service();
    $service->run_once();

    my $not_debug_logs = mdb->job_log->find( { lev => { '$ne' => 'debug' } } )->count;
    my $debug_logs = mdb->job_log->find( { lev => 'debug' } )->count;

    ok !$debug_logs;
    is $not_debug_logs , $not_debug_logs_before;
};

subtest 'run_once: does not purge jobs for a different bl' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    _set_config( 'config.purge.keep_jobs_ok' => '1D', bl => 'PROD' );

    my $job = _create_job();
    my $not_debug_logs_before = mdb->job_log->find( { lev => { '$ne' => 'debug' } } )->count;

    my $service = _build_service();
    $service->run_once();

    my $not_debug_logs = mdb->job_log->find( { lev => { '$ne' => 'debug' } } )->count;
    my $debug_logs = mdb->job_log->find( { lev => 'debug' } )->count;

    ok $debug_logs;
};

subtest 'run_once: updates job purged' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    _set_config( 'config.purge.keep_jobs_ok' => '1D' );

    my $job = _create_job();

    my $service = _build_service();
    $service->run_once();

    $job = ci->new( $job->mid );

    ok $job->purged;
};

subtest 'run_once: purges data from all logs' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    _set_config( 'config.purge.keep_jobs_ok' => '1D' );

    my $job = _create_job();

    my $id_data = mdb->job_log->find_one( { lev => { '$ne' => 'debug' } } )->{data};

    my $service = _build_service();

    $service->run_once();

    my $not_debug_log = mdb->job_log->find_one( { lev => { '$ne' => 'debug' } } );
    ok !exists $not_debug_log->{data};

    ok !mdb->grid->find_one( { _id => $id_data } );
};

subtest 'run_once: purges job log' => sub {
    _setup();

    my $tempdir = tempdir();
    mkdir "$tempdir/logs";

    local $ENV{BASELINER_LOGHOME} = "$tempdir/logs";

    _set_config( 'config.purge.keep_jobs_ok' => '1D' );

    my $job = _create_job();

    my $service = _build_service();

    $service->run_once();

    ok !-f "$tempdir/logs/job.log";
};

subtest 'run_once: purges job dir' => sub {
    _setup();

    my $tempdir = tempdir();
    mkdir "$tempdir/jobs";

    local $ENV{BASELINER_JOBHOME} = "$tempdir/jobs";

    _set_config( 'config.purge.keep_jobs_ok' => '1D' );

    my $job = _create_job();

    mkdir $job->job_dir;

    my $service = _build_service();

    $service->run_once();

    ok !-d "$tempdir/jobs/job";
};

subtest 'run_once: purges old events' => sub {
    _setup();

    _set_config( 'config.purge.event_log_keep' => '7D' );
    _set_config( 'config.purge.event_ok_purge', 1 );

    mdb->event->insert( { id => '1', event_status => 'ok', event_key => 'some', ts => '2015-01-01 00:00:00' } );
    mdb->event_log->insert( { id_event => '1' } );

    mdb->event->insert( { id => '2', event_status => 'ok', event_key => 'some', ts => '2015-01-07 00:00:00' } );
    mdb->event_log->insert( { id_event => '2' } );

    my $service = _build_service();

    mock_time '2015-01-09 00:00:00', sub {
        $service->run_once();
    };

    is( mdb->event->find->count,     1 );
    is( mdb->event->find_one->{id},  2 );
    is( mdb->event_log->find->count, 1 );
};

subtest 'run_once: doesnt purge any events when disabled' => sub {
    _setup();

    _set_config( 'config.purge.event_log_keep' => '7D' );
    _set_config( 'config.purge.event_ok_purge', 0 );
    _set_config( 'config.purge.event_ko_purge', 0 );
    _set_config( 'config.purge.event_auth_purge', 0 );

    mdb->event->insert( { id => '1', event_status => 'ok', event_key => 'some', ts => '2015-01-01 00:00:00' } );
    mdb->event_log->insert( { id_event => '1' } );

    mdb->event->insert( { id => '2', event_status => 'ko', event_key => 'some', ts => '2015-01-01 00:00:00' } );
    mdb->event_log->insert( { id_event => '2' } );

    mdb->event->insert( { id => '3', event_status => 'ok', event_key => 'event.auth', ts => '2015-01-01 00:00:00' } );
    mdb->event_log->insert( { id_event => '3' } );

    my $service = _build_service();

    mock_time '2015-01-09 00:00:00', sub {
        $service->run_once();
    };

    is( mdb->event->find->count,     3 );
    is( mdb->event_log->find->count, 3 );
};

subtest 'run_once: purges old messages' => sub {
    _setup();

    _set_config( 'config.purge.keep_sent_messages' => '7D' );

    mdb->message->insert( { created => '2015-01-01 00:00:00' } );
    mdb->message->insert( { created => '2015-01-07 00:00:00' } );

    my $service = _build_service();

    mock_time '2015-01-09 00:00:00', sub {
        $service->run_once();
    };

    is( mdb->message->find->count,     1 );
    is( mdb->message->find_one->{created},  '2015-01-07 00:00:00' );
};

subtest 'run_once: rotates logs' => sub {
    _setup();

    _set_config( 'config.purge.keep_disp_log_size',   1 );
    _set_config( 'config.purge.keep_web_log_size',    1 );
    _set_config( 'config.purge.keep_mongod_log_size', 1 );

    my $tempdir = tempdir();

    local $ENV{BASELINER_LOGHOME} = "$tempdir";
    local $ENV{BASELINER_LOG_ROTATE_SLEEP} = 0;

    TestUtils->write_file( 'hello', "$tempdir/mongod.log" );
    TestUtils->write_file( 'hello', "$tempdir/cla-disp-localhost.log" );

    my $service = _build_service( file_size_factor => 1 );

    $service->run_once();

    my @files = glob "$tempdir/*";

    is -s ("$tempdir/mongod.log"), 0;
    is -s ("$tempdir/cla-disp-localhost.log"), 0;

    ok grep { m/mongod.*\.gz/ } @files;
    ok grep { m/cla-disp-localhost.*\.gz/ } @files;
};

subtest 'daemon_run_once: does nothing when not time to run' => sub {
    _setup();

    my $service = _build_service();
    $service->mock( run_once => sub { } );

    _set_config( 'config.purge.keep_jobs_ko', 0 );

    $service->daemon_run_once();

    ok !$service->mocked_called('run_once');
};

subtest 'daemon_run_once: runs once' => sub {
    _setup();

    my $service = _build_service();
    $service->mock( run_once => sub { } );

    _set_config( 'config.daemon.purge.min_purge_time' => '00:00' );
    _set_config( 'config.daemon.purge.max_purge_time' => '23:59' );

    $service->daemon_run_once();

    ok $service->mocked_called('run_once');
};

subtest 'daemon_run_once: doesn run outside of window' => sub {
    _setup();

    my $service = _build_service();
    $service->mock( run_once => sub { } );

    _set_config( 'config.daemon.purge.min_purge_time' => '00:00' );
    _set_config( 'config.daemon.purge.max_purge_time' => '02:00' );

    mock_time '2015-01-01 12:01:01', sub {
        $service->daemon_run_once();
    };

    ok !$service->mocked_called('run_once');
};

subtest 'daemon_run_once: doesn run when next run is in the future' => sub {
    _setup();

    my $service = _build_service();
    $service->mock( run_once => sub { } );

    _set_config( 'config.daemon.purge.min_purge_time' => '00:00' );
    _set_config( 'config.daemon.purge.max_purge_time' => '23:59' );
    _set_config( 'config.daemon.purge.next_purge_date' => _now() );

    mock_time '2015-01-01 12:01:01', sub {
        $service->daemon_run_once();
    };

    ok !$service->mocked_called('run_once');
};

subtest 'daemon_run_once: saves next run' => sub {
    _setup();

    my $service = _build_service();
    $service->mock( run_once => sub { } );

    _set_config( 'config.daemon.purge.min_purge_time' => '00:00' );
    _set_config( 'config.daemon.purge.max_purge_time' => '23:59' );

    $service->daemon_run_once();

    my $next_purge_date = BaselinerX::Type::Model::ConfigStore->new->get('config.purge.next_purge_date');

    isnt $next_purge_date, '';
};

subtest 'time_to_run: checks if correct time to run' => sub {
    _setup();

    my $service = _build_service();

    my $now = Class::Date->now;

    ok $service->time_to_run( { min_purge_time => '00:00', max_purge_time => '23:59' } );

    ok !$service->time_to_run( { min_purge_time => ( $now - '1H' )->hms, max_purge_time => ( $now - '1M' )->hms } );
    ok !$service->time_to_run(
        { next_purge_date => '2030-12-12', min_purge_time => '00:00', max_purge_time => '23:59' } );
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',    'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',  'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',     'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis;

    mdb->job_log->drop;
    mdb->rule->drop;
    mdb->topic->drop;
    mdb->job_log->drop;
    mdb->grid->drop;
    mdb->event->drop;
    mdb->event_log->drop;
    mdb->message->drop;

    _set_config( 'config.daemon.purge.next_purge_date', '' );
    _set_config( 'config.daemon.purge.min_purge_time' => '00:00' );
    _set_config( 'config.daemon.purge.max_purge_time' => '00:00' );

    _set_config( 'config.purge.keep_jobs_ko',   0 );
    _set_config( 'config.purge.keep_jobs_ok',   0 );
    _set_config( 'config.purge.keep_job_files', 0 );
    _set_config( 'config.purge.no_job_purge',   0 );
}

sub _set_config {
    my ( $key, $value, @args ) = @_;

    BaselinerX::Type::Model::ConfigStore->new->set( key => $key, value => $value, @args );
}

sub _create_job {
    my (%params) = @_;
    my %p;
    my $id_rule = '1';

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    _create_rule( id_rule => $id_rule );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    $p{id_rule}    = $id_rule;
    $p{rollback}   = delete $params{rollback} || 0;
    $p{job_type}   = delete $params{job_type} || 'promote';
    $p{changesets} = [$changeset];
    $p{bl}         = delete $params{bl} || 'TEST';
    $p{purged}     = delete $params{purged} || '0';

    my $job = mock_time '2015-01-01 01:01:01', sub {
        my $job = BaselinerX::CI::job->new(
            %p,
            jobid    => mdb->seq('job'),
            name     => 'job',
            job_name => 'job',
            status   => 'READY',
            step     => 'POST'
        );
        capture {
            $job->save;
            $job->run_inproc( { username => 'root' } );
            $job->run_inproc( { username => 'root' } );
            $job->run_inproc( { username => 'root' } );
        };
        $job;
    };
    return $job;
}

sub _create_rule {
    my (%params) = @_;
    mdb->rule->insert(
        {
            id        => $params{id_rule},
            rule_when => 'promote',
        }
    );
}

sub _build_service {
    my $service = BaselinerX::Service::Purge->new(@_);
    $service = Test::MonkeyMock->new($service);
    return $service;
}
