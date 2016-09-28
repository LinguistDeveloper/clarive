use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::Model::Permissions';

subtest 'action_info: returns action info' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $permissions = _build_permissions();

    my $info = $permissions->action_info('action.some');

    is $info->key, 'action.some';
};

subtest 'role_has_action: checks if role has action' => sub {
    _setup();

    my $id_role = TestSetup->create_role( actions => [ { action => 'foo.bar.baz' } ] );

    my $role = mdb->role->find_one;

    my $permissions = _build_permissions();

    ok $permissions->role_has_action( $role,    'foo.bar.baz' );
    ok $permissions->role_has_action( $id_role, 'foo.bar.baz' );

    ok !$permissions->role_has_action( $role,    'unknown' );
    ok !$permissions->role_has_action( $id_role, 'unknown' );
    ok !$permissions->role_has_action( 123,      'unknown' );
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

subtest 'users_with_action: returns nothing when no users' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $permissions = _build_permissions();

    my @users = $permissions->users_with_action('action.some');

    is_deeply \@users, [];
};

subtest 'users_with_action: returns users with action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    _create_user_with_actions( username => 'user1', actions => [ { action => 'action.some' } ] );
    _create_user_with_actions( username => 'user2', actions => [ { action => 'action.some' } ] );
    _create_user_with_actions( username => 'user3' );

    my $permissions = _build_permissions();

    my @users = $permissions->users_with_action('action.some');

    is @users, 2;
    is $users[0], 'user1';
    is $users[1], 'user2';
};

subtest 'user_roles_ids: returns all roles for user' => sub {
    _setup();

    my $id_role1 = TestSetup->create_role( name => 'Role 1' );
    my $id_role2 = TestSetup->create_role( name => 'Role 2' );

    my $user = TestSetup->create_user();

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids('root') ], [ $id_role1, $id_role2 ];
};

subtest 'user_roles_ids: returns no roles when user does not have any' => sub {
    _setup();

    my $user = TestSetup->create_user();

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids( $user->username ) ], [];
};

subtest 'user_roles_ids: returns roles ids' => sub {
    _setup();

    my $user = TestSetup->create_user(
        project_security => {
            1 => {
                project => [ 1, 2, 3 ]
            },
            2 => {
                project => [ 3, 4 ]
            }
        }
    );

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids( $user->username ) ], [ 1, 2 ];
};

subtest 'user_roles_ids: returns roles ids filtered by single project' => sub {
    _setup();

    my $user = TestSetup->create_user(
        project_security => {
            1 => {
                project => [ 1, 2, 3 ]
            },
            2 => {
                project => [ 3, 4 ]
            }
        }
    );

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids( $user->username, projects => 2 ) ], [1];
};

subtest 'user_roles_ids: returns roles ids filtered by multiple projects' => sub {
    _setup();

    my $user = TestSetup->create_user(
        project_security => {
            1 => {
                project => [ 1, 2, 3 ]
            },
            2 => {
                project => [ 3, 4 ]
            }
        }
    );

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids( $user->username, projects => [ 2, 4 ] ) ], [ 1, 2 ];
};

subtest 'user_roles_ids: returns roles ids filtered by topic' => sub {
    _setup();

    mdb->topic->insert( { mid => '1', _project_security => { project => [1] } } );

    my $user = TestSetup->create_user(
        project_security => {
            1 => {
                project => [ 1, 2, 3 ]
            },
            2 => {
                project => [ 3, 4 ]
            }
        }
    );

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids( $user->username, topics => '1' ) ], [1];
};

subtest 'user_roles_ids: returns no roles when topic not found' => sub {
    _setup();

    my $user = TestSetup->create_user(
        project_security => {
            1 => {
                project => [ 1, 2, 3 ]
            },
            2 => {
                project => [ 3, 4 ]
            }
        }
    );

    my $permissions = _build_permissions();

    is_deeply [ $permissions->user_roles_ids( $user->username, topics => '1' ) ], [];
};

subtest 'user_roles: returns roles for user' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');

    my $id_role1 = TestSetup->create_role( name => 'Role 1' );
    my $id_role2 = TestSetup->create_role( name => 'Role 2' );

    my $user = TestSetup->create_user(
        project_security => {
            $id_role1 => {
                project => $project->mid
            },
            $id_role2 => {
                project => $project->mid
            }
        }
    );

    my $permissions = _build_permissions();

    my @roles = $permissions->user_roles( $user->username );

    is @roles, 2;
};

subtest 'is_root: returns true by username' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok $permissions->is_root('root');
};

subtest 'is_root: returns true by action' => sub {
    _setup();

    my $user = _create_user_with_actions( actions => [ { action => 'action.admin.root' } ] );

    my $permissions = _build_permissions();

    ok $permissions->is_root( $user->username );
};

subtest 'is_root: returns false by action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    ok !$permissions->is_root( $user->username );
};

subtest 'user_has_action: returns true when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( 'root', 'action.some' );
};

subtest 'user_has_action: returns false when unknown action' => sub {
    _setup();

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    is $permissions->user_has_action( $user->username, 'action.some' ), 0;
};

subtest 'user_has_action: returns false when user has no action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.some' );
};

subtest 'user_has_action: returns true when action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some' } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some' );
};

subtest 'user_has_action: returns true when action extended' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => {} );
    Baseliner::Core::Registry->add( 'main', 'action.admin' => { extends => ['action.view'] } );
    Baseliner::Core::Registry->initialize;

    my $user = _create_user_with_actions( actions => [ { action => 'action.admin' } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.view' );
};

subtest 'user_has_action: returns true when action with correct bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: returns true when action with partial bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo' }, { key => 'something' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: returns true when action with bounds and partial match' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo' }, { key => 'something' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar', something => 'baz' } );
};

subtest 'user_has_action: returns false when action with partial bounds but not exact match' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo' }, { key => 'something' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar', something => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: returns true when action bounds with star' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo' }, { key => 'something' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar', something => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar', something => '*' } );
};

subtest 'user_has_action: correctly works with intersecting star bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'role' }, { key => 'collection' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { role => 'agent', collection => 'ssh_agent' }, { role => 'project' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some',
        bounds => { role => 'agent', collection => 'ssh_agent' } );
    ok !$permissions->user_has_action( $user->username, 'action.some', bounds => { role => 'agent' } );
    ok !$permissions->user_has_action( $user->username, 'action.some',
        bounds => { role => 'agent', collection => 'ftp_agent' } );

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { role => 'project' } );
    ok $permissions->user_has_action( $user->username, 'action.some',
        bounds => { role => 'project', collection => 'whatever' } );
    ok $permissions->user_has_action( $user->username, 'action.some',
        bounds => { role => 'project', collection => '*' } );
};

subtest 'user_has_action: returns true when action with no bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ {} ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some' );
    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'baz' } );
};

subtest 'user_has_action: returns false when action with no bounds not available' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );
    Baseliner::Core::Registry->add( 'main', 'action.another' => {} );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.some' );
};

subtest 'user_has_action: returns true when action has bounds but search is star' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => '*' );
};

subtest 'user_has_action: returns false when action with unknown bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );
    Baseliner::Core::Registry->add( 'main', 'action.another' => {} );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.another' }, { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'baz' } );
};

subtest 'user_has_action: returns true when action extended with correct bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => { bounds => [ { key => 'foo' } ] } );
    Baseliner::Core::Registry->add( 'main', 'action.admin' => { extends => ['action.view'] } );
    Baseliner::Core::Registry->initialize;

    my $user =
      _create_user_with_actions( actions => [ { action => 'action.admin', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.view', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: returns false when action extended with unknown bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => { bounds => [ { key => 'foo' } ] } );
    Baseliner::Core::Registry->add( 'main', 'action.admin' => { extends => ['action.view'] } );

    my $user =
      _create_user_with_actions( actions => [ { action => 'action.admin', bounds => [ { foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.view', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: returns true when action extended with unknown bounds but original bounds are correct' =>
  sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => { bounds => [ { key => 'foo' } ] } );
    Baseliner::Core::Registry->add( 'main', 'action.admin' => { extends => ['action.view'] } );

    my $user = _create_user_with_actions(
        actions => [
            { action => 'action.view',  bounds => [ { foo => 'bar' } ] },
            { action => 'action.admin', bounds => [ { foo => 'baz' } ] }
        ]
    );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.view', bounds => { foo => 'bar' } );
  };

subtest 'user_has_action: returns false when deny bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { _deny => 1, foo => 'bar' }, {} ] } ] );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: returns true when deny bounds but no match' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { _deny => 1, foo => 'bar' }, {} ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'baz' } );
};

#subtest 'user_has_action: returns true when deny bounds but different action' => sub {
#    _setup();
#
#    Baseliner::Core::Registry->add( 'main', 'action.child' => { bounds => [ { key => 'bar' } ] } );
#    Baseliner::Core::Registry->add( 'main', 'action.parent' => { extends => ['action.child'] } );
#    Baseliner::Core::Registry->initialize;
#
#    my $user = _create_user_with_actions(
#        actions => [
#            { action => 'action.ignoreme', bounds => [ {} ] },
#            { action => 'action.child',    bounds => [ { _deny => 1, foo => 'bar' }, {} ] },
#            { action => 'action.parent',   bounds => [ {} ] },
#        ]
#    );
#
#    my $permissions = _build_permissions();
#
#    ok $permissions->user_has_action( $user->username, 'action.child', bounds => { foo => 'bar' } );
#};

subtest 'user_has_action: returns true when deny bounds but different role' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $id_role1 = TestSetup->create_role(
        actions => [
            { action => 'action.ignoreme', bounds => [ {} ] },
            { action => 'action.some',     bounds => [ { _deny => 1, foo => 'bar' }, {} ] }
        ]
    );
    my $id_role2 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ {} ] } ] );

    my $user = TestSetup->create_user(
        project_security => {
            $id_role1 => {
                project => $project->mid
            },
            $id_role2 => {
                project => $project->mid
            }
        }
    );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => 'bar' } );
};

subtest 'user_has_action: ignores deny rules when glob bounds and no other bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { _deny => 1, foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_action( $user->username, 'action.some', bounds => '*' );
};

subtest 'user_has_action: ignores deny rules when glob bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { _deny => 1, foo => 'bar' }, {} ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => '*' );
};

subtest 'user_has_action: ignores deny rules when glob bounds no match' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { _deny => 1, foo => 'bar' }, {} ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => '*' } );
};

subtest 'user_has_action: ignores deny rules when glob bounds partial match' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' }, { key => 'bar' } ] } );

    my $user = _create_user_with_actions( actions =>
          [ { action => 'action.some', bounds => [ { _deny => 1, foo => 'bar', bar => 'baz' }, { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_action( $user->username, 'action.some', bounds => '*' );
    ok $permissions->user_has_action( $user->username, 'action.some', bounds => { foo => '*', bar => 'bar' } );
};

subtest 'user_has_any_action: returns true when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok $permissions->user_has_any_action( 'root', 'action.some' );
};

subtest 'user_has_any_action: returns false when no action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    ok !$permissions->user_has_any_action( $user->username, 'action.some' );
};

subtest 'user_has_any_action: returns true when action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some.read' => {} );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some.read' } ] );

    my $permissions = _build_permissions();

    ok $permissions->user_has_any_action( $user->username, 'action.some.%' );
};

subtest 'user_actions: returns all actions for root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some'    => {} );
    Baseliner::Core::Registry->add( 'main', 'action.another' => {} );
    Baseliner::Core::Registry->initialize;

    my $permissions = _build_permissions();

    my $actions = $permissions->user_actions('root');

    is_deeply $actions,
      [
        {
            action => 'action.another'
        },
        {
            action => 'action.some'
        },
      ];
};

subtest 'user_actions: returns no actions for user' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => {} );

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    my $actions = $permissions->user_actions( $user->username );

    is_deeply $actions, [];
};

subtest 'user_actions: returns actions for user' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => {} );

    my $user = _create_user_with_actions( actions => [ { action => 'action.view' } ] );

    my $permissions = _build_permissions();

    my $actions = $permissions->user_actions( $user->username );

    is_deeply $actions,
      [
        {
            action => 'action.view',
        },
      ];
};

subtest 'user_actions: returns actions for user with extensions' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.view' => {} );
    Baseliner::Core::Registry->add( 'main', 'action.admin' => { extends => ['action.view'] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.admin' } ] );

    my $permissions = _build_permissions();

    my $actions = $permissions->user_actions( $user->username );

    is_deeply $actions,
      [
        {
            action => 'action.admin',
        },
        {
            action => 'action.view',
        },
      ];
};

#subtest 'user_actions_map: returns actions as fast-access map' => sub {
#    _setup();
#
#    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );
#    Baseliner::Core::Registry->add( 'main', 'action.parent' => { extends => ['action.some'] } );
#
#    my $user = _create_user_with_actions( actions => [ { action => 'action.parent' } ] );
#
#    my $permissions = _build_permissions();
#
#    my $map = $permissions->user_actions_map( $user->username );
#
#    is_deeply $map,
#      {
#        'action.parent' => { },
#        'action.some'   => { }
#      };
#};
#
#subtest 'user_actions_map: returns actions as fast-access map with bounds' => sub {
#    _setup();
#
#    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );
#    Baseliner::Core::Registry->add( 'main', 'action.parent' => { extends => ['action.some'] } );
#
#    my $user =
#      _create_user_with_actions( actions => [ { action => 'action.parent', bounds => [ { foo => 'bar' } ] } ] );
#
#    my $permissions = _build_permissions();
#
#    my $map = $permissions->user_actions_map( $user->username );
#
#    is_deeply $map,
#      {
#        'action.parent' => { bounds => [ { foo => 'bar' } ] },
#        'action.some'   => { bounds => [ { foo => 'bar' } ] }
#      };
#};
#
#subtest 'user_action: returns all inclusive action for root' => sub {
#    _setup();
#
#    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );
#
#    my $permissions = _build_permissions();
#
#    my $action = $permissions->user_action( 'root', 'action.some' );
#
#    is_deeply $action->{bounds}, [];
#};

subtest 'user_action: returns undef when no action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $user = _create_user_with_actions();

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some' );

    is $action, undef;
};

subtest 'user_action: returns action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some' } ] );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some' );

    ok $action;
};

subtest 'user_action: returns action ignoring bounds if no bounds supported' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );
    Baseliner::Core::Registry->add( 'main', 'action.another' => { } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some' }, { action => 'action.another', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.another' );
    ok $action;
};

subtest 'user_action: returns action with bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );
    Baseliner::Core::Registry->add( 'main', 'action.another' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some' }, { action => 'action.another', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some' );
    ok $action;
    ok !exists $action->{bounds};

    $action = $permissions->user_action( $user->username, 'action.another', bounds => '*' );
    ok $action;
    is_deeply $action->{bounds}, [ { foo => 'bar' } ];
};

subtest 'user_action: returns action with filtered bounds by deny rules' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' }, { key => 'bar' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, bar => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some', bounds => '*' );

    is_deeply $action->{bounds}, [];
    is_deeply $action->{bounds_denied}, [ { bar => 'baz' } ];
};

subtest 'user_action: returns action with bounds merged' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' }, { key => 'bar' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar' }, { bar => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some', bounds => '*' );
    is_deeply $action->{bounds}, [ { foo => 'bar' }, { bar => 'baz' } ];
};

subtest 'user_action: returns action with bounds merged from different roles' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' }, { key => 'bar' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $id_role1 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ { bar => 'baz' } ] } ] );
    my $id_role2 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $user = TestSetup->create_user(
        project_security => {
            $id_role1 => {
                project => [$project]
            },
            $id_role2 => {
                project => [$project]
            }
        }
    );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some', bounds => '*' );
    cmp_deeply $action->{bounds}, bag( { foo => 'bar' }, { bar => 'baz' } );
};

subtest 'user_action: returns action with bounds merged from different roles with deny' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' }, { key => 'bar' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $id_role1 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ { }, {_deny => 1, foo => 'bar'} ] } ] );
    my $id_role2 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $user = TestSetup->create_user(
        project_security => {
            $id_role1 => {
                project => [$project->mid]
            },
            $id_role2 => {
                project => [$project->mid]
            }
        }
    );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some', bounds => '*' );
    cmp_deeply $action->{bounds}, [];
};

subtest 'user_action: returns action with no bounds if at least one action does not have bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' }, { key => 'bar' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $id_role1 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ {} ] } ] );
    my $id_role2 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $user = TestSetup->create_user(
        project_security => {
            $id_role1 => {
                project => [$project]
            },
            $id_role2 => {
                project => [$project]
            }
        }
    );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some', bounds => '*' );
    is_deeply $action->{bounds}, [];
};

subtest 'user_action: returns all projects when root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $project = TestUtils->create_ci('project');

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( 'root', 'action.some' );
    is_deeply $action->{projects}, [ $project->mid ];
};

subtest 'user_action: returns projects ids with action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $project1 = TestUtils->create_ci('project');
    my $id_role1 = TestSetup->create_role( actions => [ { action => 'action.some' } ] );

    my $project2 = TestUtils->create_ci('project');
    my $id_role2 = TestSetup->create_role( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $project3 = TestUtils->create_ci('project');
    my $id_role3 = TestSetup->create_role();

    my $user = TestSetup->create_user(
        project_security => {
            $id_role1 => {
                project => [ $project1->mid, $project2->mid ]
            },
            $id_role2 => {
                project => [ $project2->mid ]
            },
            $id_role3 => {
                project => [ $project3->mid ]
            }
        }
    );

    my $permissions = _build_permissions();

    my $action = $permissions->user_action( $user->username, 'action.some' );
    is_deeply [ sort @{ $action->{projects} } ], [ $project1->mid, $project2->mid ];
};

subtest 'user_has_security: returns true when root' => sub {
    _setup();

    my $permissions = _build_permissions();

    ok $permissions->user_has_security( 'root', { project => [ 1, 2, 3 ] } );
};

subtest 'user_has_security: returns true when security is undefined' => sub {
    _setup();

    my $user = TestSetup->create_user( project_security => {} );

    my $permissions = _build_permissions();

    ok $permissions->user_has_security( $user->username, undef );
};

subtest 'user_has_security: returns false when no permission' => sub {
    _setup();

    my $user = TestSetup->create_user( project_security => {} );

    my $permissions = _build_permissions();

    ok !$permissions->user_has_security( $user->username, { project => [ 1, 2, 3 ] } );
};

subtest 'user_has_security: returns true when permission' => sub {
    _setup();

    my $user = TestSetup->create_user( project_security => { '1' => { project => [1] } } );

    my $permissions = _build_permissions();

    ok $permissions->user_has_security( $user->username, { project => [ 1, 2, 3 ] } );
};

subtest 'inject_security_filter: builds empty filter for root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.topics.view' => { bounds => [ { key => 'id_category' } ] } );

    my $permissions = _build_permissions();

    my $where = {};

    $permissions->inject_security_filter( 'root', $where );

    is_deeply $where, {};
};

subtest 'inject_security_filter: builds security filter for user without security' => sub {
    _setup();

    my $user = TestSetup->create_user( project_security => {} );

    my $permissions = _build_permissions();

    my $where = {};

    $permissions->inject_security_filter( $user->username, $where );

    is_deeply $where, { _project_security => undef };
};

subtest 'inject_security_filter: builds security filter for user with project dimension' => sub {
    _setup();

    my $user = TestSetup->create_user( project_security => { '1' => { project => '123' } } );

    my $permissions = _build_permissions();

    my $where = {};

    $permissions->inject_security_filter( $user->username, $where );

    is_deeply $where,
      { '$or' => [ { _project_security => undef }, { '_project_security.project' => { '$in' => [ undef, '123' ] } } ] };
};

subtest 'inject_security_filter: builds security filter for user with multiple project dimension' => sub {
    _setup();

    my $user =
      TestSetup->create_user( project_security => { '1' => { project => '123' }, '2' => { project => '321' } } );

    my $permissions = _build_permissions();

    my $where = {};

    $permissions->inject_security_filter( $user->username, $where );

    is_deeply $where,
      { '$or' =>
          [ { _project_security => undef }, { '_project_security.project' => { '$in' => [ undef, '123', '321' ] } } ] };
};

subtest 'inject_security_filter: builds security filter for user with other dimension' => sub {
    _setup();

    my $user = TestSetup->create_user(
        project_security => {
            '1' => {
                project => '123',
                area    => '321'
            }
        }
    );

    my $permissions = _build_permissions();

    my $where = {};

    $permissions->inject_security_filter( $user->username, $where );

    is_deeply $where,
      {
        '$or' => [
            { _project_security => undef },
            {
                '$and' => [
                    { '_project_security.area'    => { '$in' => ['321'] } },
                    { '_project_security.project' => { '$in' => [ undef, '123' ] } },
                ]
            }
        ]
      };
};

subtest 'user_security_dimensions_map: returns empty map for root' => sub {
    _setup();

    my $permissions = _build_permissions();

    my $map = $permissions->user_security_dimensions_map('root');

    is_deeply $map, {};
};

subtest 'user_security_dimensions_map: returns dimensions map' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role();
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');

    my $area1 = TestUtils->create_ci('area');
    my $area2 = TestUtils->create_ci('area');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid,
                area    => $area1->mid,
            },
            $id_role2 => {
                project => [ $project2->mid, $project3->mid ],
                area    => [ $area1->mid,    $area2->mid ]
            }
        }
    );

    my $permissions = _build_permissions();

    my $map = $permissions->user_security_dimensions_map( $user->username );

    is_deeply $map,
      {
        project => {
            $project->mid  => 1,
            $project2->mid => 1,
            $project3->mid => 1,
        },
        area => {
            $area1->mid => 1,
            $area2->mid => 1,
        }
      };
};

subtest 'user_security_dimension: returns dimension' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $project = TestUtils->create_ci('project');

    my $id_role2 = TestSetup->create_role();
    my $project2 = TestUtils->create_ci('project');

    my $project3 = TestUtils->create_ci('project');

    my $area1 = TestUtils->create_ci('area');
    my $area2 = TestUtils->create_ci('area');

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => $project->mid,
                area    => $area1->mid,
            },
            $id_role2 => {
                project => [ $project2->mid, $project3->mid ],
                area    => [ $area1->mid,    $area2->mid ]
            }
        }
    );

    my $permissions = _build_permissions();

    my @project_dimensions = $permissions->user_security_dimension( $user->username, 'project' );
    is_deeply [ sort @project_dimensions ], [ sort $project->mid, $project2->mid, $project3->mid ];

    my @area_dimensions = $permissions->user_security_dimension( $user->username, 'area' );
    is_deeply [ sort @area_dimensions ], [ sort $area1->mid, $area2->mid ];

    my @unknown_dimensions = $permissions->user_security_dimension( $user->username, 'unknown' );
    is_deeply \@unknown_dimensions, [];
};

subtest 'user_projects_ids: returns all projects for root' => sub {
    _setup();

    my $project1 = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_ids('root');

    is_deeply \@ids, [ $project1->mid, $project2->mid ];
};

subtest 'user_projects_ids: returns users projects' => sub {
    _setup();

    my $id_role = TestSetup->create_role;
    my $project = TestUtils->create_ci('project');

    my $project2 = TestUtils->create_ci('project');

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $permissions = _build_permissions();

    my @ids = $permissions->user_projects_ids( $user->username );

    is_deeply \@ids, [ $project->mid ];
};

subtest 'action_bounds_available: returns all bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo', handler => 'TestBounds=bounds' } ] } );

    my $permissions = _build_permissions();

    my $bounds = $permissions->action_bounds_available( 'action.some', 'foo' );

    is_deeply $bounds, [ { id => '1', title => 'Title' } ];
};

subtest 'map_action_bounds: maps bound id to title' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo', handler => 'TestBounds=bounds' } ] } );

    my $permissions = _build_permissions();

    my $map = $permissions->map_action_bounds( 'action.some', [ { foo => 1 }, {foo => 999} ] );

    is_deeply $map,
      [
        {
            foo        => 1,
            _foo_title => 'Title'
        },
        {
            foo        => 999,
            _foo_title => '999'
        },
      ];
};

subtest 'filter_bounds: returns all bounds when root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $permissions = _build_permissions();

    my $filtered = $permissions->filter_bounds( 'root', 'action.some', { foo => [ 1, 2, 3 ] } );

    is_deeply $filtered, { foo => [ 1, 2, 3 ] };
};

subtest 'filter_bounds: returns directly when everything is allowed' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {} ] } ] );

    my $permissions = _build_permissions();

    my $filtered = $permissions->filter_bounds( $user->username, 'action.some', { foo => [ 'bar', 'baz' ] } );

    is_deeply $filtered, { foo => [ 'bar', 'baz' ] };
};

subtest 'filter_bounds: filters allowed bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $filtered = $permissions->filter_bounds( $user->username, 'action.some', { foo => [ 'bar', 'baz' ] } );

    is_deeply $filtered, { foo => [ 'bar' ] };
};

subtest 'filter_bounds: filters out denied bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $filtered = $permissions->filter_bounds( $user->username, 'action.some', { foo => [ 'bar', 'baz' ] } );

    is_deeply $filtered, { foo => [ 'bar' ] };
};

subtest 'inject_project_filter: injects filter by project' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $project = TestUtils->create_ci('project');
    my $user    = _create_user_with_actions(
        project => $project,
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ]
    );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_project_filter( $user->username, 'action.some', $where );

    is_deeply $where, { projects => { '$in' => [ $project->mid ] } };
};

subtest 'inject_project_filter: ignores empty filter' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $project = TestUtils->create_ci('project');
    my $user    = _create_user_with_actions(
        project => $project,
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ]
    );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_project_filter( $user->username, 'action.some', $where, filter => [] );

    is_deeply $where, { projects => { '$in' => [ $project->mid ] } };
};

subtest 'inject_project_filter: injects filter by project ignoring additional unknown filter' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');
    my $user     = _create_user_with_actions(
        project => $project,
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ]
    );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_project_filter( $user->username, 'action.some', $where, filter => [ $project2->mid ] );

    is_deeply $where, { projects => { '$in' => [ ] } };
};

subtest 'inject_project_filter: injects filter by project respecting additional filter' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');
    my $id_role =
      TestSetup->create_role(
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ] );

    my $user = TestSetup->create_user(
        project_security => {
            $id_role => {
                project => [ $project->mid, $project2->mid ]
            }
        }
    );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_project_filter( $user->username, 'action.some', $where, filter => [ $project2->mid ] );

    is_deeply $where, { projects => { '$in' => [ $project2->mid ] } };
};

subtest 'inject_project_filter: injects filter directly when root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $project  = TestUtils->create_ci('project');
    my $project2 = TestUtils->create_ci('project');

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_project_filter( 'root', 'action.some', $where, filter => [ $project->mid, $project2->mid ] );

    is_deeply $where, { projects => { '$in' => [ $project->mid, $project2->mid ] } };
};

subtest 'inject_bounds_filters: ignores empty bounds and filters' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ {} ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( $user->username, 'action.some', $where, filters => { foo => [] } );

    is_deeply $where, { };
};

subtest 'inject_bounds_filters: ignores empty filters' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters($user->username, 'action.some', $where, filters => {foo => []});

    is_deeply $where, { foo => {'$in' => ['bar']}};
};

subtest 'inject_bounds_filters: injects filter based on action bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters($user->username, 'action.some', $where);

    is_deeply $where, { foo => { '$in' => ['bar'] } };
};

subtest 'inject_bounds_filters: injects filter based on action bounds respecting filter' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar' }, { foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters($user->username, 'action.some', $where, filters => {foo => ['bar']});

    is_deeply $where, { foo => { '$in' => ['bar'] } };
};

subtest 'inject_bounds_filters: injects filter based on action bounds ignoring unknown filter values' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar' }, { foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters($user->username, 'action.some', $where, filters => {foo => ['unknown']});

    is_deeply $where, { foo => { '$in' => [] } };
};

subtest 'inject_bounds_filters: injects filter based on action bounds with mixed values' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ { foo => 'bar' }, { foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters($user->username, 'action.some', $where, filters => {foo => ['unknown', 'bar']});

    is_deeply $where, { foo => { '$in' => ['bar'] } };
};

subtest 'inject_bounds_filters: injects filter based on action bounds with deny' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters($user->username, 'action.some', $where);

    is_deeply $where, { foo => { '$nin' => ['bar'] } };
};

subtest 'inject_bounds_filters: injects filter based on action bounds respecting deny filter' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( $user->username, 'action.some', $where, filters => { foo => ['bar'] } );

    is_deeply $where, { foo => { '$in' => ['bar'] } };
};

subtest 'inject_bounds_filters: injects empty query when filter is denied' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( $user->username, 'action.some', $where, filters => { foo => ['baz'] } );

    is_deeply $where, { foo => [] };
};

subtest 'inject_bounds_filters: injects filter based on action bounds ignoring filter with mixed values' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {}, { _deny => 1, foo => 'baz' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( $user->username, 'action.some', $where, filters => { foo => ['bar', 'baz'] } );

    is_deeply $where, { foo => { '$in' => ['bar'] } };
};

subtest 'inject_bounds_filters: injects filter directly when everything is allowed' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions(
        actions => [ { action => 'action.some', bounds => [ {} ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( $user->username, 'action.some', $where, filters => { foo => [ 'bar', 'baz' ] } );

    is_deeply $where, { foo => { '$in' => [ 'bar', 'baz' ] } };
};

subtest 'inject_bounds_filters: injects filter directly when root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( 'root', 'action.some', $where, filters => { foo => ['bar', 'baz'] } );

    is_deeply $where, { foo => { '$in' => ['bar', 'baz'] } };
};

subtest 'inject_bounds_filters: ignores empty filters when root' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters('root', 'action.some', $where, filters => {foo => []});

    is_deeply $where, {};
};

subtest 'inject_bounds_filters: maps bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => { bounds => [ { key => 'foo' } ] } );

    my $user = _create_user_with_actions( actions => [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] );

    my $permissions = _build_permissions();

    my $where = {};
    $permissions->inject_bounds_filters( $user->username, 'action.some', $where, map => { foo => 'bar' } );

    is_deeply $where, { bar => { '$in' => ['bar'] } };
};

done_testing();

{

    package TestBounds;

    sub new {
        my $class = shift;

        my $self = {};
        bless $self, $class;

        return $self;
    }

    sub bounds {
        { id => '1', title => 'Title' };
    }

}

sub _create_user_with_actions {
    my (%params) = @_;

    my $project = $params{project} || TestUtils->create_ci('project');
    my $id_role = $params{id_role} || TestSetup->create_role( actions => delete $params{actions} || [] );

    return TestSetup->create_user( id_role => $id_role, project => $project, %params );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',   'BaselinerX::Type::Action',
        'BaselinerX::Type::Service', 'BaselinerX::Type::Statement',
        'BaselinerX::CI',
    );

    TestUtils->cleanup_cis;

    mdb->role->drop;
    mdb->rule->drop;
    mdb->category->drop;
    mdb->topic->drop;
}

sub _build_permissions {
    return Baseliner::Model::Permissions->new;
}
