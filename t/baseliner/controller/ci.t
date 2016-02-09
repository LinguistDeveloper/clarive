use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';
use TestSetup;

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;

# This is needed for tests, so Moose can find all the classes
use BaselinerX::CI::balix_agent;
use BaselinerX::CI::ssh_agent;

use_ok 'Baseliner::Controller::CI';

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

subtest 'tree_classes: returns no roles when user has no permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI::Variable',
        role_name => 'Variable'
    );

    is scalar @tree, 0;
};

subtest 'tree_classes: returns roles when user has permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin.Agent.balix_agent' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI::Agent',
        role_name => 'Agent'
    );

    is @tree, 1;
    ok grep { $_->{class} eq 'BaselinerX::CI::balix_agent' } @tree;
};

subtest 'tree_classes: returns roles when user has all admin permissions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.ci.admin' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $controller = _build_controller();

    my @tree = $controller->tree_classes(
        user      => $user->username,
        role      => 'Baseliner::Role::CI::Variable',
        role_name => 'Variable'
    );

    ok scalar @tree;
    ok grep { $_->{class} eq 'BaselinerX::CI::variable' } @tree;
};

subtest 'grid: set save to false when no collection' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c(username => $user->username);

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
    my $id_role = TestSetup->create_role( actions =>
          [ { action => 'action.ci.admin.Variable.variable' } ] );
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
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.view.Variable.variable'}] );
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
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.admin'}] );
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
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.admin'}] );
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
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.admin'}] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { collection => 'variable', mids => [$variable->mid] } }, username => $user->username );

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

subtest 'delete: throws error when no permission to delete ci' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { collection => 'variable', mids => [$variable->mid] } }, username => $user->username );

    my $controller = _build_controller();

    like exception { $controller->delete($c) }, qr/User developer not authorized to delete CI variable/;
};

subtest 'export: exports ci to yaml' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.admin'}] );
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
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.admin'}] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $variable = TestUtils->create_ci('variable');

    my $c = _build_c( req => { params => { format => 'json', mids => [ $variable->mid ] } }, username => $user->username );

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
    my $id_role = TestSetup->create_role( actions => [{action => 'action.ci.admin'}] );
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

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    Baseliner::Controller::CI->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::Events' );

    TestUtils->cleanup_cis();

    mdb->role->drop;
}

done_testing;
