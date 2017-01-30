use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestSetup;

use_ok 'Baseliner::Model::PromotesAndDemotes';

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

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I', seq => 1, );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G', seq => 2, );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F', seq => 3, );

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

    my $model = _build_model();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $model->status_list( dir => 'promote', topic => $topic, username => 'developer' );

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

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I', seq => 1 );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G', seq => 2 );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F', seq => 3 );
    my $status_closed      = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F', seq => 4 );

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

    my $model = _build_model();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $model->status_list( dir => 'promote', topic => $topic, username => 'developer' );

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

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I', seq => 1 );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G', seq => 2 );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F', seq => 3 );
    my $status_closed      = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F', seq => 4 );

    my $project  = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role  = TestSetup->create_role(
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
    my $user     = TestUtils->create_ci(
        'user',
        name             => $username,
        username         => $username,
        password         => ci->user->encrypt_password( $username, 'password' ),
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

    my $model = _build_model();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $model->status_list( dir => 'promote', topic => $topic, username => 'developer' );

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

    my $status_new         = TestUtils->create_ci( 'status', name => 'New',         type => 'I', seq => 1 );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G', seq => 2 );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished',    type => 'F', seq => 3 );
    my $status_closed      = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F', seq => 4 );

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

    my $model = _build_model();

    my $topic = mdb->topic->find_one( { mid => $topic_mid } );

    my @statuses = $model->status_list(
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

subtest 'promotes_and_demotes: builds correct variants for changeset' => sub {
    _setup();

    my $bl_common = TestUtils->create_ci( 'bl', bl => '*',    seq => 1 );
    my $bl_qa     = TestUtils->create_ci( 'bl', bl => 'QA',   seq => 2 );
    my $bl_prod   = TestUtils->create_ci( 'bl', bl => 'PROD', seq => 3 );

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status_new = TestUtils->create_ci(
        'status',
        name => 'New',
        type => 'D',
        bls  => [ $bl_common->mid, $bl_qa->mid, $bl_prod->mid ],
        seq  => 1
    );
    my $status_in_progress =
      TestUtils->create_ci( 'status', name => 'In Progress', type => 'D', bls => [ $bl_qa->mid ], seq => 2 );
    my $status_finished =
      TestUtils->create_ci( 'status', name => 'Finished', type => 'D', bls => [ $bl_prod->mid ], seq => 3 );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => undef
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => 'static'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_finished->id_status,
            job_type       => 'promote'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_new->id_status,
            job_type       => 'demote'
        }
    ];

    my $id_category = TestSetup->create_category(
        statuses => [ $status_new->id_status, $status_in_progress->id_status, $status_finished->id_status ],
        workflow => $workflow
    );

    my $topic_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_in_progress,
        username    => $user->username
    );

    my $topic_doc = mdb->topic->find_one( { mid => $topic_mid } );

    my $model = _build_model();

    my ( $statics, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = $model->promotes_and_demotes_menu(
        username   => $user->username,
        topic      => $topic_doc,
        id_project => $project->mid
    );

    cmp_deeply $statics,    { "sQA" . $status_in_progress->id_status => \1 };
    cmp_deeply $promotable, { "pPROD" . $status_finished->id_status  => \1 };
    cmp_deeply $demotable,  { 'dQA' . $status_new->id_status         => \1 };
    cmp_deeply $menu_s,
      [
        {
            text => 'Deploy to In Progress (QA)',
            icon => ignore(),
            eval => {
                id_project => $project->mid,
                job_type   => 'static',
                id         => 'sQA' . $status_in_progress->id_status,
                url        => ignore(),
            },
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_in_progress->id_status,
            bl_to          => 'QA'
        }
      ];
    cmp_deeply $menu_p,
      [
        {
            text => 'Promote to Finished (PROD)',
            icon => ignore(),
            eval => {
                id_project => $project->mid,
                job_type   => 'promote',
                id         => 'pPROD' . $status_finished->id_status,
                url        => ignore(),
            },
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_finished->id_status,
            bl_to          => 'PROD'
        }
      ];
    cmp_deeply $menu_d,
      [
        {
            text => 'Demote to New (from QA)',
            icon => ignore(),
            eval => {
                id_project => $project->mid,
                job_type   => 'demote',
                id         => 'dQA' . $status_new->id_status,
                url        => ignore(),
            },
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_new->id_status,
            bl_to          => '*'
        }
      ];
};

subtest 'promotes_and_demotes: returns correct variants for changeset' => sub {
    _setup();

    my $bl_common = TestUtils->create_ci( 'bl', bl => '*',    seq => 1 );
    my $bl_qa     = TestUtils->create_ci( 'bl', bl => 'QA',   seq => 2 );
    my $bl_prod   = TestUtils->create_ci( 'bl', bl => 'PROD', seq => 3 );

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status_new = TestUtils->create_ci( 'status', name => 'New', type => 'D', bls => [ $bl_common->mid ], seq => 1 );
    my $status_in_progress =
      TestUtils->create_ci( 'status', name => 'In Progress', type => 'D', bls => [ $bl_qa->mid ], seq => 2 );
    my $status_finished =
      TestUtils->create_ci( 'status', name => 'Finished', type => 'D', bls => [ $bl_prod->mid ], seq => 3 );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => undef
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => 'static'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_finished->id_status,
            job_type       => 'promote'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_new->id_status,
            job_type       => 'demote'
        }
    ];

    my $id_category = TestSetup->create_category(
        statuses => [ $status_new->id_status, $status_in_progress->id_status, $status_finished->id_status ],
        workflow => $workflow
    );

    my $topic_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_in_progress,
        username    => $user->username
    );

    my $topic_doc = mdb->topic->find_one( { mid => $topic_mid } );

    my $model = _build_model();

    my @job_transitions = $model->promotes_and_demotes(
        username   => $user->username,
        topic      => $topic_doc,
        id_project => $project->mid,
        job_mode   => 1
    );

    cmp_deeply \@job_transitions,
      [
        {
            'is_release'     => undef,
            'job_bl'         => 'QA',
            'job_type'       => 'static',
            'bl_to'          => 'QA',
            'bl_to_seq'      => ignore(),
            'id'             => 'sQA' . $status_in_progress->id_status,
            'text'           => 'Deploy to In Progress (QA)',
            'id_project'     => $project->mid,
            'status_to'      => $status_in_progress->id_status,
            'status_to_seq'  => ignore(),
            'status_to_name' => 'In Progress',
            'id_status_from' => $status_in_progress->id_status
        },
        {
            'is_release'     => undef,
            'job_bl'         => 'PROD',
            'bl_to'          => 'PROD',
            'bl_to_seq'      => ignore(),
            'job_type'       => 'promote',
            'status_to'      => $status_finished->id_status,
            'status_to_seq'  => ignore(),
            'id_project'     => $project->mid,
            'status_to_name' => 'Finished',
            'text'           => 'Promote to Finished (PROD)',
            'id'             => 'pPROD' . $status_finished->id_status,
            'id_status_from' => $status_in_progress->id_status
        },
        {
            'job_bl'         => 'QA',
            'is_release'     => undef,
            'id'             => 'dQA' . $status_new->id_status,
            'text'           => 'Demote to New (from QA)',
            'id_project'     => $project->mid,
            'status_to'      => $status_new->id_status,
            'status_to_seq'  => ignore(),
            'status_to_name' => 'New',
            'job_type'       => 'demote',
            'bl_to'          => '*',
            'bl_to_seq'      => ignore(),
            'id_status_from' => $status_in_progress->id_status
        }
      ];
};

subtest 'promotes_and_demotes: orders transitions by corresponding sequences' => sub {
    _setup();

    my $bl_common = TestUtils->create_ci( 'bl', bl => '*',    seq => 1 );
    my $bl_prod   = TestUtils->create_ci( 'bl', bl => 'PROD', seq => 100 );
    my $bl_qa     = TestUtils->create_ci( 'bl', bl => 'QA',   seq => 1 );

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status_new = TestUtils->create_ci( 'status', name => 'New', type => 'I', bls => [ $bl_common->mid ], seq => 1 );
    my $status_finished = TestUtils->create_ci(
        'status',
        name => 'Finished',
        type => 'D',
        bls  => [ $bl_qa->mid, $bl_prod->mid ],
        seq  => 100
    );
    my $status_in_progress = TestUtils->create_ci(
        'status',
        name => 'In Progress',
        type => 'D',
        bls  => [ $bl_qa->mid, $bl_prod->mid ],
        seq  => 1
    );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => undef
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => 'static'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => 'promote'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_finished->id_status,
            job_type       => 'promote'
        }
    ];

    my $id_category = TestSetup->create_category(
        statuses => [ $status_new->id_status, $status_in_progress->id_status, $status_finished->id_status ],
        workflow => $workflow
    );

    my $topic_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_in_progress,
        username    => $user->username
    );

    my $topic_doc = mdb->topic->find_one( { mid => $topic_mid } );

    my $model = _build_model();

    my @transitions = $model->promotes_and_demotes(
        username   => $user->username,
        topic      => $topic_doc,
        id_project => $project->mid
    );

    is @transitions, 6;

    like $transitions[0]->{text}, qr/Deploy to In Progress.*QA/;
    like $transitions[1]->{text}, qr/Deploy to In Progress.*PROD/;
    like $transitions[2]->{text}, qr/Promote to In Progress.*QA/;
    like $transitions[3]->{text}, qr/Promote to In Progress.*PROD/;
    like $transitions[4]->{text}, qr/Promote to Finished.*QA/;
    like $transitions[5]->{text}, qr/Promote to Finished.*PROD/;
};

subtest 'promotes_and_demotes: builds correct variants for release' => sub {
    _setup();

    my $bl_common = TestUtils->create_ci( 'bl', bl => '*',    seq => 1 );
    my $bl_prod   = TestUtils->create_ci( 'bl', bl => 'PROD', seq => 100 );
    my $bl_qa     = TestUtils->create_ci( 'bl', bl => 'QA',   seq => 1 );

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status_new = TestUtils->create_ci( 'status', name => 'New', type => 'I', bls => [ $bl_common->mid ], seq => 1 );
    my $status_production = TestUtils->create_ci(
        'status',
        name => 'Production',
        type => 'D',
        bls  => [ $bl_qa->mid, $bl_prod->mid ],
        seq  => 200
    );
    my $status_finished =
      TestUtils->create_ci( 'status', name => 'Finished', type => 'D', bls => [ $bl_qa->mid ], seq => 100 );
    my $status_in_progress =
      TestUtils->create_ci( 'status', name => 'In Progress', type => 'D', bls => [ $bl_qa->mid ], seq => 1 );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => undef
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_in_progress->id_status,
            job_type       => 'static'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->id_status,
            id_status_to   => $status_finished->id_status,
            job_type       => 'promote'
        },
        {
            id_role        => $id_role,
            id_status_from => $status_finished->id_status,
            id_status_to   => $status_production->id_status,
            job_type       => 'promote'
        }
    ];

    my $id_changeset_rule = _create_release_form();
    my $id_category       = TestSetup->create_category(
        name         => 'Changeset',
        id_rule      => $id_changeset_rule,
        statuses     => [ $status_new->id_status, $status_in_progress->id_status, $status_finished->id_status ],
        is_changeset => '1',
        workflow     => $workflow
    );

    my $topic1_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_new,
        username    => $user->username
    );
    my $topic2_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_in_progress,
        username    => $user->username
    );
    my $topic22_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_in_progress,
        username    => $user->username
    );
    my $topic3_mid = TestSetup->create_topic(
        id_category => $id_category,
        status      => $status_finished,
        username    => $user->username
    );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name       => 'Release',
        id_rule    => $id_release_rule,
        id_status  => [ $status_new->mid, $status_in_progress->mid, $status_finished->mid ],
        is_release => '1',
    );

    my $release_topic_mid = TestSetup->create_topic(
        id_category => $id_release_category,
        status      => $status_in_progress,
        username    => $user->username,
        changesets  => [ $topic1_mid, $topic2_mid, $topic22_mid, $topic3_mid ]
    );

    my $release_topic_doc = mdb->topic->find_one( { mid => $release_topic_mid } );

    my $model = _build_model();

    my @transitions = $model->promotes_and_demotes(
        username   => $user->username,
        topic      => $release_topic_doc,
        id_project => $project->mid
    );

    is @transitions, 4;

    like $transitions[0]->{text}, qr/Deploy to In Progress.*QA/;
    like $transitions[1]->{text}, qr/Promote to Finished.*QA/;
    like $transitions[2]->{text}, qr/Promote to Production.*QA/;
    like $transitions[3]->{text}, qr/Promote to Production.*PROD/;
};

done_testing;

sub _create_changeset_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field"    => "release",
                        release_field => 'changesets'
                    },
                    key  => "fieldlet.system.release",
                    text => 'Release',
                }
            },
        ]
    );
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "changesets",
                    },
                    key  => "fieldlet.system.list_topics",
                    text => 'Changesets',
                }
            },
        ]
    );
}

sub _build_model {
    Baseliner::Model::PromotesAndDemotes->new();
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',             'BaselinerX::Type::Action',
        'BaselinerX::Type::Fieldlet', 'BaselinerX::Type::Event',
        'BaselinerX::Fieldlets',      'Baseliner::Model::Topic',
    );

    TestUtils->cleanup_cis;

    mdb->category->drop;
    mdb->topic->drop;
    mdb->rule->drop;
    mdb->role->drop;
}
