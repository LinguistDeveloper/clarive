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

use_ok 'BaselinerX::Service::Purge';

subtest 'run_once: does nothing when nothing to purge' => sub {
    _setup();

    my $service = _build_service();
    my $stats   = $service->run_once();
    is_deeply $stats, { grid => 0, job => 0, job_log => 0 };
};

subtest 'run_once: purges debug job log' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    my $job            = _create_job();
    my $debug_logs     = mdb->job_log->find( { lev => 'debug' } )->count;
    my $not_debug_logs = mdb->job_log->find( { lev => { '$ne' => 'debug' } } )->count;

    my $service                = _build_service();
    my $stats                  = $service->run_once();
    my $after_purge_debug_logs = mdb->job_log->find( { lev => 'debug' } )->count;

    is $after_purge_debug_logs, 0;
    is $stats->{job_log}, $debug_logs;
    ok $not_debug_logs;
};

subtest 'run_once: updates job purged' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    my $job = _create_job();

    my $service = _build_service();
    $service->run_once();

    $job = ci->new($job->mid);

    ok $job->purged;
};

subtest 'run_once: purges data from all logs' => sub {
    _setup();

    local $ENV{BASELINER_LOGHOME} = tempdir();

    my $job = _create_job();

    my $service = _build_service();

    $service->run_once();

    my $not_debug_log = mdb->job_log->find_one( { lev => { '$ne' => 'debug' } } );
    my $data = $not_debug_log->{data};

    ok !mdb->grid->find_one( { _id => $data } );
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

    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.purge.keep_jobs_ko',   value => 0 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.purge.keep_jobs_ok',   value => 0 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.purge.keep_job_files', value => 0 );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.purge.no_job_purge',   value => 0 );
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
    $p{job_dir}    = delete $params{job_dir} || '/job/dir';
    $p{bl}         = delete $params{bl} || 'TEST';
    $p{purged}     = delete $params{purged} || '0';

    my $job = mock_time '2015-01-01 01:01:01', sub {
        my $job = BaselinerX::CI::job->new( %p, step => 'POST', status => 'FINISHED' );
        capture { $job->save };
        $job->finish;
        $job->save;
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
    return BaselinerX::Service::Purge->new(@_);
}
