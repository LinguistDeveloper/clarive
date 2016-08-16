use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';
use TestSetup;
use TestGit;

use Clarive::ci;
use Clarive::mdb;

# This is needed for tests, so Moose can find all the classes
use BaselinerX::CI::balix_agent;
use BaselinerX::CI::ssh_agent;

use_ok 'Baseliner::Controller::CI';

subtest 'tree_object_depend: returns dependencies tree correctly' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'MyUser' );

    my $variable = TestUtils->create_ci( 'variable', name => 'My variable' );
    my $mid = $variable->mid;

    my $variable2 = TestUtils->create_ci( 'variable', name => 'My other variable', created_by => $user->username );
    my $mid2 = $variable2->mid;

    mdb->master_rel->insert( { from_mid => $mid, to_mid => $mid2, rel_type => 'ci_ci' } );
    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_object_depend( parent => $mid, from => $mid, limit => 25, start => 0 );

    is $count, 1;
    cmp_deeply \@tree, [
        {
            '_id'      => "$mid-0",
            '_parent'  => "$mid",
            '_is_leaf' => \0,

            'icon'        => ignore(),
            'class'       => 'BaselinerX::CI::variable',
            'properties'  => undef,
            'versionid'   => '1',
            'classname'   => 'BaselinerX::CI::variable',
            'mid'         => "$mid2",
            'modified_by' => undef,
            'created_by'  => 'MyUser',
            'bl'          => ['*'],
            'type'        => 'object',
            'collection'  => 'variable',
            'moniker'     => undef,
            'data'        => ignore(),
            'item'        => 'My other variable',
            'ts'          => ignore(),
        }
    ];
};

subtest 'tree_objects: returns created_by' => sub {
    _setup();

    my $project    = TestUtils->create_ci('project');
    my $id_role    = TestSetup->create_role();
    my $user       = TestSetup->create_user( id_role => $id_role, project => $project, username => 'MyUser' );
    my $variable   = TestUtils->create_ci( 'folder', mid => '222', created_by => $user->username );
    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_objects();

    is $tree[0]->{created_by}, 'MyUser';
};

subtest 'tree_objects: returns bls from bl' => sub {
    _setup();

    TestUtils->create_ci( 'generic_server', hostname => 'foo', bl => 'DEV' );

    my $controller = _build_controller();
    my ( $count, @tree ) = $controller->tree_objects();

    is $tree[0]->{bl}, 'DEV';
};

subtest 'tree_objects: converts bls mids to bl list' => sub {
    _setup();

    my $bl1 = TestUtils->create_ci( 'bl', bl => 'DEV',  name => 'DEV' );
    my $bl2 = TestUtils->create_ci( 'bl', bl => 'PROD', name => 'PROD' );

    TestUtils->create_ci( 'status', bls => [ $bl1->mid, $bl2->mid ] );

    my $controller = _build_controller();
    my ( $count, @tree ) = $controller->tree_objects();

    my ($status) = grep { $_->{classname} eq 'BaselinerX::CI::status' } @tree;

    is $status->{bl}, 'DEV,PROD';
};

subtest 'tree_roles: returns no roles when user has no permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_roles( user => $user->username );

    is scalar @tree, 0;
};

subtest 'tree_roles: returns roles when user has permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin.Agent.balix_agent' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_roles( user => $user->username );

    is @tree, 1;
};

subtest 'tree_roles: returns roles when user has all admin permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_roles( user => $user->username );

    ok scalar @tree;
};

subtest 'tree_roles: returns All as first item name in tree when sort = name' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_roles( user => $user->username, sort=> 'name');

    is $tree[0]->{item}, 'All'
};

subtest 'list_roles: returns All as item name' => sub {
    _setup();

    my $controller = _build_controller();

    my @tree = $controller->list_roles;

    ok grep { $_->{name} eq 'All' } @tree;
};

subtest 'list_roles: returns All as first item name in tree when sort = name' => sub {
    _setup();

    my $controller = _build_controller();

    my @tree = $controller->list_roles ( sort=> 'name');

    ok grep { $_->{name} eq 'All' } @tree;
};

subtest 'roles: returns all as first data item name with name_format lc and sort = name' => sub {
    _setup();

    my $c = _build_c( req => { params => { name_format => 'lc' } } );

    my $controller = _build_controller();
    my @tree = $controller->roles($c);

    my $data = $c->stash->{json}->{data}->[0];
    is $data->{name}, 'all'
};

subtest 'roles: returns All as first data item name with name_format short' => sub {
    _setup();

    my $c = _build_c( req => { params => { name_format => 'short' } } );

    my $controller = _build_controller();
    my @tree = $controller->roles($c);

    my $data = $c->stash->{json}->{data}->[0];
    is $data->{name}, 'All'
};

subtest 'tree_classes: returns no roles when user has no permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my ($cnt, @tree) = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI::Variable',
        role_name => 'Variable'
    );

    is scalar @tree, 0;
    is $cnt, 0;
};

subtest 'tree_classes: returns roles when user has permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin.Agent.balix_agent' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my ($cnt, @tree) = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI::Agent',
        role_name => 'Agent'
    );

    is @tree, 1;
    is $cnt, 1;
    ok grep { $_->{class} eq 'BaselinerX::CI::balix_agent' } @tree;
};

subtest 'tree_classes: returns roles when user has all admin permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my ($cnt, @tree) = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI::Variable',
        role_name => 'Variable'
    );

    ok scalar @tree;
    is $cnt, 1;
    ok grep { $_->{class} eq 'BaselinerX::CI::variable' } @tree;
};

subtest 'tree_classes: returns 1 role when limit is 1' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my ( $cnt, @tree ) = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI',
        role_name => 'Todos',
        limit     => 1
    );

    is scalar @tree, 1;
};


subtest 'tree_classes: returns all role when limit is 1' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my ($cnt, @tree) = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI',
        role_name => 'Todos'
    );

    is scalar @tree, $cnt;
};


subtest 'grid: set save to false when no collection' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( username => $user->username );

    my $controller = _build_controller();

    $controller->grid($c);

    is_deeply $c->stash,
      {
        'save'     => 'false',
        'template' => '/comp/ci-gridtree.js'
      };
};

subtest 'grid: set save to false when no permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { collection => 'variable' } }, username => $user->username );

    my $controller = _build_controller();

    $controller->grid($c);

    is_deeply $c->stash,
      {
        'save'     => 'false',
        'template' => '/comp/ci-gridtree.js'
      };
};

subtest 'grid: set save to true when has permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin.Variable.variable' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { collection => 'variable' } }, username => $user->username );

    my $controller = _build_controller();

    $controller->grid($c);

    is_deeply $c->stash,
      {
        'save'     => 'true',
        'template' => '/comp/ci-gridtree.js'
      };
};

subtest 'grid: set save to true when has admin permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { collection => 'variable' } }, username => $user->username );

    my $controller = _build_controller();

    $controller->grid($c);

    is_deeply $c->stash,
      {
        'save'     => 'true',
        'template' => '/comp/ci-gridtree.js'
      };
};

subtest 'edit: cannot save when not admin' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.ci.view.%.variable',
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { collection => 'variable' } }, username => $user->username );

    my $controller = _build_controller();

    $controller->edit($c);

    is_deeply $c->stash,
      {
        'save'     => 'false',
        'template' => '/comp/ci-editor.js'
      };
};

subtest 'edit: can save when admin' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.ci.admin.%.variable',
            }
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { collection => 'variable' } }, username => $user->username );

    my $controller = _build_controller();

    $controller->edit($c);

    is_deeply $c->stash,
      {
        'save'     => 'true',
        'template' => '/comp/ci-editor.js'
      };
};

subtest 'edit: throws when unknown ci' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { mid => 1 } }, username => $user->username );

    my $controller = _build_controller();

    like exception { $controller->edit($c) }, qr/Could not find CI 1 in database/;
};

subtest 'edit: throws when no permissions to view ci' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    like exception { $controller->edit($c) }, qr/User developer not authorized to view CI .*? of class variable/;
};

subtest 'edit: sets save to false when no permission to admin' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.view.Variable.variable' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->edit($c);

    is_deeply $c->stash,
      {
        'save'     => 'false',
        'template' => '/comp/ci-editor.js'
      };
};

subtest 'edit: sets save to true when has admin permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin.Variable.variable' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->edit($c);

    is_deeply $c->stash,
      {
        'save'     => 'true',
        'template' => '/comp/ci-editor.js'
      };
};

subtest 'edit: sets save to true when has admin permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->edit($c);

    is_deeply $c->stash,
      {
        'save'     => 'true',
        'template' => '/comp/ci-editor.js'
      };
};

subtest 'edit: sets save to true when has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions =>
          [ { action => 'action.ci.view.Variable.variable' }, { action => 'action.ci.admin.Variable.variable' }, ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->edit($c);

    is_deeply $c->stash,
      {
        'save'     => 'true',
        'template' => '/comp/ci-editor.js'
      };
};

subtest 'update: updates status names' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $id_rule     = _create_changeset_form();
    my $id_category = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_rule,
        is_changeset => 1
    );

    my $status = TestUtils->create_ci( 'status', name => 'Current_Name', moniker => 'CA', type => 'I' );

    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_category,
        project     => $project,
        status      => $status
    );

    my $c = _build_c(
        req => {
            params => {
                mid       => $status->mid,
                form_data => {
                    name    => 'New_Name',
                    moniker => 'CN',
                    active  => 'on',
                },
                action     => 'edit',
                collection => 'status'
            }
        }
    );

    my $controller = _build_controller();

    $controller->update($c);

    my $updated_topic = mdb->topic->find_one( { mid => $topic_mid } );

    is $updated_topic->{category_status_name}, 'New_Name';
    is $updated_topic->{category_status}->{_sort}->{name}, 'New_Name';
    is $updated_topic->{category_status}->{moniker}, 'CN';
    is $updated_topic->{category_status}->{name},    'New_Name';
    is $updated_topic->{name_status}, 'New_Name';

    cmp_deeply $c->stash,
      {
        json => {
            'success' => \1,
            'msg'     => 'CI New_Name saved ok',
            'mid'     => $status->mid
        }
      };
};

subtest 'load: throws when no mid' => sub {
    _setup();

    my $c = _build_c();

    my $controller = _build_controller();

    like exception { $controller->load($c) }, qr/mid required/;
};

subtest 'load: sets error when cannot load CI' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->load($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => re(qr/CI load error: User developer not authorized to view CI .*? of class variable/)
        }
      };
};

subtest 'load: sets CI when user has permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.view.Variable.variable' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->load($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => re(qr/CI .*? loaded ok/),
            rec     => ignore()
        }
      };
};

subtest 'load: sets CI when user has admin permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $ci = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mid => $ci->mid } }, username => $user->username );

    my $controller = _build_controller();

    $controller->load($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => re(qr/CI .*? loaded ok/),
            rec     => ignore()
        }
      };
};

subtest 'new_ci: loads ci when admin rights' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { collection => 'variable' } }, username => $user->username );

    my $controller = _build_controller();

    $controller->new_ci($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => re(qr/CI .*? loaded ok/),
            rec     => ignore()
        }
      };
};

subtest 'delete: deletes ci' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { collection => 'variable', mids => [ $variable->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->delete($c);

    like exception { ci->new( $variable->mid ) }, qr/not found/;

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'CIs deleted ok',
            'success' => \1
        }
      };
};

subtest 'delete: asks user before deleting a project' => sub {
    _setup();

    my $project  = TestUtils->create_ci( 'project', name => 'Project1' );
    my $project2 = TestUtils->create_ci( 'project', name => 'Project2' );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user1 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'foo1' );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'foo2' );
    my $user3 = TestSetup->create_user( id_role => $id_role, project => $project2, username => 'foo3' );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { collection => 'project', mids => [ $project->mid, $project2->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->delete($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'info' => [
                {
                    'ci_name'     => 'Project1',
                    'number_user' => '3'
                },
                {
                    'ci_name'     => 'Project2',
                    'number_user' => '1'
                }
            ],
            'success'            => \1,
            'needs_confirmation' => 1
        }
      };
};

subtest 'delete: deletes project when confirmed' => sub {
    _setup();

    my $project  = TestUtils->create_ci( 'project', name => 'Project1' );
    my $project2 = TestUtils->create_ci( 'project', name => 'Project2' );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user1 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'foo1' );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'foo2' );
    my $user3 = TestSetup->create_user( id_role => $id_role, project => $project2, username => 'foo3' );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req =>
          { params => { collection => 'project', delete_confirm => 1, mids => [ $project->mid, $project2->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->delete($c);

    like exception { ci->new( $project->mid ) }, qr/not found/;

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'CIs deleted ok',
            'success' => \1
        }
      };
};

subtest 'delete: updates user security when deleting a project' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project1' );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { collection => 'project', delete_confirm => 1, mids => [ $project->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->delete($c);

    $user = ci->new( $user->mid );

    is_deeply $user->{project_security}->{$id_role}->{project}, [];
};

subtest 'delete: asks user before deleting an area' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );
    my $area    = TestUtils->create_ci( 'area',    name => 'AREA' );
    my $area2   = TestUtils->create_ci( 'area',    name => 'AREA 2' );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user1 = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        area     => [ $area, $area2 ],
        username => 'foo1'
    );

    my $c = _build_c(
        req      => { params => { collection => 'area', delete_confirm => 1, mids => $area2->mid } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->delete($c);

    like exception { ci->new( $area2->mid ) }, qr/not found/;

    cmp_deeply $c->stash,
      {
        'json' => {
            'msg'     => 'CIs deleted ok',
            'success' => \1
        }
      };
};

subtest 'delete: deletes area when confirmed' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );
    my $area    = TestUtils->create_ci( 'area',    name => 'AREA' );
    my $area2   = TestUtils->create_ci( 'area',    name => 'AREA 2' );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user1 = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        area     => [ $area, $area2 ],
        username => 'foo1'
    );

    my $c = _build_c(
        req      => { params => { collection => 'area', mids => $area2->mid } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->delete($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'info' => [
                {
                    'ci_name'     => 'AREA 2',
                    'number_user' => '1'
                }
            ],
            'success'            => \1,
            'needs_confirmation' => 1
        }
      };
};

subtest 'delete: throws error when no permission to delete ci' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { collection => 'variable', mids => [ $variable->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    like exception { $controller->delete($c) }, qr/User developer not authorized to delete CI variable/;
};

subtest 'export: exports ci to yaml' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { mids => [ $variable->mid ] } }, username => $user->username );

    my $controller = _build_controller();

    $controller->export($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => 'CIs exported ok',
            data    => re(qr/---\n.*name: variable/ms)
        }
      };
};

subtest 'export: exports ci to json' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c =
      _build_c( req => { params => { format => 'json', mids => [ $variable->mid ] } }, username => $user->username );

    my $controller = _build_controller();

    $controller->export($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => 'CIs exported ok',
            data    => code( sub { JSON::decode_json( $_[0] ) } )
        }
      };
};

subtest 'export: exports ci to csv' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { ci_type => 'variable', format => 'csv', mids => [ $variable->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    $controller->export($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => 'CIs exported ok',
            data    => re(qr/bl;description;/)
        }
      };
};

subtest 'export: throws when user has no permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { ci_type => 'variable', format => 'csv', mids => [ $variable->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    like exception { $controller->export($c) }, qr/User developer not authorized to export CI variable/;
};

subtest 'import_all: throws when user has no permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c(
        req      => { params => { ci_type => 'variable', format => 'csv', mids => [ $variable->mid ] } },
        username => $user->username
    );

    my $controller = _build_controller();

    like exception { $controller->import_all($c) }, qr/User developer not authorized to import CIs/;
};

subtest 'tree_objects: returns cis without filtering' => sub {
    _setup();

    my $variable = TestUtils->create_ci('variable');

    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_objects();

    is $count, 1;
    is scalar @tree, 1;
    is $tree[0]->{collection}, 'variable';
};

subtest 'tree_objects: returns cis with filtering by json condition' => sub {
    _setup();

    TestUtils->create_ci( 'variable', name => 'My variable' );
    TestUtils->create_ci( 'variable', name => 'Your variable' );

    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_objects( filter => '{"name":"My variable"}' );

    is $count, 1;
    is scalar @tree, 1;
    is $tree[0]->{name}, 'My variable';
};

subtest 'tree_objects: sorts by seq by default' => sub {
    _setup();

    TestUtils->create_ci( 'variable', name => 'My variable' );
    TestUtils->create_ci( 'variable', name => 'Your variable' );

    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_objects();

    is $count, 2;
    is scalar @tree, 2;
    is $tree[0]->{name}, 'My variable';
    is $tree[1]->{name}, 'Your variable';
};

subtest 'tree_objects: sorts by direction' => sub {
    _setup();

    TestUtils->create_ci( 'variable', name => 'My variable' );
    TestUtils->create_ci( 'variable', name => 'Your variable' );

    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_objects( dir => 'desc' );

    is $count, 2;
    is scalar @tree, 2;
    is $tree[0]->{name}, 'Your variable';
    is $tree[1]->{name}, 'My variable';
};

subtest 'tree_objects: searches by mids' => sub {
    _setup();

    my $ci1 = TestUtils->create_ci( 'variable', name => 'My variable' );
    my $ci2 = TestUtils->create_ci( 'variable', name => 'Your variable' );

    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_objects( mids => [ $ci1->mid ] );

    is $count, 1;
    is scalar @tree, 1;
    is $tree[0]->{name}, 'My variable';
};

# Doesn't work :(
#subtest 'tree_objects: limit/start' => sub {
#    _setup();
#
#    my $ci1 = TestUtils->create_ci( 'variable', name => 'My variable' );
#    my $ci2 = TestUtils->create_ci( 'variable', name => 'Your variable' );
#
#    my $controller = _build_controller();
#
#    my ( $count, @tree ) = $controller->tree_objects(start => 1, limit => 1);
#
#    is $count, 1;
#    is scalar @tree, 1;
#    is $tree[0]->{name}, 'Your variable';
#};

subtest 'tree_object_info: returns dependencies tree' => sub {
    _setup();

    my $variable = TestUtils->create_ci( 'variable', name => 'My variable' );

    my $mid = $variable->mid;

    my $controller = _build_controller();

    my (@tree) = $controller->tree_object_info( mid => $mid, parent => $mid );

    is scalar @tree, 3;

    cmp_deeply \@tree,
      [
        {
            _id       => "$mid-0",
            _parent   => "$mid",
            _is_leaf  => \0,
            mid       => $mid,
            item      => ignore(),
            type      => 'depend_from',
            class     => '-',
            classname => '-',
            icon      => ignore(),
            ts        => '',
            versionid => '',
        },
        {
            _id       => "$mid-1",
            _parent   => "$mid",
            _is_leaf  => \0,
            mid       => $mid,
            item      => ignore(),
            type      => 'depend_to',
            class     => '-',
            classname => '-',
            icon      => ignore(),
            ts        => '',
            versionid => '',
        },
        {
            _id       => "$mid-2",
            _parent   => "$mid",
            _is_leaf  => \0,
            mid       => $mid,
            item      => ignore(),
            type      => 'ci_request',
            class     => '-',
            classname => '-',
            icon      => ignore(),
            ts        => '',
            versionid => '',
        },
      ];
};

subtest 'tree_object_depend: returns dependencies tree' => sub {
    _setup();

    my $variable = TestUtils->create_ci( 'variable', name => 'My variable' );
    my $mid = $variable->mid;

    my $variable2 = TestUtils->create_ci( 'variable', name => 'My other variable' );
    my $mid2 = $variable2->mid;

    mdb->master_rel->insert( { from_mid => $mid, to_mid => $mid2, rel_type => 'ci_ci' } );
    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_object_depend( parent => $mid, from => $mid, limit => 25, start => 0 );

    is $count, 1;
    cmp_deeply \@tree, [
        {
            '_id'      => "$mid-0",
            '_parent'  => "$mid",
            '_is_leaf' => \0,

            'icon'        => ignore(),
            'class'       => 'BaselinerX::CI::variable',
            'properties'  => undef,
            'versionid'   => '1',
            'classname'   => 'BaselinerX::CI::variable',
            'mid'         => "$mid2",
            'modified_by' => undef,
            'created_by'  => undef,
            'bl'          => ['*'],
            'type'        => 'object',
            'collection'  => 'variable',
            'moniker'     => undef,
            'data'        => ignore(),
            'item'        => 'My other variable',
            'ts'          => ignore(),
        }
    ];
};

subtest 'tree_ci_request: returns dependencies tree' => sub {
    _setup();

    my $variable = TestUtils->create_ci( 'variable', name => 'My variable' );
    my $mid = $variable->mid;

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.category.view',
            }
        ]
    );

    my $developer = TestSetup->create_user( id_role => $id_role, project => $project );
    my $status_new = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $topic_mid =
      TestSetup->create_topic( project => $project, from_mid => $mid, rel_type => 'ci_request', status => $status_new );

    my $controller = _build_controller();

    my ( $count, @tree ) = $controller->tree_ci_request( mid => $mid, parent => $mid );

    is $count, 1;
    is scalar @tree, 1;

    cmp_deeply \@tree,
      [
        {
            '_id'        => "$mid-0",
            '_parent'    => $mid,
            '_is_leaf'   => \1,
            'bl'         => undef,
            'class'      => 'BaselinerX::CI::topic',
            'collection' => 'topic',
            'data'       => ignore(),
            'icon'       => ignore(),
            'item'       => "Category #$topic_mid",
            'mid'        => $topic_mid,
            'properties' => '',
            'title'      => 'New Topic',
            'ts'         => undef,
            'type'       => 'topic',
            'versionid'  => '',
        }
      ];
};

subtest 'user_can_search: checks if user can search cis' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $another_project = TestUtils->create_ci('project');
    my $another_id_role = TestSetup->create_role();
    my $another_user =
      TestSetup->create_user( username => 'another_user', id_role => $another_id_role, project => $another_project );

    my $controller = _build_controller();

    ok !$controller->user_can_search( $another_user->username );
    ok $controller->user_can_search( $user->username );
};

subtest 'attach_revisions: attaches GitRevision to the changeset' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $id_rule     = _create_changeset_form();
    my $id_category = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_rule,
        is_changeset => 1
    );

    my $topic_mid =
      TestSetup->create_topic( username => $user->username, id_category => $id_category, project => $project );

    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        req => {
            params => {
                topic_mid => $topic_mid,
                repo      => $repo->mid,
                name      => 'master',
                branch    => 'master',
                ns        => 'git.revision/master',
                class     => 'GitRevision',
                ci_json   => JSON::encode_json(
                    {
                        'repo_dir' => $repo->repo_dir,
                        'ci_pre'   => [
                            {
                                'class' => 'GitRepository',
                                'name'  => $repo->repo_dir,
                                'mid'   => $repo->mid,
                                'data'  => {
                                    'repo_dir' => $repo->repo_dir,
                                },
                                'ns' => 'git.repository/' . $repo->repo_dir
                            }
                        ],
                        'repo'    => 'ci_pre:0',
                        'sha'     => 'master',
                        'rev_num' => 'master',
                        'branch'  => 'master'
                    }
                )
            }
        },
        username => $user->username
    );

    $controller->attach_revisions($c);

    my $revision = ci->GitRevision->find_one;

    cmp_deeply $c->stash,
      {
        'json' => {
            'success' => \1,
            'msg'     => 'CI master saved ok',
            'mid'     => $revision->{mid}
        }
      };
};

subtest 'attach_revisions: does not create already existing GitRevision' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    TestGit->commit($repo);

    TestUtils->create_ci( 'GitRevision', name => 'master', sha => 'master' );

    my $project = TestUtils->create_ci( 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $id_rule     = _create_changeset_form();
    my $id_category = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_rule,
        is_changeset => 1
    );

    my $topic_mid =
      TestSetup->create_topic( username => $user->username, id_category => $id_category, project => $project );

    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        req => {
            params => {
                topic_mid => $topic_mid,
                repo      => $repo->mid,
                name      => 'master',
                branch    => 'master',
                ns        => 'git.revision/master',
                class     => 'GitRevision',
                ci_json   => JSON::encode_json(
                    {
                        'repo_dir' => $repo->repo_dir,
                        'ci_pre'   => [
                            {
                                'class' => 'GitRepository',
                                'name'  => $repo->repo_dir,
                                'mid'   => $repo->mid,
                                'data'  => {
                                    'repo_dir' => $repo->repo_dir,
                                },
                                'ns' => 'git.repository/' . $repo->repo_dir
                            }
                        ],
                        'repo'    => 'ci_pre:0',
                        'sha'     => 'master',
                        'rev_num' => 'master',
                        'branch'  => 'master'
                    }
                )
            }
        },
        username => $user->username
    );

    $controller->attach_revisions($c);

    my $count = ci->GitRevision->find->count;

    is $count, 1;
};

subtest 'attach_revisions: returns error if not specify class' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $id_rule     = _create_changeset_form();
    my $id_category = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_rule,
        is_changeset => 1
    );

    my $topic_mid =
      TestSetup->create_topic( username => $user->username, id_category => $id_category, project => $project );

    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        req => {
            params => {
                topic_mid => $topic_mid,
                repo      => $repo->mid,
                name      => 'master',
                branch    => 'master',
                ns        => 'git.revision/master',
                class     => '',
                ci_json   => JSON::encode_json(
                    {
                        'repo_dir' => $repo->repo_dir,
                        'ci_pre'   => [
                            {
                                'class' => 'GitRepository',
                                'name'  => $repo->repo_dir,
                                'mid'   => $repo->mid,
                                'data'  => {
                                    'repo_dir' => $repo->repo_dir,
                                },
                                'ns' => 'git.repository/' . $repo->repo_dir
                            }
                        ],
                        'repo'    => 'ci_pre:0',
                        'sha'     => 'master',
                        'rev_num' => 'master',
                        'branch'  => 'master',
                    }
                )
            }
        },
        username => $user->username
    );

    $controller->attach_revisions($c);

    like $c->stash->{json}->{msg}, qr/CI error: Missing class for master/;

};

subtest 'attach_revisions: update ci if already exists' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    TestGit->commit($repo);

    TestUtils->create_ci( 'GitRevision', name => 'master', sha => 'master', description => 'original description' );

    my $project = TestUtils->create_ci( 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $id_rule     = _create_changeset_form();
    my $id_category = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_rule,
        is_changeset => 1
    );

    my $topic_mid =
      TestSetup->create_topic( username => $user->username, id_category => $id_category, project => $project );

    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        req => {
            params => {
                topic_mid => $topic_mid,
                repo      => $repo->mid,
                name      => 'master',
                branch    => 'master',
                ns        => 'git.revision/master',
                class     => 'GitRevision',
                ci_json   => JSON::encode_json(
                    {
                        'repo_dir' => $repo->repo_dir,
                        'ci_pre'   => [
                            {
                                'class' => 'GitRepository',
                                'name'  => $repo->repo_dir,
                                'mid'   => $repo->mid,
                                'data'  => {
                                    'repo_dir' => $repo->repo_dir,
                                },
                                'ns' => 'git.repository/' . $repo->repo_dir
                            }
                        ],
                        'repo'    => 'ci_pre:0',
                        'sha'     => 'master',
                        'rev_num' => 'master',
                        'branch'  => 'master',
                        'description' => 'description updated'
                    }
                )
            }
        },
        username => $user->username
    );

    $controller->attach_revisions($c);

    my $count = ci->GitRevision->find->count;
    my $revision = ci->GitRevision->find_one;

    is $count, 1;
    is $revision->{description}, 'description updated';
};

subtest 'service_run: throws an error when user does not have access' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.view.Repository.GitRepository' } ] );
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        req => {
            params => {
                mid       => $repo->mid,
                classname => 'BaselinerX::CI::GitRepository',
                key       => "service.gitrepository.create_tags",
                data      => JSON::encode_json(
                    {
                        'existing'   => 'detect',
                        'tag_filter' => '',
                        'ref'        => ''
                    }
                )
            }
        },
        username => $user->username
    );

    like exception {
        $controller->service_run($c);
    }, qr/User user not authorized to admin CIs of class GitRepository/;
};

subtest 'service_run: service is run if user have permissions to do it' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin.Repository.GitRepository' } ] );
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        req => {
            params => {
                mid       => $repo->mid,
                classname => "BaselinerX::CI::GitRepository",
                key       => "service.gitrepository.create_tags",
                data      => {}
            }
        },
        username => $user->username
    );

    $controller->service_run($c);

    cmp_deeply $c->stash,
      {
        json => {
            success   => \1,
            console   => ignore(),
            data      => ignore(),
            js_output => ignore(),
            ret       => ignore()
        }
      };
};

subtest 'json_tree: returns selected data' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status = TestUtils->create_ci( 'status', name => 'Status' );

    my $c = _build_c( req => { params => { mid => $status->mid } } );
    my $controller = _build_controller();

    my @res = $controller->json_tree($c);

    cmp_deeply $c->stash->{json}->{data},
      {
        'children' => ignore(),
        'data'     => ignore(),
        'id'       => ignore(),
        'name'     => 'Status'
      };
};

subtest 'json_tree: returns error when mids are not selected' => sub {
    _setup();

    my $c = _build_c( req => { params => { mid => '' } } );
    my $controller = _build_controller();

    $controller->json_tree($c);

    like $c->stash->{json}->{msg}, qr/Items must be selected/;
};

done_testing;

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
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "fieldletType" => "fieldlet.system.projects",
                    },
                    "key" => "fieldlet.system.projects",
                    name  => 'Project',
                }
            },
        ],
    );
}

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    Baseliner::Controller::CI->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',            'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',   'Baseliner::Model::Rules',
        'BaselinerX::Type::Service', 'BaselinerX::CI::GitRepository'
    );

    TestUtils->cleanup_cis();

    mdb->role->drop;
    mdb->category->drop;
    mdb->topic->drop;
    mdb->rule->drop;
    mdb->master_rel->drop;
}
