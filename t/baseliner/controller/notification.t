use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';
use TestSetup;

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

subtest 'list_type_recipients: gets the list of type recipients' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();
    $controller->list_type_recipients($c);

    is_deeply $c->stash->{json},
        [
        { type_recipient => 'Default', id => 'Default' },
        { type_recipient => 'Users',   id => 'Users' },
        { type_recipient => 'Roles',   id => 'Roles' },
        { type_recipient => 'Actions', id => 'Actions' },
        { type_recipient => 'Fields',  id => 'Fields' },
        { type_recipient => 'Owner',   id => 'Owner' },
        { type_recipient => 'Emails',  id => 'Emails' },
        ];
};

subtest 'get_recipients: gets recipients type Default' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();
    $controller->get_recipients( $c, 'Default' );

    is_deeply $c->stash->{json},
        {
        success    => \1,
        data       => [ { name => 'Default', id => 'Default' } ],
        field_type => 'none'
        };
};

subtest 'get_recipients: gets recipients type Emails' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c();
    $controller->get_recipients( $c, 'Emails' );

    is_deeply $c->stash->{json},
        {
        success    => \1,
        data       => [ { name => 'Emails', id => 'Emails' } ],
        field_type => 'textfield'
        };
};

subtest 'get_recipients: gets recipients type Users' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( username => 'user', id_role => $id_role, project => $project );

    my $controller = _build_controller();
    my $c          = _build_c();
    $controller->get_recipients( $c, 'Users' );

    is_deeply $c->stash->{json},
        {
        success    => \1,
        data       => [ { name => 'user', id => $user->mid, description => '' } ],
        field_type => 'combo'
        };
};

done_testing;

sub _setup {
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->notification->drop;
    mdb->index_all('notification');
    mdb->role->drop;

    TestUtils->setup_registry(
        'BaselinerX::Type::Event', 'BaselinerX::Auth', 'BaselinerX::Job', 'Baseliner::Model::Jobs',
        'BaselinerX::CI'
    );
}

sub _build_controller {

    my $controller = Baseliner::Controller::Notification->new( application => '' );

    return $controller;
}

sub _build_c { mock_catalyst_c(@_); }
