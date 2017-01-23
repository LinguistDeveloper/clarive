use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;
use TestUtils;

use Baseliner::Utils;

use_ok('BaselinerX::CI::UserGroup');

subtest 'action: can create group' => sub {
    _setup();

    my ( $project, $user, $role ) = _setup_security();
    my $group = _build_group();

    #Add user to group
    $group->set_users( $user );
    $group->save;

    my ($res) = _array( $group->users );

    is $res->mid, $user->mid;
};

subtest 'set_users: updates group in user' => sub {
    _setup();

    my ( $project, $user, $role ) = _setup_security();
    my $group = _build_group();

    $group->project_security( { "$role" => { 'project' => [ $project->mid ] } } );
    $group->save;

    #Add user to group
    $group->set_users( $user );

    $user = ci->new( $user->mid );

    is_deeply $user->project_security, { "$role" => { 'project' => [ $project->mid ] } };
};

subtest 'set_users: updates groups in users' => sub {
    _setup();

    my ( $project, $user, $role ) = _setup_security();
    my $group = _build_group();
    $group->project_security( { "$role" => { 'project' => [ $project->mid ] } } );

    my $user2 = TestUtils->create_ci( 'user', name => 'Test user2' );
    $user2->save();

    #Add users to group
    $group->set_users( $user, $user2 );
    $group->save;

    $user  = ci->new( $user->mid );
    $user2 = ci->new( $user2->mid );

    is_deeply [ $user->project_security, $user2->project_security ],
      [ { "$role" => { 'project' => [ $project->mid ] } }, { "$role" => { 'project' => [ $project->mid ] } } ];
};

subtest 'set_users: merges security with previously added users' => sub {
    _setup();

    my ( $project, $user, $role ) = _setup_security();
    my $group = _build_group();
    $group->project_security( { "$role" => { 'project' => [ $project->mid ] } } );

    #Add user to first group
    $group->set_users( $user );
    $group->save;

    my $role2 = TestSetup->create_role( id => 2, role => 'Test role 2' );
    my $group2 = _build_group();
    $group2->project_security( { "$role2" => { 'project' => [ $project->mid ] } } );

    #Add user to group
    $group2->set_users( $user );
    $group2->save;

    $user = ci->new( $user->mid );

    is_deeply $user->project_security,
      { "$role" => { 'project' => [ $project->mid ] }, "$role2" => { 'project' => [ $project->mid ] } };
};

done_testing;

sub _setup {
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_cis;
    TestUtils->cleanup_roles;
    TestUtils->register_ci_events;
}

sub _build_group {
    my ($p) = @_;

    my $ci_group = TestUtils->create_ci( 'UserGroup', name => $p->{name} // 'Test group' );
    $ci_group->save();
    return $ci_group;
}

sub _setup_security {
    my $ci_project  = TestUtils->create_ci( 'project', name => 'Test project' );
    my $ci_user = TestUtils->create_ci( 'user',    name => 'Test user' );
    my $role = TestSetup->create_role( role => 'Test role 1' );

    $ci_project->save();
    $ci_user->save();

    return ( $ci_project, $ci_user, $role );
}
