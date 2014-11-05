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
package Baseliner::Sem;
use Baseliner::Mouse;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use strict;
use warnings;

has key      => qw(is rw isa Str required 1);
has sem      => qw(is rw isa Any);
has who      => qw(is rw isa Any);
has slots    => qw(is rw isa Num default 1);
has id_queue => qw(is rw isa MongoDB::OID);
has id_sem   => qw(is rw isa MongoDB::OID);
has internal => qw(is rw isa Bool default 0);
has queue_released => qw(is rw isa Bool default 1);
has disp_id => qw(is rw isa Any), default => sub{ lc( Sys::Hostname::hostname() ) };
has session => qw(is rw isa Any), default => sub{ mdb->run_command({'whatsmyuri' => 1})->{you} };

sub BUILD {
    my ($self) = @_;

    # create semaphore if it does not exist
    my $doc;
    while ( !$self->id_sem ) {
        $doc = mdb->sem->find_one({ key=>$self->key });
        my $_id;
        if( !$doc ) {
            $_id = $self->create;
            $self->id_sem( $_id ) if $_id;
        } else {
            $self->id_sem( $doc->{_id} );
        }
    }

    return $doc;
}

sub create {
    my ($self, %p) =@_;
    my $id = '';
    try {
        $id = mdb->sem->insert({
                key       => $self->key,
                internal  => ''.$self->internal,
                slots     => 0,
                active    => '1',
                maxslots  => 0+$self->slots,
                %p
            }, { safe => 1 }
        );
    } catch {
        $id = '';
    };
    return $id;
}

sub enqueue {
    my ($self) =@_;
    my ($package, $filename, $line) = caller;
    my $caller = "$package ($line)";
    # now add request to queue
    my $seq = mdb->seq( 'sem' );
    my $id_queue = mdb->oid;
    my $doc = { 
        _id        => $id_queue,
        key        => $self->key,
        who        => $self->who,
        seq        => 0+$seq, 
        ts         => Time::HiRes::time(), 
        caller     => "$package ($line)",
        active     => '1',
        pid        => $$, 
        ts_request => mdb->ts,
        hostname   => $self->disp_id,
        status     => 'waiting',
        session    => $self->session
    };

    mdb->sem->update({ key=>$self->key },{ '$push'=>{ queue=>$doc } });
    $self->id_queue( $id_queue );
}

sub take { 
    my ($self, %p) =@_;
    my ($package, $filename, $line) = caller;
    $self->queue_released(0);
    my $wait_interval = $p{wait_interval} // Clarive->config->{semaphore_wait_interval} // .5;
    $self->who("$package ($line)") unless $self->who;
    _debug('No sem'),return $self if $ENV{CLARIVE_NO_SEMS};
    my $id_queue = $self->enqueue;
    my $que;
    my $logged = 1;

    alarm $p{timeout} if length $p{timeout};
    local $SIG{ALRM} = sub{ _fail(_loc('Timeout wating for semaphore: %1s',$p{timeout})) } if length $p{timeout};
    
    # wait until the daemon grants me out
    # NO DAEMON NOW: Try to update sem document decreasing slots
    my $updated = 0;
    my $cont = 0;
    while ( !$updated ) {
        my $print_msgs = !( $cont % int(10/$wait_interval) );  # 10 seconds for every message
        _debug(_loc 'Waiting for semaphore %1 (%2)', $self->key, $self->who) if $print_msgs;
        my $maxslots = $self->maxslots; 
        # attempt to get my semaphore here:
        #my $ret = mdb->sem->find_and_modify({
        #    query=>{ key=>$self->key, slots=>{ '$lt' => 0+$maxslots }, 'queue._id'=>$self->id_queue,  },
        #    update=>{ '$inc' => { slots => 1}, '$set'=>{ 'queue.$.status'=>'busy', 'queue.$.ts_grant'=>mdb->ts } },
        #    new => 1,
        #    #fields=>{},
        #});
        #$updated = !! $ret;
        #warn _dump($ret) if $ret;
        my $res = mdb->sem->update(
            { key=>$self->key, slots=>{ '$lt' => 0+$maxslots }, 'queue._id'=>$self->id_queue },
            { '$inc' => { slots => 1}, '$set'=>{ 'queue.$.status'=>'busy', 'queue.$.ts_grant'=>mdb->ts } },
        );
        $updated = $res->{updatedExisting};
        last if $updated;
        if ( !$updated && $cont > 0 ) {
            _debug("Looking for busy queues") if $print_msgs;
            my $doc = mdb->sem->find_one({ key=>$self->key }) // {};
            my @running_queues = grep { $_->{status} eq 'busy' } _array($doc->{queue});
            if ( @running_queues ) {
                _debug("Found ".scalar @running_queues." running queues. Checking if they are alive..");
                my %active_sessions = map { $_->{client}=>1 } grep { $_->{client} } _array(mdb->db->eval('db.$cmd.sys.inprog.findOne({$all:1});')->{inprog});
                for my $qitem ( @running_queues ) {
                    if( !$active_sessions{ $qitem->{session} } ) {
                        mdb->sem->update(
                            { key => $self->key, 'queue._id'=>$qitem->{_id} },
                            { '$inc'  => { slots => -1 }, '$pull' => { queue => { _id => $qitem->{_id}, status => 'busy' } } },
                            { multiple=>1 },
                        );
                    }
                }
            }
        } elsif ( $cont == 0 ) {
            $cont++;
        }
        
        select(undef, undef, undef, $wait_interval );
        # now check for interface changes
        my $doc = mdb->sem->find_one({ 'queue._id'=>$id_queue, 'queue.status'=>mdb->in('cancelled','granted') },{ 'queue.$'=>1 });
        $que = $doc->{queue}->[0] if $doc && ref $doc->{queue};
        if ( $que && $que->{status} =~ /cancelled|granted/ ) {
            # it's something else, probably granted or cancelled thru the interface
            _debug( _loc('Status changed to %1 from outside for semaphore %2 (%3)', $que->{status}, $self->key, $self->who) );
            $self->queue_released(1);
            $updated = 1;
        }
    }
    _debug(_loc 'Granted semaphore %1 (%2)', $self->key, $self->who);

    if( $que && $que->{status} eq 'cancelled' ) {
        _fail _loc('Cancelled semaphore %1 due to status %2', $self->key, $que->{status});
    }

    alarm 0 if $p{timeout};
    return $self;
}

sub maxslots {
    my ($self)=@_;
    my $doc = mdb->sem->find_one({ key=>$self->key },{ maxslots=>1 });
    return 1 unless $doc; 
    return 0+( $doc->{maxslots} // 1 );
}

sub release { 
    my ($self, %p) =@_;
    if ( !$self->queue_released ) {
        _debug( _loc('Releasing busy semaphore %1 (%2)', $self->key,$self->who ) );
        mdb->sem->update(
            { key => $self->key, 'queue._id'=>$self->id_queue },
            { '$inc' => { slots => -1 }, '$pull' => { queue =>{ _id => $self->id_queue, status=>'busy' } } }
        );
    } else {
        _debug( _loc('Releasing granted semaphore %1 (%2)', $self->key,$self->who ) );
        mdb->sem->update(
            { key => $self->key, 'queue._id'=>$self->id_queue },
            { '$pull' => { queue => { _id => $self->id_queue, status=>'granted' } } }
        );
    }
    $self->queue_released(1);
    _debug(_loc 'Released semaphore %1 (%2)', $self->key, $self->who);
}

sub purge { 
    my ($self, %p) =@_;
    mdb->sem->update({ key=>$self->key }, { '$pull'=>{queue=>{} } });
}

sub DEMOLISH {
    my ($self)=@_;
    return if $ENV{CLARIVE_NO_SEMS};
    # release me
    $self->release;
}


1;
