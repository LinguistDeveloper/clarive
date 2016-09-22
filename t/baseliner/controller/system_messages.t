use strict;
use warnings;

use Date::Parse;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(mock_time);
use TestSetup;

use_ok 'Baseliner::Model::SystemMessages';

subtest 'create: fails if title is not present' => sub {
    _setup();
    _create_user_with_admin_permissions();

    my $model = _build_model();
    my $p = {
        username => 'sms_user'
    };

    like exception { $model->create( $p ) }, qr/Missing message title/;

};

subtest 'create: fails if text is not present' => sub {
    _setup();
    _create_user_with_admin_permissions();

    my $model = _build_model();
    my $p = {
        username => 'sms_user',
        title => 'title'
    };

    like exception { $model->create($p) }, qr/Missing message text/;
};

subtest 'create: creates mdb entry in sms' => sub {
    _setup();
    _create_user_with_admin_permissions();

    my $user1 = TestSetup->create_user( name => 'test1', username => 'test1');
    my $user2 = TestSetup->create_user( name => 'test2', username => 'test2');

    my $sms_id = _create_sms(users => [ $user1->{mid}, $user2->{mid} ]);
    my $sms = mdb->sms->find_one({_id=>$sms_id});
    cmp_deeply $sms, {
        username => 'sms_user',
        more     => 'more',
        _id      => ignore(),
        title    => 'title',
        users    => [ 'test1', 'test2' ],
        ua       => undef,
        expires  => ignore(),
        text     => 'text',
        ts       => ignore()
    }
};

subtest 'create: creates event for sms creation' => sub {
    _setup();
    _create_user_with_admin_permissions();

    my $model = _build_model();

    $model->create(
        {   username => 'sms_user',
            title    => 'title',
            text     => 'text',
            more     => 'more'
        }
    );

    my $sms_id = mdb->sms->find_one()->{_id};
    my $events = _build_events_model();
    my $rv = $events->find_by_key('event.sms.new');

    cmp_deeply $rv->[0],
      {
        'event_key'  => 'event.sms.new',
        'event_data' => ignore(),
        'expire'     => ignore(),
        'more'       => 'more',
        'subject'    => 'System message title created',
        'text'       => 'text',
        'title'      => 'title',
        'ts'         => ignore(),
        'username'   => 'sms_user',
        'mid'        => undef,
        'rules_exec' => {
            'event.sms.new' => {
                'post-online' => 0,
                'pre-online'  => 0
            }
        },
        'id'           => $sms_id,
        'module'       => ignore(),
        'event_status' => 'new',
        't'            => ignore(),
        '_id'          => ignore(),
      };

};

subtest 'cancel: fails when sms id is not provided' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->cancel( ) }, qr/Missing message id/;
};

subtest 'cancel: updates expire time to now' => sub {
    _setup();

    my $sms_id = mock_time '2016-01-01 00:00:00', sub { _create_sms() };

    my $model = _build_model();

    mock_time '2016-01-01 13:21:08', sub { $model->cancel( {id => $sms_id, username => 'test1' }) };

    my $sms = mdb->sms->find_one();

    is $sms->{expires}, '2016-01-01 13:21:08';
};

subtest 'cancel: creates event for sms cancellation' => sub {
    _setup();

    my $sms_id = _create_sms();

    my $model = _build_model();
    mock_time '2016-01-01 13:21:08', sub { $model->cancel( {id => $sms_id, username => 'test1' }) };

    my $events = _build_events_model();
    my $rv = $events->find_by_key('event.sms.cancel');

    cmp_deeply $rv->[0],
      {
        'event_key'  => 'event.sms.cancel',
        'event_data' => ignore(),
        'ua'         => ignore(),
        'subject'    => 'System message ' . $sms_id . ' canceled',
        'ts'         => ignore(),
        'username'   => 'test1',
        'mid'        => undef,
        'rules_exec' => {
            'event.sms.cancel' => {
                'post-online' => 0,
                'pre-online'  => 0
            }
        },
        'id'           => $sms_id,
        'module'       => ignore(),
        'event_status' => 'new',
        't'            => ignore(),
        '_id'          => ignore(),
      };

};

subtest 'delete: fails when sms id is not provided' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->delete( ) }, qr/Missing message id/;
};

subtest 'delete: deletes sms' => sub {
    _setup();

    my $sms_id = _create_sms();

    my $model = _build_model();

    $model->delete( {id => $sms_id, username => 'test1' });

    my $sms = mdb->sms->find_one();
    is $sms, undef;
};

subtest 'delete: creates event for sms deletion' => sub {
    _setup();

    my $sms_id = _create_sms();

    my $model = _build_model();
    $model->delete( {id => $sms_id, username => 'test1' });

    my $events = _build_events_model();
    my $rv = $events->find_by_key('event.sms.remove');
    use Data::Dumper;

    cmp_deeply $rv->[0],
      {
        'event_key'  => 'event.sms.remove',
        'event_data' => ignore(),
        'ua'         => ignore(),
        'subject'    => 'System message ' . $sms_id . ' remove',
        'ts'         => ignore(),
        'username'   => 'test1',
        'mid'        => undef,
        'rules_exec' => {
            'event.sms.remove' => {
                'post-online' => 0,
                'pre-online'  => 0
            }
        },
        'id'           => $sms_id,
        'module'       => ignore(),
        'event_status' => 'new',
        't'            => ignore(),
        '_id'          => ignore(),
      };

};

subtest 'sms_get: fails when sms id is not provided' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->sms_get( ) }, qr/Missing message id/;
};

subtest 'sms_get: fails when username is not provided' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->sms_get({id => 'id'}) }, qr/Missing username/;
};

subtest 'sms_get: updates shown user' => sub {
    _setup();
    my $model = _build_model();

    my $sms_id = _create_sms();
    my $sms = mdb->sms->find_one({_id=>$sms_id});

    my $msg = $model->sms_get({id => $sms_id, username => 'sms_test'});

    is $sms->{shown}, undef;
    cmp_deeply $msg->{shown}[0], {
        u   => 'sms_test',
        ts  => ignore(),
        ua  => '',
        add => ''
    }
};

subtest 'sms_list: gets a list of expired and non expired sms' => sub {
    _setup();

    mock_time '2016-01-01 00:00:00', sub { _create_sms() };
    _create_sms();

    my $model = _build_model();
    my @sms = $model->sms_list();

    is scalar @sms, 2;
    cmp_deeply $sms[0]->{expired}, \0;
    cmp_deeply $sms[1]->{expired}, \1;
};

done_testing();

sub _setup {
    TestUtils->setup_registry(
        'Baseliner::Model::SystemMessages',
        'BaselinerX::Type::Event',
        'BaselinerX::CI'
    );

    TestUtils->cleanup_cis();

    mdb->sms->drop;
    mdb->event->drop;
    mdb->event_log->drop;
}

sub _build_model {
    return Baseliner::Model::SystemMessages->new();
}

sub _create_user_with_admin_permissions {
    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.admin.sms' } ] );

    return TestSetup->create_user( name => 'sms_user', username => 'sms_user', id_role => $id_role, project => $project );
}


sub _build_events_model {
    return Baseliner::Model::Events->new();
}

sub _create_sms {
    my (%params) = @_;
    my $admin_user = _create_user_with_admin_permissions();
    return TestSetup->create_sms(username => $admin_user->username, %params);
}
