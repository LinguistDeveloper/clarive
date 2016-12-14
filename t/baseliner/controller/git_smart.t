use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Deep;
use Test::Fatal;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils ':catalyst';
use TestGit;

use Cwd qw(realpath);
use Baseliner::Utils qw(_load);

use_ok 'Baseliner::Controller::GitSmart';

subtest 'git: ignores requests with empty body' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => realpath( $repo->repo_dir . '/../' )
        }
    };

    my $c = mock_catalyst_c( username => 'foo', stash => $stash );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;
    is scalar @events, 0;
};

subtest 'git: creates no events when no changes' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 0;

    ok $controller->mocked_called('cgi_to_response');
};

subtest 'git: creates correct event on first push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event      = $events[0];
    my $event_data = _load $event->{event_data};

    cmp_deeply $event_data,
      {
        branch     => 'master',
        username   => 'foo',
        message    => re(qr/update/),
        diff       => re(qr/\+\+\+ b\/README/),
        ref        => 'refs/heads/master',
        sha        => $sha,
        repository => 'Repo',
        rules_exec => ignore(),
      };
};

subtest 'git: truncates diff if it is too big' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit( $repo, content => 'x' x ( 1024 * 1024 ) );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    my $event      = $events[0];
    my $event_data = _load $event->{event_data};

    is length $event_data->{diff}, 512000;
};

subtest 'git: creates correct event on push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094" . "$sha $sha2 refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4" . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};

    is $data->{branch},   'master';
    is $data->{username}, 'foo';
    is $data->{message},  'update';
    like $data->{diff},   qr/\+\+\+ b\/README/;
    is $data->{ref},      'refs/heads/master';
    is $data->{sha},      $sha2;
};

subtest 'git: creates correct event on push when branch has slashes' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094" . "$sha $sha2 refs/heads/1.0#my/strange/branch-7\x00 report-status side-band-64k agent=git/2.6.4" . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};

    is $data->{branch}, '1.0#my/strange/branch-7';
    is $data->{ref},    'refs/heads/1.0#my/strange/branch-7';
};

subtest 'git: creates correct event on push several references' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $master_sha = TestGit->commit($repo);

    TestGit->create_branch($repo);
    my $new_sha = TestGit->commit($repo);

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body =
        "0094"
      . "0000000000000000000000000000000000000000 $master_sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0064"
      . "0000000000000000000000000000000000000000 $new_sha refs/heads/new" . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is scalar @events, 2;

    my @data = map { _load $_->{event_data} } @events;

    is $data[0]->{branch}, 'master';
    is $data[0]->{ref},    'refs/heads/master';
    is $data[0]->{sha},    $master_sha;

    is $data[1]->{branch}, 'new';
    is $data[1]->{ref},    'refs/heads/new';
    is $data[1]->{sha},    $new_sha;

    is $controller->mocked_called('cgi_to_response'), 1;
};

subtest 'git: does not create an event when removing a reference' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $master_sha = TestGit->commit($repo);

    TestGit->create_branch($repo);
    my $new_sha = TestGit->commit($repo);

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body =
        "0094"
      . "$master_sha 0000000000000000000000000000000000000000 refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is scalar @events, 0;

    is $controller->mocked_called('cgi_to_response'), 1;
};

subtest 'git: creates correct event on push tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TAG' );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body =
        "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/TAG\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};

    is $data->{branch}, 'TAG';
    is $data->{ref},    'refs/tags/TAG';
    is $data->{sha},    $sha;
};

subtest 'git: forbids pushing system tags' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TAG' );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    TestUtils->create_ci( 'bl', bl => 'TAG' );

    my $body =
        "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/TAG\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 0;

    my $error = $c->res->body;
    like $error, qr/Cannot update internal tag TAG/;
};

subtest 'git: allows pushing system tags when user has permission' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TAG' );

    my $controller = _build_controller();

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    TestUtils->create_ci( 'bl', bl => 'TAG' );

    mdb->role->insert(
        {
            id      => '1',
            actions => [
                {
                    action => 'action.git.update_tags',
                    bl     => 'TAG'
                }
            ],
            role => 'Developer'
        }
    );
    TestUtils->create_ci(
        'user',
        name             => 'developer',
        username         => 'developer',
        project_security => {
            '1' => {
                project => [ $project->mid ]
            }
        }
    );

    my $body =
        "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/TAG\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'developer',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};

    is $data->{branch}, 'TAG';
    is $data->{ref},    'refs/tags/TAG';
    is $data->{sha},    $sha;
};

subtest 'git: allows pushing system tags when user has permission and bl is complex (bl - release)' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo', tags_mode => 'release' );
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ],
        moniker      => '6.4'
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.git.repository_access',
                bl     => '*'
            },
            {
                action => 'action.git.update_tags',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );

    my $status              = TestUtils->create_ci( 'status', name => 'New', type => 'G' );
    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        is_release => '1',
        name       => 'Release',
        id_rule    => $id_release_rule,
        id_status  => $status->mid
    );

    my $release_mid = TestSetup->create_topic(
        project         => $project,
        id_category     => $id_release_category,
        title           => 'Release 0.1',
        status          => $status,
        release_version => '3.0'
    );

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/3.0-SUPPORT\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c,, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};
    is $data->{branch}, '3.0-SUPPORT';
    is $data->{ref},    'refs/tags/3.0-SUPPORT';
    is $data->{sha},    $sha;
};

subtest 'git: allows pushing system tags when user has permission and is a raw git access ' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'RAWREPO', tags_mode => '' );
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ],
        moniker      => '6.4'
    );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.git.repository_access',
                bl     => '*'
            },
            {
                action => 'action.git.update_tags',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestUtils->create_ci( 'bl', bl => 'SUPPORT' );

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/SUPPORT\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $stash = {
        git_config => {
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir . '/../',
            force_authorization => 0
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, '.git', 'info', 'refs' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};
    is $data->{branch}, 'SUPPORT';
    is $data->{ref},    'refs/tags/SUPPORT';
    is $data->{sha},    $sha;
};

subtest 'git: creates repo ci when does not exist' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo_dir
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @repo_cis = ci->GitRepository->find->all;
    is @repo_cis, 1;
};

subtest 'git: does not create repo ci when exists' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @repo_cis = ci->GitRepository->find->all;
    is @repo_cis, 1;
};

subtest 'git: creates rev ci when does not exist' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir, message => 'my commit message');

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo_dir
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @rev_cis = ci->GitRevision->find->all;
    is @rev_cis, 1;

    like $rev_cis[0]->{name}, qr/^\[.{8}\] my commit message/;
    like $rev_cis[0]->{repo}, qr/GitRepository-\d+/;
    is $rev_cis[0]->{moniker}, $sha;
    is $rev_cis[0]->{sha},    $sha;
};

subtest 'git: does not create rev ci when exists' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo_dir
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git( $c, '.git', 'info', 'refs' );

    my @rev_cis = ci->GitRevision->find->all;
    is @rev_cis, 1;
};

subtest 'git: calls pre-online event with correct params' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit( $repo->repo_dir );

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => {
            params     => {},
            user_agent => 'git/2.8.6',
            body       => $fh
        },
        stash => $stash
    );

    my $tempdir = tempdir();

    _create_run_rule(
        rule_when => 'pre-online',
        code      => qq{
            use Data::Dumper;
            open my \$fh, '>', '$tempdir/file'; print \$fh Dumper(\$stash);
        }
    );

    my $controller = _build_controller();
    $controller->git( $c, '.git', 'info', 'refs' );

    my $event_data = do { local $/; open my $fh, '<', "$tempdir/file"; <$fh> };
    $event_data =~ s{\$VAR1 = }{};
    $event_data = eval $event_data;

    is $event_data->{branch},     'master';
    is $event_data->{username},   'foo';
    is $event_data->{ref},        'refs/heads/master';
    is $event_data->{sha},        $sha;
    is $event_data->{repository}, 'Repo';
};

subtest 'git: if pre-online event fails return an error' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo_dir
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => {
            params     => {},
            user_agent => 'git/2.8.6',
            body       => $fh
        },
        stash => $stash
    );

    _create_run_rule(
        rule_when => 'pre-online',
        code      => q{die 'here';}
    );

    my $controller = _build_controller();
    $controller->git( $c, '.git', 'info', 'refs' );

    #is $c->res->status, 500;
    like $c->res->body, qr/CLARIVE ERROR: GIT ERROR\n\(rule 1\): .*here/;
};

subtest 'git: when forcing authorization fail' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo_dir
        }
    };

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => {
            params     => {},
            user_agent => 'git/2.8.6',
        },
        stash => $stash
    );

    my $controller = _build_controller();
    $controller->git( $c, '.git', 'info', 'refs' );

    is $c->res->status, 401;
    like $c->res->body, qr/CLARIVE: invalid repository: Invalid or unauthorized git repository path \.git/;
};

subtest 'git: when forcing authorization' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.git.repository_access',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir
        }
    };

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => $user->username,
        req      => {
            params     => {},
            user_agent => 'git/2.8.6',
            body       => $fh,
        },
        stash => $stash
    );

    my $controller = _build_controller();
    $controller->git( $c, 'Project', 'Repo', 'info', 'refs' );

    is $controller->mocked_called('cgi_to_response'), 1;
};

subtest 'git: return error when wrong path' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir
        }
    };

    my $c = mock_catalyst_c(
        username => 'foo',
        stash    => $stash
    );

    my $controller = _build_controller();
    $controller->git($c);

    is $c->res->status, 401;
    like $c->res->body, qr/CLARIVE: internal error: Unknown request/;
};

subtest 'git: return error when unknown project' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir
        }
    };

    my $c = mock_catalyst_c(
        username => 'foo',
        stash    => $stash
    );

    my $controller = _build_controller();
    $controller->git( $c, 'Unknown', 'Repo', 'info', 'refs' );

    is $c->res->status, 404;
    like $c->res->body, qr/CLARIVE ERROR: internal error\nProject `Unknown` not found/;
};

subtest 'git: return error when user has no access to project' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );
    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir
        }
    };

    my $c = mock_catalyst_c(
        username => 'foo',
        stash    => $stash
    );

    my $controller = _build_controller();
    $controller->git( $c, 'Project', 'Repo', 'info', 'refs' );

    is $c->res->status, 401;
    like $c->res->body, qr/CLARIVE: User: foo does not have access to the project Project/;
};

subtest 'git: return error when unknown repository' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.git.repository_access',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        stash    => $stash
    );

    my $controller = _build_controller();
    $controller->git( $c, 'Project', 'Unknown', 'info', 'refs' );

    is $c->res->status, 404;
    like $c->res->body, qr/CLARIVE ERROR: internal error\nRepository `Unknown` not found for project `Project`/;
};

subtest 'git: return error when user does not have access to repository' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $stash = {
        git_config => {
            force_authorization => 1,
            gitcgi              => '../local/libexec/git-core/git-http-backend',
            home                => $repo->repo_dir
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        stash    => $stash
    );

    my $controller = _build_controller();
    $controller->git( $c, 'Project', 'Repo', 'info', 'refs' );

    is $c->res->status, 401;
    like $c->res->body, qr/CLARIVE: User: developer does not have access to the project Project/;
};

subtest 'git: calls git with correct parameters when raw git' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => realpath( $repo->repo_dir . '/../' )
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, '.git', 'info', 'refs' );

    my ($cgi) = $controller->mocked_call_args('_system');
    my ($env) = $controller->mocked_return_args('_system');

    is $cgi, '../local/libexec/git-core/git-http-backend';

    is $env->{GIT_HTTP_EXPORT_ALL}, 1;
    is $env->{GIT_PROJECT_ROOT},    realpath( $repo->repo_dir . '/../' );

    is $env->{REMOTE_USER}, 'developer';
    is $env->{REMOTE_ADDR}, 'localhost';
    is $env->{PATH_INFO},   '/.git/info/refs';
};

subtest 'git: calls git with correct parameters when project git' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.git.repository_access',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => realpath( $repo->repo_dir . '/../' )
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, 'Project', 'Repo', 'info', 'refs' );

    my ($cgi) = $controller->mocked_call_args('_system');
    my ($env) = $controller->mocked_return_args('_system');

    is $cgi, '../local/libexec/git-core/git-http-backend';

    is $env->{GIT_HTTP_EXPORT_ALL}, 1;
    is $env->{GIT_PROJECT_ROOT},    realpath( $repo->repo_dir . '/../' );

    is $env->{REMOTE_USER}, 'developer';
    is $env->{REMOTE_ADDR}, 'localhost';
    is $env->{PATH_INFO},   '/.git/info/refs';
};

subtest 'git: finds project with special symbols' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'My Repo' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'My Project',
        repositories => [ $repo->mid ]
    );
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.git.repository_access',
                bl     => '*'
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => realpath( $repo->repo_dir . '/../' )
        }
    };

    my $c = mock_catalyst_c(
        username => $user->username,
        stash    => $stash
    );

    my $controller = _build_controller();

    $controller->git( $c, 'My%20Project', 'My%20Repo', 'info', 'refs' );

    ok $controller->mocked_called('_system');
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Events',
        'BaselinerX::Fieldlets',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::GitServices',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Topic',
    );

    TestUtils->cleanup_cis;

    my @rules = mdb->rule->find->all;

    foreach my $rule (@rules) {
        my $rule = Baseliner::RuleCompiler->new( id_rule => $rule->{id}, version_id => '' . $rule->{_id} );
        $rule->unload;
    }

    mdb->role->drop;
    mdb->rule->drop;
    mdb->event->drop;
    mdb->category->drop;

    TestUtils->create_ci( 'user', name => 'foo' );
}

sub _build_controller {
    my (%params) = @_;

    my $controller = Baseliner::Controller::GitSmart->new( application => '' );
    $controller = Test::MonkeyMock->new($controller);

    $controller->mock(
        cgi_to_response => sub {
            my $self = shift;
            my ( $c, $cb ) = @_;

            $cb->();
        }
    );
    $controller->mock(
        _system => sub {
            my $env = Storable::dclone( \%ENV );

            return $env;
        }
    );

    return $controller;
}

sub _create_run_rule {
    my (%params) = @_;

    my $code = delete $params{code} // '';

    return _create_rule(
        rule_tree => [
            {
                "attributes" => {
                    "key"  => "statement.perl.code",
                    "data" => { "code" => "$code" },
                },
                "children" => []
            },
        ],
        %params
    );
}

sub _create_rule {
    my (%params) = @_;

    my $rule_tree = delete $params{rule_tree};

    if ( $rule_tree && ref $rule_tree ) {
        $rule_tree = JSON::encode_json($rule_tree);
    }

    return mdb->rule->insert(
        {
            id            => '1',
            "rule_active" => "1",
            "rule_type"   => "event",
            "rule_name"   => "test",
            "username"    => "root",
            "rule_event"  => 'event.repository.update',
            "rule_when"   => "pre-online",
            "rule_tree"   => $rule_tree,
            %params
        }
    );
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'release_version',
                        "fieldletType" => "fieldlet.system.release_version",
                    },
                    "key" => "fieldlet.system.release_version",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            }
        ],
    );
}
