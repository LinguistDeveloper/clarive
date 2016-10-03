use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

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

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::CI', 'BaselinerX::Type::Event' );

    TestUtils->cleanup_cis;
}
