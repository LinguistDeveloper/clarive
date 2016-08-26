use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils ':catalyst', 'mock_time';

use Capture::Tiny qw(capture);

use_ok 'Baseliner::Controller::Job';

subtest 'monitor_json: returns empty data' => sub {
    _setup();

    my $c = mock_catalyst_c( username => 'developer' );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is_deeply $c->stash,
        {
        'json' => {
            'totalCount' => 0,
            'data'       => []
        }
        };
};

subtest 'monitor_json: returns jobs data' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
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

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project_doc = ci->project->find_one;
    my $project     = ci->new( $project_doc->{mid} );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );
    my $changeset = mdb->topic->find_one( { mid => $changeset_mid } );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD',
            bl_to        => 'PROD'
        );
    };

    $job_ci = ci->project->find_one( { 'projects' => { '$in' => [ $project->mid ] } } );

    my $c = mock_catalyst_c( username => 'developer', req => { params => { query_id => '-1' } } );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'monitor_json: returns the jobs filtered by bl' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
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

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project_doc = ci->project->find_one;
    my $project     = ci->new( $project_doc->{mid} );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD'

        );
    };

    my $other_job_ci;
    capture {
        $other_job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'QA'

        );
    };

    my $c = mock_catalyst_c( username => 'developer', req => { params => { query_id => '-1', filter_bl => 'PROD' } } );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'monitor_json: returns the jobs filtered by status' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
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

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project_doc = ci->project->find_one;
    my $project     = ci->new( $project_doc->{mid} );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD'

        );
    };

    my $other_job_ci;
    capture {
        $other_job_ci = TestUtils->create_ci(
            'job',
            final_status => 'SUSPENDED',
            changesets   => [$changeset_mid],
            bl           => 'PROD'

        );
    };

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => { params => { query_id => '-1', job_state_filter => '{"FINISHED":1}' } }
    );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'monitor_json: returns the jobs filtered by type' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
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

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project_doc = ci->project->find_one;
    my $project     = ci->new( $project_doc->{mid} );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD',
            job_type     => 'demote'

        );
    };

    my $other_job_ci;
    capture {
        $other_job_ci = TestUtils->create_ci(
            'job',
            final_status => 'SUSPENDED',
            changesets   => [$changeset_mid],
            bl           => 'PROD',
            job_type     => 'promote'

        );
    };

    my $c = mock_catalyst_c( username => 'developer',
        req => { params => { query_id => '-1', filter_type => 'demote' } } );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'monitor_json: returns the jobs filtered by nature' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
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

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project_doc = ci->project->find_one;
    my $project     = ci->new( $project_doc->{mid} );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $nature       = TestUtils->create_ci( 'nature', name => 'JAR' );
    my $other_nature = TestUtils->create_ci( 'nature', name => 'FOO' );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD',
            natures      => [ $nature->mid ]

        );
    };

    my $other_job_ci;
    capture {
        $other_job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD',
            natures      => [ $other_nature->mid ]

        );
    };

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => { params => { query_id => '-1', filter_nature => $nature->mid } }
    );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'monitor_json: returns the jobs filtered by project' => sub {
    _setup();

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
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
            {   "attributes" => {
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

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => 'PROD'
            },
        ]
    );
    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );
    my $other_project       = TestUtils->create_ci('project');
    my $other_changeset_mid = TestSetup->create_topic(
        id_category  => $id_changeset_category,
        project      => $other_project,
        is_changeset => 1
    );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD'
        );
    };
    my $other_job_ci;
    capture {
        $other_job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$other_changeset_mid],
            bl           => 'PROD'
        );
    };

    my $project_mid = $project->{mid};
    my $c           = mock_catalyst_c(
        username => 'user',
        req      => { params => { query_id => '-1', filter_project => $project_mid } }
    );

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
    is $c->stash->{json}->{data}[0]->{mid}, $job_ci->mid;
};

subtest 'pipeline_versions: returns versions data' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule;

    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-01 10:00:00', version_tag => 'one', username => 'foo'} );
    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-01 11:00:00', version_tag => 'two', username => 'bar'} );
    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-02 11:00:00', version_tag => 'three', username => 'baz'} );
    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-02 11:00:00', username => 'ignore me'} );

    my $c = mock_catalyst_c(username => 'developer', req => {params => {id_rule => $id_rule}});

    my $controller = _build_controller();

    $controller->pipeline_versions($c);

    cmp_deeply $c->stash, {
        json => {
            success => \1,
            data => [
                {
                    id => '',
                    label => 'Latest',
                },
                {
                    id => 'three',
                    label => 'three (baz)',
                },
                {
                    id => 'two',
                    label => 'two (bar)',
                },
                {
                    id => 'one',
                    label => 'one (foo)',
                },
            ],
            totalCount => 4,
        }
    };
};

subtest 'submit: returns an error when user does not have permission to create new job out of window' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        role => 'Role no window',
        actions => [
            {
                action => 'action.job.viewall',
                bl => 'PROD'
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'user' );
    my $id_rule = TestSetup->create_rule;

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
    );

    my $changeset_mid = TestSetup->create_topic(
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
    );

    my $c = mock_catalyst_c(
        username => $user->username,
        req      => { params => { id_rule => $id_rule, changesets => $changeset_mid, check_no_cal => 'on' } }
    );

    my $controller = _build_controller();

    capture {
        $controller->submit($c);
    };

    cmp_deeply $c->stash,
      {
        'json' => {
            success => \0,
            msg => re(qr/Error creating job: User user doesn't have permissions to create a job out of calendar/)
        }
      };
};

subtest 'submit: creates a new job' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule;

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
    );

    my $changeset_mid = TestSetup->create_topic(
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
    );

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => { params => { id_rule => $id_rule, changesets => $changeset_mid, window_type => 'N' } }
    );

    my $controller = _build_controller();

    capture {
        $controller->submit($c);
    };

    my ($job_name) = $c->stash->{json}->{msg} =~ m/Job (.*?) created/;
    my $job = ci->job->find_one({name => $job_name});

    ok $job;

    cmp_deeply $c->stash,
      {
        'json' => {
            success => \1,
            msg => re(qr/Job .*? created/)
        }
      };
};

subtest 'submit: deletes job_log when ci job is deleted' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    my $id_rule = TestSetup->create_rule(rule_type => "pipeline",rule_when => "promote");

    my $job;

    capture {
        $job = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets => [$changeset]
        );
    };

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => { params => { action => 'delete', mid => $job->{mid}, mode => 'delete' } }
    );

    my $job_log = mdb->job_log->find_one( { mid => $job->{mid} } );

    my $controller = _build_controller();

    $controller->submit($c);

    my $count_doc_log = mdb->master_doc->count({ collection => 'job',mid => $job->{mid}});;
    my $data_grid = mdb->grid->find_one({_id => $job_log->{data}});

    ok !defined $data_grid;
    is $count_doc_log, 0;
};

subtest 'submit: creates a new job with rule version tag' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule;

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'anotheruser',
    );
    my @versions = Baseliner::Model::Rules->new->list_versions($id_rule);
    Baseliner::Model::Rules->new->tag_version(version_id => $versions[0]->{_id}, version_tag => 'tag');

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
    );

    my $changeset_mid = TestSetup->create_topic(
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
    );

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => {
            params =>
              { id_rule => $id_rule, changesets => $changeset_mid, window_type => 'N', rule_version_tag => 'tag' }
        }
    );

    my $controller = _build_controller();

    capture {
        $controller->submit($c);
    };

    my ($job_name) = $c->stash->{json}->{msg} =~ m/Job (.*?) created/;
    my $job = ci->job->find_one({name => $job_name});

    is $job->{rule_version_id}, '' . $versions[0]->{_id};
    is $job->{rule_version_tag}, 'tag';
};

subtest 'submit: creates a new job without version id when dynamic' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule;

    Baseliner::Model::Rules->new->write_rule(
        id_rule  => $id_rule,
        username => 'anotheruser',
    );
    my @versions = Baseliner::Model::Rules->new->list_versions($id_rule);
    Baseliner::Model::Rules->new->tag_version(version_id => $versions[0]->{_id}, version_tag => 'tag');

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
    );

    my $changeset_mid = TestSetup->create_topic(
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
    );

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => {
            params => {
                id_rule              => $id_rule,
                changesets           => $changeset_mid,
                window_type          => 'N',
                rule_version_tag     => 'tag',
                rule_version_dynamic => 'on'
            }
        }
    );

    my $controller = _build_controller();

    capture {
        $controller->submit($c);
    };

    my ($job_name) = $c->stash->{json}->{msg} =~ m/Job (.*?) created/;
    my $job = ci->job->find_one({name => $job_name});

    is $job->{rule_version_id}, undef;
    is $job->{rule_version_tag}, 'tag';
};

subtest 'steps: returns job steps' => sub {
    _setup();

    my $c          = mock_catalyst_c();
    my $controller = _build_controller();

    $controller->steps($c);

    is_deeply $c->stash->{json},
      { data => [ { name => 'CHECK' }, { name => 'INIT' }, { name => 'PRE' }, { name => 'RUN' }, { name => 'POST' } ] };
};

subtest 'by_status: returns the amount of jobs user has permissions to view and the status of the jobs' => sub {
    _setup();

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => 'PROD'
            },
        ]
    );
    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    my $id_rule = TestSetup->create_rule( rule_when => 'promote' );

    capture {
        TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'DEV'
        );
    };

    capture {
        TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD'
        );
    };

    my $c = mock_catalyst_c( username => 'user' );

    my $controller = _build_controller();

    $controller->by_status($c);

    is $c->stash->{json}->{data}[0][0], 'FINISHED';
    is $c->stash->{json}->{data}[0][1], 1;
};

subtest 'by_status: returns the amount of jobs and the status of the jobs filtering by bl' => sub {
    _setup();

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => '*'
            },
        ]
    );
    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    my $id_rule = TestSetup->create_rule( rule_when => 'promote' );

    capture {
        TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'DEV'
        );
    };

    capture {
        TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD'
        );
    };

    my $c = mock_catalyst_c(
        username => 'user',
        req      => { params => { bls => 'DEV' } }
    );

    my $controller = _build_controller();

    $controller->by_status($c);

    is $c->stash->{json}->{data}[0][0], 'FINISHED';
    is $c->stash->{json}->{data}[0][1], 1;
};

subtest 'by_status: returns the amount of jobs and the status of the jobs filtering by period' => sub {
    _setup();

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => '*'
            },
        ]
    );
    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $changeset_mid
        = TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );

    my $id_rule = TestSetup->create_rule( rule_when => 'promote' );

    capture {
        mock_time '2016-01-01 00:05:00' => sub {
            TestSetup->create_job(
                final_status => 'FINISHED',
                changesets   => [$changeset_mid],
            );
        };
    };
    capture {
        TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
        );
    };

    my $c = mock_catalyst_c(
        username => 'user',
        req      => { params => { period => '1D' } }
    );

    my $controller = _build_controller();

    $controller->by_status($c);

    is $c->stash->{json}->{data}[0][0], 'FINISHED';
    is $c->stash->{json}->{data}[0][1], 1;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Config',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'BaselinerX::Job',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',
        'BaselinerX::CI::job',
        'BaselinerX::Type::Statement'
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->rule_version->drop;
    mdb->role->drop;
    mdb->job_log->drop;

    TestUtils->create_ci('bl', name => 'Common', bl => '*');
    TestUtils->create_ci('bl', name => 'PROD', bl => 'PROD');

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.job.viewall',
                bl => 'PROD'
            },
            {
                action => 'action.job.no_cal',
                bl => 'PROD'
            },
        ]
    );

    TestSetup->create_user( id_role => $id_role, project => $project );
}

sub _build_controller {
    Baseliner::Controller::Job->new( application => '' );
}

sub _create_changeset_form {
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_name => 'Changeset',
        rule_tree => [
            _build_stmt(
                id   => 'title',
                name => 'Title',
                type => 'fieldlet.system.title'
            ),
            _build_stmt(
                id       => 'status_new',
                bd_field => 'id_category_status',
                name     => 'Status',
                type     => 'fieldlet.system.status_new'
            ),
            _build_stmt(
                id   => 'project',
                name => 'Project',
                type => 'fieldlet.system.projects'
            ),
            _build_stmt(
                id   => 'release',
                name => 'Release',
                type => 'fieldlet.system.release'
            ),
            _build_stmt(
                id   => 'revisions',
                name => 'Revisions',
                type => 'fieldlet.system.revisions'
            ),
        ],
    );
}

sub _build_stmt {
    my (%params) = @_;

    return {
        attributes => {
            active => 1,
            data   => {
                active       => 1,
                id_field     => $params{id},
                bd_field     => $params{bd_field} || $params{id},
                fieldletType => $params{type},
            },
            disabled       => \0,
            expanded       => 1,
            leaf           => \1,
            holds_children => \0,
            palette        => \0,
            key            => $params{type},
            name           => $params{name},
            text           => $params{name},
        },
        children => []
    };
}
