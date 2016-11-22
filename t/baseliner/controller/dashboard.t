use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst', 'mock_time';
use TestSetup;

use Capture::Tiny qw(capture);
use Class::Date;
use Clarive::ci;
use Clarive::mdb;

use_ok 'Baseliner::Controller::Dashboard';

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

    # This is the original offset, so we don't go back in time on the systems where epoch cannot be < 0
    my $dt_offset = 3600 * 24 * 30;

    # generate a bunch of dates for a wide week range
    for my $unit_shift ( 1..2 ) {
        for my $dt ( 0..11 ) {   # test a year
            $dt = $dt * $SECS_IN_DAY;  # come up with an epoch daily
            for my $first_day ( 0..6 ) {  #
                my $c = _build_c( req => { params => { username => 'root', scale=>'daily', first_weekday=>$first_day, units_from=>$unit_shift, units_until=>$unit_shift } } );
                my $stash, my $data;
                mock_time $dt_offset + 1 + $dt => sub {
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

subtest 'list_topics: returns empty response when no topics' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    is_deeply $stash,
      {
        'json' => {
            'success' => \1,
            'cis'     => {},
            'data'    => []
        }
      };
};

subtest 'list_topics: returns topics' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category(id_rule => $id_rule);

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project);

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => {} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    cmp_deeply $stash,
      {
        'json' => {
            'success' => \1,
            'cis'     => ignore(),
            'data'    => [ignore()]
        }
      };

    my $data = $stash->{json}->{data}->[0];

    is $data->{title}, 'New Topic';
};

subtest 'list_topics: returns topics limited' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category(id_rule => $id_rule);

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    TestSetup->create_topic(id_category => $id_category, project => $project) for 1 .. 10;

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { limit => 5} } );

    $controller->list_topics($c);

    my $data = $c->stash->{json}->{data};

    is scalar @$data, 5;
};

subtest 'list_topics: returns topics filtered by category' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category2}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category,  status => $status, title => 'Topic' );
    TestSetup->create_topic( project => $project, id_category => $id_category2, status => $status, title => 'Topic2' );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { categories => [$id_category] } } );

    $controller->list_topics($c);

    my $data = $c->stash->{json}->{data};

    is scalar @$data, 1;
    is $data->[0]->{title}, 'Topic';
};

subtest 'list_topics: returns topics filtered by status' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status2  = TestUtils->create_ci( 'status', name => 'Closed', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    TestSetup->create_topic( project => $project, id_category => $id_category,  status => $status, title => 'Topic' );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status2, title => 'Topic2' );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { statuses => [$status->mid]} } );

    $controller->list_topics($c);

    my $data = $c->stash->{json}->{data};

    is scalar @$data, 1;
    is $data->[0]->{title}, 'Topic';
};

subtest 'list_topics: returns topics filtered by status exclusively' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status2  = TestUtils->create_ci( 'status', name => 'Closed', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category,  status => $status, title => 'Topic' );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status2, title => 'Topic2' );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { statuses => [$status->mid], not_in_status => 1} } );

    $controller->list_topics($c);

    my $data = $c->stash->{json}->{data};

    is scalar @$data, 1;
    is $data->[0]->{title}, 'Topic2';
};

subtest 'list_topics: does not return topics if user does not have access' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category(name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid);

    my $id_role = TestSetup->create_role;

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    TestSetup->create_topic(project => $project, id_category => $id_category, status => $status);

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => {} } );

    $controller->list_topics($c);

    my $data = $c->stash->{json}->{data};

    is scalar @$data, 0;
};

subtest 'list_topics: filters by user Any' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);
    my $developer2 = TestSetup->create_user(id_role => $id_role, project => $project, username => 'Developer2');

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project);
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $developer->mid, rel_type => 'topic_users'});

    my $topic_mid2 = TestSetup->create_topic(id_category => $id_category, project => $project);
    mdb->master_rel->insert(
        { from_mid => $topic_mid2, to_mid => $developer2->mid, rel_type => 'topic_users'});

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => {assigned_to => 'Any'} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is scalar(@$data), 2;
};

subtest 'list_topics: filters by user Current' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);
    my $developer2 = TestSetup->create_user(id_role => $id_role, project => $project, username => 'Developer2');

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic');
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $developer->mid, rel_type => 'topic_users'});

    my $topic_mid2 = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'His Topic');
    mdb->master_rel->insert(
        { from_mid => $topic_mid2, to_mid => $developer2->mid, rel_type => 'topic_users'});

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => {assigned_to => 'current'} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};
    is scalar(@$data), 1;

    is $data->[0]->{title}, 'My Topic';
};

subtest 'list_topics: filters by user Current when no topics' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic');

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => {assigned_to => 'current'} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};
    is scalar(@$data), 0;
};

subtest 'list_topics: sorts topics DESC by default' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic2');

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => {params => {sort => 'topic_name'}} );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is $data->[0]->{title}, 'My Topic2';
    is $data->[1]->{title}, 'My Topic';
};

subtest 'list_topics: sorts topics' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule     = TestSetup->create_common_topic_rule_form;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic2');

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => { sort => 'topic_name', dir => 'ASC' } } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is $data->[0]->{title}, 'My Topic';
    is $data->[1]->{title}, 'My Topic2';
};

subtest 'list_topics: filters topics by project' => sub {
    _setup();

    my $project1 = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;

    my $id_rule = TestSetup->create_rule_form( rule_tree => TestSetup->_fieldlets() );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => [$project1, $project2]);

    my $topic_mid  = TestSetup->create_topic( project => $project1, id_category => $id_category, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project2, id_category => $id_category, title => 'My Topic2' );

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => { project_id => $project1->mid } } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is @$data, 1;
    is $data->[0]->{title}, 'My Topic';
};

subtest 'list_topics: returns all topics without limit' => sub {
    _setup();

    my $project1 = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;

    my $id_rule = TestSetup->create_rule_form( rule_tree => TestSetup->_fieldlets() );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => [$project1, $project2]);

    my $topic_mid  = TestSetup->create_topic( project => $project1, id_category => $id_category, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project2, id_category => $id_category, title => 'My Topic2' );

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => { limit => 0 } } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is @$data, 2;
};

subtest 'list_topics: returns limited topics' => sub {
    _setup();

    my $project1 = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;

    my $id_rule = TestSetup->create_rule_form( rule_tree => TestSetup->_fieldlets() );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => [$project1, $project2]);

    my $topic_mid  = TestSetup->create_topic( project => $project1, id_category => $id_category, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project2, id_category => $id_category, title => 'My Topic2' );

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => { limit => 1 } } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is @$data, 1;
};

subtest 'topics_by_field: counts topics by status' => sub {
    _setup();

    my $status_new = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );

    my $id_rule = TestSetup->create_rule_form( rule_tree => TestSetup->_fieldlets() );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic', status => $status_new);
    my $topic_mid2 = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic2', status => $status_in_progress);
    my $topic_mid3 = TestSetup->create_topic(id_category => $id_category, project => $project, title => 'My Topic3', status => $status_in_progress);

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => { group_by => 'topics_by_status'} } );

    $controller->topics_by_field($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'success'     => \1,
            'topics_list' => {
                'New'         => [ ignore() ],
                'In Progress' => [ ignore(), ignore() ]
            },
            'data' => [ [ 'In Progress', 2 ], [ 'New', 1 ] ],
            'colors' => {
                'New'         => undef,
                'In Progress' => undef
            }
        }
      };
};

subtest 'topics_by_field: groups topics by field' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 = TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 = TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category1}]
            },
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category2}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project, id_category => $id_category1, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(project => $project, id_category => $id_category1, title => 'My Topic2');
    my $topic_mid3 = TestSetup->create_topic(project => $project, id_category => $id_category2, title => 'My Topic3');

    my $controller = _build_controller();

    my $c = _build_c(
        username => $developer->username,
        req      => {
            params => {
                'group_threshold' => '1',
                'group_by'   => 'topics_by_category',
            }
        }
    );

    $controller->topics_by_field($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is_deeply $data, [ [ Category1 => 2 ], [Category2 => 1] ];
};

subtest 'topics_by_field: sorts by label' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 = TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 = TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category1}]
            },
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category2}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project, id_category => $id_category1, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(project => $project, id_category => $id_category2, title => 'My Topic2');
    my $topic_mid3 = TestSetup->create_topic(project => $project, id_category => $id_category2, title => 'My Topic3');

    my $controller = _build_controller();

    my $c = _build_c(
        username => $developer->username,
        req      => {
            params => {
                'group_threshold' => '0.1',
                'group_by'        => 'topics_by_category',
                'sort_by_labels'  => 'on'
            }
        }
    );

    $controller->topics_by_field($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is_deeply $data, [ [ Category1 => 1 ], [Category2 => 2] ];
};

subtest 'topics_by_field: truncates labels' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 = TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 = TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category1}]
            },
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category2}]
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project, id_category => $id_category1, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(project => $project, id_category => $id_category2, title => 'My Topic2');
    my $topic_mid3 = TestSetup->create_topic(project => $project, id_category => $id_category2, title => 'My Topic3');

    my $controller = _build_controller();

    my $c = _build_c(
        username => $developer->username,
        req      => {
            params => {
                'group_threshold'   => '1',
                'group_by'          => 'topics_by_category',
                'sort_by_labels'    => 'on',
                'max_legend_length' => 5,
            }
        }
    );

    $controller->topics_by_field($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is_deeply $data, [ [ Categ => 2 ], [Categ => 1] ];
};

subtest 'topics_by_field: groups topics by field in a topic' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule = TestSetup->create_rule_form_changeset();
    my $id_release_category = TestSetup->create_category( name => 'Release', id_rule => $id_rule );

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_rule );
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.topics.view',
                bounds => [ { id_category => $id_release_category } ]
            },
            {   action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release Parent',
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child',
        release     => $release_mid,
    );

    my $changeset_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child2',
        release     => $changeset_mid,
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $developer->username,
        req      => {
            params => {
                'group_threshold' => '1',
                'group_by'        => 'topics_by_category',
                topic_mid         => $release_mid,
            }
        }
    );

    $controller->topics_by_field($c);

    my $stash = $c->stash;

    my $topics_list = $stash->{json}->{topics_list};

    is_deeply $topics_list, { Changeset => [ $changeset_mid, $changeset_mid2 ] };
};

subtest 'topics_by_field: filter topics by depth in a topic' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $id_rule = TestSetup->create_rule_form_changeset();
    my $id_release_category = TestSetup->create_category( name => 'Release', id_rule => $id_rule );

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_rule );
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.topics.view',
                bounds => [ { id_category => $id_release_category } ]
            },
            {   action => 'action.topics.view',
                bounds => [ { id_category => $id_changeset_category } ]
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release Parent',
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child',
        release     => $release_mid,
    );

    my $changeset_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child2',
        release     => $changeset_mid,
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my $c = _build_c(
        username => $developer->username,
        req      => {
            params => {
                'group_threshold' => '1',
                'group_by'        => 'topics_by_category',
                topic_mid         => $release_mid,
                depth             => 1
            }
        }
    );

    $controller->topics_by_field($c);

    my $stash = $c->stash;

    my $topics_list = $stash->{json}->{topics_list};

    is_deeply $topics_list, { Changeset => [$changeset_mid] };
};

subtest 'topics_burndown_ng: sends correct default args to dashboard' => sub {
    _setup();

    my $dashboard = Test::MonkeyMock->new;
    $dashboard->mock(dashboard => sub {});

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock(_build_dashboard_topics_burndown => sub {$dashboard});

    my $c = _build_c(
        username => 'root',
        req      => {
            params => {
            }
        }
    );

    mock_time '2016-01-01 12:00:00', sub {
        $controller->topics_burndown_ng($c);
    };

    my %params = $dashboard->mocked_call_args('dashboard');
    is_deeply \%params,
      {
        'query'           => undef,
        'id_project'      => undef,
        'categories'      => [],
        'topic_mid'       => undef,
        'username'        => 'root',
        'from'            => '2016-01-01 00:00:00',
        'to'              => '2016-01-01 12:00:00',
        'date_field'      => undef,
        'scale'           => undef,
        'closed_statuses' => undef
      };
};

subtest 'topics_burndown_ng: sends correct args to dashboard when period' => sub {
    _setup();

    my $dashboard = Test::MonkeyMock->new;
    $dashboard->mock( dashboard => sub { } );

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_dashboard_topics_burndown => sub { $dashboard } );

    my $c = _build_c(
        username => 'root',
        req      => {
            params => {
                selection_method      => 'period',
                select_by_period_from => '2016-01-01',
                select_by_period_to   => '2016-02-01',
            }
        }
    );

    $controller->topics_burndown_ng($c);

    my %params = $dashboard->mocked_call_args('dashboard');
    is_deeply \%params,
      {
        'query'           => undef,
        'id_project'      => undef,
        'categories'      => [],
        'topic_mid'       => undef,
        'username'        => 'root',
        'from'            => '2016-01-01',
        'to'              => '2016-02-01',
        'date_field'      => undef,
        'scale'           => undef,
        'closed_statuses' => undef
      };
};

subtest 'topics_burndown_ng: sends correct args to dashboard when duration' => sub {
    _setup();

    my $dashboard = Test::MonkeyMock->new;
    $dashboard->mock( dashboard => sub { } );

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_dashboard_topics_burndown => sub { $dashboard } );

    my $c = _build_c(
        username => 'root',
        req      => {
            params => {
                selection_method          => 'duration',
                select_by_duration_range  => 'day',
                select_by_duration_offset => '1',
            }
        }
    );

    mock_time '2016-01-01 12:00:00', sub {
        $controller->topics_burndown_ng($c);
    };

    my %params = $dashboard->mocked_call_args('dashboard');
    is_deeply \%params,
      {
        'query'           => undef,
        'id_project'      => undef,
        'categories'      => [],
        'topic_mid'       => undef,
        'username'        => 'root',
        'from'            => '2015-12-31 00:00:00',
        'to'              => '2015-12-31 23:59:59',
        'date_field'      => undef,
        'scale'           => undef,
        'closed_statuses' => undef
      };
};

subtest 'topics_burndown_ng: sends correct args to dashboard when topic and fields' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project = TestUtils->create_ci_project();

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid =
      TestSetup->create_topic( id_category => $id_topic_category, from => '2016-01-01', to => '2016-02-02', username => $user->name);
    my $dashboard = Test::MonkeyMock->new;
    $dashboard->mock( dashboard => sub { } );

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_dashboard_topics_burndown => sub { $dashboard } );

    my $c = _build_c(
        username => 'root',
        req      => {
            params => {
                topic_mid                   => $topic_mid,
                selection_method            => 'topic_filter',
                select_by_topic_filter_from => 'from',
                select_by_topic_filter_to   => 'to',
            }
        }
    );

    $controller->topics_burndown_ng($c);

    my %params = $dashboard->mocked_call_args('dashboard');
    is_deeply \%params,
      {
        'query'           => undef,
        'id_project'      => undef,
        'categories'      => [],
        'topic_mid'       => $topic_mid,
        'username'        => 'root',
        'from'            => '2016-01-01',
        'to'              => '2016-02-02',
        'date_field'      => undef,
        'scale'           => undef,
        'closed_statuses' => undef
      };
};

subtest 'viewjobs: returns mid jobs filtered by status' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();

    my $project           = TestUtils->create_ci_project;
    my $id_role           = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [{}]} ] );
    my $user              = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid         = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule           = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };
    capture {
        $job_ci3 = TestSetup->create_job(
            final_status => 'CANCELLED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { status => 'FINISHED' } } );

    $controller->viewjobs($c);

    is $c->{stash}->{jobs}, $job_ci->{mid} . ',' . $job_ci2->{mid};
};

subtest 'viewjobs: returns mid jobs filtered by period' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project   = TestUtils->create_ci_project;
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [{}]} ] );
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule   = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        mock_time '2016-01-01 00:05:00' => sub {
            $job_ci = TestSetup->create_job(
                final_status => 'FINISHED',
                changesets   => [$topic_mid],
            );
        };
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
        );
    };
    capture {
        $job_ci3 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
        );
    };

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { period => '7D' } } );

    $controller->viewjobs($c);

    is $c->{stash}->{jobs}, $job_ci2->{mid} . ',' . $job_ci3->{mid};
};

subtest 'viewjobs: returns mid jobs filtered by bl' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project   = TestUtils->create_ci_project;
    my $bl        = TestUtils->create_ci( 'bl', name => 'PROD', bl => 'PROD' );
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [{}] } ] );
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule   = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci3 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'DEV'
        );
    };

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { bl => $bl->name } } );

    $controller->viewjobs($c);

    is $c->{stash}->{jobs}, $job_ci->{mid} . ',' . $job_ci2->{mid};
};

subtest 'list_jobs: returns empty response when no jobs' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

    $controller->list_jobs($c);

    my $stash = $c->stash;

    is_deeply $stash,
      {
        'json' => {
            'success' => \1,
            'data'    => []
        }
      };
};

subtest 'list_jobs: returns no jobs if user does not have permission' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_common_topic_rule_form;
    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role;

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );
    my $changeset = mdb->topic->find_one( { mid => $changeset_mid } );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid],
            bl         => 'PROD',
            bl_to      => 'PROD'
        );
    };

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => {} } );

    $controller->list_jobs($c);

    my $stash = $c->stash;

    is_deeply $stash,
      {
        'json' => {
            'success' => \1,
            'data'    => []
        }
      };
};

subtest 'list_jobs: returns jobs allowed to user' => sub {
    _setup();

    TestUtils->create_ci('bl', bl => 'QA');
    TestUtils->create_ci('bl', bl => 'PROD');

    my $id_changeset_rule = TestSetup->create_common_topic_rule_form;
    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');
    my $id_role =
      TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ { bl => 'QA' } ] } ] );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );
    my $changeset_mid2
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project2, is_changeset => 1 );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid],
            bl         => 'QA',
            bl_to      => 'QA'
        );

        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid2],
            bl         => 'QA',
            bl_to      => 'QA'
        );

        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid],
            bl         => 'PROD',
            bl_to      => 'PROD'
        );
    };

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => {} } );

    $controller->list_jobs($c);

    my $stash = $c->stash;

    is @{ $c->stash->{json}->{data} }, 1;
    is $c->stash->{json}->{data}->[0]->{bl}, 'QA';
};

subtest 'list_jobs: returns jobs allowed to user filtered by bl' => sub {
    _setup();

    my $bl_QA = TestUtils->create_ci('bl', bl => 'QA');
    my $bl_PROD = TestUtils->create_ci('bl', bl => 'PROD');

    my $id_changeset_rule = TestSetup->create_common_topic_rule_form;
    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');
    my $id_role =
      TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );
    my $changeset_mid2
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project2, is_changeset => 1 );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid],
            bl         => 'QA',
            bl_to      => 'QA'
        );

        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid2],
            bl         => 'QA',
            bl_to      => 'QA'
        );

        TestUtils->create_ci(
            'job',
            changesets => [$changeset_mid],
            bl         => 'PROD',
            bl_to      => 'PROD'
        );
    };

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => {bls => [$bl_QA->mid]} } );

    $controller->list_jobs($c);

    my $stash = $c->stash;

    is @{ $c->stash->{json}->{data} }, 1;
    is $c->stash->{json}->{data}->[0]->{bl}, 'QA';
};

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',
        'Baseliner::Controller::Job',
    );
    TestUtils->cleanup_cis;

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->category->drop;
    mdb->topic->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->job_log->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _create_topic_form {
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'from',
                        "fieldletType" => "fieldlet.datetime",
                    },
                    "key" => "fieldlet.datetime",
                    name  => 'From',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'to',
                        "fieldletType" => "fieldlet.datetime",
                    },
                    "key" => "fieldlet.datetime",
                    name  => 'To',
                }
            },
            {   "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ],
    );
}

sub _build_controller {
    Baseliner::Controller::Dashboard->new( application => '' );
}

done_testing;
