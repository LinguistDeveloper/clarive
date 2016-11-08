use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

use Baseliner::Utils qw(_dump);

use_ok 'Baseliner::Model::Notification';

subtest 'decode_data: modifies key/value to mid/name' => sub {
    my $model = _build_model();

    my $output = $model->decode_data( _dump( { scopes => { status => { foo => 'bar' } } } ) );

    is_deeply $output, {
        scopes => {
            status => [
                {   mid  => 'foo',
                    name => 'bar'
                }
            ]
        }
    };
};

subtest 'decode_data: correctly decodes data' => sub {
    my $model = _build_model();

    my $output = $model->decode_data( _dump( { scopes => { step => ['bar'] } } ) );

    is_deeply $output, { scopes => { step => [ { name => 'bar' } ] } };
};

subtest 'encode_scopes: modifies mid/name to key/value' => sub {
    my $model = _build_model();

    my $output = $model->encode_scopes( ( { status => [ { mid => 'foo', name => 'bar' } ] } ) );

    is_deeply $output, { status => { 'foo' => 'bar' } };
};

subtest 'decode_data: converts list of steps names to list of hashes' => sub {
    my $model = _build_model();

    my $data = { scopes => { step => ['foo'] } };

    my $output = $model->decode_scopes( ($data), 'step' );

    is_deeply $output, [ { name => 'foo' } ];
};

subtest 'isValid: returns 1 if the value of the scopes exists in notify_scope ' => sub {
    my $model = _build_model();

    my $p = {
        data         => { scopes => { step => [ { name => 'foo' }, { name => 'bar' } ] } },
        notify_scope => { step   => 'foo' }
    };

    my $output = $model->isValid($p);

    is $output, 1;
};

subtest 'get_recipients: returns the name of the fields of type system.users' => sub {
    _setup();

    my $model = _build_model();

    my $id_rule     = _create_form();
    my $id_category = TestSetup->create_category(
        name    => 'Category',
        id_rule => $id_rule,
    );

    my $output = $model->get_recipients('Fields');
    is_deeply $output, [ { name => 'owner', id => 'owner' } ];
};

subtest 'get_recipients: returns all users' => sub {
    _setup();

    my $model = _build_model();

    my $user = TestSetup->create_user();

    my $output = $model->get_recipients('Users');
    is_deeply $output, [ { id => $user->mid, description => '', name => $user->name } ];
};

subtest 'get_recipients: returns all roles' => sub {
    _setup();

    my $model = _build_model();

    my $id_role = TestSetup->create_role();
    my $role = mdb->role->find_one( { id => $id_role } );

    my $output = $model->get_recipients('Roles');

    is_deeply $output, [ { id => $role->{id}, description => '', name => $role->{role} } ];
};

subtest 'get_recipients: returns all actions' => sub {
    _setup();

    my $model = _build_model();

    my @output = $model->get_recipients('Actions');

    like $output[0]->{id}, qr/^action./;
};

subtest 'get_rules_notifications: returns notification to user associated to the role filter by project ' => sub {
    _setup();

    my $project  = TestUtils->create_ci_project();
    my $project2 = TestUtils->create_ci_project();
    my $id_role  = TestSetup->create_role();
    my $user     = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2    = TestSetup->create_user( id_role => $id_role, project => $project2, username => 'tester' );

    my $model = _build_model();

    mdb->notification->insert(
        {   event_key     => 'event.job.end',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}',
            data          => { recipients => { TO => { Roles => { mid => $id_role } } } }

        },
    );

    my @output = $model->get_rules_notifications(
        { notify_scope => { project => [ $project->mid ] }, action => 'SEND', event_key => 'event.job.end' } );

    my ($keys) = keys %{ $output[0] };
    my $username = $user->username;

    is scalar @output, 1;
    is_deeply $output[0]->{"$keys"}->{carrier}->{TO}, { $username => 1 };
};

subtest 'get_rules_notifications: returns notification to user associated to the role filter by topic mid ' => sub {
    _setup();

    my $project     = TestUtils->create_ci_project();
    my $project2    = TestUtils->create_ci_project();
    my $id_role     = TestSetup->create_role();
    my $user        = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2       = TestSetup->create_user( id_role => $id_role, project => $project2, username => 'tester' );
    my $id_rule     = TestSetup->create_rule_form();
    my $id_category = TestSetup->create_category(
        name    => 'Category',
        id_rule => $id_rule,
    );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
    );
    mdb->topic->update( { mid => "$topic_mid" },
        { '$set' => { '_project_security' => { project => [ $project->mid ] } } } );

    my $model = _build_model();

    mdb->notification->insert(
        {   event_key     => 'event.topic.create',
            action        => 'SEND',
            is_active     => '1',
            template_path => '{}',
            data          => { recipients => { TO => { Roles => { mid => $id_role } } } }

        },
    );

    my @output
        = $model->get_rules_notifications( { mid => $topic_mid, action => 'SEND', event_key => 'event.topic.create' } );

    my ($keys) = keys %{ $output[0] };
    my $username = $user->username;

    is scalar @output, 1;
    is_deeply $output[0]->{"$keys"}->{carrier}->{TO}, { $username => 1 };
};

done_testing;

sub _create_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => { id_field => 'owner', },
                    "key"  => "fieldlet.system.users",
                    text   => 'Owner',
                }
            },
        ]
    );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Registor', 'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',             'BaselinerX::Fieldlets',
        'Baseliner::Model::Label',    'BaselinerX::Type::Service',
        'Baseliner::Model::Topic',    'Baseliner::Model::Rules',
        'BaselinerX::Type::Statement'
    );

    Baseliner::Core::Registry->initialize;

    TestUtils->cleanup_cis;

    mdb->role->drop;
    mdb->rule->drop;
    mdb->category->drop;
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    mdb->notification->drop;
    mdb->index_all('notification');
    mdb->role->drop;
}

sub _build_model {
    return Baseliner::Model::Notification->new();
}
