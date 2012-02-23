package Baseliner::Controller::Scheduler;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use JSON::XS;
use Try::Tiny;
use utf8;
use Encode;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.admin.scheduler' => { name=>'Admin Scheduler' };

register 'menu.admin.scheduler' => {
    label    => 'Scheduler',
    url_comp => '/scheduler/grid',
    actions  => [ 'action.admin.scheduler' ],
    title    => 'Scheduler',
    index    => 85,
    icon     => '/static/images/silk/clock.png'
};

sub grid : Local {
    my ( $self, $c ) = @_;
    #$c->forward('/namespace/load_namespaces');
    #$c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/scheduler_grid.js';
}

sub json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    
    $sort ||= 'name';
    $dir ||= 'asc';
    
    my $page = to_pages( start => $start, limit => $limit );
	my $where = {}; 
	my $args;
    
    $query and $where = query_sql_build(
        query  => $query,
        fields => {
            name        => 'name',
            service     => 'service',
            parameters  => 'parameters',
            next_exec   => 'next_exec',
            last_exec   => 'last_exec',
            description => 'description',
            frequency   => 'frequency',
            workdays    => 'workdays',
            status      => 'status',
            pid         => 'pid'
        }
    );

    $args = {page => $page, rows => $limit};
    $args->{order_by} = "$sort $dir";

    my $rs = $c->model('Baseliner::BaliScheduler')->search($where, $args);

    my $pager = $rs->pager;
    $cnt = $pager->total_entries;

    my @rows;
    while ( my $r = $rs->next ) {
        push @rows,
            {
            id          => $r->id,
            name        => $r->name,
            service     => $r->service,
            parameters  => $r->parameters,
            next_exec   => $r->next_exec,
            last_exec   => $r->last_exec,
            description => $r->description,
            frequency   => $r->frequency,
            workdays    => $r->workdays,
            status      => $r->status,
            pid         => $r->pid
            }
    }
    $c->stash->{json} = { data => \@rows, totalCount=>$cnt };     
    $c->forward('View::JSON');
}

sub delete_schedule : Local {
    my ( $self, $c ) = @_;
    my $user                  = $c->username;
    my $p                     = $c->request->params;

    my $id = $p->{id};

    try{
        if ( $id ) {
            my $row = $c->model('Baseliner::BaliScheduler')->find($id);
            $row->delete;
        }
        $c->stash->{json} = {msg => 'ok', success => \1};  
    } catch {
        my $err = shift;
        $c->stash->{json} = {msg => _loc( "Error deleting schedule: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );    

}

sub run_schedule : Local {
    my ( $self, $c ) = @_;
    my $user                  = $c->username;
    my $p                     = $c->request->params;

    my $id = $p->{id};

    try{
        if ( $id ) {
            BaselinerX::Model::SchedulerModel->schedule_task( taskid=>$id, when=>'now');
        }
        $c->stash->{json} = {msg => 'ok', success => \1};  
    } catch {
        my $err = shift;
        $c->stash->{json} = {msg => _loc( "Error deleting schedule: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );    

}

sub save_schedule : Local {
    my ( $self, $c ) = @_;
    my $user                  = $c->username;
    my $p                     = $c->request->params;

    _log "Ejecutando save_schedule";
    my $id = $p->{id};
    my $name = $p->{name};
    my $service = $p->{service};
    my $next_exec = $p->{date}." ".$p->{time};
    my $parameters = $p->{txt_conf};
    my $frequency = $p->{frequency};
    my $description = $p->{description};
    my $workdays = $p->{workdays} && $p->{workdays} eq 'on'?1:0;

    _log "Valor de workdays: $workdays";

    _log _dump $p;

    try{
        if ( !$id ) {
            $c->model('Baseliner::BaliScheduler')->create( { 
                name => $name, 
                service => $service,
                next_exec => $next_exec,
                parameters => $parameters,
                frequency => $frequency,
                description => $description,
                workdays => $workdays
            } );
        } else {
            my $row = $c->model('Baseliner::BaliScheduler')->find($id);
            $row->name($name); 
            $row->service($service);
            $row->next_exec($next_exec);
            $row->parameters($parameters);
            $row->frequency($frequency);
            $row->description($description);
            $row->workdays($workdays);
            $row->update;
        }

        $c->stash->{json} = {msg => 'ok', success => \1};  
    } catch {
        my $err = shift;
        $c->stash->{json} = {msg => _loc( "Error saving configuration schedule: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );    

}

sub toggle_activation : Local {
    my ( $self, $c ) = @_;
    my $p                     = $c->request->params;

    my $id = $p->{id};
    my $status = $p->{status};
    my $new_status;

    try{
        if ( $id ) {
            $new_status = BaselinerX::Model::SchedulerModel->toggle_activation( taskid=>$id, status=>$status );
        }
        $c->stash->{json} = {msg => 'Task is now '.$new_status, success => \1};  
    } catch {
        my $err = shift;
        $c->stash->{json} = {msg => _loc( "Error changing activation: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );    

}

sub kill_schedule : Local {
    my ( $self, $c ) = @_;
    my $p                     = $c->request->params;

    my $id = $p->{id};

    try{
        if ( $id ) {
            BaselinerX::Model::SchedulerModel->kill_schedule( taskid=>$id );
        }
        $c->stash->{json} = {msg => 'Task killed', success => \1};  
    } catch {
        my $err = shift;
        $c->stash->{json} = {msg => _loc( "Error killing task: %1", $err ), success => \0};
    };
    $c->forward( 'View::JSON' );    

}

sub update_conf : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my $conf = $p->{conf};
    
    my $service = Baseliner->model('Baseliner::BaliScheduler')->find( $id );
    if( ref $service ) {
	$service->parameters( $p->{conf} );
	$service->update;
	$c->stash->{json} = { success => \1, msg => _loc("Configuration changed") };
    }
    else{
	$c->stash->{json} = { success => \0, msg => _loc('Error changing the configuration') };
    }
    $c->forward('View::JSON');
}

1;
