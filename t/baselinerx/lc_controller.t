use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils qw(:catalyst);
use TestSetup;
use Test::TempDir::Tiny;

use JSON ();

use_ok 'BaselinerX::LcController';

subtest 'favorite_add: sets correct params to stash' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();
    my $stash      = {};

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                text => 'Some Title',
                icon => '/path/to/icon.svg',
                data => JSON::encode_json( { title => 'foo' } ),
                menu => JSON::encode_json( {} ),
            }
        },
        stash => $stash
    );

    $controller->favorite_add($c);

    my ($id) = keys %{ $user_ci->favorites };

    is_deeply $c->stash,
        { json => { success => \1, msg => 'Favorite added ok', id_folder => '', id_favorite => $id, position => '0' } };
};

subtest 'favorite_add: saves favorites to user' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                is_folder => 1,
                text      => 'Some Title',
                icon      => '/path/to/icon.svg',
                data      => JSON::encode_json( { title => 'foo' } ),
                menu => JSON::encode_json( {} ),
            }
        }
    );

    $controller->favorite_add($c);

    $user_ci = ci->new( $user_ci->mid );
    my ($id) = keys %{ $user_ci->favorites };

    cmp_deeply $user_ci->favorites,
        {
        $id => {
            'id_favorite' => $id,
            'id_folder'   => $id,
            'menu'        => {},
            'text'        => 'Some Title',
            'data'        => { 'title' => 'foo' },
            'icon'        => ignore(),
            'position'    => 0,
            'url'         => '/lifecycle/tree_favorites?id_folder=' . $id
        }
        };
};

subtest 'favorite_add: saves favorites to user when folder' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                text      => 'Some Title',
                icon      => '',
                is_folder => 1,
                data      => JSON::encode_json( { title => 'foo' } ),
                menu => JSON::encode_json( {} ),
            }
        }
    );

    $controller->favorite_add($c);

    my ($id) = $c->stash->{json}->{id_folder};
    $user_ci = ci->new( $user_ci->mid );

    cmp_deeply $user_ci->favorites,
        {
        $id => {
            'icon'        => ignore(),
            'id_folder'   => $id,
            'text'        => 'Some Title',
            'url'         => "/lifecycle/tree_favorites?id_folder=$id",
            'menu'        => {},
            'id_favorite' => $id,
            'position'    => '0',
            'data'        => { 'title' => 'foo' }
        }
        };
};

subtest 'favorite_del: removes item from favorites' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->save;

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => { params => { id_favorite => 123 } }
    );

    $controller->favorite_del($c);

    is_deeply $c->stash, { json => { success => \1, msg => 'Favorite removed ok' } };
};

subtest 'favorite_rename: change the name of favorite item' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->save;

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => { params => { id_favorite => 123, text => 'new text' } }
    );

    $controller->favorite_rename($c);

    is_deeply $c->stash, { json => { success => \1, msg => 'Favorite renamed ok' } };
};

subtest 'favorite_rename: rename item from favorites' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();
    my $stash      = {};

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->save;

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => { params => { id => 123, text => 'rename test 1' } },
        stash    => $stash
    );

    $controller->favorite_rename($c);

    is_deeply $c->stash, { json => { success => \1, msg => 'Favorite renamed ok' } };
};

subtest 'favorite_add_to_folder: moves item on favorite tree' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        position    => '0',
        text        => 'test 1'
    };

    $user_ci->favorites->{321} = {
        id_favorite => '321',
        id_folder   => '321',
        position    => '1',
        text        => 'test 2'
    };

    $user_ci->save;

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => {
            params => {
                id_favorite => '321',
                id_parent   => '123',
                action      => 'append',
            }
        }
    );

    $controller->favorite_add_to_folder($c);

    is_deeply $c->stash, { json => { success => \1, msg => 'Favorite moved ok' } };
};

subtest 'tree_favorites: returns the favorite items' => sub {
    _setup();

    my $user_ci    = TestUtils->create_ci('user');
    my $controller = _build_controller();
    my $stash      = {};

    $user_ci->favorites->{123} = {
        id_favorite => '123',
        id_folder   => '123',
        position    => '0',
        text        => 'test 1'
    };
    $user_ci->save;

    my $c = mock_catalyst_c(
        username => 'foo',
        user_ci  => $user_ci,
        req      => { params => { id_favorite => 123 } },
        stash    => $stash
    );

    $controller->tree_favorites($c);

    cmp_deeply $c->stash->{json},

        [
        {   id_favorite => '123',
            id_folder   => '123',
            position    => '0',
            text        => 'test 1',
            leaf        => \1
        }
        ];
};

subtest 'tree_project_releases: build releases tree' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "name_field"   => "Status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                        "name_field"   => "status",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ]
    );

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category(
        name       => 'Release',
        id_rule    => $id_rule,
        id_status  => [ $status_new->mid, $status_finished->mid ],
        is_release => '1'
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_new
    );

    my $controller = _build_controller();

    my $stash = {};

    my $c = mock_catalyst_c(
        username => $user->username,
        req      => {
            params => {
                id_project => $project->mid
            }
        },
        stash => $stash
    );

    $controller->tree_project_releases($c);

    cmp_deeply $c->stash,
      {
        'json' => [
            {
                'icon' => '/static/images/icons/release.svg',
                'text' => 'New Topic',
                'menu' => [
                    {
                        'icon' => '/static/images/icons/topic.svg',
                        'text' => 'Related',
                        'eval' => {
                            'handler' => 'Baseliner.open_topic_grid_from_release'
                        }
                    },
                    {
                        'icon' => '/static/images/icons/topic.svg',
                        'text' => 'Apply filter',
                        'eval' => {
                            'handler' => 'Baseliner.open_apply_filter_from_release'
                        }
                    }
                ],
                'url'  => '/lifecycle/topic_contents',
                'data' => {
                    'click' => {
                        'icon'  => '/static/images/icons/topic.svg',
                        'url'   => re(qr{/topic/view\?topic_mid=$topic_mid}),
                        'title' => "Release #$topic_mid",
                        'type'  => 'comp'
                    },
                    'topic_mid' => $topic_mid,
                    'on_drop'   => {
                        'url' => '/comp/topic/topic_drop.js'
                    }
                },
                'topic_name' => {
                    'mid'             => $topic_mid,
                    'is_release'      => 1,
                    'category_status' => '<b>(New)</b>',
                    'category_name'   => 'Release',
                    'category_color'  => undef
                }
            }
        ]
      };

};

subtest 'status_list: no statuses when no promotion' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "name_field"   => "Status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                        "name_field"   => "status",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ]
    );

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name       => 'Changeset',
        id_rule    => $id_rule,
        id_status  => [ $status_new->mid, $status_finished->mid ],
        is_release => '1',
        workflow   => [
            {
                id_role        => $id_role,
                id_status_from => $status_new->mid,
                id_status_to   => $status_in_progress->mid,
                job_type       => undef
            },
            {
                id_role        => $id_role,
                id_status_from => $status_in_progress->mid,
                id_status_to   => $status_finished->mid,
                job_type       => 'promote'
            }
        ]
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_new
    );

    my $controller = _build_controller();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $controller->status_list( dir => 'promote', topic => $topic, username => 'developer' );

    is_deeply \@statuses, [];
};

subtest 'status_list: returns correct statuses when user has only one role' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "name_field"   => "Status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                        "name_field"   => "status",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ]
    );

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F' );
    my $status_closed      = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $id_role2 = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name       => 'Changeset',
        id_rule    => $id_rule,
        id_status  => [ $status_new->mid, $status_finished->mid ],
        is_release => '1',
        workflow   => [
            {
                id_role        => $id_role,
                id_status_from => $status_new->mid,
                id_status_to   => $status_in_progress->mid,
                job_type       => undef
            },
            {
                id_role        => $id_role,
                id_status_from => $status_in_progress->mid,
                id_status_to   => $status_finished->mid,
                job_type       => 'promote'
            },
            {
                id_role        => $id_role2,
                id_status_from => $status_finished->mid,
                id_status_to   => $status_closed->mid,
                job_type       => 'promote'
            }
        ]
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_in_progress
    );

    my $controller = _build_controller();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $controller->status_list( dir => 'promote', topic => $topic, username => 'developer' );

    is @statuses, 1;
    is $statuses[0]->{mid}, $status_finished->mid;
};


subtest 'status_list: returns correct statuses when user has more than one role' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "name_field"   => "Status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                        "name_field"   => "status",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ]
    );

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F' );
    my $status_closed      = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $id_role2 = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $username = 'developer';
    my $user = TestUtils->create_ci(
        'user',
        name             => $username,
        username         => $username,
        password         => ci->user->encrypt_password($username, 'password'),
        project_security => {
            $id_role => {
                project => [ map { $_->mid } ( ref $project eq 'ARRAY' ? @$project : ($project) ) ]
            },
            $id_role2 => {
                project => [ map { $_->mid } ( ref $project2 eq 'ARRAY' ? @$project2 : ($project2) ) ]
            }
        }
    );

    my $id_category = TestSetup->create_category(
        name       => 'Changeset',
        id_rule    => $id_rule,
        id_status  => [ $status_new->mid, $status_finished->mid ],
        is_release => '1',
        workflow   => [
            {
                id_role        => $id_role,
                id_status_from => $status_new->mid,
                id_status_to   => $status_in_progress->mid,
                job_type       => undef
            },
            {
                id_role        => $id_role,
                id_status_from => $status_in_progress->mid,
                id_status_to   => $status_finished->mid,
                job_type       => 'promote'
            },
            {
                id_role        => $id_role2,
                id_status_from => $status_in_progress->mid,
                id_status_to   => $status_closed->mid,
                job_type       => 'promote'
            },
            {
                id_role        => $id_role2,
                id_status_from => $status_finished->mid,
                id_status_to   => $status_closed->mid,
                job_type       => 'promote'
            },
        ]
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_in_progress
    );

    my $controller = _build_controller();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $controller->status_list( dir => 'promote', topic => $topic, username => 'developer' );

    is @statuses, 1;
    is $statuses[0]->{mid}, $status_finished->mid;
};

subtest 'status_list: use statuses passed' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "name_field"   => "Status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                        "name_field"   => "status",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ]
    );

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F' );
    my $status_closed      = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $id_role2 = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            }
        ]
    );
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name       => 'Changeset',
        id_rule    => $id_rule,
        id_status  => [ $status_new->mid, $status_finished->mid ],
        is_release => '1',
        workflow   => [
            {
                id_role        => $id_role,
                id_status_from => $status_new->mid,
                id_status_to   => $status_in_progress->mid,
                job_type       => undef
            },
            {
                id_role        => $id_role,
                id_status_from => $status_in_progress->mid,
                id_status_to   => $status_finished->mid,
                job_type       => 'promote'
            },
            {
                id_role        => $id_role2,
                id_status_from => $status_finished->mid,
                id_status_to   => $status_closed->mid,
                job_type       => 'promote'
            }
        ]
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
    );

    my $controller = _build_controller();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $controller->status_list(
        dir      => 'promote',
        topic    => $topic,
        username => 'developer',
        status   => $status_in_progress->mid,
        statuses => {
            $status_in_progress->mid => {%$status_in_progress},
            $status_finished->mid    => {%$status_finished},
        }
    );

    is @statuses, 1;
    is $statuses[0]->{mid}, $status_finished->mid;
};

subtest 'tree_topic_get_files: creates click in data json ' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();
    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };
    my $tempdir = tempdir();

    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );
    my $file = Util->_file("$tempdir/filename.jpg");

    Baseliner::Model::Topic->new->upload( f => $file, p => $params, username => 'root' );

    my $controller = _build_controller();
    my $c          = mock_catalyst_c(
        req => {
            params => {
                id_topic     => $topic_mid,
                sw_get_files => 'true'
            }
        }
    );
    $controller->tree_topic_get_files($c);

    is $c->stash->{json}[0]{data}{click}{type},  'download';
    is $c->stash->{json}[0]{data}{click}{title}, 'filename.jpg' . '(v1)';

};

subtest 'build_topic_tree: creates children if topic has files' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $params = { filter => 'test_file', qqfile => 'filename.jpg', topic_mid => "$topic_mid" };
    my $tempdir = tempdir();

    TestUtils->write_file( 'content', "$tempdir/filename.jpg" );
    my $file = Util->_file("$tempdir/filename.jpg");

    Baseliner::Model::Topic->new->upload( f => $file, p => $params, username => 'root' );

    my $controller = _build_controller();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );
    my @output = $controller->build_topic_tree( mid => $topic_mid, topic => $topic );

    ok $output[0]{children};
};

subtest 'build_topic_tree: does not create children if topic has not files' => sub {
    _setup();

    my $project   = TestUtils->create_ci_project;
    my $id_role   = TestSetup->create_role();
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( username => $user->username );

    my $controller = _build_controller();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );
    my @output = $controller->build_topic_tree( mid => $topic_mid, topic => $topic );

    ok !$output[0]{children};
};

done_testing;

sub _build_controller {
    BaselinerX::LcController->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Events',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Registor',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Controller::Topic',
    );

    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->topic->drop;
    mdb->event->drop;
    mdb->rule->drop;
    mdb->role->drop;
}
