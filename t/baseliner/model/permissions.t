use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::Model::Permissions';

subtest 'role_exists: checks if role exists' => sub {
    _setup();

    mdb->role->insert( { role => 'hello' } );

    my $permissions = _build_permissions();

    ok !$permissions->role_exists('unknown');
    ok $permissions->role_exists('hello');
};

subtest 'has_role_action: checks if role has action' => sub {
    _setup();

    mdb->role->insert( { role => 'role', actions => [ { action => 'foo.bar.baz' } ] } );

    my $role = mdb->role->find_one;

    my $permissions = _build_permissions();

    ok !$permissions->has_role_action( role => $role, action => 'unknown' );
    ok $permissions->has_role_action( role => $role, action => 'foo.bar.baz' );
};

subtest 'user_has_action: returns true for any action when user is root' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( username => 'root', action => 'some.action' );
};

subtest 'is_root: returns true when username is root' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    ok !$permissions->is_root( $user->username );
    ok $permissions->is_root('root');
};

subtest 'is_root: returns true when user has admin action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.admin.root' } ] );

    my $permissions = _build_permissions();

    ok $permissions->is_root( $user->username );
};

subtest 'user_actions_list: returns all available actions when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    my @actions = $permissions->user_actions_list( username => 'root' );

    ok scalar @actions;
};

subtest 'user_actions_list: returns available actions for user' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'some.action' } ] );

    my $permissions = _build_permissions();

    my @actions = $permissions->user_actions_list( username => $user->username );

    is_deeply \@actions, ['some.action'];
};

subtest 'user_actions_list: filters actions by regex' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'some.action' }, { action => 'other.action' } ] );

    my $permissions = _build_permissions();

    my @actions = $permissions->user_actions_list( username => $user->username, action => qr/some/ );

    is_deeply \@actions, ['some.action'];
};

subtest 'user_actions_list: filters actions by star bl' => sub {
    _setup();

    my $user = _create_user_with_actions(
        actions => [ { action => 'some.action', bl => '*' }, { action => 'other.action', bl => 'DEV' } ] );

    my $permissions = _build_permissions();

    my @actions = $permissions->user_actions_list( username => $user->username, bl => '*');

    is_deeply \@actions, ['some.action', 'other.action'];
};

subtest 'user_actions_list: filters actions by bl and star' => sub {
    _setup();

    my $user = _create_user_with_actions(
        actions => [ { action => 'some.action', bl => '*' }, { action => 'other.action', bl => 'DEV' } ] );

    my $permissions = _build_permissions();

    my @actions = $permissions->user_actions_list( username => $user->username, bl => 'DEV');

    is_deeply \@actions, ['some.action', 'other.action'];
};

subtest 'user_actions_list: filters actions by bl' => sub {
    _setup();

    my $user = _create_user_with_actions(
        actions => [ { action => 'some.action', bl => 'PROD' }, { action => 'other.action', bl => 'DEV' } ] );

    my $permissions = _build_permissions();

    my @actions = $permissions->user_actions_list( username => $user->username, bl => 'DEV');

    is_deeply \@actions, ['other.action'];
};

subtest 'user_roles_for_topic: returns user roles when no topic mid' => sub {
    _setup();

    my $id_role = TestSetup->create_role( actions => [ { action => 'some.action' } ] );
    my $user = _create_user_with_actions( id_role => $id_role );

    my $permissions = _build_permissions();

    my @roles = $permissions->user_roles_for_topic( username => $user->username );

    is_deeply \@roles, [$id_role];
};

subtest 'user_roles_for_topic: returns user roles for topic mid' => sub {
    _setup();

    my $id_role = TestSetup->create_role( actions => [ { action => 'some.action' } ] );
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role( actions => [ { action => 'some.other.action' } ] );
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid
            },
            $id_role2 => {
                project => $project2->mid
            }
        }
    );

    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $permissions = _build_permissions();

    my $topic_mid = TestSetup->create_topic(
        project     => [ $project, $project3 ],
        id_rule     => $id_rule,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    my @roles = $permissions->user_roles_for_topic( username => $user->username, mid => $topic_mid );

    is_deeply \@roles, [$id_role];
};

subtest 'user_actions_by_topic: returns user actions for topic mid' => sub {
    _setup();

    my $id_role =
      TestSetup->create_role( actions => [ { action => 'other.action' }, { action => 'some.action.read' } ] );
    my $project = TestUtils->create_ci('project');
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $permissions = _build_permissions();

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_rule,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    my @actions = $permissions->user_actions_by_topic( username => $user->username, mid => $topic_mid );

    is_deeply \@actions,
      [
        {
            'positive' => ['other.action'],
            'negative' => ['some.action.read']
        }
      ];
};

subtest 'user_has_read_action: returns false when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok !$permissions->user_has_read_action( username => 'root', action => 'foo.bar' );
};

subtest 'user_has_read_action: returns true when user has read action' => sub {
    _setup();

    my $id_role =
      TestSetup->create_role( actions => [ { action => 'action.topicsfield.category.status.read' } ] );
    my $project = TestUtils->create_ci('project');
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    ok $permissions->user_has_read_action(
        username => $user->username,
        action   => 'action.topicsfield.category.status.read'
    );
};

subtest 'user_has_read_action: returns false when user does not have read action' => sub {
    _setup();

    my $id_role =
      TestSetup->create_role( actions => [ ] );
    my $project = TestUtils->create_ci('project');
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_read_action(
        username => $user->username,
        action   => 'action.topicsfield.category.status.read'
    );
};

subtest 'user_can_search_ci: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 0;
};

subtest 'user_can_search_ci: true when admin' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 1;
};

subtest 'user_can_search_ci: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.search.ci' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 1;
};

subtest 'user_can_search_ci: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions( username => 'root' );

    my $permissions = _build_permissions();

    is $permissions->user_can_search_ci( $user->username ), 1;
};

subtest 'user_is_ci_admin: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_is_ci_admin( $user->username ), 0;
};

subtest 'user_is_ci_admin: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_is_ci_admin( $user->username ), 1;
};

subtest 'user_is_ci_admin: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions( username => 'root' );

    my $permissions = _build_permissions();

    is $permissions->user_is_ci_admin( $user->username ), 1;
};

subtest 'user_can_admin_ci: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 0;
};

subtest 'user_can_admin_ci: false when no collection' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin.%.variable' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 0;
};

subtest 'user_can_admin_ci: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin.%.variable' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username, 'variable' ), 1;
};

subtest 'user_can_admin_ci: true when ci admin' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 1;
};

subtest 'user_can_admin_ci: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions( username => 'root' );

    my $permissions = _build_permissions();

    is $permissions->user_can_admin_ci( $user->username ), 1;
};

subtest 'user_can_view_ci: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 0;
};

subtest 'user_can_view_ci: false when no collection' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.view.%.variable' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 0;
};

subtest 'user_can_view_ci: true when action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.view.%.variable' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username, 'variable' ), 1;
};

subtest 'user_can_view_ci: true when ci collection admin' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin.%.variable' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username, 'variable' ), 1;
};

subtest 'user_can_view_ci: true when ci admin' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.admin' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 1;
};

subtest 'user_can_view_ci: true when root' => sub {
    _setup();

    my $user = _create_user_with_actions( username => 'root' );

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci( $user->username ), 1;
};

subtest 'user_can_view_ci_group: true when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci_group( 'root' ), 1;
};

subtest 'user_can_view_ci_group: true when has action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.ci.view.variable.variable' } ] );

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci_group( $user->username, 'variable' ), 1;
};

subtest 'user_can_view_ci_group: false when no action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_can_view_ci_group( $user->username, 'variable' ), 0;
};

subtest 'user_projects_ids: returns all projects when root' => sub {
    _setup();

    my $project = TestUtils->create_ci('project', name => 'Project1');
    my $project2 = TestUtils->create_ci('project', name => 'Project2');

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_ids( username => 'root' );

    is_deeply \@ids, [$project->mid, $project2->mid];
};

subtest 'user_projects_ids: returns user projects' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role();
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');
    my $project4 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid
            },
            $id_role2 => {
                project => [$project2->mid, $project3->mid]
            }
        }
    );

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_ids( username => $user->username );

    is_deeply [ sort @ids ], [ sort $project->mid, $project2->mid, $project3->mid ];
};

subtest 'user_projects_ids: returns empty list when no user projects' => sub {
    _setup();

    my $user = TestSetup->create_user;

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_ids( username => $user->username );

    is_deeply \@ids, [];
};

subtest 'user_projects_ids_with_collection: ' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role();
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid
            },
            $id_role2 => {
                project => [$project2->mid, $project3->mid]
            }
        }
    );

    my $permissions = _build_permissions();

    my @projects = $permissions->user_projects_ids_with_collection( username => $user->username );

    is_deeply [ sort { values %{ $a->{project} } <=> values %{ $b->{project} } } @projects ],
      [
        {
            'project' => {
                $project->mid => 1
            }
        },
        {
            'project' => {
                $project2->mid => 1,
                $project3->mid => 1,
            }
        }
      ];
};

subtest 'user_projects: returns all projects when root' => sub {
    _setup();

    my $project  = TestUtils->create_ci( 'project', name => 'Project1' );
    my $project2 = TestUtils->create_ci( 'project', name => 'Project2' );

    my $permissions = _build_permissions();

    my @projects = $permissions->user_projects( username => 'root' );

    is_deeply [ sort @projects ], [ sort 'project/' . $project->mid, 'project/' . $project2->mid ];
};

subtest 'user_projects: returns user projects' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role();
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');
    my $project4 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid
            },
            $id_role2 => {
                project => [$project2->mid, $project3->mid]
            }
        }
    );

    my $permissions = _build_permissions();

    my @projects = $permissions->user_projects( username => $user->username );

    is_deeply [ sort @projects ], [ sort map {"project/$_"} $project->mid, $project2->mid, $project3->mid ];
};

subtest 'user_projects: returns nothing when no projects' => sub {
    _setup();

    my $user = TestSetup->create_user;

    my $permissions = _build_permissions();

    my @projects = $permissions->user_projects( username => $user->username );

    is_deeply \@projects, [];
};

subtest 'build_project_security: does nothing when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    my $where = {};
    my $is_root = 1;

    $permissions->build_project_security($where, 'root', $is_root);

    is_deeply $where, {};
};

subtest 'build_project_security: builds empty project_security when no accessible categories' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    my $where = {};
    my $is_root = 0;

    $permissions->build_project_security($where, $user->username, $is_root);

    is_deeply $where,
      {
        '$or' => [
            {
                '_project_security' => undef
            }
        ]
      };
};

subtest 'build_project_security: builds query for accessible categories' => sub {
    _setup();

    my $id_role = TestSetup->create_role(actions => [{action => 'action.topics.category.admin'}]);
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );
    TestSetup->create_category(
        name      => 'Another Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $permissions = _build_permissions();

    my $where = {};
    my $is_root = 0;

    $permissions->build_project_security($where, $user->username, $is_root);

    is_deeply $where,
      {
        '$or' => [
            {
                'category.id' => {
                    '$in' => [$id_category]
                },
                '_project_security.project' => {
                    '$in' => [$project->mid]
                }
            },
            {
                '_project_security' => undef
            }
        ]
      };
};

subtest 'build_project_security: builds query for filtered categories' => sub {
    _setup();

    my $id_role = TestSetup->create_role( actions =>
          [ { action => 'action.topics.category.admin' }, { action => 'action.topics.another_category.admin' }, ] );
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );
    TestSetup->create_category(
        name      => 'Another Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $permissions = _build_permissions();

    my $where = {};
    my $is_root = 0;

    $permissions->build_project_security($where, $user->username, $is_root, $id_category);

    is_deeply $where,
      {
        '$or' => [
            {
                'category.id' => {
                    '$in' => [$id_category]
                },
                '_project_security.project' => {
                    '$in' => [$project->mid]
                }
            },
            {
                '_project_security' => undef
            }
        ]
      };
};

subtest 'user_roles: returns user roles' => sub {
    _setup();

    my $id_role = TestSetup->create_role(description => 'My Role', actions => [{action => 'foo.bar'}]);
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    my @roles = $permissions->user_roles($user->username);

    is_deeply \@roles,
      [
        {
            actions     => ['foo.bar'],
            description => 'My Role',
            role        => 'Role',
            id          => $id_role
        }
      ];
};

subtest 'user_role_ids: returns roles ids' => sub {
    _setup();

    my $id_role = TestSetup->create_role(description => 'My Role', actions => [{action => 'foo.bar'}]);
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    my @ids = $permissions->user_role_ids($user->username);
    is_deeply \@ids, [$id_role];
};

subtest 'user_role_ids: returns nothing when user has no roles' => sub {
    _setup();

    my $user = TestSetup->create_user;

    my $permissions = _build_permissions();

    my @ids = $permissions->user_role_ids($user->username);
    is_deeply \@ids, [];
};

subtest 'user_role_ids: returns nothing when unknown user' => sub {
    _setup();

    my $permissions = _build_permissions();

    my @ids = $permissions->user_role_ids('unknown');
    is_deeply \@ids, [];
};

subtest 'user_can_topic_by_project: returns true when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok $permissions->user_can_topic_by_project(username => 'root', mid => '123');
};

subtest 'user_can_topic_by_project: returns true when user can access topic' => sub {
    _setup();

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.admin' } ] );
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_rule,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    my $permissions = _build_permissions();

    ok $permissions->user_can_topic_by_project(username => $user->username, mid => $topic_mid);
};

subtest 'user_can_topic_by_project: returns false when user cannot access topic' => sub {
    _setup();

    my $id_role = TestSetup->create_role;
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status      = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_rule,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    my $permissions = _build_permissions();

    ok !$permissions->user_can_topic_by_project(username => $user->username, mid => $topic_mid);
};

subtest 'user_projects_with_action: returns all projects when root' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_with_action(username => 'root', action => 'some.action');

    is_deeply [ sort @ids ], [ sort $project->mid, $project2->mid ];
};

subtest 'user_projects_with_action: returns projects for user' => sub {
    _setup();

    my $id_role = TestSetup->create_role(actions => [{action => 'some.action', bl => '*'}]);
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role(actions => [{action => 'another.action', bl => '*'}]);
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid
            },
            $id_role2 => {
                project => [$project2->mid, $project3->mid]
            }
        }
    );

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_with_action(username => $user->username, action => 'some.action');

    is_deeply [ sort @ids ], [ sort $project->mid ];
};

subtest 'user_projects_with_action: returns multiple projects for user' => sub {
    _setup();

    my $id_role = TestSetup->create_role(actions => [{action => 'some.action', bl => '*'}]);
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role(actions => [{action => 'some.action', bl => '*'}]);
    my $project2 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => [$project->mid, $project2->mid]
            }
        }
    );

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_with_action(username => $user->username, action => 'some.action');

    is_deeply [ sort @ids ], [ sort $project->mid, $project2->mid ];
};

subtest 'user_projects_with_action: returns nothing when no suitable project' => sub {
    _setup();

    my $id_role = TestSetup->create_role;
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( project_security => { $id_role => { project => $project->mid } } );

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_with_action(username => $user->username, action => 'some.action');

    is_deeply \@ids, [];
};

subtest 'user_namespaces: returns user namespaces' => sub {
    _setup();

    my $id_role = TestSetup->create_role;
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( project_security => { $id_role => { project => $project->mid } } );

    my $permissions = _build_permissions();

    my @namespaces = $permissions->user_namespaces($user->username);

    is_deeply \@namespaces, [ 'project/' . $project->mid ];
};

subtest 'list: returns user actions when username' => sub {
    _setup();

    my $id_role = TestSetup->create_role(actions => [{action => 'some.action'}]);
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( project_security => { $id_role => { project => $project->mid } } );

    my $permissions = _build_permissions();

    my @actions = $permissions->list(username => $user->username);

    is_deeply \@actions, ['some.action'];
};

subtest 'list: returns users when action' => sub {
    _setup();

    my $id_role = TestSetup->create_role(actions => [{action => 'some.action', bl => '*'}]);
    my $project = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( project_security => { $id_role => { project => $project->mid } } );

    my $permissions = _build_permissions();

    my @users = $permissions->list(action => 'some.action', bl => 'any');

    is_deeply \@users, [$user->mid];
};

subtest 'users_with_roles: returns users with roles' => sub {
    _setup();

    my $id_role = TestSetup->create_role;
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role;

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    my @users = $permissions->users_with_roles( roles => [$id_role] );

    is_deeply \@users, [ $user->name ];
};

subtest 'users_with_roles: returns nothing when no users' => sub {
    _setup();

    my $id_role  = TestSetup->create_role;
    my $id_role2 = TestSetup->create_role;

    my $permissions = _build_permissions();

    my @users = $permissions->users_with_roles( roles => [$id_role] );

    is_deeply \@users, [];
};

done_testing();

sub _create_user_with_actions {
    my (%params) = @_;

    my $project = $params{project} || TestUtils->create_ci('project');
    my $id_role = $params{id_role} || TestSetup->create_role( actions => delete $params{actions} || [] );

    return TestSetup->create_user( id_role => $id_role, project => $project, %params );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Registor', 'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service',  'BaselinerX::Type::Statement',
        'BaselinerX::CI',             'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',    'Baseliner::Model::Rules'
    );

    Baseliner::Core::Registry->initialize;

    TestUtils->cleanup_cis;

    mdb->role->drop;
    mdb->rule->drop;
    mdb->category->drop;
    mdb->topic->drop;
}

sub _create_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "status_new",
                        "fieldletType" => "fieldlet.system.status_new",
                        "name_field"   => "Status",
                    },
                    "key" => "fieldlet.system.status_new",
                    text  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "Project",
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                    text  => 'Project',
                }
            },
        ]
    );
}

sub _build_permissions {
    return Baseliner::Model::Permissions->new;
}
