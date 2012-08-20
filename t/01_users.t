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
}



