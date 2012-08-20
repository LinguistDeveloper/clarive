use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Baseliner' }

my $m = Baseliner->model('Semaphores');

{
    my $req = $m->create( sem=>'test.sem', bl=>'TEST' );
    is( $req->sem, 'test.sem', 'create sem' );
    $req->status( 'waiting' );
    $req->update;

    $m->process_queue;
    $req->discard_changes;
    is( $req->status, 'granted', 'granted sem');
    $req->next_status;  # busy
    is( $req->status, 'busy', 'sem busy');

    my $sem = Baseliner->model('Baseliner::BaliSem')->search->first;
    is( $sem->occupied, 1, 'occupied count ok');

    my $req2 = $m->create( sem=>'test.sem', bl=>'TEST' );
    $req2->status( 'waiting' );
    $req2->update;
    $m->process_queue;
    $req2->discard_changes;
    is( $req2->status, 'waiting', 'no grant for you' )
}
{
    my $sem = Baseliner->model('Baseliner::BaliSem')->search->first;
    my $req = $sem->bl_queue->first;
    is( $req->status, 'done', 'auto destroy' );
}
{
    my $sem = Baseliner->model('Semaphores')->create( sem=>'test.sem2' );
    my $var = 0;
    eval { $sem->wait_for( frequency=>2, callback=>sub{ $var++ }, timeout=>5 ); };
    ok( $@ =~ m/Timeout/i, 'sem wait_for timeout' );
    is( $var, 3, 'sem callback count' );
    $sem->release;
}

done_testing;
