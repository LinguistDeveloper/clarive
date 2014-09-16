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
        { id=>'wait_interval', default=>'.5'}
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
    # $self->check_for_roadkill if $check_for_roadkill;
}

sub run_daemon {
    my ($self, $c, $config) = @_;
    my $freq = $config->{frequency} // 500_000;  # milisecs
    my $iterations = $config->{iterations} || 1000;
    
    _log "Starting sem daemon with frequency '$freq'";
    # _log "Making sure the semaphore queue is Capped...";
    
    # mdb->pipe->drop;
    # mdb->create_capped('pipe');
    # mdb->pipe->find->all;
    # mdb->pipe->insert({ q=>'sem', w=>'sem-base', base=>1 });  # otherwise follow goes bezerk

    _log "Sem daemon started";
    my $iteration=1;
    my $pending=0;
    #my $hostname = Util->my_hostname;
    
    my $cr_iters = $config->{check_for_roadkill_iterations} // 1000;
    
    require Baseliner::Sem;
    do {
        my $sem = Baseliner::Sem->new( key=>'sem_daemon', who=>"sem_daemon", internal=>1 );
        $sem->take;
        try {
            $self->run_once( $c, $config, !($iteration % $cr_iters) );
        } catch {
            my $err = shift;
            _error "SEM DAEMON ERROR: $err";
        };
        $iteration++; 
        # $pending = mdb->sem_queue->find({ status => 'waiting', active=>1 })->count;
        if ( $sem ) {
            $sem->release;
        }
        sleep 100;
    } while ( ( $iteration <=  $iterations ) || $pending > 0 );

    _info "semaphore iteration finished " . $iteration . ' > ' . $iterations . ' or ' . $pending . " > 0\n";
    
    # cleanup 
}

sub check_for_roadkill {
    my ($self, %p ) = @_;
    
    _debug _loc("RUNNING sem_check_for_roadkill");
    my $rs = mdb->sem_queue->find({ status=>mdb->in('waiting', 'idle', 'granted', 'busy') });
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
            }, { multiple=>1 });
}

1;
