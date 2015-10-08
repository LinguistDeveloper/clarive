use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::MockSleep;

use lib 't/lib';
use TestEnv;
use TestUtils ':catalyst';

TestEnv->setup;

use POSIX ":sys_wait_h";
use JSON ();
use Baseliner::Role::CI;
use Baseliner::Model::Topic;
use Baseliner::RuleFuncs;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Fieldlet;
use BaselinerX::Fieldlets;
use Baseliner::Queue;

use Baseliner::Controller::Topic;
use Baseliner::Model::Topic;
use Class::Date;

subtest 'kanban config save' => sub {
    _setup();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid, statuses=>[ $base_params->{status_new} ]  } } );
    $controller->kanban_config($c);
    ok ${ $c->stash->{json}{success} };

    $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config( $c );
    is $c->stash->{json}{config}{statuses}->[0], $base_params->{status_new};
};

subtest 'kanban no config, default' => sub {
    _setup();
    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update({ %$base_params, action=>'add' });
    my $controller = _build_controller();
    my $c = _build_c( req => { params => { mid=>$topic_mid } } );
    $controller->kanban_config($c);
    is keys %{ $c->stash->{json}{config} }, 0;
};

############ end of tests

sub _build_c {
    mock_catalyst_c( username => 'test', @_ );
}

sub _setup {
    Baseliner::Core::Registry->clear();
    TestUtils->register_ci_events();
    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::Topic->new( application => '' );
}

sub _topic_setup {
    mdb->topic->drop;
    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;
    mdb->category->drop;
    mdb->rule->drop;

    Baseliner::Core::Registry->add_class( undef, 'event'    => 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add_class( undef, 'fieldlet' => 'BaselinerX::Type::Fieldlet' );

    Baseliner::Core::Registry->add( 'caller', 'event.topic.create', {} );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.system.status_new' => {
            bd_field  => 'id_category_status',
            id_field  => 'status_new',
            origin    => 'system',
            meta_type => 'status'
        }
    );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.required.category' => {
            id_field => 'category',
            bd_field => 'id_category',
            origin   => 'system',
        }
    );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.system.projects' => {
            get_method => 'get_projects',
            set_method => 'set_projects',
            meta_type  => 'project',
            relation   => 'system',
        }
    );

    my $status_id = ci->status->new( type => 'I' )->save;

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_type => "form",
            rule_seq  => $id_rule,
            rule_tree => JSON::encode_json(
                [
                    {
                        "attributes" => {
                            "data" => {
                                "bd_field"     => "id_category_status",
                                "name_field"   => "Status",
                                "fieldletType" => "fieldlet.system.status_new",
                                "id_field"     => "status_new",
                            },
                            "key" => "fieldlet.system.status_new",
                        }
                    },
                    {
                        "attributes" => {
                            "data" => {
                                "bd_field"     => "project",
                                "fieldletType" => "fieldlet.system.projects",
                                "id_field"     => "project",
                            },
                            "key" => "fieldlet.system.projects",
                        }
                    }
                ]
            )
        }
    );

    my $cat_id = mdb->seq('id');
    mdb->category->insert(
        { id => "$cat_id", name => 'Category', statuses => [$status_id], default_form => "$id_rule" } );

    my $project = ci->project->new( name => 'Project' );
    my $project_mid = $project->save;

    return {
        'project'    => $project_mid,
        'category'   => "$cat_id",
        'status_new' => "$status_id",
    };

}

done_testing;

