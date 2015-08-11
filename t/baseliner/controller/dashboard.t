use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst', 'mock_time';

BEGIN {
    TestEnv->setup;
}

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::Dashboard;

use Test::MockTime qw(set_absolute_time restore_time);

subtest 'roadmap: week ranging from and until' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { username => 'root', weeks_from=>1, weeks_until=>1 } } );

    mock_time '2014-07-02T00:00:00Z' => sub {
        $controller->roadmap($c);
    };
    my $stash = $c->stash;
    is @{ $stash->{json}{data} }, 3, 'is three days';
};

############ end of tests

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _setup {
    Baseliner::Core::Registry->clear();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::Dashboard->new( application => '' );
}

done_testing;
