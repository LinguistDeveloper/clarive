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

    TestUtils->create_ci('bl', name => '*',    bl => 'Common');
    TestUtils->create_ci('bl', name => 'QA',   bl => 'QA');
    TestUtils->create_ci('bl', name => 'PROD', bl => 'PROD');

    my $repo_dir = '/tmp/repo.git';
    system("rm -rf $repo_dir");

    TestGit->create_repo(dir => $repo_dir, bare => 1);
    TestGit->commit($repo_dir);

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

    my $status_new = TestUtils->create_ci('status', name => 'New', type => 'I');
    my $status_in_progress =
      TestUtils->create_ci('status', name => 'In Progress', type => 'G');
    my $status_finished =
      TestUtils->create_ci('status', name => 'Finished', type => 'G');
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
            },
            {
                action => 'action.home.show_menu',
            },
            {
                action => 'action.home.view_releases',
            },
            {
                action => 'action.job.create',
            },
            {
                action => 'action.job.view_monitor',
            },
            {
                action => 'action.job.viewall',
            },
            {
                action => 'action.job.no_cal',
            },
            {
                action => 'action.topics.changeset.create',
            },
            {
                action => 'action.topics.changeset.view',
            },
            {
                action => 'action.topics.release.view',
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
        id_category => $id_release_category,
        title       => 'Release 0.1',
        status      => $status_new
    );

    my $changeset_mid = TestSetup->create_topic(
        project     => $project,
        id_category => $id_changeset_category,
        title       => 'Fix everything',
        status      => $status_new
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
