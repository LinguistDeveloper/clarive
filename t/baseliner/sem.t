use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }

use POSIX ":sys_wait_h";
use Try::Tiny;
use Sys::Hostname;
use Time::HiRes qw(usleep);
use Socket;
use IO::Socket;
use IO::Select;
use Baseliner::Utils qw(_error _timeout);

use_ok 'Baseliner::Sem';

subtest 'new: creates semaphore' => sub {
    _setup();

    Baseliner::Sem->new( key => 'sem' );

    my $count = mdb->sem->find->count;

    is $count, 1;
};

subtest 'new: sets id_sem' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );

    my $doc = mdb->sem->find_one;

    is $sem->id_sem, $doc->{_id};
};

subtest 'new: does not create semaphore if already exists' => sub {
    _setup();

    Baseliner::Sem->new( key => 'sem' );
    Baseliner::Sem->new( key => 'sem' );

    my $count = mdb->sem->find->count;

    is $count, 1;
};

subtest 'take: enqueues semaphore' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $doc = mdb->sem->find_one;
    cmp_deeply $doc->{queue},
      [
        {
            'active'     => '1',
            'caller'     => ignore(),
            'hostname'   => ignore(),
            '_id'        => ignore(),
            'key'        => 'sem',
            'pid'        => re(qr/^\d+$/),
            'seq'        => re(qr/^\d+$/),
            'session'    => re(qr/^\d+$/),
            'status'     => 'busy',
            'ts_grant'   => ignore(),
            'ts'         => ignore(),
            'ts_request' => ignore(),
            'who'        => ignore(),
        }
      ];

    $sem->release;
};

subtest 'take: enqueues next semaphore' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $queue;

    if ( my $pid = fork ) {
        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    last;
                }

                my $doc = mdb->sem->find_one;
                if ( @{ $doc->{queue} } == 2 ) {
                    $queue = $doc->{queue};
                    $sem->release;
                }
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        my $sem2 = Baseliner::Sem->new( key => 'sem' );
        $sem2->take( timeout => 5 );
        $sem2->release;

        mdb->disconnect;
        exit;
    }

    is @$queue, 2;
    is $queue->[0]->{pid},    $$;
    is $queue->[0]->{status}, 'busy';
    my $seq = $queue->[0]->{seq};

    is $queue->[1]->{status}, 'waiting';
    isnt $queue->[1]->{pid},  $$;
    is $queue->[1]->{seq},    $seq + 1;
};

subtest 'take: unshifts from queue on release' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $queue;

    if ( my $pid = fork ) {
        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                $sem->release;

                my $doc = mdb->sem->find_one;
                if ( @{ $doc->{queue} } == 1 && $doc->{queue}->[0]->{status} eq 'busy' ) {
                    $queue = $doc->{queue};
                    last;
                }
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        my $sem2 = Baseliner::Sem->new( key => 'sem' );
        $sem2->take( timeout => 5 );
        $sem2->release;

        mdb->disconnect;
        exit;
    }

    is @$queue, 1;
    isnt $queue->[0]->{pid},  $$;
    is $queue->[0]->{status}, 'busy';
};

subtest 'take: allows several semaphorse when maxslot' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem', slots => 2 );
    $sem->take( timeout => 5 );

    my $doc = mdb->sem->find_one;
    is $doc->{slots},    1;
    is $doc->{maxslots}, 2;

    my $sem2 = Baseliner::Sem->new( key => 'sem' );
    $sem2->take( timeout => 5 );

    $doc = mdb->sem->find_one;
    is $doc->{slots}, 2;

    is $doc->{queue}->[0]->{status}, 'busy';
    is $doc->{queue}->[1]->{status}, 'busy';

    $sem->release;
    $sem2->release;
};

subtest 'take: grants semaphore from outside' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $doc;
    if ( my $pid = fork ) {
        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                # Simulate granting from outside
                mdb->sem->update( { key => 'sem', queue => { '$elemMatch' => { status => 'waiting' } } },
                    { '$set' => { 'queue.$.status' => 'granted' } } );

                my $check = mdb->sem->find_one;
                if ( @{ $check->{queue} } == 2 && $check->{queue}->[-1]->{status} eq 'busy' ) {
                    $doc = $check;
                }

                if ( $res == -1 || $res ) {
                    last;
                }
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        my $sem2 = Baseliner::Sem->new( key => 'sem' );
        $sem2->take( timeout => 5 );
        $sem2->release;

        mdb->disconnect;
        exit;
    }

    is $doc->{slots},    1;
    is $doc->{maxslots}, 1;

    is $doc->{queue}->[0]->{status}, 'busy';

    is $doc->{queue}->[1]->{status},  'busy';
    is $doc->{queue}->[1]->{granted}, '1';

    $sem->release;
};

subtest 'take: cancels semaphore from outside' => sub {
    _setup();

    socketpair( my $child_sock, my $parent_sock, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "socketpair: $!";

    $child_sock->autoflush(1);
    $parent_sock->autoflush(1);

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $response;

    if ( my $pid = fork ) {
        close $parent_sock;

        my $s = IO::Select->new();
        $s->add($child_sock);

        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    last;
                }

                if ( my @fh = $s->can_read(0.1) ) {
                    foreach my $fh (@fh) {
                        my $rcount = sysread $fh, my $buffer, 1024;

                        if ($rcount) {
                            $response = $buffer;
                        }
                    }
                }

                mdb->sem->update( { key => 'sem', queue => { '$elemMatch' => { status => 'waiting' } } },
                    { '$set' => { 'queue.$.status' => 'cancelled' } } );
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        eval {
            my $sem2 = Baseliner::Sem->new( key => 'sem' );
            $sem2->take( timeout => 5 );
            $sem2->release;
        };

        print $parent_sock $@;

        close $child_sock;

        mdb->disconnect;
        exit;
    }

    like $response, qr/Cancelled semaphore/;

    $sem->release;
};

subtest 'take: makes sure semaphores are processed in order' => sub {
    _setup();

    socketpair( my $child_sock, my $parent_sock, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "socketpair: $!";

    $child_sock->autoflush(1);
    $parent_sock->autoflush(1);

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $response = '';

    my %pids;
    for my $seq ( 1 .. 5 ) {
        if ( my $pid = fork ) {
            $pids{$pid}++;

            _timeout 5, sub {
                while (1) {
                    my $doc = mdb->sem->find_one;

                    if ( @{ $doc->{queue} } == $seq + 1 ) {
                        last;
                    }

                    usleep(100_000);
                }
            }, 'timeout during waiting for start';
        }
        else {
            die "cannot fork: $!" unless defined $pid;

            mdb->disconnect;

            my $sem2 = Baseliner::Sem->new( key => 'sem' );
            $sem2->take( timeout => 5 );

            print $parent_sock $seq;

            $sem2->release;

            close $child_sock;

            mdb->disconnect;
            exit;
        }
    }

    $sem->release;

    close $parent_sock;

    my $s = IO::Select->new();
    $s->add($child_sock);

    _timeout 5, sub {
        while (1) {
            for my $pid ( keys %pids ) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    delete $pids{$pid};
                }
            }

            last unless keys %pids;

            if ( my @fh = $s->can_read(0.1) ) {
                foreach my $fh (@fh) {
                    my $rcount = sysread $fh, my $buffer, 1024;

                    if ($rcount) {
                        $response .= $buffer;
                    }
                }
            }
        }
    }, 'timeout during waiting for exit';

    is $response, '12345';

    $sem->release;
};

subtest 'take: removes dead busy semaphor connection' => sub {
    _setup();

    my $before;

    if ( my $pid = fork ) {
        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    last;
                }

                my $sem_doc = mdb->sem->find_one( { key => 'sem' } );
                if ( $sem_doc->{queue} && @{ $sem_doc->{queue} } >= 1 && $sem_doc->{queue}->[0]->{status} eq 'busy' ) {
                    $before = $sem_doc;

                    kill 9, $pid;
                }
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        my $sem = Baseliner::Sem->new( key => 'sem' );
        $sem->take( timeout => 5 );

        while (1) {
            usleep(100_000);
        }

        $sem->release;

        mdb->disconnect;
        exit;
    }

    is @{ $before->{queue} }, 1;
    isnt $before->{queue}->[0]->{pid}, $$;

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $sem_doc = mdb->sem->find_one( { key => 'sem' } );

    is @{ $sem_doc->{queue} }, 1;
    is $sem_doc->{queue}->[0]->{pid}, $$;
    is $sem_doc->{slots}, 1;

    $sem->release;
};

subtest 'take: removes dead waiting semaphor connection' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $before;

    if ( my $pid = fork ) {
        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    last;
                }

                my $sem_doc = mdb->sem->find_one( { key => 'sem' } );
                if ( $sem_doc->{queue} && @{ $sem_doc->{queue} } == 2 && $sem_doc->{queue}->[1]->{status} eq 'waiting' )
                {
                    $before = $sem_doc;

                    kill 9, $pid;
                }
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        my $sem = Baseliner::Sem->new( key => 'sem' );
        $sem->take( timeout => 5 );

        while (1) {
            usleep(100_000);
        }

        $sem->release;

        mdb->disconnect;
        exit;
    }

    is @{ $before->{queue} }, 2;
    is $before->{queue}->[0]->{pid},   $$;
    isnt $before->{queue}->[1]->{pid}, $$;

    $sem->release;

    my $sem2 = Baseliner::Sem->new( key => 'sem' );
    $sem2->take( timeout => 5 );

    my $sem_doc = mdb->sem->find_one( { key => 'sem' } );

    is @{ $sem_doc->{queue} }, 1;
    is $sem_doc->{queue}->[0]->{pid}, $$;
    is $sem_doc->{slots}, 1;

    $sem2->release;
};

subtest 'take: removes dead granted semaphore' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    if ( my $pid = fork ) {
        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    last;
                }

                mdb->sem->update( { key => 'sem', queue => { '$elemMatch' => { status => 'waiting' } } },
                    { '$set' => { 'queue.$.status' => 'granted' } } );

                my $sem_doc = mdb->sem->find_one;
                if ( @{ $sem_doc->{queue} } == 2 && $sem_doc->{queue}->[-1]->{status} eq 'busy' ) {
                    kill 9, $pid;
                }
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        my $sem2 = Baseliner::Sem->new( key => 'sem' );
        $sem2->take( timeout => 5 );
        $sem2->release;

        mdb->disconnect;
        exit;
    }

    $sem->release;

    my $sem2 = Baseliner::Sem->new( key => 'sem' );
    $sem2->take( timeout => 5 );

    my $sem_doc = mdb->sem->find_one;

    is $sem_doc->{slots},    1;
    is $sem_doc->{maxslots}, 1;
    is @{ $sem_doc->{queue} }, 1;

    $sem2->release;
};

subtest 'take: removes sems without queues' => sub {
    _setup();

    mdb->sem->insert( { key => 'some key1' } );
    mdb->sem->insert( { key => 'some key2', queue => undef } );
    mdb->sem->insert( { key => 'some key3', queue => [] } );

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    $sem->release;

    is( mdb->sem->count, 1 );
};

subtest 'take: throws on timeout' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $sem2 = Baseliner::Sem->new( key => 'sem' );
    my $e = exception { $sem2->take( timeout => 1 ) };

    $sem->release;

    like $e, qr/Timeout waiting for semaphore: 1s/;
};

subtest 'purge: removes sem completely' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );

    $sem->take( timeout => 5 );

    $sem->purge;

    my $sem_doc = mdb->sem->find_one;
    is_deeply $sem_doc->{queue}, [];
};

subtest 'take: takes released semaphore' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );

    $sem->take( timeout => 5 );

    ok !$sem->released;

    $sem->release;
    ok $sem->released;

    $sem->take( timeout => 5 );
    ok !$sem->released;

    $sem->release;
    ok $sem->released;
};

subtest 'release: does not release semaphore from a child' => sub {
    _setup();

    socketpair( my $child_sock, my $parent_sock, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      or die "socketpair: $!";

    $child_sock->autoflush(1);
    $parent_sock->autoflush(1);

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $is_released;

    if ( my $pid = fork ) {
        close $parent_sock;

        my $s = IO::Select->new();
        $s->add($child_sock);

        _timeout 5, sub {
            while (1) {
                my $res = waitpid( $pid, WNOHANG );

                if ( $res == -1 || $res ) {
                    last;
                }

                if ( my @fh = $s->can_read(0.1) ) {
                    foreach my $fh (@fh) {
                        my $rcount = sysread $fh, my $buffer, 1024;

                        if ($rcount) {
                            $is_released = $buffer;
                        }
                    }
                }

                mdb->sem->update( { key => 'sem', queue => { '$elemMatch' => { status => 'waiting' } } },
                    { '$set' => { 'queue.$.status' => 'cancelled' } } );
            }
        };
    }
    else {
        die "cannot fork: $!" unless defined $pid;

        mdb->disconnect;

        $sem->release;

        print $parent_sock $sem->released;

        close $child_sock;

        mdb->disconnect;
        exit;
    }

    ok !$sem->released;
    ok !$is_released;

    my $sem_doc = mdb->sem->find_one;
    is @{ $sem_doc->{queue} }, 1;
    is $sem_doc->{queue}->[0]->{status}, 'busy';

    $sem->release;
};

subtest 'DEMOLISH: releases semaphore' => sub {
    _setup();

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    undef $sem;

    my $sem_doc = mdb->sem->find_one;
    is @{ $sem_doc->{queue} }, 0;
};

subtest 'take: does nothing when CLARIVE_NO_SEMS' => sub {
    _setup();

    local $ENV{CLARIVE_NO_SEMS} = 1;

    my $sem = Baseliner::Sem->new( key => 'sem' );
    $sem->take( timeout => 5 );

    my $sem_doc = mdb->sem->find_one;
    ok !$sem_doc;
};

subtest 'simple locking' => sub {
    _setup();

    my $slotcnt  = sub { mdb->sem->find_one( { key => 'test' } )->{slots} };
    my $maxslots = sub { mdb->sem->find_one( { key => 'test' } )->{maxslots} };

    my $sem1 = Baseliner::Sem->new( key => 'test', who => "sems.t", slots => 2 );

    my $max = $maxslots->();
    is $max, 2, 'maxslots is 2 from the beginning';

    my $slots1 = $slotcnt->();
    is $slots1, 0, '0 slot before take';

    $sem1->take( timeout => 5 );

    my $slots2 = $slotcnt->();
    is $slots2, 1, '1 slot after take';

    for ( 1 .. 4 ) {
        my $semt = Baseliner::Sem->new( key => 'test', who => "sems.t" );
        $semt->take( wait_interval => .1 );
        my $slotsloop = $slotcnt->();
        is $slotsloop, 2, '2 slot after 2nd take';
    }

    my $slots3 = $slotcnt->();
    is $slots2, $slots3, 'all loop sems destroyed';

    $sem1->release;

    my $slotsf = $slotcnt->();
    is $slotsf, 0, 'all sems destroyed';

    my $max2 = $maxslots->();
    is $max2, 2, 'maxslots is 2 still';
};

subtest 'critical section' => sub {
    _setup();

    diag 'set TEST_SEM_LONG to run more tests';

    my $maxchi  = $ENV{TEST_SEM_LONG} ? 10 : 2;
    my $maxloop = $ENV{TEST_SEM_LONG} ? 50 : 5;

    mdb->sem->update( { key => 'test' }, { '$set' => { maxslots => 1 } } );
    mdb->sem_test->insert( { k => 0, tot1 => 0, tot2 => 0 } );

    my $critical = sub {
        my $who = shift;

        #warn "CHILD $who\n" ;
        my $k1 = mdb->sem_test->find_one->{k};
        $k1 == 0 ? mdb->sem_test->update( {}, { '$inc' => { tot1 => 1 } } ) : _error("$who misfired before");

        #is $k1, 0, '1 is 0 for ' . $who;
        mdb->sem_test->update( {}, { '$inc' => { k => 1 } } );
        Time::HiRes::usleep( int( 2000 * rand() ) );
        mdb->sem_test->update( {}, { '$inc' => { k => -1 } } );
        my $k2 = mdb->sem_test->find_one->{k};
        $k2 == 0 ? mdb->sem_test->update( {}, { '$inc' => { tot2 => 1 } } ) : _error("$who misfired after");

        #is $k2, 0, '2 is 0 for ' . $who;
    };

    my @pids;
    for my $n ( 1 .. $maxchi ) {
        if ( my $pid = fork ) {

            # parent
            push @pids, $pid;
        }
        else {
            # child
            mdb->disconnect;
            for ( 1 .. $maxloop ) {
                my $chi = Baseliner::Sem->new( key => 'test', who => "child_$n" );
                $chi->take( wait_interval => .1 );
                $critical->("child_$n");
                $chi->release;

                #Time::HiRes::usleep( int( 100 * rand() ) );
            }
            mdb->disconnect;
            exit 0;
        }
    }

    waitpid $_, 0 for @pids;

    my $doc = mdb->sem_test->find_one;
    is $$doc{k}, 0, 'k is zero at the end';
    is $$doc{tot1}, ( $maxchi * $maxloop ), 'all children ok before';
    is $$doc{tot2}, ( $maxchi * $maxloop ), 'all children ok after';

    my $s = mdb->sem->find_one( { key => 'test' } );
    is $s->{slots},    0, 'slots is zero at the end';
    is $s->{maxslots}, 1, 'maxslots is 1 at the end';
};

subtest 'test child death release' => sub {
    _setup();

    diag 'set TEST_SEM_LONG to run more tests';

    my $maxchi  = $ENV{TEST_SEM_LONG} ? 40   : 2;
    my $maxloop = $ENV{TEST_SEM_LONG} ? 1000 : 5;

    mdb->sem->update( { key => 'test' }, { '$set' => { maxslots => 1 } } );
    mdb->sem_test->insert( { timeouts => 0 } );

    my $critical = sub {
        my $who = shift;
        my $ran = substr( Time::HiRes::time(), -1, 1 );

        #warn "CHILD $who - $ran\n";
        Time::HiRes::usleep( int( 100 * rand() ) );
        if ( $ran == 1 ) {

            #warn "---EXIT $who\n";
            kill 9 => $$;
        }
    };

    my @pids;
    for my $n ( 1 .. $maxchi ) {
        if ( my $pid = fork ) {

            # parent
            push @pids, $pid;
        }
        else {
            # child
            mdb->disconnect;
            for ( 1 .. $maxloop ) {
                my $chi = Baseliner::Sem->new( key => 'test', who => "child_$n" );
                try {
                    $chi->take( wait_interval => .1, timeout => 20 );
                    $critical->("child_$n");
                    $chi->release;
                }
                catch {
                    mdb->sem_test->update( {}, { '$inc' => { timeouts => 1 } } );
                };
            }
            mdb->disconnect;
            exit 0;
        }
    }

    waitpid $_, 0 for @pids;

    my $doc = mdb->sem_test->find_one;
    is $$doc{timeouts}, 0, 'timeouts is zero at the end';

    my $last = Baseliner::Sem->new( key => 'test', who => "cleanup" );
    $last->take( timeout => 5 );
    $last->release;

    ok 1, 'take-release last';
    my $s = mdb->sem->find_one( { key => 'test' } );
    is $s->{slots},    0, 'slots is zero at the end';
    is $s->{maxslots}, 1, 'maxslots is 1 at the end';
};

subtest 'granted' => sub {
    _setup();

    mdb->sem->update( { key => 'test' }, { '$set' => { maxslots => 1 } } );
    mdb->sem_test->insert( { aa => 0 } );

    my @pids;
    my $par = Baseliner::Sem->new( key => 'test', who => "parent" );
    $par->take( wait_interval => .1, timeout => 20 );

    if ( my $pid = fork ) {
        push @pids, $pid;
    }
    else {
        # child
        mdb->disconnect;
        my $chi = Baseliner::Sem->new( key => 'test', who => "child" );
        $chi->take( wait_interval => .1, timeout => 20 );
        mdb->sem_test->update( { aa => 0 }, { aa => 1 } );
        $chi->release;
        mdb->disconnect;
        exit 0;
    }

    while (1) {

        # grant if available
        my $ret = mdb->sem->update( { key => 'test', 'queue.who' => 'child' },
            { '$set' => { 'queue.$.status' => 'granted' } } );
        last if $ret->{updatedExisting};
    }
    sleep 2;
    mdb->sem_test->update( { aa => 1 }, { aa => 2 } );
    $par->release;

    waitpid $_, 0 for @pids;
    ok( mdb->sem_test->find_one->{aa} == 2, 'granted doc not deleted by child' );
    my $s = mdb->sem->find_one( { key => 'test' } );
    is $s->{slots},    0, 'granted slots is zero at the end';
    is $s->{maxslots}, 1, 'granted maxslots is 1 at the end';
};

subtest 'cancelled' => sub {
    _setup();

    mdb->sem->update( { key => 'test' }, { '$set' => { maxslots => 1 } } );
    mdb->sem_test->insert( { aa => 0 } );

    my @pids;
    my $par = Baseliner::Sem->new( key => 'test', who => "parent" );
    $par->take( wait_interval => .1, timeout => 20 );

    if ( my $pid = fork ) {
        push @pids, $pid;
    }
    else {
        # child
        mdb->disconnect;
        my $chi = Baseliner::Sem->new( key => 'test', who => "child" );
        try {
            $chi->take( wait_interval => .1, timeout => 20 );
        }
        catch {
            mdb->sem_test->update( {}, { '$inc' => { aa => -1 } } );
        };
        $chi->release;
        mdb->disconnect;
        exit 0;
    }

    while (1) {

        # grant if available
        my $ret = mdb->sem->update( { key => 'test', 'queue.who' => 'child' },
            { '$set' => { 'queue.$.status' => 'cancelled' } } );
        last if $ret->{updatedExisting};
    }
    sleep 2;
    mdb->sem_test->update( {}, { '$inc' => { aa => 1 } } );
    $par->release;

    waitpid $_, 0 for @pids;

    ok( mdb->sem_test->find_one->{aa} == 0, 'cancelled doc not deleted by child' );
    my $s = mdb->sem->find_one( { key => 'test' } );
    is $s->{slots},    0, 'cancelled slots is zero at the end';
    is $s->{maxslots}, 1, 'cancelled maxslots is 1 at the end';
};

done_testing;

sub _setup {
    mdb->sem->drop;
    mdb->sem_queue->drop;
    mdb->sem_test->drop;

    mdb->index_all('sem');
    mdb->index_all('master_seq');
}
