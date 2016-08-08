use strict;
use warnings;

use Test::More;
use Test::Deep;
use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils ':catalyst';

use_ok 'Baseliner::Controller::Message';

subtest 'to_and_cc: without params' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();

    $controller->to_and_cc($c);

    is ${ $c->stash->{json}->{success} }, 1;
};

subtest 'to_and_cc: with params' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = mock_catalyst_c(
        username => 'root',
        req      => { params => { query => 'user/1300', deny_email => 1 } }
    );

    $controller->to_and_cc($c);
    cmp_deeply $c->stash,
        {
        json => {
            success => \1,
            data    => [
                {   id   => 'user\/1300',
                    long => '',
                    name => 'user\/1300',
                    ns   => 'user\/1300',
                    type => 'Email'
                }
            ],
            totalCount => 1
        }
        };
};

done_testing;

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Message->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry( 'Baseliner::Controller::CI',
        'Baseliner::Model::Jobs', 'Baseliner::Model::Topic', );
}

sub _build_c {
    mock_catalyst_c( username => 'root', @_ );
}

