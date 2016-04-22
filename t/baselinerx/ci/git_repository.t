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

    my $project = _create_ci_project( repositories => [ $repo->mid ] );

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

    my $project = _create_ci_project( repositories => [ $repo->mid ] );

    $repo->create_tags_handler( undef, { tag_filter => 'project-TEST' } );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/project-TEST/];
};

subtest 'create_tags_service_handler: creates release and project tags' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'release,project' );
    TestGit->commit($repo);

    my $project  = _create_ci_project( repositories => [ $repo->mid ] );
    my $project2 = _create_ci_project( moniker      => 'project2' );

    my $status_new       = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status_not_final = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_final     = TestUtils->create_ci( 'status', name => 'Closed',      type => 'F' );

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = _create_release_form();

    my $id_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_rule,
    );
    TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'New Release',
        status          => $status_new,
        release_version => '1.0',
        project         => $project,
        username        => $user->name,
    );
    TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'Release',
        status          => $status_not_final,
        release_version => '1.1',
        project         => [ $project, $project2 ],
        username        => $user->name,
    );
    TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'Release From Another Project',
        status          => $status_not_final,
        release_version => '9.9',
        project         => $project2,
        username        => $user->name,
    );
    TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'Closed Release',
        status          => $status_final,
        release_version => '0.9',
        project         => $project,
        username        => $user->name,
    );

    $repo->create_tags_handler( undef, {} );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/1.1-PROD 1.1-TEST project-PROD project-TEST/];
};

subtest 'update_baselines: moves baselines up in promote' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha = TestGit->commit($repo);
    my $sha_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo->update_baselines(
        job       => {},
        bl        => 'TEST',
        type      => 'promote',
        revisions => [$sha_rev]
    );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: returns refs' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $prev_sha = TestGit->commit($repo);
    my $prev_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $prev_sha );
    TestGit->tag( $repo, tag => 'TEST' );

    my $top_sha = TestGit->commit($repo);
    my $top_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $top_sha );

    my $retval = $repo->update_baselines(
        job       => {},
        bl        => 'TEST',
        type      => 'promote',
        revisions => [$top_rev]
    );

    cmp_deeply $retval,
      {
        '*' => {
            'previous' => ignore(),
            'current'  => ignore(),
            'output'   => re(qr/Updated tag 'TEST'/)
        }
      };

    is $retval->{'*'}->{previous}->sha, $prev_rev->sha;
    is $retval->{'*'}->{current}->sha,  $top_rev->sha;
};

subtest 'update_baselines: moves baselines down in demote' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $old_sha  = TestGit->commit($repo);
    my $old_sha2 = TestGit->commit($repo);

    my $old_sha2_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $old_sha2 );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $repo->update_baselines( job => {}, bl => 'TEST', type => 'demote', revisions => [$old_sha2_rev] );

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
    my $sha_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );

    $repo->update_baselines( job => {}, bl => 'TEST', type => 'static', revisions => [$sha_rev] );

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

    $repo->update_baselines( job => {}, bl => 'TEST', type => 'static', revisions => [], ref => $sha );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: does nothing when already there' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $repo->update_baselines( job => {}, bl => 'TEST', type => 'static', revisions => [], ref => $sha );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: throws when tags_mode is project but no projects' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    like
      exception { $repo->update_baselines( job => {}, bl => 'TEST', type => 'static', revisions => [], ref => $sha ) },
      qr/Projects are required/;
};

subtest 'update_baselines: updates tags for every project' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $project = _create_ci_project( moniker => 'project-with-dashes', repositories => [ $repo->mid ] );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'project-with-dashes-TEST' );

    my $new_sha = TestGit->commit($repo);

    $repo->update_baselines(
        job       => { projects => [$project] },
        bl        => 'TEST',
        type      => 'promote',
        revisions => [],
        ref       => $new_sha
    );

    my $tag_sha = TestGit->rev_parse( $repo, 'project-with-dashes-TEST' );

    is $tag_sha, $new_sha;
};

subtest 'update_baselines: updates tags for every release' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'release,project' );

    my $project = _create_ci_project( moniker => 'project', repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => '1.0-TEST' );

    my $new_sha = TestGit->commit($repo);
    my $new_sha_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $new_sha );

    my $id_release_rule = _create_release_form();

    my $id_release_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_release_rule,
    );
    my $release_mid = TestSetup->create_topic(
        id_category     => $id_release_category,
        title           => 'New Release',
        release_version => '1.0',
        project         => $project,
    );

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category(
        name       => 'Changeset',
        is_release => '1',
        id_rule    => $id_changeset_rule,
    );

    TestSetup->create_topic(
        id_category => $id_changeset_category,
        title       => 'Changeset #1',
        project     => $project,
        release     => $release_mid,
        revisions   => [ $new_sha_rev->mid ],
        username    => $user->name,
    );

    $repo->update_baselines(
        job       => { projects => [$project] },
        bl        => 'TEST',
        type      => 'promote',
        revisions => [$new_sha_rev],
    );

    my $tag_sha = TestGit->rev_parse( $repo, '1.0-TEST' );

    is $tag_sha, $new_sha;
};

subtest 'update_baselines: returns correct results' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $project = _create_ci_project( moniker => 'project-with-dashes', repositories => [ $repo->mid ] );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci( 'GitRevision', sha => $sha, repo => $repo );
    TestGit->tag( $repo, tag => 'project-with-dashes-TEST' );
    my $top_sha = TestGit->commit($repo);
    my $top_rev = TestUtils->create_ci( 'GitRevision', sha => $top_sha, repo => $repo );

    my $retval = $repo->update_baselines(
        job       => { projects => [$project] },
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

    is $retval->{ $project->mid }->{previous}->sha, $rev->sha;
    is $retval->{ $project->mid }->{current}->sha,  $top_rev->sha;
};

subtest 'update_baselines: updates tags only for project related to the repository' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'project' );

    my $project       = _create_ci_project( repositories => [ $repo->mid ] );
    my $other_project = _create_ci_project( moniker      => 'other' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'project-TEST' );

    TestGit->commit($repo);

    $repo->update_baselines(
        job       => { projects => [ $project, $other_project ] },
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

    is $rev->sha, $sha5;
};

subtest 'top_revision: returns top revision ignoring dates' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit( $repo, datetime => '2015-01-01 00:00:00' );
    my $sha1 = TestGit->commit( $repo, datetime => '2015-01-02 00:00:00' );
    my $sha2 = TestGit->commit( $repo, datetime => '2015-01-03 00:00:00' );
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha3 = TestGit->commit( $repo, datetime => '2015-01-04 00:00:00' );
    my $sha4 = TestGit->commit( $repo, datetime => '2015-01-05 00:00:00' );
    my $sha5 = TestGit->commit( $repo, datetime => '2015-01-01 00:00:00' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha4 }, { sha => $sha1 }, { sha => $sha3 }, { sha => $sha2 }, { sha => $sha5 } ],
        tag       => 'TEST'
    );

    is $rev->sha, $sha5;
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

    is $rev->sha, $sha2;
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

    is $rev->sha, $sha;
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

subtest 'top_revision: returns resolved sha when passing a ref' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha3 = TestGit->commit($repo);
    my $sha4 = TestGit->commit($repo);
    my $sha5 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'top' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha4 }, { sha => $sha1 }, { sha => $sha3 }, { sha => $sha2 }, { sha => 'top' } ],
        tag       => 'TEST'
    );

    is $rev->sha, $sha5;
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

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST' );
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

    like exception { $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST' ) },
      qr/prefix is required/;
};

subtest 'group_items_for_revisions: returns top revision items in project mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $project = _create_ci_project( repositories => [ $repo->mid ] );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'project-TEST' );
    my $sha2 = TestGit->commit($repo);

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $ci = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $ci->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: returns top revision items in release,project mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'release,project' );

    my $project = _create_ci_project( repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_release_rule = _create_release_form();

    my $id_release_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_release_rule,
    );
    my $release_mid = TestSetup->create_topic(
        id_category     => $id_release_category,
        title           => 'New Release',
        release_version => '1.0',
        project         => $project,
        username        => $user->name,
    );

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category(
        name       => 'Changeset',
        is_release => '1',
        id_rule    => $id_changeset_rule,
    );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => '1.0-TEST' );
    my $sha2 = TestGit->commit($repo);

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    TestSetup->create_topic(
        id_category => $id_changeset_category,
        title       => 'Changeset #1',
        project     => $project,
        release     => $release_mid,
        revisions   => [ $sha->mid, $sha2->mid ],
        username    => $user->name,
    );

    my $ci = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $ci->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'checkout: throws when unknown bl' => sub {
    _setup();

    my $dir = tempdir();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    like exception { $repo->checkout( dir => $dir, bl => '213' ) }, qr/Error: tag `213` not found in repository/;
};

subtest 'checkout: checkouts items into directory' => sub {
    _setup();

    my $dir = tempdir();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    $repo->checkout( dir => $dir, bl => 'TEST' );

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

    my $retval = $repo->checkout( dir => $dir, bl => 'TEST' );

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
    TestGit->tag( $repo, tag => 'project-TEST' );
    my $sha2 = TestGit->commit($repo);

    like exception { $repo->checkout( dir => $dir, bl => 'project-TEST' ) }, qr/prefix is required/;
};

subtest 'checkout: checkouts items into directory with project tag_mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $project = _create_ci_project( repositories => [ $repo->mid ] );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'project-TEST' );
    my $sha2 = TestGit->commit($repo);

    my $dir = tempdir();

    $repo->checkout( dir => $dir, bl => 'TEST', project => $project );

    opendir( my $dh, $dir ) || die "can't opendir $dir $!";
    my @files = grep { !/^\./ } readdir($dh);
    closedir $dh;

    is_deeply \@files, ['README'];
};

subtest 'checkout: checkouts items into directory with release,project tag_mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'release,project' );

    my $project = _create_ci_project( repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => '1.0-TEST' );
    my $sha2 = TestGit->commit($repo);

    my $sha_rev  = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );
    my $sha2_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my $id_release_rule = _create_release_form();

    my $id_release_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_release_rule,
    );
    my $release_mid = TestSetup->create_topic(
        id_category     => $id_release_category,
        title           => 'New Release',
        release_version => '1.0',
        project         => $project,
        username        => $user->name,
    );

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category(
        name       => 'Changeset',
        is_release => '1',
        id_rule    => $id_changeset_rule,
    );

    TestSetup->create_topic(
        id_category => $id_changeset_category,
        title       => 'Changeset #1',
        project     => $project,
        release     => $release_mid,
        revisions   => [ $sha_rev->mid, $sha2_rev->mid ],
        username    => $user->name
    );

    my $dir = tempdir();

    $repo->checkout( dir => $dir, bl => 'TEST', project => $project, revisions => [ $sha_rev, $sha2_rev ] );

    opendir( my $dh, $dir ) || die "can't opendir $dir $!";
    my @files = grep { !/^\./ } readdir($dh);
    closedir $dh;

    is_deeply \@files, ['README'];
};

subtest 'checkout: checkouts items into directory with release,project tag_mode and release is an arrayref' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'release,project' );

    my $project = _create_ci_project( repositories => [ $repo->mid ] );
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => '1.0-TEST' );
    my $sha2 = TestGit->commit($repo);

    my $sha_rev  = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha );
    my $sha2_rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    my $id_release_rule = _create_release_form();

    my $id_release_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_release_rule,
    );
    my $release_mid = TestSetup->create_topic(
        id_category     => $id_release_category,
        title           => 'New Release',
        release_version => '1.0',
        project         => $project,
        username        => $user->username,
    );

    my $id_changeset_rule = _create_changeset_form();

    my $id_changeset_category = TestSetup->create_category(
        name       => 'Changeset',
        is_release => '1',
        id_rule    => $id_changeset_rule,
    );

    TestSetup->create_topic(
        id_category => $id_changeset_category,
        title       => 'Changeset #1',
        project     => $project,
        release     => [$release_mid],
        revisions   => [ $sha_rev->mid, $sha2_rev->mid ]
    );

    my $dir = tempdir();

    $repo->checkout( dir => $dir, bl => 'TEST', project => $project, revisions => [ $sha_rev, $sha2_rev ] );

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

subtest 'commits_for_branch: gets tag from bl diff repository' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2' );
    TestGit->commit( $repo, message => 'initial' );
    TestGit->commit( $repo, message => 'first' );
    TestGit->tag( $repo, tag => 'TEST' );

    TestGit->commit( $repo, message => 'second' );
    TestGit->commit( $repo, message => 'third' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @commits = $repo->commits_for_branch( branch => 'master', project => '' );
    is scalar @commits, 3;
    like $commits[0], qr/^[a-z0-9]{40} third$/;
    like $commits[1], qr/^[a-z0-9]{40} second$/;
    like $commits[2], qr/^[a-z0-9]{40} first$/;
};

subtest 'commits_for_branch: gets tag from bl individual commits repository' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2', revision_mode=>'show' );
    TestGit->commit( $repo, message => 'initial' );
    TestGit->commit( $repo, message => 'first' );
    TestGit->tag( $repo, tag => 'TEST' );

    TestGit->commit( $repo, message => 'second' );
    TestGit->commit( $repo, message => 'third' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @commits = $repo->commits_for_branch( branch => 'master', project => '' );
    is scalar @commits, 4;
    like $commits[0], qr/^[a-z0-9]{40} third$/;
    like $commits[1], qr/^[a-z0-9]{40} second$/;
    like $commits[2], qr/^[a-z0-9]{40} first$/;
    like $commits[3], qr/^[a-z0-9]{40} initial$/;
};

subtest 'get_system_tags: get tags without project just bl ' => sub {
    _setup();
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'bl' );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );
    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'COMUN' );

    my @tags = $repo->get_system_tags($repo);

    is_deeply \@tags, [qw/SUPPORT TEST COMUN/];
};

subtest 'get_system_tags: get tags with project' => sub {
    _setup();
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'project' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ],
        moniker      => '1.0'
    );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );

    my @tags = $repo->get_system_tags($repo);

    is_deeply \@tags, [qw/1.0-SUPPORT/];
};

subtest 'get_system_tags: get tags with release,project but without release' => sub {
    _setup();
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'release,project' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ],
        moniker      => '1.0'
    );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );

    my @tags = $repo->get_system_tags($repo);

    is_deeply \@tags, [qw/1.0-SUPPORT/];
};

subtest 'get_system_tags: get tags with release,project' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'release,project' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ],
        moniker      => '3.0'
    );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );

    my $status              = TestUtils->create_ci( 'status', name => 'New', type => 'G' );
    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        is_release => '1',
        name       => 'Release',
        id_rule    => $id_release_rule,
        id_status  => $status->mid
    );

    my $id_role     = TestSetup->create_role();
    my $user        = TestSetup->create_user( id_role => $id_role, project => $project );
    my $release_mid = TestSetup->create_topic(
        project         => $project,
        id_category     => $id_release_category,
        title           => 'Release 0.1',
        status          => $status,
        username        => $user->name,
        release_version => '1.0'
    );

    my @tags = $repo->get_system_tags($repo);

    is_deeply \@tags, [qw/3.0-SUPPORT 1.0-SUPPORT/];
};

done_testing;

sub _create_ci_project {
    return TestUtils->create_ci( 'project', name => 'Project', moniker => 'project', @_ );
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "status_new",
                        "fieldletType" => "fieldlet.system.status_new",
                        "name_field"   => "Status",
                    },
                    "key" => "fieldlet.system.status_new",
                    text  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "release_version",
                        "fieldletType" => "fieldlet.system.release_version",
                        "name_field"   => "Version",
                    },
                    "key" => "fieldlet.system.release_version",
                    text  => 'Version',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "Project",
                    },
                    "key" => "fieldlet.system.projects",
                    text  => 'Project',
                }
            },
        ]
    );
}

sub _create_changeset_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "status_new",
                        "fieldletType" => "fieldlet.system.status_new",
                        "name_field"   => "Status",
                    },
                    "key" => "fieldlet.system.status_new",
                    text  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "release",
                        "fieldletType" => "fieldlet.system.release",
                        "name_field"   => "Release",
                    },
                    "key" => "fieldlet.system.release",
                    text  => 'Release',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "revisions",
                        "fieldletType" => "fieldlet.system.revisions",
                        "name_field"   => "Revisions",
                    },
                    "key" => "fieldlet.system.revisions",
                    text  => 'Revisions',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "Project",
                    },
                    "key" => "fieldlet.system.projects",
                    text  => 'Project',
                }
            },
        ]
    );
}

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',          'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
    );

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;
}
