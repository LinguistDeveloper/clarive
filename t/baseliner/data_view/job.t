use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils 'mock_time';
use TestSetup;
use Capture::Tiny qw(capture);

use Baseliner::DataView::Job;

subtest 'build_where: builds correct where period' => sub {
    _setup();

    my $where;
    my $view = _build_view();

    mock_time '2016-01-02 00:00:00' => sub {
        $where = $view->build_where( username => 'root', query_id => -1, filter => { period => '1D' } );
    };

    cmp_deeply $where, { endtime => { '$gt' => '2016-01-01' } };
};

subtest 'build_where: builds correct where type' => sub {
    _setup();

    my $view = _build_view();
    my $where = $view->build_where( username => 'root', query_id => -1, filter => { filter_type => 'demote' } );

    cmp_deeply $where, { job_type => 'demote' };
};

subtest 'build_where: builds correct where bl' => sub {
    _setup();

    my $bl = TestUtils->create_ci( 'bl', name => 'PROD', bl => 'PROD' );

    my $view = _build_view();
    my $where = $view->build_where( username => 'root', query_id => -1, filter => { bls => $bl->mid } );

    cmp_deeply $where, { bl => { '$in' => [ $bl->mid ] } };
};

subtest 'build_where: builds correct where bl when user has bl associated' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => 'PROD'
            },
        ]
    );

    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $view = _build_view();
    my $where = $view->build_where( username => 'user', query_id => -1, filter => { bls => 'PROD' } );

    cmp_deeply $where, { bl => { '$in' => ['PROD'] }, projects => { '$in' => [ $project->mid ] } };
};

subtest 'build_where: builds correct where bl when user has bl associated' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => 'PROD'
            },
        ]
    );

    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $view = _build_view();
    my $where = $view->build_where( username => 'user', query_id => -1, filter => { bls => 'PROD' } );

    cmp_deeply $where, { bl => { '$in' => ['PROD'] }, projects => { '$in' => [ $project->mid ] } };
};

subtest 'build_where: builds correct where bl when user has other bl associated' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => 'PROD'
            },
        ]
    );

    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $view = _build_view();
    my $where = $view->build_where( username => 'user', query_id => -1, filter => { bls => 'TEST' } );

    cmp_deeply $where, { bl => '', projects => { '$in' => [ $project->mid ] } };
};

subtest 'build_where: builds correct where natures' => sub {
    _setup();

    my $nature = TestUtils->create_ci( 'nature', name => 'JAR' );

    my $view = _build_view();
    my $where = $view->build_where( username => 'root', query_id => -1, filter => { filter_nature => $nature->mid } );

    cmp_deeply $where, { natures => { '$in' => [ $nature->mid ] } };
};

subtest 'build_where: builds correct where projects' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;

    my $view = _build_view();
    my $where = $view->build_where( username => 'root', query_id => -1, filter => { filter_project => $project->mid } );

    cmp_deeply $where, { projects => { '$in' => [ $project->mid ] } };
};

subtest 'build_where: builds correct where when user has project associated' => sub {
    _setup();

    my $project       = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role       = TestSetup->create_role(
        actions => [
            {   action => 'action.job.viewall',
                bl     => 'PROD'
            },
        ]
    );

    TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $view  = _build_view();
    my $where = $view->build_where(
        username => 'user',
        query_id => -1,
        filter   => { filter_project => [ $project->mid, $other_project->mid ] }
    );

    cmp_deeply $where, { projects => { '$in' => [ $project->mid ] }, bl => { '$in' => ['PROD'] } };
};

subtest 'build_where: builds correct where statuses' => sub {
    _setup();

    my $view  = _build_view();
    my $where = $view->build_where(
        username => 'root',
        query_id => -1,
        filter   => { job_state_filter => '{"FINISHED":1,"APPROVAL":0}' }
    );

    cmp_deeply $where, { status => { '$in' => ['FINISHED'] } };
};

subtest 'build_where: builds correct where query_id' => sub {
    _setup();

    my $view = _build_view();
    my $where = $view->build_where( username => 'root', query_id => 'job1,job2' );

    cmp_deeply $where, { 'mid' => { '$in' => [ 'job1', 'job2' ] } };
};

subtest 'find: returns jobs filtered by where' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();

    my $project           = TestUtils->create_ci_project;
    my $id_role           = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user              = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid         = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule           = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };
    capture {
        $job_ci3 = TestSetup->create_job(
            final_status => 'CANCELLED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };
    my $view  = _build_view();
    my $where = {};
    $where->{status} = 'CANCELLED';

    my $rs = $view->find( username => $user->username, where => $where );

    is $rs->next->{mid}, $job_ci3->{mid};
    is $rs->count, '1';
};

subtest 'find: returns jobs filtered by status' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();

    my $project           = TestUtils->create_ci_project;
    my $id_role           = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user              = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid         = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule           = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };
    capture {
        $job_ci3 = TestSetup->create_job(
            final_status => 'CANCELLED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };
    my $view = _build_view();

    my $rs
        = $view->find( username => $user->username, filter => { job_state_filter => '{"CANCELLED":1,"APPROVAL":0}' } );

    is $rs->next->{mid}, $job_ci3->{mid};
    is $rs->count, '1';
};

subtest 'find: returns jobs filtered by bls' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();

    my $project           = TestUtils->create_ci_project;
    my $id_role           = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user              = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid         = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule           = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'DEV'
        );
    };
    capture {
        $job_ci3 = TestSetup->create_job(
            final_status => 'CANCELLED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };
    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { bls => 'PROD' } );

    is $rs->next->{mid}, $job_ci->{mid};
    is $rs->count, '1';

};

subtest 'find: returns empty if user has not permissions to view jobs filtered by bl' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project   = TestUtils->create_ci_project;
    my $bl        = TestUtils->create_ci( 'bl', name => 'PROD', bl => 'PROD' );
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => 'DEV' } ] );
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule   = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'DEV'
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { bls => $bl->name } );

    is $rs->count, '0';
};

subtest 'find: returns jobs filtered by period' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project   = TestUtils->create_ci_project;
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule   = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;

    capture {
        mock_time '2016-01-01 00:05:00' => sub {
            $job_ci = TestSetup->create_job(
                final_status => 'FINISHED',
                changesets   => [$topic_mid],
            );
        };
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { period => '7D' } );

    is $rs->next->{mid}, $job_ci2->{mid};
    is $rs->count, '1';
};

subtest 'find: returns job filtered by type' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project   = TestUtils->create_ci_project;
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user      = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $job_ci;
    my $job_ci2;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            job_type     => 'demote',
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            job_type     => 'promote',
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { filter_type => 'demote' } );

    is $rs->next->{mid}, $job_ci->{mid};
    is $rs->count, '1';
};

subtest 'find: returns job filtered by nature' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project      = TestUtils->create_ci_project;
    my $id_role      = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user         = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid    = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $nature       = TestUtils->create_ci( 'nature', name => 'JAR' );
    my $other_nature = TestUtils->create_ci( 'nature', name => 'FOO' );
    my $job_ci;
    my $job_ci2;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            job_type     => 'demote',
            natures      => [ $nature->mid ],
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            job_type     => 'promote',
            natures      => [ $other_nature->mid ]
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { filter_nature => $nature->mid } );

    is $rs->next->{mid}, $job_ci->{mid};
    is $rs->count, '1';
};

subtest 'find: returns job filtered by project' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project       = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid       = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $other_topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $other_project );
    my $job_ci;
    my $job_ci2;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            job_type     => 'demote',
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$other_topic_mid],
            job_type     => 'demote',
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { filter_project => $project->{mid} } );

    is $rs->next->{mid}, $job_ci->{mid};
    is $rs->count, '1';
};

subtest 'find: returns empty if user is not associated to the project to filter' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );

    my $project       = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid       = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $other_topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $other_project );
    my $job_ci;
    my $job_ci2;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            job_type     => 'demote',
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$other_topic_mid],
            job_type     => 'demote',
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, filter => { filter_project => $other_project->{mid} } );

    is $rs->count, '0';
};

subtest 'find: returns jobs filtered by query_id' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();

    my $project           = TestUtils->create_ci_project;
    my $id_role           = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bl => '*' } ] );
    my $user              = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid         = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule           = TestSetup->create_rule( rule_when => 'promote' );
    my $job_ci;
    my $job_ci2;
    my $job_ci3;

    capture {
        $job_ci = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => 'PROD'
        );
    };
    capture {
        $job_ci2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid],
            bl           => '*'
        );
    };

    my $view = _build_view();

    my $rs = $view->find( username => $user->username, query_id => $job_ci->{mid} . ',' . $job_ci2->{mid} );

    is $rs->next->{mid}, $job_ci->{mid};
    is $rs->count, '2';
};

done_testing;

sub _create_topic_form {
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'from',
                        "fieldletType" => "fieldlet.datetime",
                    },
                    "key" => "fieldlet.datetime",
                    name  => 'From',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'to',
                        "fieldletType" => "fieldlet.datetime",
                    },
                    "key" => "fieldlet.datetime",
                    name  => 'To',
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
        ],
    );
}

sub _build_view {
    Baseliner::DataView::Job->new;
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',     'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis;
    mdb->category->drop;
    mdb->topic->drop;
    mdb->rule->drop;
    mdb->job_log->drop;
    mdb->role->drop;
}
