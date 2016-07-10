use strict;
use warnings;

use Test::More;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use_ok 'Baseliner::ActionRole::ACL';

subtest 'returns 1 when user has permission' => sub {
    _setup();

    Baseliner::Core::Registry->add('main', 'action.some' => {});

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role( actions => [ { action => 'action.some' } ] );
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = mock_catalyst_c( username => $user->username );

    my $action = _build_action();

    $action->{attributes}->{ACL} = 'action.some';

    ok $action->match($c);
    ok $action->match_captures($c);
};

subtest 'returns 0 when user has no permission' => sub {
    _setup();

    Baseliner::Core::Registry->add('main', 'action.some' => {});

    my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $c = mock_catalyst_c( username => $user->username );

    my $action = _build_action();

    $action->{attributes}->{ACL} = 'action.some';

    ok !$action->match($c);
    ok !$action->match_captures($c);
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Action',
    );
    TestUtils->cleanup_cis;

    mdb->role->drop;
}

sub _build_action {
    my $meta = Moose::Meta::Class->initialize('TestActionACL')->create_anon_class(
        superclasses => ['TestActionACL'],
        roles        => ['Baseliner::ActionRole::ACL'],
        cache        => 1,
    );

    return $meta->name->new;
}

package TestActionACL;
use Moose;
BEGIN { extends 'Catalyst::Action' }

sub match          { 1 }
sub match_captures { 1 }
