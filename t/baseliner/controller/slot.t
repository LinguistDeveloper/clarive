use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use Baseliner::Utils qw(_encode_json);

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

subtest 'calendar_grid_json: returns calendar list' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.view', bl => '*' } ] );
    my $user   = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );
    TestSetup->create_calendar(bl => '*', name => 'Calendar');
    TestSetup->create_calendar(bl => '*', name => 'Calendar2');

    my $c = _build_c( username => $user->username );

    my $controller = _build_controller();
    $controller->calendar_grid_json($c);

    is @{$c->stash->{json}{data}}, 2;
    is $c->stash->{json}{totalCount}, 2;
};

subtest 'calendar_grid_json: returns calendar list with limit -1' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.view', bl => '*' } ] );
    my $user   = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );
    TestSetup->create_calendar(bl => '*', name => 'Calendar');
    TestSetup->create_calendar(bl => '*', name => 'Calendar2');

    my $c = _build_c(
        username => $user->username,
        req => { params => { limit => -1 } }
    );

    my $controller = _build_controller();
    $controller->calendar_grid_json($c);

    is @{$c->stash->{json}{data}}, 2;
    is $c->stash->{json}{totalCount}, 2;
};

subtest 'calendar_grid_json: returns calendar list with limit 1' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.calendar.view', bl => '*' } ] );
    my $user   = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );
    TestSetup->create_calendar(bl => '*', name => 'Calendar');
    TestSetup->create_calendar(bl => '*', name => 'Calendar2');

    my $c = _build_c(
        username => $user->username,
        req => { params => { limit => 1 } }
    );

    my $controller = _build_controller();
    $controller->calendar_grid_json($c);

    is @{$c->stash->{json}{data}}, 1;
    is $c->stash->{json}{totalCount}, 2;
};

subtest 'calendar_grid_json: returns names as scopes' => sub {
    _setup();

    my $area = TestUtils->create_ci('area');
    TestSetup->create_calendar(bl => '*', name => 'Calendar', ns =>$area->mid);

    my $c = _build_c( username => 'root' );
    my $controller = _build_controller();
    $controller->calendar_grid_json($c);

    is @{$c->stash->{json}{data}}, 1;
    is $c->stash->{json}{data}->[0]->{ns}, "$area->{name}";
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

subtest 'permissions_calendar: returns an error when the user does not have permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
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
    $controller->permissions_calendar($c);

    cmp_deeply $c->stash->{json}, { success => \0, msg => 'You do not have permissions to open this calendar' };
};

subtest 'build_job_window: new job gets the correct calendar related if the project belongs to a group' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $group = TestUtils->create_ci( 'group', { contents => [ $project->mid ] } );

    my $id_cal = TestSetup->create_calendar( name => 'Group', seq => '200', ns => '' . $group->mid );
    my @id_win = _create_initial_slots( id_cal => $id_cal, type => 'N' );

    my $changeset_mid = TestSetup->create_changeset( project => $project );

    my $date = DateTime->now;

    my $params = {
        bl           => 'TEST',
        date_format  => '%Y-%m-%d',
        job_contents => _encode_json( [ { mid => $changeset_mid } ] ),
        job_date     => $date
    };

    my $c = _build_c( req => { params => $params }, username => 'root' );

    my $controller = _build_controller();
    $controller->build_job_window($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            cals    => [
                {
                    name   => 'Group',
                    _id    => ignore(),
                    active => ignore(),
                    bl     => ignore(),
                    id     => ignore(),
                    ns     => ignore(),
                    seq    => ignore()
                }
            ],
            cis   => ignore(),
            data  => ignore(),
            stats => ignore()
        }
      };
};

subtest 'build_job_window: new job gets the correct first slot if the project belongs to a group' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $group = TestUtils->create_ci( 'group', { contents => [ $project->mid ] } );

    my $id_cal = TestSetup->create_calendar( name => 'Group', seq => '200', ns => '' . $group->mid );
    my @id_win = _create_initial_slots( id_cal => $id_cal, type => 'N' );

    my $changeset_mid = TestSetup->create_changeset( project => $project );

    my $date = DateTime->now;

    my $params = {
        bl           => 'TEST',
        date_format  => '%Y-%m-%d',
        job_contents => _encode_json( [ { mid => $changeset_mid } ] ),
        job_date     => $date
    };

    my $c = _build_c( req => { params => $params }, username => 'root' );

    my $controller = _build_controller();
    $controller->build_job_window($c);

    cmp_deeply $c->stash->{json}->{data}[0], [ ignore(), 'Group (N)', 'N', ignore(), ];
};

subtest 'build_job_window: no calendar available' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();

    my $changeset_mid = TestSetup->create_changeset( project => $project );

    my $id_cal = TestSetup->create_calendar( name => 'Prod', seq => '100', bl => 'PROD' );
    my @id_win = _create_initial_slots( id_cal => $id_cal, type => 'N' );

    my $date = DateTime->now;

    my $params = {
        bl           => 'TEST',
        date_format  => '%Y-%m-%d',
        job_contents => _encode_json( [ { mid => $changeset_mid } ] ),
        job_date     => $date
    };

    my $c = _build_c( req => { params => $params }, username => 'root' );

    my $controller = _build_controller();
    $controller->build_job_window($c);

    is @{ $c->stash->{json}->{data} }, 0;
};

subtest 'build_job_window: get first slot from higher priority calendar' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();

    my $changeset_mid = TestSetup->create_changeset( project => $project );

    my $date = DateTime->now;

    my $id_cal = TestSetup->create_calendar( name => 'Common', seq => '100', bl => '*' );
    my @id_win = _create_initial_slots( id_cal => $id_cal, type => 'N', days => [ $date->dow - 1 ] );

    my $id_cal2 = TestSetup->create_calendar( name => 'TEST', seq => '200', bl => 'TEST' );
    my @id_win2 = _create_initial_slots( id_cal => $id_cal2, type => 'U' );

    my $params = {
        bl           => 'TEST',
        date_format  => '%Y-%m-%d',
        job_contents => _encode_json( [ { mid => $changeset_mid } ] ),
        job_date     => $date
    };

    my $c = _build_c( req => { params => $params }, username => 'root' );

    my $controller = _build_controller();
    $controller->build_job_window($c);

    cmp_deeply $c->stash->{json}->{data}[0], [ ignore(), 'TEST (U)', 'U', ignore(), ];
};

subtest 'build_job_window: no slot available if higher priority is blocking' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();

    my $changeset_mid = TestSetup->create_changeset( project => $project );

    my $date = DateTime->now;

    my $id_cal = TestSetup->create_calendar( name => 'Common', seq => '100', bl => '*' );
    my @id_win = _create_initial_slots( id_cal => $id_cal, type => 'N', days => [ $date->dow - 1 ] );

    my $id_cal2 = TestSetup->create_calendar( name => 'TEST', seq => '200', bl => 'TEST' );
    my @id_win2 = _create_initial_slots( id_cal => $id_cal2, type => 'B', days => [ $date->dow - 1 ] );

    my $params = {
        bl           => 'TEST',
        date_format  => '%Y-%m-%d',
        job_contents => _encode_json( [ { mid => $changeset_mid } ] ),
        job_date     => $date
    };

    my $c = _build_c( req => { params => $params }, username => 'root' );

    my $controller = _build_controller();
    $controller->build_job_window($c);

    is @{ $c->stash->{json}->{data}[0] }, 0;
};

TODO: {
    local $TODO = "Fix priority check in slots";

    subtest 'build_job_window: slot available if higher priority is allowing' => sub {
        _setup();

        my $project = TestUtils->create_ci_project();

        my $changeset_mid = TestSetup->create_changeset( project => $project );

        my $date = DateTime->now;

        my $id_cal = TestSetup->create_calendar( name => 'Common', seq => '200', bl => '*' );
        my @id_win = _create_initial_slots( id_cal => $id_cal, type => 'N', days => [ $date->dow -1 ] );

        my $id_cal2 = TestSetup->create_calendar( name => 'TEST', seq => '100', bl => 'TEST' );
        my @id_win2 = _create_initial_slots( id_cal => $id_cal2, type => 'B', days => [ $date->dow -1 ] );

        my $params = {
            bl           => 'TEST',
            date_format  => '%Y-%m-%d',
            job_contents => '[{"mid": "' . $changeset_mid . '"}]',
            job_date     => $date
        };

        my $c = _build_c( req => { params => $params }, username => 'root' );

        my $controller = _build_controller();
        $controller->build_job_window($c);

        cmp_deeply $c->stash->{json}->{data}[0], [ ignore(), 'Common (N)', 'N', ignore(), ];
    };
}

done_testing;

sub _create_initial_slots {
    my (%params) = @_;

    my @days = $params{days} ? @{$params{days}} : (0 .. 6);

    my @id_win;
    for my $day ( @days ) {
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
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Menu',
        'BaselinerX::Type::Config',
        'BaselinerX::Fieldlets',
        'BaselinerX::Type::Fieldlet',
        'Baseliner::Model::Topic',
        'Baseliner::Controller::Slot',
    );

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
