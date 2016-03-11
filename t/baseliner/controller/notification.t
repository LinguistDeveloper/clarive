use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';

use_ok 'Baseliner::Controller::Notification';

subtest 'list_notifications: returns notifications' => sub {
    _setup();

    mdb->notification->insert(
        {   event_key     => 'event.auth.cas_ok',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}'

        },
    );
    my $controller = _build_controller();
    my $c = _build_c();

    $controller->list_notifications($c);

    my $data = $c->stash->{json}{data};

    is $data->[0]->{event_key}, 'event.auth.cas_ok';
};

subtest 'list_notifications: search with special characters + -' => sub {
    _setup();

    mdb->notification->insert(
        {   event_key     => 'event.auth.cas_ok',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}'

        },
    );
    mdb->notification->insert(
        {   event_key     => 'event.job.run',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}'

        },
    );
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { query => '+auth -job' } } );

    $controller->list_notifications($c);

    my $data = $c->stash->{json}{data};

    is $data->[0]->{event_key}, 'event.auth.cas_ok';
    is $data->[1]->{event_key}, undef;

};

subtest 'list_notifications: searches notification that exist' => sub {
    _setup();

    mdb->notification->insert(
        {   event_key     => 'event.auth.cas_ok',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}'

        },
    );
    mdb->notification->insert(
        {   event_key     => 'event.job.run',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}'

        },
    );
    my $controller = _build_controller();

    my $cnt = mdb->notification->count();
    my $c = _build_c( req => { params => { query => 'event.job' } } );

    $controller->list_notifications($c);

    my $data = $c->stash->{json}{data};

    is $cnt, '2';
    is $data->[0]->{event_key}, 'event.job.run';
    is $data->[1], undef;
};

subtest 'list_notifications: search a notification does not exist' => sub {
    _setup();

    mdb->notification->insert(
        {   event_key     => 'event.auth.cas_ok',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}'

        },
    );
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { query => 'event.job' } } );

    $controller->list_notifications($c);

    my $data = $c->stash->{json}{data};

    is $data->[0]->{event_key}, undef;
};

sub _setup {
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->notification->drop;
    mdb->index_all('notification');

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::Auth', 'BaselinerX::Job' );
}

sub _build_controller {

    my $controller = Baseliner::Controller::Notification->new( application => '' );

    return $controller;
}

sub _build_c { mock_catalyst_c(@_); }

done_testing;
