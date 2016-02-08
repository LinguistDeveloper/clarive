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
use Baseliner::Model::Topic;
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

sub create_label {
    my $class = shift;
    my (%params) = @_;

    my $id_label = mdb->seq('id');
    mdb->label->insert(
        {
            id    => "$id_label",
            name  => 'label',
            color => '#000000',
            %params
        }
    );

    return "$id_label";
}

sub create_rule_form {
    my $class = shift;
    my (%params) = @_;

    if ( $params{rule_tree} && ref $params{rule_tree} ) {
        $params{rule_tree} = JSON::encode_json( $params{rule_tree} );
    }

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_type => "form",
            rule_seq  => $id_rule,
            %params,
        }
    );

    return "$id_rule";
}

sub create_category {
    my $class = shift;
    my (%params) = @_;

    my $id_status = delete $params{id_status} || ci->status->new( name => 'New', type => 'I' )->save;
    my $id_rule = delete $params{id_rule};

    my $id_cat = mdb->seq('id');
    mdb->category->insert(
        {
            id       => "$id_cat",
            name     => 'Category',
            statuses => ref $id_status eq 'ARRAY' ? $id_status : [$id_status],
            $id_rule ? ( default_form => "$id_rule" ) : (),
            %params
        }
    );

    return "$id_cat";
}

sub create_topic {
    my $class = shift;
    my (%params) = @_;

    my $id_form = delete $params{form} || TestSetup->create_rule_form;
    my $status = delete $params{status} || TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $id_category =
      delete $params{id_category} || TestSetup->create_category( id_rule => $id_form, id_status => $status->mid );
    my $project = delete $params{project} || TestUtils->create_ci_project;

    my $base_params = {
        'project'         => $project->mid,
        'category'        => $id_category,
        'status_new'      => $status->mid,
        'status'          => $status->mid,
        'id_rule'         => $id_form,
        'category_status' => { id => $status->mid },
        'id_category_status' =>  $status->mid ,
    };

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update(
        {
            %$base_params,
            action => 'add',
            title  => 'New Topic',
            %params
        }
    );

    return $topic_mid;
}

sub create_role {
    my $class = shift;
    my (%params) = @_;

    my $id_role = mdb->seq('id');
    mdb->role->insert(
        {
            id      => "$id_role",
            actions => delete $params{actions} || [],
            role    => delete $params{role} || 'Role',
            %params
        }
    );

    return $id_role;
}

sub create_user {
    my $class = shift;
    my (%params) = @_;

    my $id_role = delete $params{id_role} or die 'id_role required';
    my $project = delete $params{project} or die 'project required';

    return TestUtils->create_ci(
        'user',
        name             => 'developer',
        username         => 'developer',
        project_security => {
            $id_role => {
                project => [ map { $_->mid } ( ref $project eq 'ARRAY' ? @$project : ($project) ) ]
            }
        },
        %params
    );
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
                text => 'Status',
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
                text => 'Project',
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
                text => 'Parent topics',
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
                text => 'Child topics',
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
                text => 'Files',
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
