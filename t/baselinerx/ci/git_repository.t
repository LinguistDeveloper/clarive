use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup; }

use TestUtils;
use TestGit;

use Capture::Tiny qw(capture_merged);
use BaselinerX::CI::project;

use_ok 'BaselinerX::CI::GitRepository';

subtest 'create_tags_service_handler: does nothing when no bls' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    $repo->create_tags_handler( undef, {} );

    my @tags = TestGit->tags($repo);

    is_deeply \@tags, [];
};

subtest 'create_tags_service_handler: skips common bl' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => '*' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    $repo->create_tags_handler( undef, {} );

    my @tags = TestGit->tags($repo);

    is_deeply \@tags, [];
};

subtest 'create_tags_service_handler: creates tags for every bl' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    $repo->create_tags_handler( undef, {} );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/PROD TEST/];
};

subtest 'create_tags_service_handler: returns command output' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    is $repo->create_tags_handler( undef, {} ), '';
};

subtest 'create_tags_service_handler: creates tags for matching bls' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    $repo->create_tags_handler( undef, { tag_filter => 'TEST' } );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/TEST/];
};

subtest 'create_tags_service_handler: creates tags for the first commit' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    my @refs = TestGit->commits($repo);

    $repo->create_tags_handler( undef, {} );

    my $ref = TestGit->rev_parse( $repo, 'TEST' );

    is $ref, $refs[-1];
};

subtest 'create_tags_service_handler: creates tags for specific ref' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    my @refs = TestGit->commits($repo);

    $repo->create_tags_handler( undef, { ref => $refs[0] } );

    my $ref = TestGit->rev_parse( $repo, 'TEST' );

    is $ref, $refs[0];
};

subtest 'create_tags_service_handler: detects existing tags by default' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    TestGit->commit($repo);

    my @refs = TestGit->commits($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    $repo->create_tags_handler( undef, {} );

    my $ref = TestGit->rev_parse( $repo, 'TEST' );

    is $ref, $refs[0];
};

subtest 'create_tags_service_handler: overwrites existing tags when specified' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    TestGit->commit($repo);

    my @refs = TestGit->commits($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    $repo->create_tags_handler( undef, { existing => 'no-detect' } );

    my $ref = TestGit->rev_parse( $repo, 'TEST' );

    is $ref, $refs[-1];
};

subtest 'create_tags_service_handler: creates project tags' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );
    TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', name => 'project', repositories => [ $repo->mid ] );

    $repo->create_tags_handler( undef, {} );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/project-PROD project-TEST/];
};

subtest 'create_tags_service_handler: filters by tags when projects' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );
    TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', name => 'project', repositories => [ $repo->mid ] );

    $repo->create_tags_handler( undef, { tag_filter => 'project-TEST' } );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/project-TEST/];
};

subtest 'update_baselines: moves baselines up in promote' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha = TestGit->commit($repo);

    $repo->update_baselines( bl => 'TEST', type => 'promote', revisions => [ { sha => $sha } ] );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: returns refs' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $prev_sha = TestGit->commit($repo);
    my $prev_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $prev_sha);
    TestGit->tag( $repo, tag => 'TEST' );

    my $top_sha = TestGit->commit($repo);
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $top_sha);

    my $retval = $repo->update_baselines( bl => 'TEST', type => 'promote', revisions => [ { sha => $top_sha } ] );

    cmp_deeply $retval,
      {
        '*' => {
            'previous' => ignore(),
            'current'  => ignore(),
            'output'   => re(qr/Updated tag 'TEST'/)
        }
      };

    is $retval->{'*'}->{previous}->sha, $prev_rev->sha;
    is $retval->{'*'}->{current}->sha, $top_rev->sha;
};

subtest 'update_baselines: moves baselines down in demote' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $old_sha  = TestGit->commit($repo);
    my $old_sha2 = TestGit->commit($repo);

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $repo->update_baselines( bl => 'TEST', type => 'demote', revisions => [ { sha => $old_sha2 }, { sha => $sha } ] );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $old_sha;
};

subtest 'update_baselines: moves baselines up in static' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha = TestGit->commit($repo);

    $repo->update_baselines( bl => 'TEST', type => 'static', revisions => [ { sha => $sha } ] );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: moves baselines to specific ref' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha = TestGit->commit($repo);

    $repo->update_baselines( bl => 'TEST', type => 'static', revisions => [], ref => $sha );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: does nothing when already there' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $repo->update_baselines( bl => 'TEST', type => 'static', revisions => [], ref => $sha );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: throws when tags_mode is project but no projects' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    like exception { $repo->update_baselines( bl => 'TEST', type => 'static', revisions => [], ref => $sha ) },
      qr/Projects are required/;
};

subtest 'update_baselines: updates tags for every project' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $project = TestUtils->create_ci( 'project', name => 'project-with-dashes', repositories => [ $repo->mid ] );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'project-with-dashes-TEST' );

    my $new_sha = TestGit->commit($repo);

    $repo->update_baselines(
        job       => { projects => [ $project ] },
        bl        => 'TEST',
        type      => 'promote',
        revisions => [],
        ref       => $new_sha
    );

    my $tag_sha = TestGit->rev_parse( $repo, 'project-with-dashes-TEST' );

    is $tag_sha, $new_sha;
};

subtest 'update_baselines: returns correct results' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $project = TestUtils->create_ci( 'project', name => 'project-with-dashes', repositories => [ $repo->mid ] );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', sha => $sha, repo => $repo);
    TestGit->tag( $repo, tag => 'project-with-dashes-TEST' );
    my $top_sha = TestGit->commit($repo);
    my $top_rev = TestUtils->create_ci('GitRevision', sha => $top_sha, repo => $repo);

    my $retval = $repo->update_baselines(
        job       => { projects => [ $project ] },
        bl        => 'TEST',
        type      => 'promote',
        revisions => [],
        ref       => $top_sha
    );

    cmp_deeply $retval,
      {
        $project->mid => {
            previous => ignore(),
            current  => ignore(),
            output   => re(qr/Updated tag 'project-with-dashes-TEST'/)
        }
      };

    is $retval->{$project->mid}->{previous}->sha, $rev->sha;
    is $retval->{$project->mid}->{current}->sha, $top_rev->sha;
};

subtest 'update_baselines: updates tags only for project related to the repository' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $project = TestUtils->create_ci( 'project', name => 'project', repositories => [ $repo->mid ] );
    my $other_project = TestUtils->create_ci( 'project', name => 'other', repositories => [] );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'project-TEST' );

    TestGit->commit($repo);

    $repo->update_baselines(
        job =>
          { projects => [ $project, $other_project ] },
        bl        => 'TEST',
        type      => 'static',
        revisions => [],
        ref       => $sha
    );

    like capture_merged { TestGit->rev_parse( $repo, 'other-TEST' ) }, qr/unknown revision/;
};

subtest 'top_revision: returns top revision from random commits' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha3 = TestGit->commit($repo);
    my $sha4 = TestGit->commit($repo);
    my $sha5 = TestGit->commit($repo);

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha4 }, { sha => $sha1 }, { sha => $sha3 }, { sha => $sha2 }, { sha => $sha5 } ],
        tag       => 'TEST'
    );

    is_deeply $rev, { sha => $sha5 };
};

subtest 'top_revision: returns same top revision when already on top' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha1 }, { sha => $sha2 } ],
        tag       => 'TEST'
    );

    is_deeply $rev, { sha => $sha2 };
};

subtest 'top_revision: returns tag sha when nowhere to move' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha1 } ],
        tag       => 'TEST'
    );

    is $rev->sha, $sha2;
};

subtest 'top_revision: throws when tag has not same history' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    TestGit->create_branch( $repo, branch => 'another' );
    my $sha3 = TestGit->commit($repo);

    TestGit->switch_branch( $repo, 'master' );
    my $sha4 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    TestGit->commit($repo);

    TestGit->switch_branch( $repo, 'another' );
    my $sha5 = TestGit->commit($repo);

    like exception {
        $repo->top_revision(
            revisions => [ { sha => $sha5 } ],
            tag       => 'TEST'
          )
    }, qr/Cannot promote .* common history/;
};

subtest 'top_revision: returns bottom revision when in demote' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha1 }, { sha => $sha2 } ],
        type      => 'demote',
        tag       => 'TEST'
    );

    is_deeply $rev, { sha => $sha1 };
};

subtest 'top_revision: throws when demoting everything' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    like exception {
        $repo->top_revision(
            revisions => [ { sha => $sha }, { sha => $sha1 }, { sha => $sha2 } ],
            type      => 'demote',
            tag       => 'TEST'
          )
    }, qr/Trying to demote all revisions/;
};

subtest 'top_revision: throws when one of the commits has not same history' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);

    TestGit->create_branch( $repo, branch => 'another' );
    my $sha2 = TestGit->commit($repo);
    my $sha3 = TestGit->commit($repo);

    TestGit->switch_branch( $repo, 'master' );
    my $sha4 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha5 = TestGit->commit($repo);
    my $sha6 = TestGit->commit($repo);

    like exception {
        $repo->top_revision(
            revisions => [ { sha => $sha2 }, { sha => $sha6 } ],
            tag       => 'TEST'
          )
    }, qr/Not all commits are in .*? history/;
};

subtest 'top_revision: throws when no revisions passed' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    like exception { $repo->top_revision( revisions => [], tag => 'TEST' ) }, qr/Error: No revisions passed/;
};

subtest 'top_revision: throws when unknown sha' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', name => 'repo' );

    like exception { $repo->top_revision( revisions => [ { sha => 'unknown' } ], tag => 'TEST' ) },
      qr/Error: revision `unknown` not found in repository repo/;
};

subtest 'top_revision: throws when unknown tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', name => 'repo' );

    my $sha = TestGit->commit($repo);

    like exception { $repo->top_revision( revisions => [ { sha => $sha } ], tag => 'UNKNOWN' ) },
      qr/Error: tag `UNKNOWN` not found in repository repo/;
};

subtest 'group_items_for_revisions: returns top revision items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $ci = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $ci->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: throws when no project in project tags_mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    like exception { $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], tag => 'TEST' ) },
      qr/project is required/;
};

subtest 'group_items_for_revisions: returns top revision items in project mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'Project-TEST' );
    my $sha2 = TestGit->commit($repo);

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $ci = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $ci->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], tag => 'TEST', project => 'Project' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'checkout: checkouts items into directory' => sub {
    _setup();

    my $dir = tempdir();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    $repo->checkout( dir => $dir, tag => 'TEST' );

    opendir( my $dh, $dir ) || die "can't opendir $dir $!";
    my @files = grep { !/^\./ } readdir($dh);
    closedir $dh;

    is_deeply \@files, ['README'];
};

subtest 'checkout: returns checked out items' => sub {
    _setup();

    my $dir = tempdir();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    my $retval = $repo->checkout( dir => $dir, tag => 'TEST' );

    cmp_deeply $retval,
      {
        'ls'     => [ re(qr/100644 blob f599e28\s+3\s+README/) ],
        'output' => undef
      };
};

subtest 'checkout: throws when no project passed in project tags_mode' => sub {
    _setup();

    my $dir = tempdir();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'Project-TEST' );
    my $sha2 = TestGit->commit($repo);

    like exception { $repo->checkout( dir => $dir, tag => 'Project-TEST' ) }, qr/project required/;
};

subtest 'checkout: checkouts items into directory with project tag_mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'Project-TEST' );
    my $sha2 = TestGit->commit($repo);

    my $dir = tempdir();

    $repo->checkout( dir => $dir, tag => 'TEST', project => 'Project' );

    opendir( my $dh, $dir ) || die "can't opendir $dir $!";
    my @files = grep { !/^\./ } readdir($dh);
    closedir $dh;

    is_deeply \@files, ['README'];
};

subtest 'list_branches: returns branches' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit( $repo, message => 'my change' );

    my @branches = $repo->list_branches( project => 'Project' );

    is scalar @branches, 1;

    is $branches[0]->name, 'master';
    like $branches[0]->head->commit->message, qr/my change/;
};

subtest 'list_branches: excludes branch names' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => 'new' );
    TestGit->commit( $repo, message => 'my change' );

    TestGit->create_branch( $repo, branch => 'new' );

    my @branches = $repo->list_branches( project => 'Project' );

    is scalar @branches, 1;

    is $branches[0]->name, 'master';
};

subtest 'list_branches: includes branch names' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2' );
    TestGit->commit( $repo, message => 'my change' );

    TestGit->create_branch( $repo, branch => 'new' );
    TestGit->create_branch( $repo, branch => 'new2' );

    my @branches = $repo->list_branches( project => 'Project' );

    is scalar @branches, 1;

    is $branches[0]->name, 'new2';
};

subtest 'commits_for_branch: returns commits by tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit( $repo, message => 'initial' );
    TestGit->commit( $repo, message => 'first' );
    TestGit->tag( $repo, tag => 'TEST' );

    TestGit->commit( $repo, message => 'second' );
    TestGit->commit( $repo, message => 'third' );

    my @commits = $repo->commits_for_branch( tag => 'TEST', branch => 'master' );
    is scalar @commits, 3;
    like $commits[0], qr/^[a-z0-9]{40} third$/;
    like $commits[1], qr/^[a-z0-9]{40} second$/;
    like $commits[2], qr/^[a-z0-9]{40} first$/;
};

subtest 'commits_for_branch: get tag from bl when not present' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2' );
    TestGit->commit( $repo, message => 'initial' );
    TestGit->commit( $repo, message => 'first' );
    TestGit->tag( $repo, tag => 'TEST' );

    TestGit->commit( $repo, message => 'second' );
    TestGit->commit( $repo, message => 'third' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @commits = $repo->commits_for_branch( branch => 'master' );
    is scalar @commits, 3;
    like $commits[0], qr/^[a-z0-9]{40} third$/;
    like $commits[1], qr/^[a-z0-9]{40} second$/;
    like $commits[2], qr/^[a-z0-9]{40} first$/;
};

subtest 'commits_for_branch: throws when no tag present' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2' );

    like exception { $repo->commits_for_branch( tag => 'UNKNOWN', branch => 'master' ) }, qr/could not find tag/;
};

subtest 'commits_for_branch: throws when no tags present' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2' );

    like exception { $repo->commits_for_branch( branch => 'master' ) }, qr/could not find tag/;
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );
}
