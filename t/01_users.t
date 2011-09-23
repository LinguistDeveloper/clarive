use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Baseliner' }

# create any user Joe
{
    my $mu = Baseliner->model('Baseliner::BaliUser');
    $mu->create({ username=>'joe', password=>'password' });
    my $user = $mu->search({ username=>'joe' })->first;
    ok( $user->username eq 'joe', 'created joe user' );

    my $perm = Baseliner->model('Permissions');
    ok( ! $perm->user_has_action( username=>'joe', action=>'action.admin.root' ), 'joe has no action' );

    $perm->create_role( 'ROLE_TEST' );
    $perm->add_action( 'action.test1', 'ROLE_TEST' );
    $perm->add_action( 'action.test2', 'ROLE_TEST' );
    $perm->grant_role( username=>'joe', role=>'ROLE_TEST' );

    my $projects =
        $perm->user_projects_for_action( username => 'joe',
            action => [ 'action.test1', 'action.test2' ] )
        ; 
    is( $projects->[0], 1, 'project found for user' );
}



