use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;
use Baseliner::Utils qw(parse_dt _dt);

use_ok 'Baseliner::Model::Calendar';

subtest 'merge_calendars: merges calendars correctly' => sub {
    _setup();

    my $id_cal  = TestSetup->create_calendar( bl => 'QA', name => 'Calendar' );
    my $id_cal2 = TestSetup->create_calendar( bl => '*',  name => 'Calendar2' );
    my @days    = ( 0 .. 6 );
    my @id_win;
    for my $day (@days) {
        my $id_win  = mdb->seq('calendar_window');
        my $id_win2 = mdb->seq('calendar_window');
        push @id_win, $id_win;
        mdb->calendar_window->insert(
            {
                'id'         => $id_win,
                'active'     => 1,
                'day'        => $day,
                'end_date'   => undef,
                'end_time'   => '00:07',
                'start_date' => undef,
                'start_time' => '00:06',
                'type'       => 'U',
                id_cal       => $id_cal
            }
        );
        mdb->calendar_window->insert(
            {
                'id'         => $id_win2,
                'active'     => 1,
                'day'        => $day,
                'end_date'   => undef,
                'end_time'   => '00:10',
                'start_date' => undef,
                'start_time' => '00:09',
                'type'       => 'U',
                id_cal       => $id_cal2
            }
        );
    }

    my $date    = '2016-01-02 00:05:00';
    my $project = TestUtils->create_ci_project();

    my @rel_cals = mdb->calendar->find(
        {
            ns => { '$in' => [ [ $project->{mid} ], '/', 'Global', undef ] },
            bl => { '$in' => [ 'QA', '*' ] }
        }
    )->all;
    my @ns_cals = map { $_->{ns} } @rel_cals;

    my $model = _build_model();

    my $hours = $model->merge_calendars( ns => mdb->in(@ns_cals), bl => 'QA', date => $date );
    my @available_slots = sort keys %$hours;

    is scalar @available_slots, 2;
    is $hours->{ $available_slots[0] }->{cal}, 'Calendar';
    is $hours->{ $available_slots[1] }->{cal}, 'Calendar2';
};

subtest 'check_dates: no data' => sub {
    _setup();

    my $model = _build_model();
    my ( $hour_store, @rel_cals ) = $model->check_dates();
    is @$hour_store, 0;
    is @rel_cals,    0;
};

subtest 'check_dates: returns correct data' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar( bl => 'PROD', name => 'Calendar' );
    my @id_win        = _create_initial_slots( id_cal => $id_cal );
    my $project       = TestUtils->create_ci_project();
    my $changeset_mid = TestSetup->create_changeset( project => $project );

    my $model = _build_model();

    my $date = _dt();
    my ( $hour_store, @rel_cals ) = $model->check_dates( $date, 'PROD', $project->{mid} );
    my $now                  = Class::Date->now->strftime("%H:%M");
    my $first_time_available = $hour_store->[0]->[0];

    is $first_time_available, $now;
    is $rel_cals[0]->{bl}, 'PROD';
    is $rel_cals[0]->{id}, $id_cal;
};

subtest 'delete_multi: deletes calendars and windows' => sub {
    _setup();

    mdb->calendar->insert( { id => '1' } );
    mdb->calendar_window->insert( { id_cal => '1' } );

    mdb->calendar->insert( { id => '2' } );
    mdb->calendar_window->insert( { id_cal => '2' } );

    mdb->calendar->insert( { id => '3' } );
    mdb->calendar_window->insert( { id_cal => '3' } );

    my $model = _build_model();

    $model->delete_multi( ids => [ 1, 2 ] );

    is( mdb->calendar->count,                     1 );
    is( mdb->calendar->find_one->{id},            3 );
    is( mdb->calendar_window->find_one->{id_cal}, 3 );
};

done_testing;

sub _build_model {
    Baseliner::Model::Calendar->new;
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',             'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',    'BaselinerX::Type::Menu',
        'BaselinerX::Type::Config',   'BaselinerX::Fieldlets',
        'BaselinerX::Type::Fieldlet', 'Baseliner::Model::Topic',
        'Baseliner::Controller::Slot',
    );

    TestUtils->cleanup_cis;

    mdb->calendar->drop;
    mdb->calendar_window->drop;
}

sub _create_initial_slots {
    my (%params) = @_;

    my @days = $params{days} ? @{ $params{days} } : ( 0 .. 6 );

    my @id_win;
    for my $day (@days) {
        my $id_win = mdb->seq('calendar_window');
        push @id_win, $id_win;
        mdb->calendar_window->insert(
            {
                'id'         => $id_win,
                'active'     => 1,
                'day'        => $day,
                'end_date'   => undef,
                'end_time'   => '24:00',
                'start_date' => undef,
                'start_time' => '00:00',
                'type'       => 'U',
                %params
            }
        );
    }

    return @id_win;
}
