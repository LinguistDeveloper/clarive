use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(mock_time);

use Baseliner::DateRange;

subtest 'build range for days' => sub {
    my (@range) = mock_time '2015-01-01T12:01:02', sub { _build_date_range()->build_pair };

    is_deeply \@range, [ '2015-01-01 00:00:00', '2015-01-01 12:01:02' ];
};

subtest 'build range for days with offset' => sub {
    my (@range) = mock_time '2015-01-01T12:01:02', sub { _build_date_range()->build_pair('day', 1) };

    is_deeply \@range, [ '2014-12-31 00:00:00', '2014-12-31 23:59:59' ];
};

subtest 'build range for weeks' => sub {
    my (@range) = mock_time '2016-01-01T12:01:02', sub { _build_date_range()->build_pair('week') };

    is_deeply \@range, [ '2015-12-28 00:00:00', '2016-01-01 12:01:02' ];
};

subtest 'build range for weeks with offset' => sub {
    my (@range) = mock_time '2016-01-01T12:01:02', sub { _build_date_range()->build_pair('week', 1) };

    is_deeply \@range, [ '2015-12-21 00:00:00', '2015-12-28 23:59:59' ];
};

subtest 'build range for months' => sub {
    my (@range) = mock_time '2016-01-01T12:01:02', sub { _build_date_range()->build_pair('month') };

    is_deeply \@range, [ '2016-01-01 00:00:00', '2016-01-01 12:01:02' ];
};

subtest 'build range for months with offset' => sub {
    my (@range) = mock_time '2016-01-01T12:01:02', sub { _build_date_range()->build_pair('month', 1) };

    is_deeply \@range, [ '2015-12-01 00:00:00', '2015-12-31 23:59:59' ];
};

subtest 'build range for years' => sub {
    my (@range) = mock_time '2016-01-01T12:01:02', sub { _build_date_range()->build_pair('year') };

    is_deeply \@range, [ '2016-01-01 00:00:00', '2016-01-01 12:01:02' ];
};

subtest 'build range for years with offset' => sub {
    my (@range) = mock_time '2016-01-01T12:01:02', sub { _build_date_range()->build_pair('year', 1) };

    is_deeply \@range, [ '2015-01-01 00:00:00', '2015-12-31 23:59:59' ];
};

done_testing;

sub _build_date_range {
    Baseliner::DateRange->new;
}
