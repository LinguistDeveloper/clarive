use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::MonkeyMock;
use TestEnv;
use TestUtils ':catalyst';
BEGIN { TestEnv->setup }
use TestGit;
use JSON ();

use Baseliner::Utils qw(_load);
use_ok 'Baseliner::Controller::GitSmart';

subtest 'git: ignores requests with empty body' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => '' },
        stash    => $stash
    );

    $controller->git( $c, '.git' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;
    is scalar @events, 0;
};

subtest 'git: creates no events when no changes' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

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

    my $body = "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    my $cgi_wrapper = _mock_cgi_wrapper();
    my $controller = _build_controller( cgi_wrapper => $cgi_wrapper );

    $controller->git( $c, '.git' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 0;

    ok $cgi_wrapper->mocked_called('run');
};

subtest 'git: creates correct event on first push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

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

    $controller->git( $c, '.git' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};

    is $data->{branch},    'master';
    is $data->{username},  'foo';
    like $data->{message}, qr/update/;
    like $data->{diff},    qr/\+\+\+ b\/README/;
    is $data->{ref},       'refs/heads/master';
    is $data->{sha},       $sha;
};

subtest 'git: creates correct event on push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

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

    $controller->git( $c, '.git' );

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

subtest 'git: creates correct event on push several references' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $master_sha = TestGit->commit($repo);

    TestGit->create_branch($repo);
    my $new_sha = TestGit->commit($repo);

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

    my $cgi_wrapper = _mock_cgi_wrapper();
    my $controller = _build_controller( cgi_wrapper => $cgi_wrapper );

    $controller->git( $c, '.git' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is scalar @events, 2;

    my @data = map { _load $_->{event_data} } @events;

    is $data[0]->{branch}, 'master';
    is $data[0]->{ref},    'refs/heads/master';
    is $data[0]->{sha},    $master_sha;

    is $data[1]->{branch}, 'new';
    is $data[1]->{ref},    'refs/heads/new';
    is $data[1]->{sha},    $new_sha;

    is $cgi_wrapper->mocked_called('run'), 1;
};

subtest 'git: creates correct event on push tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TAG' );

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

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

    $controller->git( $c, '.git' );

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

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

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

    $controller->git( $c, '.git' );

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

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [ $repo->mid ]
    );

    my $controller = _build_controller();

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

    $controller->git( $c, '.git' );

    my @events = mdb->event->find( { event_key => 'event.repository.update' } )->all;

    is @events, 1;

    my $event = $events[0];
    my $data  = _load $event->{event_data};

    is $data->{branch}, 'TAG';
    is $data->{ref},    'refs/tags/TAG';
    is $data->{sha},    $sha;
};

subtest 'git: creates repo ci when does not exist' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

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

    $controller->git( $c, '.git' );

    my @repo_cis = ci->GitRepository->find->all;
    is @repo_cis, 1;
};

subtest 'git: does not create repo ci when exists' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'Repo' );
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

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

    $controller->git( $c, '.git' );

    my @repo_cis = ci->GitRepository->find->all;
    is @repo_cis, 1;
};

subtest 'git: creates rev ci when does not exist' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

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

    $controller->git( $c, '.git' );

    my @rev_cis = ci->GitRevision->find->all;
    is @rev_cis, 1;
};

subtest 'git: does not create rev ci when exists' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

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

    $controller->git( $c, '.git' );

    my @rev_cis = ci->GitRevision->find->all;
    is @rev_cis, 1;
};

subtest 'git: if pre-online event fails return an error' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

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
    $controller->git( $c, '.git' );

    is $c->res->status, 500;
    like $c->res->body, qr/CLARIVE: GIT ERROR: \(rule 1\): here/;
};

subtest 'git: if cgi wrapper fails returns an error' => sub {
    _setup();

    my $repo_dir = TestGit->create_repo;
    my $sha      = TestGit->commit($repo_dir);

    TestUtils->create_ci( 'GitRevision', sha => $sha );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

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

    my $cgi_wrapper = _mock_cgi_wrapper( run => sub { { is_success => 0, error => 'Some error' } } );

    my $controller = _build_controller( cgi_wrapper => $cgi_wrapper );
    $controller->git( $c, '.git' );

    is $c->res->status, 500;
    like $c->res->body, qr/CLARIVE: GIT ERROR: Some error/;
};

done_testing;

sub _mock_cgi_wrapper {
    my (%params) = @_;

    my $cgi_wrapper = Test::MonkeyMock->new;
    $cgi_wrapper->mock( run => $params{run} || sub { { is_success => 1 } } );

    return $cgi_wrapper;
}

sub _build_controller {
    my (%params) = @_;

    my $cgi_wrapper = $params{cgi_wrapper} || _mock_cgi_wrapper();

    my $controller = Baseliner::Controller::GitSmart->new( application => '' );
    $controller = Test::MonkeyMock->new($controller);

    $controller->mock( _build_cgi_wrapper => sub { $cgi_wrapper } );

    return $controller;
}

sub _create_run_rule {
    my (%params) = @_;

    my $code = delete $params{code} // '';

    _create_rule(
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

    mdb->rule->insert(
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

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Type::Statement',
        'BaselinerX::CI',          'BaselinerX::Events',
        'Baseliner::Model::Rules'
    );

    TestUtils->cleanup_cis;

    mdb->event->drop;
    mdb->role->drop;
    mdb->rule->drop;

    TestUtils->create_ci( 'user', name => 'foo', username => 'foo' );
}
