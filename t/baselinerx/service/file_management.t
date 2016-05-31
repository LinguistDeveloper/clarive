use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;
use Test::TempDir::Tiny;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'BaselinerX::Service::FileManagement';

subtest 'run_ship: fails when no server was configured' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward' } );

    my $user_ci = TestUtils->create_ci('user');

    like exception {
        $service->run_ship(
            $c,
            {
                local_path       => '',
                remote_path      => '',
                backup_mode      => '',
                server           => '',
                exist_mode_local => '',
                user             => $user_ci
            }
        );
    }, qr/Server not configured/;
};

subtest 'run_ship: fails when no local files were found in fail local mode' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward' } );

    my $tmp = tempdir();

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server => sub { $server } );
    my $user_ci = TestUtils->create_ci('user');

    like exception {
        $service->run_ship(
            $c,
            {
                local_path       => "$tmp/foo/bar",
                remote_path      => 'remote/',
                backup_mode      => 'none',
                server           => $server,
                exist_mode_local => 'fail',
                user             => $user_ci
            }
        );
    }, qr/Error: No local files were found/;
};

subtest 'run_ship: does not fail when no local files were found in skip local mode' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward' } );

    my $tmp = tempdir();

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server => sub { $server } );
    my $user_ci = TestUtils->create_ci('user');

    ok !exception {
        $service->run_ship(
            $c,
            {
                local_path       => "$tmp/foo/bar",
                remote_path      => 'remote/',
                backup_mode      => 'none',
                server           => $server,
                exist_mode_local => 'skip',
                user             => $user_ci
            }
          )
    };
};

subtest 'run_ship: copies file to remote' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'ship' } );

    my $tmp = tempdir();
    TestUtils->write_file( "foobar", "$tmp/foo" );

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server => sub { $server } );

    $service->run_ship( $c,
        { local_path => "$tmp/foo", remote_path => 'remote/', backup_mode => 'none', server => $server } );

    my $chksum = ( keys %{ $c->stash->{sent_files}->{localhost} } )[0];

    cmp_deeply $c->stash->{sent_files},
      {
        localhost => {
            $chksum => {
                'remote/foo' => re(qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/)
            }
        }
      };
};

subtest 'run_ship: copies file with special symbols' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'ship' } );

    my $tmp = tempdir();
    my $filepath = "$tmp/foo bar \$baz";
    TestUtils->write_file( "foobar", $filepath );

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server => sub { $server } );

    $service->run_ship(
        $c,
        {
            local_path  => $filepath,
            remote_path => 'remote/',
            backup_mode => 'none',
            server      => $server
        }
    );

    my $chksum = ( keys %{ $c->stash->{sent_files}->{localhost} } )[0];

    cmp_deeply $c->stash->{sent_files},
      {
        localhost => {
            $chksum => {
                'remote/foo bar $baz' => re(qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/)
            }
        }
      };
};

subtest 'run_sync_remote: runs sync_dir on agent' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'sync_remote' } );

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server => sub { $server } );
    $agent->mock( sync_dir => sub { } );

    $service->run_sync_remote(
        $c,
        {
            local_path  => '/local/path',
            remote_path => '/remote/path/',
            direction   => 'local-to-remote',
            server      => $server
        }
    );

    my (%args) = $agent->mocked_call_args('sync_dir');
    is_deeply \%args,
      {
        'remote'            => '/remote/path/',
        'local'             => '/local/path',
        'direction'         => 'local-to-remote',
        'delete_extraneous' => 0
      };
};

subtest 'run_retrieve: writes correct messages into the log' => sub {
    _setup();

    my $log = _mock_logger();

    my $job = _mock_job( logger => $log );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'run_retrieve' } );

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost', name => 'MyServer' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server   => sub { $server } );
    $agent->mock( get_file => sub { } );

    $service->run_retrieve(
        $c,
        {
            local_path  => '/local/path',
            remote_path => '/remote/path/',
            server      => $server
        }
    );

    my ($message) = $log->mocked_call_args('info');

    like $message, qr/\/remote\/path\/' to '\/local\/path/;
};

subtest 'run_retrieve: calls agent returns correct parameters' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'run_retrieve' } );

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost', name => 'MyServer' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server   => sub { $server } );
    $agent->mock( get_file => sub { } );

    $service->run_retrieve(
        $c,
        {
            local_path  => '/local/path',
            remote_path => '/remote/path/',
            server      => $server
        }
    );

    my (%args) = $agent->mocked_call_args('get_file');

    is_deeply \%args,
      {
        'remote' => '/remote/path/',
        'local'  => '/local/path'
      };
};

subtest 'run_retrieve: throws an error when no local path' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'run_retrieve' } );

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost', name => 'MyServer' );

    like exception {
        $service->run_retrieve(
            $c,
            {
                remote_path => "/tmp/unlikely-to-exist123",
                server      => $server
            }
        );
    }, qr/Missing parameter local_file/;
};

subtest 'run_retrieve: throws an error when no remote path' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward', current_task_name => 'run_retrieve' } );

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost', name => 'MyServer' );

    like exception {
        $service->run_retrieve(
            $c,
            {
                local_path => "tmp/foo/bar",
                server     => $server
            }
        );
    }, qr/Missing parameter remote_file/;
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'Baseliner::Model::Jobs' );

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;
}

sub _mock_logger {
    my (%params) = @_;

    my $logger = Test::MonkeyMock->new;
    $logger->mock( info  => sub { } );
    $logger->mock( warn  => sub { } );
    $logger->mock( debug => sub { } );

    return $logger;
}

sub _mock_job {
    my (%params) = @_;

    my $logger = $params{logger} || _mock_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock(
        is_failed => $params{is_failed} || sub { 0 },
        when => sub { $_[0] eq 'status' && $_[1] eq 'last_finish_status' }
    );
    $job->mock( rollback => $params{rollback} || sub { 0 } );
    $job->mock( logger     => sub { $logger } );
    $job->mock( job_type   => sub { 'promote' } );
    $job->mock( job_dir    => sub { '/job/dir' } );
    $job->mock( bl         => sub { 'TEST' } );
    $job->mock( exec       => sub { 1 } );
    $job->mock( backup_dir => sub { tempdir() } );
    $job->mock( step       => sub { 'RUN' } );

    return $job;
}

sub _mock_agent {
    my $agent = Test::MonkeyMock->new;
    $agent->mock( copy_attrs  => sub { } );
    $agent->mock( file_exists => sub { 0 } );
    $agent->mock( mkpath      => sub { } );
    $agent->mock( put_file    => sub { } );
}

sub _mock_c {
    my (%params) = @_;

    my $c = Test::MonkeyMock->new;
    $c->mock( stash => sub { $params{stash} } );

    return $c;
}

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::FileManagement->new(@_);
}
