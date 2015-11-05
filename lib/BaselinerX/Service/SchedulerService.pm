package BaselinerX::Service::SchedulerService;
use Moose;

use POSIX ":sys_wait_h";
use Baseliner::Sem;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Model::Scheduler;
use Baseliner::Utils qw(_log);
use Clarive::mdb;

with 'Baseliner::Role::Service';

has 'config' => ( is => 'rw', isa => 'Any' );

register 'config.scheduler' => {
    metadata => [
        { id => 'frequency',  label => 'SQA send_ju Daemon Frequency', default => 60 },
        { id => 'iterations', label => 'Iteraciones del servicio',     default => 1000 }
    ]
};

register 'service.scheduler' => {
    config  => 'config.scheduler',
    icon    => '/static/images/icons/daemon.gif',
    handler => \&run,
};

register 'service.scheduler.run_once' => {
    config  => 'config.scheduler',
    icon    => '/static/images/icons/daemon.gif',
    handler => \&run_once,
};

register 'service.scheduler.test' => {
    config  => 'config.scheduler',
    icon    => '/static/images/icons/daemon.gif',
    handler => \&scheduler_test
};

sub run {
    my ( $self, $c, $config ) = @_;

    _log "Starting service.scheduler";

    my $iterations = $config->{iterations};

    for ( 1 .. $iterations ) {
        my $sem = Baseliner::Sem->new( key => 'scheduler_daemon', who => "scheduler_daemon", internal => 1 );
        $sem->take;

        $self->run_once( $c, $config );
        $self->road_kill( $c, $config );

        if ($sem) {
            $sem->release;
        }

        sleep $config->{frequency};
    }

    _log "Ending service.scheduler";
}

sub run_once {
    my ( $self, $c, $config ) = @_;

    $self->config($config);

    my $scheduler = $self->_build_scheduler;

    my @tasks = $scheduler->tasks_list( status => 'IDLE' );

    _log "Number of tasks to dispatch: " . @tasks;

    for my $task (@tasks) {

        # TODO create a job for each one, of type "internal", hide from the public view? (according
        #   to a user defined option

        my $pid = fork;

        # Parent
        if ($pid) {
        }

        # Child
        else {
            mdb->disconnect;    # mongo fork protection, will reconnect later

            $SIG{HUP}  = 'DEFAULT';
            $SIG{TERM} = 'DEFAULT';
            $SIG{STOP} = 'DEFAULT';

            _log 'Starting to work...';

            my $description = $task->{description} || $task->{name} || $task->{id};

            _log "Task '$description' started with PID $$";

            $scheduler->run_task( taskid => $task->{_id}, pid => $$ );

            _log "Task '$description' finished";

            exit 0;
        }
    }

    waitpid( -1, WNOHANG );
}

sub road_kill {
    my ( $self, $c, $config ) = @_;

    $self->config($config);

    $self->_build_scheduler->road_kill;
}

sub scheduler_test {
    my ( $self, $c, $config ) = @_;

    _log "Service.scheduler.test is now running";

    sleep 60;
    return 0;
}

sub _build_scheduler {
    my $self = shift;

    return Baseliner::Model::Scheduler->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
