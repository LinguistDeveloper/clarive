use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;
use TestGit;
use TestSetup;

use BaselinerX::GitServices;

subtest 'create_branch: actually creates a branch' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash  = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit };
    my $gs     = BaselinerX::GitServices->new();
    my $rv     = $gs->create_branch( $stash, $config );

    my $git = $repo->git;

    my @branches = $git->exec( 'branch', '-a' );

    is_deeply( \@branches, [ '* master', '  test_branch' ] );

    my $branch_sha = $git->exec( 'rev-parse', 'test_branch' );

    is $branch_sha, $commit;
};

subtest 'create_branch: creates a branch in multiple repositories' => sub {
    _setup();

    my $gs = BaselinerX::GitServices->new();
    my $stash = {};

    my $repo1 = TestUtils->create_ci_GitRepository();
    my $commit1 = TestGit->commit($repo1);

    my $config = { repo => $repo1->mid, tag => 'TEST', sha => $commit1 };
    my $rv = $gs->create_tag( $stash, $config );

    my $repo2 = TestUtils->create_ci_GitRepository();
    my $commit2 = TestGit->commit($repo2);
    
    $config = { repo => $repo2->mid, tag => 'TEST', sha => $commit2 };
    $rv = $gs->create_tag( $stash, $config );


    $config = { repo => [$repo1->mid,$repo2->mid], branch => 'test_branch', sha => 'TEST' };
    $rv = $gs->create_branch( $stash, $config );

    my $git = $repo1->git;

    my @branches = $git->exec( 'branch', '-a' );
     
    is_deeply(\@branches, ['* master','  test_branch']);

    my $branch_sha = $git->exec( 'rev-parse', 'test_branch' );
         
    is $branch_sha, $commit1;

    $git = $repo2->git;

    @branches = $git->exec( 'branch', '-a' );
     
    is_deeply(\@branches, ['* master','  test_branch']);

    $branch_sha = $git->exec( 'rev-parse', 'test_branch' );
         
    is $branch_sha, $commit2;
};


subtest 'create_branch: fails if no sha provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, branch => 'test_branch' };

    like exception {
        my $gs = BaselinerX::GitServices->new();
        my $rv = $gs->create_branch( $stash, $config );
    }, qr/Missing sha/;

};

subtest 'create_branch: fails if no branch provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid };

    like exception {
        my $gs = BaselinerX::GitServices->new();
        my $rv = $gs->create_branch( $stash, $config );
    }, qr/Missing branch name/;
};

subtest 'create_branch: fails if no repo provided' => sub {
    _setup();

    my $repo   = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash  = {};
    my $config = {};

    like exception {
        my $gs = BaselinerX::GitServices->new();
        my $rv = $gs->create_branch( $stash, $config );
    }, qr/Missing repo mid/;
};

subtest 'create_branch: move branch if force specified' => sub {
    _setup();

    my $repo    = TestUtils->create_ci_GitRepository();
    my $commit  = TestGit->commit($repo);
    my $commit2 = TestGit->commit($repo);

    my $stash  = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit };
    my $gs     = BaselinerX::GitServices->new();
    my $rv     = $gs->create_branch( $stash, $config );

    $config = { repo => $repo->mid, branch => 'test_branch', sha => $commit2, force => 1 };
    $rv = $gs->create_branch( $stash, $config );

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
    my $gs     = BaselinerX::GitServices->new();
    my $rv     = $gs->create_branch( $stash, $config );

    like exception {
        my $rv = $gs->create_branch( $stash, $config );
    }, qr/A branch named 'test_branch' already exists/;
};

subtest 'create_branch: fails if commit does not exist' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();
    my $commit = TestGit->commit($repo);

    my $stash = {};
    my $config = { repo => $repo->mid, branch => 'test_branch', sha => 'TEST' };
    my $gs = BaselinerX::GitServices->new();

    like exception {
        my $rv = $gs->create_branch( $stash, $config );
    }, qr/Not a valid object name: 'TEST'/; 
     
};

done_testing();

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->register_ci_events;

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;
}
