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
    my $c          = _build_c();

    $controller->list_notifications($c);

    my $data = $c->stash->{json}{data};

    is $data->[0]->{event_key}, 'event.auth.cas_ok';
};

subtest 'list_notifications: searches with special characters + -' => sub {
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
    is @$data, '1';

};

subtest 'list_notifications: searches a notification that exist' => sub {
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
    is @$data, '1';
};

subtest 'list_notifications: searches a notification does not exist' => sub {
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

    is @$data, '0';
};

subtest 'list_status_end: inserts the final status in json data' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();
    $controller->list_status_end($c);

    my $data = $c->stash->{json}{data};

    is_deeply $data,
        [
        { name => 'REJECTED' },
        { name => 'CANCELLED' },
        { name => 'TRAPPED' },
        { name => 'TRAPPED_PAUSED' },
        { name => 'ERROR' },
        { name => 'FINISHED' },
        { name => 'KILLED' },
        { name => 'EXPIRED' }
        ];
};

subtest 'save_notification: saves final status in the scope of event.job.end' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                notification_id => '-1',
                status          => 'TRAPPED',
                event           => 'event.job.end',
                status_names    => '{"TRAPPED":"TRAPPED"}',
                recipients      => '{}',
                project         => '',
                bl              => ''
            }
        }
    );
    $controller->save_notification($c);

    my $notification = mdb->notification->find_one( { "data.scopes.status.name" => 'TRAPPED' } );

    is $notification->{data}->{scopes}->{status}[0]->{name}, 'TRAPPED';

};

subtest 'save_notification: saves bl in the scope of event.job' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                notification_id => '-1',
                event           => 'event.job.end',
                bl              => '343',
                bl_names        => '{"343":"DEV"}',
                recipients      => '{}',
                project         => '',
                status          => ''
            }
        }
    );
    $controller->save_notification($c);

    my $notification = mdb->notification->find_one( { "data.scopes.bl.name" => 'DEV' } );

    is $notification->{data}->{scopes}->{bl}[0]->{name}, 'DEV';

};

subtest 'save_notification: saves the step in the scope of event.job.start_step' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                notification_id => '-1',
                step            => 'RUN',
                event           => 'event.job.start_step',
                step_names      => '["RUN"]',
                recipients      => '{}',
                project         => '',
                bl              => ''
            }
        }
    );
    $controller->save_notification($c);

    my $notification = mdb->notification->find_one( { "data.scopes.step.name" => 'RUN' } );

    is $notification->{data}->{scopes}->{step}[0]->{name}, 'RUN';
};

done_testing;

sub _setup {
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->notification->drop;
    mdb->index_all('notification');

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::Auth', 'BaselinerX::Job', 'Baseliner::Model::Jobs' );
}

sub _build_controller {

    my $controller = Baseliner::Controller::Notification->new( application => '' );

    return $controller;
}

sub _build_c { mock_catalyst_c(@_); }
