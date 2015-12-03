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

use BaselinerX::CI::project;

use_ok 'BaselinerX::CI::GitRevision';

subtest 'items: returns added items' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
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

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );
    my $sha2 = _git_commit($repo_dir);

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
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

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    system("cd $repo_dir; git rm README; git commit -a -m 'new'");
    my $sha2 = ( _git_commits($repo_dir) )[0];

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
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

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; git rm README; git commit -a -m 'new'");
    my $sha2 = ( _git_commits($repo_dir) )[0];
    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( type => 'demote', bl => 'TEST', tag => 'TEST' );
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

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit($repo_dir);
    my $sha2 = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( type => 'demote', bl => 'TEST', tag => 'TEST' );
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

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( type => 'demote', bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'D';
    is $item->mask,   undef;
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: throws when redeploying without changesets' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);

    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    like exception { $rev->items( bl => 'TEST', tag => 'TEST' ) }, qr/No changesets for this sha/;
};

subtest 'items: throws when redeploying when sha is in several changesets' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);

    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $topic2 = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $topic2->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    like exception { $rev->items( bl => 'TEST', tag => 'TEST' ) }, qr/This sha is contained in more than one changeset/;
};

subtest 'items: cannot redeploy when no last job detected' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);

    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    like exception { $rev->items( bl => 'TEST', tag => 'TEST' ) }, qr/No last job detected.*Cannot redeploy/;
};

subtest 'items: cannot redeploy when last job detected but without bl_original' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);

    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
        );
    };

    like exception { $rev->items( bl => 'TEST', tag => 'TEST', project => 'Project' ) }, qr/No last job detected/;
};

subtest 'items: redeploy' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo =
      TestUtils->create_ci( 'GitRepository', repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);
    system("cd $repo_dir; echo 'foobar' >> NEW_FILE; git add .; git commit -a -m 'new'");
    my $sha2 = _git_last_commit($repo_dir);

    _git_tag( $repo_dir, 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        'Project' => {
                            current => $sha
                        }
                    }
                }
            }
        );
    };

    my @items = $rev->items( bl => 'TEST', tag => 'TEST', project => 'Project' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

done_testing;

sub _create_repo {
    my $dir = tempdir();

    system("cd $dir; git init");

    return $dir;
}

sub _set_timestamp {
    my ($timestamp) = @_;

    $ENV{GIT_AUTHOR_DATE}    = $timestamp;
    $ENV{GIT_COMMITTER_DATE} = $timestamp;
}

sub _git_commit {
    my ( $repo_dir, $timestamp ) = @_;

    _set_timestamp($timestamp) if $timestamp;

    my $text = TestUtils->random_string;

    system("cd $repo_dir; echo '$text' >> README; git add .; git commit -a -m 'new'");

    return ( _git_commits($repo_dir) )[0];
}

sub _git_last_commit {
    my ($repo_dir) = @_;

    return ( _git_commits($repo_dir) )[0];
}

sub _git_commits {
    my ($repo_dir) = @_;

    return map { chomp; $_ } `cd $repo_dir; git rev-list HEAD`;
}

sub _git_tag {
    my ( $repo_dir, $tag ) = @_;

    system("cd $repo_dir; git tag $tag");
}

sub _setup {
    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'Baseliner::Model::Jobs' );
}
