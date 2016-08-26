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
                {   id   => 'user\/1300',
                    long => '',
                    name => 'user\/1300',
                    ns   => 'user\/1300',
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
        {
            id => 'mi\@email\.com',
            long => ignore(),
            ns => 'mi\@email\.com',
            name => 'mi\@email\.com',
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

done_testing;

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Message->new( application => '' );
}

sub _build_c {
    mock_catalyst_c( username => 'root', @_ );
}

sub _setup {
    Baseliner::Core::Registry->clear();

    TestUtils->setup_registry(
        'Baseliner::Controller::CI',
        'Baseliner::Model::Jobs',
        'Baseliner::Model::Topic'
    );

    TestUtils->cleanup_cis();

    TestUtils->register_ci_events();

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;
    mdb->role->drop;
}
