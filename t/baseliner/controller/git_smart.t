use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::MonkeyMock;
use TestEnv;
use TestUtils ':catalyst';
BEGIN { TestEnv->setup }
use TestGit;

use Baseliner::Utils qw(_load);
use_ok 'Baseliner::Controller::GitSmart';

subtest 'git: ignores requests with empty body' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
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
        req      => {params => {}, body => ''},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my @events = mdb->event->find({event_key => 'event.repository.update'})->all;
    is scalar @events, 0;
};

subtest 'git: creates correct event on first push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
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
        req      => {params => {}, body => $fh},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my ($event) =
      mdb->event->find({event_key => 'event.repository.update'})->all;

    my $data = _load $event->{event_data};

    is $data->{branch},    'master';
    is $data->{username},  'foo';
    like $data->{message}, qr/update/;
    like $data->{diff},    qr/\+\+\+ b\/README/;
    is $data->{ref},       'refs/heads/master';
    is $data->{sha},       $sha;
};

subtest 'git: creates correct event on push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
    );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    my $body = "0094"
      . "$sha $sha2 refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => {params => {}, body => $fh},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my ($event) =
      mdb->event->find({event_key => 'event.repository.update'})->all;

    my $data = _load $event->{event_data};

    is $data->{branch},   'master';
    is $data->{username}, 'foo';
    is $data->{message},  'update';
    like $data->{diff},   qr/\+\+\+ b\/README/;
    is $data->{ref},      'refs/heads/master';
    is $data->{sha},      $sha2;
};

subtest 'git: creates correct event on push several references' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $master_sha = TestGit->commit($repo);

    TestGit->create_branch($repo);
    my $new_sha = TestGit->commit($repo);

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
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
      . "0000000000000000000000000000000000000000 $master_sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0064"
      . "0000000000000000000000000000000000000000 $new_sha refs/heads/new"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => {params => {}, body => $fh},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my (@events) =
      mdb->event->find({event_key => 'event.repository.update'})->all;

    is scalar @events, 2;

    my @data = map { _load $_->{event_data} } @events;

    is $data[0]->{branch}, 'master';
    is $data[0]->{ref},    'refs/heads/master';
    is $data[0]->{sha},    $master_sha;

    is $data[1]->{branch}, 'new';
    is $data[1]->{ref},    'refs/heads/new';
    is $data[1]->{sha},    $new_sha;
};

subtest 'git: creates correct event on push tag' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $sha = TestGit->commit($repo);

    TestGit->tag($repo, tag => 'TAG');

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
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
        req      => {params => {}, body => $fh},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my ($event) =
      mdb->event->find({event_key => 'event.repository.update'})->all;

    my $data = _load $event->{event_data};

    is $data->{branch}, 'TAG';
    is $data->{ref},    'refs/tags/TAG';
    is $data->{sha},    $sha;
};

subtest 'git: forbids pushing system tags' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $sha = TestGit->commit($repo);

    TestGit->tag($repo, tag => 'TAG');

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
    );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    TestUtils->create_ci('bl', bl => 'TAG');

    my $body =
        "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/TAG\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => {params => {}, body => $fh},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my ($event) =
      mdb->event->find({event_key => 'event.repository.update'})->all;

    ok !$event;

    my $error = $c->res->body;

    like $error, qr/Cannot update internal tag TAG/;
};

subtest 'git: allows pushing system tags when user has permission' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    my $sha = TestGit->commit($repo);

    TestGit->tag($repo, tag => 'TAG');

    my $project = TestUtils->create_ci(
        'project',
        name         => 'Project',
        repositories => [$repo->mid]
    );

    my $controller = _build_controller();

    my $stash = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home   => $repo->repo_dir . '/../'
        }
    };

    TestUtils->create_ci('bl', bl => 'TAG');

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
                project => [$project->mid]
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
        req      => {params => {}, body => $fh},
        stash    => $stash
    );

    $controller->git($c, '.git');

    my ($event) =
      mdb->event->find({event_key => 'event.repository.update'})->all;

    my $data = _load $event->{event_data};

    is $data->{branch}, 'TAG';
    is $data->{ref},    'refs/tags/TAG';
    is $data->{sha},    $sha;
};

done_testing;

sub _build_controller {
    my $controller = Baseliner::Controller::GitSmart->new(application => '');
    $controller = Test::MonkeyMock->new($controller);

    $controller->mock(wrap_cgi_stream => sub { });

    return $controller;
}

sub _setup {
    TestUtils->setup_registry('BaselinerX::Type::Event', 'BaselinerX::CI',
        'BaselinerX::Events');

    TestUtils->cleanup_cis;

    mdb->event->drop;
    mdb->role->drop;

    TestUtils->create_ci('user', name => 'foo', username => 'foo');
}
