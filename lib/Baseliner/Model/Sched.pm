package Baseliner::Model::Sched;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;

BEGIN { extends 'Catalyst::Model' }

sub tasks_list {
    my ( $self, %p ) = @_;

    my $status = $p{status};

    my @tasks_to_return = ();
    #Looking for tasks to run
    my $tasks = mdb->scheduler->find({ status=>mdb->in('IDLE','KILLED','RUNNOW') });
    
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

    my $rs = mdb->scheduler->find({ status=>mdb->in('RUNNING') });

    require Proc::Exists;
    
    while( my $r = $rs->next ) {
        my $pid = $r->{pid};
        next unless $pid > 0;
        _log _loc("Checking if process $pid exists");
        next if Proc::Exists::pexists( $pid );
        _log _loc("Process $pid does not exist");
        $self->set_task_data( taskid=>$r->{_id}, status=>'IDLE');
        $self->schedule_task( taskid=>$r->{_id}, when=>$self->next_from_last_schedule( taskid=>$r->{_id} ));
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
    
    my $task = mdb->scheduler->find_one({ _id=>mdb->oid($taskid) });
    my $status = $task->{status};

    _log "Running task ".$task->{description};

    $self->set_last_execution( taskid=>$taskid, when=>$self->now );
    $self->set_task_data( taskid=>$taskid, status=>'RUNNING', pid=>$pid );
    
    my $out;
    if( $task->{id_rule} =~ /^\d+$/ ) {
        # it's a rule
        my $stash = $task->{parameters} || {};
        require Capture::Tiny;
        _log "============================ SCHED RUN START ============================";
        ($out) = Capture::Tiny::tee_merged(sub{
            my $ret = Baseliner->model('Rules')->run_single_rule( 
                id_rule => $task->{id_rule},
                logging => 1,
                stash   => $stash,
                simple_error => 2,  # hide "Error Running Rule...Error DSL" even as _error
            );
        });
        _log "============================ SCHED RUN END   ============================";
        my $stash_yaml = _dump( $stash );
    } elsif( $task->{service} ) {
        # it's a service
        $out = Baseliner->launch( $task->{service}, data=>$task->{parameters} );
    } else {
        _fail _loc 'Could not find rule or service for scheduler task run `%1` (%2)', $task->{name}, $taskid;
    }
    
    # save output log
    mdb->scheduler->update({ _id=>mdb->oid($task->{_id}) },{ '$set'=>{ last_log=>substr($task->{last_log}."\n".$out,-(1024*1024*4)) } });  # 4MB max last log

    if ($task->{frequency} eq 'ONCE') {
        mdb->scheduler->update({ _id=>mdb->oid($task->{_id}) },{ '$set'=>{ next_exec=>undef } });
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

    my $up;
    $up->{status} = $status if $status;
    $up->{pid} = $pid if $pid;
    mdb->scheduler->update({ _id=>mdb->oid($taskid) },{ '$set'=>$up }) if $up;
}

sub schedule_task {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when = $p{when};

    if ( $when eq 'now') {
        mdb->scheduler->update({ _id=>mdb->oid($taskid) },{ '$set'=>{ status=>'RUNNOW' } });
        _log "Task will run now";
    } else {
        mdb->scheduler->update({ _id=>mdb->oid($taskid) },{ '$set'=>{ next_exec=>"$when" } });
        _log "New next exec is ".$when;
    }
}

sub set_last_execution {
    my ( $self, %p ) = @_;

    my $taskid = $p{taskid};
    my $when = $p{when};

    mdb->scheduler->update({ _id=>mdb->oid($taskid) },{ '$set'=>{ last_exec=>"$when" } });
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
    my $task = mdb->scheduler->find_one({ _id=>mdb->oid($taskid) });

    my $last_schedule = Class::Date->new($task->{next_exec});

    my $next_exec = $last_schedule+$task->{frequency};

    my $now = Class::Date->new($self->now);

    if ( $next_exec < $now ) {
        $next_exec = $now+$task->{frequency};
    }
    if ( $task->{workdays} ) {
        $next_exec = $self->next_workday( date => $next_exec);	
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
    
    require Proc::Exists;

    my $taskid = $p{taskid};
    my $task = mdb->scheduler->find_one({ _id=>mdb->oid($taskid) });
    
    my $pid = $task->{pid};
    _log "Killing PID $pid";

    if ( Proc::Exists::pexists( $pid ) ) {
        kill 9,$pid;
        $self->schedule_task( taskid=>$taskid, when=>$self->next_from_last_schedule( taskid=>$taskid )); 
    };

    $self->set_task_data( taskid => $taskid, status => 'KILLED');
}
1;

