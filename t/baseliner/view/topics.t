use strict;
use warnings;

use Test::More;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use Baseliner::Model::Topic;
use Baseliner::View::Topics;

subtest 'build_where: builds correct where project_security' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username );

    is_deeply $where,
      {
        '$or' => [
            {
                '_project_security.project' => {
                    '$in' => [ $project->mid ]
                },
                'category.id' => {
                    '$in' => [ $id_category1, $id_category2, ]
                }
            },
            {
                '_project_security' => undef
            }
        ]
      };
};

subtest 'build_where: builds correct where categories' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, categories => [$id_category1] );

    is_deeply $where->{'category.id'}, { '$in' => [$id_category1] };
};

subtest 'build_where: builds correct where categories from filter' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, filter => { categories => [$id_category1] } );

    is_deeply $where->{'category.id'}, { '$in' => [$id_category1] };
};

subtest 'build_where: builds correct where statuses' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status1->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, statuses => [ $status1->mid ] );

    is_deeply $where->{'category_status.id'}, { '$in' => [ $status1->mid ] };
};

subtest 'build_where: builds correct where statuses from filter' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status1->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, filter => { statuses => [ $status1->mid ] } );

    is_deeply $where->{'category_status.id'}, { '$in' => [ $status1->mid ] };
};

subtest 'build_where: builds correct where filter is JSON' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status1->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, filter => JSON::encode_json({ statuses => [ $status1->mid ] }) );

    is_deeply $where->{'category_status.id'}, { '$in' => [ $status1->mid ] };
};

subtest 'build_where: builds correct where statuses not in' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status1->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid  = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 = TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 = TestSetup->create_topic( project => $project, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where =
      $view->build_where( username => $developer->username, statuses => [ $status1->mid ], not_in_status => 1 );

    is_deeply $where->{'category_status.id'}, { '$nin' => [ $status1->mid ] };
};

subtest 'build_where: builds correct where project id' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
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
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status1->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project1 = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role  = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => [ $project1, $project2 ] );

    my $topic_mid = TestSetup->create_topic( project => $project1, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 =
      TestSetup->create_topic( project => $project1, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 =
      TestSetup->create_topic( project => $project2, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, id_project => $project1->mid );

    is_deeply $where->{'mid'}, { '$in' => [ $topic_mid, $topic_mid2 ] };
};

subtest 'build_where: builds correct where topic mid' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $project = TestUtils->create_ci_project;

    my $id_changeset_rule = _create_changeset_form( with_sprint => 1 );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status1->mid );

    my $id_sprint_rule = _create_sprint_form();
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status1->mid );

    my $sprint1_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #1',
        status      => $status1
    );

    my $changeset1_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status1
    );

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset1_mid, sprint => [$sprint1_mid] } );

    my $sprint2_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint #2',
        status      => $status1
    );

    my $changeset2_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything again',
        status      => $status1
    );

    Baseliner::Model::Topic->new->update(
        { action => 'update', topic_mid => $changeset2_mid, sprint => [$sprint2_mid] } );

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

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    my $view = _build_view();

    my $where = $view->build_where( username => $developer->username, topic_mid => $sprint1_mid );

    is_deeply $where->{'mid'}, { '$in' => [ $sprint1_mid, $changeset1_mid ] };
};

subtest 'build_where: builds correct where merging filter' => sub {
    _setup();

    my $status1 = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
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
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status1->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project1 = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role  = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => [ $project1, $project2 ] );

    my $topic_mid = TestSetup->create_topic( project => $project1, id_category => $id_category1, title => 'My Topic' );
    my $topic_mid2 =
      TestSetup->create_topic( project => $project1, id_category => $id_category1, title => 'My Topic2' );
    my $topic_mid3 =
      TestSetup->create_topic( project => $project2, id_category => $id_category2, title => 'My Topic3' );

    my $view = _build_view();

    my $where = $view->build_where(
        username   => $developer->username,
        categories => [$id_category1],
        filter     => { foo => 'bar', 'category.id' => { '$in' => [$id_category2] } }
    );

    is $where->{'foo'}, 'bar';
    is_deeply $where->{'category.id'}, { '$in' => [ $id_category1, $id_category2 ] };
};

subtest 'build_where: builds correct where category_type' => sub {
    _setup();

    my $status1      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule      = TestSetup->create_rule_form();
    my $id_category1 = TestSetup->create_category(
        name       => 'Category1',
        is_release => 1,
        id_rule    => $id_rule,
        id_status  => $status1->mid
    );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status1->mid );

    my $project1 = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role  = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => [ $project1, $project2 ] );

    my $view = _build_view();

    my $where = $view->build_where(
        username      => $developer->username,
        category_type => 'release'
    );

    is $where->{'category.is_release'}, 1;

    my $where2 = $view->build_where(
        username      => $developer->username,
        category_type => 'changeset'
    );

    is $where2->{'category.is_changeset'}, 1;
};

subtest 'view: accepts limit and skip' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    for ( 1 .. 10 ) {
        TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic ' . $_ );
    }

    my $view = _build_view();

    my $rs = $view->view( username => $developer->username, limit => 5, skip => 8 );

    is $rs->count(1), 2;
    is $rs->next->{title}, 'My Topic 9';
};

subtest 'view: accepts limit and skip from filter' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    for ( 1 .. 10 ) {
        TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic ' . $_ );
    }

    my $view = _build_view();

    my $rs = $view->view( username => $developer->username, filter => { limit => 5, start => 8 } );

    is $rs->count(1), 2;
    is $rs->next->{title}, 'My Topic 9';
};

subtest 'view: accepts sort and dir' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule = TestSetup->create_rule_form();
    my $id_category1 =
      TestSetup->create_category( name => 'Category1', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'Category2', id_rule => $id_rule, id_status => $status->mid );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category1.view',
            },
            {
                action => 'action.topics.category2.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );

    for ( 1 .. 10 ) {
        TestSetup->create_topic( project => $project, id_category => $id_category1, title => 'My Topic ' . $_ );
    }

    my $view = _build_view();

    my $rs = $view->view( username => $developer->username, sort => 'title', dir => 'desc' );

    is $rs->next->{title}, 'My Topic 9';
};

done_testing;

sub _create_sprint_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
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

sub _build_view {
    Baseliner::View::Topics->new;
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',          'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic', 'Baseliner::Model::Rules'
    );

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->category->drop;
    mdb->topic->drop;
    mdb->role->drop;
    mdb->rule->drop;
}

