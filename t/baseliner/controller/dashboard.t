use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst', 'mock_time';

BEGIN {
    TestEnv->setup;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::Dashboard;
use Class::Date;

our $SECS_IN_DAY = 3600 * 24;

subtest 'roadmap: consistent week ranges by setting from and until and random times' => sub {
    _setup();
    my $controller = _build_controller();

    # generate a bunch of dates for a wide week range
    for my $wk_shift ( 1..3 ) {
        my $c = _build_c( req => { params => { username => 'root', units_from=>$wk_shift, units_until=>$wk_shift } } );

        for my $epoch ( 1..366 ) {
            my $dt = $epoch*($SECS_IN_DAY + int(rand($SECS_IN_DAY)));
            mock_time $dt => sub {
                $controller->roadmap($c);
            };
            my $stash = $c->stash;
            is @{ $stash->{json}{data} }, 1+(2*$wk_shift), "is ".(1+2*$wk_shift)." weeks for " . Class::Date->new($dt) . "";
        }
    }
};

subtest 'roadmap: first week should always be the last first weekday before today - weekshift' => sub {
    _setup();

    my $controller = _build_controller();

    # generate a bunch of dates for a wide week range
    for my $wk_shift ( 0..2 ) {
        for my $dt ( 0..30 ) {   # test a month worth of epochs
            $dt = $dt * $SECS_IN_DAY;  # come up with an epoch
            for my $first_day ( 0..6 ) {  # from Sunday to Saturday
                my $c = _build_c( req => { params => { username => 'root', first_weekday=>$first_day, units_from=>$wk_shift, units_until=>$wk_shift } } );
                mock_time 1+$dt => sub {
                    $controller->roadmap($c);
                };
                my $stash = $c->stash;
                is( Class::Date->new($stash->{json}{data}->[0]->{date})->_wday, $first_day, "ok for weekday $first_day for " . Class::Date->new(1+$dt) );
            }
        }
    }
};

subtest 'roadmap: build a monthly scaled calendar' => sub {
    _setup();
    my $controller = _build_controller();

    # generate a bunch of dates for a wide week range
    for my $unit_shift ( 1..2 ) {
        for my $dt ( 0..11 ) {   # test a year
            $dt = $dt * $SECS_IN_DAY * 32;  # come up with an epoch monthly
            for my $first_day ( 0..6 ) {  # 
                my $c = _build_c( req => { params => { username => 'root', scale=>'monthly', first_weekday=>$first_day, units_from=>$unit_shift, units_until=>$unit_shift } } );
                mock_time 1+$dt => sub {
                    $controller->roadmap($c);
                };
                my $stash = $c->stash;
                my $data = $stash->{json}{data};
                is( (Class::Date->new($data->[0]->{date})+'1M')->string, $data->[1]->{date}, 'first and second separated by a month' );
            }
        }
    }
};

subtest 'roadmap: build a daily scaled calendar' => sub {
    _setup();
    my $controller = _build_controller();

    # generate a bunch of dates for a wide week range
    for my $unit_shift ( 1..2 ) {
        for my $dt ( 0..11 ) {   # test a year
            $dt = $dt * $SECS_IN_DAY;  # come up with an epoch daily
            for my $first_day ( 0..6 ) {  # 
                my $c = _build_c( req => { params => { username => 'root', scale=>'daily', first_weekday=>$first_day, units_from=>$unit_shift, units_until=>$unit_shift } } );
                my $stash, my $data;
                mock_time 1+$dt => sub {
                    $controller->roadmap($c);
                    my $tday = Class::Date->now;
                    $stash = $c->stash;
                    $data = $stash->{json}{data};
                    is( (Class::Date->new($data->[0]->{date})+ ($unit_shift . 'D') )->string, substr( $tday->string, 0,10).' 00:00:00', "$data->[0]->{date} first day is a $unit_shift shift units away from today $tday" );
                };
                is( (Class::Date->new($data->[0]->{date})+'1D')->string, $data->[1]->{date}, 'first and second separated by a day' );
            }
        }
    }
};

subtest 'roadmap: basic condition take in' => sub {
    _setup();
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { condition=>'"topic":{"$regex":"^a"}', 
                username => 'root' } } );
    $controller->roadmap($c);
    my $stash = $c->stash;
    is @{ $stash->{json}{data} }, 21, 'get the default 10wks + 10wks + 1 rows';
};

############ end of tests

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _setup {
    Baseliner::Core::Registry->clear();
    TestUtils->register_ci_events();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::Dashboard->new( application => '' );
}

done_testing;
