package TestSetup;

use strict;
use warnings;

use base 'Exporter';
use TestUtils;

our @EXPORT_OK = qw(_setup_user _setup_clear _topic_setup);

use Carp;
use JSON ();
use Capture::Tiny qw(capture);
use Baseliner::CI;
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use Baseliner::Model::Topic;
use BaselinerX::Type::Fieldlet;
use BaselinerX::CI::job;

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

    my $id_label = mdb->seq('label');
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

sub create_rule {
    my $class = shift;
    my (%params) = @_;

    if ( $params{rule_tree} && ref $params{rule_tree} ) {
        $params{rule_tree} = JSON::encode_json( $params{rule_tree} );
    }

    my $id_rule  = mdb->seq('rule');
    my $seq_rule = 0 + mdb->seq('rule_seq');
    my $ts       = delete $params{ts} || '2016-01-01 00:00:00';
    mdb->rule->insert(
        {
            id          => "$id_rule",
            rule_active => 1,
            rule_name   => 'Rule',
            rule_seq    => $seq_rule,
            rule_type   => 'independent',
            ts          => $ts,
            %params,
        }
    );

    return "$id_rule";
}

sub create_rule_pipeline {
    my $class = shift;
    my (%params) = @_;

    my $id_rule = $class->create_rule(
        rule_name => 'Main Pipeline',
        rule_type => 'pipeline',
        rule_when => 'promote',
        %params,
        rule_tree => [
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "CHECK",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => []
            },
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "INIT",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => []
            },
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "PRE",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => [
                    {
                        "attributes" => {
                            "palette"        => 0,
                            "disabled"       => 0,
                            "on_drop_js"     => undef,
                            "key"            => "statement.code.server",
                            "who"            => "root",
                            "text"           => "Server CODE",
                            "expanded"       => 1,
                            "run_sub"        => 1,
                            "leaf"           => \1,
                            "active"         => 1,
                            "name"           => "Server CODE",
                            "holds_children" => 0,
                            "data"           => {
                                "lang" => "perl",
                                "code" => "sleep(10);"
                            },
                            "nested"  => "0",
                            "on_drop" => ""
                        },
                        "children" => []
                    },
                    {
                        "attributes" => {
                            "palette"        => 0,
                            "disabled"       => 0,
                            "on_drop_js"     => undef,
                            "key"            => "statement.if.var",
                            "text"           => "IF var THEN",
                            "expanded"       => 1,
                            "run_sub"        => 1,
                            "leaf"           => \0,
                            "name"           => "IF var THEN",
                            "active"         => 1,
                            "holds_children" => 1,
                            "data"           => {},
                            "nested"         => "0",
                            "on_drop"        => ""
                        },
                        "children" => [
                            {
                                "attributes" => {
                                    "palette"        => 0,
                                    "disabled"       => 0,
                                    "on_drop_js"     => undef,
                                    "key"            => "statement.code.server",
                                    "text"           => "INSIDE IF",
                                    "expanded"       => 1,
                                    "run_sub"        => 1,
                                    "leaf"           => \1,
                                    "name"           => "Server CODE",
                                    "active"         => 1,
                                    "holds_children" => 0,
                                    "data"           => {},
                                    "nested"         => "0",
                                    "on_drop"        => ""
                                },
                                "children" => []
                            },
                            {
                                "attributes" => {
                                    "icon"           => "/static/images/icons/if.svg",
                                    "palette"        => 0,
                                    "on_drop_js"     => undef,
                                    "holds_children" => 1,
                                    "nested"         => "0",
                                    "key"            => "statement.if.var",
                                    "text"           => "IF var THEN",
                                    "run_sub"        => 1,
                                    "leaf"           => \0,
                                    "on_drop"        => "",
                                    "name"           => "IF var THEN",
                                    "data"           => {},
                                    "expanded"       => 1
                                },
                                "children" => [
                                    {
                                        "attributes" => {
                                            "palette"        => 0,
                                            "on_drop_js"     => undef,
                                            "holds_children" => 0,
                                            "nested"         => "0",
                                            "key"            => "statement.code.server",
                                            "text"           => "INSIDE IF2",
                                            "run_sub"        => 1,
                                            "leaf"           => \1,
                                            "on_drop"        => "",
                                            "name"           => "Server CODE",
                                            "data"           => {},
                                            "expanded"       => 1
                                        },
                                        "children" => []
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "RUN",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => [
                    {
                        "attributes" => {
                            "palette"        => 0,
                            "disabled"       => 0,
                            "on_drop_js"     => undef,
                            "key"            => "statement.code.server",
                            "who"            => "root",
                            "text"           => "Server CODE",
                            "expanded"       => 1,
                            "run_sub"        => 1,
                            "leaf"           => \1,
                            "active"         => 1,
                            "name"           => "Server CODE",
                            "holds_children" => 0,
                            "data"           => {
                                "lang" => "perl",
                                "code" => "sleep(10);"
                            },
                            "nested"  => "0",
                            "on_drop" => ""
                        },
                        "children" => []
                    }
                ]
            },
            {
                "attributes" => {
                    "disabled" => 0,
                    "active"   => 1,
                    "key"      => "statement.step",
                    "text"     => "POST",
                    "expanded" => 1,
                    "leaf"     => \0,
                },
                "children" => [
                    {
                        "attributes" => {
                            "palette"        => 0,
                            "disabled"       => 0,
                            "on_drop_js"     => undef,
                            "key"            => "statement.code.server",
                            "who"            => "root",
                            "text"           => "Server CODE",
                            "expanded"       => 1,
                            "run_sub"        => 1,
                            "leaf"           => \1,
                            "active"         => 1,
                            "name"           => "Server CODE",
                            "holds_children" => 0,
                            "data"           => {
                                "lang" => "perl",
                                "code" => "sleep(10);"
                            },
                            "nested"  => "0",
                            "on_drop" => ""
                        },
                        "children" => []
                    }
                ]
            }
        ]
    );

    return "$id_rule";
}

sub create_rule_with_code {
    my $class = shift;
    my (%params) = @_;

    my $lang = delete $params{lang} || 'perl';
    my $code = delete $params{code};

    my $id_rule = $class->create_rule(
        %params,
        rule_tree => [
            {
                "attributes" => {
                    "key"  => "statement.code.server",
                    "text" => "Server CODE",
                    "name" => "Server CODE",
                    "data" => {
                        "lang" => $lang,
                        "code" => $code
                    },
                },
            }
        ]
    );

    return "$id_rule";
}

sub create_rule_form {
    my $class = shift;
    my (%params) = @_;

    return $class->create_rule(
        rule_name => 'Form',
        rule_type => "form",
        rule_when => 'post-offline',
        %params
    );
}

sub create_rule_form_changeset {
    my $class = shift;
    my (%params) = @_;

    return TestSetup->create_rule_form(
        rule_name => 'Changeset',
        rule_tree => [
            _build_stmt(
                id   => 'title',
                name => 'Title',
                type => 'fieldlet.system.title'
            ),
            _build_stmt(
                id       => 'status_new',
                bd_field => 'id_category_status',
                name     => 'Status',
                type     => 'fieldlet.system.status_new'
            ),
            _build_stmt(
                id   => 'project',
                name => 'Project',
                type => 'fieldlet.system.projects'
            ),
            _build_stmt(
                id   => 'release',
                name => 'Release',
                type => 'fieldlet.system.release'
            ),
            _build_stmt(
                id   => 'revisions',
                name => 'Revisions',
                type => 'fieldlet.system.revisions'
            ),
            @{ delete $params{rule_tree} || [] }
        ],
        %params
    );
}

sub create_category {
    my $class = shift;
    my (%params) = @_;

    my $id_status = delete $params{id_status} || ci->status->new( name => 'New', type => 'I' )->save;
    my $id_rule = delete $params{id_rule};

    my $id_cat = mdb->seq('category');
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

sub create_changeset {
    my $self = shift;
    my (%params) = @_;

    my $project = $params{project} || TestUtils->create_ci_project();

    my $rule_options = $params{rule_options} || {};
    my $category_options = $params{category_options} || {};
    my $user_options = $params{user_options} || {};
    my $changeset_options = $params{changeset_options} || {};

    my $id_changeset_rule = $self->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "name_field"   => "Status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                        "name_field"   => "status",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {   "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type      => 'project',
                        collection     => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
            {   "attributes" => {
                    "data" => {
                        "fieldletType" => "fieldlet.system.revisions",
                        "id_field"     => "revisions",
                        "bd_field"     => "revisions",
                        "name_field"   => "Revisions",
                    },
                    "key" => "fieldlet.system.revisions",
                }
            }
        ],
        %$rule_options
    );
    my $id_changeset_category = $self->create_category( name => 'Changeset', id_rule => $id_changeset_rule, %$category_options );

    my $user = $self->create_user( %$user_options );

    my $changeset_mid = $self->create_topic(
        id_category  => $id_changeset_category,
        is_changeset => 1,
        project     => [ $project ],
        %$changeset_options
    );
}

sub create_topic {
    my $class = shift;
    my (%params) = @_;

    my $ts = mdb->ts;

    my $id_form = delete $params{form} || delete $params{id_rule} || TestSetup->create_rule_form;
    my $status = delete $params{status} || TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $username = delete $params{username} || 'developer';
    my $id_category =
      delete $params{id_category}
      || TestSetup->create_category( id_rule => $id_form, name => 'Category', id_status => $status->mid );
    my $project = delete $params{project} || TestUtils->create_ci_project;

    my $base_params = {
        'project' => ref $project eq 'ARRAY'
        ? [ map { $_->mid } @$project ]
        : $project->mid,
        'category'           => $id_category,
        'status_new'         => $status->mid,
        'status'             => $status->mid,
        'id_rule'            => $id_form,
        'category_status'    => { id => $status->mid },
        'id_category_status' => $status->mid,
    };

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update(
        {
            %$base_params,
            action   => 'add',
            title    => 'New Topic',
            username => $username,
            %params
        }
    );

    mdb->topic->update( { mid => "$topic_mid" }, { '$set' => { created_on => $ts } } );

    return $topic_mid;
}

sub create_comment {
    my $self = shift;
    my (%params) = @_;

    my $topic_mid = $params{topic_mid};
    my $text      = $params{text};

    my $post = ci->post->new(
        {
            topic      => $topic_mid,
            created_by => $params{created_by} || 'Developer',
            created_on => mdb->ts,
        }
    );
    $post->save;
    $post->put_data($text);

    return $post->mid;
}

sub create_role {
    my $class = shift;
    my (%params) = @_;

    my $id_role = mdb->seq('role');
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

    my $id_role = delete $params{id_role};
    my $project = delete $params{project};
    my $area    = delete $params{area};

    if ($id_role && ref $id_role eq 'HASH') {
        $id_role = $class->create_role(%$id_role);
    }

    my $username = delete $params{username} || 'developer';
    my $password = delete $params{password} || 'password';

    my $project_security = $params{project_security};

    if ( !$project_security && ( $id_role && $project ) ) {
        $project_security = {
            $id_role => {
                project => [ map { $_->mid } ( ref $project eq 'ARRAY' ? @$project : ($project) ) ],
                $area ? ( area => [ map { $_->mid } ( ref $area eq 'ARRAY' ? @$area : ($area) ) ] ) : (),
            }
        };
    }

    return TestUtils->create_ci(
        'user',
        name             => $username,
        username         => $username,
        password         => ci->user->encrypt_password($username, $password),
        project_security => $project_security,
        %params
    );
}


sub create_calendar {
    my $class = shift;
    my (%params) = @_;

    my $ns = $params{ns} ? delete($params{ns}) : '/';

    my $id_cal = mdb->seq('calendar');
    mdb->calendar->insert( { id => "$id_cal", active => 1, bl => '*', name => 'Calendar', ns => $ns, %params } );

    return "$id_cal";
}

sub create_sms {
    my $class = shift;
    my (%params) = @_;
    my $p = {
        title => 'title',
        text => 'text',
        more => 'more',
        %params
    };

    my $model = Baseliner::Model::SystemMessages->new();
    my $sms = $model->create($p);

    return $sms->{id};
}

sub create_job {
    my $class = shift;
    my (%params) = @_;

    my $id_rule = $class->create_rule(
        rule_when => 'promote',
        rule_tree => JSON::encode_json(
            [
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.step",
                        "text"     => "CHECK",
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.step",
                        "text"     => "INIT",
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => []
                },
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.step",
                        "text"     => "PRE",
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => [
                        {
                            "attributes" => {
                                "palette"        => 0,
                                "disabled"       => 0,
                                "on_drop_js"     => undef,
                                "key"            => "statement.code.server",
                                "who"            => "root",
                                "text"           => "Server CODE",
                                "expanded"       => 1,
                                "run_sub"        => 1,
                                "leaf"           => \1,
                                "active"         => 1,
                                "name"           => "Server CODE",
                                "holds_children" => 0,
                                "data"           => {
                                    "lang" => "perl",
                                    "code" => "sleep(10);"
                                },
                                "nested"  => "0",
                                "on_drop" => ""
                            },
                            "children" => []
                        },
                    ]
                },
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.step",
                        "text"     => "RUN",
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => [
                        {
                            "attributes" => {
                                "palette"        => 0,
                                "disabled"       => 0,
                                "on_drop_js"     => undef,
                                "key"            => "statement.code.server",
                                "who"            => "root",
                                "text"           => "Server CODE",
                                "expanded"       => 1,
                                "run_sub"        => 1,
                                "leaf"           => \1,
                                "active"         => 1,
                                "name"           => "Server CODE",
                                "holds_children" => 0,
                                "data"           => {
                                    "lang" => "perl",
                                    "code" => "sleep(10);"
                                },
                                "nested"  => "0",
                                "on_drop" => ""
                            },
                            "children" => []
                        }
                    ]
                },
                {
                    "attributes" => {
                        "disabled" => 0,
                        "active"   => 1,
                        "key"      => "statement.step",
                        "text"     => "POST",
                        "expanded" => 1,
                        "leaf"     => \0,
                    },
                    "children" => [
                        {
                            "attributes" => {
                                "palette"        => 0,
                                "disabled"       => 0,
                                "on_drop_js"     => undef,
                                "key"            => "statement.code.server",
                                "who"            => "root",
                                "text"           => "Server CODE",
                                "expanded"       => 1,
                                "run_sub"        => 1,
                                "leaf"           => \1,
                                "active"         => 1,
                                "name"           => "Server CODE",
                                "holds_children" => 0,
                                "data"           => {
                                    "lang" => "perl",
                                    "code" => "sleep(10);"
                                },
                                "nested"  => "0",
                                "on_drop" => ""
                            },
                            "children" => []
                        }
                    ]
                }
            ]
        )
    );

    my $job = BaselinerX::CI::job->new(id_rule => $id_rule, %params);
    capture { $job->save };

    return $job;
}

sub _topic_setup {
    my $status_id = ci->status->new( name=>'New', type => 'I' )->save;

    my $id_rule = mdb->seq('id');
    mdb->rule->insert(
        {
            id        => "$id_rule",
            ts        => '2015-08-06 09:44:30',
            rule_name => 'Form',
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
        'project'         => $project_mid,
        'category'        => "$cat_id",
        'status_new'      => "$status_id",
        'status'          => "$status_id",
        id_rule           => "$id_rule",
        'category_status' => { id => "$status_id" },
        'title'           => 'Topic',
        'username'        => 'test',
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
                    "id_field"     => "title",
                    "name_field"   => "Title",
                    "fieldletType" => "fieldlet.system.title",
                },
                "key" => "fieldlet.system.title",
                text => 'Title',
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

sub _build_stmt {
    my (%params) = @_;

    return {
        attributes => {
            active => 1,
            data   => {
                active       => 1,
                id_field     => $params{id},
                bd_field     => $params{bd_field} || $params{id},
                fieldletType => $params{type},
            },
            disabled       => \0,
            expanded       => 1,
            leaf           => \1,
            holds_children => \0,
            palette        => \0,
            key            => $params{type},
            name           => $params{name},
            text           => $params{name},
        },
        children => []
    };
}

1;
