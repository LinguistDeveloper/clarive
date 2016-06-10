use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::Utils;
use TestSetup;
use Baseliner::Role::CI;
use BaselinerX::Type::Event;

use_ok 'Baseliner::Model::Favorites';

subtest 'add_favorite_item: adds new folder to favorites' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    my $model    = _build_model();
    my $favorite = $model->add_favorite_item(
        $user_ci,
        {   text      => "Folder",
            data      => _encode_json( { data => 'Some data' } ),
            is_folder => '1'
        }
    );

    cmp_deeply(
        $favorite,
        {   'url'         => ignore(),
            'text'        => 'Folder',
            'position'    => 0,
            'id_folder'   => ignore(),
            'id_favorite' => ignore(),
            'data'        => { 'data' => 'Some data' },
            'icon'        => ignore()
        }
    );
};

subtest 'add_favorite_item: adds new item that is not folder to favorites' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    my $model    = _build_model();
    my $favorite = $model->add_favorite_item(
        $user_ci,
        {   text => "randmo item",
            data => _encode_json( { data => 'Some data' } ),
            icon => 'image.svg'
        }
    );

    cmp_deeply(
        $favorite,
        {   'text'        => 'randmo item',
            'position'    => 0,
            'id_favorite' => ignore(),
            'data'        => { 'data' => 'Some data' },
            'icon'        => 'image.svg'
        }
    );
};

subtest 'get_children: returns the children with empty parent' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user_ci->favorites->{3456} = {
        id_favorite => '3456',
        id_folder   => '3456',
        id_parent   => '123',
        position    => '1',
        text        => 'test 1'
    };
    $user_ci->favorites->{1234} = {
        id_favorite => '1234',
        id_folder   => '1234',
        id_parent   => '123',
        position    => '2',
        text        => 'test 2'
    };
    $user_ci->save;

    my $model = _build_model();
    my $list_favorites = $model->get_children( $user_ci, '' );

    is scalar @$list_favorites[0]->{id_favorite}, '123';
    is scalar @$list_favorites[1]->{id_favorite}, '345';
    is scalar @$list_favorites, 2;
};

subtest 'get_children: returns the children with parent' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user_ci->favorites->{3456} = {
        id_favorite => '3456',
        id_folder   => '3456',
        id_parent   => '123',
        position    => '1',
        text        => 'test 1'
    };
    $user_ci->favorites->{1234} = {
        id_favorite => '1234',
        id_folder   => '1234',
        id_parent   => '123',
        position    => '2',
        text        => 'test 2'
    };
    $user_ci->save;

    my $model = _build_model();
    my $list_favorites = $model->get_children( $user_ci, '123' );

    is scalar @$list_favorites[0]->{id_favorite}, '3456';
    is scalar @$list_favorites[1]->{id_favorite}, '1234';
    is scalar @$list_favorites, 2;
};

subtest 'get_children_recursive: find children of parent' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user_ci->favorites->{3456} = {
        id_favorite => '3456',
        id_folder   => '3456',
        id_parent   => '123',
        position    => '1',
        text        => 'test 1'
    };
    $user_ci->favorites->{1234} = {
        id_favorite => '1234',
        id_folder   => '1234',
        id_parent   => '123',
        position    => '2',
        text        => 'test 2'
    };
    $user_ci->save;

    my $model = _build_model();
    my @node = $model->get_children_recursive( $user_ci, '123' );

    is scalar @node, '3';
};

subtest 'delete_nodes: deletes favorite folder ' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->save;

    my $model = _build_model();
    $model->delete_nodes( $user_ci, '123', '' );

    is_deeply $user_ci->favorites, {};
};

subtest 'rename_favorite: rename favorite folder' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->save;

    my $model = _build_model();
    $model->rename_favorite( $user_ci, '123', 'test new' );

    is $user_ci->favorites->{123}->{text}, 'test new';
};

subtest 'remove_position: updates position when node is deleted' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_parent   => '',
        position    => '0',
        text        => 'text A'
    };
    $user_ci->favorites->{234} = {
        id_favorite => '234',
        id_parent   => '',
        position    => '2',
        text        => 'text B'
    };
    $user_ci->save;

    my $model = _build_model();
    $model->remove_position( $user_ci, '1' );

    is $user_ci->favorites->{234}->{position}, '1';
};

subtest 'delete_nodes: deletes favorite folder and its children' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user_ci->favorites->{3456} = {
        id_favorite => '3456',
        id_folder   => '3456',
        id_parent   => '123',
        position    => '1',
        text        => 'test 1'
    };
    $user_ci->favorites->{1234} = {
        id_favorite => '1234',
        id_parent   => '123',
        position    => '2',
        text        => 'test 2'
    };
    $user_ci->save;

    my $model = _build_model();
    $model->delete_nodes( $user_ci, '123' );

    is $user_ci->favorites->{123}, undef;
};

subtest 'update_position: moves to favorite folder' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user_ci->save;

    my $id_favorite   = '123';
    my $id_parent     = '345';
    my $action        = 'append';
    my $nodes_ordered = '';

    my $model = _build_model();
    $model->update_position(
        $user_ci, $id_favorite,
        $id_parent,
        action        => $action,
        nodes_ordered => $nodes_ordered
    );

    $user_ci = ci->new( $user_ci->mid );

    is_deeply $user_ci->favorites,
        {
        '345' => {
            'id_favorite' => '345',
            'text'        => 'test 2',
            'id_folder'   => '345',
            'position'    => 0,
            'id_parent'   => ''
        },
        '123' => {
            'id_favorite' => '123',
            'id_folder'   => '123',
            'text'        => 'test 1',
            'position'    => 1,
            'id_parent'   => '345'
        }
        };
};

subtest 'update_position: moves to correct position favorite folder' => sub {
    _setup();

    my $user = TestSetup->create_user();
    $user->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user->save;

    my $id_favorite   = '345';
    my $id_parent     = '';
    my $nodes_ordered = [ { id_favorite => '123', position => '1' }, { id_favorite => '345', position => '0' } ];

    my $model = _build_model();
    $model->update_position( $user, $id_favorite, $id_parent, nodes_ordered => $nodes_ordered );

    $user = ci->new( $user->mid );

    is_deeply $user->favorites,
        {
        '345' => {
            'id_favorite' => '345',
            'text'        => 'test 2',
            'id_folder'   => '345',
            'position'    => 0,
            'id_parent'   => ''
        },
        '123' => {
            'id_favorite' => '123',
            'id_folder'   => '123',
            'text'        => 'test 1',
            'position'    => 1,
            'id_parent'   => ''
        }
        };
};

subtest 'update_position: moves to favorite folder with another parent' => sub {
    _setup();

    my $user_ci = TestSetup->create_user();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        id_parent   => '',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->favorites->{345} = {
        id_favorite => '345',
        id_folder   => '345',
        id_parent   => '',
        position    => '1',
        text        => 'test 2'
    };
    $user_ci->favorites->{3456} = {
        id_favorite => '3456',
        id_folder   => '3456',
        id_parent   => '123',
        position    => '1',
        text        => 'test 1'
    };
    $user_ci->favorites->{1234} = {
        id_favorite => '1234',
        id_folder   => '1234',
        id_parent   => '123',
        position    => '2',
        text        => 'test 2'
    };
    $user_ci->save;

    my $id_favorite   = '345';
    my $id_parent     = '123';
    my $nodes_ordered = [
        { id_favorite => '3456', position => '0' },
        { id_favorite => '1234', position => '1' },
        { id_favorite => '345',  position => '2' }
    ];

    my $model = _build_model();
    $model->update_position( $user_ci, $id_favorite, $id_parent, nodes_ordered => $nodes_ordered );
    $user_ci = ci->new( $user_ci->mid );

    is_deeply $user_ci->favorites,
        {
        '3456' => {
            'id_folder'   => '3456',
            'text'        => 'test 1',
            'position'    => 0,
            'id_favorite' => '3456',
            'id_parent'   => '123'
        },
        '345' => {
            'id_folder'   => '345',
            'position'    => 2,
            'id_favorite' => '345',
            'text'        => 'test 2',
            'id_parent'   => '123'
        },
        '123' => {
            'text'        => 'test 1',
            'position'    => '0',
            'id_favorite' => '123',
            'id_parent'   => '',
            'id_folder'   => '123'
        },
        '1234' => {
            'id_folder'   => '1234',
            'text'        => 'test 2',
            'position'    => 1,
            'id_favorite' => '1234',
            'id_parent'   => '123'
        }
        };
};

done_testing();

sub _build_model {
    return Baseliner::Model::Favorites->new;
}

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    TestUtils->cleanup_cis;
}
