use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestGit;

use BaselinerX::CI::GitItem;
use BaselinerX::CI::GitRepository;
use BaselinerX::CI::GitRevision;

use_ok 'BaselinerX::Service::ChangesetServices';

subtest 'update_baselines: calls repo update_baselines with correct params' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock('update_baselines');

    my $job = _mock_job();
    my $c   = _mock_c(
        stash => {
            job             => $job,
            project_changes => [
                {
                    project              => '',
                    repo_revisions_items => [
                        {
                            repo      => $repo,
                            revisions => [$rev],
                            items     => ''
                        }
                    ]
                }
            ]
        }
    );

    my $service = _build_service();

    $service->update_baselines( $c, {} );

    my (%args) = $repo->mocked_call_args('update_baselines');
    cmp_deeply \%args,
      {
        'revisions' => [$rev],
        'type'      => 'promote',
        'tag'       => 'TEST',
        'job'       => $job
      };
};

subtest 'update_baselines: groups revisions' => sub {
    _setup();

    my $repo1 = TestUtils->create_ci_GitRepository();
    my $sha11 = TestGit->commit($repo1);
    my $sha12 = TestGit->commit($repo1);
    TestGit->tag( $repo1, tag => 'TEST' );
    my $rev11 = TestUtils->create_ci( 'GitRevision', repo => $repo1, sha => $sha11 );
    my $rev12 = TestUtils->create_ci( 'GitRevision', repo => $repo1, sha => $sha12 );

    $repo1 = Test::MonkeyMock->new($repo1);
    $repo1->mock('update_baselines');

    my $repo2 = TestUtils->create_ci_GitRepository();
    my $sha21 = TestGit->commit($repo2);
    my $sha22 = TestGit->commit($repo2);
    TestGit->tag( $repo2, tag => 'TEST' );
    my $rev21 = TestUtils->create_ci( 'GitRevision', repo => $repo2, sha => $sha21 );
    my $rev22 = TestUtils->create_ci( 'GitRevision', repo => $repo2, sha => $sha22 );

    $repo2 = Test::MonkeyMock->new($repo2);
    $repo2->mock('update_baselines');

    my $job = _mock_job();
    my $c   = _mock_c(
        stash => {
            job             => $job,
            project_changes => [
                {
                    project              => '',
                    repo_revisions_items => [
                        {
                            repo      => $repo1,
                            revisions => [$rev11],
                            items     => ''
                        },
                        {
                            repo      => $repo1,
                            revisions => [$rev12],
                            items     => ''
                        },
                        {
                            repo      => $repo2,
                            revisions => [$rev21],
                            items     => ''
                        },
                        {
                            repo      => $repo2,
                            revisions => [$rev22],
                            items     => ''
                        },
                    ]
                }
            ]
        }
    );

    my $service = _build_service();

    $service->update_baselines( $c, {} );

    my (%args1) = $repo1->mocked_call_args('update_baselines');

    cmp_deeply \%args1,
      {
        'revisions' => bag( $rev11, $rev12 ),
        'type'      => 'promote',
        'tag'       => 'TEST',
        'job'       => $job
      };

    my (%args2) = $repo2->mocked_call_args('update_baselines');

    cmp_deeply \%args2,
      {
        'revisions' => bag( $rev21, $rev22 ),
        'type'      => 'promote',
        'tag'       => 'TEST',
        'job'       => $job
      };
};

subtest 'update_baselines: groups revisions with different projects' => sub {
    _setup();

    my $repo1 = TestUtils->create_ci_GitRepository();
    my $sha11 = TestGit->commit($repo1);
    my $sha12 = TestGit->commit($repo1);
    TestGit->tag( $repo1, tag => 'TEST' );
    my $rev11 = TestUtils->create_ci( 'GitRevision', repo => $repo1, sha => $sha11 );
    my $rev12 = TestUtils->create_ci( 'GitRevision', repo => $repo1, sha => $sha12 );

    $repo1 = Test::MonkeyMock->new($repo1);
    $repo1->mock('update_baselines');

    my $repo2 = TestUtils->create_ci_GitRepository();
    my $sha21 = TestGit->commit($repo2);
    my $sha22 = TestGit->commit($repo2);
    TestGit->tag( $repo2, tag => 'TEST' );
    my $rev21 = TestUtils->create_ci( 'GitRevision', repo => $repo2, sha => $sha21 );
    my $rev22 = TestUtils->create_ci( 'GitRevision', repo => $repo2, sha => $sha22 );

    $repo2 = Test::MonkeyMock->new($repo2);
    $repo2->mock('update_baselines');

    my $job = _mock_job();
    my $c   = _mock_c(
        stash => {
            job             => $job,
            project_changes => [
                {
                    project              => 'one',
                    repo_revisions_items => [
                        {
                            repo      => $repo1,
                            revisions => [$rev11],
                            items     => ''
                        },
                        {
                            repo      => $repo1,
                            revisions => [$rev12],
                            items     => ''
                        },
                    ]
                },
                {
                    project              => 'two',
                    repo_revisions_items => [
                        {
                            repo      => $repo2,
                            revisions => [$rev21],
                            items     => ''
                        },
                        {
                            repo      => $repo2,
                            revisions => [$rev22],
                            items     => ''
                        },
                    ]
                }
            ]
        }
    );

    my $service = _build_service();

    $service->update_baselines( $c, {} );

    my (%args1) = $repo1->mocked_call_args('update_baselines');

    cmp_deeply \%args1,
      {
        'revisions' => bag( $rev11, $rev12 ),
        'type'      => 'promote',
        'tag'       => 'TEST',
        'job'       => $job
      };

    my (%args2) = $repo2->mocked_call_args('update_baselines');

    cmp_deeply \%args2,
      {
        'revisions' => bag( $rev21, $rev22 ),
        'type'      => 'promote',
        'tag'       => 'TEST',
        'job'       => $job
      };
};

subtest 'update_baselines: saves to stash previous rev for rollback' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock( update_baselines => sub { 'UPDATE BASELINES' } );

    my $job   = _mock_job();
    my $stash = {
        job             => $job,
        project_changes => [
            {
                project              => '',
                repo_revisions_items => [
                    {
                        repo      => $repo,
                        revisions => [$rev],
                        items     => ''
                    }
                ]
            }
        ]
    };
    my $c = _mock_c( stash => $stash );

    my $service = _build_service();

    $service->update_baselines( $c, {} );

    is_deeply $stash->{bl_original}, { $repo->mid => 'UPDATE BASELINES' };
};

subtest 'update_baselines: calls repo update_baselines with correct params in rollback mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha      = TestGit->commit($repo);
    my $prev_sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $prev_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $prev_sha );
    my $rev      = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock( update_baselines => sub { 'UPDATE BASELINES' } );

    my $job = _mock_job( rollback => sub { 1 } );
    my $c = _mock_c(
        stash => {
            bl_original => {
                $repo->mid => {
                    'some-key' => {
                        previous => $prev_rev,
                        current  => 'current',
                        output   => '',
                    }
                }
            },
            job             => $job,
            project_changes => [
                {
                    project              => '',
                    repo_revisions_items => [
                        {
                            repo      => $repo,
                            revisions => [$rev],
                            items     => ''
                        }
                    ]
                }
            ]
        }
    );

    my $service = _build_service();

    $service->update_baselines( $c, {} );

    my (%args) = $repo->mocked_call_args('update_baselines');
    cmp_deeply \%args,
      {
        'revisions' => [],
        'type'      => 'promote',
        'tag'       => 'TEST',
        'job'       => $job,
        'ref'       => $prev_rev
      };
};

subtest 'update_baselines: does nothing in rollback when no original bl found' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock( update_baselines => sub { 'UPDATE BASELINES' } );

    my $job = _mock_job( rollback => sub { 1 } );
    my $c = _mock_c(
        stash => {
            job             => $job,
            project_changes => [
                {
                    project              => '',
                    repo_revisions_items => [
                        {
                            repo      => $repo,
                            revisions => [$rev],
                            items     => ''
                        }
                    ]
                }
            ]
        }
    );

    my $service = _build_service();

    $service->update_baselines( $c, {} );

    is $repo->mocked_called('update_baselines'), 0;
};

subtest 'checkout_bl: calls repo checkout with correct params' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $repo = TestUtils->create_ci_GitRepository( rel_path => '/path/to/rel' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock( update_baselines => sub { 'UPDATE BASELINES' } );
    $repo->mock( checkout         => sub { } );

    my $job = _mock_job();
    my $c   = _mock_c(
        stash => {
            bl              => 'TEST',
            job             => $job,
            project_changes => [
                {
                    project              => $project,
                    repo_revisions_items => [
                        {
                            repo      => $repo,
                            revisions => [$rev],
                            items     => ''
                        }
                    ]
                }
            ]
        }
    );

    my $service = _build_service();

    $service->checkout_bl( $c, {} );

    my (%args) = $repo->mocked_call_args('checkout');
    cmp_deeply \%args,
      {
        'tag'     => 'TEST',
        'dir'     => '/job/dir/Project/path/to/rel',
        'project' => 'Project'
      };
};

subtest 'checkout_bl_all_repos: calls repo checkout with correct params' => sub {
    _setup();

    my $repo1 = TestUtils->create_ci_GitRepository( rel_path => 'path/to/repo1.git' );
    $repo1 = Test::MonkeyMock->new($repo1);
    $repo1->mock( checkout => sub { } );

    my $repo2 = TestUtils->create_ci_GitRepository( rel_path => 'path/to/repo2.git', bl => '*' );
    $repo2 = Test::MonkeyMock->new($repo2);
    $repo2->mock( checkout => sub { } );

    my $repo3 = TestUtils->create_ci_GitRepository( rel_path => 'path/to/repo3.git', bl => 'PROD' );
    $repo3 = Test::MonkeyMock->new($repo3);
    $repo3->mock( checkout => sub { } );

    my $project = TestUtils->create_ci_project();
    $project = Test::MonkeyMock->new($project);
    $project->mock( repositories => sub { [ $repo1, $repo2, $repo3 ] } );

    my $job = _mock_job();
    my $c   = _mock_c(
        stash => {
            bl              => 'TEST',
            job             => $job,
            project_changes => [
                {
                    project => $project,
                }
            ]
        }
    );

    my $service = _build_service();

    $service->checkout_bl_all_repos( $c, {} );

    my (%args1) = $repo1->mocked_call_args('checkout');
    cmp_deeply \%args1, {
        'project' => 'Project',
        'tag'     => 'TEST',
        'dir'     => '/job/dir/Project/path/to/repo1.git'

    };

    my (%args2) = $repo2->mocked_call_args('checkout');
    cmp_deeply \%args2, {
        'project' => 'Project',
        'tag'     => 'TEST',
        'dir'     => '/job/dir/Project/path/to/repo2.git'

    };

    is $repo3->mocked_called('checkout'), 0;
};

subtest 'job_items: loads items into job' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( rel_path => 'path/to/repo.git' );

    my $item = BaselinerX::CI::GitItem->new(
        repo      => $repo,
        sha       => '123',
        path      => "/full/path",
        versionid => 1,
    );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    my $project = TestUtils->create_ci_project();
    $project = Test::MonkeyMock->new($project);
    $project->mock( repositories => sub { [$repo] } );

    my $changeset = TestUtils->create_ci_topic();
    $changeset = Test::MonkeyMock->new($changeset);
    $changeset->mock( projects  => sub { ($project) } );
    $changeset->mock( revisions => sub { ($rev) } );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock( group_items_for_revisions => sub { ($item) } );

    my $job   = _mock_job();
    my $stash = {
        job        => $job,
        changesets => [$changeset]
    };
    my $c = _mock_c( stash => $stash );

    my $service = _build_service();

    $service->job_items( $c, {} );

    cmp_deeply $stash->{items}, [$item];
    is_deeply $stash->{item_name_list}, ['path'];
    is_deeply $stash->{item_name_list_quote}, q{'path'};
    is_deeply $stash->{item_name_list_comma}, 'path';

    is_deeply $stash->{project_changes},
      [
        {
            project              => $project,
            repo_revisions_items => [
                {
                    'revisions' => [$rev],
                    'repo'      => $repo,
                    'items'     => [$item]
                }
            ]
        }
      ];
};

subtest 'job_items: returns project count' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( rel_path => 'path/to/repo.git' );

    my $item = BaselinerX::CI::GitItem->new(
        repo      => $repo,
        sha       => '123',
        path      => "/full/path",
        versionid => 1,
    );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo = Test::MonkeyMock->new($repo);
    $repo->mock( group_items_for_revisions => sub { ($item) } );

    my $project = TestUtils->create_ci_project();
    $project = Test::MonkeyMock->new($project);
    $project->mock( repositories => sub { [$repo] } );

    my $changeset = TestUtils->create_ci_topic();
    $changeset = Test::MonkeyMock->new($changeset);
    $changeset->mock( projects  => sub { ($project) } );
    $changeset->mock( revisions => sub { ($rev) } );

    my $job   = _mock_job();
    my $stash = {
        job        => $job,
        changesets => [$changeset]
    };
    my $c = _mock_c( stash => $stash );

    my $service = _build_service();

    my $result = $service->job_items( $c, {} );

    is_deeply $result, { project_count => 1 };
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;
}

sub _mock_logger {
    my (%params) = @_;

    my $logger = Test::MonkeyMock->new;
    $logger->mock( info  => sub { } );
    $logger->mock( debug => sub { } );

    return $logger;
}

sub _mock_job {
    my (%params) = @_;

    my $logger = $params{logger} || _mock_logger();

    my $job = Test::MonkeyMock->new;
    $job->mock(
        is_failed => $params{is_failed} || sub { 0 },
        when => sub { $_[0] eq 'status' && $_[1] eq 'last_finish_status' }
    );
    $job->mock( rollback => $params{rollback} || sub { 0 } );
    $job->mock( logger   => sub { $logger } );
    $job->mock( job_type => sub { 'promote' } );
    $job->mock( job_dir  => sub { '/job/dir' } );
    $job->mock( bl       => sub { 'TEST' } );

    return $job;
}

sub _mock_c {
    my (%params) = @_;

    my $c = Test::MonkeyMock->new;
    $c->mock( stash => sub { $params{stash} } );

    return $c;
}

sub _build_service {
    my (%params) = @_;

    return BaselinerX::Service::ChangesetServices->new(@_);
}
