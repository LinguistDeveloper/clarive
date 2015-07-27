use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils;

TestEnv->setup;

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::GitTree;

subtest 'get_commits_history: returns validation errors' => sub {
    TestUtils->cleanup_cis;

    my $controller = _build_controller();

    my $params = {};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params ) );

    $controller->get_commits_history($c);

    is_deeply $c->stash,
      { json => { success => \0, msg => 'Validation failed', errors => { repo_mid => 'REQUIRED' } } };
};

subtest 'get_commits_history: returns commits' => sub {
    TestUtils->cleanup_cis;

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = FakeContext->new( req => FakeRequest->new( params => $params ) );

    $controller->get_commits_history($c);

    cmp_deeply $c->stash, {
        json => {
            success    => \1,
            msg        => 'Success loading commits history',
            totalCount => 1,
            commits    => [
                {
                    'revision' => '38405ec5',
                    'comment'  => "\n\n    initial",
                    'date'     => ignore(),
                    'author'   => ignore(),
                    'ago'      => ignore(),
                    'tags'     => 'HEAD -> master'

                }
            ]
        }
    };
};

sub _build_controller {
    Baseliner::Controller::GitTree->new( application => '' );
}

done_testing;

package FakeRequest;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{params} = $params{params};

    return $self;
}

sub parameters { &params }
sub params     { shift->{params} }

package FakeContext;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{stash} = $params{stash} || {};
    $self->{req} = $params{req};

    return $self;
}

sub stash {
    my $self = shift;

    return $self->{stash} unless @_;

    if ( @_ == 1 ) {
        return $self->{stash}->{ $_[0] };
    }

    return $self->{stash}->{ $_[0] } = $_[1];
}
sub request { &req }
sub req     { shift->{req} }
sub res     { }
sub forward { 'FORWARD' }
