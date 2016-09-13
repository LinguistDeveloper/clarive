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
        'Baseliner::Model::Label'
    );

    Baseliner::Core::Registry->initialize;

    TestUtils->cleanup_cis;

    mdb->role->drop;
    mdb->rule->drop;
    mdb->category->drop;
}

sub _build_model {
    return Baseliner::Model::Notification->new();
}
