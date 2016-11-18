use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use_ok 'Baseliner::Controller::Message';

subtest 'to_and_cc: without params' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();

    $controller->to_and_cc($c);

    is ${ $c->stash->{json}->{success} }, 1;
};

subtest 'to_and_cc: with params' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = mock_catalyst_c(
        username => 'root',
        req      => { params => { query => 'user/1300', deny_email => 1 } }
    );

    $controller->to_and_cc($c);
    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            data    => [
                {
                    id   => 'user/1300',
                    long => '',
                    name => 'user/1300',
                    ns   => 'user/1300',
                    type => 'Email'
                }
            ],
            totalCount => 1
        }
    };
};

subtest 'to_and_cc: returns user and role' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'MyUser' );

    my $c = _build_c( req => { params => { } } );
    my $controller = _build_controller();

    $controller->to_and_cc($c);

    cmp_deeply $c->stash->{json}->{data},
    [
        {
            id => $user->mid,
            long => ignore(),
            ns => ignore(),
            name => $user->username,
            type => 'User'
        },
        {
            id => $id_role,
            long => ignore(),
            ns => ignore(),
            name => 'Role',
            type => 'Role'
        }
    ];
};

subtest 'to_and_cc: returns filtered user' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'MyUser' );

    my $c = _build_c( req => { params => { query => 'User' } } );
    my $controller = _build_controller();

    $controller->to_and_cc($c);

    cmp_deeply $c->stash->{json}->{data},
    [
        {
            id => $user->mid,
            long => ignore(),
            ns => ignore(),
            name => $user->username,
            type => 'User'
        },
        {
            id => 'User',
            long => ignore(),
            ns => 'User',
            name => 'User',
            type => 'Email'
        }
    ];
};

subtest 'to_and_cc: returns a new parameter created by query type Email' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'MyUser' );

    my $c = _build_c( req => { params => { query => 'mi@email.com' } } );
    my $controller = _build_controller();

    $controller->to_and_cc($c);

    cmp_deeply $c->stash->{json}->{data},
    [
        {   id   => 'mi@email.com',
            long => ignore(),
            ns   => 'mi@email.com',
            name => 'mi@email.com',
            type => 'Email'
        }
    ];
};

subtest 'to_and_cc: returns empty values from query' => sub {
    _setup();

    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( username => 'MyUser' );

    my $c = _build_c( req => { params => { denyEmail => 1, query => 'mi@email.com' } } );
    my $controller = _build_controller();

    $controller->to_and_cc($c);

    cmp_deeply $c->stash->{json}->{data}, [];
};

subtest 'inbox_json: returns empty inbox' => sub {
    _setup();

    my $user = TestSetup->create_user();

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username );

    $controller->inbox_json($c);

    is_deeply $c->stash,
      {
        username => $user->username,
        messages => {
            total => 0,
            data  => []
        }
      };
};

subtest 'inbox_json: returns inbox' => sub {
    _setup();

    my $user = TestSetup->create_user();

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username );

    TestSetup->create_message( queue => [ { username => $user->username } ] );

    $controller->inbox_json($c);

    cmp_deeply $c->stash,
      {
        username => $user->username,
        messages => {
            total => 1,
            data  => [ ignore() ]
        }
      };
};

subtest 'inbox_json: returns inbox for another user if has permission' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.admin.users'
            }
        ]
    );

    my $user = TestSetup->create_user( project => $project, id_role => $id_role );

    my $otheruser = TestSetup->create_user( username => 'otheruser' );

    TestSetup->create_message( queue => [ { username => $otheruser->username } ] );

    my $controller = _build_controller();

    my $c = _build_c( username => $user->username, req => { params => { username => $otheruser->username } } );

    $controller->inbox_json($c);

    cmp_deeply $c->stash,
      {
        username => $otheruser->username,
        messages => {
            total => 1,
            data  => [ ignore() ]
        }
      };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',  'BaselinerX::Type::Menu',
        'BaselinerX::Type::Config',  'BaselinerX::Type::Event',
        'BaselinerX::Type::Service', 'BaselinerX::CI',
        'BaselinerX::Auth',          'Baseliner::Controller::User',
    );

    TestUtils->cleanup_cis;

    mdb->message->drop;
    mdb->role->drop;
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Message->new( application => '' );
}

sub _build_c {
    mock_catalyst_c( username => 'root', @_ );
}
