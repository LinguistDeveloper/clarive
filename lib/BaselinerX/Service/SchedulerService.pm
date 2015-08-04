package BaselinerX::Service::SchedulerService;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
has 'config' => ( is=>'rw', isa=>'Any' );

register 'config.scheduler' => {
    
    metadata => [
       { id=>'frequency', label=>'SQA send_ju Daemon Frequency', default => 60 },
       { id=>'iterations', label=>'Iteraciones del servicio', default => 1000 }
    ]
};

register 'service.scheduler' => {  config   => 'config.scheduler',  icon => '/static/images/icons/daemon.gif',  handler => \&run, }; 

sub run { # bucle de demonio aqui
    my ($self,$c, $config) = @_;
    _log "Starting service.scheduler";
    my $iterations = $config->{iterations};
    require Baseliner::Sem;
    for( 1..$iterations ) {  # bucle del servicio, se pira a cada 1000, y el dispatcher lo rearranca de nuevo
        my $sem = Baseliner::Sem->new( key=>'scheduler_daemon', who=>"scheduler_daemon", internal=>1 );
        $sem->take;
        $self->run_once($c,$config);
        $self->road_kill($c,$config);
        if ( $sem ) {
            $sem->release;
        }
        sleep $config->{frequency};
    }
    _log "Ending service.scheduler";
}

register 'service.scheduler.run_once' => {  config   => 'config.scheduler', icon => '/static/images/icons/daemon.gif',   handler => \&run_once, };


sub run_once {
    my ( $self, $c, $config ) = @_;
    $self->config( $config );
    my $pid      = '';

    my $sm = Baseliner->model('Sched');

    my @tasks = $sm->tasks_list( status => 'IDLE');    # find new schedules
    _log "Number of tasks to dispatch: " . @tasks;
    for my $task ( @tasks ) {
        
        # TODO create a job for each one, of type "internal", hide from the public view? (according
        #   to a user defined option 

        $pid = fork;   
        
        if ( $pid ) {
            # parent
            mdb->scheduler->update({ _id=>mdb->oid($task->{_id}) },{ '$set'=>{ last_pid=>$pid } });
        } else {
            # child
            mdb->disconnect;    # mongo fork protection, will reconnect later
            
            $SIG{HUP} = 'DEFAULT';
            $SIG{TERM} = 'DEFAULT';
            $SIG{STOP} = 'DEFAULT';
            _log 'Starting to work...';
            _log "Task ".$task->{description}." started with PID $$";
            
            # Run Task
            $sm->run_task( taskid => $task->{_id}, pid=>$$ );  

            _log "Task ".$task->{description}." finished";
            
            exit 0;
        }
    }
    # get rid of zombies
    BaselinerX::Service::JobDaemon->reap_children();
}

sub road_kill {
    my ( $self, $c, $config ) = @_;
    $self->config( $config );

    Baseliner->model('Sched')->road_kill; # find new schedules
}

register 'service.scheduler.test' => { config => 'config.scheduler', icon => '/static/images/icons/daemon.gif', handler => \&scheduler_test };

sub scheduler_test {
    my ( $self, $c, $config ) = @_;
    
    _log "Service.scheduler.test is now running";
    sleep 60;
    return 0;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
