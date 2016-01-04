use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils qw(:catalyst);

use JSON ();

use_ok 'BaselinerX::LcController';

subtest 'favorite_add: sets correct params to stash' => sub {
    _setup();

    my $user_ci = TestUtils->create_ci('user');

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                text => 'Some Title',
                icon => '/path/to/icon.png',
                data => JSON::encode_json(
                    {
                        title => 'foo'
                    }
                ),
                menu => JSON::encode_json( {} ),
            }
        },
        stash => $stash
    );

    $controller->favorite_add($c);

    is_deeply $c->stash, { json => { success => \1, msg => 'Favorite added ok', id_folder => undef } };
};

subtest 'favorite_add: sets correct params to stash with id_folder' => sub {
    _setup();

    my $user_ci = TestUtils->create_ci('user');

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                id_folder => '123',
                text      => 'Some Title',
                icon      => '/path/to/icon.png',
                data      => JSON::encode_json(
                    {
                        title => 'foo'
                    }
                ),
                menu => JSON::encode_json( {} ),
            }
        },
        stash => $stash
    );

    $controller->favorite_add($c);

    cmp_deeply $c->stash, { json => { success => \1, msg => 'Favorite added ok', id_folder => re(qr/^\d+-\d+$/) } };
};

subtest 'favorite_add: saves favorites to user' => sub {
    _setup();

    my $user_ci = TestUtils->create_ci('user');

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                text => 'Some Title',
                icon => '/path/to/icon.png',
                data => JSON::encode_json(
                    {
                        title => 'foo'
                    }
                ),
                menu => JSON::encode_json( {} ),
            }
        },
        stash => $stash
    );

    $controller->favorite_add($c);

    $user_ci = ci->new( $user_ci->mid );

    my ($id) = keys %{ $user_ci->favorites };

    cmp_deeply $user_ci->favorites,
      {
        $id => {
            'icon'        => re(qr/\.png$/),
            'text'        => 'Some Title',
            'menu'        => {},
            'id_favorite' => $id,
            'data'        => {
                'title' => 'foo'
            }
        }
      };
};

subtest 'favorite_add: saves favorites to user when folder' => sub {
    _setup();

    my $user_ci = TestUtils->create_ci('user');

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                id_folder => '123',
                text      => 'Some Title',
                icon      => '/path/to/icon.png',
                data      => JSON::encode_json(
                    {
                        title => 'foo'
                    }
                ),
                menu => JSON::encode_json( {} ),
            }
        },
        stash => $stash
    );

    $controller->favorite_add($c);

    my ($id) = $c->stash->{json}->{id_folder};

    $user_ci = ci->new( $user_ci->mid );

    cmp_deeply $user_ci->favorites,
      {
        $id => {
            'icon'        => re(qr/\.png$/),
            'id_folder'   => $id,
            'text'        => 'Some Title',
            'url'         => "/lifecycle/tree_favorite_folder?id_folder=$id",
            'menu'        => {},
            'id_favorite' => $id,
            'data'        => {
                'title' => 'foo'
            }
        }
      };
};

subtest 'favorite_add_to_folder: sets correct params to stash' => sub {
    _setup();

    my $user_ci = TestUtils->create_ci('user');

    $user_ci->favorites->{123} = {};
    $user_ci->favorites->{345} = {};
    $user_ci->save;

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                id_favorite     => '123',
                favorite_folder => 'My Folder',
                id_folder       => '345',
            }
        },
        stash => $stash
    );

    $controller->favorite_add_to_folder($c);

    is_deeply $c->stash, { json => { success => \1, msg => 'Favorite moved ok' } };
};

subtest 'favorite_add_to_folder: updates user favorites' => sub {
    _setup();

    my $user_ci = TestUtils->create_ci('user');

    $user_ci->favorites->{123} = {};
    $user_ci->favorites->{345} = {};
    $user_ci->save;

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                id_favorite     => '123',
                favorite_folder => 'My Folder',
                id_folder       => '345',
            }
        },
        stash => $stash
    );

    $controller->favorite_add_to_folder($c);

    $user_ci = ci->new( $user_ci->mid );

    is_deeply $user_ci->favorites,
      {
        '345' => {
            'favorite_folder' => '345',
            'contents'        => {
                '123' => {}
            }
        }
      };
};

done_testing;

sub _build_controller {
    BaselinerX::LcController->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::Events' );

    TestUtils->cleanup_cis;
}
