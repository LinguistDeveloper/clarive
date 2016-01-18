use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst', 'mock_time';
BEGIN { TestEnv->setup }
use TestSetup;

use Clarive::ci;
use Clarive::mdb;
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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project);

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => {} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    cmp_deeply $stash,
      {
        'json' => {
            'success' => \1,
            'cis'     => {},
            'data'    => [ignore()]
        }
      };

    my $data = $stash->{json}->{data}->[0];

    is $data->{title}, 'New Topic';
};

subtest 'list_topics: returns topics limited' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    TestSetup->create_topic(project => $project) for 1 .. 10;

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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            },
            {
                action => 'action.topics.othercategory.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $id_category = TestSetup->create_category(name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid);
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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);
    my $developer2 = TestSetup->create_user(id_role => $id_role, project => $project, username => 'Developer2');

    my $topic_mid = TestSetup->create_topic(project => $project);
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $developer->mid, rel_type => 'topic_users'});

    my $topic_mid2 = TestSetup->create_topic(project => $project);
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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);
    my $developer2 = TestSetup->create_user(id_role => $id_role, project => $project, username => 'Developer2');

    my $topic_mid = TestSetup->create_topic(project => $project, title => 'My Topic');
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $developer->mid, rel_type => 'topic_users'});

    my $topic_mid2 = TestSetup->create_topic(project => $project, title => 'His Topic');
    mdb->master_rel->insert(
        { from_mid => $topic_mid2, to_mid => $developer2->mid, rel_type => 'topic_users'});

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => {assigned_to => 'Current'} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};
    is scalar(@$data), 1;

    is $data->[0]->{title}, 'My Topic';
};

subtest 'list_topics: filters by user Current when no topics' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project, title => 'My Topic');

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => {assigned_to => 'Current'} } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};
    is scalar(@$data), 0;
};

subtest 'list_topics: sorts topics DESC by default' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(project => $project, title => 'My Topic2');

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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $developer = TestSetup->create_user(id_role => $id_role, project => $project);

    my $topic_mid = TestSetup->create_topic(project => $project, title => 'My Topic');
    my $topic_mid2 = TestSetup->create_topic(project => $project, title => 'My Topic2');

    my $controller = _build_controller();

    my $c = _build_c( username => $developer->username, req => { params => { sort => 'topic_name', dir => 'ASC' } } );

    $controller->list_topics($c);

    my $stash = $c->stash;

    my $data = $stash->{json}->{data};

    is $data->[0]->{title}, 'My Topic';
    is $data->[1]->{title}, 'My Topic2';
};

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic'
    );

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->category->drop;
    mdb->role->drop;
    mdb->rule->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::Dashboard->new( application => '' );
}

done_testing;
