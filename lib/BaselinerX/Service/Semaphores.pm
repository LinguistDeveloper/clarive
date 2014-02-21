package BaselinerX::Service::Semaphores;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use Proc::Exists qw(pexists);

with 'Baseliner::Role::Service';

#========== Configs 

register 'config.sem.server' => {
    metadata => [
        { id=>'host',  default=>'localhost' },
        { id=>'auto_purge',  default=>1 },
        { id=>'purge_interval',  default=>'1D' },
        { id=>'iterations', default=>1000},
        { id=>'check_for_roadkill_iterations', default=>500},
    ],
};

#========== Services

register 'service.sem.check' => {
    config  => 'config.sem.server',
    handler => \&run_once,
};

register 'service.sem.daemon' => {
    name    => 'Manage DB Semaphores',
    config  => 'config.sem.server',
    daemon  => 1,
    handler => \&run_daemon,
};

sub run_once {
    my ($self, $c, $config, $check_for_roadkill ) = @_;
    
    $check_for_roadkill //= 1;

    # cleanup killed rows, etc
    $self->cleanup( purge_interval=>$config->{purge_interval} ) if $config->{auto_purge} && $check_for_roadkill;
    # check for dead processes
    $self->check_for_roadkill if $check_for_roadkill;
    # process queue
    $self->process_queue( %$config );
}

sub run_daemon {
    my ($self, $c, $config) = @_;
    my $freq = $config->{frequency} // 500_000;  # milisecs
    my $iterations = $config->{iterations} || 1000;
    
    _log "Starting sem daemon with frequency '$freq'";
    _log "Making sure the semaphore queue is Capped...";
    
    # mdb->pipe->drop;
    mdb->create_capped('pipe');
    mdb->pipe->find->all;
    mdb->pipe->insert({ q=>'sem', w=>'sem-base', base=>1 });  # otherwise follow goes bezerk

    _log "Sem daemon started";
    my $iteration=1;
    my $pending=0;
    my $hostname = Util->my_hostname;
    
    my $cr_iters = $config->{check_for_roadkill_iterations} // 1000;
    
    do {
        mdb->pipe->follow( where=>{ q=>'sem' }, iter=>$iterations, code=>sub{
            try {
                $self->run_once( $c, $config, !($iteration % $cr_iters) );
            } catch {
                my $err = shift;
                _error "SEM DAEMON ERROR: $err";
            };
            return 1;
        });
        $iteration++; 
        $pending = mdb->sem_queue->find({ status => 'waiting', hostname=>$hostname })->count;
    } while ( ( $iteration <=  $iterations ) || $pending > 0 );

    _info "semaphore iteration finished " . $iteration . ' > ' . $iterations . ' or ' . $pending . " > 0\n";
    
    # cleanup 
    $self->cleanup( purge_interval=>$config->{purge_interval} ) if $config->{auto_purge};
}

sub process_queue {
    my ( $self, %args ) = @_;
    my $key_ant = '';
    my $sem;
    my $slots;
    my $busy;
    my $free_slots;
    
    my @sems = mdb->sem->find->all;
    for my $sem ( @sems ) {
        my $slots = $sem->{slots} // 1;
        next if $slots == 0;
        my $key = $sem->{key};
        my $busy = mdb->sem_queue->find({ key=>$key, status=>'busy' })->all;
        my $free_slots = $slots==-1 ? 1 : $slots - $busy;  # -1 = infinity
        next if $free_slots < 1;

        my @reqs = 
            mdb->sem_queue
            ->find({ key=>$key, status => 'waiting', active=>1, hostname=>Util->my_hostname })
            ->sort( Tie::IxHash->new( seq=>1, ts=>1 ) )->all; 
            
        $free_slots = @reqs if $slots == -1;  # infinity
        
        for( 1..$free_slots ) {
            my $req = shift @reqs;
            next if !ref $req;
            my $id_queue = $req->{_id};
            mdb->sem_queue->update({ _id=>$id_queue }, { '$set'=>{ status=>'granted', ts_grant=>_now() } }, { safe=>1 });
            mdb->pipe->insert({ q=>'sem', w=>'sem-grant', id_queue=>$id_queue }); 
            _log _loc 'Granted semaphore %1 to %2', $key, $req->{who};
        }
        
    }
}

sub check_for_roadkill {
    my ($self, %p ) = @_;
    
    _debug _loc("RUNNING sem_check_for_roadkill");
    my $rs = mdb->sem_queue->find({ status=>mdb->in('waiting', 'idle', 'granted', 'busy'), hostname=>Util->my_hostname });
    while( my $r = $rs->next ) {
        my $pid = $r->{pid};
        next unless $pid > 0;
        #_debug _loc("Checking if process $pid exists");
        next if pexists( $pid );
        _warn _loc("Process $pid does not exist");
        _warn _loc("Detected killed semaphore %1", $r->{key} );
        $r->{status} = 'killed';
        mdb->sem_queue->save( $r, { safe=>1 });
    }
}

sub cleanup {
    my ($self, %p ) = @_;
    my $inter = $p{purge_interval} // '1D';
    my $purge_date = ''.(Class::Date->now - $inter); 
    # roadkilled? old?
    mdb->sem_queue->remove({ 
            status=>mdb->in('cancelled','done','killed'), 
            ts_request=>{ '$lt'=>$purge_date }, 
            hostname=>Util->my_hostname }, { multiple=>1 });
}

1;
