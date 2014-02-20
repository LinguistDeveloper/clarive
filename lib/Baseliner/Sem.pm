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

has key      => qw(is rw isa Str required 1);
has sem      => qw(is rw isa Any);
has who      => qw(is rw isa Any);
has slots    => qw(is rw isa Num default 1);
has id_queue => qw(is rw isa MongoDB::OID);
has id_sem   => qw(is rw isa MongoDB::OID);
has internal => qw(is rw isa Bool default 0); 

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
            internal  => ''.$self->internal,
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
    my ($package, $filename, $line) = caller;
    $self->who("$package ($line)") unless $self->who;
    _debug('No sem'),return $self if $ENV{CLARIVE_NO_SEMS};
    my $id_queue = $self->enqueue;
    my $freq = config_get( 'config.sem.server.wait_for' )->{wait_for} // 250_000;  # microsecs, 250ms
    my $que;
    my $logged = 0;
    # wait until the daemon grants me out
    mdb->create_capped('pipe');
    mdb->pipe->insert({ q=>'sem', id_queue=>$id_queue });
    mdb->pipe->follow( where=>{ id_queue=>$id_queue }, code=>sub{
        _debug('wating sem in take..........');
        if( !$logged ) {
            _warn( _loc 'Waiting for semaphore %1 (%2)', $self->key, $self->who );
            $logged = 1;
        }
        return 0 if $que = mdb->sem_queue->find_one({ _id=>$id_queue, status=>{ '$ne'=>'waiting' } });
        return 1;  
    });

    my $status = $que->{status};
    if( $status eq 'granted' ) {
        $que->{status} = 'busy';
        $que->{ts_grant} = mdb->ts;
        mdb->sem_queue->save( $que, { safe=>1 });
    }
    else {
        _fail _loc 'Semaphore cancelled due to status `%1`', $status;
    }
    return $self;
}

sub release { 
    my ($self, %p) =@_;
    my $que = mdb->sem_queue->find_one({ _id=>$self->id_queue });
    $que->{status} = 'done'; 
    $que->{ts_release} = mdb->ts;
    if( $que->{_id} ) {
        mdb->sem_queue->save( $que );
        mdb->pipe->insert({ q=>'sem', id_queue=>$self->id_queue });
    }
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
