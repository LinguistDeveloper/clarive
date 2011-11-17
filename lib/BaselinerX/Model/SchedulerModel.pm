#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.PROD0000054129
#	Fecha de pase .................... 2011/11/17 20:29:43
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/lib/BaselinerX/Model/SchedulerModel.pm
#	Versión del elemento ............. 0
#	Propietario de la version ........ infroox (INFROOX - RODRIGO DE OLIVEIRA GONZALEZ)

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
    my $tasks = Baseliner->model('Baseliner::BaliScheduler')->search( {status => $status, next_exec => {'!=',undef} } );

    rs_hashref($tasks);

    while ( my $task = $tasks->next ){
        _log "Evaluating task ".$task->{description};
        if ( $self->needs_execution( $task ) ) {
            my $task_to_run = {};
            for ( keys %{$task} ) {
                _log $_.":".$task->{$_};
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
		$self->set_task_data( taskid=>$rs->id, status=>'IDLE');
		$self->schedule_task( taskid=>$rs->id, when=>$self->next_from_last_schedule( taskid=>$rs->id ));
    }
}

sub needs_execution {
    my ( $self, $task ) = @_;

    use Class::Date;
	
	my $nextDate = Class::Date->new( $task->{next_exec} );
	
	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Year += 1900;
	$Month +=1;
	
	my $now= Class::Date->new([$Year,$Month,$Day,$Hour,$Minute]);
	
	_log "Next date is: $nextDate";
	_log "Now is $now";	

	return $nextDate <= $now;
}

sub run_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $pid = $p{pid};
    my $task = Baseliner->model('Baseliner::BaliScheduler')->find($taskid);

    _log "Running task ".$task->description;
    $self->set_last_execution( taskid=>$taskid, when=>$self->now );
    $self->set_task_data( taskid=>$taskid, status=>'RUNNING', pid=>$pid );
    my $out = Baseliner->launch( $task->service, data=>$task->parameters );

    if ( $task->frequency eq 'ONCE') {
    	$task->next_exec(undef);
    	$task->update;
    } else {
    	$self->schedule_task( taskid=>$taskid, when=>$self->next_from_last_schedule( taskid=>$taskid ));
    }
    $self->set_task_data( taskid=>$taskid, status=>'IDLE', pid=>0 );
}

sub set_task_data {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $status = $p{status};
    my $pid = $p{pid};

    my $task = Baseliner->model('BaliScheduler')->find($taskid);

	$task->status($status) if $status;
	$task->pid($pid) if $pid;

	$task->update;
}

sub schedule_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when = $p{when};

    my $task = Baseliner->model('BaliScheduler')->find($taskid);
    my $next_exec;

	if ( $when eq 'now') {
		$next_exec = $self->now;		
	} else {
		$next_exec = $when;
	}
    _log "New next exec is ".$next_exec;
	$task->next_exec($next_exec);
	$task->update;
}

sub set_last_execution {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when = $p{when};

    my $task = Baseliner->model('BaliScheduler')->find($taskid);

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
    my $task = Baseliner->model('BaliScheduler')->find($taskid);

	my $now = $self->now;
	my $last_schedule = Class::Date->new($task->next_exec);

	my $next_exec = $last_schedule+$task->frequency;

	if ( $next_exec < $now ) {
		$next_exec = $now+$task->frequency;
	}
	return $next_exec;
}

sub next_workday {
    my ( $self, %p ) = @_;

    my $date = $p{date};

    while ( !is_workday( date=>$date ) ) {
        $date = $date+"1D";
    }
    return $date;
}

sub is_workday {
    my ( $self, %p ) = @_;

	my @workdays = ('Monday','Tuesday','Wednesday','Thursday','Friday');

    my $date = $p{date};
    return $date->day_of_weekname ~~ @workdays;
}

1;