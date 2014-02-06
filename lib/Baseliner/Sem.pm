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

has key      => qw(is rw isa Str required 1);
has sem      => qw(is rw isa Any);
has who      => qw(is rw isa Any);
has slots    => qw(is rw isa Num default 1);
has id_queue => qw(is rw isa MongoDB::OID);
has id_sem   => qw(is rw isa MongoDB::OID);

sub BUILD {
    my ($self) = @_;

    # create semaphore if it does not exist
    my $doc = mdb->sem->find_one({ key=>$self->key }); 
    my $_id;
    if( !$doc ) {
        $_id = $self->create;
    }
    $self->id_sem( $doc->{_id} // $_id );
    return $doc;
}

sub create {
    my ($self, %p) =@_;
    return mdb->sem->insert({
            key       => $self->key,
            slots     => $self->slots,
            %p
        }, { safe => 1 }
    );
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
    my $id_queue = $self->enqueue;
    my $que;
    # wait until the daemon grants me out
    while( 1 ) {
        # granted?
        last if $que = mdb->sem_queue->find_one({ _id=>$id_queue, status=>{ '$ne'=>'waiting' } });
        sleep 1;
    }
    my $status = $que->{status};
    if( $status eq 'granted' ) {
        $que->{status} = 'busy';
        $que->{ts_grant} = mdb->ts;
        mdb->sem_queue->save( $que, { safe=>1 });
    }
    else {
        _fail _loc 'Semaphore cancelled due to status %1', $status;
    }
    return $self;
}

sub release { 
    my ($self, %p) =@_;
    my $que = mdb->sem_queue->find_one({ _id=>$self->id_queue });
    $que->{status} = 'done'; 
    $que->{ts_release} = mdb->ts;
    mdb->sem_queue->save( $que, { safe=>1 } );
}

sub purge { 
    my ($self, %p) =@_;
    mdb->sem_queue->remove({ key=>$self->key }, { multiple=>1 });
}


1;
