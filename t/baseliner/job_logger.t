use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Capture::Tiny qw(capture);

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';
use TestSetup;

use_ok 'Baseliner::JobLogger';

subtest 'common_log: logs data' => sub {
    _setup();

    my $job = _mock_job();

    my $logger = _build_logger( job => $job, jobid => 1, exec => 1, current_service => 'some.service' );

    capture {
        $logger->common_log(
            'info', 'foobar',
            data      => 'DATA',
            data_name => 'file.txt',
            prefix    => '/prefix/',
            milestone => 'milestone',
            username  => 'foo'
        );
    };

    my $job_log = mdb->job_log->find_one;

    cmp_deeply $job_log,
      {
        '_id'         => ignore(),
        'id'          => ignore(),
        'data'        => ignore(),
        'data_length' => 4,
        'data_name'   => 'file.txt',
        'exec'        => 1,
        'lev'         => 'info',
        'mid'         => 'job-1',
        'module'      => ignore(),
        'pid'         => ignore(),
        'prefix'      => '/prefix/',
        'milestone'   => 'milestone',
        'no_trim'     => 0,
        'rule'        => '1',
        'section'     => 'general',
        'service_key' => 'some.service',
        'step'        => 'PRE',
        'stmt_level'  => 0,
        'text'        => 'foobar',
        't'           => ignore(),
        'ts'          => ignore(),
      };

    my $grid = mdb->grid->find_one;
    is Baseliner::Utils::uncompress( $grid->slurp ), 'DATA';
};

subtest 'common_log: correctly saves unicode text' => sub {
    _setup();

    my $job = _mock_job();

    my $logger = _build_logger( job => $job, jobid => 1, exec => 1, current_service => 'some.service' );

    capture {
        $logger->common_log( 'info', "\x{1F603}", 'DATA' );
    };

    my $job_log = mdb->job_log->find_one;
    is $job_log->{text}, "\x{1F603}";
};

subtest 'common_log: correctly saves long text into grid' => sub {
    _setup();

    my $job = _mock_job();

    my $logger = _build_logger( job => $job, jobid => 1, exec => 1, current_service => 'some.service' );

    capture {
        $logger->common_log( 'info', "\x{1F603}" x 2050, 'DATA' );
    };

    my $job_log = mdb->job_log->find_one;
    is length $job_log->{text}, 2000;

    my $grid = mdb->grid->find_one;
    my $data = Baseliner::Utils::uncompress( $grid->slurp );
    like Encode::decode( 'UTF-8', $data ), qr/====\n\x{1F603}/;
};

subtest 'common_log: does not trim data with no_trim option' => sub {
    _setup();

    my $job = _mock_job();

    my $logger = _build_logger( job => $job, jobid => 1, exec => 1, current_service => 'some.service' );

    capture {
        $logger->common_log( 'info', "\x{1F603}" x 2050, data => 'DATA', no_trim => 1 );
    };

    my $job_log = mdb->job_log->find_one;
    isnt length $job_log->{text}, 2000;
};

subtest 'common_log: correctly saves unicode data into grid' => sub {
    _setup();

    my $job = _mock_job();

    my $logger = _build_logger( job => $job, jobid => 1, exec => 1, current_service => 'some.service' );

    capture {
        $logger->common_log( 'info', 'foobar', data => "\x{1F603}" );
    };

    my $grid = mdb->grid->find_one;
    is Baseliner::Utils::uncompress( $grid->slurp ), Encode::encode( 'UTF-8', "\x{1F603}" );
};

subtest 'common_log: dumps data in case of a reference' => sub {
    _setup();

    my $job = _mock_job();

    my $logger = _build_logger( job => $job, jobid => 1, exec => 1, current_service => 'some.service' );

    capture {
        $logger->common_log( 'info', 'foobar', data => { foo => 'bar' } );
    };

    my $grid = mdb->grid->find_one;
    is Baseliner::Utils::uncompress( $grid->slurp ), "---\nfoo: bar\n";
};

done_testing;

sub _build_logger {
    Baseliner::JobLogger->new(@_);
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',              'BaselinerX::Type::Event',
        'Baseliner::Model::Events',    'Baseliner::Model::Topic',
        'BaselinerX::Type::Fieldlet',  'BaselinerX::Fieldlets',
        'BaselinerX::Type::Statement', 'Baseliner::Model::Jobs',
        'Baseliner::Model::Rules',
    );

    TestUtils->cleanup_cis();

    mdb->job_log->drop;
    mdb->grid->drop;
}

sub _mock_job {
    my $job = Test::MonkeyMock->new;

    $job->mock( mid            => sub { 'job-1' } );
    $job->mock( step           => sub { 'PRE' } );
    $job->mock( id_rule        => sub { '1' } );
    $job->mock( service_levels => sub { { 'PRE' => {} } } );

    return $job;
}
