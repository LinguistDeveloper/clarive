use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';

use Clarive::mdb;

use_ok 'Baseliner::Controller::Role';

subtest 'action_tree: returns all actions when new role' => sub {
    _setup();

    my $controller = _build_controller( actions => [ { key => 'action.topics.category.view' } ] );

    my $c = _build_c( req => { params => { } }, authenticate => {} );

    ok $controller->action_tree($c);

    my $actions = $c->stash->{json};

    is scalar @$actions, 1;

    is $actions->[0]->{key}, 'action.topics';
};

subtest 'action_tree: returns action tree' => sub {
    _setup();

    mdb->role->insert(
        {
            id      => '1',
            role    => 'Role',
            actions => [
                {
                    action => 'action.topics.category.view'
                }
            ]
        }
    );

    my $controller = _build_controller( actions => [ { key => 'action.topics.category.view' } ] );

    my $c = _build_c( req => { params => { id_role => '1' } }, authenticate => {} );

    ok $controller->action_tree($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                'icon'     => '/static/images/icons/action_folder.gif',
                'text'     => 'topics',
                'children' => [
                    {
                        'icon'      => '/static/images/icons/folder.gif',
                        '_modified' => 1,
                        'children'  => [
                            {
                                'icon' => '/static/images/icons/checkbox.png',
                                'text' => undef,
                                'id'   => 'action.topics.category.view',
                                'leaf' => \1,
                                'key'  => 'action.topics.category.view'
                            }
                        ],
                        'key'       => 'action.topics.category',
                        'text'      => 'category',
                        'leaf'      => \0,
                        'draggable' => \0
                    }
                ],
                'leaf'      => \0,
                'draggable' => \0,
                'key'       => 'action.topics'
            }
        ]
      };
};

subtest 'action_tree: searches through actions' => sub {
    _setup();

    mdb->role->insert(
        {
            id      => '1',
            role    => 'Role',
            actions => [
                {
                    action => 'action.topics.category.view',
                }
            ]
        }
    );

    my $controller =
      _build_controller( actions => [ { key => 'action.topics.category.view', name => 'View topics' } ] );

    my $c = _build_c( req => { params => { id_role => '1', query => 'topics' } }, authenticate => {} );

    $controller->action_tree($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'icon' => '/static/images/icons/checkbox.png',
                'text' => 'View topics',
                'id'   => 'action.topics.category.view',
                'leaf' => \1
            }
        ]
      };
};

subtest 'update: creates new role' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { id => '-1', name => 'Developer', role_actions => '[]' } } );

    $controller->update($c);

    my $role = mdb->role->find_one();
    ok($role);
    is( $role->{role}, 'Developer' );

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
                msg     => "Role created"
            }
        }
    );
};

subtest 'update: does not create new role with the same name as another' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { id => '-1', name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    $c = _build_c( req => { params => { id => '-1', name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    is( mdb->role->find->count, 1 );

    is_deeply(
        $c->stash,
        {
            json => {
                success => \0,
                msg     => "Error: role exists"
            }
        }
    );
};

subtest 'update: updates role that exists ' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { id => '-1', name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    my $role = mdb->role->find_one( { role => 'Developer' } );

    $c = _build_c( req => { params => { id => $role->{id}, name => 'Developer_new', role_actions => '[]' } } );
    $controller->update($c);

    my $role_updated = mdb->role->find_one( { id => $role->{id} } );

    is( $role_updated->{role}, 'Developer_new' );

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
                msg     => "Role modified"
            }
        }
    );
};

subtest 'update: does not update role with same name as another' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => '-1', name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    $c = _build_c( req => { params => { id => '-1', name => 'Manager', role_actions => '[]' } } );
    $controller->update($c);

    my $role = mdb->role->find_one( { role => 'Developer' } );

    $c = _build_c( req => { params => { id => $role->{id}, name => 'Manager', role_actions => '[]' } } );
    $controller->update($c);

    is_deeply(
        $c->stash,
        {
            json => {
                success => \0,
                msg     => "Error: another role exists with same name"
            }
        }
    );
};

sub _setup {
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->role->drop;

    TestUtils->setup_registry();
}

sub _build_controller {
    my (%params) = @_;

    my $actions = Test::MonkeyMock->new;
    $actions->mock( list => sub { @{ $params{actions} || [] } } );

    my $controller = Baseliner::Controller::Role->new( application => '' );

    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_model_actions => sub { $actions } );

    return $controller;
}

sub _build_c { mock_catalyst_c(@_); }

done_testing;
