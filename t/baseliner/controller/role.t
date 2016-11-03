use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestSetup;
use TestUtils ':catalyst';

use Clarive::mdb;

use Baseliner::CI;
use Baseliner::Role::CI;

use_ok 'Baseliner::Controller::Role';

subtest 'action_tree: returns all actions when new role' => sub {
    _setup();

    my $controller = _build_controller( actions => [ { key => 'action.ci.admin' } ] );

    my $c = _build_c( req => { params => {} }, authenticate => {} );

    ok $controller->action_tree($c);

    my $actions = $c->stash->{json};

    is scalar @$actions, 1;

    is $actions->[0]->{key}, 'action.ci';
};

subtest 'action_tree: returns action tree' => sub {
    _setup();

    mdb->role->insert(
        {
            id      => '1',
            role    => 'Role',
            actions => [
                {
                    action => 'action.ci.admin'
                }
            ]
        }
    );

    my $controller = _build_controller( actions => [ { key => 'action.ci.admin' } ] );

    my $c = _build_c( req => { params => { id_role => '1' } }, authenticate => {} );

    ok $controller->action_tree($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'draggable' => \0,
                'children'  => [
                    {
                        'icon'             => '/static/images/icons/checkbox.svg',
                        'id'               => 'action.ci.admin',
                        'text'             => '',
                        'bounds_available' => \0,
                        'key'              => 'action.ci.admin',
                        'leaf'             => \1
                    }
                ],
                'icon'      => '/static/images/icons/file.svg',
                'key'       => 'action.ci',
                'text'      => 'ci',
                'leaf'      => \0,
                '_modified' => 1
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
                    action => 'action.ci.admin',
                }
            ]
        }
    );

    my $controller =
      _build_controller( actions => [ { key => 'action.ci.admin', name => 'View topics' } ] );

    my $c = _build_c( req => { params => { id_role => '1', query => 'topics' } }, authenticate => {} );

    $controller->action_tree($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'icon' => '/static/images/icons/checkbox.svg',
                'text' => 'View topics',
                'id'   => 'action.ci.admin',
                'bounds_available' => \0,
                'leaf' => \1
            }
        ]
      };
};

subtest 'update: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => {} } );

    $controller->update($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => {
                name => 'REQUIRED'
            }
        }
      };
};

subtest 'update: creates new role' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => { name => 'Developer', description => 'New Role', dashboards => 1, role_actions => '[]' }
        }
    );

    $controller->update($c);

    my $role = mdb->role->find_one();

    ok $role;
    is $role->{role},        'Developer';
    is $role->{description}, 'New Role';
    is_deeply $role->{dashboards}, [1];

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
                msg     => "Role created",
                id      => $role->{id},
            }
        }
    );
};

subtest 'update: creates new role with multiple dashboards' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => { name => 'Developer', dashboards => [ 1, 2, 3 ], role_actions => '[]' }
        }
    );

    $controller->update($c);

    my $role = mdb->role->find_one();

    is_deeply $role->{dashboards}, [ 1, 2, 3 ];
};

subtest 'update: returns an error when creating a new role with existing name' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    $c = _build_c( req => { params => { name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    is( mdb->role->find->count, 1 );

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => "Validation failed",
            errors  => { name => 'Role with this name already exists' }
        }
      };
};

subtest 'update: updates role' => sub {
    _setup();

    local $Baseliner::_no_cache = 1;

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    my $role = mdb->role->find_one( { role => 'Developer' } );

    $c = _build_c( req => { params => { id => $role->{id}, name => 'Developer_new', role_actions => '[]' } } );
    $controller->update($c);

    my $role_updated = mdb->role->find_one( { id => "$role->{id}" } );

    is $role_updated->{role}, 'Developer_new';

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
                id      => $role_updated->{id},
                msg     => "Role modified"
            }
        }
    );
};

subtest 'update: creates role with actions' => sub {
    _setup();

    local $Baseliner::_no_cache = 1;

    my $controller = _build_controller();
    my $c = _build_c(
        req => {
            params => {
                name         => 'Developer',
                role_actions => JSON::encode_json( [ { action => 'action.some', bounds => [ { foo => 'bar' } ] } ] )
            }
        }
    );
    $controller->update($c);

    my $role_updated = mdb->role->find_one();

    is_deeply $role_updated->{actions},
      [
        {
            'action' => 'action.some',
            'bounds' => [
                {
                    'foo' => 'bar'
                }
            ]
        }
      ];
};

subtest 'update: creates role with actions converting no bounds' => sub {
    _setup();

    local $Baseliner::_no_cache = 1;

    my $controller = _build_controller();
    my $c = _build_c(
        req => {
            params => {
                name         => 'Developer',
                role_actions => JSON::encode_json( [ { action => 'action.some', bounds => '' } ] )
            }
        }
    );
    $controller->update($c);

    my $role_updated = mdb->role->find_one();

    is_deeply $role_updated->{actions}, [ { 'action' => 'action.some', 'bounds' => [ {} ] } ];
};

subtest 'update: creates role with actions converting empty bounds to no bounds' => sub {
    _setup();

    local $Baseliner::_no_cache = 1;

    my $controller = _build_controller();
    my $c = _build_c(
        req => {
            params => {
                name         => 'Developer',
                role_actions => JSON::encode_json( [ { action => 'action.some', bounds => [ {'' => ''}, { foo => 'bar' } ] } ] )
            }
        }
    );
    $controller->update($c);

    my $role_updated = mdb->role->find_one();

    is_deeply $role_updated->{actions}, [ { 'action' => 'action.some', 'bounds' => [ {}, { foo => 'bar' } ] } ];
};

subtest 'update: creates role with actions removing private keys' => sub {
    _setup();

    local $Baseliner::_no_cache = 1;

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                name         => 'Developer',
                role_actions => JSON::encode_json(
                    [
                        {
                            action => 'action.some',
                            bounds => [
                                { foo => 'bar', _deny => 1, _foo_title => 'Bar' },
                            ]
                        }
                    ]
                )
            }
        }
    );
    $controller->update($c);

    my $role_updated = mdb->role->find_one();

    is_deeply $role_updated->{actions}, [ { 'action' => 'action.some', 'bounds' => [ { _deny => 1, foo => 'bar' } ] } ];
};

subtest 'update: creates role with actions removing duplications' => sub {
    _setup();

    local $Baseliner::_no_cache = 1;

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                name         => 'Developer',
                role_actions => JSON::encode_json(
                    [
                        {
                            action => 'action.some',
                            bounds => [
                                { '' => '' },
                                {},
                                { foo => 'bar' },
                                { foo => 'bar' },
                                { foo => 'bar', another => 'here' }
                            ]
                        }
                    ]
                )
            }
        }
    );
    $controller->update($c);

    my $role_updated = mdb->role->find_one();

    is_deeply $role_updated->{actions},
      [ { 'action' => 'action.some', 'bounds' => [ {}, { foo => 'bar' }, { foo => 'bar', another => 'here' } ] } ];
};

subtest 'update: does not update role with same name as another' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { name => 'Developer', role_actions => '[]' } } );
    $controller->update($c);

    $c = _build_c( req => { params => { name => 'Manager', role_actions => '[]' } } );
    $controller->update($c);

    my $role = mdb->role->find_one( { role => 'Developer' } );

    $c = _build_c( req => { params => { id => $role->{id}, name => 'Manager', role_actions => '[]' } } );
    $controller->update($c);

    is_deeply(
        $c->stash,
        {
            json => {
                success => \0,
                msg     => 'Validation failed',
                errors  => {
                    name => 'Role with this name already exists'
                }
            }
        }
    );
};

subtest 'update: returns an error when unknown role id' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => '123', name => 'Manager', role_actions => '[]' } } );
    $controller->update($c);

    is_deeply(
        $c->stash,
        {
            json => {
                success => \0,
                msg     => 'Unknown role `123`',
            }
        }
    );
};

subtest 'delete: asks for confirmation when role has assigned users' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { id_role => $id_role } } );

    my $controller = _build_controller();
    $controller->delete($c);

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
                users   => ['developer']
            }
        }
    );
};

subtest 'delete: deletes role with users when confirmed' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = _build_c( req => { params => { id_role => $id_role, delete_confirm => '1' } } );

    my $controller = _build_controller();
    $controller->delete($c);

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
            }
        }
    );
};

subtest 'delete: deletes role without users' => sub {
    _setup();

    my $id_role = TestSetup->create_role();

    my $c = _build_c( req => { params => { id_role => $id_role, delete_confirm => '1' } } );

    my $controller = _build_controller();
    $controller->delete($c);

    is_deeply(
        $c->stash,
        {
            json => {
                success => \1,
            }
        }
    );
};

subtest 'duplicate: returns correct name when a role has been duplicated before' => sub {
    _setup();

    my $id_role1 = TestSetup->create_role(role => 'Role');
    my $id_role2 = TestSetup->create_role(role => 'Duplicate of Role');
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { id_role => $id_role1, role => 'Role'} }, authenticate => {} );
    $controller->duplicate($c);

    ok(mdb->role->find_one( {role => 'Duplicate of Role 2'}));
};

subtest 'duplicate: returns correct name' => sub {
    _setup();

    my $id_role1 = TestSetup->create_role(role => 'Role');
    my $controller = _build_controller( actions => [ { key => 'action.ci.admin' } ] );
    my $c = _build_c( req => { params => { id_role => $id_role1, role => 'Role'} }, authenticate => {} );
    $controller->duplicate($c);

    ok(mdb->role->find_one( {role => 'Duplicate of Role'}));

};

subtest 'json: returns correct successful response with filter' => sub {
    _setup();

    my $id_role  = TestSetup->create_role( role => 'Role', );
    my $id_role2 = TestSetup->create_role( role => 'Role5', );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { query => 'Role5' } });
    $controller->json($c);

    is $c->stash->{json}{data}[0]->{id}, $id_role2;
    is $c->stash->{json}{totalCount}, 1;

};

subtest 'json: returns correct successful response with limit all' => sub {
    _setup();

    my $id_role  = TestSetup->create_role( role => 'Role', );
    my $id_role2 = TestSetup->create_role( role => 'Role5', );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { limit => -1 } });
    $controller->json($c);

    is @{$c->stash->{json}{data}}, 2;
    is $c->stash->{json}{totalCount}, 2;
};

subtest 'json: returns correct successful response with limit defined' => sub {
    _setup();

    my $id_role  = TestSetup->create_role( role => 'Role', );
    my $id_role2 = TestSetup->create_role( role => 'Role5', );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { limit => 1 } });
    $controller->json($c);

    is @{$c->stash->{json}{data}}, 1;
    is $c->stash->{json}{totalCount}, 2;
};

subtest 'json: returns correct successful response without filter' => sub {
    _setup();

    my $id_role  = TestSetup->create_role( role => 'Role', );
    my $id_role2 = TestSetup->create_role( role => 'Role5', );

    my $controller = _build_controller();

    my $c = _build_c();
    $controller->json($c);

    is $c->stash->{json}{data}[0]->{id}, $id_role;
    is $c->stash->{json}{data}[1]->{id}, $id_role2;
    is $c->stash->{json}{totalCount}, 2;
};

subtest 'action_info: returns no info for unknown action' => sub {
    _setup();

    my $c = mock_catalyst_c( req => { params => { action => 'action.unknown' } } );

    my $controller = _build_controller();

    $controller->action_info($c);

    cmp_deeply $c->stash->{json}, {success => \0};
};

subtest 'action_info: returns info action' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main',
        'action.some' => { bounds => [ { key => 'foo', name => 'Foo' }, { key => 'bar', name => 'Bar' } ] } );

    my $c = mock_catalyst_c( req => { params => { action => 'action.some' } } );

    my $controller = _build_controller();

    $controller->action_info($c);

    cmp_deeply $c->stash->{json},
      {
        success => \1,
        info    => {
            values => [],
            action => 'action.some',
            bounds => [
                {
                    key     => 'foo',
                    name    => 'Foo',
                    depends => undef,
                },
                {
                    key     => 'bar',
                    name    => 'Bar',
                    depends => undef,
                }
            ]
        }
      };
};

subtest 'bounds: returns no data when unknown action' => sub {
    _setup();

    my $c = mock_catalyst_c( req => { params => { action => 'action.unknown' } } );

    my $controller = _build_controller();

    $controller->bounds($c);

    cmp_deeply $c->stash->{json}, {
        'data' => [
            {
                'id'    => '',
                'title' => 'Any'
            }
        ],
        totalCount => 1
    };
};

subtest 'bounds: returns no data when action has no bounds' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'action.some' => {} );

    my $c = mock_catalyst_c( req => { params => { action => 'action.some' } } );

    my $controller = _build_controller();

    $controller->bounds($c);

    cmp_deeply $c->stash->{json}, {
        'data' => [
            {
                'id'    => '',
                'title' => 'Any'
            }
        ],
        totalCount => 1
    };
};

subtest 'bounds: returns available bounds for action' => sub {
    _setup();

    Baseliner::Core::Registry->add(
        'main',
        'action.some' => {
            bounds =>
              [ { key => 'foo', name => 'Foo', handler => 'TestRoleAction=bounds' }, { key => 'bar', name => 'Bar' } ]
        }
    );

    my $c = mock_catalyst_c( req => { params => { action => 'action.some', bound => 'foo' } } );

    my $controller = _build_controller();

    $controller->bounds($c);

    cmp_deeply $c->stash->{json},
      { data => [ { id => '', title => 'Any' }, { id => 'id', title => 'Title' } ], totalCount => 2, };
};

subtest 'bounds: returns available bounds for action with filter' => sub {
    _setup();

    Baseliner::Core::Registry->add(
        'main',
        'action.some' => {
            bounds =>
              [ { key => 'foo', name => 'Foo', handler => 'TestRoleAction=bounds' }, { key => 'bar', name => 'Bar' } ]
        }
    );

    my $c = mock_catalyst_c(
        req => { params => { action => 'action.some', bound => 'foo', filter => JSON::encode_json( { filter => 'me' } ) } }
    );

    my $controller = _build_controller();

    $controller->bounds($c);

    cmp_deeply $c->stash->{json},
      { data => [ { id => '', title => 'Any' }, { id => 'filtered', title => 'Filtered' } ], totalCount => 2, };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Events',
        'BaselinerX::Fieldlets',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Topic',
    );

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->role->drop;
}

sub _build_controller {
    my (%params) = @_;

    my $actions = Test::MonkeyMock->new;
    $actions->mock(
        list => sub {
            my @actions = @{ $params{actions} || [] };

            my @objects;
            foreach my $action (@actions) {
                my $mock = Test::MonkeyMock->new;
                $mock->mock( key    => sub { $action->{key} } );
                $mock->mock( name   => sub { $action->{name} } );
                $mock->mock( bounds => sub { } );
                push @objects, $mock;
            }

            return @objects;
        }
    );

    my $controller = Baseliner::Controller::Role->new( application => '' );

    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_model_actions => sub { $actions } );

    return $controller;
}

sub _build_c { mock_catalyst_c(@_); }

package TestRoleAction;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub bounds {
    my $self = shift;
    my (%params) = @_;

    return ({id => 'filtered', title => 'Filtered'}) if $params{filter};

    (
        {
            id => 'id',
            title => 'Title',
        }
    )
}
