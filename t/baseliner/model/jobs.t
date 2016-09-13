use strict;
use warnings;

use Test::More;
use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils;

use JSON ();
use Capture::Tiny qw(capture);
use BaselinerX::CI::job;
use BaselinerX::Type::Model::ConfigStore;

use_ok 'Baseliner::Model::Jobs';

subtest 'monitor: returns progress 100% when job finished' => sub {
    _setup();

    my $changeset_mid = _create_changeset();

    my $job = _create_job( changesets => [$changeset_mid] );
    $job->status('FINISHED');
    $job->save;

    my $model = _build_model();

    my ( $count, @rows ) = $model->monitor( { username => 'root', query_id => -1 } );

    is $rows[0]->{progress}, '100%';
};

subtest 'monitor: returns progress start' => sub {
    _setup();

    my $changeset_mid = _create_changeset();

    my $job = _create_job( changesets => [$changeset_mid] );

    my $model = _build_model();

    my ( $count, @rows ) = $model->monitor( { username => 'root', query_id => -1 } );

    is $rows[0]->{progress}, ' 0% (0/4)';
};

subtest 'monitor: returns progress in beetween' => sub {
    _setup();

    my $changeset_mid = _create_changeset();

    my $job = _create_job( changesets => [$changeset_mid] );

    mdb->job_log->insert(
        {   mid        => $job->mid,
            lev        => 'debug',
            stmt_level => 1,
        }
    );

    my $model = _build_model();

    my ( $count, @rows ) = $model->monitor( { username => 'root', query_id => -1 } );

    is $rows[0]->{progress}, ' 25% (1/4)';
};

subtest 'monitor: does not return progress over 100%' => sub {
    _setup();

    my $changeset_mid = _create_changeset();

    my $job = _create_job( changesets => [$changeset_mid] );

    for ( 1 .. 5 ) {
        mdb->job_log->insert(
            {
                mid        => $job->mid,
                lev        => 'debug',
                stmt_level => 1,
            }
        );
    }

    my $model = _build_model();

    my ( $count, @rows ) = $model->monitor( { username => 'root', query_id => -1 } );

    is $rows[0]->{progress}, ' 25% (1/4)';
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',     'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',       'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',     'Baseliner::Model::Jobs',
        'Baseliner::DataView::Job'
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->job_log->drop;
    mdb->role->drop;

    BaselinerX::Type::Model::ConfigStore->set( key => 'config.job.mask', value => '%s.%s-%08d' );
}

sub _create_job {
    my (%params) = @_;

    mdb->rule->insert(
        {
            id        => '1',
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
                            "leaf" => \0,
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
                            "leaf" => \0,
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
                            "leaf" => \0,
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
                                    "leaf" => \1,
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
                                    "leaf" => \0,
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
                                            "palette"    => 0,
                                            "disabled"   => 0,
                                            "on_drop_js" => undef,
                                            "key"  => "statement.code.server",
                                            "text" => "INSIDE IF",
                                            "expanded"       => 1,
                                            "run_sub"        => 1,
                                            "leaf" => \1,
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
                                            "icon" =>
                                              "/static/images/icons/if.svg",
                                            "palette"        => 0,
                                            "on_drop_js"     => undef,
                                            "holds_children" => 1,
                                            "nested"         => "0",
                                            "key"      => "statement.if.var",
                                            "text"     => "IF var THEN",
                                            "run_sub"  => 1,
                                            "leaf" => \0,
                                            "on_drop"  => "",
                                            "name"     => "IF var THEN",
                                            "data"     => {},
                                            "expanded" => 1
                                        },
                                        "children" => [
                                            {
                                                "attributes" => {
                                                    "palette"        => 0,
                                                    "on_drop_js"     => undef,
                                                    "holds_children" => 0,
                                                    "nested"         => "0",
                                                    "key" =>
                                                      "statement.code.server",
                                                    "text"     => "INSIDE IF2",
                                                    "run_sub"  => 1,
                                                    "leaf" => \1,
                                                    "on_drop"  => "",
                                                    "name"     => "Server CODE",
                                                    "data"     => {},
                                                    "expanded" => 1
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
                            "leaf" => \0,
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
                                    "leaf" => \1,
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
                            "leaf" => \0,
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
                                    "leaf" => \1,
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
        }
    );

    my $job = BaselinerX::CI::job->new(id_rule => '1', %params);
    capture { $job->save };

    return $job;
}

sub _create_changeset {
    my (%params) = @_;

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
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
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",
                        "name_field"   => "project",
                        meta_type => 'project',
                        collection => 'project',
                    },
                    "key" => "fieldlet.system.projects",
                }
            },
        ]
    );

    my $id_changeset_category = TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule );

    my $project = $params{project} || TestUtils->create_ci('project');
    my $user = $params{user} || do {
        my $id_role = $params{id_role} || TestSetup->create_role(actions => [ {action =>'action.job.viewall', bl => '*' }]);

        TestSetup->create_user( id_role => $id_role, project => $project );
    };

    my $changeset_mid =
      TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1, username => $user->name );

    return $changeset_mid;
}

sub _build_model {
    Baseliner::Model::Jobs->new(@_);
}
