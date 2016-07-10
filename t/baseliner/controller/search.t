use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils ':catalyst';

use_ok 'Baseliner::Controller::Search';

subtest 'providers: sorts providers' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();

    $controller->providers($c);

    is_deeply(
        $c->stash,
        {
            json => {

                providers => [
                    {
                        'type' => 'Job',
                        'pkg'  => 'Baseliner::Model::Jobs',
                        'name' => 'Jobs'
                    },
                    {
                        'pkg'  => 'Baseliner::Model::Topic',
                        'type' => 'Topic',
                        'name' => 'Topics'
                    },
                    {
                        'name' => 'CIs',
                        'pkg'  => 'Baseliner::Controller::CI',
                        'type' => 'CI'
                    }
                ]
            }
        }
    );
};

done_testing;

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Search->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'Baseliner::Controller::CI',
        'Baseliner::Model::Jobs',
        'Baseliner::Model::Topic',
    );
}

sub _build_c {
    mock_catalyst_c( username => 'root', @_ );
}
