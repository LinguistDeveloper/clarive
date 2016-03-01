use strict;
use warnings;
use lib 't/lib';

use Test::More;
use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils qw(mock_time);

use_ok 'Baseliner::Dashboard::TopicsBurndown';

subtest 'burndown: by default show for today with hour scale' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_new_mid = mock_time '2015-01-01T01:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    my $topic_in_progress_mid = mock_time '2015-01-01T02:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    my $topic_finished = mock_time '2015-01-01T03:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    mock_time '2015-01-02T01:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_in_progress->mid
        );
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_finished,
            id_status => $status_finished->mid
        );
    };

    my $burndown = mock_time '2015-01-02T22:00:00', sub {
        $dashboard->dashboard(
            username => $user->username,
            scale    => 'hour'
        );
    };

    is_deeply $burndown,
      [
        [ '2015-01-02 00', 3 ],
        [ '2015-01-02 01', 2 ],
        [ '2015-01-02 02', 2 ],
        [ '2015-01-02 03', 2 ],
        [ '2015-01-02 04', 2 ],
        [ '2015-01-02 05', 2 ],
        [ '2015-01-02 06', 2 ],
        [ '2015-01-02 07', 2 ],
        [ '2015-01-02 08', 2 ],
        [ '2015-01-02 09', 2 ],
        [ '2015-01-02 10', 2 ],
        [ '2015-01-02 11', 2 ],
        [ '2015-01-02 12', 2 ],
        [ '2015-01-02 13', 2 ],
        [ '2015-01-02 14', 2 ],
        [ '2015-01-02 15', 2 ],
        [ '2015-01-02 16', 2 ],
        [ '2015-01-02 17', 2 ],
        [ '2015-01-02 18', 2 ],
        [ '2015-01-02 19', 2 ],
        [ '2015-01-02 20', 2 ],
        [ '2015-01-02 21', 2 ],
        [ '2015-01-02 22', 2 ],
        [ '2015-01-02 23', 2 ],
      ];
};

subtest 'burndown: scale by day' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_new_mid = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project ) };

    my $topic_in_progress_mid = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project ) };

    my $topic_finished = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project ) };

    mock_time '2015-01-02T00:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_in_progress->mid
        );
    };

    mock_time '2015-01-02T01:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_in_progress->mid
        );
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_finished->mid
        );
    };

    my $topic_during = mock_time '2015-01-04T03:00:00', sub { TestSetup->create_topic( project => $project ) };

    my $burndown = $dashboard->dashboard(
        username => $user->username,
        from     => '2015-01-02',
        to       => '2015-01-05',
        scale    => 'day'
    );

    is_deeply $burndown, [
        ['2015-01-02', 2],
        ['2015-01-03', 2],
        ['2015-01-04', 3],
        ['2015-01-05', 3],
    ];
};

subtest 'burndown: scale by month' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_new_mid = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project ) };

    my $topic_in_progress_mid = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project ) };

    my $topic_finished = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project ) };

    mock_time '2015-02-01T00:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_in_progress->mid
        );
    };

    mock_time '2015-03-01T00:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_in_progress->mid
        );
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_finished->mid
        );
    };

    my $burndown = $dashboard->dashboard(
        username => $user->username,
        from     => '2015-01-01',
        to       => '2015-03-01',
        scale    => 'month'
    );

    is_deeply $burndown, [
        ['2015-01', 2],
        ['2015-02', 2],
        ['2015-03', 2],
    ];
};

subtest 'burndown: created and closed during period' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_new_mid = mock_time '2015-01-01T01:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    my $topic_in_progress_mid = mock_time '2015-01-01T02:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    my $topic_finished = mock_time '2015-01-01T03:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    mock_time '2015-01-02T01:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_finished,
            id_status => $status_finished->mid
        );
    };

    my $topic_during = mock_time '2015-01-02T03:00:00', sub {
        TestSetup->create_topic( status => $status_new, project => $project );
    };

    mock_time '2015-01-02T04:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_during,
            id_status => $status_finished->mid
        );
    };

    mock_time '2015-01-02T05:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_new_mid,
            id_status => $status_finished->mid
        );
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_in_progress_mid,
            id_status => $status_finished->mid
        );
    };

    my $burndown = mock_time '2015-01-02T22:00:00', sub {
        $dashboard->dashboard(
            username => $user->username,
            scale    => 'hour'
        );
    };

    is_deeply $burndown,
      [
        [ '2015-01-02 00', 3 ],
        [ '2015-01-02 01', 2 ],
        [ '2015-01-02 02', 2 ],
        [ '2015-01-02 03', 3 ],
        [ '2015-01-02 04', 2 ],
        [ '2015-01-02 05', 0 ],
        [ '2015-01-02 06', 0 ],
        [ '2015-01-02 07', 0 ],
        [ '2015-01-02 08', 0 ],
        [ '2015-01-02 09', 0 ],
        [ '2015-01-02 10', 0 ],
        [ '2015-01-02 11', 0 ],
        [ '2015-01-02 12', 0 ],
        [ '2015-01-02 13', 0 ],
        [ '2015-01-02 14', 0 ],
        [ '2015-01-02 15', 0 ],
        [ '2015-01-02 16', 0 ],
        [ '2015-01-02 17', 0 ],
        [ '2015-01-02 18', 0 ],
        [ '2015-01-02 19', 0 ],
        [ '2015-01-02 20', 0 ],
        [ '2015-01-02 21', 0 ],
        [ '2015-01-02 22', 0 ],
        [ '2015-01-02 23', 0 ],
      ];
};

subtest 'burndown: filters out categories that user has no access to' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );
    my $other_category = TestSetup->create_category(
        name      => 'Other category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_finished = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project, id_category => $other_category ) };

    mock_time '2015-01-02T01:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_finished,
            id_status => $status_finished->mid
        );
    };

    my $burndown = $dashboard->dashboard(
        username => $user->username,
        from     => '2015-01-02',
        to       => '2015-01-05',
        scale    => 'day'
    );

    is_deeply $burndown, [ [ '2015-01-02', 0 ], [ '2015-01-03', 0 ], [ '2015-01-04', 0 ], [ '2015-01-05', 0 ] ];
};

subtest 'burndown: filters out topics that user has no access to project' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
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
        ]
    );
    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project       = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role       = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_finished = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( project => $other_project, id_category => $id_category, status => $status_new ) };

    mock_time '2015-01-02T01:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_finished,
            id_status => $status_finished->mid
        );
    };

    my $burndown = $dashboard->dashboard(
        username => $user->username,
        from     => '2015-01-02',
        to       => '2015-01-05',
        scale    => 'day'
    );

    is_deeply $burndown, [ [ '2015-01-02', 0 ], [ '2015-01-03', 0 ], [ '2015-01-04', 0 ], [ '2015-01-05', 0 ] ];
};

subtest 'burndown: filters by category' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );
    my $other_category = TestSetup->create_category(
        name      => 'Other category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
                action => 'action.topics.other_category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic_finished = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( status => $status_new, project => $project, id_category => $other_category ) };

    mock_time '2015-01-02T01:00:00', sub {
        Baseliner::Model::Topic->new->change_status(
            change    => 1,
            mid       => $topic_finished,
            id_status => $status_finished->mid
        );
    };

    my $burndown = $dashboard->dashboard(
        username        => $user->username,
        from            => '2015-01-02',
        to              => '2015-01-05',
        scale => 'day',
        categories      => [$id_category]
    );

    is_deeply $burndown, [ [ '2015-01-02', 0 ], [ '2015-01-03', 0 ], [ '2015-01-04', 0 ], [ '2015-01-05', 0 ] ];
};

subtest 'burndown: filters by custom filter' => sub {
    _setup();

    my $id_rule            = TestSetup->create_rule_form();
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $id_category        = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ]
    );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $dashboard = _build_dashboard();

    my $topic = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( title => 'Hello', status => $status_new, project => $project, id_category => $id_category ) };
    my $topic2 = mock_time '2015-01-01T00:00:00',
      sub { TestSetup->create_topic( title => 'Bye', status => $status_new, project => $project, id_category => $id_category ) };

    my $burndown = $dashboard->dashboard(
        username => $user->username,
        from     => '2015-01-02',
        to       => '2015-01-05',
        scale    => 'day',
        query    => q/{"title":"Hello"}/
    );

    is_deeply $burndown, [ [ '2015-01-02', 1 ], [ '2015-01-03', 1 ], [ '2015-01-04', 1 ], [ '2015-01-05', 1 ] ];
};

subtest 'burndown: filters by topic_mid' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topics.sprint.view',
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my ($status_new, $status_in_progress, $status_finished) = _create_statuses();

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status_new->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status_new->mid );

    my $sprint1_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #1',
        status      => $status_new
    );

    my $changeset1_mid = mock_time '2016-01-02', sub {
        TestSetup->create_topic(
            project     => $project,
            id_category => $id_changeset_category,
            title       => 'Fix everything',
            status      => $status_new
        );
    };

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset1_mid, sprint => [$sprint1_mid] } );

    my $sprint2_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #2',
        status      => $status_new
    );

    my $changeset2_mid = mock_time '2016-01-02', sub {
        TestSetup->create_topic(
            project     => $project,
            id_category => $id_changeset_category,
            title       => 'Fix everything',
            status      => $status_new
        );
    };

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset2_mid, sprint => [$sprint2_mid] } );

    my $dashboard = _build_dashboard();

    my $burndown = $dashboard->dashboard(
        username  => $user->username,
        scale     => 'day',
        from      => '2016-01-01',
        to        => '2016-01-03',
        topic_mid => $sprint2_mid
    );

    is_deeply $burndown, [['2016-01-01' => 0], ['2016-01-02' => 1], ['2016-01-03' => 1]];
};

subtest 'burndown: selects dates with including' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my ($status_new, $status_in_progress, $status_finished) = _create_statuses();

    my $id_changeset_rule = _create_changeset_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status_new->mid );

    my $changeset_mid = mock_time '2016-01-02 23:59:59', sub {
        TestSetup->create_topic(
            project     => $project,
            id_category => $id_changeset_category,
            title       => 'Fix everything',
            status      => $status_new
        );
    };

    my $dashboard = _build_dashboard();

    my $burndown = $dashboard->dashboard(
        username => $user->username,
        scale    => 'day',
        from     => '2016-01-01',
        to       => '2016-01-02',
    );

    is_deeply $burndown, [['2016-01-01' => 0], ['2016-01-02' => 1]];
};

done_testing();

sub _create_statuses {
    my $status_new         = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    return ( $status_new, $status_in_progress, $status_finished )
}

sub _create_sprint_form {
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
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
}

sub _create_changeset_form {
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
            $params{with_sprint}
            ? (
                {
                    "attributes" => {
                        "data" => {
                            id_field      => 'sprint',
                            release_field => 'changesets'
                        },
                        "key" => "fieldlet.system.release",
                        name  => 'Sprint',
                    }
                }
              )
            : (),
        ],
    );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',          'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules'
    );

    TestUtils->cleanup_cis;

    mdb->event->drop;
    mdb->rule->drop;
    mdb->role->drop;
    mdb->category->drop;
    mdb->topic->drop;
    mdb->activity->drop;
}

sub _build_dashboard {
    return Baseliner::Dashboard::TopicsBurndown->new;
}
