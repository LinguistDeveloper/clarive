package Baseliner::SetupProfile::Support;
use strict;
use warnings;
use base 'Baseliner::SetupProfile::Base';

use BaselinerX::Type::Model::ConfigStore;
use Baseliner::SetupProfile::Reset;
use Baseliner::Mongo;
use TestSetup;
use TestUtils;
use TestGit;

sub setup {
    my $self = shift;

    Baseliner::SetupProfile::Reset->new->setup;

    TestUtils->setup_registry(
        'BaselinerX::Type::Event',   'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Dashlet', 'BaselinerX::CI',
        'BaselinerX::Fieldlets',     'BaselinerX::Dashlets',
        'Baseliner::Model::Topic',   'Baseliner::Model::Rules'
    );

    my $bl_common = TestUtils->create_ci('bl', name => 'Common', bl => '*');
    my $bl_qa     = TestUtils->create_ci('bl', name => 'QA',     bl => 'QA');
    my $bl_prod   = TestUtils->create_ci('bl', name => 'PROD',   bl => 'PROD');

    my $repo_dir = '/tmp/repo.git';
    system("rm -rf $repo_dir");

    TestGit->create_repo(dir => $repo_dir, bare => 1);

    my $repo = TestUtils->create_ci(
        'GitRepository',
        name     => 'Repo',
        repo_dir => $repo_dir,
    );

    my $config = BaselinerX::Type::Model::ConfigStore->new;

    $config->set(
        key   => 'config.git.gitcgi',
        value => "$ENV{CLARIVE_BASE}/local/libexec/git-core/git-http-backend"
    );
    $config->set(
        key   => 'config.git.home',
        value => "/tmp/"
    );
    $config->set(
        key   => 'config.git.path',
        value => "$ENV{CLARIVE_BASE}/local/bin/git"
    );

    my $status_new = TestUtils->create_ci(
        'status',
        name => 'New',
        type => 'I',
        bls  => [$bl_common->mid]
    );
    my $status_in_progress = TestUtils->create_ci(
        'status',
        name => 'In Progress',
        type => 'G',
        bls  => [$bl_common->mid]
    );
    my $status_finished = TestUtils->create_ci(
        'status',
        name => 'Finished',
        type => 'D',
        bls  => [$bl_qa->mid]
    );
    my $status_closed =
      TestUtils->create_ci('status', name => 'Closed', type => 'F');

    my $project = TestUtils->create_ci_project(repositories => [$repo->mid]);

    my @actions;
    foreach my $status (qw/new in_progress finished/) {
        foreach my $category (qw/changeset/) {
            foreach my $field (qw/title status project revisions/) {
                push @actions,
                  {action =>
                      "action.topicsfield.$category.$field.$status.write"};
            }
        }
    }

    my $id_role = TestSetup->create_role(
        role    => 'Developer',
        actions => [
            {
                action => 'action.home.show_lifecycle',
                bl     => '*'
            },
            {
                action => 'action.home.show_menu',
                bl     => '*'
            },
            {
                action => 'action.home.view_releases',
                bl     => '*'
            },
            {
                action => 'action.job.create',
                bl     => '*'
            },
            {
                action => 'action.job.view_monitor',
                bl     => '*'
            },
            {
                action => 'action.job.viewall',
                bl     => '*'
            },
            {
                action => 'action.job.no_cal',
                bl     => '*'
            },
            {
                action => 'action.topics.changeset.jobs',
                bl     => '*'
            },
            {
                action => 'action.topics.changeset.create',
                bl     => '*'
            },
            {
                action => 'action.topics.changeset.view',
                bl     => '*'
            },
            {
                action => 'action.topics.release.view',
                bl     => '*'
            },
            {
                action => 'action.git.repository_access',
                bl     => '*'
            },
            @actions
        ]
    );
    my $user = TestSetup->create_user(
        id_role  => $id_role,
        project  => $project,
        name     => 'developer',
        username => 'developer',
        password => 'password'
    );

    my $id_changeset_rule     = _create_changeset_form();
    my $id_changeset_category = TestSetup->create_category(
        name         => 'Changeset',
        is_changeset => '1',
        id_rule      => $id_changeset_rule,
        id_status =>
          [$status_new->mid, $status_in_progress->mid, $status_finished->mid]
    );

    my $changeset_workflow = [
        {
            id_role        => $id_role,
            id_status_from => $status_new->mid,
            id_status_to   => $status_in_progress->mid,
            job_type       => undef
        },
        {
            id_role        => $id_role,
            id_status_from => $status_in_progress->mid,
            id_status_to   => $status_finished->mid,
            job_type       => 'promote'
        }
    ];
    mdb->category->update(
        {id => $id_changeset_category},
        {
            '$set'  => {workflow => $changeset_workflow},
            '$push' => {statuses => [$status_in_progress->mid, $status_finished->mid]}
        }
    );

    my $id_release_rule     = _create_release_form();
    my $id_release_category = TestSetup->create_category(
        name       => 'Release',
        is_release => '1',
        id_rule    => $id_release_rule,
        id_status =>
          [$status_new->mid, $status_in_progress->mid, $status_finished->mid]
    );

    my $release_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_release_rule,
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status_new
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_rule     => $id_changeset_rule,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status_new
    );

    TestSetup->create_rule(
        rule_name => 'Pipeline',
        rule_when => 'promote',
        rule_type => 'pipeline'
    );
}

sub _create_changeset_form {
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
        ],
    );
}

sub _create_release_form {
    return TestSetup->create_rule_form(
        rule_name => 'Release',
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
        ],
    );
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
