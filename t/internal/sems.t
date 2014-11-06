use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
{
    
    $ENV{BALI_CMD} = 1;
    require Sys::Hostname;
    require Clarive::mdb;
    require Clarive::cache;
    require Baseliner::Sem;
    require Baseliner;
    require Time::HiRes;
    use Baseliner::Utils;
    
    mdb->sem->remove({ key=>'test' });
    mdb->sem_queue->remove({ key=>'test' });
    my $slotcnt = sub { mdb->sem->find_one({ key=>'test' })->{slots} };
    my $maxslots = sub { mdb->sem->find_one({ key=>'test' })->{maxslots} };
    $| = 1;
    
    if(1) {
        my $sem1 = Baseliner::Sem->new( key=>'test', who=>"sems.t", slots=>2 );
        
        my $max = $maxslots->();
        is $max, 2, 'maxslots is 2 from the beginning';
        
        my $slots1 = $slotcnt->();
        is $slots1, 0, '0 slot before take'; 

        $sem1->take;
        
        my $slots2 = $slotcnt->();
        is $slots2, 1, '1 slot after take'; 

        for( 1..4 ) {
            my $semt = Baseliner::Sem->new( key=>'test', who=>"sems.t" );
            $semt->take( wait_interval=>.1 );
            my $slotsloop = $slotcnt->();
            is $slotsloop, 2, '2 slot after 2nd take'; 
        }
        
        my $slots3 = $slotcnt->();
        is $slots2,$slots3, 'all loop sems destroyed';
        
        $sem1->release;
        
        my $slotsf = $slotcnt->();
        is $slotsf,0, 'all sems destroyed';
        
        my $max2 = $maxslots->();
        is $max2, 2, 'maxslots is 2 still';
        
    }
    
    
    # critical section test
    if(1){
        my $maxchi = 10;
        my $maxloop = 50;
        
        $| = 1;
        mdb->sem->update({ key=>'test' },{ '$set'=>{ maxslots=>1 } });
        mdb->sem_test->drop;
        mdb->sem_test->insert({ k=>0, tot1=>0, tot2=>0 });
        my $critical = sub{
            my $who = shift;
            #warn "CHILD $who\n" ;
            my $k1 = mdb->sem_test->find_one->{k};
            $k1==0 ? mdb->sem_test->update({ },{ '$inc'=>{ tot1=>1 } }) : _error( "$who misfired before" );
            #is $k1, 0, '1 is 0 for ' . $who;
            mdb->sem_test->update({ },{ '$inc'=>{ k=>1 } });
            Time::HiRes::usleep( int( 2000 * rand() ) );
            mdb->sem_test->update({ },{ '$inc'=>{ k=>-1 } });
            my $k2 = mdb->sem_test->find_one->{k};
            $k2==0 ? mdb->sem_test->update({ },{ '$inc'=>{ tot2=>1 } }) : _error( "$who misfired after" );
            
            #is $k2, 0, '2 is 0 for ' . $who;
        };
        
        my @pids;
        for my $n ( 1..$maxchi ) {
            if( my $pid = fork ) {
                # parent
                push @pids, $pid;
            }else {
                # child
                mdb->disconnect;
                for( 1..$maxloop ) {
                    my $chi = Baseliner::Sem->new( key=>'test', who=>"child_$n" );
                    $chi->take( wait_interval=>.1 );
                    $critical->("child_$n");
                    $chi->release;
                    #Time::HiRes::usleep( int( 100 * rand() ) );
                }
                exit 0;
            }
        }
        
        waitpid $_, 0 for @pids;
        my $doc = mdb->sem_test->find_one;
        is $$doc{k}, 0, 'k is zero at the end';
        is $$doc{tot1}, ($maxchi*$maxloop), 'all children ok before';
        is $$doc{tot2}, ($maxchi*$maxloop), 'all children ok after';
        mdb->sem_test->drop();
        
        my $s = mdb->sem->find_one({ key=>'test' });
        is $s->{slots}, 0, 'slots is zero at the end';
        is $s->{maxslots}, 1, 'maxslots is 1 at the end';
    }

    if(1) {
        my $maxchi = 40;
        my $maxloop = 1000;
        
        mdb->sem->update({ key=>'test' },{ '$set'=>{ maxslots=>1 } });
        mdb->sem_test->drop();
        mdb->sem_test->insert({ timeouts=>0 });
        
        my $critical = sub{
            my $who = shift;
            my $ran = substr(Time::HiRes::time(),-1,1);
            warn "CHILD $who - $ran\n";
            Time::HiRes::usleep( int( 100 * rand() ) );
            if( $ran == 1 ){
                warn "---EXIT $who\n";
                kill 9 => $$;
            }
        };
        
        my @pids;
        for my $n ( 1..$maxchi ) {
            if( my $pid = fork ) {
                # parent
                push @pids, $pid;
            }else {
                # child
                mdb->disconnect;
                for( 1..$maxloop ) {
                    my $chi = Baseliner::Sem->new( key=>'test', who=>"child_$n" );
                    try {
                        $chi->take( wait_interval=>.1, timeout=>20 );
                        $critical->("child_$n");
                        $chi->release;
                    } catch {
                        mdb->sem_test->update({},{ '$inc'=>{timeouts=>1} });
                    };
                }
                exit 0;
            }
        }
        
        waitpid $_, 0 for @pids;
        my $doc = mdb->sem_test->find_one;
        is $$doc{timeouts}, 0, 'timeouts is zero at the end';
        
        my $last = Baseliner::Sem->new( key=>'test', who=>"cleanup" );
        $last->take;
        $last->release;
        
        ok 1,'take-release last';
        my $s = mdb->sem->find_one({ key=>'test' });
        is $s->{slots}, 0, 'slots is zero at the end';
        is $s->{maxslots}, 1, 'maxslots is 1 at the end';
        
    }
    
    # granted test
    if(1){
        mdb->sem->update({ key=>'test' },{ '$set'=>{ maxslots=>1 } });
        mdb->sem_test->drop();
        mdb->sem_test->insert({ aa=>0 });
        
        my @pids;
        my $par = Baseliner::Sem->new( key=>'test', who=>"parent" );
        $par->take( wait_interval=>.1, timeout=>20 );
        
        if( my $pid = fork ) {
            push @pids, $pid;
        } else {
            # child
            mdb->disconnect;
            my $chi = Baseliner::Sem->new( key=>'test', who=>"child" );
            $chi->take( wait_interval=>.1, timeout=>20 );
            mdb->sem_test->update({ aa=>0 },{ aa=>1 });
            $chi->release;
            exit 0;
        }
        
        while(1){
            # grant if available
            my $ret = mdb->sem->update({ key=>'test', 'queue.who'=>'child' },{ '$set'=>{ 'queue.$.status'=>'granted' } });
            last if $ret->{updatedExisting};
        }
        sleep 2;
        mdb->sem_test->update({ aa=>1 },{ aa=>2 });
        $par->release;
        
        waitpid $_, 0 for @pids;
        ok( mdb->sem_test->find_one->{aa}==2, 'granted doc not deleted by child' );
        my $s = mdb->sem->find_one({ key=>'test' });
        is $s->{slots}, 0, 'granted slots is zero at the end';
        is $s->{maxslots}, 1, 'granted maxslots is 1 at the end';
    }
    
    # cancelled test
    if(1){
        mdb->sem->update({ key=>'test' },{ '$set'=>{ maxslots=>1 } });
        mdb->sem_test->drop();
        mdb->sem_test->insert({ aa=>0 });
        
        my @pids;
        my $par = Baseliner::Sem->new( key=>'test', who=>"parent" );
        $par->take( wait_interval=>.1, timeout=>20 );
        
        if( my $pid = fork ) {
            push @pids, $pid;
        } else {
            # child
            mdb->disconnect;
            my $chi = Baseliner::Sem->new( key=>'test', who=>"child" );
            try {
                $chi->take( wait_interval=>.1, timeout=>20 );
            } catch {
                mdb->sem_test->update({},{ '$inc'=>{ aa=>-1 } });
            };
            $chi->release;
            exit 0;
        }
        
        while(1){
            # grant if available
            my $ret = mdb->sem->update({ key=>'test', 'queue.who'=>'child' },{ '$set'=>{ 'queue.$.status'=>'cancelled' } });
            last if $ret->{updatedExisting};
        }
        sleep 2;
        mdb->sem_test->update({},{ '$inc'=>{ aa=>1 } });
        $par->release;
        
        waitpid $_, 0 for @pids;
        ok( mdb->sem_test->find_one->{aa}==0, 'cancelled doc not deleted by child' );
        my $s = mdb->sem->find_one({ key=>'test' });
        is $s->{slots}, 0, 'cancelled slots is zero at the end';
        is $s->{maxslots}, 1, 'cancelled maxslots is 1 at the end';
    }
    
    mdb->sem_test->drop();
}

done_testing();
