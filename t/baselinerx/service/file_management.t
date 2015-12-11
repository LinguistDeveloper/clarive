use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::MonkeyMock;
use Test::TempDir::Tiny;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'BaselinerX::Service::FileManagement';

subtest 'run_ship: copies file to remote' => sub {
    _setup();

    my $job = _mock_job();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward' } );

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

    my $c = _mock_c( stash => { job => $job, job_mode => 'forward' } );

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
