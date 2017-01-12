use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils qw(mock_time);

use BaselinerX::CI::status;

use_ok 'BaselinerX::Service::GenericServices';

subtest 'get_date: returns given date' => sub {

    my $service = _build_service();

    my $date = $service->get_date( undef, { date => "2016-01-02" } );

    is $date, "2016-01-02 00:00:00";
};

subtest 'get_date: returns given date formatted' => sub {

    my $service = _build_service();

    my $date = $service->get_date( undef, { format => "%Y-%m-%dT%H:%M:%S", date => "2016-01-02" } );

    is $date, "2016-01-02T00:00:00";
};

subtest 'get_date: returns given date' => sub {

    my $service = _build_service();

    my $date = $service->get_date( undef, { date => "2016-01-02" } );

    is $date, "2016-01-02 00:00:00";
};

subtest 'get_date: returns current date' => sub {

    my $date;
    my $service = _build_service();

    mock_time "2016-01-01 00:00:00", sub {
        $date = $service->get_date( undef, undef );
    };

    is $date, "2016-01-01 00:00:00";
};

subtest 'get_date: returns current date in specified format' => sub {

    my $date;
    my $service = _build_service();

    mock_time "2016-01-01 00:00:00", sub {
        $date = $service->get_date( undef, { format => "%Y-%m-%d" } );
    };

    is $date, "2016-01-01";
};

subtest 'get_date: fails when wrong date' => sub {

    my $service = _build_service();

    like exception { $service->get_date( undef, { date => "ñññ" } ); }, qr/Date ñññ is not a valid date/;
};

done_testing;

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::GenericServices->new(%params);
}
