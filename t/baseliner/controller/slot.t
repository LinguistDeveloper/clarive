use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use_ok 'Baseliner::Controller::Slot';

subtest 'calendar_submit: creates correct slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();

    my $controller = _build_controller();

    my $params = {
        id       => '',
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find->all;
    is scalar @win, 7;

    for my $day ( 0 .. 6 ) {
        cmp_deeply $win[$day],
          {
            '_id'        => ignore(),
            'id'         => ignore(),
            'id_cal'     => $id_cal,
            'active'     => 1,
            'day'        => $day,
            'end_date'   => undef,
            'end_time'   => '24:00',
            'start_date' => undef,
            'start_time' => '00:00',
            'type'       => code( sub { $day == 4 ? 'N' : 'B' } )
          };
    }

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_submit: updates correct slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();
    my @id_win = _create_initial_slots( id_cal => $id_cal );

    my $controller = _build_controller();

    my $params = {
        id       => $id_win[0],
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find->all;
    is scalar @win, 7;

    for my $day ( 0 .. 6 ) {
        cmp_deeply $win[$day],
          {
            '_id'        => ignore(),
            'id'         => ignore(),
            'id_cal'     => $id_cal,
            'active'     => 1,
            'day'        => $day,
            'end_date'   => undef,
            'end_time'   => '24:00',
            'start_date' => undef,
            'start_time' => '00:00',
            'type'       => code( sub { $day == 4 ? 'N' : 'B' } )
          };
    }

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_submit: removes correct slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();

    my @id_win = _create_initial_slots( id_cal => $id_cal );

    my $controller = _build_controller();

    my $params = {
        id       => $id_win[4],
        id_cal   => $id_cal,
        cmd      => 'B',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find->all;
    is scalar @win, 6;

    for my $day ( 0 .. 3, 5 .. 6 ) {
        my $win = shift @win;
        cmp_deeply $win,
          {
            '_id'        => ignore(),
            'id'         => ignore(),
            'id_cal'     => $id_cal,
            'active'     => 1,
            'day'        => $day,
            'end_date'   => undef,
            'end_time'   => '24:00',
            'start_date' => undef,
            'start_time' => '00:00',
            'type'       => 'B'
          };
    }

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};


subtest 'calendar_submit: updates correct slots if new one finish before' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();
    my @id_win = _create_initial_slots( id_cal => $id_cal );

    my $controller = _build_controller();
    my $params = {
        id       => $id_win[0],
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };
    my $c = mock_catalyst_c( req => { params => $params } );
    $controller->calendar_submit($c);

    my $new_params = {
        id       => $id_win[0],
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '11:00',
        ven_fin  => '12:00',
        date     => ''
    };
    my $c_new = mock_catalyst_c( req => { params => $new_params } );

    $controller->calendar_submit($c_new);

    my @win = mdb->calendar_window->find->all;

    is scalar @win, 7;

    for my $day ( 0 .. 6 ) {
        cmp_deeply $win[$day],
          {
            '_id'        => ignore(),
            'id'         => ignore(),
            'id_cal'     => $id_cal,
            'active'     => 1,
            'day'        => $day,
            'end_date'   => undef,
            'end_time'   =>  code( sub { $day == 4 ? '12:00' : '24:00' } ),
            'start_date' => undef,
            'start_time' => code( sub { $day == 4 ? '11:00' : '00:00' } ),
            'type'       => code( sub { $day == 4 ? 'N' : 'B' } )
          };
    }

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_submit: activates correct slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();
    my @id_win = _create_initial_slots( id_cal => $id_cal, active => 0 );

    my $controller = _build_controller();

    my $params = {
        id  => $id_win[0],
        cmd => 'C1',
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find->all;
    is scalar @win, 7;

    for my $day ( 0 .. 6 ) {
        if ($day == 0) {
            is $win[$day]->{active}, '1';
        }
        else {
            is $win[$day]->{active}, '0';
        }
    }

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_submit: deactivates correct slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();
    my @id_win = _create_initial_slots( id_cal => $id_cal );

    my $controller = _build_controller();

    my $params = {
        id  => $id_win[0],
        cmd => 'C0',
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find->all;
    is scalar @win, 7;

    for my $day ( 0 .. 6 ) {
        if ($day == 0) {
            is $win[$day]->{active}, '0';
        }
        else {
            is $win[$day]->{active}, '1';
        }
    }

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_submit: merges slots' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();
    my @id_win = _create_initial_slots( id_cal => $id_cal );

    my $controller = _build_controller();

    my $params = {
        id       => $id_win[0],
        id_cal   => $id_cal,
        cmd      => 'AD',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '06:00',
        date     => ''
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find({day => 4})->all;

    cmp_deeply $win[0],
      {
        '_id'        => ignore(),
        'id'         => ignore(),
        'id_cal'     => $id_cal,
        'active'     => 0,
        'day'        => 4,
        'start_date' => undef,
        'end_date'   => undef,
        'start_time' => '00:00',
        'end_time'   => '06:00',
        'type'       => 'N'
      };

    cmp_deeply $win[1],
      {
        '_id'        => ignore(),
        'id'         => ignore(),
        'id_cal'     => $id_cal,
        'active'     => 1,
        'day'        => 4,
        'start_date' => undef,
        'end_date'   => undef,
        'start_time' => '06:00',
        'end_time'   => '24:00',
        'type'       => 'B'
      };

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_submit: merges slots with specific date' => sub {
    _setup();

    my $id_cal = TestSetup->create_calendar();
    my @id_win = _create_initial_slots( id_cal => $id_cal );

    my $controller = _build_controller();

    my $params = {
        id       => $id_win[0],
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };
    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    $params = {
        id       => $id_win[0],
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '06:00',
        date     => '8/1/2016'
    };
    $c = mock_catalyst_c( req => { params => $params } );

    $controller->calendar_submit($c);

    my @win = mdb->calendar_window->find({day => 4})->all;

    cmp_deeply $win[0],
      {
        '_id'        => ignore(),
        'id'         => ignore(),
        'id_cal'     => $id_cal,
        'active'     => 1,
        'day'        => 4,
        'start_date' => '2016-01-08',
        'end_date'   => '2016-01-08',
        'start_time' => '00:00',
        'end_time'   => '06:00',
        'type'       => 'N'
      };

    cmp_deeply $win[1],
      {
        '_id'        => ignore(),
        'id'         => ignore(),
        'id_cal'     => $id_cal,
        'active'     => 1,
        'day'        => 4,
        'start_date' => undef,
        'end_date'   => undef,
        'start_time' => '00:00',
        'end_time'   => '24:00',
        'type'       => 'N'
      };

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Calendar modified.', cal_window => ignore() } };
};

subtest 'calendar_grid: check permissions in the stash to edit calendar' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.edit', bl => '*' } ] );
    my $user = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );

    my $c = _build_c( username => $user->username );

    my $controller = _build_controller();
    $controller->calendar_grid($c);

    is $c->stash->{can_edit},  1;
    is $c->stash->{can_admin}, 0;

};

subtest 'calendar_grid: check permissions in the stash to view calendar' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.view', bl => '*' } ] );
    my $user   = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );
    my $id_cal = TestSetup->create_calendar();

    my $c = _build_c( username => $user->username );

    my $controller = _build_controller();
    $controller->calendar_grid($c);

    is $c->stash->{can_edit},  0;
    is $c->stash->{can_admin}, 0;

};

subtest 'calendar: check permissions in the stash to admin calendar' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.admin', bl => '*' } ] );
    my $user = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );

    my $id_cal = TestSetup->create_calendar();

    my $params = {
        id       => '',
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };

    my $c = _build_c( req => { params => $params }, username => $user->username );

    my $controller = _build_controller();
    $controller->calendar($c);

    is $c->stash->{can_admin}, 1;

};

subtest 'calendar: check permissions in the stash to view calendar' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.view', bl => '*' } ] );
    my $user = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );

    my $id_cal = TestSetup->create_calendar();

    my $params = {
        id       => '',
        id_cal   => $id_cal,
        cmd      => 'A',
        ven_dia  => '4',
        ven_tipo => 'N',
        ven_ini  => '00:00',
        ven_fin  => '24:00',
        date     => ''
    };

    my $c = _build_c( req => { params => $params }, username => $user->username );

    my $controller = _build_controller();
    $controller->calendar($c);

    is $c->stash->{can_edit},  0;
    is $c->stash->{can_admin}, 0;

};

done_testing;

sub _create_initial_slots {
    my (%params) = @_;

    my @id_win;
    for my $day ( 0 .. 6 ) {
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
                'type'       => 'B',
                %params
            }
        );
    }

    return @id_win;
}

sub _build_controller {
    Baseliner::Controller::Slot->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry();
    TestUtils->register_ci_events();
    TestUtils->cleanup_cis;
    mdb->calendar->drop;
    mdb->calendar_window->drop;
    mdb->role->drop;

}

sub _build_c {
    mock_catalyst_c(
        username => 'test',
        model    => Baseliner::Model::Permissions->new(),
        @_
    );
}
