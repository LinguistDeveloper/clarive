package BaselinerX::Service::SchedulerService;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
has 'config' => ( is=>'rw', isa=>'Any' );

register 'service.scheduler' => {  config   => 'config.scheduler',   handler => \&run, }; 

sub run { # bucle de demonio aqui
    my ($self,$c, $config) = @_;
    _log "Starting service.scheduler";
    my $iterations = $config->{iterations};
    for( 1..$iterations ) {  # bucle del servicio, se pira a cada 1000, y el dispatcher lo rearranca de nuevo
        $self->run_once($c,$config);
        $self->road_kill($c,$config);
        sleep $config->{frequency};
    }
    _log "Ending service.scheduler";
}

register 'service.scheduler.run_once' => {  config   => 'config.scheduler',   handler => \&run_once, };


sub run_once {
    my ( $self, $c, $config ) = @_;
    $self->config( $config );
    my $pid      = '';

    my $sm = Baseliner->model('SchedulerModel');

    my @tasks = $sm->tasks_list( status => 'IDLE');    # find new schedules
    _log "Number of tasks to dispatch: " . @tasks;
    for my $task ( @tasks ) {

        #
        $pid = fork;
        if ( $pid ) {
            BaselinerX::Job::Service::Daemon->reap_children();
            next;
        }
        $SIG{HUP} = 'DEFAULT';
        $SIG{TERM} = 'DEFAULT';
        $SIG{STOP} = 'DEFAULT';
        _log 'Starting to work...';
        _log "Task ".$task->{description}." started with PID $$";
        $sm->run_task( taskid => $task->{id}, pid=>$$ );    # run scheduled task
        _log "Task ".$task->{description}." finished";
        exit 0;
    }
}

sub road_kill {
    my ( $self, $c, $config ) = @_;
    $self->config( $config );

    my $sm = Baseliner->model('SchedulerModel');
    $sm->road_kill;    # find new schedules
}

register 'service.scheduler.test' => { config => 'config.scheduler', handler => \&scheduler_test };

sub scheduler_test {
    my ( $self, $c, $config ) = @_;
    
    _log "Service.scheduler.test is now running";
    sleep 60;
    return 0;

}

1;
