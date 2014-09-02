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

has key      => qw(is rw isa Str required 1);
has sem      => qw(is rw isa Any);
has who      => qw(is rw isa Any);
has slots    => qw(is rw isa Num default 1);
has id_queue => qw(is rw isa MongoDB::OID);
has id_sem   => qw(is rw isa MongoDB::OID);
has internal => qw(is rw isa Bool default 0);
has queue_released => qw(is rw isa Bool default 1);

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
                slots     => 0+$self->slots,
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
    my $doc = { 
        key        => $self->key,
        who        => $self->who,
        seq        => $seq, 
        ts         => Time::HiRes::time(), 
        caller     => "$package ($line)",
        active     => 1,
        pid        => $$, 
        ts_request => mdb->ts,
        hostname   => Util->my_hostname,
        status     => 'waiting',
    };

    my $id_queue = mdb->sem_queue->insert( $doc, { safe=>1 });
    $self->id_queue( $id_queue );
}

sub take { 
    my ($self, %p) =@_;
    my ($package, $filename, $line) = caller;
    $self->queue_released(0);
    my $config = config_get('config.sem.server');
    $self->who("$package ($line)") unless $self->who;
    _debug('No sem'),return $self if $ENV{CLARIVE_NO_SEMS};
    my $id_queue = $self->enqueue;
    my $que;
    my $logged = 1;
    # wait until the daemon grants me out
    # NO DAEMON NOW: Try to update sem document decreasing slots
    my $updated = 0;

    while ( !$updated ) {
        _debug(_loc 'Waiting for semaphore %1 (%2)', $self->key, $self->who);
        my $res = mdb->sem->update({ key => $self->key, slots => { '$gt' => 0 }},{ '$inc' => { slots => -1} });
        $updated = $res->{updatedExisting};
        if ( !$updated ) {
            select(undef, undef, undef, $config->{wait_interval});
        }
        $que = mdb->sem_queue->find_one({ _id=>$id_queue });
        if ($que->{status} ne 'waiting') {
            $self->queue_released(1);
            $updated = 1;
        }
    }
    _debug(_loc 'Granted semaphore %1 (%2)', $self->key, $self->who);

    if ( $que->{status} =~ /waiting|granted/ ) {    
        $que->{status} = 'busy';
        $que->{ts_grant} = mdb->ts;
        mdb->sem_queue->save( $que, { safe=>1 });
    } else {
        _fail _loc('Cancelled semaphore %1 due to status %2', $self->key, $que->{status});
    }

    return $self;
}

sub release { 
    my ($self, %p) =@_;
    if ( !$self->queue_released ) {
        my $res = mdb->sem->update({ key => $self->key },{ '$inc' => { slots => 1} });
    }
    my $que = mdb->sem_queue->find_one({ _id=>$self->id_queue });
    $que->{status} = 'done'; 
    $que->{ts_release} = mdb->ts;
    if( $que->{_id} ) {
        mdb->sem_queue->save( $que );
    }
    $self->queue_released(1);
}

sub purge { 
    my ($self, %p) =@_;
    mdb->sem_queue->remove({ key=>$self->key }, { multiple=>1 });
}

sub DEMOLISH {
    my ($self)=@_;
    return if $ENV{CLARIVE_NO_SEMS};
    # release me
    $self->release;
}


1;
