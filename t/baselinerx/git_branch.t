use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use TestGit;

use_ok 'BaselinerX::GitBranch';

subtest 'node_data: returns correct data' => sub {
    my $branch = _build_branch(
        head      => '123',
        name      => 'master',
        project   => 'Project',
        repo_name => 'repo',
        repo_dir  => '/repo.git',
    );

    cmp_deeply $branch->node_data,
      {
        'icon'       => ignore(),
        'provider'   => 'Git Revision',
        'project'    => 'Project',
        'demotable'  => '0',
        'bl_to'      => undef,
        'tab_icon'   => ignore(),
        'controller' => 'gittree',
        'ci'         => {
            'ns'   => 'git.revision/master',
            'name' => 'master',
            'data' => {
                'repo'   => 'ci_pre:0',
                'ci_pre' => [
                    {
                        'mid'  => undef,
                        'ns'   => 'git.repository//repo.git',
                        'name' => '/repo.git',
                        'data' => {
                            'repo_dir' => '/repo.git'
                        },
                        'class' => 'GitRepository'
                    }
                ],
                'sha'     => 'master',
                'rev_num' => 'master',
                'branch'  => 'master'
            },
            'class' => 'GitRevision',
            'role'  => 'Revision'
        },
        'repo_mid'   => undef,
        'repo_name'  => 'repo',
        'name'       => 'master',
        'repo_dir'   => '/repo.git',
        'branch'     => 'master',
        'promotable' => '0',
        'bl_from'    => undef,
        'ns'         => 'git.revision/master@Project:repo',
        'click'      => {
            'controller' => 'gittree',
            'repo_mid'   => undef,
            'url'        => '/comp/view_commits_history.js',
            'title'      => 'history: master',
            'type'       => 'comp',
            'branch'     => 'master',
            'repo_dir'   => '/repo.git'
        }
      };
};

sub _build_branch {
    my (%params) = @_;

    return BaselinerX::GitBranch->new(%params);
}

done_testing;
