package Baseliner::Model::Semaphores;
use Moose;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Baseliner::Exception::Semaphore::Cancelled;
use Proc::Exists qw(pexists);
use Try::Tiny;

=head1 NAME

Model::Semaphores

=head1 DESCRIPTION

The main semaphore model. 

Possible statuses for the queue:

    - idle - created, but not requested
    - waiting - blocked waiting for granted
    - granted - master semaphore service granted request
    - busy - process has the semaphore
    - done - process released the semaphore
    - killed - requestor process has disappeared

Usage:

    my $sem = $c->model('Semaphores')->create( sem=>'dummy.semaphore', bl=>'TEST' );
    $sem->wait_for;
       # do stuff here....
    $sem->release;

Or, directly:

    my $sem = $c->model('Semaphores')->wait_for( sem=>'dummy.semaphore', bl=>'TEST' );
    $sem->release;

=head1 SEE ALSO

L<Baseliner::Schema::Baseliner::Result::BaliSemQueue>

=cut

has 'id' => ( is=>'rw', isa=>'Num' );
has 'logger' => ( is=>'rw', isa=>'Any' );

=head1 METHODS 

=head2 create

Creates the request queue place, but does not lock the request until later. 

=cut

sub create {
    my $self = shift;
    my $p = _parameters(@_);
    $p->{sem} or _throw 'Missing semaphore name "sem"';
    #$p->{sem} or _throw 'Missing requester sem id';
    my ($package, $filename, $line) = caller;
    my $caller = "$package ($line)";
    my $who = $p->{who} || $caller;

    my $config = Baseliner->model('ConfigStore')->get('config.sem.server', bl=>$p->{bl} || '*' );

    # create the semaphore entry
    my $sem = $self->find_or_create( $p );
    
    # now add request to queue
    my $req = Baseliner->model('Baseliner::BaliSemQueue')->create({
        caller      => "$package ($line)",
        who         => $who,
        who_id      => $p->{who_id} || '',
        id_job      => $p->{id_job},
        sem         => $p->{sem},   
        run_now     => $p->{run_now} || 0,   
        bl          => $p->{bl} || '*',    
        host        => $p->{host} || $config->{host}, 
        pid         => $$,
        status    => "waiting"
    });
    #$req->seq( $req->id );
    $req->update;

    _debug _now." $$ Creating semaphore". "\n";
    return $req;
}

=head2 request

Creates and waits for its place in the semaphore queue.

=cut

sub request {
    my $self = shift;
    my $p = _parameters(@_);
    my $frequency=$p->{frequency}||=10;
    $self->logger( $p->{logger} ) if defined $p->{logger};
    my $sem_req = $self->create( @_ );
    return $self->wait_for( id=>$sem_req->id, sem=>$sem_req->sem, frequency=>$frequency, no_wait=>$p->{no_wait} );
}

sub wait_for {
    my ($self, %p ) = @_;
    my $req = Baseliner->model('Baseliner::BaliSemQueue')->find( $p{id} );
    _throw _loc('Semaphore %1 not found', $p{sem} ) unless ref $req;
    $req->status( 'waiting' );
    $req->update;
    $req->wait_for( logger=>$self->logger, %p); #frequency=>$p{frequency} );
    return $req;
}

sub process_queue {
    my ( $self, %args ) = @_;
    my $reqs = Baseliner->model('Baseliner::BaliSemQueue')->search( { status => 'waiting', active => 1 }, { order_by => 'sem ASC, id ASC' } );
    my $sem_ant = '';
    my $sem;
    my $slots;
    my $occupied;
    my $free_slots;

    while ( my $req = $reqs->next ) {

        my $sem_txt = $req->sem;
        my $bl      = $req->bl;

        $ENV{BASELINER_DEBUG} and _log "Processing request for semaphore " . $sem_txt;

        if ( $sem_txt ne $sem_ant ) {
            $sem        = Baseliner->model('Baseliner::BaliSem')->search( { sem => $sem_txt, bl => $bl } )->first;
            $slots      = $sem->slots;
            $occupied   = $sem->occupied;
            $free_slots = $slots - $occupied;
        }

        if ( $free_slots > 0 || $sem->queue_mode eq 'free' || $sem->active == 0 ) {
            _debug _now." $$ Granted semaphore ". $req->id . " SEM: " . $req->sem . " FREE SLOTS " . $free_slots . " SLOTS " . $slots . " OCCUPIED " . $occupied . " QUEUE MODE " . $sem->queue_mode . "\n";
            $req->status('granted');
            $req->ts_grant(_now);
            $req->update;
            --$free_slots;
            $ENV{BASELINER_DEBUG} and _log $req->id . " granted";
        }
        else {
            $ENV{BASELINER_DEBUG} and _log $req->id . " not granted.  No free slots in semaphore " . $req->{sem};
        }
    }
}

sub list_queue {
    my ($self, %p ) = @_;
    my $data = $self->process_queue( show_only=>1 );
}

sub deadlock_check {
    # 1. list waiting in queue, get slot owners
    # 2. list pid for slot owners and see if pids are waiting
}

sub find_or_create
{
    my $self   = shift;
    my $p      = _parameters(@_);
    my $rs_sem = Baseliner->model('Baseliner::BaliSem');
    my $sem    = $rs_sem->search({sem => $p->{sem}, bl => $p->{bl} || '*'})->first;
    if (ref $sem)
    {
        $p->{description}
          and $sem->description($p->{description}), $sem->update;
    }
    else
    {
        try
        {
            $sem = $rs_sem->create(
                                   {
                                    sem    => $p->{sem},
                                    active => exists $p->{active} ? $p->{active} : 0,
                                    bl     => $p->{bl} || '*'
                                   }
                                  );
        }
        catch
        {
            _log _loc("Something wrong when creating the semaphore " . $p->{sem} . ".  Probably it's already there");
        };
    }
    return $sem;
}

sub cancel {
    my ($self, %p ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliSemQueue')->search(\%p);
    while( my $r = $rs->next ) {
        $r->status('cancel');
        $r->update;
    }
}

sub check_for_roadkill {
    my ($self, %p ) = @_;
    
    #TODO: Semaphores in other hosts than in BALI server
    
    $ENV{ BASELINER_DEBUG } && _log _loc("RUNNING sem_check_for_roadkill");
    my $rs = Baseliner->model('Baseliner::BaliSemQueue')->search({ status=>['waiting', 'idle', 'granted', 'busy'] });
    while( my $r = $rs->next ) {
        my $pid = $r->pid;
        #next unless $pid > 0;
        _debug _loc("Checking if process $pid exists");
        next if pexists( $pid );
        _debug _loc("Process $pid does not exist");
        _log _loc("Detected killed semaphore %1-%2", $r->sem, $r->bl);
        $r->status('killed');
        $r->update;
    }
}

sub del_roadkill {
    my ($self, %p ) = @_;
    my $rs = Baseliner->model('Baseliner::BaliSemQueue')->search({ status=>'killed' });
    while( my $r = $rs->next ) {
        $r->delete;
    }
}

sub purge {
    my ($self, %p ) = @_;
    my $statuses = $p{statuses} || ['killed', 'cancel', 'done'];
    my $rs = Baseliner->model('Baseliner::BaliSemQueue')->search({ status=>$statuses });
    while( my $r = $rs->next ) {
        $r->delete;
    }
}

1;

