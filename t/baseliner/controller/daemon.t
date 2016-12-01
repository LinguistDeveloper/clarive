use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';

use_ok 'Baseliner::Controller::Daemon';

subtest 'list: gets all daemons' => sub {
    _setup();
    my $daemon = mdb->daemon->insert(
        {   service => 'service.job.daemon',
            pid     => 123
        }
    );
    my $daemon2 = mdb->daemon->insert( { service => 'service.auth.ok' } );

    my $controller = _build_controller();
    my $c          = _build_c();
    $controller->list($c);

    is $c->stash->{json}->{totalCount}, 2;
    cmp_deeply $c->stash->{json}->{data},
        [
        {   id      => $daemon2->{value},
            service => 'service.auth.ok'
        },
        {   id      => $daemon->{value},
            pid     => '123',
            service => 'service.job.daemon'
        }
        ];
};

subtest 'list: gets daemons by query' => sub {
    _setup();
    my $daemon = mdb->daemon->insert(
        {   service => 'service.job.daemon',
            pid     => 123
        }
    );
    my $daemon2 = mdb->daemon->insert( { service => 'service.auth.ok' } );

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { query => 'auth' } } );
    $controller->list($c);

    is $c->stash->{json}->{totalCount}, 1;
    cmp_deeply $c->stash->{json}->{data},
        [
        {   id      => $daemon2->{value},
            service => 'service.auth.ok'
        }
        ];
};

done_testing;

sub _setup {
    my (%params) = @_;

    mdb->daemon->drop;
}

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    Baseliner::Controller::Daemon->new( application => '' );
}
