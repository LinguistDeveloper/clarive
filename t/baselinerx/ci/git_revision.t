use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;
use Capture::Tiny qw(capture);

use TestEnv;
BEGIN { TestEnv->setup; }

use TestUtils;
use TestGit;

use BaselinerX::CI::project;

use_ok 'BaselinerX::CI::GitRevision';

subtest 'items: returns added items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha2 = TestGit->commit( $repo, file => 'NEW_FILE' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my @items = $rev->items( tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: returns modified items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my @items = $rev->items( tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns deleted items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha2 = TestGit->commit( $repo, action => 'git rm README' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my @items = $rev->items( tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'D';
    is $item->mask,   undef;
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns added items when demoting' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit( $repo, action => 'git rm README' );
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my @items = $rev->items( type => 'demote', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns modified items when demoting' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my @items = $rev->items( type => 'demote', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns deleted items when demoting' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit( $repo, file => 'NEW_FILE' );
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my @items = $rev->items( type => 'demote', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'D';
    is $item->mask,   undef;
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: returns items referenced by branch' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha2 = TestGit->commit( $repo, file => 'NEW_FILE' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => 'HEAD' );

    my @items = $rev->items( tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'create_or_update: fails when repo_dir missing' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    like exception { BaselinerX::CI::GitRevision->create_or_update( {} ) }, qr/Missing parameter repo_dir/;
};

subtest 'create_or_update: fails when repo_mid missing' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    like exception { BaselinerX::CI::GitRevision->create_or_update( { repo_dir => $repo->repo_dir } ) },
      qr/Missing parameter repo_mid/;
};

subtest 'create_or_update: fails when sha missing' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    like exception {
        BaselinerX::CI::GitRevision->create_or_update( { repo_dir => $repo->repo_dir, repo_mid => $repo->mid } )
    }, qr/Missing parameter sha/;
};

subtest 'create_or_update: creates new revision' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );
    my $sha = TestGit->commit($repo, message => 'initial');

    my $sha_short = substr( $sha, 0, 8 );
    my $name = "[$sha_short] initial";

    my $rev_mid = BaselinerX::CI::GitRevision->create_or_update(
        { repo_dir => $repo->repo_dir, repo_mid => $repo->mid, sha => $sha } );

    my $new_revision = ci->GitRevision->find_one({mid=>$rev_mid});

    is $new_revision->{repo}, $repo->mid;
    is $new_revision->{sha}, $sha;
    is $new_revision->{moniker}, $sha;
    is $new_revision->{name}, $name;
};

subtest 'create_or_update: creates new revision from branch' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );
    my $sha = TestGit->commit($repo, message => 'initial');
    TestGit->create_branch( $repo, branch => 'test' );

    my $sha_short = substr( $sha, 0, 8 );
    my $name = "[test] initial";

    my $rev_mid = BaselinerX::CI::GitRevision->create_or_update(
        { repo_dir => $repo->repo_dir, repo_mid => $repo->mid, sha => 'test' } );

    my $new_revision = ci->GitRevision->find_one({mid=>$rev_mid});

    is $new_revision->{repo}, $repo->mid;
    is $new_revision->{sha}, 'test';
    is $new_revision->{moniker}, 'test';
    is $new_revision->{name}, $name;
};

subtest 'create_or_update: loads existing revision' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );
    my $sha = TestGit->commit($repo, message => 'initial');
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    my $rev_mid = BaselinerX::CI::GitRevision->create_or_update(
        { repo_dir => $repo->repo_dir, repo_mid => $repo->mid, sha => $sha } );

    my $new_revision = ci->GitRevision->find_one({mid=>$rev_mid});

    is $rev->{mid}, $rev_mid;
};


subtest 'create_or_update: loads existing revision from correct repo' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );
    my $sha = TestGit->commit($repo, message => 'initial');
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    my $repo2 = TestUtils->create_ci_GitRepository( name => 'repo2', revision_mode => 'diff' );
    my $sha2 = TestGit->commit($repo2, message => 'initial');
    my $rev2 = TestUtils->create_ci( 'GitRevision', repo => $repo2, sha => $sha2 );


    my $rev_mid = BaselinerX::CI::GitRevision->create_or_update(
        { repo_dir => $repo->repo_dir, repo_mid => $repo->mid, sha => $sha } );

    my $new_revision = ci->GitRevision->find_one({mid=>$rev_mid});

    is $rev->{mid}, $rev_mid;
    is $new_revision->{repo}, $repo->mid;
};

subtest 'create_or_update: creates new revision from correct repo' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );
    my $sha = TestGit->commit($repo, message => 'initial');
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    my $repo2 = TestUtils->create_ci_GitRepository( name => 'repo2', revision_mode => 'diff' );
    my $sha2 = TestGit->commit($repo2, message => 'initial');

    my $rev_mid = BaselinerX::CI::GitRevision->create_or_update(
        { repo_dir => $repo2->repo_dir, repo_mid => $repo2->mid, sha => $sha2 } );

    my $new_revision = ci->GitRevision->find_one({mid=>$rev_mid});

    isnt $rev->{mid}, $rev_mid;
    is $new_revision->{repo}, $repo2->mid;
};

subtest 'create_or_update: creates new revision branch from correct repo' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );
    my $sha = TestGit->commit($repo, message => 'initial');
    TestGit->create_branch( $repo, branch => 'test' );
    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => 'test' );

    my $repo2 = TestUtils->create_ci_GitRepository( name => 'repo2', revision_mode => 'diff' );
    my $sha2 = TestGit->commit($repo2, message => 'initial');
    TestGit->create_branch( $repo2, branch => 'test' );

    my $rev_mid = BaselinerX::CI::GitRevision->create_or_update(
        { repo_dir => $repo2->repo_dir, repo_mid => $repo2->mid, sha => 'test' } );

    my $new_revision = ci->GitRevision->find_one({mid=>$rev_mid});

    isnt $rev->{mid}, $rev_mid;
    is $new_revision->{repo}, $repo2->mid;
    is $new_revision->{sha}, 'test';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'BaselinerX::CI',
        'Baseliner::Model::Jobs',
        'Baseliner::Model::Rules',
        'Baseliner::Controller::GitSmart'
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;
}
