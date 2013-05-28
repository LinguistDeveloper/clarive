package BaselinerX::Service::SemService;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Service';

#========== Configs 

register 'config.sem.server' => {
    metadata => [
        { id=>'frequency', default=>5 },
        { id=>'wait_for',  default=>5 },
        { id=>'host',  default=>'localhost' },
        { id=>'auto_purge',  default=>0 },
        { id=>'iterations', default=>100},
    ],
};

register 'config.sem.client' => {
    metadata => [
        { id=>'sem', default=>'dummy.semaphore' },
        { id=>'bl',  default=>'*' },
        { id=>'host',  default=>'localhost' },
        { id=>'sleep',  default=>30 },
    ],
};

#========== Services

register 'service.sem.check' => {
    config  => 'config.sem.server',
    handler => \&run_once,
};

register 'service.sem.daemon' => {
    config  => 'config.sem.server',
    handler => \&run_daemon,
};

register 'service.sem.use' => {
    config  => 'config.sem.client',
    handler => \&request,
};

register 'service.sem.list' => {
    config  => 'config.sem.client',
    handler => \&sem_list,
};

register 'service.sem.dummy_job' => {
    config  => 'config.sem.client',
    handler => \&sem_dummy_job,
};

sub request {
    my ($self, $c, $config) = @_;
    my $sm = Baseliner->model('Semaphores');
    _debug "Requested semaphore client for " . "sem=" . $config->{sem} . ", bl=" . $config->{bl};
    my $sem = $sm->request( %$config );
    _debug "Granted semaphore client for " . "sem=" . $config->{sem} . ", bl=" . $config->{bl};
    sleep $config->{sleep};
    _debug "Releasing semaphore client for " . "sem=" . $config->{sem} . ", bl=" . $config->{bl};
    $sem->release;
}

sub run_once {
    my ($self, $c, $config) = @_;

    my $sm = Baseliner->model('Semaphores');

    # cleanup killed rows
    $sm->del_roadkill if $config->{auto_purge};
    # process queue
    $sm->process_queue( %$config );
    # check for dead processes
    $sm->check_for_roadkill;
}

sub run_daemon {
    my ($self, $c, $config) = @_;
    my $freq = $config->{frequency} || 10;
    my $iterations = $config->{iterations} || 100;

    _log "Sem daemon started";
    my $iteration=0;
    my $pending=0;

    do {
        try {
            $self->run_once( $c, $config );
        } catch {
            my $err = shift;
            _debug "ERROR: $err";
        };
        sleep $freq;
        $iteration++; 
        $pending = Baseliner->model('Baseliner::BaliSemQueue')->search( { status => 'waiting', active => 1 } )->count;

    } while ( ( $iteration <=  $iterations ) || $pending gt 0 );
    _debug _now." $$ SEM ITERATION FINISHED " . $iteration . ' le ' . $iterations . ' or ' . $pending . " gt 0\n";
    _log "Sem daemon finished";
}

sub sem_list {
    my ($self, $c, $config) = @_;
    Baseliner->model('Semaphores')->list_queue;
    
}

sub dummy_job {
    my ($self, $c, $config) = @_;
    my $job = $c->stash->{job};
    my $log = $job->logger;

    $log->info( _loc('Starting dummy sleep semaphore service' ) );

    my $sm = Baseliner->model('Semaphores');
    $log->info("Requested semaphore client for " . "sem=" . $config->{sem} . ", bl=" . $config->{bl}) ;

    my $sem = $sm->request( %$config, logger=>$log, who=>$job->name );
    $log->info("Granted semaphore client for " . "sem=" . $config->{sem} . ", bl=" . $config->{bl} );

    sleep $config->{sleep};
    $log->info( "Releasing semaphore client for " . "sem=" . $config->{sem} . ", bl=" . $config->{bl} );

    $sem->release;

    $log->info( _loc('Finished dummy sleep semaphore service' ) );
}

1;
