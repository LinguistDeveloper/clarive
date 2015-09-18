use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use TestEnv;
use TestUtils ':catalyst';

TestEnv->setup;

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Controller::GitTree;

local *Baseliner::model = sub {
    shift;
    my ($model) = @_;

    if ( $model eq 'ConfigStore' ) {
        require BaselinerX::Type::Model::ConfigStore;
        return BaselinerX::Type::Model::ConfigStore->new;
    }

    return Clarive::model($model);
    die "unknown model '$model'";
};

my $RE_sha8 = '[a-f0-9]{8}';
my $RE_sha  = '[a-f0-9]{40}';
sub re_sha8 { re(qr/^$RE_sha8$/) }
sub re_sha  { re(qr/^$RE_sha$/) }
sub re_date { re(qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/) }

subtest 'get_commits_history: returns validation errors' => sub {
    _setup();    

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_history($c);

    is_deeply $c->stash,
      { json => { success => \0, msg => 'Validation failed', errors => { repo_mid => 'REQUIRED' } } };
};

subtest 'get_commits_history: returns commits' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_history($c);

    cmp_deeply $c->stash, {
        json => {
            success    => \1,
            msg        => 'Success loading commits history',
            totalCount => 2,
            commits    => [
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    dir
',
                    'date'   => re_date(),
                    'author' => 'vti <vti@clarive.com>',
                    'ago'    => ignore(),
                    'tags'   => re(qr/HEAD.*?(master|release).*?(release|master)/)
                },
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    initial',
                    'date'   => re_date(),
                    'author' => 'vti <vti@clarive.com>',
                    'ago'    => ignore()
                }

            ]
        }
    };
};

subtest 'branch_commits: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_commits($c);

    is_deeply $c->stash,
      { json => { success => \0, msg => 'Validation failed', errors => { repo_mid => 'REQUIRED' } } };
};

subtest 'branch_commits: returns commits' => sub {
    _setup();

    BaselinerX::CI::bl->new( bl => 'release' )->save;

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, branch => 'master' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_commits($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                'icon' => ignore(),
                'text' => re(qr/^\[$RE_sha8\] dir$/),
                'data' => {
                    'sha'        => re_sha(),
                    'branch'     => 'master',
                    'rev_num'    => re_sha(),
                    'repo_dir'   => 't/data/git-bare.git',
                    'controller' => 'gittree',
                    'click'      => {
                        'repo_mid' => ignore(),
                        'action'   => 'edit',
                        'url'      => '/comp/view_diff.js',
                        'type'     => 'comp',
                        'title'    => re(qr/^Commit $RE_sha8$/),
                        'load'     => \1,
                        'repo_dir' => 't/data/git-bare.git'
                    },
                    'ci' => {
                        'ns'   => re(qr/^git\.revision\/$RE_sha$/),
                        'name' => re(qr/^\[$RE_sha8\] dir$/),
                        'data' => {
                            'repo'   => 'ci_pre:0',
                            'ci_pre' => [
                                {
                                    'mid'  => ignore(),
                                    'ns'   => 'git.repository/t/data/git-bare.git',
                                    'name' => 't/data/git-bare.git',
                                    'data' => {
                                        'repo_dir' => 't/data/git-bare.git'
                                    },
                                    'class' => 'GitRepository'
                                }
                            ],
                            'sha'     => ignore(),
                            'rev_num' => ignore(),
                            'branch'  => 'master'
                        },
                        'class' => 'GitRevision',
                        'role'  => 'Revision'
                    },
                    'repo_mid' => ignore()
                },
                'leaf' => \1
            }
        ]
      };
};

subtest 'branch_changes returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_changes($c);

    is_deeply $c->stash,
      { json => { success => \0, msg => 'Validation failed', errors => { repo_mid => 'REQUIRED' } } };
};

subtest 'branch_changes returns changes' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_changes($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                icon => ignore(),
                text => 'foo/bar',
                leaf => \1
            }
        ]
      };
};

subtest 'branch_tree: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_tree($c);

    is_deeply $c->stash,
      { json => { success => \0, msg => 'Validation failed', errors => { repo_mid => 'REQUIRED' } } };
};

subtest 'branch_tree: returns tree' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_tree($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                'text' => 'foo',
                'url'  => '/gittree/branch_tree',
                'data' => {
                    'sha'      => re_sha(),
                    'repo_mid' => $repo_ci->mid,
                    'branch'   => 'HEAD',
                    'folder'   => 'foo'
                },
                'leaf' => \0
            },
            {
                'text' => 'HOWTO',
                'data' => {
                    'controller' => 'gittree',
                    'tab_icon'   => ignore(),
                    'click'      => {
                        'action' => 'edit',
                        'url'    => '/comp/view_file.js',
                        'type'   => 'comp',
                        'title'  => 'HEAD: HOWTO',
                        'load'   => \1
                    },
                    'repo_mid' => $repo_ci->mid,
                    'file'     => 'HOWTO',
                    'rev_num'  => re_sha(),
                    'branch'   => 'HEAD'
                },
                'leaf' => \1
            }
        ]
      };
};

subtest 'branch_tree: returns tree from a subdirectory' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, folder => 'foo' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_tree($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                'text' => 'bar',
                'data' => {
                    'controller' => 'gittree',
                    'tab_icon'   => ignore(),
                    'click'      => {
                        'action' => 'edit',
                        'url'    => '/comp/view_file.js',
                        'type'   => 'comp',
                        'title'  => 'HEAD: bar',
                        'load'   => \1
                    },
                    'repo_mid' => $repo_ci->mid,
                    'file'     => 'foo/bar',
                    'rev_num'  => re_sha(),
                    'branch'   => 'HEAD'
                },
                'leaf' => \1
            }
        ]
      };
};

subtest 'get_file_revisions: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_revisions($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED', filename => 'REQUIRED', sha => 'REQUIRED' }
        }
      };
};

subtest 'get_file_revisions: returns commits' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'HOWTO', sha => '123' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_revisions($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                name => re_sha8()
            }
        ]
      };
};

subtest 'view_file: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_file($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED', filename => 'REQUIRED', sha => 'REQUIRED' }
        }
      };
};

subtest 'view_file: returns file content' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'HOWTO', sha => '38405ec58cb2aa9eecf8f44326bdb80c8624d057' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_file($c);

    cmp_deeply $c->stash,
      {
        json => {
            'msg'          => 'Success viewing file',
            'success'      => \1,
            'file_content' => 'This is a howto.',
            'rev_num'      => re_sha8()
        }
      };
};

subtest 'get_file_blame: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_blame($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED', filename => 'REQUIRED', sha => 'REQUIRED' }
        }
      };
};

subtest 'get_file_blame: returns blame' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'HOWTO', sha => '38405ec58cb2aa9eecf8f44326bdb80c8624d057' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_blame($c);

    cmp_deeply $c->stash,
      {
        json => {
            'msg'      => re(qr/^\^[a-f0-9]{7} \(vti .*?\) This is a howto\.$/),
            'success'  => \1,
            'suported' => \1
        }
      };
};

subtest 'view_diff_file: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff_file($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED', file => 'REQUIRED', sha => 'REQUIRED' }
        }
      };
};

subtest 'view_diff_file: returns diff' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, file => 'HOWTO', sha => '38405ec58cb2aa9eecf8f44326bdb80c8624d057' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff_file($c);

    cmp_deeply $c->stash,
      {
        json => {
            'commit_info' => {
                'revision' => re_sha8(),
                'comment'  => '    initial',
                'date'     => ignore(),
                'author'   => ignore(),
            },
            'msg'     => 'Success loading file diff',
            'success' => \1,
            'changes' => [
                {
                    'revision1'   => re_sha8(),
                    'code_chunks' => [
                        {
                            'stats' => '-0,0 +1',
                            'code'  => '+This is a howto.'
                        }
                    ],
                    'path'      => 'HOWTO',
                    'revision2' => re_sha8(),
                }
            ]
        }
      };
};

subtest 'view_diff: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = FakeContext->new( req => FakeRequest->new( params => $params ) );

    $controller->view_diff($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED', sha => 'REQUIRED' }
        }
      };
};

subtest 'view_diff: returns diff' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, sha => '38405ec58cb2aa9eecf8f44326bdb80c8624d057' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff($c);

    cmp_deeply $c->stash,
      {
        json => {
            'commit_info' => {
                'revision' => re_sha8(),
                'comment'  => '    initial',
                'date'     => '  Mon Jul 27 09:21:31 2015 +0200',
                'author'   => 'vti <vti@clarive.com>'
            },
            'msg'     => 'Success loading diffs',
            'success' => \1,
            'changes' => [
                {
                    'revision1'   => '0000000',
                    'code_chunks' => [
                        {
                            'stats' => '-0,0 +1',
                            'code'  => '+This is a howto.'
                        }
                    ],
                    'path'      => 'HOWTO',
                    'revision2' => 'eb6af9b'
                }
            ]
        }
      };
};

subtest 'get_file_history: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_history($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED', filename => 'REQUIRED', sha => 'REQUIRED' }
        }
      };
};

subtest 'get_file_history: returns diff' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'HOWTO', sha => '38405ec58cb2aa9eecf8f44326bdb80c8624d057' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_history($c);

    cmp_deeply $c->stash,
      {
        json => {
            'totalCount' => 1,
            'msg'        => 'Success loading file history',
            'success'    => \1,
            'history'    => [ [ ignore(), ignore(), re_sha8(), '    initial' ] ]
        }
      };
};

subtest 'get_tags: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_tags($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED' }
        }
      };
};

subtest 'get_tags: returns tags' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_tags($c);

    cmp_deeply $c->stash, { json => [ { name => 'release' } ] };
};

subtest 'get_commits_search: returns validation errors' => sub {
    _setup();

    my $controller = _build_controller();

    my $params = {};

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_search($c);

    is_deeply $c->stash,
      {
        json => {
            success => \0,
            msg     => 'Validation failed',
            errors  => { repo_mid => 'REQUIRED' }
        }
      };
};

subtest 'get_commits_search: returns found commits by comment' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, query => '--comment="initial"' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_search($c);

    cmp_deeply $c->stash, {
        json => {
            'totalCount' => 1,
            'msg'        => 'Success loading commits history',
            'success'    => \1,
            'commits'    => [
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    initial',
                    'date'   => '2015-07-27T07:21:31',
                    'author' => 'vti <vti@clarive.com>',
                    'ago'    => ignore()
                }
            ]
        }
    };
};

subtest 'get_commits_search: returns found commits by author' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, query => '--author="vti"' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_search($c);

    cmp_deeply $c->stash, {
        json => {
            'totalCount' => 2,
            'msg'        => 'Success loading commits history',
            'success'    => \1,
            'commits'    => [
                {
                    'revision' => 'f8785d4e',
                    'comment'  => '

    dir
',
                    'date'   => re_date(),
                    'author' => 'vti <vti@clarive.com>',
                    'ago'    => ignore()
                },
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    initial',
                    'date'   => re_date(),
                    'author' => 'vti <vti@clarive.com>',
                    'ago'    => ignore()
                }
            ]
        }
    };
};

subtest 'get_commits_search: returns found commits by revision' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, query => '38405ec58c' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_search($c);

    cmp_deeply $c->stash, {
        json => {
            'totalCount' => 1,
            'msg'        => 'Success loading commits history',
            'success'    => \1,
            'commits'    => [
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    initial',
                    'date'   => '2015-07-27T07:21:31',
                    'author' => 'vti <vti@clarive.com>',
                    'ago'    => ignore()
                }
            ]
        }
    };
};

subtest 'get_commits_search: returns empty result when nothing found' => sub {
    _setup();

    my $repo_ci = ci->GitRepository->new( repo_dir => 't/data/git-bare.git' );
    $repo_ci->save;

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, query => 'abcdef' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_search($c);

    cmp_deeply $c->stash,
      {
        json => {
            'totalCount' => 0,
            'msg'        => 'Success loading commits history',
            'success'    => \1,
            'commits'    => []
        }
      };
};

sub _build_controller {
    Baseliner::Controller::GitTree->new( application => '' );
}

sub _setup {
    Baseliner::Core::Registry->clear();
    TestUtils->register_ci_events();
    TestUtils->cleanup_cis;
}
done_testing;
