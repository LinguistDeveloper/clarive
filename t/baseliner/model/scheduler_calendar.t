use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use lib 't/lib';

use TestEnv;
use TestUtils qw(mock_time);
BEGIN { TestEnv->setup }

use_ok 'Baseliner::Model::SchedulerCalendar';

subtest 'has_time_passed' => sub {
    my $model = _build_model();

    mock_time(
        '2015-01-01T00:00:00' => sub {
            ok !$model->has_time_passed('2015-01-01 00:00:01');
            ok $model->has_time_passed('2015-01-01 00:00:00');
            ok $model->has_time_passed('2014-12-31 23:59:59');
        }
    );
};

subtest 'calculate_next_exec: in the future' => sub {
    my $model = _build_model();

    mock_time(
        '2015-01-01T00:00:00' => sub {
            is $model->calculate_next_exec('2015-01-02 00:00:00'), '2015-01-03 00:00:00';
            is $model->calculate_next_exec( '2015-01-02 00:00:00', frequency => '2D' ), '2015-01-04 00:00:00';
        }
    );
};

subtest 'calculate_next_exec: in the past' => sub {
    my $model = _build_model();

    mock_time(
        '2015-01-01T00:00:00' => sub {
            is $model->calculate_next_exec('2014-01-02 00:00:00'), '2015-01-02 00:00:00';
            is $model->calculate_next_exec( '2014-01-02 00:00:00', frequency => '2D' ), '2015-01-03 00:00:00';
        }
    );
};

subtest 'calculate_next_exec: move to the next work day' => sub {
    my $model = _build_model();

    mock_time(
        '2015-01-01T00:00:00' => sub {
            is $model->calculate_next_exec( '2015-01-01 00:00:00', frequency => '2D', workdays => 1 ),
              '2015-01-05 00:00:00';
        }
    );
};

done_testing();

sub _build_model {
    return Baseliner::Model::SchedulerCalendar->new;
}
