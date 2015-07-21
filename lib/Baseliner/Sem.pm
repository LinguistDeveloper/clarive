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
has seq      => qw(is rw isa Num default), sub { 0+mdb->seq('sem') };
has id_queue => qw(is rw isa MongoDB::OID);
has id_sem   => qw(is rw isa MongoDB::OID);
has internal => qw(is rw isa Bool default 0);
has must_release => qw(is rw isa Bool default 0);
has released     => qw(is rw isa Bool default 0);
has disp_id => qw(is rw isa Any), default => sub{ lc( Sys::Hostname::hostname() ) };
has session => qw(is rw isa Any), default => sub{ 
    my $actual_conection;
    my @conn = mdb->db->get_collection( '$cmd.sys.inprog' )->find_one({'$all'=>1})->{inprog};
    for my $elem (_array @conn){
        $actual_conection = $elem->{connectionId} if $elem->{client} && $elem->{client} eq mdb->run_command({'whatsmyuri' => 1})->{you};
        last if $actual_conection;
    }
    $actual_conection;
};


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
    my $seq = $self->seq;
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
    $self->must_release(0);
    my $wait_interval = $p{wait_interval} // Clarive->config->{semaphore_wait_interval} // .5;
    $self->who("$package ($line)") unless $self->who;
    _debug('No sem'),return $self if $ENV{CLARIVE_NO_SEMS};
    my $id_queue = $self->enqueue;
    my $id_str = "$id_queue";
    my $logged = 1;

    alarm $p{timeout} if length $p{timeout};
    local $SIG{ALRM} = sub{ _fail(_loc('Timeout wating for semaphore: %1s',$p{timeout})) } if length $p{timeout};
    
    # wait until the daemon grants me out
    my $updated = 0;
    my $cont = 0;
    TAKEN: while ( !$updated ) {
        # 10 seconds for every message
        my $print_msgs = !( ($cont-1) % int(10/$wait_interval) );  
        _debug(_loc 'Waiting for semaphore %1 (%2)', $self->key, $self->who) if $cont && $print_msgs;
        
        # check the current queue 
        my $doc = mdb->sem->find_one({ key=>$self->key });
        _fail _loc('Cancelled semaphore %1 due to missing record', $self->key) unless $doc;
        my $maxslots = $doc->{maxslots} // 0;
        my $minseq;
        my (@active_queues);
        for my $que ( _array($doc->{queue}) ){
            my $s = $que->{status};
            my $qid = "$$que{_id}"; 
            push @active_queues, $que;
            if( $s eq 'waiting' ) {
                # minseq enforces that semaphores are consumed in order
                $minseq = $que->{seq} if !defined $minseq || ( $que->{seq} > -1 && $que->{seq} < $minseq );
            }
            elsif( $qid eq $id_str && $s eq 'granted' ) {
                # granted or cancelled thru the web interface
                _debug( _loc('Status changed to %1 from outside for semaphore %2 (%3)', $que->{status}, $self->key, $self->who) );
                # no slots taken, granted manually
                mdb->sem->update(
                    { key=>$self->key, queue=>{'$elemMatch'=>{ _id=>$self->id_queue } } },
                    { '$set'=>{ 'queue.$.status'=>'busy',  'queue.$.ts_grant'=>mdb->ts, 'queue.$.granted'=>'1' } }
                );
                $self->must_release(0);
                last TAKEN;
            }
            elsif( $qid eq $id_str && $s eq 'cancelled' ) {
                $self->must_release(0);
                _fail _loc('Cancelled semaphore %1 due to status %2', $self->key, $que->{status});
            }
        }
        my $res = mdb->sem->update(
            { key=>$self->key, slots=>{ '$lt' => 0+$maxslots }, queue=>{ '$elemMatch'=>{ _id=>$self->id_queue, seq=>{ '$gt'=>-1, '$lte'=>0+$minseq }}} },
            { '$inc' => { slots => 1}, '$set'=>{ 'queue.$.status'=>'busy', 'queue.$.ts_grant'=>mdb->ts } },
        );
        $updated = $res->{updatedExisting};
        if( $updated ) {
            $self->must_release(1);
            _debug(_loc 'Taken semaphore %1 (%2), seq %3 from min %4', $self->key,$self->who,$self->seq, $minseq );
            last TAKEN;
        } elsif ( $cont > 0 ) {
            if ( @active_queues ) {
                _debug("Found ".scalar @active_queues." running queues. Checking if they are alive..") if $print_msgs;
                
                my @conn = mdb->db->get_collection( '$cmd.sys.inprog' )->find_one({'$all'=>1})->{inprog};
                my %active_sessions;
                map { $active_sessions{$_->{connectionId}} = 1  if $_->{connectionId} } _array(@conn);
                
                #my %active_sessions = map { $_->{client}=>1 } grep { $_->{client} } _array(mdb->db->get_collection( '$cmd.sys.inprog' )->find_one({'$all'=>1})->{inprog});
                for my $qitem ( @active_queues ) {
                    if( !$active_sessions{ $qitem->{session} } ) {
                        if( !$qitem->{granted} ) {
                            # waiting and dead? removed from queue
                            mdb->sem->update(
                                { key => $self->key, queue=>{'$elemMatch'=>{_id=>$qitem->{_id}, status=>'waiting', granted=>{'$exists'=>0} } } },
                                { '$pull' => { queue => { _id => $qitem->{_id}, status => 'waiting' } } },
                                { multiple=>1 },
                            ) if $qitem->{status} eq 'waiting';
                            # busy and dead? removed from queue and slot increased
                            mdb->sem->update(
                                { key => $self->key, queue=>{'$elemMatch'=>{_id=>$qitem->{_id}, status=>'busy', granted=>{'$exists'=>0} } } },
                                { '$inc'  => { slots => -1 }, '$pull' => { queue => { _id => $qitem->{_id}, status => 'busy' } } },
                                { multiple=>1 },
                            ) if $qitem->{status} eq 'busy';
                        } else {
                            # granted semaphores do not decrease slot
                            mdb->sem->update(
                                { key => $self->key, queue=>{'$elemMatch'=>{_id=>$qitem->{_id},status=>'busy', granted=>{'$exists'=>1} } } },
                                { '$pull' => { queue => { _id => $qitem->{_id}, status => 'busy' } } },
                                { multiple=>1 },
                            );
                        }
                    }
                }
            }
        } elsif ( $cont == 0 ) {
            $cont++;
        }
        
        select(undef, undef, undef, $wait_interval );
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
    return if $self->released;
    if ( $self->must_release ) {

        my $res = mdb->sem->update(
            { key => $self->key, 'queue._id'=>$self->id_queue },
            { '$inc' => { slots => -1 }, '$pull' => { queue =>{ _id => $self->id_queue, status=>'busy', pid => $$ } } }
        );
        if ( $res->{updatedExisting} ) {
            _debug( _loc('Released busy semaphore %1 (%2)', $self->key,$self->who ) );
        }

    } else {
        my $res = mdb->sem->update(
            { key => $self->key , 'queue._id'=>$self->id_queue},
            { '$pull' => { queue => { _id => $self->id_queue, pid => $$ } } }
        );
        if ( $res->{updatedExisting} ) {
            _debug( _loc('Released not busy semaphore %1 (%2)', $self->key,$self->who ) );
        }
    }
    $self->must_release(0);
    $self->released(1);
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
