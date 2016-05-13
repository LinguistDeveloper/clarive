use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup qw(_topic_setup _setup_clear _setup_user);
use TestUtils qw(mock_time);

use List::MoreUtils qw(pairwise);
use Capture::Tiny qw(capture);
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Action;
use BaselinerX::Type::Event;
use BaselinerX::Type::Statement;
use BaselinerX::Type::Event;
use Baseliner::Utils qw(_load _file _get_extension_file);

use_ok 'Baseliner::Model::Topic';

subtest 'non_root_workflow: topic returns static workflow' => sub{
    _setup();
    _setup_user();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;
    my $id_category = $base_params->{category};

    # create a workflow
    my $workflow =
      [ { id_role => $id_role, id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef } ];
    mdb->category->update( { id => "$base_params->{category}" },
        { '$set' => { workflow => $workflow, default_workflow=>'' }, '$push' => { statuses => $id_status_to } } );

    my $model = _build_model();

    my %roles = map { $_=>1 } Baseliner::Model::Permissions->new->user_roles_ids( $user->username );
    my @workflow = $model->non_root_workflow( $user->username, categories=>[$id_category] );

    is_deeply( \@workflow, [ {
        id_status_from => $id_status_from,
        id_status_to   => $id_status_to,
        id_role        => $id_role,
        job_type       => undef,
        id_category    => $id_category
    } ]);
};

subtest 'non_root_workflow: topic returns rule workflow' => sub{
    _setup();
    _setup_user();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;
    my $id_category = $base_params->{category};

    my $id_rule = TestSetup->create_rule(
        rule_name => 'Workflow',
        rule_type => 'workflow',
        rule_when => 'post-offline',
        rule_tree => [
            {   attributes => {
                    leaf           => \1,
                    nested         => 0,
                    holds_children => \0,
                    run_sub        => \1,
                    palette        => \0,
                    text           => "CODE",
                    key            => "statement.perl.code",
                    name           => 'workflow from code',
                    ts             => "2015-06-30T13=>42=>57",
                    who            => "root",
                    expanded       => \0,
                    data => {
                        code=>sprintf(q{
                            $stash->{workflow} = [
                                {
                                    id_role        => '%s',
                                    id_status_from => '%s',
                                    id_status_to   => '%s',
                                    job_type       => undef
                                }
                            ];
                        }, $id_role, $id_status_from, $id_status_to)
                    },
                },
                children => [],
            },
        ],
    );

    mdb->category->update(
        { id => "$base_params->{category}" },
        {
            '$set' => { workflow => [], default_workflow => $id_rule },
            '$push' => { statuses => $id_status_to }
        }
    );

    my $model = _build_model();

    my %roles = map { $_ => 1 } Baseliner::Model::Permissions->new->user_roles_ids( $user->username );
    my @workflow = $model->non_root_workflow( $user->username, categories => [$id_category] );

    cmp_deeply(
        \@workflow,
        [
            superhashof( {
                    id_status_from => $id_status_from,
                    id_status_to   => $id_status_to,
                    id_role        => $id_role,
                    job_type       => undef,
                    id_category    => $id_category
                }
            )
        ]
    );
};

subtest 'next_status_for_user: return static workflow for root' => sub {
    _setup();
    _setup_user();

    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to   = ci->status->new( name => 'Dev', type => 'I' )->save;
    my $id_category    = "$base_params->{category}";

    # create a workflow
    my $workflow =
      [ { id_role => '1', id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef } ];
    mdb->category->update( { id => $id_category },
        { '$set' => { workflow => $workflow, default_workflow => '' }, '$push' => { statuses => $id_status_to } } );

    my @to_status = Baseliner::Model::Topic->next_status_for_user(
        username       => 'root',
        id_category    => $id_category,
        id_status_from => $id_status_from,
        topic_mid      => $topic_mid
    );

    cmp_deeply \@to_status, [
        {
            id_category      => $id_category,
            id_status_from   => $id_status_from,
            id_status_to     => $id_status_to,
            id_status        => $id_status_to,
            seq              => ignore(),
            seq_from         => ignore(),
            seq_to           => ignore(),
            status_bl        => '*',
            status_name      => 'Dev',
            status_name_from => 'New',
        }
      ];
};

subtest 'next_status_for_user: return static workflow for user' => sub {
    _setup();

    my $id_status_from = TestUtils->create_ci( 'status', name => 'New' )->id_status;
    my $id_status_to   = TestUtils->create_ci( 'status', name => 'Dev', type  => 'G' )->id_status;

    my $id_rule = TestSetup->create_rule_form();
    my $id_category =
      TestSetup->create_category( id_rule => $id_rule, id_status => [ $id_status_from, $id_status_to ] );

    my $id_role = TestSetup->create_role;
    my $project = TestUtils->create_ci_project;
    my $user    = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );

    my $topic_mid =
      TestSetup->create_topic( id_status => $id_status_from, id_category => $id_category, username => $user->username );

    my $workflow = [
        { id_role => '1', id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef },
        { id_role => $id_role, id_status_from => $id_status_from, id_status_to => $id_status_to, job_type => undef }
    ];
    mdb->category->update( { id => $id_category },
        { '$set' => { workflow => $workflow, default_workflow => '' }, '$push' => { statuses => $id_status_to } } );

    my @to_status = Baseliner::Model::Topic->next_status_for_user(
        username       => 'developer',
        id_category    => $id_category,
        id_status_from => $id_status_from,
        topic_mid      => $topic_mid
    );

    cmp_deeply \@to_status, [
        {
            id_category        => $id_category,
            id_status_from     => $id_status_from,
            id_status_to       => $id_status_to,
            id_status          => $id_status_to,
            job_type           => undef,
            seq                => ignore(),
            status_type        => 'G',
            status_bl_from     => '*',
            status_description => undef,
            status_bl          => '*',
            status_name        => 'Dev',
            statuses_name_from   => 'New',
        }
      ];
};

subtest 'next_status_for_user: rule workflow' => sub {
    _setup();
    _setup_user();

    my $base_params = _topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $id_status_from = $base_params->{status_new};
    my $id_status_to = ci->status->new( name => 'Dev', type => 'I' )->save;

    my $id_rule = TestSetup->create_rule(
        rule_name => 'Workflow',
        rule_type => 'workflow',
        rule_when => 'post-offline',
        rule_tree => [
            {   attributes => {
                    leaf           => \1,
                    nested         => 0,
                    holds_children => \0,
                    run_sub        => \1,
                    palette        => \0,
                    text           => "CODE",
                    key            => "statement.perl.code",
                    name           => 'workflow from code',
                    ts             => "2015-06-30T13=>42=>57",
                    who            => "root",
                    expanded       => \0,
                    data => {
                        code=>sprintf(q{
                            $stash->{workflow} = [
                                {
                                    id_role        => '1',
                                    id_status_from => '%s',
                                    id_status_to   => '%s',
                                    job_type       => undef
                                }
                            ];
                        }, $id_status_from, $id_status_to)
                    },
                },
                children => [],
            },
        ],
    );

    mdb->category->update( { id => "$base_params->{category}" },
        { '$set'=>{ workflow=>[], default_workflow=>$id_rule }, '$push' => { statuses => $id_status_to } } );

    my @statuses = Baseliner::Model::Topic->next_status_for_user(
        username       => 'root',
        id_category    => $base_params->{category},
        id_status_from => $id_status_from,
        topic_mid      => $topic_mid
    );

    my $transition = shift @statuses;
    is $transition->{id_status_from}, $id_status_from;
    is $transition->{id_status_to},   $id_status_to;
};

subtest 'category_workflow: returns static workflow' => sub {
    _setup();

    my $base_params = TestSetup->_topic_setup();
    my $bl          = TestUtils->create_ci( 'bl', name => 'TEST', bl => 'TEST', moniker => 'TEST' );
    my $id_role     = TestSetup->create_role();
    my $status1     = TestUtils->create_ci( 'status', name => 'Deploy', type => 'D', bls => [ $bl->mid ] );

    my $id_category = "$base_params->{category}";
    my $workflow    = [ {
            id_role        => $id_role,
            id_status_from => $base_params->{status},
            id_status_to   => $status1->mid,
            job_type       => 'promote'
        }
    ];
    mdb->category->update( { id => $id_category },
        { '$set' => { workflow => $workflow }, '$push' => { statuses => $status1->mid } } );

    my $model = _build_model();

    my @ret = $model->category_workflow($id_category);

    cmp_deeply $ret[0],
      {
        id_category      => $id_category,
        id_role          => $id_role,
        id_status_from   => ignore(),
        role             => 'Role',
        role_job_type    => 'promote',
        status_color     => ignore(),
        status_from      => 'New',
        status_time      => ignore(),
        status_type      => 'I',
        statuses_to      => ['Deploy [promote]'],
        statuses_to_type => ['D [promote]'],
      };
};

subtest 'category_workflow: returns rule workflow' => sub {
    _setup();

    my $base_params = TestSetup->_topic_setup();
    my $bl          = TestUtils->create_ci( 'bl', name => 'TEST', bl => 'TEST', moniker => 'TEST' );
    my $id_role     = TestSetup->create_role();
    my $status1     = TestUtils->create_ci( 'status', name => 'Deploy', type => 'D', bls => [ $bl->mid ] );

    my $id_category    = "$base_params->{category}";
    my $id_status_from = "$base_params->{status}";
    my $id_status_to   = $status1->id_status;

    my $id_rule = TestSetup->create_rule(
        rule_name => 'Workflow',
        rule_type => 'workflow',
        rule_when => 'post-offline',
        rule_tree => [
            {   attributes => {
                    leaf           => \1,
                    nested         => 0,
                    holds_children => \0,
                    run_sub        => \1,
                    palette        => \0,
                    text           => "CODE",
                    key            => "statement.perl.code",
                    name           => 'workflow from code',
                    ts             => "2015-06-30T13=>42=>57",
                    who            => "root",
                    expanded       => \0,
                    data => {
                        code=>sprintf(q{
                            $stash->{workflow} = [
                                {
                                    id_role        => '%s',
                                    id_status_from => '%s',
                                    id_status_to   => '%s',
                                    job_type       => 'promote',
                                }
                            ];
                        }, $id_role, $id_status_from, $id_status_to)
                    },
                },
                children => [],
            },
        ],
    );

    mdb->category->update( { id => "$base_params->{category}" },
        { '$set' => { workflow => [], default_workflow => $id_rule }, '$push' => { statuses => $id_status_to } } );

    my $model = _build_model();

    my @ret = $model->category_workflow($id_category, 'root');

    cmp_deeply $ret[0],
      {
        id_category      => $id_category,
        id_role          => $id_role,
        id_status_from   => ignore(),
        role             => 'Role',
        role_job_type    => 'promote',
        status_color     => ignore(),
        status_from      => 'New',
        status_time      => ignore(),
        status_type      => 'I',
        statuses_to      => ['Deploy [promote]'],
        statuses_to_type => ['D [promote]'],
      };
};

subtest 'topic_projects: returns project' => sub {
    _setup();

    my $topic = _build_model();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    is_deeply( [ $topic->topic_projects( $topic_mid ) ], [ $project->mid ] );
};

subtest 'get_short_name: returns same name when no category exists' => sub {
    _setup();

    my $topic = _build_model();

    is $topic->get_short_name( name => 'foo' ), 'foo';
};

subtest 'get_short_name: returns acronym' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'Category', acronym => 'cat' } );

    my $topic = _build_model();

    is $topic->get_short_name( name => 'Category' ), 'cat';
};

subtest 'get_short_name: returns auto acronym when does not exist' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'Category' } );

    my $topic = _build_model();

    is $topic->get_short_name( name => 'Category' ), 'C';
};

subtest 'get_short_name: returns auto acronym when does not exist removing special characters' => sub {
    _setup();

    mdb->category->insert( { id => 1, name => 'C123A##TegoRY' } );

    my $topic = _build_model();

    is $topic->get_short_name( name => 'C123A##TegoRY' ), 'CATRY';
};

subtest 'get_meta: returns meta fields' => sub {
    _setup();
    _setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $meta = Baseliner::Model::Topic->new->get_meta($topic_mid);

    is ref $meta, 'ARRAY';

    my $fieldlets = TestSetup->_fieldlets();
    my @fields = map { $$_{attributes}{data}{id_field} } @$fieldlets;
    unshift @fields, ( 'created_by', 'modified_by', 'created_on', 'category', 'modified_on' );
    my @fields_from_meta = sort map { $$_{id_field} } @$meta;
    is_deeply \@fields_from_meta, [sort @fields];
};

subtest 'get_meta: builds topic meta with a topic_mid in stash' => sub {
    _setup();

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');
    my $project = TestUtils->create_ci_project( bls => [ $bl->mid ] );

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'user' );
    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $id_changeset_rule = _create_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid, is_changeset => 1 );

    my $topic_mid = TestSetup->create_topic(
        status      => $status,
        username    => $user->username,
        id_category => $id_changeset_category,
        text        => '${topic_mid}',
        title       => "Topic"
    );

    my $meta = Baseliner::Model::Topic->new->get_meta($topic_mid);
    my @field = grep {$_->{name} && $_->{name} eq 'Textfield'} @$meta;

    is $field[0]->{test_field}, $topic_mid;
};

subtest 'get_meta: builds category meta with a topic_mid in stash' => sub {
    _setup();

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');
    my $project = TestUtils->create_ci_project( bls => [ $bl->mid ] );

    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project, username => 'user' );
    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );

    my $id_changeset_rule = _create_form();
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid, is_changeset => 1 );

    my $topic_mid = TestSetup->create_topic(
        status      => $status,
        username    => $user->username,
        id_category => $id_changeset_category,
        text        => '${topic_mid}',
        title       => "Topic"
    );

    my $meta = Baseliner::Model::Topic->new->get_meta($topic_mid, $id_changeset_category);
    my @field = grep {$_->{name} && $_->{name} eq 'Textfield'} @$meta;

    is $field[0]->{test_field}, $topic_mid;
};

subtest 'include into fieldlet gets its topic list' => sub {
    _setup();
    _setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my ( undef, $topic_mid2 ) =
      Baseliner::Model::Topic->new->update( { %$base_params, parent => $topic_mid, action => 'add' } );
    my $field_meta = { include_options => 'all_parents' };
    my $data = { category => { is_release => 0, id => $base_params->{category} }, topic_mid => $topic_mid2 };
    my ( $is_release, @parent_topics ) = Baseliner::Model::Topic->field_parent_topics( $field_meta, $data );

    ok scalar @parent_topics == 1;
    is $parent_topics[0]->{mid}, $topic_mid;
};

subtest 'include into fieldlet filters out releases' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my $rel_cat = TestSetup->_topic_release_category($base_params);
    my ( undef, $topic_mid ) =
      Baseliner::Model::Topic->new->update( { %$base_params, category => $rel_cat, action => 'add' } );
    my ( undef, $topic_mid2 ) =
      Baseliner::Model::Topic->new->update( { %$base_params, parent => $topic_mid, action => 'add' } );

    my $field_meta = { include_options => 'none' };
    my $data = { category => { is_release => 0, id => $base_params->{category} }, topic_mid => $topic_mid2 };
    my ( $is_release, @parent_topics ) = Baseliner::Model::Topic->field_parent_topics( $field_meta, $data );

    ok scalar @parent_topics == 0;
};

subtest 'remove_file: croaks when topic mid not found' => sub {
    _setup();

    my $model = _build_model();

    like exception { $model->remove_file() }, qr/topic mid required/;
};

subtest 'remove_file: croaks when asset mid not found' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid = TestSetup->create_topic();
    my $model     = _build_model();

    like exception { $model->remove_file( topic_mid => $topic_mid, asset_mid => 'asset-1' ) },
        qr/File id asset-1 not found/;
};

subtest 'remove_file: creates correct event.file.remove' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username  = ci->user->find_one()->{name};

    my %result = $model_topic->upload(
        file      => $file,
        topic_mid => $topic_mid,
        filename  => 'filename.txt',
        filter    => 'test_file',
        username  => $username,
        fullpath  => '/filename.txt'
    );

    my $asset = ci->asset->find_one();

    my @asset_remove;
    push @asset_remove, { id => $asset->{mid}, name => $asset->{name} };

    $model_topic->remove_file(
        username  => $username,
        asset_mid => $asset->{mid},
        topic_mid => $topic_mid
    );

    my $event = mdb->event->find_one( { event_key => 'event.file.remove' } );
    my $event_data = _load $event->{event_data};

    cmp_deeply $event_data,
        superhashof(
        {   username       => $username,
            mid            => $topic_mid,
            files          => \@asset_remove,
            total_files    => scalar @asset_remove,
            notify_default => [],
            subject        => re(qr/Deleted 1 file\(s\)/)
        }
        );

};


subtest 'remove_file: creates correct event.file.remove when the file is removed by field' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my $username  = ci->user->find_one()->{name};

    my %result = $model_topic->upload(
        file      => $file,
        topic_mid => $topic_mid,
        filename  => 'filename.txt',
        filter    => 'test_file',
        username  => $username,
        fullpath  => ''
    );

    my $asset = ci->asset->find_one();
    my @asset_remove;
    push @asset_remove, { id => $asset->{mid}, name => $asset->{name} };

    $model_topic->remove_file(
        username  => $username,
        asset_mid => [],
        fields    => 'test_file',
        topic_mid => $topic_mid
    );

    my $event = mdb->event->find_one( { event_key => 'event.file.remove' } );
    my $event_data = _load $event->{event_data};

    cmp_deeply $event_data,
        superhashof(
        {   username       => $username,
            mid            => $topic_mid,
            files          => \@asset_remove,
            total_files    => scalar @asset_remove,
            notify_default => [],
            subject        => re(qr/Deleted 1 file\(s\)/)
        }
        );

};

subtest 'save_data: check master_rel for from_cl and to_cl from set_topics' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my ( undef, $topic_mid2 ) =
      Baseliner::Model::Topic->new->update( { %$base_params, parent => $topic_mid, action => 'add' } );
    my $doc = mdb->master_rel->find_one( { from_mid => "$topic_mid", to_mid => "$topic_mid2" } );
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl},   'topic';
};

subtest 'save_data: check master_rel for from_cl and to_cl from set_projects' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );
    my $doc = mdb->master_rel->find_one( { from_mid => "$topic_mid" } );
    is $doc->{from_cl}, 'topic';
    is $doc->{to_cl},   'project';
};

subtest 'save_doc: correctly saved common environment entry in calendar fieldlet' => sub {
    _setup();
    my $id_rule = TestSetup->create_rule_form();
    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [ { action => 'action.topics.category.view', } ] );

    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_rule   => $id_rule,
        id_status => $status->mid
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic'
    );

    my $doc = {
        'calendar' => [
            {   'mid'             => '32446',
                'allday'          => 0,
                'plan_start_date' => '2016-03-09 00:00:00',
                'rel_field'       => 'env',
                'plan_end_date'   => '2016-03-26 00:00:00',
                'id'              => '163',
                'slotname'        => '*'
            }
        ],
    };

    my %p = ( mid => $topic_mid, custom_fields => [], username => $user->username );
    my $meta = [ { id_field => 'calendar', meta_type => 'calendar' } ];
    my $topic_ci = ci->new($topic_mid);

    Baseliner::Model::Topic->new->save_doc( $meta, $topic_ci, $doc, %p );

    ok( $doc->{calendar}->{'*'} );
};

subtest 'update: creates correct event.topic.create' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.create' } );
    my $event_data = _load $event->{event_data};

    my $topic = mdb->topic->find_one( { mid => "$topic_mid" } );
    my $category = mdb->category->find_one;

    my @project_names = ();
    my @project_mids = $topic->{project};
    foreach my $project_mid (@project_mids){
        my $project_ci = ci->new($project_mid);
        if( $project_ci && $project_ci->name){
            push @project_names, $project_ci->name;
        }
    }

    is $event_data->{mid},           $topic_mid;
    is $event_data->{title},         $topic->{title};
    is $event_data->{topic},         $topic->{title};
    is $event_data->{name_category}, $category->{name};
    is $event_data->{category},      $category->{name};
    is $event_data->{category_name}, $category->{name};
    is_deeply $event_data->{notify_default}, [];
    is_deeply $event_data->{projects}, \@project_names;
    like $event_data->{subject}, qr/New topic: Category #\d+/;
    is_deeply $event_data->{notify},
      {
        'project'         => [ $base_params->{project} ],
        'category_status' => $category->{statuses}->[0],
        'category'        => $category->{id}
      };
};

subtest 'update: creates topic when rule fails' => sub {
    _setup();

    TestSetup->_setup_user();

    my $status_id = ci->status->new( name => 'New', type => 'I' )->save;

    my $id_rule1 = mdb->seq('id');
    mdb->rule->insert(
        {   id          => "$id_rule1",
            ts          => '2015-08-06 09:44:30',
            rule_event  => "event.topic.create",
            rule_active => '1',
            rule_type   => 'event',
            rule_when   => "post-online",
            rule_seq    => $id_rule1,
            rule_tree   => JSON::encode_json(
                [   {   "attributes" => {
                            "data"   => { "msg" => "abort here" },
                            "key"    => "statement.fail",
                            "text"   => "FAIL",
                            "name"   => "FAIL",
                            "active" => 1,
                            "nested" => "0"
                        },
                        "children" => []
                    }
                ]
                )

        }
    );
    my $id_rule = TestSetup->create_rule_form();
    my $cat_id  = mdb->seq('id');
    mdb->category->insert(
        { id => "$cat_id", name => 'Category', statuses => [$status_id], default_form => "$id_rule" } );

    my $project = ci->project->new( name => 'Project' );
    my $project_mid = $project->save;

    my $base_params = {
        'project'         => $project_mid,
        'category'        => "$cat_id",
        'status_new'      => "$status_id",
        'status'          => "$status_id",
        'category_status' => { id => "$status_id" },
        'title'           => 'Topic Create',
        'username'        => 'test',
    };

    capture { like
            exception { Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } ) }
        , qr/Error adding Topic: \(rule $id_rule1\): Error running rule '$id_rule1': abort here/;
    };

    my $topic = mdb->topic->find_one();
    is $topic->{title}, 'Topic Create';
};

subtest 'update: reload topic when have deploy in initial status' => sub {
    _setup();

    my $base_params = TestSetup->_topic_setup();

    my $bl = TestUtils->create_ci('bl', name => 'TEST', bl => 'TEST', moniker => 'TEST');

    my $project = ci->new($base_params->{project});
    $project->{bls} = [ $bl->mid ];
    $project->update();

    my $role = mdb->role->find_one();

    my $status1 = TestUtils->create_ci( 'status', name => 'Deploy', type => 'D', bls => [ $bl->mid ] );
    my $workflow = [ { id_role => $role->{id}, id_status_from => $base_params->{status}, id_status_to => $status1->mid, job_type => 'promote' } ];

    mdb->category->update( { id => "$base_params->{category}" }, { '$set' => { workflow => $workflow }, '$push' => { statuses => $status1->mid } } );

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.create' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{return_options}->{reload_tab}, 1;
};


subtest 'update: creates correct event.topic.modify' => sub {
    _setup();
    TestSetup->_setup_user();

    my $base_params = TestSetup->_topic_setup();

    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    Baseliner::Model::Topic->new->update( { action => 'update', topic_mid => $topic_mid, title => 'Second title', username => 'test' } );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify' } );
    my $event_data = _load $event->{event_data};

    my $topic = mdb->topic->find_one( { mid => "$topic_mid" } );
    my $category = mdb->category->find_one;

    cmp_deeply $event_data, {
        mid => $topic_mid,
        title => $topic->{title},
        topic => $topic->{title},
        topic_data => {
            name_category => $category->{name},
            category_color => $category->{category_color},
            category_id => $category->{id},
            category_status_id => $topic->{category_status}->{id},
            category_status_name => $topic->{category_status}->{name},
            category_status_seq => ignore(),
            category_status_type => $topic->{category_status}->{type},
            color_category => ignore(),
            id_category => $topic->{category_id},
            id_category_status => $topic->{id_category_status},
            is_changeset => ignore(),
            username => ignore(),
            is_release => ignore(),
            mid => ignore(),
            username => ignore(),
            modified_on => ignore(),
            name_status => $topic->{name_status},
            status_new => $topic->{status_new},
            title => ignore(),
            topic_mid => $topic_mid,
            category => {
                _id => ignore(),
                id => $category->{id},
                statuses => ignore(),
                default_form => $category->{default_form},
                name => $category->{name},
            },
            category_name => $category->{name},
            category_status => $topic->{category_status},
            modified_by => ignore(),
        },
        notify => {
            'category_status' => $category->{statuses}->[0],
            'category'        => $category->{id}
        },
        notify_default => [],
        return_options => ignore(),
        rules_exec => ignore(),
        subject => ignore(),
        topic_mid => $topic_mid,
        username => ignore(),
    };
    like $event_data->{subject}, qr/Topic updated: Category #\d+/;
};

subtest 'update: updates project security' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_name => 'Changeset',
        rule_tree => [
            {
                id   => 'title',
                data => {
                    id_field => 'title'
                },
                name => 'Title',
                key  => 'fieldlet.system.title'
            },
            {
                id   => 'status_new',
                data => {
                    bd_field => 'id_category_status',
                },
                name => 'Status',
                key  => 'fieldlet.system.status_new'
            },
            {
                id   => 'project',
                data => {
                    id_field => 'project'
                },
                name => 'Project',
                key  => 'fieldlet.system.projects'
            },
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic' );

    my $topic = mdb->topic->find_one( { mid => "$topic_mid" } );

    is_deeply $topic->{_project_security}, {
        project => [
            $project->mid
        ]
    };
};

subtest 'upload: throws an error when file missed' => sub {
    my $model_topic = _build_model();

    like exception {
        $model_topic->upload(
            file      => '',
            topic_mid => '1234',
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => 'test_user'
        );
    },
        qr/Missing parameter file/;
};

subtest 'upload: throws an error if param file is not a Path::Class::File - Object' => sub {
    my $model_topic = _build_model();

    like exception {
        $model_topic->upload(
            file      => 'filename.jpg',
            topic_mid => '1234',
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => 'test_user'
        );
    },
        qr/param file is not a Path::Class::File - Object/;
};

subtest 'upload: throws an error if file does not exist' => sub {
    my $model_topic = _build_model();
    my $temp_file   = Util->_tmp_dir . '/fakefile.txt';
    my $file        = Util->_file($temp_file);

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => '1234',
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => 'test_user'
        );
    },
        qr/The file $file does not exist/;

    $file->remove();
};

subtest 'upload: throws an error if param filename is not passed' => sub {
    my $model_topic = _build_model();
    my $file   = TestUtils->create_temp_file( filename => 'filename.txt' );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => '1234',
            filename  => '',
            filter    => 'test_file',
            username  => 'test_user'
        );
    },
        qr/Missing parameter filename/;

    $file->remove();
};

subtest 'upload: throws an error if param topic_mid is not passed' => sub {
    my $model_topic = _build_model();
    my $file   = TestUtils->create_temp_file( filename => 'filename.txt' );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => '',
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => 'test_user'
        );
    },
        qr/Missing parameter topic_mid/;

    $file->remove();
};

subtest 'upload: throws an error if param topic_mid is passed but it is not a topic' => sub {
    my $model_topic = _build_model();
    my $file   = TestUtils->create_temp_file( filename => 'filename.txt' );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => '1234',
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => 'test_user'
        );
    },
        qr/topic_mid \(1234\) is not a topic/;

    $file->remove();
};

subtest 'upload: throws an error if param filter is not passed' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => $topic_mid,
            filename  => 'filename.txt',
            filter    => '',
            username  => 'test_user'
        );
    },
        qr/Missing parameter filter/;

    $file->remove();
};

subtest 'upload: throws an error if param filter is passed but it is not a fieldlet' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => $topic_mid,
            filename  => 'filename.txt',
            filter    => 'test_filter',
            username  => 'test_user'
        );
    },
        qr/The related field does not exist for the topic: $topic_mid/;

    $file->remove();
};

subtest 'upload: throws an error if param username is not passed' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file      = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => $topic_mid,
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => ''
        );
    },
        qr/Missing parameter username/;

    $file->remove();
};

subtest 'upload: throws an error if file is is already the latest version' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file = TestUtils->create_temp_file( filename => 'filename.txt' );
    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );

    $model_topic->upload(
        file      => $file,
        topic_mid => $topic_mid,
        filename  => 'filename.txt',
        filter    => 'test_file',
        username  => 'developer',
        fullpath  => ''
    );

    like exception {
        $model_topic->upload(
            file      => $file,
            topic_mid => $topic_mid,
            filename  => 'filename.txt',
            filter    => 'test_file',
            username  => 'developer',
            fullpath  => ''
        );
    },
        qr/File is already the latest version/;

    $file->remove();
};

subtest 'upload: returns file uploaded' => sub {
    _setup();

    my $model_topic = _build_model();
    my $file = TestUtils->create_temp_file( filename => 'filename.txt' );

    my $topic_mid = TestSetup->_create_topic( title => 'my topic' );
    my %result = $model_topic->upload(
        file      => $file,
        topic_mid => $topic_mid,
        filename  => 'filename.txt',
        filter    => 'test_file',
        username  => 'developer',
        fullpath  => ''
    );

    my $asset = ci->asset->find_one();

    cmp_deeply \%result,
        {
        upload_file => {
            mid      => $asset->{mid},
            name     => $asset->{name},
            fullpath => '/filename.txt'
        }
        };

    $file->remove();
};

subtest 'topics_for_user: returns topics allowed by category action' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( id_category => $id_category, status => $status, title => "Topic Mine" );
    TestSetup->create_topic( id_category => $id_category2, status => $status, title => "Topic Not Mine" );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, limit => 5 } );

    is scalar @rows, 1;
    is $rows[0]->{title}, 'Topic Mine';
};

subtest 'topics_for_user: returns topics allowed by project' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic Mine" );
    TestSetup->create_topic( project => $project2, id_category => $id_category, status => $status, title => "Topic Mine" );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, limit => 5 } );

    is scalar @rows, 1;
    is $rows[0]->{title}, 'Topic Mine';
};

subtest 'topics_for_user: returns topics' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_category } ]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic' );
    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => 'Topic2' );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username } );

    is scalar @rows, 2;
};

subtest 'topics_for_user: returns topics limited' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic $_" )
      for 1 .. 10;

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, limit => 5 } );

    is scalar @rows, 5;
};

subtest 'topics_for_user: returns topics sorted' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic $_" )
      for 1 .. 2;

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, sort => 'topic_name' } );

    my ($topic_number)  = $rows[0]->{topic_name} =~ m/#(\d+)/;
    my ($topic_number2) = $rows[1]->{topic_name} =~ m/#(\d+)/;

    ok $topic_number > $topic_number2;

    ( $data, @rows ) = $model->topics_for_user( { username => $user->username, sort => 'topic_name', dir => -1 } );

    ($topic_number)  = $rows[0]->{topic_name} =~ m/#(\d+)/;
    ($topic_number2) = $rows[1]->{topic_name} =~ m/#(\d+)/;

    ok $topic_number < $topic_number2;
};

subtest 'topics_for_user: returns topics filtered by category' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category2}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category2,
        status      => $status,
        title       => "Other Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, categories => [$id_category] } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics filtered by category negative' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_category2 =
      TestSetup->create_category( name => 'OtherCategory', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category2}]
            }
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category2,
        status      => $status,
        title       => "Other Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, categories => ["!$id_category"] } );

    is @rows, 1;
    is $rows[0]->{title}, 'Other Topic';
};

subtest 'topics_for_user: returns topics filtered topic mid' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $mid =
      TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    my $mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Other Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, topic_list => [$mid2] } );

    is @rows, 1;
    is $rows[0]->{title}, 'Other Topic';
};

subtest 'topics_for_user: returns topics filtered by assigned to me' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
        ]
    );

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic_mid =
      TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );
    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user->mid, rel_type => 'topic_users' } );

    my $topic_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Other Topic"
    );
    mdb->master_rel->insert( { from_mid => $topic_mid, to_mid => $user2->mid, rel_type => 'topic_users' } );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, assigned_to_me => 1 } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics filtered by statuses' => sub {
    _setup();

    my $id_rule         = TestSetup->create_common_topic_rule_form();
    my $status_initial  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $project         = TestUtils->create_ci_project;
    my $id_category =
      TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status_initial->mid );

    my $id_role         = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
        ]
    );

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_initial,
        title       => "Topic"
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_finished,
        title       => "Finished Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic';
};

subtest 'topics_for_user: returns topics clear filtered' => sub {
    _setup();

    my $id_rule            = TestSetup->create_common_topic_rule_form();
    my $status_initial     = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $status_in_progress = TestUtils->create_ci( 'status', name => 'In Progress', type => 'G' );
    my $status_finished    = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );
    my $project            = TestUtils->create_ci_project;
    my $id_category =
      TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status_initial->mid );

    my $id_role            = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
        ]
    );

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_initial,
        title       => "Topic"
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_in_progress,
        title       => "In Progress Topic"
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status_finished,
        title       => "Finished Topic"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, clear_filter => 1 } );

    is @rows, 3;
};

subtest 'topics_for_user: returns topics filtered by labels' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [{id_category => $id_category}]
            },
        ]
    );

    my $user  = TestSetup->create_user( id_role => $id_role, project => $project );
    my $user2 = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_label_one = TestSetup->create_label( name => 'one' );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_one],
        title       => "Topic one"
    );

    my $id_label_two = TestSetup->create_label( name => 'two' );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_two],
        title       => "Topic two"
    );

    my $id_label_three = TestSetup->create_label( name => 'three' );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        labels      => [$id_label_three],
        title       => "Topic three"
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, labels => [$id_label_one] } );

    is @rows, 1;
    is $rows[0]->{title}, 'Topic one';
};

subtest 'run_query_builder: finds topics by query in a project' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project2,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );
    my $topic3 = TestSetup->create_topic(
        project     => $project2,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic3'
    );

    my $model = _build_model();

    my $where = {};
    my (@topics) = $model->run_query_builder( 'Topic', $where, $user->username, id_project => $project->mid);

    is scalar @topics, 1;
    is $topics[0], $topic2;
};

subtest 'topics_for_user: topic that does not exist' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            },
            {   "attributes" => {
                    "data" => {
                        "id_field"     => "title",
                        "name_field"   => "Title",
                        "fieldletType" => "fieldlet.system.title",
                    },
                    "key" => "fieldlet.system.title",
                    text  => 'Title',
                    }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $other_project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, id_project => $project->mid, query => 'Topic3' } );

    is scalar @rows, 0;
};

subtest 'topics_for_user: does not return topic that exist in other project' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            }
        ],
    );

    my $status        = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project       = TestUtils->create_ci_project;
    my $other_project = TestUtils->create_ci_project;
    my $id_role       = TestSetup->create_role( actions => [ { action => 'action.topics.category.view', } ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $other_project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, id_project => $project->mid, query => 'Topic2' } );

    is scalar @rows, 0;
};

subtest 'topics_for_user: searches a topic with special characters ' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",

                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {   "attributes" => {
                    "data" => {
                        id_field       => 'project',
                        "bd_field"     => "project",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project",

                    },
                    "key"      => "fieldlet.system.projects",
                    name_field => 'Project',
                }
            },
            {   "attributes" => {
                    "data" => {
                        "id_field"     => "title",
                        "name_field"   => "Title",
                        "fieldletType" => "fieldlet.system.title",
                    },
                    "key" => "fieldlet.system.title",
                    text  => 'Title',
                    }
            }
        ],
    );

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role( actions => [ { action => 'action.topics.view', bounds => [{id_category => $id_category}]} ] );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );
    my $topic1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic1'
    );
    my $topic2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic2'
    );

    my $model = _build_model();

    my ( $data, @rows )
        = $model->topics_for_user( { username => $user->username, id_project => $project->mid, query => 'Top?c2' } );

    is scalar @rows, 1;
    is $rows[0]->{mid}, $topic2;
};

subtest 'topics_for_user: returns can_edit = 1 if user has permissions to edit' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my $id_role =
      TestSetup->create_role(
        actions => [ { action => 'action.topics.edit', bounds => [ { id_category => $id_category } ] } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username } );

    is $rows[0]->{can_edit}, '1';
};

subtest 'topics_for_user: returns can_edit = 0 if user has not permissions to edit' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $id_role =
      TestSetup->create_role(
        actions => [ { action => 'action.topics.view', bounds => [ { id_category => $id_category } ] } ] );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    TestSetup->create_topic( project => $project, id_category => $id_category, status => $status, title => "Topic" );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username } );

    is $rows[0]->{can_edit}, '0';
};

subtest 'build_sort: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->build_sort( 'some_field', 1 ),  { '_sort.some_field' => 1 };
    is_deeply $model->build_sort( 'some_field', -1 ), { '_sort.some_field' => -1 };

    for (
        qw/
        category_status_name
        modified_on
        created_on
        modified_by
        created_by
        category_name
        moniker
        /
      )
    {
        is_deeply $model->build_sort( $_, 1 ),  { $_ => 1 };
        is_deeply $model->build_sort( $_, -1 ), { $_ => -1 };
    }

    is_deeply $model->build_sort( 'topic_mid', 1 ),  { '_id' => 1 };
    is_deeply $model->build_sort( 'topic_mid', -1 ), { '_id' => -1 };

    my $ix_hash = $model->build_sort( 'topic_name', 1 );
    my @keys    = $ix_hash->Keys;
    my @values  = $ix_hash->Values;

    my %hash = pairwise { no warnings 'once'; ( $a, $b ) } @keys, @values;

    is_deeply \%hash, { created_on => 1, mid => 1 };
};

subtest 'grep_in_and_nin: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], [] ), [ 1, 2, 3 ];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], [1] ), [1];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], ['!2'] ), [ 1, 3 ];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3 ], [ 1, 2, 3, '!1', '!2' ] ), [3];
    is_deeply $model->grep_in_and_nin( [ 1, 2, 3, 4 ], [ 1, 2, 3, '!1', '!2', '!3' ] ), [];
};

subtest 'build_in_and_nin_query: builds correct condition' => sub {
    my $model = _build_model();

    is_deeply $model->build_in_and_nin_query( [] ), undef;
    is_deeply $model->build_in_and_nin_query( [1] ),    { '$in'  => [1] };
    is_deeply $model->build_in_and_nin_query( ['!2'] ), { '$nin' => [2] };
    is_deeply $model->build_in_and_nin_query( [ 1, 2, 3, '!1', '!2' ] ), { '$in' => [ 1, 2, 3 ], '$nin' => [ 1, 2 ] };
};

subtest 'status_changes: returns all the status changes' => sub {
    my $model = _build_model();

    my $status = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $topic_mid = TestSetup->create_topic(
        status => $status,
        title  => "Topic"
    );

    my $status1 = TestUtils->create_ci( 'status', name => 'Change1', type => 'I' );
    mock_time '2016-01-01T00:00:00', sub {
        $model->change_status( mid => $topic_mid, id_status => $status1->mid, change => 1, username => 'user' );
    };

    my $status2 = TestUtils->create_ci( 'status', name => 'Change2', type => 'I' );
    mock_time '2016-01-02T00:00:00', sub {
        $model->change_status( mid => $topic_mid, id_status => $status2->mid, change => 1, username => 'user' );
    };

    my @changes = $model->status_changes( { mid => $topic_mid } );

    is scalar @changes, 2;
    is_deeply $changes[0],
      {
        old_status => 'Change1',
        status     => 'Change2',
        username   => 'user',
        when       => '2016-01-02 00:00:00'
      };
    is_deeply $changes[1],
      {
        old_status => 'New',
        status     => 'Change1',
        username   => 'user',
        when       => '2016-01-01 00:00:00'
      };
};

subtest 'get_users_friend: returns users with same rights for this category and status' => sub {
    _setup();

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user1   = TestSetup->create_user( name => 'user1', id_role => $id_role, project => $project );
    my $user2   = TestSetup->create_user( name => 'user2', id_role => $id_role, project => $project );

    my $id_role_other = TestSetup->create_role();
    my $user3 = TestSetup->create_user( name => 'user3', id_role => $id_role_other, project => $project );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->mid,
            id_status_to   => $status_finished->mid,
            job_type       => undef
        }
    ];
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_status => [ $status_new->mid, $status_finished->mid ],
        workflow  => $workflow
    );

    my $model = _build_model();

    my @friends = $model->get_users_friend( id_category => $id_category, id_status => $status_new->mid );

    is_deeply \@friends, [qw/user1 user2/];
};

subtest 'get_users_friend: returns empty when no category found' => sub {
    _setup();

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user1   = TestSetup->create_user( name => 'user1', id_role => $id_role, project => $project );
    my $user2   = TestSetup->create_user( name => 'user2', id_role => $id_role, project => $project );

    my $id_role_other = TestSetup->create_role();
    my $user3 = TestSetup->create_user( name => 'user3', id_role => $id_role_other, project => $project );

    my $workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->mid,
            id_status_to   => $status_finished->mid,
            job_type       => undef
        }
    ];
    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_status => [ $status_new->mid, $status_finished->mid ],
        workflow  => $workflow
    );

    my $model = _build_model();

    my @friends = $model->get_users_friend( id_category => 'unknown-123', id_status => $status_new->mid );

    is_deeply \@friends, [];
};

subtest 'get_users_friend: returns empty when no role found' => sub {
    _setup();

    my $status_new      = TestUtils->create_ci( 'status', name => 'New',      type => 'I' );
    my $status_finished = TestUtils->create_ci( 'status', name => 'Finished', type => 'F' );

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user1   = TestSetup->create_user( name => 'user1', id_role => $id_role, project => $project );
    my $user2   = TestSetup->create_user( name => 'user2', id_role => $id_role, project => $project );

    my $id_role_other = TestSetup->create_role();
    my $user3 = TestSetup->create_user( name => 'user3', id_role => $id_role_other, project => $project );

    my $id_category = TestSetup->create_category(
        name      => 'Category',
        id_status => [ $status_new->mid, $status_finished->mid ],
    );

    my $model = _build_model();

    my @friends = $model->get_users_friend( id_category => $id_category, id_status => $status_new->mid );

    is_deeply \@friends, [];
};

subtest 'get_meta_permissions: returns all fields for root' => sub {
    _setup();

    my $model = _build_model();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $user = TestSetup->create_user( username => 'root');

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "title",
                    },
                    "key" => "fieldlet.system.title",
                    name  => 'Title',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "status_new",
                        "bd_field" => "id_category_status",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "description",
                    },
                    "key" => "fieldlet.system.description",
                    name  => 'Description',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'release',
                        release_field => 'changesets'
                    },
                    "key" => "fieldlet.system.release",
                    name  => 'Release',
                }
            }
        ],
    );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status,
        username => $user->username
    );

    my $topic_meta = Baseliner::Model::Topic->new->get_meta( $changeset_mid, $id_changeset_category, $user->username );

    my $meta = $model->get_meta_permissions(
        'data' => {
            'topic_mid' => $changeset_mid,
            'category'  => {
                'id'   => $id_changeset_category,
                'name' => 'Changeset',
            },
            'category_status' => {
                'mid'  => $status->mid,
                'name' => 'New',
            },
        },
        meta     => $topic_meta,
        username => $user->username
    );

    my ($title_field) = grep { $_->{name} && $_->{name} eq 'Title' } @$meta;
    ok !exists $title_field->{allowBlank};
    cmp_deeply $title_field->{readonly}, \0;

    my ($status_field) = grep { $_->{name} && $_->{name} eq 'Status' } @$meta;
    cmp_deeply $status_field->{allowBlank}, 'true';
    cmp_deeply $status_field->{readonly}, \0;

    my ($description_field) = grep { $_->{name} && $_->{name} eq 'Description' } @$meta;
    cmp_deeply $description_field->{allowBlank}, 'true';
    cmp_deeply $description_field->{readonly}, \0;

    my ($release_field) = grep { $_->{name} && $_->{name} eq 'Release Combo' } @$meta;
    cmp_deeply $release_field->{allowBlank}, 'true';
    cmp_deeply $release_field->{readonly}, \0;
};

subtest 'get_meta_permissions: returns meta with filtered permissions' => sub {
    _setup();

    my $model = _build_model();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $project2 = TestUtils->create_ci_project;

    my $id_changeset_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "title",
                    },
                    "key" => "fieldlet.system.title",
                    name  => 'Title',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "status_new",
                        "bd_field" => "id_category_status",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "project",
                    },
                    "key" => "fieldlet.system.projects",
                    name  => 'Project',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field" => "description",
                    },
                    "key" => "fieldlet.system.description",
                    name  => 'Description',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'release',
                        release_field => 'changesets'
                    },
                    "key" => "fieldlet.system.release",
                    name  => 'Release',
                }
            }
        ],
    );
    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topicsfield.read',
                bounds => [
                    {
                        id_category => $id_changeset_category,
                        id_status   => $status->id_status,
                        id_field    => 'title'
                    }
                ]
            },
            {
                action => 'action.topicsfield.read',
                bounds => [
                    {
                        id_category => $id_changeset_category,
                        id_status   => $status->id_status,
                        id_field    => 'status_new'
                    }
                ]
            },
            {
                action => 'action.topicsfield.read',
                bounds => [
                    {
                        id_category => $id_changeset_category,
                        id_status   => $status->id_status,
                        id_field    => 'description'
                    }
                ]
            },
            {
                action => 'action.topicsfield.write',
                bounds => [
                    {
                        id_category => $id_changeset_category,
                        id_status   => $status->id_status,
                        id_field    => 'release'
                    }
                ]
            },
        ]
    );
    my $id_role2 = TestSetup->create_role( actions => [ { action => 'action.topicsfield.write', bounds => [ {} ] }, ] );

    my $user =
      TestSetup->create_user(
        project_security => { $id_role => { project => $project->mid }, $id_role2 => { project => $project2->mid } } );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status
    );

    my $topic_meta = Baseliner::Model::Topic->new->get_meta( $changeset_mid, $id_changeset_category, $user->username );

    my $meta = $model->get_meta_permissions(
        'data' => {
            'topic_mid' => $changeset_mid,
            'category'  => {
                'id'   => $id_changeset_category,
                'name' => 'Changeset',
            },
            id_category       => $id_changeset_category,
            'category_status' => {
                'mid'  => $status->mid,
                'name' => 'New',
            },
            id_category_status => $status->mid,
            _project_security  => { project => $project->mid }
        },
        meta     => $topic_meta,
        username => $user->username
    );

    my ($title_field) = grep { $_->{name} && $_->{name} eq 'Title' } @$meta;
    ok $title_field;

    my ($status_field) = grep { $_->{name} && $_->{name} eq 'Status' } @$meta;
    ok $status_field;

    my ($description_field) = grep { $_->{name} && $_->{name} eq 'Description' } @$meta;
    cmp_deeply $description_field->{readonly}, \1;

    my ($release_field) = grep { $_->{name} && $_->{name} eq 'Release Combo' } @$meta;
    cmp_deeply $release_field->{readonly}, \0;
};

subtest 'get_categories_permissions: returns all categories for root' => sub {
    _setup();

    my $user = TestSetup->create_user( username => 'root' );

    TestSetup->create_category( name => 'Changeset' );
    TestSetup->create_category( name => 'KB' );
    TestSetup->create_category( name => 'Release' );

    my $model = _build_model();

    my @categories = $model->get_categories_permissions( username => 'root', type => 'view' );

    is @categories, 3;
    ok grep { $_->{name} eq 'Changeset' } @categories;
    ok grep { $_->{name} eq 'KB' } @categories;
    ok grep { $_->{name} eq 'Release' } @categories;
};

subtest 'get_categories_permissions: returns nothing if not allowed' => sub {
    _setup();

    my $id_category1 = TestSetup->create_category( name => 'Changeset' );
    my $id_category2 = TestSetup->create_category( name => 'KB' );
    my $id_category3 = TestSetup->create_category( name => 'Release' );

    my $project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $model = _build_model();

    my @categories = $model->get_categories_permissions( username => $user->username, type => 'view' );

    is @categories, 0;
};

subtest 'get_categories_permissions: returns categories for user' => sub {
    _setup();

    my $id_category1 = TestSetup->create_category( name => 'Changeset' );
    my $id_category2 = TestSetup->create_category( name => 'KB' );
    my $id_category3 = TestSetup->create_category( name => 'Release' );

    my $project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    {
                        id_category => $id_category1,
                    }
                ]
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $model = _build_model();

    my @categories = $model->get_categories_permissions( username => $user->username, type => 'view' );

    is @categories, 1;
    ok grep { $_->{name} eq 'Changeset' } @categories;
};

subtest 'get_categories_permissions: returns categories for user filtered by specific category' => sub {
    _setup();

    my $id_category1 = TestSetup->create_category( name => 'Changeset' );
    my $id_category2 = TestSetup->create_category( name => 'KB' );
    my $id_category3 = TestSetup->create_category( name => 'Release' );

    my $project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    {
                        id_category => $id_category1
                    },
                    {
                        id_category => $id_category2
                    }
                ]
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $model = _build_model();

    my @categories = $model->get_categories_permissions( username => $user->username, type => 'view', id => $id_category1 );

    is @categories, 1;
    ok grep { $_->{name} eq 'Changeset' } @categories;
};

subtest 'get_categories_permissions: returns all categories if no bounds' => sub {
    _setup();

    my $id_category1 = TestSetup->create_category( name => 'Changeset' );
    my $id_category2 = TestSetup->create_category( name => 'KB' );
    my $id_category3 = TestSetup->create_category( name => 'Release' );

    my $project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ {} ]
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $model = _build_model();

    my @categories = $model->get_categories_permissions( username => $user->username, type => 'view', id => $id_category3 );

    is @categories, 3;
};

subtest 'get_categories_permissions: returns nothing for user filtered by specific category that is not allowed' => sub {
    _setup();

    my $id_category1 = TestSetup->create_category( name => 'Changeset' );
    my $id_category2 = TestSetup->create_category( name => 'KB' );
    my $id_category3 = TestSetup->create_category( name => 'Release' );

    my $project = TestUtils->create_ci_project;

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    {
                        id_category => $id_category1
                    },
                    {
                        id_category => $id_category2
                    }
                ]
            },
        ]
    );

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $model = _build_model();

    my @categories = $model->get_categories_permissions( username => $user->username, type => 'view', id => $id_category3 );

    is @categories, 0;
};

subtest 'get_users: returns users filtering by role' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
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
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'asignada',
                    },
                    "key" => "fieldlet.system.users",
                    name  => 'Asiganada',
                }
            }
        ],
    );
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic',
        asignada    => $user->mid
    );

    my $model = _build_model();
    my $users = $model->get_users( $topic_mid, 'asignada', undef, {} );

    is scalar @$users, 1;
    is $users->[0]->{username}, $user->username;
};

subtest 'get_users: adds username field to the data' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                        "id_field"     => "status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field => 'asignada',
                    },
                    "key" => "fieldlet.system.users",
                    name  => 'Asiganada',
                }
            }
        ],
    );
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();

    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => 'Topic',
        asignada    => $user->mid
    );
    my $data  = {};
    my $model = _build_model();
    my $users = $model->get_users( $topic_mid, 'asignada', undef, $data );

    is $data->{"asignada._user_name"}, $user->username;
};

subtest 'set_topic: saves topic into parent' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topicsfield.changeset.sprint.new.write',
            },
        ]
    );
    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $id_sprint_rule = TestSetup->create_rule_form(
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
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
    my $id_changeset_rule = TestSetup->create_rule_form(
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
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'sprint',
                        parent_field  => 'changesets'
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Sprint',
                }
            }
        ],
    );
    my $id_sprint_category =
      TestSetup->create_category( name => 'Sprint', id_rule => $id_sprint_rule, id_status => $status->mid );

    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $sprint_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_sprint_category,
        title       => 'Sprint Parent',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child',
        sprint     => $sprint_mid,
        status      => $status
    );

    my $model = _build_model();
    my $sprint = $model->get_data( undef, $sprint_mid, with_meta=>1 );
    is scalar @{ $sprint->{changesets} }, 1;
    is $sprint->{changesets}->[0]->{mid}, $changeset_mid;
};

subtest 'set_topic: saves topic into release' => sub {
    _setup();

    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topicsfield.changeset.release.new.write',
            },
        ]
    );
    my $user = TestSetup->create_user(id_role => $id_role, project => $project);

    my $id_release_rule = TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        id_field       => 'Status',
                        "bd_field"     => "id_category_status",
                        "fieldletType" => "fieldlet.system.status_new",
                    },
                    "key" => "fieldlet.system.status_new",
                    name  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'changesets',
                    },
                    "key" => "fieldlet.system.list_topics",
                    name  => 'Changesets',
                }
            }
        ],
    );
    my $id_changeset_rule = TestSetup->create_rule_form(
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
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'release',
                        release_field => 'changesets'
                    },
                    "key" => "fieldlet.system.release",
                    name  => 'Release',
                }
            }
        ],
    );
    my $id_release_category =
      TestSetup->create_category( name => 'Release', id_rule => $id_release_rule, id_status => $status->mid );

    my $id_changeset_category =
      TestSetup->create_category( name => 'Changeset', id_rule => $id_changeset_rule, id_status => $status->mid );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release Parent',
        status      => $status
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child',
        release     => $release_mid,
        status      => $status
    );

    my $model = _build_model();
    my $release = $model->get_data( undef, $release_mid, with_meta=>1);
    is scalar @{ $release->{changesets} }, 1;
    is $release->{changesets}->[0]->{mid}, $changeset_mid;
};

subtest 'deal_with_images: returns field in image format with src' => sub {
    _setup();

    my $field = q[<img src="data:image/gif;base64,BASE64">];

    my $model = _build_model();

    my $image = $model->deal_with_images( { topic_mid => '123', field => $field } );

    like $image, qr{<img class="bali-topic-editor-image" src="/topic/img/.+">};
};

subtest 'deal_with_images: returns field in image format with src that have more than one image' => sub {
    _setup();

    my $field = q[<img src="data:image/gif;base64,BASE64"><img src="data:image/gif;base64,BASE64">];

    my $model = _build_model();

    my $image = $model->deal_with_images( { topic_mid => '123', field => $field } );

    like $image, qr{<img class="bali-topic-editor-image" src="/topic/img/.+"><img class="bali-topic-editor-image" src="/topic/img/.+">};
};

subtest 'deal_with_images: returns field with added class' => sub {
    _setup();

    my $field = q[<img src="123">];

    my $model = _build_model();
    my $image = $model->deal_with_images( { topic_mid => '123', field => $field } );

    like $image, qr{class="bali-topic-editor-image"};
};

subtest 'deal_with_images: inserts data into grid' => sub {
    _setup();

    my $field = q[<img src="data:image/gif;base64,BASE64">];

    my $model = _build_model();

    $model->deal_with_images( { topic_mid => '123', field => $field } );

    my $doc = mdb->grid->find_one();

    is $doc->{info}->{parent_mid},   '123';
    is $doc->{info}->{content_type}, 'image/gif';
    is $doc->{info}->{length},       4;
};

subtest 'status_changes: saves the name of the project assigned to the topic in event.topic.change_status' => sub {
    _setup();
    _setup_user();

    my $base_params = _topic_setup();
    my ( undef, $topic_mid ) = Baseliner::Model::Topic->new->update( { %$base_params, action => 'add' } );

    my $topic_ci = ci->new($topic_mid);
    my @projects = $topic_ci->projects;

    my $model = _build_model();

    my $other_status = TestUtils->create_ci( 'status', name => 'Change1', type => 'I' );

    $model->change_status(
        mid       => $topic_mid,
        id_status => $other_status->mid,
        change    => 1,
        username  => $base_params->{username}
    );

    my $event = mdb->event->find_one( { event_key => 'event.topic.change_status' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{projects}[0], $projects[0]->{name};
};

subtest 'get_categories_permissions: returns all categories' => sub {
    _setup();

    my $id_category   = TestSetup->create_category();
    my $id_category_1 = TestSetup->create_category();
    my $id_category_2 = TestSetup->create_category();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    { id_category => $id_category },
                    { id_category => $id_category_1 },
                    { id_category => $id_category_2 },
                ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic = _build_model();

    my @output = $topic->get_categories_permissions( type => 'view', username => $user->{username} );

    is @output, 3;
};

subtest 'get_categories_permissions: returns categories that are of type release' => sub {
    _setup();

    my $project       = TestUtils->create_ci_project;
    my $id_category   = TestSetup->create_category();
    my $id_category_1 = TestSetup->create_category( is_release => '1' );
    my $id_category_2 = TestSetup->create_category();

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    { id_category => $id_category },
                    { id_category => $id_category_1 },
                    { id_category => $id_category_2 },
                ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic = _build_model();

    my @output = $topic->get_categories_permissions( is_release => '1', type => 'view', username => $user->{username} );

    is $output[0]->{id}, $id_category_1;
    is @output, 1;
};

subtest 'get_categories_permissions: returns all categories when is_release is 0' => sub {
    _setup();

    my $project       = TestUtils->create_ci_project;
    my $id_category   = TestSetup->create_category();
    my $id_category_1 = TestSetup->create_category();
    my $id_category_2 = TestSetup->create_category( is_release => '1' );

    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [
                    { id_category => $id_category },
                    { id_category => $id_category_1 },
                    { id_category => $id_category_2 },
                ]
            },
        ]
    );
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $topic = _build_model();

    my @output = $topic->get_categories_permissions( is_release => '0', type => 'view', username => $user->{username} );

    is @output, 3;
};

subtest 'set_users: set value of old user in modify_field event' => sub {
    _setup();

    my $project  = TestUtils->create_ci('project');
    my $id_role  = TestSetup->create_role();
    my $user     = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );
    my $user_old = TestSetup->create_user( id_role => $id_role, project => $project, username => 'old_user' );
    my $user_new = TestSetup->create_user( id_role => $id_role, project => $project, username => 'new_user' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Users",
                        "fieldletType" => "fieldlet.system.users",
                        "id_field"     => "users",
                    },
                    "key" => "fieldlet.system.users",
                    text  => 'Users',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $user_old->mid, rel_type => 'topic_users', rel_field => 'users' } );

    my $ci = ci->new($topic_mid);

    my $model = _build_model();

    $model->set_users( $ci, $user_new->{mid}, 'developer', 'users' );
    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, $user_old->username;
};

subtest 'set_users: set value of old user in modify_field event when no new users' => sub {
    _setup();

    my $project  = TestUtils->create_ci('project');
    my $id_role  = TestSetup->create_role();
    my $user     = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );
    my $user_old = TestSetup->create_user( id_role => $id_role, project => $project, username => 'old_user' );
    my $user_new = TestSetup->create_user( id_role => $id_role, project => $project, username => 'new_user' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Users",
                        "fieldletType" => "fieldlet.system.users",
                        "id_field"     => "users",
                    },
                    "key" => "fieldlet.system.users",
                    text  => 'Users',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $user_old->mid, rel_type => 'topic_users', rel_field => 'users' } );

    my $ci = ci->new($topic_mid);

    my $model = _build_model();

    $model->set_users( $ci,'', 'developer', 'users' );
    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, $user_old->username;
};


subtest 'set_users: set value of old user in modify_field event when old user is empty' => sub {
    _setup();

    my $project  = TestUtils->create_ci('project');
    my $id_role  = TestSetup->create_role();
    my $user     = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );
    my $user_new = TestSetup->create_user( id_role => $id_role, project => $project, username => 'new_user' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Users",
                        "fieldletType" => "fieldlet.system.users",
                        "id_field"     => "users",
                    },
                    "key" => "fieldlet.system.users",
                    text  => 'Users',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $ci = ci->new($topic_mid);

    my $model = _build_model();

    $model->set_users( $ci, $user_new->{mid}, 'developer', 'users' );
    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, '';
};

subtest 'set_users: set value of old user in modify_field event when many old users exist' => sub {
    _setup();

    my $project    = TestUtils->create_ci('project');
    my $id_role    = TestSetup->create_role();
    my $user       = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );
    my $user_old_1 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'old_user1' );
    my $user_old_2 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'old_user2' );
    my $user_old_3 = TestSetup->create_user( id_role => $id_role, project => $project, username => 'old_user3' );
    my $user_new   = TestSetup->create_user( id_role => $id_role, project => $project, username => 'new_user' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Users",
                        "fieldletType" => "fieldlet.system.users",
                        "id_field"     => "users",
                    },
                    "key" => "fieldlet.system.users",
                    text  => 'Users',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $user_old_1->mid, rel_type => 'topic_users', rel_field => 'users' } );
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $user_old_2->mid, rel_type => 'topic_users', rel_field => 'users' } );
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $user_old_3->mid, rel_type => 'topic_users', rel_field => 'users' } );

    my $ci = ci->new($topic_mid);

    my $model = _build_model();

    $model->set_users( $ci, $user_new->{mid}, 'developer', 'users' );
    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, 'old_user1,old_user2,old_user3';
};

subtest 'set_users: set value of old user in modify_field event' => sub {
    _setup();

    my $project  = TestUtils->create_ci('project');
    my $id_role  = TestSetup->create_role();
    my $user     = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );
    my $user_old = TestSetup->create_user( id_role => $id_role, project => $project, username => 'old_user' );
    my $user_new = TestSetup->create_user( id_role => $id_role, project => $project, username => 'new_user' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Users",
                        "fieldletType" => "fieldlet.system.users",
                        "id_field"     => "users",
                    },
                    "key" => "fieldlet.system.users",
                    text  => 'Users',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $user_old->mid, rel_type => 'topic_users', rel_field => 'users' } );

    my $ci = ci->new($topic_mid);

    my $model = _build_model();

    $model->set_users( $ci, $user_new->{mid}, 'developer', 'users' );
    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, $user_old->username;
};

subtest 'set_topics: set value of old topic in modify_field event' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Topic Selector",
                        "fieldletType" => "fieldlet.system.list_topics",
                        "id_field"     => "list_topics",
                    },
                    "key" => "fieldlet.system.list_topics",
                    text  => 'Topic Selector',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $topic_mid_old = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old'
    );

    my $topic_mid_new = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_New'
    );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old, rel_type => 'topic_topic', rel_field => 'list_topics' } );

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_topics( $ci_topic, $topic_mid_new, 'developer', 'list_topics', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, $topic_mid_old;

};

subtest 'set_topics: set value of old topic in modify_field event when have more than one old topic ' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Topic Selector",
                        "fieldletType" => "fieldlet.system.list_topics",
                        "id_field"     => "list_topics",
                    },
                    "key" => "fieldlet.system.list_topics",
                    text  => 'Topic Selector',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $topic_mid_old_1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old_1'
    );
    my $topic_mid_old_2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old_2'
    );
    my $topic_mid_old_3 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old_3'
    );

    my $topic_mid_new = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_New'
    );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old_1, rel_type => 'topic_topic', rel_field => 'list_topics' } );
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old_2, rel_type => 'topic_topic', rel_field => 'list_topics' } );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old_3, rel_type => 'topic_topic', rel_field => 'list_topics' } );

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_topics( $ci_topic, $topic_mid_new, 'developer', 'list_topics', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    my $all_old_topics = $topic_mid_old_1 . "," . $topic_mid_old_2 . "," . $topic_mid_old_3;

    is $event_data->{old_value}, $all_old_topics;

};

subtest 'set_topics: set value of old topic in modify_field when no new topic' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Topic Selector",
                        "fieldletType" => "fieldlet.system.list_topics",
                        "id_field"     => "list_topics",
                    },
                    "key" => "fieldlet.system.list_topics",
                    text  => 'Topic Selector',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $topic_mid_old_1 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old_1'
    );
    my $topic_mid_old_2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old_2'
    );
    my $topic_mid_old_3 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic_Old_3'
    );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old_1, rel_type => 'topic_topic', rel_field => 'list_topics' } );
    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old_2, rel_type => 'topic_topic', rel_field => 'list_topics' } );

    mdb->master_rel->insert(
        { from_mid => $topic_mid, to_mid => $topic_mid_old_3, rel_type => 'topic_topic', rel_field => 'list_topics' } );

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_topics( $ci_topic, '', 'developer', 'list_topics', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    my $all_old_topics = $topic_mid_old_1 . "," . $topic_mid_old_2 . "," . $topic_mid_old_3;

    is $event_data->{old_value}, $all_old_topics;

};

subtest 'set_projects: set value of old project in modify_field event' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Project Combo",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project_combo",
                    },
                    "key" => "fieldlet.system.projects",
                    text  => 'Project Combo',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $project_old = TestUtils->create_ci('project');
    my $project_new = TestUtils->create_ci('project');

    mdb->master_rel->insert(
        {   from_mid  => $topic_mid,
            to_mid    => $project_old->{mid},
            rel_type  => 'topic_project',
            rel_field => 'project_combo'
        }
    );

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_projects( $ci_topic, $project_new->{mid}, 'developer', 'project_combo', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, 'project:' . $project_old->{mid};

};

subtest 'set_projects: set value of old project in modify_field event when no new project' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Project Combo",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project_combo",
                    },
                    "key" => "fieldlet.system.projects",
                    text  => 'Project Combo',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $project_old = TestUtils->create_ci('project');

    mdb->master_rel->insert(
        {   from_mid  => $topic_mid,
            to_mid    => $project_old->{mid},
            rel_type  => 'topic_project',
            rel_field => 'project_combo'
        }
    );

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_projects( $ci_topic, '', 'developer', 'project_combo', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, 'project:' . $project_old->{mid};

};

subtest 'set_projects: set value of several old project in modify_field event when are new project' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Project Combo",
                        "fieldletType" => "fieldlet.system.projects",
                        "id_field"     => "project_combo",
                    },
                    "key" => "fieldlet.system.projects",
                    text  => 'Project Combo',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    my $project_old_1 = TestUtils->create_ci('project');
    my $project_old_2 = TestUtils->create_ci('project');
    my $project_old_3 = TestUtils->create_ci('project');

    mdb->master_rel->insert(
        {   from_mid  => $topic_mid,
            to_mid    => $project_old_1->{mid},
            rel_type  => 'topic_project',
            rel_field => 'project_combo'
        }
    );
    mdb->master_rel->insert(
        {   from_mid  => $topic_mid,
            to_mid    => $project_old_2->{mid},
            rel_type  => 'topic_project',
            rel_field => 'project_combo'
        }
    );
    mdb->master_rel->insert(
        {   from_mid  => $topic_mid,
            to_mid    => $project_old_3->{mid},
            rel_type  => 'topic_project',
            rel_field => 'project_combo'
        }
    );

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_projects( $ci_topic, '', 'developer', 'project_combo', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );

    my $event_data = _load $event->{event_data};

    my $all_old_projects
        = 'project:'
        . $project_old_1->{mid}
        . ',project:'
        . $project_old_2->{mid}
        . ',project:'
        . $project_old_3->{mid};

    is $event_data->{old_value}, $all_old_projects;

};

subtest 'set_revisions: set value of old revisions in modify_field event' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Revision Box",
                        "fieldletType" => "fieldlet.system.revisions",
                        "id_field"     => "revisions",
                    },
                    "key" => "fieldlet.system.revisions",
                    text  => 'Revision Box',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    mdb->master_rel->insert(
        {   from_mid => $topic_mid,
            to_mid   => $project->{mid},
            rel_type => 'topic_project'
        }
    );

    my $ci_revision_old = TestUtils->create_ci('GitRevision');

    mdb->master_rel->insert(
        {   from_mid => $topic_mid,
            to_mid   => $ci_revision_old->{mid},
            rel_type => 'topic_revision'
        }
    );

    my $ci_revision_new = TestUtils->create_ci('GitRevision');

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_revisions( $ci_topic, $ci_revision_new->{mid}, 'developer', 'revisions', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    is $event_data->{old_value}, 'GitRevision:' . $ci_revision_old->{mid};

};

subtest 'set_revisions: set value of old revisions in modify_field event when no new revisions' => sub {
    _setup();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project, username => 'developer' );

    my $id_rule = TestSetup->create_rule_form(
        rule_tree => [
            {   "attributes" => {
                    "data" => {
                        "name_field"   => "Revision Box",
                        "fieldletType" => "fieldlet.system.revisions",
                        "id_field"     => "revisions",
                    },
                    "key" => "fieldlet.system.revisions",
                    text  => 'Revision Box',
                }
            }
        ]
    );
    my $id_category = TestSetup->create_category( id_rule => $id_rule );
    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        username    => 'developer',
        title       => 'Topic'
    );

    mdb->master_rel->insert(
        {   from_mid => $topic_mid,
            to_mid   => $project->{mid},
            rel_type => 'topic_project'
        }
    );

    my $ci_revision_old_1 = TestUtils->create_ci('GitRevision');
    my $ci_revision_old_2 = TestUtils->create_ci('GitRevision');
    my $ci_revision_old_3 = TestUtils->create_ci('GitRevision');

    mdb->master_rel->insert(
        {   from_mid => $topic_mid,
            to_mid   => $ci_revision_old_1->{mid},
            rel_type => 'topic_revision'
        }
    );
    mdb->master_rel->insert(
        {   from_mid => $topic_mid,
            to_mid   => $ci_revision_old_2->{mid},
            rel_type => 'topic_revision'
        }
    );
    mdb->master_rel->insert(
        {   from_mid => $topic_mid,
            to_mid   => $ci_revision_old_3->{mid},
            rel_type => 'topic_revision'
        }
    );

    my $ci_revision_new = TestUtils->create_ci('GitRevision');

    my $ci_topic = ci->new($topic_mid);
    my $model    = _build_model();
    my $meta     = Baseliner::Model::Topic->new->get_meta($topic_mid);

    $model->set_revisions( $ci_topic, '', 'developer', 'revisions', $meta, '0' );

    my $event = mdb->event->find_one( { event_key => 'event.topic.modify_field' } );
    my $event_data = _load $event->{event_data};

    my $all_old_revison
        = 'GitRevision:'
        . $ci_revision_old_1->{mid}
        . ',GitRevision:'
        . $ci_revision_old_2->{mid}
        . ',GitRevision:'
        . $ci_revision_old_3->{mid};
    is $event_data->{old_value}, $all_old_revison;

};

subtest 'change_bls: sets new bl and relationships' => sub {
    _setup();

    my $model = _build_model();

    my $bl = TestUtils->create_ci('bl', bl => 'TEST');

    my $status_new = TestUtils->create_ci('status');

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = _create_release_form();

    my $id_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_rule,
    );
    my $topic_mid = TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'New Release',
        status          => $status_new,
        release_version => '1.0',
        project         => $project,
        username        => $user->name,
    );

    $model->change_bls( mid => $topic_mid, bls => ['TEST'], username => $user->username );

    my $topic = mdb->topic->find_one({mid => $topic_mid});

    is_deeply $topic->{bls}, [ $bl->mid ];

    my $rel = mdb->master_rel->find_one(
        {
            from_mid  => $topic_mid,
            to_mid    => $bl->mid,
            rel_type  => 'topic_bl',
            rel_field => 'bls',
            from_cl   => 'topic',
            to_cl     => 'bl'
        }
    );
    ok $rel;
};

subtest 'change_bls: adds new bl and relationships' => sub {
    _setup();

    my $model = _build_model();

    my $old_bl = TestUtils->create_ci('bl', bl => 'DEMO');
    my $bl = TestUtils->create_ci('bl', bl => 'TEST');

    my $status_new = TestUtils->create_ci('status');

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = _create_release_form();

    my $id_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_rule,
    );
    my $topic_mid = TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'New Release',
        status          => $status_new,
        release_version => '1.0',
        project         => $project,
        username        => $user->name,
        bls => [$old_bl->mid]
    );

    $model->change_bls( mid => $topic_mid,  bls => ['TEST'], username => $user->username );

    my $topic = mdb->topic->find_one({mid => $topic_mid});

    is_deeply $topic->{bls}, [ $old_bl->mid, $bl->mid ];

    my $rel = mdb->master_rel->find_one(
        {
            from_mid  => $topic_mid,
            to_mid    => $bl->mid,
            rel_type  => 'topic_bl',
            rel_field => 'bls',
            from_cl   => 'topic',
            to_cl     => 'bl'
        }
    );
    ok $rel;
};

subtest 'change_bls: overwrites bl and relationships' => sub {
    _setup();

    my $model = _build_model();

    my $bl = TestUtils->create_ci('bl', bl => 'TEST');

    my $status_new = TestUtils->create_ci('status');

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    my $user = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = _create_release_form();

    my $id_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_rule,
    );
    my $topic_mid = TestSetup->create_topic(
        id_category     => $id_category,
        title           => 'New Release',
        status          => $status_new,
        release_version => '1.0',
        project         => $project,
        username        => $user->name,
        bls => [$bl->mid]
    );

    $model->change_bls( mid => $topic_mid, bls => ['TEST'], username => $user->username );

    my $topic = mdb->topic->find_one({mid => $topic_mid});

    is_deeply $topic->{bls}, [ $bl->mid ];

    my $rel = mdb->master_rel->find_one(
        {
            from_mid  => $topic_mid,
            to_mid    => $bl->mid,
            rel_type  => 'topic_bl',
            rel_field => 'bls',
            from_cl   => 'topic',
            to_cl     => 'bl'
        });
    ok $rel;
};

subtest 'bounds_categories: returns categories' => sub {
    _setup();

    TestSetup->create_category( id => '123', name => 'Category' );

    my @categories = _build_model()->bounds_categories();

    is_deeply \@categories,
      [
        {
            id    => '123',
            title => 'Category'
        }
      ];
};

subtest 'bounds_statuses: returns statuses' => sub {
    _setup();

    my $status = TestUtils->create_ci('status', name => 'New');

    my @statuses = _build_model()->bounds_statuses();

    is_deeply \@statuses,
      [
        {
            id    => $status->id_status,
            title => 'New'
        }
      ];
};

subtest 'bounds_statuses: returns statuses filtered by category' => sub {
    _setup();

    TestUtils->create_ci('status', name => 'Another');
    my $status = TestUtils->create_ci('status', name => 'New');

    my $id_rule = TestSetup->create_common_topic_rule_form();

    my $id_category =
      TestSetup->create_category( name => 'Category', id_rule => $id_rule, statuses => [ $status->id_status ] );

    my @statuses = _build_model()->bounds_statuses(id_category => $id_category);

    is_deeply \@statuses,
      [
        {
            id    => $status->id_status,
            title => 'New'
        }
      ];
};

subtest 'bounds_fields: returns not fields when no category' => sub {
    _setup();

    my @fields = _build_model()->bounds_fields();

    is_deeply \@fields, [];
};

subtest 'bounds_fields: returns not fields when category is all' => sub {
    _setup();

    my @fields = _build_model()->bounds_fields(id_category => '*');

    is_deeply \@fields, [];
};

subtest 'bounds_fields: returns fields from category' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();

    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule );

    my @fields = _build_model()->bounds_fields(id_category => $id_category);

    is_deeply \@fields,
      [
        {
            'title' => 'Description (description)',
            'id'    => 'description'
        },
        {
            'title' => 'Project Combo (project)',
            'id'    => 'project'
        },
        {
            'title' => 'Status (status_new)',
            'id'    => 'status_new'
        },
        {
            'title' => 'Title (title)',
            'id'    => 'title'
        }
      ];
};

subtest 'topics_for_user: returns topics sorted by labels desc' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_category } ]
            }
        ]
    );
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    mdb->label->insert(
        {   id    => '3',
            name  => 'A_name',
            color => 'red'
        }
    );

    mdb->label->insert(
        {   id    => '2',
            name  => 'B_name',
            color => 'blue'
        }
    );

    mdb->label->insert(
        {   id    => '4',
            name  => 'C_name',
            color => 'green'
        }
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        title       => 'B_name',
        labels      => 2,
        status      => $status
    );
    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        title       => 'C_name',
        labels      => 4,
        status      => $status,
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        title       => 'A_name',
        labels      => 3,
        status      => $status
    );
    mdb->topic->update( { labels => 2 }, { '$set' => { _sort => { labels_max_priority => 40 } } } );
    mdb->topic->update( { labels => 4 }, { '$set' => { _sort => { labels_max_priority => 50 } } } );
    mdb->topic->update( { labels => 3 }, { '$set' => { _sort => { labels_max_priority => 30 } } } );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, sort => 'labels', dir => 'DESC' } );

    is($rows[0]->{labels}->[0],'4;C_name;green');
    is($rows[1]->{labels}->[0],'2;B_name;blue');
    is($rows[2]->{labels}->[0],'3;A_name;red');
};

subtest 'topics_for_user: returns topics sorted by labels asc' => sub {
    _setup();

    my $id_rule = TestSetup->create_common_topic_rule_form();
    my $status  = TestUtils->create_ci( 'status', name => 'New', type => 'I' );
    my $project = TestUtils->create_ci_project;
    my $id_category = TestSetup->create_category( name => 'Category', id_rule => $id_rule, id_status => $status->mid );
    my $id_role = TestSetup->create_role(
        actions => [
            {
                action => 'action.topics.view',
                bounds => [ { id_category => $id_category } ]
            }
        ]
    );
    my $user
        = TestSetup->create_user( id_role => $id_role, project => $project );

    mdb->label->insert(
        {   id    => '3',
            name  => 'A_name',
            color => 'red'
        }
    );

    mdb->label->insert(
        {   id    => '2',
            name  => 'B_name',
            color => 'blue'
        }
    );

    mdb->label->insert(
        {   id    => '4',
            name  => 'C_name',
            color => 'green'
        }
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        title       => 'B_name',
        labels      => 2,
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        title       => 'C_name',
        labels      => 4,
        status      => $status
    );

    TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        title       => 'A_name',
        labels      => 3,
        status      => $status
    );

    mdb->topic->update( { labels => 2 }, { '$set' => { _sort => { labels_max_priority => 40 } } } );
    mdb->topic->update( { labels => 4 }, { '$set' => { _sort => { labels_max_priority => 50 } } } );
    mdb->topic->update( { labels => 3 }, { '$set' => { _sort => { labels_max_priority => 30 } } } );

    my $model = _build_model();

    my ( $data, @rows ) = $model->topics_for_user( { username => $user->username, sort => 'labels', dir => 'ASC' } );

    is($rows[0]->{labels}->[0],'3;A_name;red');
    is($rows[1]->{labels}->[0],'2;B_name;blue');
    is($rows[2]->{labels}->[0],'4;C_name;green');
};

subtest 'build_sort: builds correct condition when sort by label' => sub {
    my $model = _build_model();

    is_deeply $model->build_sort( 'labels', 1 ),  { '_sort.labels_max_priority' => 1 };
    is_deeply $model->build_sort( 'labels', -1 ),  { '_sort.labels_max_priority' => -1 };
};

subtest 'get_fieldlets_from_default_form: returns fieldlets of one form' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $model   = _build_model();
    my @nodes   = $model->get_fieldlets_from_default_form($id_rule);

    my @check_nodes = grep { $_->{key} =~ /fieldlet/ } @nodes;

    is( scalar @nodes, scalar @check_nodes );
};

subtest 'get_fieldlets_from_default_form: fails if no id_rule' => sub {
    _setup();

    my $id_rule = TestSetup->create_rule_form();
    my $model   = _build_model();

    like exception { $model->get_fieldlets_from_default_form(); }, qr/Id not provided/;
};

subtest 'check_permissions_change_status: returns true when user has permissions to change status' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role;
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status  = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'I' );

    my $workflow = [
        {   id_role        => $id_role,
            id_status_from => $status->id_status,
            id_status_to   => $status2->id_status,
            job_type       => 'promote'
        }
    ];
    my $id_rule     = TestSetup->create_rule_form();
    my $id_category = TestSetup->create_category(
        name     => 'Category',
        id_rule  => $id_rule,
        workflow => $workflow
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Topic"
    );
    my $model  = _build_model();
    my $output = $model->check_permissions_change_status(
        username    => $user->username,
        id_category => $id_category,
        old_status  => $status,
        new_status  => $status2,
        topic_mid   => $topic_mid
    );

    ok $output;
};

subtest 'check_permissions_change_status: throws an error when user has no permissions to change status' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role;
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $status  = TestUtils->create_ci( 'status', name => 'New',         type => 'I' );
    my $status2 = TestUtils->create_ci( 'status', name => 'In Progress', type => 'I' );
    my $status3 = TestUtils->create_ci( 'status', name => 'Finished',    type => 'I' );

    my $workflow = [
        {   id_role        => $id_role,
            id_status_from => $status->id_status,
            id_status_to   => $status2->id_status,
            job_type       => 'promote'
        }
    ];
    my $id_rule     = TestSetup->create_rule_form();
    my $id_category = TestSetup->create_category(
        name     => 'Category',
        id_rule  => $id_rule,
        workflow => $workflow
    );

    my $topic_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_category,
        status      => $status,
        title       => "Topic"
    );

    my $model = _build_model();

    like exception {
        $model->check_permissions_change_status(
            username    => $user->username,
            id_category => $id_category,
            old_status  => $status,
            new_status  => $status3,
            topic_mid   => $topic_mid
        );
    }, qr/has no permissions to change status from 'New' to 'Finished'/;
};

subtest 'filter_children: returns the children closest' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = TestSetup->create_rule_form_changeset();
    my $id_release_category = TestSetup->create_category( name => 'Release', id_rule => $id_rule );

    my $id_changeset_category = TestSetup->create_category( name => 'Release', id_rule => $id_rule );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release Parent',
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Changeset Child',
        release     => $release_mid,
    );

    my $changeset_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child2',
        release     => $changeset_mid,
    );
    my $where = {};

    $where->{'category.id'} = mdb->in($id_release_category);
    my $model = _build_model();

    $model->filter_children( $where, topic_mid => $release_mid, depth => 1 );

    is_deeply $where->{mid}, { '$in' => [$changeset_mid] };

};

subtest 'filter_children: returns all the children of the topic' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $id_rule = TestSetup->create_rule_form_changeset();
    my $id_release_category = TestSetup->create_category( name => 'Release', id_rule => $id_rule );

    my $id_changeset_category = TestSetup->create_category( name => 'Release', id_rule => $id_rule );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Release Parent',
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_release_category,
        title       => 'Changeset Child',
        release     => $release_mid,
    );

    my $changeset_mid2 = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Changeset Child2',
        release     => $changeset_mid,
    );
    my $where = {};

    $where->{'category.id'} = mdb->in($id_release_category);
    my $model = _build_model();

    $model->filter_children( $where, topic_mid => $release_mid );

    is_deeply $where->{mid}, { '$in' => [ $changeset_mid, $changeset_mid2 ] };
};

done_testing();

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Registor',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::CI',          'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic', 'Baseliner::Model::Rules',
        'BaselinerX::Type::Statement'
    );

    TestUtils->cleanup_cis;

    mdb->activity->drop;
    mdb->category->drop;
    mdb->event->drop;
    mdb->grid->drop;
    mdb->label->drop;
    mdb->role->drop;
    mdb->rule->drop;
    mdb->topic->drop;
    mdb->master_rel->drop;
    mdb->index_all('topic');
}

sub _build_model {
    return Baseliner::Model::Topic->new;
}

sub _create_form {
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
            },
            {
                "attributes" => {
                    "data" => {
                        id_field      => 'text',
                        test_field => '${topic_mid}'
                    },
                    "key" => "fieldlet.text",
                    name  => 'Text',
                }
            },
            @{$params{rule_tree} || []}
        ],
    );
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_tree => [
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "status_new",
                        "fieldletType" => "fieldlet.system.status_new",
                        "name_field"   => "Status",
                    },
                    "key" => "fieldlet.system.status_new",
                    text  => 'Status',
                }
            },
            {
                "attributes" => {
                    "data" => {
                        "id_field"     => "release_version",
                        "fieldletType" => "fieldlet.system.release_version",
                        "name_field"   => "Version",
                    },
                    "key" => "fieldlet.system.release_version",
                    text  => 'Version',
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
                    text  => 'Project',
                }
            },
        ]
    );
}
