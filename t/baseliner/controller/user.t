use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use Capture::Tiny qw(capture);
use Clarive::ci;
use Clarive::mdb;
use Baseliner::Core::Registry;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_file _dir _array);

use_ok 'Baseliner::Controller::User';

subtest 'infoactions: non admin user is not allowed to query other users action' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { username => 'root' } } );

    $controller->infoactions($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
};

subtest 'infoactions: same user is allowed to query his own actions' => sub {
    _setup();

    my $controller = _build_controller();
    my $c = _build_c( req => { params => { username => 'test' } } );
    $controller->infoactions($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infoactions: root user is allowed to query any user actions' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'test' } },
        username => 'root'
    );

    $controller->infoactions($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: non admin user is not allowed to query other users detail' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'root' } },
        username => 'test'
    );

    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
};

subtest 'infodetail: non admin user is not allowed to query role details' => sub {
    _setup();

    my $controller = _build_controller();
    my $params     = { id_role => 1 };
    my $c          = _build_c(
        req      => { params => { id_role => 1 } },
        username => 'test'
    );

    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { msg => re(qr/not authorized/) } };
};

subtest 'infodetail: same user is allowed to query his own details' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'test' } },
        username => 'test'
    );
    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'test' } },
        username => 'root'
    );
    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: root user is allowed to query any user details' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { id_role => 1 } },
        username => 'root'
    );
    $controller->infodetail($c);
    cmp_deeply $c->stash, { json => { data => ignore() } };
};

subtest 'infodetail: gets role if the project associated is active' => sub {
    _setup();

    my $project = TestUtils->create_ci_project( active => '1' );
    my $id_role = TestSetup->create_role();
    TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'user1' } },
        username => 'root'
    );
    $controller->infodetail($c);
    is $c->stash->{json}->{data}[0]->{id_role}, $id_role;
};

subtest 'infodetail: does not get role if the project associated is not active' => sub {
    _setup();

    my $project = TestUtils->create_ci_project( active => '0' );
    my $id_role = TestSetup->create_role();
    TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );

    my $controller = _build_controller();
    my $c          = _build_c(
        req      => { params => { username => 'user1' } },
        username => 'root'
    );
    $controller->infodetail($c);
    is $c->stash->{json}->{data}[0], undef;
};

subtest 'list: returns complete user list' => sub {
    _setup();

    my $controller = _build_controller();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );
    TestSetup->create_user( name => 'user2', username => 'user2', id_role => $id_role, project => $project );

    my $c = _build_c( username => 'root' );
    $controller->list($c);

    is $c->stash->{json}{data}[1]->{username}, 'user1';
    is $c->stash->{json}{data}[2]->{username}, 'user2';
    is @{$c->stash->{json}{data}}, 3;
    is $c->stash->{json}{totalCount}, 3;
};

subtest 'list: returns user list with limit -1' => sub {
    _setup();

    my $controller = _build_controller();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );
    TestSetup->create_user( name => 'user2', username => 'user2', id_role => $id_role, project => $project );

    my $c = _build_c(
        req      => { params => { limit => -1 } },
        username => 'root'
    );
    $controller->list($c);

    is @{$c->stash->{json}{data}}, 3;
    is $c->stash->{json}{totalCount}, 3;
};

subtest 'list: returns user list with limit 1' => sub {
    _setup();

    my $controller = _build_controller();

    my $project = TestUtils->create_ci('project');
    my $id_role = TestSetup->create_role();
    TestSetup->create_user( name => 'user1', username => 'user1', id_role => $id_role, project => $project );
    TestSetup->create_user( name => 'user2', username => 'user2', id_role => $id_role, project => $project );

    my $c = _build_c(
        req => { params => { limit => 1 } },
        username => 'root'
    );
    $controller->list($c);

    is @{$c->stash->{json}{data}}, 1;
    is $c->stash->{json}{totalCount}, 3;
};

subtest 'avatar: generates user avatar if it doesnt exit' => sub {
    _setup();

    my $tempdir = tempdir();

    my $c = _build_c( username => 'root', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $controller = _build_controller();
    $controller->avatar($c);

    my ($file) = $c->mocked_call_args('serve_static_file');

    ok -d "$tempdir/root/identicon";
    ok -f "$tempdir/root/identicon/root.png";

    like $file, qr{$tempdir/root/identicon/root.png};
    like _file($file)->slurp, qr/^.PNG/;
};

subtest 'avatar: generates avatar for specific user' => sub {
    _setup();

    my $tempdir = tempdir();

    my $c = _build_c( username => 'user', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $controller = _build_controller();
    $controller->avatar( $c, 'user', 'foo.png' );

    my ($file) = $c->mocked_call_args('serve_static_file');

    ok -d "$tempdir/root/identicon";
    ok -f "$tempdir/root/identicon/user.png";

    like $file, qr{$tempdir/root/identicon/user.png};
    like _file($file)->slurp, qr/^.PNG/;
};

subtest 'avatar: returns avatar if exists' => sub {
    _setup();

    my $tempdir = tempdir();

    _dir("$tempdir/root/identicon")->mkpath;
    TestUtils->write_file( "HELLO", "$tempdir/root/identicon/root.png" );

    my $c = _build_c( username => 'root', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $controller = _build_controller();
    $controller->avatar($c);

    my ($file) = $c->mocked_call_args('serve_static_file');

    like $file, qr{$tempdir/root/identicon/root.png};
    is _file($file)->slurp, 'HELLO';
};

subtest 'avatar: returns default avatar when generation fails' => sub {
    _setup();

    my $tempdir = tempdir();

    _dir("$tempdir/root/static/images/icons/")->mkpath;
    TestUtils->write_file( "DEFAULT", "$tempdir/root/static/images/icons/user.svg" );

    my $c = _build_c( username => 'root', path_to => $tempdir );
    $c = Test::MonkeyMock->new($c);
    $c->mock('serve_static_file');

    my $identicon_generator = Test::MonkeyMock->new;
    $identicon_generator->mock( generate => sub { die 'some error' } );

    my $controller = _build_controller();
    $controller = Test::MonkeyMock->new($controller);
    $controller->mock( _build_identicon_generator => sub {$identicon_generator} );
    $controller->avatar($c);

    my ($file) = $c->mocked_call_args('serve_static_file');

    like $file, qr{$tempdir/root/static/images/icons/user.svg};
    is _file($file)->slurp, 'DEFAULT';
};

subtest 'avatar_refresh: removes existing avatar' => sub {
    _setup();

    my $tempdir = tempdir();

    _dir("$tempdir/root/identicon")->mkpath;
    TestUtils->write_file( "HELLO", "$tempdir/root/identicon/root.png" );

    my $c = _build_c( username => 'root', path_to => $tempdir );

    my $controller = _build_controller();
    $controller->avatar_refresh($c);

    ok !-e "$tempdir/root/identicon/root.png";
    cmp_deeply $c->stash, { json => { success => \1, msg => 'Avatar refreshed' } };
};

subtest 'avatar_refresh: shows error when no avatar was present' => sub {
    _setup();

    my $tempdir = tempdir();

    my $c = _build_c( username => 'root', path_to => $tempdir );

    my $controller = _build_controller();
    $controller->avatar_refresh($c);

    cmp_deeply $c->stash,
        { json => { success => \0, msg => re(qr/Error removing previous avatar '.*?': No such file or directory/) } };
};

subtest 'avatar_refresh: throws when refreshing avatar for another user' => sub {
    _setup();

    my $c = _build_c( username => 'test' );

    my $controller = _build_controller();

    like exception { $controller->avatar_refresh( $c, 'otheruser' ) },
        qr/Cannot change avatar for user otheruser: user test not administrator/;
};

subtest 'avatar_refresh: removes avatar for another when root' => sub {
    _setup();

    my $tempdir = tempdir();

    _dir("$tempdir/root/identicon")->mkpath;
    TestUtils->write_file( "HELLO", "$tempdir/root/identicon/otheruser.png" );

    my $c = _build_c( username => 'root', path_to => $tempdir );

    my $controller = _build_controller();

    $controller->avatar_refresh( $c, 'otheruser' );

    ok !-e "$tempdir/root/identicon/otheruser.png";
};

subtest 'avatar_refresh: removes avatar for another user has admin action' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.admin.users', } ] );
    my $user = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );

    my $tempdir = tempdir();

    _dir("$tempdir/root/identicon")->mkpath;
    TestUtils->write_file( "HELLO", "$tempdir/root/identicon/otheruser.png" );

    my $c = _build_c( username => $user->username, path_to => $tempdir );

    my $controller = _build_controller();

    $controller->avatar_refresh( $c, 'otheruser' );

    ok !-e "$tempdir/root/identicon/otheruser.png";
};

subtest 'avatar_upload: returns an error when upload fails' => sub {
    _setup();

    my $tempdir = tempdir();

    my $c = _build_c( username => 'root', path_to => $tempdir, req => { body => 'wrong file handle' } );

    my $controller = _build_controller();
    $controller->avatar_upload($c);

    cmp_deeply $c->stash,
        {
        'json' => {
            'msg'     => re(qr/Error saving uploaded avatar: /),
            'success' => \0
        }
        };
};

subtest 'avatar_upload: saves avatar' => sub {
    _setup();

    my $tempdir = tempdir();

    open my $fh, '<', 'root/static/images/icons/user.png';

    my $c = _build_c( username => 'root', path_to => $tempdir, req => { body => $fh } );

    my $controller = _build_controller();
    $controller->avatar_upload($c);

    ok -e "$tempdir/root/identicon/root.png";

    cmp_deeply $c->stash,
        {
        'json' => {
            'msg'     => 'Changed user avatar',
            'success' => \1
        }
        };
};

subtest 'avatar_upload: throws when uploading avatar for another user' => sub {
    _setup();

    my $c = _build_c( username => 'test' );

    my $controller = _build_controller();

    like exception { $controller->avatar_upload( $c, 'otheruser' ) },
        qr/Cannot change avatar for user otheruser: user test not administrator/;
};

subtest 'avatar_upload: uploads avatar for another when root' => sub {
    _setup();

    my $tempdir = tempdir();

    open my $fh, '<', 'root/static/images/icons/user.png';

    my $c = _build_c( username => 'root', path_to => $tempdir, req => { body => $fh } );

    my $controller = _build_controller();

    $controller->avatar_upload( $c, 'otheruser' );

    ok -e "$tempdir/root/identicon/otheruser.png";
};

subtest 'avatar_upload: upload avatar for another user has admin action' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.admin.users', } ] );
    my $user = TestSetup->create_user( name => 'user', username => 'user', id_role => $id_role, project => $project );

    my $tempdir = tempdir();

    _dir("$tempdir/root/identicon")->mkpath;
    TestUtils->write_file( "HELLO", "$tempdir/some-file.png" );

    open my $fh, '<', "$tempdir/some-file.png";

    my $c = _build_c( username => $user->username, path_to => $tempdir, req => { body => $fh } );

    my $controller = _build_controller();

    $controller->avatar_upload( $c, 'otheruser' );

    ok -e "$tempdir/root/identicon/otheruser.png";
};

subtest 'country_info: get country info successful' => sub {
    _setup();

    my $c = _build_c( path_to => $ENV{CLARIVE_HOME} );
    my $controller = _build_controller();
    $controller->country_info($c);

    my @cnt = _array $c->stash->{json}->{data};

    is scalar @cnt, '249';
    cmp_deeply $c->stash, { json => { msg => 'Country info success', success => \1, data => ignore() } };
};

subtest 'country_info: File not found' => sub {
    _setup();

    my $c = _build_c( path_to => '/foo' );
    my $controller = _build_controller();

    $controller->country_info($c);

    cmp_deeply $c->stash, { json => { msg => re(qr/Error: File not found/), success => \0 } };
};

subtest 'timezone_list: list the timezone' => sub {
    _setup();

    my $c          = _build_c();
    my $controller = _build_controller();

    $controller->timezone_list($c);
    my @cnt = _array $c->stash->{json}->{data};

    is scalar @cnt, '349';
};

subtest 'repl_config: return the user preferences in the repl console' =>
    sub {
    _setup();

    my $user       = TestSetup->create_user();
    my $c          = mock_catalyst_c( username => $user->username );
    my $controller = _build_controller();

    $controller->repl_config($c);
    my @data = _array $c->stash->{json}->{data};

    cmp_deeply @data,
        {
        'lang'   => 'js-server',
        'syntax' => 'javascript',
        'out'    => 'yaml',
        'theme'  => 'eclipse'
    };
};

subtest
    'update_repl_config: updates the user preferences when change language'
    => sub {
    _setup();

    my $user = TestSetup->create_user();
    my $c    = mock_catalyst_c(
        username => $user->username,
        req => { params => { 'lang' => 'css', 'syntax' => 's-css' } }
    );

    my $controller = _build_controller();

    $controller->update_repl_config($c);

    my $data = $c->stash->{json}->{data};

    is $data->{lang},   'css';
    is $data->{syntax}, 's-css';
};

subtest
    'update_repl_config: updates the user preferences when change output' =>
    sub {
    _setup();

    my $user = TestSetup->create_user();
    my $c    = mock_catalyst_c(
        username => $user->username,
        req => { params => { 'out' => 'json' } }
    );

    my $controller = _build_controller();

    $controller->update_repl_config($c);

    my $data = $c->stash->{json}->{data};

    is $data->{out}, 'json';
};

subtest 'update_repl_config: updates the user preferences when change theme' =>
    sub {
    _setup();

    my $user = TestSetup->create_user();
    my $c    = mock_catalyst_c(
        username => $user->username,
        req => { params => { 'theme' => 'chaos' } }
    );

    my $controller = _build_controller();

    $controller->update_repl_config($c);

    my $data = $c->stash->{json}->{data};

    is $data->{theme}, 'chaos';
};

subtest 'projects_list: shows only the projects actives' => sub {
    _setup();

    my $project  = TestUtils->create_ci( 'project', name => 'Project', active => '1' );
    my $project2 = TestUtils->create_ci( 'project', name => 'Project', active => '0' );

    my $c          = mock_catalyst_c();
    my $controller = _build_controller();

    $controller->projects_list($c);

    my @tree = _array $c->stash->{json};

    is @tree, 1;
    is $tree[0]->{data}->{id_project}, $project->mid;
};

done_testing;

sub _build_c {
    mock_catalyst_c(
        username => 'test',
        model    => 'Baseliner::Model::Permissions',
        @_
    );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Config',
        'BaselinerX::Type::Menu',
        'Baseliner::Controller::User',
        'Baseliner::Controller::Role',
    );

    TestUtils->register_ci_events();

    mdb->master->drop;
    mdb->master_rel->drop;
    mdb->master_doc->drop;

    my $user = ci->user->new( name => 'test' );
    $user->save;
}

sub _build_controller {
    Baseliner::Controller::User->new( application => '' );
}
