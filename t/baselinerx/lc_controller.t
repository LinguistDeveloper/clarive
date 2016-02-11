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
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.release.view',
            }
        ]
    );
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name       => 'Release',
        id_rule    => $id_rule,
        id_status  => [ $status_new->mid, $status_finished->mid ],
        is_release => '1'
    );

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
                'icon' => '/static/images/icons/release.png',
                'text' => 'New Topic',
                'menu' => [
                    {
                        'icon' => '/static/images/icons/topic.png',
                        'text' => 'Related',
                        'eval' => {
                            'handler' => 'Baseliner.open_topic_grid_from_release'
                        }
                    },
                    {
                        'icon' => '/static/images/icons/topic.png',
                        'text' => 'Apply filter',
                        'eval' => {
                            'handler' => 'Baseliner.open_apply_filter_from_release'
                        }
                    }
                ],
                'url'  => '/lifecycle/topic_contents',
                'data' => {
                    'click' => {
                        'icon'  => '/static/images/icons/topic.png',
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

subtest 'status_list: returns correct statuses' => sub {
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

done_testing;

sub _build_controller {
    BaselinerX::LcController->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::CI',
        'BaselinerX::Events',      'BaselinerX::Type::Fieldlet',
        'Baseliner::Model::Topic', 'BaselinerX::Fieldlets'
    );

    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->topic->drop;
    mdb->event->drop;
    mdb->rule->drop;
    mdb->role->drop;
}
