package BaselinerX::Model::SchedulerModel;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);

BEGIN { extends 'Catalyst::Model' }

sub tasks_list {
    my ( $self, %p ) = @_;

    my $status = $p{status};

    my @tasks_to_return = ();
    #Looking for tasks to run
    my $tasks = Baseliner->model('Baseliner::BaliScheduler')->search( {status => ['IDLE','KILLED','RUNNOW'] } );

    rs_hashref($tasks);

    while ( my $task = $tasks->next ){
        _log "Evaluating task ".$task->{description};
        if ( $self->needs_execution( $task ) ) {
            my $task_to_run = {};
            for ( keys %{$task} ) {
                $task_to_run->{$_} = $task->{$_};
            }
            push @tasks_to_return, $task_to_run;
        }
    }
    return @tasks_to_return;
}

sub road_kill {

    my ( $self ) = @_;

    my $rs = Baseliner->model('Baseliner::BaliScheduler')->search( {status => 'RUNNING'} );

    while( my $r = $rs->next ) {
        my $pid = $r->pid;
        next unless $pid > 0;
        _log _loc("Checking if process $pid exists");
        next if pexists( $pid );
        _log _loc("Process $pid does not exist");
        $self->set_task_data( taskid=>$r->id, status=>'IDLE');
        $self->schedule_task( taskid=>$r->id, when=>$self->next_from_last_schedule( taskid=>$r->id ));
    }
}

sub needs_execution {
    my ( $self, $task ) = @_;

    use Class::Date;
    
    my $exec_now = 0;

    if ( $task->{status} eq 'RUNNOW' ) {
        $exec_now = 1;
    } else {
        my $nextDate = Class::Date->new( $task->{next_exec} );
        
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year += 1900;
        $Month +=1;
        
        my $now= Class::Date->new([$Year,$Month,$Day,$Hour,$Minute]);
        
        _log "Next date is: $nextDate";
        _log "Now is $now";			
        $exec_now = $nextDate <= $now;
    }

    return $exec_now ;
}

sub run_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $pid = $p{pid};
    my $task = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);
    my $status = $task->status;

    _log "Running task ".$task->description;

    $self->set_last_execution( taskid=>$taskid, when=>$self->now );
    $self->set_task_data( taskid=>$taskid, status=>'RUNNING', pid=>$pid );
    my $out = Baseliner->launch( $task->service, data=>$task->parameters );

    if ( $task->frequency eq 'ONCE') {
        $task->next_exec(undef);
        $task->update;
    } elsif ( $status ne 'RUNNOW') {
        $self->schedule_task( taskid=>$taskid, when=>$self->next_from_last_schedule( taskid=>$taskid ));
    }
    $self->set_task_data( taskid=>$taskid, status=>'IDLE', pid=>0 );
}

sub set_task_data {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $status = $p{status};
    my $pid = $p{pid};

    my $task = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);

    $task->status($status) if $status;
    $task->pid($pid) if $pid;

    $task->update;
}

sub schedule_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when = $p{when};

    my $task = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);

    if ( $when eq 'now') {
        $task->status( 'RUNNOW' );		
        _log "Task will run now";
    } else {
        $task->next_exec( $when );
        _log "New next exec is ".$when;
    }

    $task->update;
}

sub set_last_execution {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when = $p{when};

    my $task = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);

    $task->last_exec($when);
    $task->update;
}

sub now {
    my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
    $Year += 1900;
    $Month +=1;

    return 	Class::Date->new([$Year,$Month,$Day,$Hour,$Minute]);
}

sub next_from_now {
    
}

sub next_from_last_exec {
    
}

sub next_from_last_schedule {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $task = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);

    my $last_schedule = Class::Date->new($task->next_exec);

    my $next_exec = $last_schedule+$task->frequency;

    my $now = Class::Date->new($self->now);

    if ( $next_exec < $now ) {
        $next_exec = $now+$task->frequency;
    }
    if ( $task->{workdays} ) {
        $next_exec = next_workday( date => $next_exec);	
    }
    return $next_exec;
}

sub next_workday {
    my ( $self, %p ) = @_;

    my $date = Class::Date->new($p{date});	

    while ( !is_workday( date=>$date ) ) {
        $date = $date+"1D";
    }
    return $date;
}

sub is_workday {
    my ( $self, %p ) = @_;

    my @workdays = ('Monday','Tuesday','Wednesday','Thursday','Friday');

    my $date = Class::Date->new($p{date});
    return $date->day_of_weekname ~~ @workdays;
}

sub toggle_activation {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $status = $p{status};
    my $new_status;

    if ( $status =~ /IDLE|KILLED/ ) {
        $self->set_task_data( taskid => $taskid, status => 'INACTIVE');
        $new_status = 'inactive';
    } else {
        $new_status = 'active';
        $self->set_task_data( taskid => $taskid, status => 'IDLE');
    }
    return $new_status;
}

sub kill_schedule {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
     my $rs = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);
     my $pid = $rs->pid;

     _log "Killing PID $pid";

    if ( pexists( $pid ) ) {
        kill 9,$pid;
        $self->schedule_task( taskid=>$taskid, when=>$self->next_from_last_schedule( taskid=>$taskid )); 
    };


       $self->set_task_data( taskid => $taskid, status => 'KILLED');
}
1;
