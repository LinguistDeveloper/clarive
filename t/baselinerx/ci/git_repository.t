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

subtest 'get_system_tags: returns system tags' => sub {
    _setup();
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'bl' );

    TestUtils->create_ci( 'bl', bl => '*' );
    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @tags = $repo->get_system_tags($repo);

    is_deeply \@tags, [qw/SUPPORT TEST/];
};

subtest 'get_system_tags: returns system tags in release mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', tags_mode => 'release' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ],
        moniker      => '3.0'
    );

    TestUtils->create_ci( 'bl', bl => '*' );
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

    is_deeply \@tags, [qw/SUPPORT 1.0-SUPPORT/];
};

subtest 'get_system_tags: skips inactive bls' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( tags_mode => 'bl' );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT', active => '0' );
    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'COMMON' );

    my @tags = $repo->get_system_tags($repo);

    is @tags, 2;
    is $tags[0], 'TEST';
    is $tags[1], 'COMMON';
};

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

subtest 'create_tags_service_handler: creates tags for another repo' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );
    TestUtils->create_ci( 'bl', bl => 'PROD' );

    my $repo = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo);

    BaselinerX::CI::GitRepository->create_tags_handler( undef, { repo => $repo->mid } );

    my @tags = TestGit->tags($repo);

    is_deeply [ sort @tags ], [qw/PROD TEST/];
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
        tag       => 'TEST',
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
        tag       => 'TEST',
        type      => 'promote',
        revisions => [$top_rev]
    );

    cmp_deeply $retval,
      {
        'previous' => ignore(),
        'current'  => ignore(),
        'output'   => re(qr/Updated tag 'TEST'/),
        'tag'      => 'TEST'
      };

    is $retval->{previous}->sha, $prev_rev->sha;
    is $retval->{current}->sha,  $top_rev->sha;
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

    $repo->update_baselines( job => {}, tag => 'TEST', type => 'demote', revisions => [$old_sha2_rev] );

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

    $repo->update_baselines( job => {}, tag => 'TEST', type => 'static', revisions => [$sha_rev] );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: does nothing when already there' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $repo->update_baselines( job => {}, tag => 'TEST', type => 'static', revisions => [ { sha => $sha } ] );

    my $tag_sha = TestGit->rev_parse( $repo, 'TEST' );

    is $tag_sha, $sha;
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
        revisions => [
            BaselinerX::CI::GitRevision->new( sha => $sha4 ),
            BaselinerX::CI::GitRevision->new( sha => $sha1 ),
            BaselinerX::CI::GitRevision->new( sha => $sha3 ),
            BaselinerX::CI::GitRevision->new( sha => $sha2 ),
            ( my $top = BaselinerX::CI::GitRevision->new( sha => $sha5 ) )
        ],
        tag => 'TEST'
    );

    is "$rev", "$top";
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
        revisions => [
            BaselinerX::CI::GitRevision->new( sha => $sha4 ),
            BaselinerX::CI::GitRevision->new( sha => $sha1 ),
            BaselinerX::CI::GitRevision->new( sha => $sha3 ),
            BaselinerX::CI::GitRevision->new( sha => $sha2 ),
            ( my $top = BaselinerX::CI::GitRevision->new( sha => $sha5 ) )
        ],
        tag => 'TEST'
    );

    is "$rev", "$top";
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
        revisions => [
            BaselinerX::CI::GitRevision->new( sha => $sha1 ),
            ( my $top = BaselinerX::CI::GitRevision->new( sha => $sha2 ) )
        ],
        tag => 'TEST'
    );

    is "$rev", "$top";
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
            revisions => [ BaselinerX::CI::GitRevision->new( sha => $sha5 ) ],
            tag       => 'TEST'
          )
    },
      qr/Cannot promote .* common history/;
};

subtest 'top_revision: returns bottom revision when in demote' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha1 = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = $repo->top_revision(
        revisions =>
          [ BaselinerX::CI::GitRevision->new( sha => $sha1 ), BaselinerX::CI::GitRevision->new( sha => $sha2 ) ],
        type => 'demote',
        tag  => 'TEST'
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
            revisions => [
                BaselinerX::CI::GitRevision->new( sha => $sha ),
                BaselinerX::CI::GitRevision->new( sha => $sha1 ),
                BaselinerX::CI::GitRevision->new( sha => $sha2 )
            ],
            type => 'demote',
            tag  => 'TEST'
          )
    },
      qr/Trying to demote all revisions/;
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
            revisions =>
              [ BaselinerX::CI::GitRevision->new( sha => $sha2 ), BaselinerX::CI::GitRevision->new( sha => $sha6 ) ],
            tag => 'TEST'
          )
    },
      qr/Not all commits are in .*? history/;
};

subtest 'top_revision: throws when no revisions passed' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    like exception { $repo->top_revision( revisions => [], tag => 'TEST' ) }, qr/Error: No revisions passed/;
};

subtest 'top_revision: throws when unknown sha' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', name => 'repo' );

    like exception {
        $repo->top_revision( revisions => [ BaselinerX::CI::GitRevision->new( sha => 'unknown' ) ], tag => 'TEST' )
    },
      qr/Error: revision `unknown` not found in repository repo/;
};

subtest 'top_revision: throws when unknown tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff', name => 'repo' );

    my $sha = TestGit->commit($repo);

    like exception {
        $repo->top_revision( revisions => [ BaselinerX::CI::GitRevision->new( sha => $sha ) ], tag => 'UNKNOWN' )
    },
      qr/Error: tag `UNKNOWN` not found in repository repo/;
};

subtest 'group_items_for_revisions: returns top revision items' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $ci = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $ci->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: throws when trying to redeploy and no last job' => sub {
    _setup();

    my $project = TestUtils->create_ci( 'project', name => 'Project' );
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $ci = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $ci->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    like
      exception { $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => 'TEST', project => $project ) }
    , qr/Cannot redeploy/;
};

subtest 'group_items_for_revisions: throws when redeploy but last job is invalid' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
            }
        );
    };

    like
      exception { $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => 'TEST', project => $project ) }
    , qr/Cannot redeploy/;
};

subtest 'group_items_for_revisions: allows redeploy when last job found' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $sha2->mid,
                            previous => $sha,
                        }
                    }
                }
            }
        );
    };

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: allows redeploy when last job found and release mode' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => '1.0-TEST' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $sha2->mid,
                            previous => BaselinerX::CI::GitRevision->new(sha => $sha->sha),
                            tag => '1.0-TEST'
                        }
                    }
                }
            }
        );
    };

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => '1.0-TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: fails redeploy in release mode when tag does not match' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => '1.0-TEST' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => $sha2, repo => $repo );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $sha2->mid,
                            previous => $sha,
                            tag => '2.0-TEST'
                        }
                    }
                }
            }
        );
    };

    like exception {
        $repo->group_items_for_revisions(
            revisions => [ $sha, $sha2 ],
            bl        => 'TEST',
            tag       => '1.0-TEST',
            project   => $project
          )
    },
      qr/Cannot redeploy/
};

subtest 'group_items_for_revisions: allows redeploy with branch' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => 'master', repo => $repo );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $sha2->mid,
                            previous => $sha,
                        }
                    }
                }
            }
        );
    };

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: allows redeploy with tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    TestGit->tag( $repo, tag => 'TO-DEPLOY' );

    $sha  = TestUtils->create_ci( 'GitRevision', sha => $sha,  repo => $repo );
    $sha2 = TestUtils->create_ci( 'GitRevision', sha => 'TO-DEPLOY', repo => $repo );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $sha2->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $sha2->mid,
                            previous => $sha,
                        }
                    }
                }
            }
        );
    };

    my @items = $repo->group_items_for_revisions( revisions => [ $sha, $sha2 ], bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->path,   '/README';
};

subtest 'group_items_for_revisions: allows redeploy after redeploy' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', tags_mode => 'project', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $sha);

    my $top_sha = TestGit->commit( $repo, file => 'NEW_FILE' );
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $top_sha);

    TestGit->tag( $repo, tag => 'TEST' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $top_rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture_merged {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            endtime      => '2015-01-01 00:00:00',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $top_rev,
                            previous => $rev,
                        }
                    }
                }
            }
        );
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            endtime      => '2015-01-01 00:00:01',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $top_rev,
                            previous => $top_rev,
                        }
                    }
                }
            }
        );
    };

    my @items = $repo->group_items_for_revisions( revisions => [ $top_rev ], bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $top_rev->sha;
    is $item->path,   '/NEW_FILE';
};

subtest 'checkout: throws when unknown tag' => sub {
    _setup();

    my $dir = tempdir();

    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    like exception { $repo->checkout( dir => $dir, tag => '213' ) }, qr/Error: tag `213` not found in repository/;
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

    my $sha = TestGit->commit($repo, content => 'hello');
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo, content => 'bye');

    my $retval = $repo->checkout( dir => $dir, tag => 'TEST' );

    cmp_deeply $retval,
      {
        'ls'     => [ re(qr/100644 blob ce01362\s+6\s+README/) ],
        'output' => undef
      };
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

    my @commits = $repo->commits_for_branch( branch => 'master', project => 'test_project' );
    is scalar @commits, 3;
    like $commits[0], qr/^[a-z0-9]{40} third$/;
    like $commits[1], qr/^[a-z0-9]{40} second$/;
    like $commits[2], qr/^[a-z0-9]{40} first$/;
};

subtest 'commits_for_branch: gets tag from bl individual commits repository' => sub {
    _setup();

    my $repo =
      TestUtils->create_ci_GitRepository( exclude => [ '^new', 'master' ], include => 'new2', revision_mode => 'show' );
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

subtest 'commits_for_branch: shows all commits when page_size is bigger' => sub {
    _setup();
    my $tag       = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository();

    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        page            => 1,
        page_size       => 40,
        show_commit_tag => 1,
        project         => 'test_project'
    );
    is scalar @commits, 4;
};

subtest 'commits_for_branch: hides tagged commits when show_commit_tag=0' => sub {
    _setup();

    my $tag       = 'tag_1';

    my $repo = TestUtils->create_ci_GitRepository();

    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        project         => 'test_project',
        page            => 1,
        page_size       => 40,
        show_commit_tag => 0
    );
    is scalar @commits, 3;
};

subtest 'commits_for_branch: paging second page with show_commit_tag=0' => sub {
    _setup();

    my $tag       = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository();
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        project         => 'test_project',
        page            => 2,
        page_size       => 2,
        show_commit_tag => 0
    );
    is scalar @commits, 1;
};

subtest 'commits_for_branch: paging second page with show_commit_tag=0 and page_size>available commits' => sub {
    _setup();

    my $tag  = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository();
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        project         => 'test_project',
        page            => 2,
        page_size       => 40,
        show_commit_tag => 0
    );
    is scalar @commits, 0;
};

subtest 'commits_for_branch: paging all commits with show_commit_tag=1 and revision_mode set to show' => sub {
    _setup();

    my $tag = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'show' );
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        page            => 1,
        page_size       => 40,
        show_commit_tag => 1,
        project         => 'test_project'
    );
    is scalar @commits, 4;
};

subtest 'commits_for_branch: paging all commits with show_commit_tag=0 and revision_mode set to show' => sub {
    _setup();

    my $tag       = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'show' );
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        project         => 'test_project',
        page            => 1,
        page_size       => 40,
        show_commit_tag => 0
    );
    is scalar @commits, 4;
};

subtest 'commits_for_branch: paging second page with show_commit_tag=0 and revision_mode set to show' => sub {
    _setup();

    my $tag       = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'show' );
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        project         => 'test_project',
        page            => 2,
        page_size       => 2,
        show_commit_tag => 0
    );
    is scalar @commits, 2;
};

subtest
'commits_for_branch: paging second page with show_commit_tag=0 and page_size>available commits and revision_mode set to show'
  => sub {
    _setup();
    my $tag       = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository( revision_mode => 'show' );
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    BaselinerX::CI::bl->new( bl => $tag )->save;
    my @commits = $repo->commits_for_branch(
        branch          => 'master',
        project         => 'test_project',
        page            => 2,
        page_size       => 40,
        show_commit_tag => 0
    );
    is scalar @commits, 4;
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
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Jobs',
        'Baseliner::Model::Rules',
    );

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;
}
