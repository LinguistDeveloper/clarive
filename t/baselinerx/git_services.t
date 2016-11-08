use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestGit;

use_ok 'BaselinerX::GitServices';

subtest 'create_branch: creates a branch' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit };

    my $gs = _build_service();
    $gs->create_branch( $stash, $config );

    my $git = $repo->git;

    my @branches = $git->exec( 'branch', '-a' );

    is_deeply( \@branches, [ '* master', '  test_branch' ] );

    my $branch_sha = $git->exec( 'rev-parse', 'test_branch' );

    is $branch_sha, $commit;
};

subtest 'create_branch: creates and returns revisions' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit };

    my $gs = _build_service();
    my $revisions = $gs->create_branch( $stash, $config );

    is @$revisions, 1;

    my $revision = ci->new($revisions->[0]);
    is $revision->name, 'test_branch';
    is $revision->repo->mid, $repo->mid;
    is $revision->sha, 'test_branch';
    is $revision->moniker, $commit;
};

subtest 'create_branch: creates a branch in multiple repositories' => sub {
    _setup();

    my $gs    = _build_service();
    my $stash = {};

    my $repo1   = TestUtils->create_ci_GitRepository();
    my $commit1 = TestGit->commit($repo1);

    my $config = { repo => $repo1->mid, tag => 'TEST', sha => $commit1 };
    $gs->create_tag( $stash, $config );

    my $repo2   = TestUtils->create_ci_GitRepository();
    my $commit2 = TestGit->commit($repo2);

    $config = { repo => $repo2->mid, tag => 'TEST', sha => $commit2 };
    $gs->create_tag( $stash, $config );

    $config = { repo => [ $repo1->mid, $repo2->mid ], branch => 'test_branch', sha => 'TEST' };
    $gs->create_branch( $stash, $config );

    my $git = $repo1->git;

    my @branches = $git->exec( 'branch', '-a' );

    is_deeply( \@branches, [ '* master', '  test_branch' ] );

    my $branch_sha = $git->exec( 'rev-parse', 'test_branch' );

    is $branch_sha, $commit1;

    $git = $repo2->git;

    @branches = $git->exec( 'branch', '-a' );

    is_deeply( \@branches, [ '* master', '  test_branch' ] );

    $branch_sha = $git->exec( 'rev-parse', 'test_branch' );

    is $branch_sha, $commit2;
};

subtest 'create_branch: fails if no sha provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, branch => 'test_branch' };

    my $gs = _build_service();

    like exception { $gs->create_branch( $stash, $config ) }, qr/Missing sha/;
};

subtest 'create_branch: fails if no branch provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid };

    my $gs = _build_service();

    like exception { $gs->create_branch( $stash, $config ) }, qr/Missing branch name/;
};

subtest 'create_branch: fails if no repo provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash  = {};
    my $config = {};

    my $gs = _build_service();

    like exception { $gs->create_branch( $stash, $config ) }, qr/Missing repo mid/;
};

subtest 'create_branch: move branch if force specified' => sub {
    _setup();

    my $repo    = TestUtils->create_ci_GitRepository();
    my $commit  = TestGit->commit($repo);
    my $commit2 = TestGit->commit($repo);

    my $stash  = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit };
    my $gs     = _build_service();
    $gs->create_branch( $stash, $config );

    $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit2, force => 1 };
    $gs->create_branch( $stash, $config );

    my $git = $repo->git;
    my $branch_sha = $git->exec( 'rev-parse', 'test_branch' );

    is $branch_sha, $commit2;
};

subtest 'create_branch: fails if branch exists' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash  = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit };
    my $gs     = _build_service();
    $gs->create_branch( $stash, $config );

    like exception { $gs->create_branch( $stash, $config ) }, qr/A branch named 'test_branch' already exists/;
};

subtest 'create_branch: fails if commit does not exist' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash  = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => 'TEST' };
    my $gs     = _build_service();

    like exception { $gs->create_branch( $stash, $config ) }, qr/Not a valid object name: 'TEST'/;
};

subtest 'create_tag: creates a tag in repo' => sub {
    _setup();

    my $gs    = _build_service();
    my $stash = {};

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $config = { repo => $repo->mid, tag => 'TEST', sha => $commit };
    $gs->create_tag( $stash, $config );

    my $git = $repo->git;

    my @tags = $git->exec('tag');

    is_deeply( \@tags, ['TEST'] );

    my $tag_sha = $git->exec( 'rev-parse', 'TEST' );

    is $tag_sha, $commit;
};

subtest 'create_tag: fails if no sha provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, tag => 'test_branch' };

    my $gs = _build_service();

    like exception { $gs->create_tag( $stash, $config ) }, qr/Missing sha/;
};

subtest 'create_tag: fails if no tag provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid };

    my $gs = _build_service();

    like exception { $gs->create_tag( $stash, $config ) }, qr/Missing tag name/;
};

subtest 'create_tag: fails if no repo provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash  = {};
    my $config = {};

    my $gs = _build_service();

    like exception { $gs->create_tag( $stash, $config ) }, qr/Missing repo mid/;
};

subtest 'create_tag: fails when tag already exists' => sub {
    _setup();

    my $repo    = TestUtils->create_ci_GitRepository();
    my $commit  = TestGit->commit($repo);
    my $commit2 = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, tag => 'TEST', sha => $commit };

    my $gs = _build_service();
    $gs->create_tag( $stash, $config );

    $config = { repo => $repo->mid, tag => 'TEST', sha => $commit2 };

    like exception { $gs->create_tag( $stash, $config ) }, qr/already exists/;
};

subtest 'create_tag: moves tag if already exists and force is selected' => sub {
    _setup();

    my $repo    = TestUtils->create_ci_GitRepository();
    my $commit  = TestGit->commit($repo);
    my $commit2 = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, tag => 'TEST', sha => $commit };

    my $gs = _build_service();
    $gs->create_tag( $stash, $config );

    $config = { repo => $repo->mid, tag => 'TEST', sha => $commit2, force => 'on' };

    $gs->create_tag( $stash, $config );

    my @tags = $repo->git->exec('tag');

    is_deeply( \@tags, ['TEST'] );

    my $tag_sha = $repo->git->exec( 'rev-parse', 'TEST' );

    is $tag_sha, $commit2;
};

subtest 'delete_reference: deletes branch' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    $repo->git->exec( 'checkout', '-b', 'new_branch' );
    $repo->git->exec( 'checkout', 'master' );

    my $gs = _build_service();

    $gs->delete_reference( {}, { repo => $repo->mid, type => 'branch', sha => 'new_branch' } );

    my @branches = $repo->git->exec( 'branch', '-a' );

    is_deeply( \@branches, ['* master'] );
};

subtest 'delete_reference: deletes tag' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    $repo->git->exec( 'tag', 'TAG' );

    my $gs = _build_service();

    $gs->delete_reference( {}, { repo => $repo->mid, type => 'tag', sha => 'TAG' } );

    my @tags = $repo->git->exec('tag');

    is_deeply( \@tags, [] );
};

subtest 'delete_reference: deletes any reference' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    $repo->git->exec( 'checkout', '-b', 'new_branch' );
    $repo->git->exec( 'checkout', 'master' );
    $repo->git->exec( 'tag', 'TAG' );

    my $gs = _build_service();

    $gs->delete_reference( {}, { repo => $repo->mid, type => 'any', sha => 'new_branch' } );
    $gs->delete_reference( {}, { repo => $repo->mid, type => 'any', sha => 'TAG' } );

    my @branches = $repo->git->exec( 'branch', '-a' );
    my @tags = $repo->git->exec('tag');

    is_deeply( \@branches, ['* master'] );
    is_deeply( \@tags, [] );
};

subtest 'merge_branch: merges branches' => sub {
    _setup();

    my $bare_repo = TestGit->create_repo( bare => 1 );
    my $cloned_repo = TestGit->clone($bare_repo);

    my $repo = TestUtils->create_ci('GitRepository', repo_dir => $bare_repo);

    TestGit->commit($cloned_repo);

    TestGit->create_branch( $cloned_repo, branch => 'new_branch' );
    TestGit->switch_branch( $cloned_repo, 'new_branch' );
    TestGit->commit( $cloned_repo, message => 'some fixes' );
    TestGit->push($cloned_repo, upstream => 'new_branch');
    TestGit->switch_branch( $cloned_repo, 'master' );
    TestGit->push($cloned_repo);

    my $gs = _build_service();

    $gs->merge_branch( {}, { repo => $repo->mid, no_ff => 'on', topic_branch => 'new_branch', into_branch => 'master' } );

    my @log = $repo->git->exec('log');

    ok grep { m/Merge branch/ } @log;
};

subtest 'merge_branch: merges branches with custom message' => sub {
    _setup();

    my $bare_repo = TestGit->create_repo( bare => 1 );
    my $cloned_repo = TestGit->clone($bare_repo);

    my $repo = TestUtils->create_ci('GitRepository', repo_dir => $bare_repo);

    TestGit->commit($cloned_repo);

    TestGit->create_branch( $cloned_repo, branch => 'new_branch' );
    TestGit->switch_branch( $cloned_repo, 'new_branch' );
    TestGit->commit( $cloned_repo, message => 'some fixes' );
    TestGit->push($cloned_repo, upstream => 'new_branch');
    TestGit->switch_branch( $cloned_repo, 'master' );
    TestGit->push($cloned_repo);

    my $gs = _build_service();

    $gs->merge_branch(
        {},
        {
            repo         => $repo->mid,
            no_ff        => 'on',
            topic_branch => 'new_branch',
            into_branch  => 'master',
            message      => 'Hello from another branch'
        }
    );

    my @log = $repo->git->exec('log');

    ok grep { m/Hello from another branch/ } @log;
};

subtest 'merge_branch: fails when conflicts' => sub {
    _setup();

    my $bare_repo = TestGit->create_repo( bare => 1 );
    my $cloned_repo = TestGit->clone($bare_repo);

    my $repo = TestUtils->create_ci('GitRepository', repo_dir => $bare_repo);

    TestGit->commit($cloned_repo, content => "one\ntwo\nthree");
    TestGit->push($cloned_repo);

    TestGit->create_branch( $cloned_repo, branch => 'new_branch' );
    TestGit->switch_branch( $cloned_repo, 'new_branch' );
    TestGit->commit( $cloned_repo, message => 'some fixes', action => 'replace', content => "one123\nconflict\nthree");
    TestGit->push($cloned_repo, upstream => 'new_branch');

    TestGit->switch_branch( $cloned_repo, 'master' );
    TestGit->commit($cloned_repo, content => "one\ntwo2\nthree", action => 'replace');
    TestGit->push($cloned_repo);

    my $gs = _build_service();

    like exception {
        $gs->merge_branch( {},
            { repo => $repo->mid, no_ff => 'on', topic_branch => 'new_branch', into_branch => 'master' } )
    },
      qr/Merge failed/;
};

subtest 'rebase_branch: rebases branch' => sub {
    _setup();

    my $bare_repo = TestGit->create_repo( bare => 1 );
    my $cloned_repo = TestGit->clone($bare_repo);

    my $repo = TestUtils->create_ci('GitRepository', repo_dir => $bare_repo);

    TestGit->commit($cloned_repo, file => 'README');
    TestGit->push($cloned_repo);

    TestGit->create_branch( $cloned_repo, branch => 'new_branch' );
    TestGit->switch_branch( $cloned_repo, 'new_branch' );
    TestGit->commit( $cloned_repo, message => 'some fixes', file => 'INSTALL');
    TestGit->push($cloned_repo, upstream => 'new_branch');

    TestGit->switch_branch( $cloned_repo, 'master' );
    TestGit->commit($cloned_repo, file => 'README');
    TestGit->push($cloned_repo);

    my $gs = _build_service();

    $gs->rebase_branch( {}, { repo => $repo->mid, branch => 'new_branch', upstream => 'master' } );

    my @log = grep { /commit/ } $repo->git->exec( 'log', 'new_branch' );

    is @log, 3;
};

subtest 'rebase_branch: throws when conflicts' => sub {
    _setup();

    my $bare_repo = TestGit->create_repo( bare => 1 );
    my $cloned_repo = TestGit->clone($bare_repo);

    my $repo = TestUtils->create_ci('GitRepository', repo_dir => $bare_repo);

    TestGit->commit($cloned_repo, content => "one");
    TestGit->push($cloned_repo);

    TestGit->create_branch( $cloned_repo, branch => 'new_branch' );
    TestGit->switch_branch( $cloned_repo, 'new_branch' );
    TestGit->commit( $cloned_repo, message => 'some fixes', action => 'replace', content => "one123");
    TestGit->push($cloned_repo, upstream => 'new_branch');

    TestGit->switch_branch( $cloned_repo, 'master' );
    TestGit->commit($cloned_repo, content => "one\ntwo2\nthree", action => 'replace');
    TestGit->push($cloned_repo);

    my $gs = _build_service();

    like exception { $gs->rebase_branch( {}, { repo => $repo->mid, branch => 'new_branch', upstream => 'master' } ) }, qr/Rebase failed/;
};

done_testing();

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->register_ci_events;
}

sub _build_service {
    return BaselinerX::GitServices->new();
}
