use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestGit;

use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use BaselinerX::Type::Model::ConfigStore;

my $RE_sha8 = '[a-f0-9]{8}';
my $RE_sha  = '[a-f0-9]{40}';
sub re_sha8 { re(qr/^$RE_sha8$/) }
sub re_sha  { re(qr/^$RE_sha$/) }
sub re_date { re(qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/) }

use_ok 'Baseliner::Controller::GitTree';

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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci, message => 'initial');
    TestGit->commit($repo_ci);

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

    update
',
                    'date'   => re_date(),
                    'author' => 'clarive <clarive@localhost>',
                    'ago'    => ignore(),
                    'tags'   => re(qr/HEAD.*?master/)
                },
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    initial',
                    'date'   => re_date(),
                    'author' => 'clarive <clarive@localhost>',
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
      { json =>
          { success => \0, msg => 'Validation failed', errors => { repo_mid => 'REQUIRED', project => 'REQUIRED' } } };
};

subtest 'branch_commits: returns commits' => sub {
    _setup();

    TestUtils->create_ci( 'bl', bl => 'release',  name => 'release' );

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci);
    TestGit->commit($repo_ci);
    TestGit->tag($repo_ci, tag => 'release');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, branch => 'master', show_commit_tag => 1, project => 'test_project' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_commits($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                'icon' => ignore(),
                'text' => re(qr/^\[$RE_sha8\] update$/),
                'data' => {
                    'sha'        => re_sha(),
                    'branch'     => 'master',
                    'rev_num'    => re_sha(),
                    'repo_dir'   => ignore(),
                    'controller' => 'gittree',
                    'click'      => {
                        'repo_mid' => ignore(),
                        'action'   => 'edit',
                        'url'      => '/comp/view_diff.js',
                        'type'     => 'comp',
                        'title'    => re(qr/^Commit $RE_sha8$/),
                        'load'     => \1,
                        'repo_dir' => ignore()
                    },
                    'ci' => {
                        'ns'   => re(qr/^git\.revision\/$RE_sha$/),
                        'name' => re(qr/^\[$RE_sha8\] update$/),
                        'data' => {
                            'repo'   => 'ci_pre:0',
                            'ci_pre' => [
                                {
                                    'mid'  => ignore(),
                                    'ns'   => re(qr{git.repository/}),
                                    'name' => ignore(),
                                    'data' => {
                                        'repo_dir' => ignore()
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

subtest 'branch_commits: returns paged commits with more nodes available for initial page' => sub {
    _setup();

    my $tag  = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository();
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    my $sha1 = TestGit->commit($repo_path);
    my $sha2 = TestGit->commit($repo_path);

    TestUtils->create_ci( 'bl', bl => $tag,  name => $tag );

    BaselinerX::Type::Model::ConfigStore->new->set(
        key   => 'config.git.page_size',
        value => 2
    );

    my $params =
      { repo_mid => $repo->mid, branch => 'master', project => 'test_project', page => 1, show_commit_tag => 0 };
    my $c = mock_catalyst_c( req => { params => $params } );

    my $controller = _build_controller();
    $controller->branch_commits($c);

    is scalar @{ $c->stash->{json} }, 3;
    is $c->stash->{json}->[0]->{data}->{sha}, $sha2;
    is $c->stash->{json}->[1]->{data}->{sha}, $sha1;
    is $c->stash->{json}->[2]->{text}, 'Show next';
    is $c->stash->{json}->[2]->{data}->{page}, 2;
};

subtest 'branch_commits: always initialized in page 1 by default' => sub {
    _setup();

    my $tag  = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository();
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    my $sha1 = TestGit->commit($repo_path);
    my $sha2 = TestGit->commit($repo_path);

    TestUtils->create_ci( 'bl', bl => $tag,  name => $tag );

    BaselinerX::Type::Model::ConfigStore->new->set(
        key   => 'config.git.page_size',
        value => 2
    );

    my $params =
      { repo_mid => $repo->mid, branch => 'master', project => 'test_project', show_commit_tag => 0 };
    my $c = mock_catalyst_c( req => { params => $params } );

    my $controller = _build_controller();
    $controller->branch_commits($c);

    is $c->stash->{json}->[2]->{data}->{page}, 2;
};

subtest 'branch_commits: returns paged commits with more nodes available for non initial revision_paging_size' => sub {
    _setup();

    my $tag                  = 'tag_1';

    my $repo = TestUtils->create_ci_GitRepository();

    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    my $sha1 = TestGit->commit($repo_path);
    my $sha2 = TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    TestUtils->create_ci( 'bl', bl => $tag,  name => $tag );

    BaselinerX::Type::Model::ConfigStore->new->set(
        key   => 'config.git.page_size',
        value => 2
    );

    my $params =
      { repo_mid => $repo->mid, branch => 'master', project => 'test_project', page => 2, show_commit_tag => 0 };
    my $c = mock_catalyst_c( req => { params => $params } );

    my $controller = _build_controller();
    $controller->branch_commits($c);

    is scalar @{ $c->stash->{json} }, 2;
    is $c->stash->{json}->[0]->{data}->{sha}, $sha2;
    is $c->stash->{json}->[1]->{data}->{sha}, $sha1;
};

subtest 'branch_commits: returns paged commits with no more commits to show' => sub {
    _setup();

    my $tag  = 'tag_1';
    my $repo = TestUtils->create_ci_GitRepository();
    my $repo_path = $repo->repo_dir;
    TestGit->commit($repo_path);
    TestGit->tag( $repo_path, tag => $tag );
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);
    TestGit->commit($repo_path);

    TestUtils->create_ci( 'bl', bl => $tag,  name => $tag );

    BaselinerX::Type::Model::ConfigStore->new->set(
        key   => 'config.git.page_size',
        value => 15
    );

    my $params =
      { repo_mid => $repo->mid, branch => 'master', project => 'test_project', page => 3, show_commit_tag => 0 };
    my $c = mock_catalyst_c( req => { params => $params } );

    my $controller = _build_controller();
    $controller->branch_commits($c);

    is_deeply $c->stash, { json => [] };
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci);

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_changes($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
                icon => ignore(),
                text => 'README',
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci);
    TestGit->commit($repo_ci, file => 'foo/bar');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->branch_tree($c);

    cmp_deeply $c->stash,
      {
        json => [
            {
              'leaf' => \0,
              'url' => '/gittree/branch_tree',
              'iconCls' => 'default_folders',
              'data' => {
                          'repo_mid' => ignore(),
                          'branch' => 'HEAD',
                          'sha' => ignore(),
                          'folder' => 'foo'
                        },
              'text' => 'foo'
            },
            {
                'text' => 'README',
                'data' => {
                    'controller' => 'gittree',
                    'tab_icon'   => ignore(),
                    'click'      => {
                        'action' => 'edit',
                        'url'    => '/comp/view_file.js',
                        'type'   => 'comp',
                        'title'  => 'HEAD: README',
                        'load'   => \1
                    },
                    'repo_mid' => $repo_ci->mid,
                    'file'     => 'README',
                    'rev_num'  => re_sha(),
                    'branch'   => 'HEAD'
                },
                'iconCls' => 'default_folders',
                'leaf'    => \1
            }
        ]
      };
};

subtest 'branch_tree: returns tree from a subdirectory' => sub {
    _setup();

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci, file => 'foo/bar');

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
                'iconCls' => 'default_folders',
                'leaf'    => \1
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, message => 'initial');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'README', sha => $sha };

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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, message => 'initial', content => 'This is a howto.');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'README', sha => $sha };

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

subtest 'view_file: returns special content when binary' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit(
        $repo,
        file    => 'binary.img',
        content => do { local $/; open my $fh, '<', 'root/static/spinner.gif' or die $!; <$fh> }
    );

    my $controller = _build_controller();

    my $params = { repo_mid => $repo->mid, filename => 'binary.img', sha => $sha };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_file($c);

    cmp_deeply $c->stash,
      {
        json => {
            'msg'          => 'Success viewing file',
            'success'      => \1,
            'file_content' => "It's a Binary file (view method not applicable)",
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, content => 'This is a howto.');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'README', sha => $sha };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_blame($c);

    cmp_deeply $c->stash,
      {
        json => {
            'msg'      => re(qr/^\^[a-f0-9]{7} \(clarive .*?\) This is a howto\.$/),
            'success'  => \1,
            'suported' => \1
        }
      };
};

subtest 'get_file_blame: returns special blame when binary' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit(
        $repo,
        file    => 'binary.img',
        content => do { local $/; open my $fh, '<', 'root/static/spinner.gif' or die $!; <$fh> }
    );

    my $controller = _build_controller();

    my $params = { repo_mid => $repo->mid, filename => 'binary.img', sha => $sha };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_file_blame($c);

    cmp_deeply $c->stash,
      {
        json => {
            'msg'      => "It's a Binary file (blame method not applicable)",
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, message => 'initial', content => 'This is a howto.');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, file => 'README', sha => $sha };

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
                            'code'  => "+This is a howto.\n"
                        }
                    ],
                    'path'      => 'README',
                    'revision2' => re_sha8(),
                }
            ]
        }
      };
};

subtest 'view_diff_file: returns diff when file has only one line' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit( $repo, file => 'fich.txt', content => 'primera linea', message => 'primer commit' );
    my $sha2 = TestGit->commit(
        $repo,
        file    => 'fich.txt',
        content => 'segunda linea',
        message => 'segundo commit',
        action  => 'replace'
    );

    my $controller = _build_controller();

    my $params = { file => 'fich.txt', repo_mid => $repo->mid, sha => $sha2 };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff_file($c);

    is $c->stash->{json}->{changes}[0]->{code_chunks}[0]->{code}, "-primera linea\n+segunda linea\n";
};

subtest 'view_diff_file: returns diff when the change is in finally line' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit(
        $repo,
        file    => 'fich.txt',
        content => "Primera linea \nSegunda linea",
        message => 'primer commit'
    );
    my $sha2 = TestGit->commit(
        $repo,
        file    => 'fich.txt',
        content => "Primera linea \nModif Segunda linea",
        message => 'segundo commit',
        action  => 'replace',
    );

    my $controller = _build_controller();

    my $params = { file => 'fich.txt', repo_mid => $repo->mid, sha => $sha2 };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff_file($c);

    is $c->stash->{json}->{changes}[0]->{code_chunks}[0]->{code},
      " Primera linea \n-Segunda linea\n+Modif Segunda linea\n";
};

subtest 'view_diff_file: returns special diff for binary files' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit(
        $repo,
        file    => 'binary.img',
        content => do { local $/; open my $fh, '<', 'root/static/spinner.gif' or die $!; <$fh> }
    );

    my $controller = _build_controller();

    my $params = { file => 'binary.img', repo_mid => $repo->mid, sha => $sha };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff_file($c);

    cmp_deeply $c->stash->{json}->{changes}[0]->{code_chunks}[0],
      {
        stats => '-0,0 +0,0',
        code  => "It's a Binary file (diff method not applicable)"
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, message => 'initial', content => 'This is a howto.');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, sha => $sha };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff($c);

    cmp_deeply $c->stash,
      {
        json => {
            'commit_info' => {
                'revision' => re_sha8(),
                'comment'  => '    initial',
                'date'     => ignore(),
                'author'   => 'clarive <clarive@localhost>'
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
                    'path'      => 'README',
                    'revision2' => ignore()
                }
            ]
        }
      };
};

subtest 'view_diff: add at first of the code chunks a whitespace if it is not a diff' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository();

    my $sha = TestGit->commit(
        $repo,
        file    => 'fich.txt',
        content => "Primera linea\nSegunda linea\nTercera linea",
        message => 'primer commit'
    );
    my $sha2 = TestGit->commit(
        $repo,
        file    => 'fich.txt',
        content => "Primera linea\nModif Segunda linea\nTercera linea",
        message => 'segundo commit',
        action  => 'replace',
    );

    my $controller = _build_controller();

    my $params = { file => 'fich.txt', repo_mid => $repo->mid, sha => $sha2 };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->view_diff($c);

    is $c->stash->{json}->{changes}[0]->{code_chunks}[0]->{code},
        "  Primera linea\n-Segunda linea\n+Modif Segunda linea\n Tercera linea";
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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, message => 'initial');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, filename => 'README', sha => $sha };

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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci);
    TestGit->tag($repo_ci, tag => 'release');

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

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci, message => 'initial');

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
                    'date'   => ignore(),
                    'author' => 'clarive <clarive@localhost>',
                    'ago'    => ignore()
                }
            ]
        }
    };
};

subtest 'get_commits_search: returns found commits by author' => sub {
    _setup();

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci, message => 'initial');
    TestGit->commit($repo_ci, message => 'update');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, query => '--author="clarive"' };

    my $c = mock_catalyst_c( req => { params => $params } );

    $controller->get_commits_search($c);

    cmp_deeply $c->stash, {
        json => {
            'totalCount' => 2,
            'msg'        => 'Success loading commits history',
            'success'    => \1,
            'commits'    => [
                {
                    'revision' => ignore(),
                    'comment'  => '

    update
',
                    'date'   => re_date(),
                    'author' => 'clarive <clarive@localhost>',
                    'ago'    => ignore()
                },
                {
                    'revision' => re_sha8(),
                    'comment'  => '

    initial',
                    'date'   => re_date(),
                    'author' => 'clarive <clarive@localhost>',
                    'ago'    => ignore()
                }
            ]
        }
    };
};

subtest 'get_commits_search: returns found commits by revision' => sub {
    _setup();

    my $repo_ci = TestUtils->create_ci_GitRepository();
    my $sha = TestGit->commit($repo_ci, message => 'initial');

    my $controller = _build_controller();

    my $params = { repo_mid => $repo_ci->mid, query => substr($sha, 0, 5) };

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
                    'date'   => ignore(),
                    'author' => 'clarive <clarive@localhost>',
                    'ago'    => ignore()
                }
            ]
        }
    };
};

subtest 'get_commits_search: returns empty result when nothing found' => sub {
    _setup();

    my $repo_ci = TestUtils->create_ci_GitRepository();
    TestGit->commit($repo_ci, message => 'initial');

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

done_testing;

sub _build_controller {
    Baseliner::Controller::GitTree->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry();
    TestUtils->register_ci_events();
    TestUtils->cleanup_cis;
}
