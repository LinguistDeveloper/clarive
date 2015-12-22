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

subtest 'git: creates event on push' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository(name => 'Repo');
    TestGit->commit($repo);

    my $project = TestUtils->create_ci('project', name => 'Project', repositories => [$repo->mid]);

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    my $controller = _build_controller();

    my $stash  = {
        git_config => {
            gitcgi => '../local/libexec/git-core/git-http-backend',
            home => $repo->repo_dir . '/../'
        }
    };

    my $body = "$sha $sha2 refs/heads/master\x00 report-status side-band" ;
    open my $fh, '<', \$body;

    my $c = mock_catalyst_c(
        username => 'foo',
        req      => { params => {}, body => $fh },
        stash    => $stash
    );

    $controller->git($c, '.git');

    my ($event) = mdb->event->find({event_key => 'event.repository.update'})->all;

    my $data = _load $event->{event_data};

    is $data->{branch},   'master';
    is $data->{username}, 'foo';
    is $data->{message},  'update';
    is $data->{diff}, '';
    is $data->{ref},  'refs/heads/master';
    is $data->{sha},  $sha2;
};

done_testing;

sub _build_controller {
    my $controller = Baseliner::Controller::GitSmart->new( application => '' );
    $controller = Test::MonkeyMock->new($controller);

    $controller->mock(wrap_cgi_stream => sub {});

    return $controller;
}

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::Events' );

    TestUtils->cleanup_cis;

    mdb->event->drop;
}
