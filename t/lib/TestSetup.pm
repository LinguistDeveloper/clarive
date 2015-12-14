package TestSetup;

use strict;
use warnings;

use base 'Exporter';
use TestUtils;

our @EXPORT_OK = qw(_setup_user _setup_clear _topic_setup);

use Carp;
use JSON ();
use Baseliner::CI;
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Fieldlet;

sub _setup_clear {
    Baseliner::Core::Registry->clear();
    TestUtils->cleanup_cis();
    TestUtils->register_ci_events();
}

sub _setup_user {
    my $user = ci->user->new( name=>'root', username=>'root' );
    $user->save;
    $user = ci->user->new( name=>'test', username=>'test' );
    $user->save;
}

sub _topic_setup {
    mdb->topic->drop;
    mdb->category->drop;
    mdb->rule->drop;

    Baseliner::Core::Registry->add_class( undef, 'event'    => 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->add_class( undef, 'fieldlet' => 'BaselinerX::Type::Fieldlet' );

    Baseliner::Core::Registry->add( 'caller', 'event.topic.create', {} );
    Baseliner::Core::Registry->add( 'caller', 'event.file.create', {} );

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

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.system.list_topics' => {
            get_method  => 'get_topics',
            set_method  => 'set_topics',
            meta_type   => 'topic',
            relation    => 'system',
        }
    );

    Baseliner::Core::Registry->add(
        'caller',
        'fieldlet.attach_file' => {
            get_method  => 'get_files',
            type        => 'upload_files',
        }
    );

    my $status_id = ci->status->new( name=>'New', type => 'I' )->save;

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_type => "form",
            rule_seq  => $id_rule,
            rule_tree => JSON::encode_json(_fieldlets())
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
        'status'     => "$status_id",
        id_rule      => "$id_rule",
        'category_status' => { id=>"$status_id" },
    };
}

sub _topic_release_category {
    my $self = shift;
    my ($base_params) = @_;
    my $cat_id = mdb->seq('id');
    mdb->category->insert(
        { id => "$cat_id", name => 'Release', is_release=>"1", statuses => [$base_params->{status}], default_form => "$base_params->{id_rule}" } );
    return $cat_id;
}

sub _fieldlets {
    return [
        {
            "attributes" => {
                "data" => {
                    "bd_field"     => "id_category_status",
                    "name_field"   => "Status",
                    "fieldletType" => "fieldlet.system.status_new",
                    "id_field"     => "status_new",
                    "name_field"   => "Status",
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
                    "name_field"   => "Project",
                },
                "key" => "fieldlet.system.projects",
            }
        },
        {
            "attributes" => {
                "data" => {
                    "bd_field"      => "parent",
                    "fieldletType"  => "fieldlet.system.list_topics",
                    "parent_field"  => "children",
                    "id_field"      => "parent",
                    "name_field"    => "Parent topics",
                    "editable"      => "1",
                },
                "key" => "fieldlet.system.list_topics",
            }
        },
        {
            "attributes" => {
                "data" => {
                    "bd_field"      => "children",
                    "fieldletType"  => "fieldlet.system.list_topics",
                    "id_field"      => "parent",
                    "name_field"    => "Child topics",
                    "editable"      => "1",
                },
                "key" => "fieldlet.system.list_topics",
            }
        },
        {
           "attributes" => {
               "data" => {
                   "bd_field"      => "test_file",
                   "fieldletType"  => "fieldlet.attach_file",
                   "id_field"      => "test_file",
                   "name_field"    => "Files",
                   "editable"      => "1",
               },
               "key" => "fieldlet.attach_file",
           }
        }
    ];
}

sub _setup_label {
    Baseliner::Core::Registry->add( 'caller', 'event.file.labels', {} );
    my $id = mdb->seq('label');
    mdb->label->insert({ color=> '#99CC00', id=> '', name=>'label', sw_allprojects=>1 });
    return $id;
}

1;
