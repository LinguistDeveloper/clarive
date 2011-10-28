use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Baseliner' }

#ok( 1, 'init' );

# create the root user
{
    my $mu = Baseliner->model('Baseliner::BaliUser');
    $mu->create({ username=>'root', password=>'password' });
    my $user = $mu->search->first;
    ok( $user->username eq 'root', 'created root user' );

    my $role = Baseliner->model('Baseliner::BaliRole')->create({ role=>'root', description=>'the root role' });
    $role->bali_roleactions->create({ action=>'action.admin.root' });
    $role->bali_roleusers->create({ username=>'root' });

    ok( Baseliner->model('Permissions')->user_has_action( username=>'root', action=>'action.admin.root' ), 'user has action' );
    ok( Baseliner->model('Permissions')->user_has_action( username=>'root', action=>'action.123456789dfghjk' ), 'root has any action' );
}

done_testing;
