use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Deep;
use Test::Fatal;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Encode ();
use Capture::Tiny qw(capture);
use Baseliner::JobLogger;

use_ok 'BaselinerX::Service::Scripting';

subtest 'run_local: runs local command' => sub {
    _setup();

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { path => 'echo "hello"' };

    my $output;
    capture {
        $output = $service->run_local( $c, $config );
    };

    is_deeply $output,
      {
        ret    => 0,
        rc     => 0,
        output => "hello\n"
      };
};

subtest 'run_local: runs local command with unicode' => sub {
    _setup();

    my $smile = Encode::encode( 'UTF-8', "\x{1F608}" );

    my $tempdir  = tempdir();
    my $filename = "$tempdir/file_" . $smile;
    TestUtils->write_file( $smile, $filename );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { path => qq{cat '$filename'} };

    my $output;
    capture {
        $output = $service->run_local( $c, $config );
    };

    is_deeply $output,
      {
        ret    => 0,
        rc     => 0,
        output => $smile
      };
};

subtest 'run_local: logs command with unicode' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file( Encode::encode( 'UTF-8', "\x{1F608}" ), "$tempdir/file" );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { path => qq{cat '$tempdir/file'} };

    capture {
        $service->run_local( $c, $config );
    };

    my @job_log = mdb->job_log->find->all;

    like $job_log[0]->{text}, qr/Running command: cat/;
    like $job_log[1]->{text}, qr/Finished command cat/;

    my @grids = mdb->grid->all;

    like( Util->uncompress( $grids[0]->slurp ), qr/---\n- cat/ );
    is( Util->uncompress( $grids[1]->slurp ), Encode::encode( 'UTF-8', "RC: 0\nRET: 0\nOUTPUT: \x{1F608}" ) );
};

subtest 'run_local: prints to STDOUT/STDERR logging' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file( Encode::encode( 'UTF-8', "\x{1F608}" ), "$tempdir/file" );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { path => qq{cat '$tempdir/file'} };

    my ( $stdout, $stderr, $exit ) = capture {
        $service->run_local( $c, $config );
    };

    is $stdout, Encode::encode( 'UTF-8', "\x{1F608}" );
    like $stderr, qr/Running command/;
    is_deeply $exit,
      {
        ret    => 0,
        rc     => 0,
        output => Encode::encode( 'UTF-8', "\x{1F608}" )
      };
};

subtest 'run_remote: runs remote command with correct arguments' => sub {
    _setup();

    my $agent = _mock_agent();

    my $server = TestUtils->create_ci( 'generic_server', hostname => 'localhost' );
    $server = Test::MonkeyMock->new($server);
    $server->mock( connect => sub { $agent } );

    $agent->mock( server => sub { $server } );

    my $service = _build_service();

    my $c = _mock_c( stash => { job => _mock_job() } );
    my $config = { path => 'echo', args => ['hello'], environment => ['FOO=bar'], server => $server };

    my $output;
    capture {
        $output = $service->run_remote( $c, $config );
    };

    my ( $options, $command, @args ) = $agent->mocked_call_args('execute');

    cmp_deeply $options, { chdir => undef, env => ['FOO=bar'], stdout_file => ignore() };
    is $command, 'echo';
    is_deeply \@args, ['hello'];

    is_deeply $output,
      {
        'output' => 'OUTPUT',
        'rc'     => 0,
        'ret'    => 'OUTPUT'
      };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'Baseliner::Model::Jobs'
    );
    TestUtils->cleanup_cis;

    mdb->job_log->drop;
    mdb->grid->drop;
}

sub _build_service {
    BaselinerX::Service::Scripting->new;
}

sub _build_job_logger {
    my (%params) = @_;

    return Baseliner::JobLogger->new( job => $params{job}, jobid => 1, exec => 1, current_service => 'some.service' );
}

sub _mock_c {
    my (%params) = @_;

    my $c = Test::MonkeyMock->new;
    $c->mock( stash => sub { $params{stash} } );
    return $c;
}

sub _mock_agent {
    my $agent = Test::MonkeyMock->new;

    $agent->mock( execute   => sub { } );
    $agent->mock( output    => sub { 'OUTPUT' } );
    $agent->mock( rc        => sub { 0 } );
    $agent->mock( ret       => sub { 'OUTPUT' } );
    $agent->mock( tuple_str => sub { "RET: RC=0\nOUTPUT\nRET: OUTPUT" } );

    return $agent;
}

sub _mock_job {
    my (%params) = @_;

    my $job = Test::MonkeyMock->new;

    $job->mock( mid            => sub { 'job-1' } );
    $job->mock( step           => sub { 'PRE' } );
    $job->mock( id_rule        => sub { '1' } );
    $job->mock( service_levels => sub { { 'PRE' => {} } } );
    $job->mock( logger         => sub { $params{logger} || _build_job_logger( job => $job ) } );

    return $job;
}
