use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }

use TestUtils;

use Capture::Tiny qw(capture_merged);
use File::Temp qw(tempdir);
use BaselinerX::CI::project;

use_ok 'BaselinerX::CI::GitRepository';

subtest 'create_tags_service_handler: does nothing when no bls' => sub {
    _setup();

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    $ci->create_tags_handler( undef, {} );

    my @tags = _git_tags("$repo_dir/.git");

    is_deeply \@tags, [];
};

subtest 'create_tags_service_handler: skips common bl' => sub {
    _setup();

    _create_bl_ci( bl => '*' );

    my $repo_dir = _create_repo();
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
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    is $ci->create_tags_handler( undef, {} ), '';
};

subtest 'create_tags_service_handler: creates tags for matching bls' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
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

    my $ref = _git_sha_from_tag($repo_dir, 'TEST');

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

    my $ref = _git_sha_from_tag($repo_dir, 'TEST');

    is $ref, $refs[0];
};

subtest 'create_tags_service_handler: detects existing tags by default' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();

    _git_commit($repo_dir);

    my @refs = _git_commits($repo_dir);

    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_tag($repo_dir, 'TEST');

    $ci->create_tags_handler( undef, {} );

    _git_tags("$repo_dir/.git");

    my $ref = _git_sha_from_tag($repo_dir, 'TEST');

    is $ref, $refs[0];
};

subtest 'create_tags_service_handler: overwrites existing tags when specified' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();

    _git_commit($repo_dir);

    my @refs = _git_commits($repo_dir);

    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_tag($repo_dir, 'TEST');

    $ci->create_tags_handler( undef, { existing => 'no-detect' } );

    _git_tags("$repo_dir/.git");

    my $ref = _git_sha_from_tag($repo_dir, 'TEST');

    is $ref, $refs[-1];
};

subtest 'create_tags_service_handler: creates project tags' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );
    _create_bl_ci( bl => 'PROD' );

    my $repo_dir = _create_repo();
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
    _git_tag($repo_dir, 'TEST');

    my $sha = _git_commit($repo_dir);

    $ci->update_baselines(tag => 'TEST', type => 'promote', revisions => [{sha => $sha}]);

    my $tag_sha = _git_sha_from_tag($repo_dir, 'TEST');

    is $tag_sha, $sha;
};

subtest 'update_baselines: moves baselines down in demote' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    my $old_sha = _git_commit($repo_dir);

    my $sha = _git_commit($repo_dir);
    _git_tag($repo_dir, 'TEST');

    $ci->update_baselines(tag => 'TEST', type => 'demote', revisions => [{sha => $sha}]);

    my $tag_sha = _git_sha_from_tag($repo_dir, 'TEST');

    is $tag_sha, $old_sha;
};

subtest 'update_baselines: moves baselines up in static' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_commit($repo_dir);
    _git_tag($repo_dir, 'TEST');

    my $sha = _git_commit($repo_dir);

    $ci->update_baselines(tag => 'TEST', type => 'static', revisions => [{sha => $sha}]);

    my $tag_sha = _git_sha_from_tag($repo_dir, 'TEST');

    is $tag_sha, $sha;
};

subtest 'update_baselines: moves baselines to specific ref' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    _git_commit($repo_dir);
    _git_tag($repo_dir, 'TEST');

    my $sha = _git_commit($repo_dir);

    $ci->update_baselines(tag => 'TEST', type => 'static', revisions => [], ref => $sha);

    my $tag_sha = _git_sha_from_tag($repo_dir, 'TEST');

    is $tag_sha, $sha;
};

subtest 'update_baselines: does nothing when already there' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo' );

    my $sha = _git_commit($repo_dir);
    _git_tag($repo_dir, 'TEST');

    $ci->update_baselines(tag => 'TEST', type => 'static', revisions => [], ref => $sha);

    my $tag_sha = _git_sha_from_tag($repo_dir, 'TEST');

    is $tag_sha, $sha;
};

subtest 'update_baselines: throws when tags_mode is project but no projects' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $sha = _git_commit($repo_dir);
    _git_tag($repo_dir, 'TEST');

    like exception { $ci->update_baselines( tag => 'TEST', type => 'static', revisions => [], ref => $sha ) },
      qr/Projects are required/;
};

subtest 'update_baselines: updates tags for every project' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $project = _create_project_ci( name => 'project', repositories => [ $ci->mid ] );

    my $sha = _git_commit($repo_dir);
    _git_tag($repo_dir, 'project-TEST');

    my $new_sha = _git_commit($repo_dir);

    $ci->update_baselines(
        job       => { projects => [ { name => 'project', repositories => [ $ci->mid ] } ] },
        tag       => 'TEST',
        type      => 'static',
        revisions => [],
        ref       => $sha
    );

    my $tag_sha = _git_sha_from_tag($repo_dir, 'project-TEST');

    is $tag_sha, $new_sha;
};

subtest 'update_baselines: updates tags only for project related to the repository' => sub {
    _setup();

    _create_bl_ci( bl => 'TEST' );

    my $repo_dir = _create_repo();
    my $ci = _create_git_repository_ci( repo_dir => "$repo_dir/.git", name => 'repo', tags_mode => 'project' );

    my $project = _create_project_ci( name => 'project', repositories => [ $ci->mid ] );
    _create_project_ci( name => 'other', repositories => [ ] );

    my $sha = _git_commit($repo_dir);
    _git_tag($repo_dir, 'project-TEST');

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

sub _git_commit {
    my ($repo_dir) = @_;

    system("cd $repo_dir; echo new > README; git commit -a -m 'new'");

    return ( _git_commits($repo_dir) )[0];
}

sub _create_repo {
    my $dir = tempdir( CLEANUP => 1 );

    system("cd $dir; git init; touch README; git add .; git commit -m 'initial'");

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
