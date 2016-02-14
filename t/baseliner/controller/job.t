use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
use TestUtils ':catalyst';
BEGIN { TestEnv->setup }
use TestSetup;

use Capture::Tiny qw(capture);

use_ok 'Baseliner::Controller::Job';

subtest 'monitor_json: returns empty data' => sub {
    _setup();

    my $c = mock_catalyst_c(username => 'developer');

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is_deeply $c->stash,
      {
        'json' => {
            'totalCount' => 0,
            'data'       => []
        }
      };
};

subtest 'monitor_json: returns jobs data' => sub {
    _setup();

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

    my $project_doc = ci->project->find_one;
    my $project = ci->new($project_doc->{mid});

    my $changeset_mid =
      TestSetup->create_topic( id_category => $id_changeset_category, project => $project, is_changeset => 1 );
    my $changeset = mdb->topic->find_one({mid => $changeset_mid});

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    my $job_ci;
    capture {
        $job_ci = TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$changeset_mid],
            bl           => 'PROD',
            bl_to        => 'PROD'
        );
    };

    $job_ci = ci->project->find_one({'projects' => { '$in' => [ $project->mid ]} });

    my $c = mock_catalyst_c(username => 'developer', req => {params => {query_id => '-1'}});

    my $controller = _build_controller();

    $controller->monitor_json($c);

    is $c->stash->{json}->{totalCount}, 1;
};

subtest 'pipeline_versions: returns versions data' => sub {
    _setup();

    my $id_rule = '1';

    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-01 10:00:00', username => 'foo'} );
    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-01 11:00:00', username => 'bar'} );
    mdb->rule_version->insert( { id => '1', id_rule => $id_rule, ts => '2015-01-02 11:00:00', username => 'baz'} );

    my $c = mock_catalyst_c(username => 'developer', req => {params => {id_rule => $id_rule}});

    my $controller = _build_controller();

    $controller->pipeline_versions($c);

    cmp_deeply $c->stash, {
        json => {
            success => \1,
            data => [
                {
                    id => ignore(),
                    rule_version => 'Latest (baz)',
                },
                {
                    id => ignore(),
                    rule_version => '2015-01-01 11:00:00 (bar)',
                },
                {
                    id => ignore(),
                    rule_version => '2015-01-01 10:00:00 (foo)',
                },
            ],
            totalCount => 3,
        }
    };
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->rule_version->drop;

    TestUtils->create_ci('bl', name => 'Common', bl => '*');
    TestUtils->create_ci('bl', name => 'PROD', bl => 'PROD');

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.job.viewall',
                bl => 'PROD'
            },
        ]
    );

    TestSetup->create_user( id_role => $id_role, project => $project );
}

sub _build_controller {
    Baseliner::Controller::Job->new( application => '' );
}
