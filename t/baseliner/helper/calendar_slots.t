use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst);
use TestSetup;

use Calendar::Slots;

use_ok 'Baseliner::Helper::CalendarSlots';

subtest 'slots: returns simple slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar;

    my $calendar = Calendar::Slots->new();

    $calendar->slot( weekday => 1, name => 'N', start => '00:00', end => '02:00', data => { type => 'N' } );

    my $slots = $calendar->week_of('20160104');

    my $c = mock_catalyst_c( language => 'en' );
    $c->stash->{slots} = $slots;

    my $data = _build_helper(c => $c)->slots;

    is_deeply $data->{headers}, [qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/];

    is scalar @{ $data->{rows} }, 48;

    cmp_deeply $data->{rows}->[0],
      {
        time    => '0000',
        columns => [
            {
                'date'     => undef,
                'active'   => undef,
                'duration' => '00:00 - 02:00',
                'end'      => '02:00',
                'rowspan'  => '4',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '00:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };

    for ( 1 .. 47 ) {
        cmp_deeply $data->{rows}->[$_]->{columns}, [ {}, {}, {}, {}, {}, {}, {}, ];
    }
};

subtest 'slots: slots with several durations' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar;

    my $calendar = Calendar::Slots->new();

    $calendar->slot( weekday => 1, name => 'N', start => '00:00', end => '02:00', data => { type => 'N' } );
    $calendar->slot( weekday => 1, name => 'N', start => '03:00', end => '05:00', data => { type => 'N' } );
    $calendar->slot( weekday => 1, name => 'N', start => '19:00', end => '20:00', data => { type => 'N' } );

    my $slots = $calendar->week_of('20160104');

    my $c = mock_catalyst_c( language => 'en' );
    $c->stash->{slots} = $slots;

    my $data = _build_helper(c => $c)->slots;

    cmp_deeply $data->{rows}->[0],
      {
        time    => '0000',
        columns => [
            {
                'date'     => undef,
                'active'   => undef,
                'duration' => '00:00 - 02:00',
                'end'      => '02:00',
                'rowspan'  => '4',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '00:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };

    cmp_deeply $data->{rows}->[6],
      {
        time    => '0300',
        columns => [
            {
                'date'     => undef,
                'active'   => undef,
                'duration' => '03:00 - 05:00',
                'end'      => '05:00',
                'rowspan'  => '4',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '03:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };

    cmp_deeply $data->{rows}->[38],
      {
        time    => '1900',
        columns => [
            {
                'date'     => undef,
                'active'   => undef,
                'duration' => '19:00 - 20:00',
                'end'      => '20:00',
                'rowspan'  => '2',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '19:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };
};

subtest 'slots: slots with specific dates' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar;

    my $calendar = Calendar::Slots->new();

    $calendar->slot( date => '20160104', name => 'N', start => '00:00', end => '02:00', data => { type => 'N' } );

    my $slots = $calendar->week_of('20160104');

    my $c = mock_catalyst_c( language => 'en' );
    $c->stash->{slots} = $slots;

    my $data = _build_helper(c => $c)->slots;

    cmp_deeply $data->{rows}->[0],
      {
        time    => '0000',
        columns => [
            {
                'date'     => '04/01/2016',
                'active'   => undef,
                'duration' => '00:00 - 02:00',
                'end'      => '02:00',
                'rowspan'  => '4',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '00:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };
};

subtest 'slots: do not show specific date if it is out of range' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar;

    my $calendar = Calendar::Slots->new();

    $calendar->slot( date => '20150104', name => 'N', start => '00:00', end => '02:00', data => { type => 'N' } );

    my $slots = $calendar->week_of('20160104');

    my $c = mock_catalyst_c( language => 'en' );
    $c->stash->{slots} = $slots;

    my $data = _build_helper(c => $c)->slots;

    cmp_deeply $data->{rows}->[0],
      {
        time    => '0000',
        columns => [
            {
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };
};

subtest 'slots: do not show specific date if it is out of range and generic is present' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar;

    my $calendar = Calendar::Slots->new();

    $calendar->slot( date    => '20150104', name => 'N', start => '00:00', end => '02:00', data => { type => 'N' } );
    $calendar->slot( weekday => 1,          name => 'N', start => '01:00', end => '05:00', data => { type => 'N' } );

    my $slots = $calendar->week_of('20160104');

    my $c = mock_catalyst_c( language => 'en' );
    $c->stash->{slots} = $slots;

    my $data = _build_helper(c => $c)->slots;

    cmp_deeply $data->{rows}->[2],
      {
        time    => '0100',
        columns => [
            {
                'date'     => undef,
                'active'   => undef,
                'duration' => '01:00 - 05:00',
                'end'      => '05:00',
                'rowspan'  => '8',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '01:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };
};

subtest 'slots: correctly show overlapping dates and general slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar;

    my $calendar = Calendar::Slots->new();

    $calendar->slot( date    => '20160104', name => 'N', start => '00:00', end => '02:00', data => { type => 'N' } );
    $calendar->slot( date    => '20160104', name => 'X', start => '02:00', end => '24:00', data => { type => 'N' } );
    $calendar->slot( weekday => 1,          name => 'N', start => '01:00', end => '05:00', data => { type => 'N' } );

    my $slots = $calendar->week_of('20160104');

    my $c = mock_catalyst_c( language => 'en' );
    $c->stash->{slots} = $slots;

    my $data = _build_helper(c => $c)->slots;

    cmp_deeply $data->{rows}->[0],
      {
        time    => '0000',
        columns => [
            {
                'date'     => '04/01/2016',
                'active'   => undef,
                'duration' => '00:00 - 02:00',
                'end'      => '02:00',
                'rowspan'  => '4',
                'day'      => 0,
                'type'     => 'N',
                'id'       => undef,
                'start'    => '00:00'
            },
            {},
            {},
            {},
            {},
            {},
            {},
        ],
      };
};

done_testing;

sub _setup {
    mdb->calendar->drop;
}

sub _build_helper {
    my (%params) = @_;

    Baseliner::Helper::CalendarSlots->new(%params);
}
