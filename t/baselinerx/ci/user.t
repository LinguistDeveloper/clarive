use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use Baseliner::Utils qw(_array);

use_ok 'BaselinerX::CI::user';

subtest 'preferences by default' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role;
    my $user    = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );
    my $ci_user = BaselinerX::CI::user->new;

    is( $ci_user->{country},          'es' );
    is( $ci_user->{currency},         'EUR' );
    is( $ci_user->{decimal},          'Comma' );
    is( $ci_user->{date_format_pref}, 'format_from_local' );
    is( $ci_user->{time_format_pref}, 'format_from_local' );
    is( $ci_user->{timezone_pref},    'server_timezone' );
};

subtest 'general_prefs_save: save prefs when user change it' => sub {
    _setup();

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role;
    my $ci_user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project );
    my $data    = (
        {   data => {
                country          => 'us',
                currency         => 'USD',
                decimal          => 'Period',
                date_format_pref => 'format_from_local',
                time_format_pref => 'format_from_local',
                timezone_pref    => 'server_timezone'
            },
            username => $ci_user->{name}
        }
    );
    $ci_user->general_prefs_save($data);

    is( $ci_user->{country},  'us' );
    is( $ci_user->{currency}, 'USD' );
    is( $ci_user->{decimal},  'Period' );
    is( $ci_user->{mid},      $ci_user->{mid} );
};

subtest 'combo_list: returns empty list when no users' => sub {
    _setup();

    my $res = BaselinerX::CI::user->combo_list();

    is_deeply $res, { data => [] };
};

subtest 'combo_list: returns users list' => sub {
    _setup();

    TestSetup->create_user( username => 'developer', realname => 'Developer' );

    my $res = BaselinerX::CI::user->combo_list();

    is_deeply $res, { data => [ { username => 'developer', realname => 'Developer' } ] };
};

subtest 'combo_list: returns users list with query' => sub {
    _setup();

    TestSetup->create_user( username => 'developer', realname => 'Developer' );
    TestSetup->create_user( username => 'user',      realname => 'User' );

    my $res = BaselinerX::CI::user->combo_list( { query => 'ser' } );

    is_deeply $res, { data => [ { username => 'user', realname => 'User' } ] };
};

subtest 'combo_list: returns only active users' => sub {
    _setup();

    TestSetup->create_user( username => 'developer', active => 1, realname => 'Developer' );
    TestSetup->create_user( username => 'user',      active => 0, realname => 'User' );

    my $res = BaselinerX::CI::user->combo_list();

    is_deeply $res, { data => [ { username => 'developer', realname => 'Developer' } ] };
};

subtest 'combo_list: returns variables' => sub {
    _setup();

    TestUtils->create_ci(
        'variable',
        var_type     => 'ci',
        var_ci_role  => 'Baseliner::Role::CI',
        var_ci_class => 'user',
        name         => 'user'
    );

    my $res = BaselinerX::CI::user->combo_list( { with_vars => 1 } );

    cmp_deeply $res,
      {
        'data' => [
            {
                'icon'     => ignore(),
                'realname' => 'variable',
                'username' => '${user}'
            }
        ]
      };
};

subtest 'combo_list: returns variables by query' => sub {
    _setup();

    TestUtils->create_ci(
        'variable',
        var_type     => 'ci',
        var_ci_role  => 'Baseliner::Role::CI',
        var_ci_class => 'user',
        name         => 'user'
    );

    TestUtils->create_ci(
        'variable',
        var_type     => 'ci',
        var_ci_role  => 'Baseliner::Role::CI',
        var_ci_class => 'user',
        name         => 'client'
    );

    my $res = BaselinerX::CI::user->combo_list( { with_vars => 1, query => 'cli' } );

    is $res->{data}->[0]->{username}, '${client}';
};

subtest 'combo_list: returns variables by query as value' => sub {
    _setup();

    TestUtils->create_ci(
        'variable',
        var_type     => 'ci',
        var_ci_role  => 'Baseliner::Role::CI',
        var_ci_class => 'user',
        name         => 'user'
    );

    TestUtils->create_ci(
        'variable',
        var_type     => 'ci',
        var_ci_role  => 'Baseliner::Role::CI',
        var_ci_class => 'user',
        name         => 'client'
    );

    my $res = BaselinerX::CI::user->combo_list( { with_vars => 1, valuesqry => 1, query => '${client}' } );

    is $res->{data}->[0]->{username}, '${client}';
};

subtest 'combo_list: returns query when extra values' => sub {
    _setup();

    my $res =
      BaselinerX::CI::user->combo_list( { valuesqry => 'true', query => 'custom value', with_extra_values => 'true' } );

    is $res->{data}->[0]->{username}, 'custom value';
};

subtest 'groups: user that already belongs to a group gets security merged when added group to user' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis({ name => 'Group1'});
    $group->project_security({ "$role" => { 'project' => [$prj->mid]} });

    #Add user to first group
    $group->set_users(($user));
    $group->save;

    $user = ci->new($user->mid);

    my $role2 = TestUtils->create_role('Test role 2',2);
    my $group2 = _build_cis({ name => 'Group2'});

    $group2->project_security({ "$role2" => { 'project' => [$prj->mid]} });
    $group2->save;

    #Add group to the user
    $user->groups((_array($user->groups),$group2));
    $user->save;

    is_deeply $user->project_security, { "$role" => { 'project' => [$prj->mid]}, "$role2" => { 'project' => [$prj->mid]} };
};

subtest 'groups: user keeps group1 security when is removed from group2' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis({ name => 'Group1'});
    $group->project_security({ "$role" => { 'project' => [$prj->mid]} });

    #Add user to first group
    $group->set_users(($user));
    $group->save;

    $user = ci->new($user->mid);

    my $role2 = TestUtils->create_role('Test role 2',2);
    my $group2 = _build_cis({ name => 'Group2'});

    $group2->project_security({ "$role2" => { 'project' => [$prj->mid]} });
    $group2->save;

    #Add group to the user
    $user->groups((_array($user->groups),$group2));
    $user->save;

    is_deeply $user->project_security, { "$role" => { 'project' => [$prj->mid]}, "$role2" => { 'project' => [$prj->mid]} };

    #Add group to the user
    $user->groups($group);
    $user->save;

    is_deeply $user->project_security, { "$role" => { 'project' => [$prj->mid]} };
};

subtest 'groups: user security sets to group when added to the user groups' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis();
    $group->project_security({ "$role" => { 'project' => [$prj->mid]} });
    $group->save;

    #Add group to the user
    $user->groups([$group]);
    $user->save;

    $user = ci->new($user->mid);

    is_deeply $user->project_security, { "$role" => { 'project' => [$prj->mid]} };
};


done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::CI', 'BaselinerX::Type::Event' );
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_roles;
    TestUtils->register_ci_events;
    TestUtils->cleanup_cis;
}

sub _build_cis {
    my ($p) = @_;

    my $ci_group = TestUtils->create_ci('UserGroup', name => $p->{name} // 'Test group');
    $ci_group->save();
    return $ci_group;
}

sub _setup_security {
    my $ci_prj = TestUtils->create_ci('project', name => 'Test project');
    my $ci_user = TestUtils->create_ci('user', name => 'Test user');
    my $role = TestUtils->create_role('Test role 1');

    $ci_prj->save();
    $ci_user->save();

    return ($ci_prj, $ci_user, $role);
}
