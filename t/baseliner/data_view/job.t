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

subtest 'find: builds correct query when field sorting is not in group keys' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $project_1     = TestUtils->create_ci_project( name => 'Project_A' );
    my $project_2     = TestUtils->create_ci_project( name => 'Project_B' );
    my $project_3     = TestUtils->create_ci_project( name => 'Project_C' );
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => [ $project_1, $project_2, $project_3 ] );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid_1       = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_1
    );
    my $topic_mid_2 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_2,
    );
    my $topic_mid_3 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_3
    );
    my $group_keys = { applications => 'job_contents.list_apps' };

    my $job_ci_1;
    my $job_ci_2;
    my $job_ci_3;

    capture {
        $job_ci_1 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_1],
            bl           => 'PROD',
            name         => 'job 1'
        );
    };
    capture {
        $job_ci_2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_2],
            bl           => 'PROD',
            name         => 'job 2'
        );
    };
    capture {
        $job_ci_3 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_3],
            bl           => 'PROD',
            name         => 'job 3'
        );
    };

    my $view = _build_view();

    my $find = $view->find(
        username   => 'root',
        groupby    => 'applications',
        dir        => 'desc',
        sort       => 'last_log',
        groupdir   => 'DESC',
        group_keys => $group_keys
    );

    my @job_list = $find->all;

    cmp_deeply $job_list[0]->{job_contents}->{list_apps}, ['Project_C'];
    cmp_deeply $job_list[1]->{job_contents}->{list_apps}, ['Project_B'];
    cmp_deeply $job_list[2]->{job_contents}->{list_apps}, ['Project_A'];
};

subtest 'find: builds correct query when field sorting and group by field  are nested in the same structure' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $project_1     = TestUtils->create_ci_project( name => 'Project_A' );
    my $project_2     = TestUtils->create_ci_project( name => 'Project_B' );
    my $project_3     = TestUtils->create_ci_project( name => 'Project_C' );
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => [ $project_1, $project_2, $project_3 ] );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid_1       = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_1
    );
    my $topic_mid_2 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_2,
    );
    my $topic_mid_3 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_3
    );
    my $group_keys = {
        applications => 'job_contents.list_apps',
        natures      => 'job_contents.list_natures'
    };

    my $job_ci_1;
    my $job_ci_2;
    my $job_ci_3;

    capture {
        $job_ci_1 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_1],
            bl           => 'PROD',
            name         => 'job 1'
        );
    };
    capture {
        $job_ci_2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_2],
            bl           => 'PROD',
            name         => 'job 2'
        );
    };
    capture {
        $job_ci_3 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_3],
            bl           => 'PROD',
            name         => 'job 3'
        );
    };

    my $view = _build_view();

    my $find = $view->find(
        username   => 'root',
        groupby    => 'applications',
        dir        => 'desc',
        sort       => 'natures',
        groupdir   => 'DESC',
        group_keys => $group_keys
    );

    my @job_list = $find->all;

    cmp_deeply $job_list[0]->{job_contents}->{list_apps}, ['Project_C'];
    cmp_deeply $job_list[1]->{job_contents}->{list_apps}, ['Project_B'];
    cmp_deeply $job_list[2]->{job_contents}->{list_apps}, ['Project_A'];
};

subtest 'find: builds correct query when field sorting is in group keys' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $project_1     = TestUtils->create_ci_project( name => 'Project_A' );
    my $project_2     = TestUtils->create_ci_project( name => 'Project_B' );
    my $project_3     = TestUtils->create_ci_project( name => 'Project_C' );
    my $project_4     = TestUtils->create_ci_project( name => 'Project_D' );
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user
        = TestSetup->create_user( id_role => $id_role, project => [ $project_1, $project_2, $project_3, $project_4 ] );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid_1 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_1
    );
    my $topic_mid_2 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_2,
    );
    my $topic_mid_3 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => [ $project_3, $project_4 ]
    );
    my $group_keys = {
        applications => 'job_contents.list_apps',
        bl           => 'bl'
    };

    my $job_ci_1;
    my $job_ci_2;
    my $job_ci_3;
    my $job_ci_4;

    capture {
        $job_ci_1 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_1],
            bl           => 'PROD',
            name         => 'job 1'
        );
    };
    capture {
        $job_ci_2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_2],
            bl           => 'QA',
            name         => 'job 2'
        );
    };
    capture {
        $job_ci_3 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_3],
            bl           => 'QA',
            name         => 'job 3'
        );
    };
    capture {
        $job_ci_4 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_3],
            bl           => 'PROD',
            name         => 'job 4'
        );
    };

    my $view = _build_view();

    my $find = $view->find(
        username   => 'root',
        groupby    => 'applications',
        dir        => 'asc',
        sort       => 'bl',
        groupdir   => 'asc',
        group_keys => $group_keys
    );

    my @job_list = $find->all;

    cmp_deeply $job_list[0]->{bl}, 'PROD';
    cmp_deeply $job_list[0]->{job_contents}->{list_apps}, ['Project_A'];
    cmp_deeply $job_list[1]->{bl}, 'QA';
    cmp_deeply $job_list[1]->{job_contents}->{list_apps}, ['Project_B'];
    cmp_deeply $job_list[2]->{bl}, 'PROD';
    cmp_deeply $job_list[2]->{job_contents}->{list_apps}, [ 'Project_C', 'Project_D' ];
    cmp_deeply $job_list[3]->{bl}, 'QA';
    cmp_deeply $job_list[3]->{job_contents}->{list_apps}, [ 'Project_C', 'Project_D' ];
};

subtest 'find: builds correct query when groupby field is not nested' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();
    my $project_1     = TestUtils->create_ci_project( name => 'Project_A' );
    my $project_2     = TestUtils->create_ci_project( name => 'Project_B' );
    my $project_3     = TestUtils->create_ci_project( name => 'Project_C' );
    my $project_4     = TestUtils->create_ci_project( name => 'Project_D' );
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user
        = TestSetup->create_user( id_role => $id_role, project => [ $project_1, $project_2, $project_3, $project_4 ] );
    my $id_topic_category = TestSetup->create_category( name => 'Topic', id_rule => $id_topic_rule );
    my $topic_mid_1 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_1
    );
    my $topic_mid_2 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => $project_2,
    );
    my $topic_mid_3 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => [$project_3]
    );
    my $topic_mid_4 = TestSetup->create_topic(
        id_category => $id_topic_category,
        project     => [$project_4]
    );
    my $group_keys = {
        bl     => 'bl',
        status => 'status'
    };

    my $job_ci_1;
    my $job_ci_2;
    my $job_ci_3;
    my $job_ci_4;

    capture {
        $job_ci_1 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_1],
            bl           => 'PROD',
            name         => 'job 1'
        );
    };
    capture {
        $job_ci_2 = TestSetup->create_job(
            final_status => 'FINISHED',
            changesets   => [$topic_mid_2],
            bl           => 'QA',
            name         => 'job 2'
        );
    };
    capture {
        $job_ci_3 = TestSetup->create_job(
            status     => 'READY',
            changesets => [$topic_mid_3],
            bl         => 'QA',
            name       => 'job 3'
        );
    };
    capture {
        $job_ci_4 = TestSetup->create_job(
            final_status => 'READY',
            changesets   => [$topic_mid_4],
            bl           => 'QA',
            name         => 'job 4'
        );
    };

    my $view = _build_view();

    my $find = $view->find(
        username   => 'root',
        groupby    => 'bl',
        dir        => 'desc',
        sort       => 'status',
        groupdir   => 'DESC',
        group_keys => $group_keys
    );

    my @job_list = $find->all;

    cmp_deeply $job_list[0]->{bl},     'QA';
    cmp_deeply $job_list[0]->{status}, 'READY';
    cmp_deeply $job_list[1]->{bl},     'QA';
    cmp_deeply $job_list[1]->{status}, 'READY';
    cmp_deeply $job_list[2]->{bl},     'QA';
    cmp_deeply $job_list[2]->{status}, 'FINISHED';
    cmp_deeply $job_list[3]->{bl},     'PROD';
    cmp_deeply $job_list[3]->{status}, 'FINISHED';
};

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
    my $project2      = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role       = TestSetup->create_role(
        actions => [
            {
                action => 'action.job.viewall',
                bounds => [ { } ]
            },
        ]
    );

    TestSetup->create_user(
        username         => 'user',
        project_security => {
            $id_role => {
                project => [$project, $project2]
            }
        }
    );

    my $view  = _build_view();
    my $where = $view->build_where(
        username => 'user',
        query_id => -1,
        filter   => { filter_project => [ $project->mid, $project2->mid, $other_project->mid ] }
    );

    cmp_deeply $where->{projects}, { '$in' => [ $project->mid, $project2->mid ] };
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

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );
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

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );
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

    my $rs =
      $view->find( username => $user->username, filter => { job_state_filter => '{"CANCELLED":1,"APPROVAL":0}' } );

    is $rs->next->{mid}, $job_ci3->{mid};
    is $rs->count, '1';
};

subtest 'find: returns jobs filtered by bls' => sub {
    _setup();

    my $id_topic_rule = _create_topic_form();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );
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

    my $project = TestUtils->create_ci_project;
    my $bl = TestUtils->create_ci( 'bl', name => 'PROD', bl => 'PROD' );
    my $id_role =
      TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ { bl => 'DEV' } ] } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic_mid = TestSetup->create_topic( id_category => $id_topic_category, project => $project );
    my $id_rule = TestSetup->create_rule( rule_when => 'promote' );
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
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
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
    my $id_role   = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
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
    my $id_role      = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
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

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
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

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
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

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.job.viewall', bounds => [ {} ] } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );
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
            {
                "attributes" => {
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
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'from',
                        "fieldletType" => "fieldlet.datetime",
                    },
                    "key" => "fieldlet.datetime",
                    name  => 'From',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'to',
                        "fieldletType" => "fieldlet.datetime",
                    },
                    "key" => "fieldlet.datetime",
                    name  => 'To',
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
        ],
    );
}

sub _build_view {
    Baseliner::DataView::Job->new;
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',  'BaselinerX::Type::Config',
        'BaselinerX::Type::Event',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service', 'BaselinerX::Type::Statement',
        'BaselinerX::CI',            'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',   'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',    'Baseliner::Controller::Job',
    );

    TestUtils->cleanup_cis;

    mdb->master_doc->drop;
    mdb->category->drop;
    mdb->job_log->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->topic->drop;
}
