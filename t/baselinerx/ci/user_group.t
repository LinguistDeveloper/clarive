use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::Utils;

# use Baseliner;
# use Baseliner::CI;
# use Clarive::ci;
# use Baseliner::Core::Registry;
# use Baseliner::Role::CI;    # WTF this is needed for CI
# use BaselinerX::CI::variable;

use_ok('BaselinerX::CI::UserGroup');

subtest 'action: can create group' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis();

    #Add user to group
    $group->set_users(($user));
    $group->save;

    my ($res) = _array($group->users);

    is $res->mid, $user->mid;
};

subtest 'set_users: user security sets to group when added' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis();

    $group->project_security({ "$role" => { 'project' => [$prj->mid]} });
    $group->save;

    #Add user to group
    $group->set_users(($user));

    $user = ci->new($user->mid);

    is_deeply $user->project_security, { "$role" => { 'project' => [$prj->mid]} };
};

subtest 'set_users: user security sets to all users in group when added' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis();
    $group->project_security({ "$role" => { 'project' => [$prj->mid]} });

    my $user2 = TestUtils->create_ci('user', name => 'Test user2');
    $user2->save();

    #Add users to group
    $group->set_users(($user,$user2));
    $group->save;

    $user = ci->new($user->mid);
    $user2 = ci->new($user2->mid);

    is_deeply [ $user->project_security, $user2->project_security ],
        [
            { "$role" => { 'project' => [ $prj->mid ] } },
            { "$role" => { 'project' => [ $prj->mid ] } }
        ];
};

subtest 'set_users: user that already belongs to a group gets security merged' => sub {
    _setup();

    my ( $prj, $user, $role) = _setup_security();
    my $group = _build_cis();
    $group->project_security({ "$role" => { 'project' => [$prj->mid]} });

    #Add user to first group
    $group->set_users(($user));
    $group->save;

    my $role2 = TestUtils->create_role('Test role 2',2);
    my $group2 = _build_cis();
    $group2->project_security({ "$role2" => { 'project' => [$prj->mid]} });

    #Add user to group
    $group2->set_users(($user));
    $group2->save;

    $user = ci->new($user->mid);

    is_deeply $user->project_security, { "$role" => { 'project' => [$prj->mid]}, "$role2" => { 'project' => [$prj->mid]} };
};

done_testing;

sub _setup {
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_cis;
    TestUtils->cleanup_roles;
    TestUtils->register_ci_events;
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
