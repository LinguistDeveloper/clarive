use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(:catalyst mock_time);
use TestSetup;


use_ok 'Baseliner::Controller::Label';

subtest 'list: returns labels' => sub {
     _setup();

    my $label_id = TestSetup->create_label(name => "MyLabel");

    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

    $controller->list($c);
    my $data = $c->stash->{json}->{data};

    is $data->[0]->{name}, 'MyLabel';
    ok (mdb->label->find_one({name => 'MyLabel'}));
};

subtest 'grid: sets correct template' => sub {
     _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => {} } );

    $controller->grid($c);

    is $c->stash->{template}, '/comp/label_admin.js';
};

subtest 'attach: user with permission to attach labels can attach labels' => sub {
    _setup();

    my $label_id = TestSetup->create_label();
    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [ { action => 'action.labels.attach_labels' } ] );
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );
    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                ids => ["$label_id"]
            }
        }
    );
    $controller->attach($c);

    cmp_deeply( $c->stash,
        { json => { msg => re(qr/Labels assigned/), success => \1 } } );

    ok (mdb->label->find_one({id => $label_id}));
    ok (mdb->topic->find_one({mid => $topic_mid, labels =>[$label_id]}));
};

subtest 'attach: user without permission to attach labels can not attach labels' => sub {
    _setup();

    my $label_id = TestSetup->create_label();
    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );
    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                ids => ["$label_id"]
            }
        }
    );
    $controller->attach($c);

    cmp_deeply( $c->stash, { json => { msg => re(qr/Error assigning Labels/), success => \0 } } );

    ok (mdb->label->find_one({id => $label_id}));
    ok !(mdb->topic->find_one({mid => $topic_mid, labels =>[$label_id]}));
};

subtest 'detach: detaches a label properly if user has permission' => sub {
    _setup();

    my $label_id = TestSetup->create_label();
    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(actions => [ { action => 'action.labels.remove_labels' } ] );
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
        labels      => [$label_id]
    );
    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                ids => ["$label_id"]
            }
        }
    );
    $controller->detach($c, $topic_mid, $label_id );

    cmp_deeply( $c->stash,
        { json => { msg => re(qr/Label deleted/), success => \1 } } );

    ok (mdb->label->find_one({id => $label_id}));
    ok !(mdb->topic->find_one({mid => $topic_mid, labels =>[$label_id]}));
};

subtest 'detach: user without permission to detach can not detach a label' => sub {
    _setup();

    my $label_id = TestSetup->create_label();
    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
        label       => $label_id

    );
    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                topic_mid => $topic_mid,
                ids => ["$label_id"]
            }
        }
    );
    $controller->detach($c, $topic_mid, $label_id );

    cmp_deeply( $c->stash, { json => { msg => re(qr/does not have permissions to detach a label/), success => \0 } } );
    ok (mdb->label->find_one({id => $label_id}));
    ok (mdb->topic->find_one({mid => $topic_mid, label =>$label_id}));
};

subtest 'update: creates a new label if action is add' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );
    my $controller = _build_controller();

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                action => 'add',
                color  => '#000000',
                name   => 'MyLabel',
                seq    => 123
            }
        }
    );
    $controller->update($c);

    cmp_deeply( $c->stash, { json => { msg => re(qr/Label added/), success => \1 } } );

    my $new_label = mdb->label->find_one( { name => 'MyLabel' } );

    is $new_label->{name},  'MyLabel';
    is $new_label->{seq},   '123';
    is $new_label->{color}, '#000000';
};

subtest 'update: does not create label if the name already exists' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );
    my $controller = _build_controller();

    mdb->label->insert( { id => 123, name => 'MyLabel' } );

    my $c = _build_c(
        username => $user->username,
        req      => {
            params => {
                action => 'add',
                color  => '#000000',
                name   => 'MyLabel',
                seq    => 123
            }
        }
    );
    $controller->update($c);

    cmp_deeply(
        $c->stash,
        {
            json => {
                msg     => re(qr/Validation failed/),
                errors  => { name => re(qr/Label name already exists/) },
                success => \0
            }
        }
    );
};

subtest 'update: updates label' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );

    my $label_id = TestSetup->create_label( name => 'MyLabel', color => '#000000', seq => 123 );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                id     => $label_id,
                action => 'update',
                name   => 'New Value',
                color  => '#123123',
                seq    => 321
            }
        }
    );
    $controller->update($c);

    cmp_deeply( $c->stash, { json => { msg => re(qr/Label modified/), success => \1} } );

    my $updated_label = mdb->label->find_one( { id => $label_id } );

    is $updated_label->{name},  'New Value';
    is $updated_label->{seq},   '321';
    is $updated_label->{color}, '#123123';
};

subtest 'update: updates label with the same name' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );

    my $label_id = TestSetup->create_label( name => 'MyLabel', color => '#000000', seq => 123 );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                id     => $label_id,
                action => 'update',
                name   => 'MyLabel',
                color  => '#123123',
                seq    => 321
            }
        }
    );
    $controller->update($c);

    cmp_deeply( $c->stash, { json => { msg => re(qr/Label modified/), success => \1} } );

    my $updated_label = mdb->label->find_one( { id => $label_id } );

    is $updated_label->{name},  'MyLabel';
};

subtest 'update: returns an error when new name already exists' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );

    TestSetup->create_label( name => 'OtherLabel', color => '#000000', seq => 123 );

    my $label_id = TestSetup->create_label( name => 'MyLabel', color => '#000000', seq => 123 );

    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                id     => $label_id,
                action => 'update',
                name   => 'OtherLabel',
                color  => '#123123',
                seq    => 321
            }
        }
    );
    $controller->update($c);

    cmp_deeply(
        $c->stash,
        {
            json => {
                msg     => re(qr/Validation failed/),
                errors  => { name => re(qr/Label name already exists/) },
                success => \0
            }
        }
    );
};

subtest 'delete: removes a label properly' => sub {
    _setup();

    my $label_id = TestSetup->create_label(name => "MyLabel" );
    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'changeset',
        id_rule      => $id_changeset_rule,
        is_changeset => 1
    );
    my $topic_mid = TestSetup->create_topic(
        username    => $user->username,
        id_category => $id_changeset_category,
        project     => $project,
    );
    my $controller = _build_controller();
    my $c          = _build_c(
        username => $user->username,
        req      => {
            params => {
                color      => '000000',
                action    => 'delete',
                label     => 'MyLabel',
                projects  => $project,
                ids => $label_id
            }
        }
    );
    $controller->delete($c);

    cmp_deeply( $c->stash, { json => { msg => re(qr/Labels deleted/), success => \1 } } );

    ok !(mdb->label->find_one({id => $label_id}));
};

done_testing;

sub _create_changeset_form {
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            }
        ],
    );
}

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _build_controller {
    Baseliner::Controller::Label->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',            'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',                     'BaselinerX::Fieldlets',
        'BaselinerX::Service::TopicServices', 'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',            'BaselinerX::LcController',
        'BaselinerX::Type::Model::ConfigStore', 'Baseliner::Model::TopicExporter'
    );
    TestUtils->cleanup_cis;

    mdb->topic->drop;
    mdb->category->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->label->drop;
}
