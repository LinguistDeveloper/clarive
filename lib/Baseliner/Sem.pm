package Baseliner::Sem;
use Moose;

use Try::Tiny;
use Sys::Hostname ();
use Baseliner::Utils qw(_loc _debug _fail _array _retry);

use constant DEBUG => !!$ENV{BASELINER_SEM_DEBUG};

has key      => qw(is rw isa Str required 1);
has sem      => qw(is rw isa Any);
has who      => qw(is rw isa Any);
has slots    => qw(is rw isa Num default 1);
has seq      => qw(is rw isa Num);
has id_queue => qw(is rw isa MongoDB::OID);
has id_sem   => qw(is rw isa Maybe[MongoDB::OID]);
has internal => qw(is rw isa Bool default 0);
has released => qw(is rw isa Bool default 0);
has pid      => qw(is rw isa Any), default => sub { $$ };
has disp_id  => qw(is rw isa Any), default => sub { lc( Sys::Hostname::hostname() ) };
has
  session => qw(is rw isa Any lazy 1),
  default => sub {
    my $self = shift;

    my $myuri = mdb->run_command( { 'whatsmyuri' => 1 } )->{you};

    my $current_conection;
    my $conn = $self->_connections;
    for my $elem (@$conn) {
        $current_conection = $elem->{connectionId} if $elem->{client} && $elem->{client} eq $myuri;
        last if $current_conection;
    }

    return $current_conection;
  };

sub BUILD {
    my ($self) = @_;

    if ( $ENV{CLARIVE_NO_SEMS} ) {
        return $self;
    }

    my $doc;

    _retry sub {
        $doc = mdb->sem->find_one( { key => $self->key } );

        if ( !$doc ) {
            my $_id = $self->_create;
            $self->id_sem($_id);
        }
        else {
            $self->id_sem( $doc->{_id} );
        }
      },
      attempts => 10,
      pause    => 0.5;

    return $doc;
}

sub take {
    my $self = shift;
    my (%p) = @_;

    if ( $ENV{CLARIVE_NO_SEMS} ) {
        _debug('No sem');

        return $self;
    }

    $self->released(0);

    my $wait_interval = $p{wait_interval} // Clarive->config->{semaphore_wait_interval} // .5;

    unless ( $self->who ) {
        my ( $package, $filename, $line ) = caller;

        $self->who("$package ($line)");
    }

    $self->_lock_queue( sub { $self->_enqueue } );

    my $time = 0;

    while (1) {
        try {
            $self->_cleanup_dead_sessions;

            $self->_refresh_slots_counts;
        };

        $self->_debug_threshold( _loc( 'Waiting for semaphore %1 (%2)', $self->key, $self->who ) );

        if ( my $new_status = $self->_take_if_granted ) {
            _debug _loc( 'Status changed to %1 from outside for semaphore %2 (%3)', $new_status, $self->key,
                $self->who );

            last;
        }

        if ( my $new_status = $self->_is_cancelled ) {
            _fail _loc( 'Cancelled semaphore %1 due to status %2', $self->key, $new_status );
        }

        if ( $self->_try_to_take ) {
            _debug( _loc 'Taken semaphore %1 (%2), seq %3 from min %4', $self->key, $self->who, $self->seq, 0 );

            last;
        }

        select( undef, undef, undef, $wait_interval );

        $time += $wait_interval;

        if ( $p{timeout} && $time > $p{timeout} ) {
            _fail _loc( 'Timeout waiting for semaphore: %1s', $p{timeout} );
        }
    }

    return $self;
}

sub release {
    my ( $self, %p ) = @_;

    if ( $ENV{CLARIVE_NO_SEMS} ) {
        return $self;
    }

    return if $self->released;
    return if $self->pid != $$;    # fork protection: avoid child working on parent sems

    my $res;

    _retry sub {

        # Release normal semaphore (not granted, nor cancelled)
        $res = mdb->sem->update(
            {
                key   => $self->key,
                queue => {
                    '$elemMatch' =>
                      { _id => $self->id_queue, status => { '$ne' => 'cancelled' }, granted => { '$exists' => 0 } }
                }
            },
            { '$inc' => { slots => -1 }, '$pull' => { queue => { _id => $self->id_queue, pid => $$ } } },
            { safe   => 1 }
        );
        if ( $res->{updatedExisting} ) { _debug( _loc( 'Released semaphore %1 (%2)', $self->key, $self->who ) ); }

        warn "$self: [release] normal result=$res->{updatedExisting}\n" if DEBUG;

        return $res->{updatedExisting} if $res->{updatedExisting};

        # Release cancelled semaphore
        $res = mdb->sem->update(
            { key => $self->key, queue => { '$elemMatch' => { _id => $self->id_queue, status => 'cancelled' } } },
            { '$pull' => { queue => { _id => $self->id_queue, pid => $$ } } },
            { safe    => 1 }
        );
        if ( $res->{updatedExisting} ) {
            _debug( _loc( 'Released cancelled semaphore %1 (%2)', $self->key, $self->who ) );
        }

        warn "$self: [release] cancelled result=$res->{updatedExisting}\n" if DEBUG;

        return $res->{updatedExisting} if $res->{updatedExisting};

        # Release granted semaphore
        $res = mdb->sem->update(
            {
                key   => $self->key,
                queue => { '$elemMatch' => { _id => $self->id_queue, granted => { '$exists' => 1 } } }
            },
            { '$pull' => { queue => { _id => $self->id_queue, pid => $$ } } },
            { safe    => 1 }
        );
        if ( $res->{updatedExisting} ) {
            _debug( _loc( 'Released granted semaphore %1 (%2)', $self->key, $self->who ) );
        }

        warn "$self: [release] granted result=$res->{updatedExisting}\n" if DEBUG;

        return $res->{updatedExisting};
      },
      attempts => 10,
      pause    => 0.5;

    $self->released(1);
}

sub purge {
    my ( $self, %p ) = @_;

    mdb->sem->update( { key => $self->key }, { '$pull' => { queue => {} } }, { safe => 1 } );
}

sub _create {
    my $self = shift;

    warn "$self: [create] attempt\n" if DEBUG;

    my $id = mdb->sem->insert(
        {
            key      => $self->key,
            internal => '' . $self->internal,
            slots    => 0,
            active   => '1',
            maxslots => 0 + $self->slots,
        },
        { safe => 1 }
    );

    warn "$self: [create] OK\n" if DEBUG;

    return $id;
}

sub _enqueue {
    my $self = shift;
    my (%params) = @_;

    my ( $package, $filename, $line ) = caller;
    my $caller = "$package ($line)";

    my $seq = delete $params{seq} || 0 + mdb->seq('sem');
    $self->seq($seq);

    my $id_queue = delete $params{id_queue} || mdb->oid;

    my $doc = {
        _id        => $id_queue,
        key        => $self->key,
        who        => $self->who,
        seq        => 0 + $seq,
        ts         => 0 + sprintf( '%.5f', Time::HiRes::time() ),
        caller     => "$package ($line)",
        active     => '1',
        pid        => $$,
        ts_request => mdb->ts,
        hostname   => $self->disp_id,
        status     => 'waiting',
        session    => $self->session,
        %params
    };

    warn "$self: [enqueue] id=$id_queue seq=$seq\n" if DEBUG;

    _retry sub {
        mdb->sem->update( { key => $self->key }, { '$push' => { queue => $doc } }, { safe => 1 } );
      },
      attempts => 10,
      pause    => 0.5;

    $self->id_queue($id_queue);

    return $id_queue;
}

sub _try_to_take {
    my $self = shift;

    warn "$self: [take] attempt\n" if DEBUG;

    return $self->_lock_queue(
        sub {
            my $sem_doc = mdb->sem->find_one( { key => $self->key } );
            my ($item) = sort { $a->{seq} <=> $b->{seq} } grep { $_->{status} eq 'waiting' } @{ $sem_doc->{queue} };

            unless ( $item && $item->{seq} ) {
                warn "$self: [take] no seq found\n" if DEBUG;

                $self->_enqueue( id_queue => $self->id_queue, seq => $self->seq, recreated => 1 );

                return;
            }

            my $minseq   = $item->{seq};
            my $maxslots = $sem_doc->{maxslots};

            my $res = mdb->sem->update(
                {
                    key   => $self->key,
                    slots => { '$lt' => 0 + $maxslots },
                    queue => {
                        '$elemMatch' => {
                            _id    => $self->id_queue,
                            status => 'waiting',
                            seq    => { '$gt' => -1, '$lte' => 0 + $minseq }
                        }
                    }
                },
                { '$inc' => { slots => 1 }, '$set' => { 'queue.$.status' => 'busy', 'queue.$.ts_grant' => mdb->ts } },
                { safe   => 1 }
            );

            warn "$self: [take] result=$res->{updatedExisting}\n" if DEBUG;

            return $res->{updatedExisting};
        }
    );
}

sub _take_if_granted {
    my $self = shift;

    warn "$self: [granted] check\n" if DEBUG;

    my $granted = mdb->sem->update(
        { key => $self->key, queue => { '$elemMatch' => { _id => $self->id_queue, status => 'granted' } } },
        { '$set' => { 'queue.$.status' => 'busy', 'queue.$.ts_grant' => mdb->ts, 'queue.$.granted' => '1' } },
        { safe   => 1 }
    );

    warn "$self: [granted] result=$granted->{updatedExisting}\n" if DEBUG;

    if ( $granted && $granted->{updatedExisting} ) {
        return 'granted';
    }

    return 0;
}

sub _is_cancelled {
    my $self = shift;

    warn "$self: [cancelled] check\n" if DEBUG;

    my $doc = mdb->sem->find_one(
        { key => $self->key, queue => { '$elemMatch' => { _id => $self->id_queue, status => 'cancelled' } } },
    );

    warn "$self: [cancelled] result=" . !!$doc . "\n" if DEBUG;

    return 'cancelled' if $doc;

    return 0;
}

sub _connections {
    my $sys = mdb->db->get_collection('$cmd.sys.inprog')->find_one( { '$all' => 1 } );
    return [] unless $sys && $sys->{inprog};

    return $sys->{inprog};
}

sub _refresh_slots_counts {
    my $self = shift;

    $self->_create unless mdb->sem->find_one( { key => $self->key } );

    $self->_lock_queue(
        sub {
            my $sem_doc = mdb->sem->find_one( { key => $self->key } );
            return unless $sem_doc;

            my $real_slots = grep { $_->{status} eq 'busy' } @{ $sem_doc->{queue} };
            my $slots = $sem_doc->{slots};

            if ( $real_slots != $slots ) {
                mdb->sem->update( { key => $self->key }, { '$set' => { slots => $real_slots } } );
            }
        }
    );
}

sub _cleanup_dead_sessions {
    my $self = shift;

    my $conn = $self->_connections;
    my %active_sessions = map { ( $_->{connectionId} => 1 ) } grep { $_->{connectionId} } @$conn;

    warn "$self: [cleanup] attempt connections=" . keys(%active_sessions) . "\n" if DEBUG;

    my @sems = mdb->sem->find( { queue => { '$ne' => [] } } )->all;

    $self->_debug_threshold( "Found " . scalar(@sems) . " running queues. Checking if they are alive.." );

    foreach my $sem (@sems) {
        my @queue = _array $sem->{queue};

        my $key = $sem->{key};

        for my $item (@queue) {
            if ( !$active_sessions{ $item->{session} } ) {

                warn "$self: [cleanup] detected $item->{session}\n" if DEBUG;

                # waiting and dead? removed from queue
                mdb->sem->update(
                    {
                        key   => $key,
                        queue => {
                            '$elemMatch' => { _id => $item->{_id}, status => 'waiting', granted => { '$exists' => 0 } }
                        }
                    },
                    { '$pull'  => { queue => { _id => $item->{_id}, status => 'waiting' } } },
                    { multiple => 1 },
                );

                # busy and dead? removed from queue and slot increased
                mdb->sem->update(
                    {
                        key   => $key,
                        queue => {
                            '$elemMatch' => { _id => $item->{_id}, status => 'busy', granted => { '$exists' => 0 } }
                        }
                    },
                    {
                        '$inc'  => { slots => -1 },
                        '$pull' => { queue => { _id => $item->{_id}, status => 'busy' } }
                    },
                    { multiple => 1 },
                );

                # granted semaphores do not decrease slot
                mdb->sem->update(
                    {
                        key   => $key,
                        queue => {
                            '$elemMatch' => { _id => $item->{_id}, status => 'busy', granted => { '$exists' => 1 } }
                        }
                    },
                    { '$pull'  => { queue => { _id => $item->{_id}, status => 'busy' } } },
                    { multiple => 1 },
                );
            }
        }
    }
}

sub _lock_queue {
    my $self = shift;
    my ($cb) = @_;

    warn "$self: [queue] lock attempt\n" if DEBUG;

    my $wait_interval = 0.5;

    my $time = 0;
    while (1) {
        my $res;

        try {
            $res = mdb->sem->update( { key => $self->key }, { '$set' => { locked => 1 } }, { safe => 1 } );
        };

        last if $res->{updatedExisting};

        warn "$self: [queue] Waiting for queue to be unlocked\n" if DEBUG;

        select( undef, undef, undef, $wait_interval );
        $time += $wait_interval;

        die 'Timeout when locking queue' if $time > 5;
    }

    warn "$self: [queue] lock OK\n" if DEBUG;

    my $error;
    my $ret = try { $cb->() } catch { warn "$$ ERROR INSIDE OF LOCK: $_"; $error = $_ };

    warn "$self: [queue] unlock attempt\n" if DEBUG;

    $time = 0;
    while (1) {
        my $res;

        last unless mdb->sem->find_one( { key => $self->key } );

        try {
            $res = mdb->sem->update( { key => $self->key }, { '$set' => { locked => 0 } }, { safe => 1 } );
        };

        last if $res->{updatedExisting};

        select( undef, undef, undef, $wait_interval );

        $time += $wait_interval;
        die 'Timeout when unlocking queue' if $time > 5;
    }

    warn "$self: [queue] unlock OK\n" if DEBUG;

    die $error if $error;

    return $ret;
}

my %DEBUG_THRESHOLD;

sub _debug_threshold {
    my $self = shift;
    my ($msg) = @_;

    delete $DEBUG_THRESHOLD{$_} for grep { time - $DEBUG_THRESHOLD{$_} >= 10 } keys %DEBUG_THRESHOLD;

    if ( !exists $DEBUG_THRESHOLD{$msg} ) {
        $DEBUG_THRESHOLD{$msg} = time;

        _debug $msg;
    }
}

sub DEMOLISH {
    my ($self) = @_;

    $self->release;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 Baseliner::Sem

UNIX semaphores.

This module is useful for online semaphores, because
it won't go to the database.

The number of slots is set to 1 by default.

    my $sem = Baseliner::Sem->new( key=>'abcde' );
    $sem->take;

    # critical section here

    $sem->release;   # or on $sem destruction, it's released

Set slots:

    my $sem = Baseliner::Sem->new( key=>'abcde' );
    $sem->slots( 5 );

Possible statuses for the queue:

    - idle - created, but not requested
    - waiting - blocked waiting for granted
    - granted - master semaphore service granted request
    - busy - process has the semaphore
    - done - process released the semaphore
    - cancelled - abort semaphore
    - killed - requestor process has disappeared

=cut
