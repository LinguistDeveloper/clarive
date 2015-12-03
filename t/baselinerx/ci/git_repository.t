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

use Capture::Tiny qw(capture_merged);
use BaselinerX::CI::project;

use_ok 'BaselinerX::CI::GitRepository';

subtest 'create_tags_service_handler: does nothing when no bls' => sub {
    _setup();

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, {} );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply \@tags, [];
};

subtest 'create_tags_service_handler: skips common bl' => sub {
    _setup();

    _create_bl_ci( bl => '*' );

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, {} );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply \@tags, [];
};

subtest 'create_tags_service_handler: creates tags for every bl' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, {} );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply [ sort @tags ], [qw/PROD TEST/];
};

subtest 'create_tags_service_handler: returns command output' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    is $ci->create_tags_handler( undef, {} ), '';
};

subtest 'create_tags_service_handler: creates tags for matching bls' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, { tag_filter => 'TEST' } );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply [ sort @tags ], [qw/TEST/];
};

subtest 'create_tags_service_handler: creates tags for the first commit' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();

    _git_commit($repo_dir);

    my @refs = _git_commits($repo_dir);

    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, {} );

    _git_tags("$repo_dir/.git");

    my $ref = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $ref, $refs[-1];
};

subtest 'create_tags_service_handler: creates tags for specific ref' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();

    _git_commit($repo_dir);

    my @refs = _git_commits($repo_dir);

    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, { ref => $refs[0] } );

    _git_tags("$repo_dir/.git");

    my $ref = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $ref, $refs[0];
};

subtest 'create_tags_service_handler: detects existing tags by default' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();

    _git_commit($repo_dir);

    my @refs = _git_commits($repo_dir);

    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_tag( $repo_dir, 'TEST' );

    $ci->create_tags_handler( undef, {} );

    _git_tags("$repo_dir/.git");

    my $ref = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $ref, $refs[0];
};

subtest 'create_tags_service_handler: overwrites existing tags when specified' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();

    _git_commit($repo_dir);

    my @refs = _git_commits($repo_dir);

    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_tag( $repo_dir, 'TEST' );

    $ci->create_tags_handler( undef, { existing => 'no-detect' } );

    _git_tags("$repo_dir/.git");

    my $ref = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $ref, $refs[-1];
};

subtest 'create_tags_service_handler: creates project tags' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $project = _create_project_ci( name => 'project', repositories => [ $ci->mid ] );

    $ci->create_tags_handler( undef, {} );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply [ sort @tags ], [qw/project-PROD project-TEST/];
};

subtest 'create_tags_service_handler: filters by tags when projects' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
    _git_commit($repo_dir);
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $project = _create_project_ci( name => 'project', repositories => [ $ci->mid ] );

    $ci->create_tags_handler( undef, { tag_filter => 'project-TEST' } );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply [ sort @tags ], [qw/project-TEST/];
};

subtest 'update_baselines: moves baselines up in promote' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    my $sha = _git_commit($repo_dir);

    $ci->update_baselines( tag => 'TEST', type => 'promote', revisions => [ { sha => $sha } ] );

    my $tag_sha = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: returns refs' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    my $sha = _git_commit($repo_dir);

    my $retval = $ci->update_baselines( tag => 'TEST', type => 'promote', revisions => [ { sha => $sha } ] );

    cmp_deeply $retval,
      {
        '' => {
            'previous' => ignore(),
            'current'  => $sha,
            'output'   => re(qr/Updated tag 'TEST'/)
        }
      };
};

subtest 'update_baselines: moves baselines down in demote' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    my $old_sha  = _git_commit( $repo_dir, '2015-01-01 00:00:00' );
    my $old_sha2 = _git_commit( $repo_dir, '2015-01-01 00:00:01' );

    my $sha = _git_commit( $repo_dir, '2015-01-01 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

    $ci->update_baselines( tag => 'TEST', type => 'demote', revisions => [ { sha => $old_sha2 }, { sha => $sha } ] );

    my $tag_sha = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $tag_sha, $old_sha;
};

subtest 'update_baselines: moves baselines up in static' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    my $sha = _git_commit($repo_dir);

    $ci->update_baselines( tag => 'TEST', type => 'static', revisions => [ { sha => $sha } ] );

    my $tag_sha = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: moves baselines to specific ref' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    my $sha = _git_commit($repo_dir);

    $ci->update_baselines( tag => 'TEST', type => 'static', revisions => [], ref => $sha );

    my $tag_sha = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: does nothing when already there' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    my $sha = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    $ci->update_baselines( tag => 'TEST', type => 'static', revisions => [], ref => $sha );

    my $tag_sha = _git_sha_from_tag( $repo_dir, 'TEST' );

    is $tag_sha, $sha;
};

subtest 'update_baselines: throws when tags_mode is project but no projects' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $sha = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'TEST' );

    like exception { $ci->update_baselines( tag => 'TEST', type => 'static', revisions => [], ref => $sha ) },
      qr/Projects are required/;
};

subtest 'update_baselines: updates tags for every project' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $project = _create_project_ci( name => 'project', repositories => [ $ci->mid ] );

    my $sha = _git_commit( $repo_dir, '2015-01-01 00:00:00' );
    _git_tag( $repo_dir, 'project-TEST' );

    my $new_sha = _git_commit( $repo_dir, '2015-01-01 00:00:01' );

    $ci->update_baselines(
        job       => { projects => [ { name => 'project', repositories => [ $ci->mid ] } ] },
        tag       => 'TEST',
        type      => 'promote',
        revisions => [],
        ref       => $new_sha
    );

    my $tag_sha = _git_sha_from_tag( $repo_dir, 'project-TEST' );

    is $tag_sha, $new_sha;
};

subtest 'update_baselines: updates tags only for project related to the repository' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $project = _create_project_ci( name => 'project', repositories => [ $ci->mid ] );
    _create_project_ci( name => 'other', repositories => [] );

    my $sha = _git_commit($repo_dir);
    _git_tag( $repo_dir, 'project-TEST' );

    _git_commit($repo_dir);

    $ci->update_baselines(
        job       => { projects => [ { name => 'project', repositories => [ $ci->mid ] }, { name => 'other' } ] },
        tag       => 'TEST',
        type      => 'static',
        revisions => [],
        ref       => $sha
    );

    like capture_merged { _git_sha_from_tag( $repo_dir, 'other-TEST' ) }, qr/unknown revision/;
};

subtest 'top_revision: returns top revision from random commits' => sub {
    _setup();

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

    my $sha3 = _git_commit( $repo_dir, '2015-01-02 00:00:03' );
    my $sha4 = _git_commit( $repo_dir, '2015-01-02 00:00:04' );
    my $sha5 = _git_commit( $repo_dir, '2015-01-02 00:00:05' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha4 }, { sha => $sha1 }, { sha => $sha3 }, { sha => $sha2 }, { sha => $sha5 } ],
        tag       => 'TEST'
    );

    is_deeply $rev, { sha => $sha5 };
};

subtest 'top_revision: returns same top revision when already on top' => sub {
    _setup();

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha1 }, { sha => $sha2 } ],
        tag       => 'TEST'
    );

    is_deeply $rev, { sha => $sha2 };
};

subtest 'top_revision: returns tag sha when nowhere to move' => sub {
    _setup();

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha1 } ],
        tag       => 'TEST'
    );

    is $rev->sha, $sha2;
};

subtest 'top_revision: throws when tag has not same history' => sub {
    _setup();

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );

    _git_branch( $repo_dir, 'another' );
    my $tag_sha = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

    like exception {
        $repo->top_revision(
            revisions => [ { sha => $sha1 }, { sha => $sha2 } ],
            tag       => 'TEST'
          )
    }, qr/Cannot promote .* common history/;
};

subtest 'top_revision: returns bottom revision when in demote' => sub {
    _setup();

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

    my $rev = $repo->top_revision(
        revisions => [ { sha => $sha1 }, { sha => $sha2 } ],
        type      => 'demote',
        tag       => 'TEST'
    );

    is_deeply $rev, { sha => $sha1 };
};

subtest 'top_revision: throws when demoting everything' => sub {
    _setup();

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    _git_tag( $repo_dir, 'TEST' );

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

    my $repo_dir = _create_repo('2015-01-01 00:00:00');
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha  = _git_commit( $repo_dir, '2015-01-02 00:00:00' );
    my $sha1 = _git_commit( $repo_dir, '2015-01-02 00:00:01' );

    _git_branch( $repo_dir, 'another' );
    my $sha2 = _git_commit( $repo_dir, '2015-01-02 00:00:02' );
    my $sha3 = _git_commit( $repo_dir, '2015-01-02 00:00:03' );

    _git_branch( $repo_dir, 'master' );
    my $sha4 = _git_commit( $repo_dir, '2015-01-02 00:00:04' );
    _git_tag( $repo_dir, 'TEST' );
    my $sha5 = _git_commit( $repo_dir, '2015-01-02 00:00:05' );
    my $sha6 = _git_commit( $repo_dir, '2015-01-02 00:00:06' );

    like exception {
        $repo->top_revision(
            revisions => [ { sha => $sha2 }, { sha => $sha6 } ],
            tag       => 'TEST'
          )
    }, qr/Not all commits are in .*? history/;
};

subtest 'top_revision: throws when no revisions passed' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    like exception { $repo->top_revision( revisions => [], tag => 'TEST' ) }, qr/Error: No revisions passed/;
};

subtest 'top_revision: throws when unknown sha' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    like exception { $repo->top_revision( revisions => [ { sha => 'unknown' } ], tag => 'TEST' ) },
      qr/Error: revision `unknown` not found in repository repo/;
};

subtest 'top_revision: throws when unknown tag' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $repo = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', revision_mode => 'diff' );

    my $sha = _git_commit($repo_dir);

    like exception { $repo->top_revision( revisions => [ { sha => $sha } ], tag => 'UNKNOWN' ) },
      qr/Error: tag `UNKNOWN` not found in repository repo/;
};

done_testing;

sub _git_tags {
    my ($repo_dir) = @_;
    return map { chomp; $_ } `cd $repo_dir; git tag -l`;
}

sub _git_commits {
    my ($repo_dir) = @_;

    return map { chomp; $_ } `cd $repo_dir; git rev-list HEAD`;
}

sub _git_tag {
    my ( $repo_dir, $tag ) = @_;

    system("cd $repo_dir; git tag $tag");
}

sub _git_sha_from_tag {
    my ( $repo_dir, $tag ) = @_;

    my $ref = `cd $repo_dir; git rev-parse $tag`;
    chomp $ref;
    return $ref;
}

sub _set_timestamp {
    my ($timestamp) = @_;

    $ENV{GIT_AUTHOR_DATE}    = $timestamp;
    $ENV{GIT_COMMITTER_DATE} = $timestamp;
}

sub _git_branch {
    my ( $repo_dir, $branch ) = @_;

    if ( $branch eq 'master' ) {
        system("cd $repo_dir; git checkout $branch 2> /dev/null");
    }
    else {
        system("cd $repo_dir; git checkout -b $branch 2> /dev/null");
    }
}

sub _git_commit {
    my ( $repo_dir, $timestamp ) = @_;

    _set_timestamp($timestamp) if $timestamp;

    my $text = TestUtils->random_string;

    system("cd $repo_dir; echo '$text' >> README; git add .; git commit -a -m 'new'");

    return ( _git_commits($repo_dir) )[0];
}

sub _create_repo {
    my $dir = tempdir();

    system("cd $dir; git init");

    return $dir;
}

sub _create_project_ci {
    my $ci = BaselinerX::CI::project->new(@_);
    $ci->save;
    return $ci;
}

sub _create_bl_ci {
    my $ci = BaselinerX::CI::bl->new(@_);
    $ci->save;
    return $ci;
}

sub _create_git_repository_ci {
    my $ci = BaselinerX::CI::GitRepository->new(@_);
    $ci->save;
    return $ci;
}

sub _setup {
    TestUtils->cleanup_cis;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );
}
