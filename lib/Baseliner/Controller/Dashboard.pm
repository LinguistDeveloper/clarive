package Baseliner::Controller::Dashboard;
use Baseliner::PlugMouse;
use Baseliner::Utils qw(:default _load_yaml_from_comment);
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use Try::Tiny;
use Scalar::Util qw(looks_like_number);
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

register 'menu.admin.dashboard' => {
    label    => 'Dashboard',
    title    => _loc ('Admin Dashboard'),
    action   => 'action.admin.dashboard',
    url_comp => '/dashboard/grid',
    icon     => '/static/images/icons/dashboard.png',
    tab_icon => '/static/images/icons/dashboard.png'
};

register 'action.admin.dashboard' => { name=>'View and Admin dashboards' };

##Configuración del dashboard
register 'config.dashboard' => {
    metadata => [
           { id=>'job_days', label=>'Days for job statistics', default => 7 },
        ]
};

register 'config.dashlet.baselines' => {
    metadata => [
           { id=>'bl_days', label=>'Days for baseline graph', default => 7 },
           { id=>'states', label=>'States for job statistics', default => 'DESA,IT,TEST,PREP,PROD' },
           { id=>'projects', label=>'Projects for job statistics', default => 'ALL' },
        ]
};

register 'config.dashlet.lastjobs' => {
    metadata => [
           { id=>'rows', label=>'Number of rows', default => 7 },
        ]
};

register 'config.dashlet.emails' => {
    metadata => [
           { id=>'rows', label=>'Number of rows', default => 7 },
        ]
};

register 'config.dashlet.topics' => {
    metadata => [
           { id=>'rows', label=>'Number of rows', default => 7 },
        ]
};

register 'config.dashlet.jobs' => {
    metadata => [
           { id=>'rows', label=>'Number of rows', default => 7 },
        ]
};

sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $c->stash->{template} = '/comp/dashboard_grid.js';
}


sub list_dashboard : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my ($start, $limit, $query, $dir, $sort, $cnt) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $dir ||= 'desc';
    $start||= 0;
    $limit ||= 100;
    
    my $page = to_pages( start=>$start, limit=>$limit );
    
    
    my $where = $query
        ? { 'lower(name||description)' => { -like => "%".lc($query)."%" } }
        : undef;   

    #my @roles = map { $_->{id} } $c->model('Permissions')->user_roles( $c->username );
    #$where->{"dashboard_roles.id_role"} = \@roles;
    
    my $rs = $c->model('Baseliner::BaliDashboard')->search( $where,
                                                            { page => $page,
                                                              rows => $limit,
                                                              order_by => $sort ? { "-$dir" => $sort } : undef,
                                                              join => ['dashboard_roles']
                                                            }
                                                    );
    
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;		
    
    my @rows;
    while( my $r = $rs->next ) {
        # produce the grid

        my @roles = map { $_->{id_role} } $c->model('Baseliner::BaliDashboardRole')->search( {id_dashboard => $r->id})->hashref->all;
        my @dashlets = map {$_->{html} . '#' . $_->{url} } sort { $a->{order} <=> $b->{order} } _array _load $r->dashlets;
        
        push @rows,
            {
                id 			=> $r->id,
                name		=> $r->name,
                description	=> $r->description,
                is_main 	=> $r->is_main,
                is_system	=> \$r->is_system,
                type 		=> $r->is_columns eq '1' ? 'T':'O',
                roles 		=> \@roles,
                dashlets	=> \@dashlets
            };
    }
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};		
    $c->forward('View::JSON');
}

sub generic : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
}


sub list_dashlets : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my @dash_dirs = map {
        _dir( $_->root, 'dashlets' )->stringify  
    } Baseliner->features->list;
    push @dash_dirs, $c->path_to( 'root/dashlets' ) . "";
    @dash_dirs = grep { -d } @dash_dirs;
    my @dashlets = map {
        my @ret;
        my $dashlet_dir = $_;
        for my $f ( grep { -f } _dir($dashlet_dir)->children ) {
            my $d    = $f->slurp;
            my $yaml = _load_yaml_from_comment( $d );

            my $metadata = try {
                _load($yaml);
            }
            catch {
                my $err = shift;
                _error( _loc( 'Could not load metadata for dashlet %1: %2', $f, $err ) );
                {};
            };
            my @rows = map { +{ field => $_, value => $metadata->{$_} } } keys %{ $metadata || {} };
            push @ret,
                {
                file     => "$f",
                yaml     => $yaml,
                metadata => $metadata,
                rows     => \@rows,
                };
        }
        @ret;
    } @dash_dirs;
    #@dashlets;
    
    my @rows;
    my $cnt = 1;
    for my $dash ( @dashlets ) {
        push @rows,
          {
            id			=> $dash->{metadata}->{html} . '#' . ( $dash->{metadata}->{url} // $cnt++ ),
            name		=> $dash->{metadata}->{name},
            description	=> $dash->{metadata}->{description},
            config		=> $dash->{metadata}->{config}
            
          };		
    }	
    
    $c->stash->{json} = { data=>\@rows };
    $c->forward('View::JSON');
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my (@dashlets);
    
    my $i = 0;
    
    foreach my $dashlet (_array $p->{dashlets}){
        my @html_url = split(/#/, $dashlet);

        my $_dashlet = {};
        
        $_dashlet->{html}	=	$html_url[0];
        $_dashlet->{url}	=  $html_url[1];
        $_dashlet->{order}	=  ++$i;
            
        if($p->{id} != -1){
            my $dashboard = $c->model('Baseliner::BaliDashboard')->find($p->{id});
            my @config_dashlet = grep {$_->{html}=~ $html_url[0]} _array _load($dashboard->dashlets);
            if($config_dashlet[0]->{params}){
                $_dashlet->{params} = $config_dashlet[0]->{params};
            };			
        }			
            
        push @dashlets, $_dashlet;
        
    }

    given ($action) {
        when ('add') {
            try{
                my $row;
                $row = $c->model('Baseliner::BaliDashboard')->search( {name => $p->{name}} )->first;
                if(!$row){
                    my $dashboard = $c->model('Baseliner::BaliDashboard')->create(
                                    {
                                        name  => $p->{name},
                                        description => $p->{description},
                                        is_main => $p->{dashboard_main_check} ? '1': '0',
                                        is_columns => $p->{type} eq 'T' ? '1': '0',
                                        dashlets => _dump \@dashlets,
                                        
                                    });
                    
                    if ($dashboard->id){
                        foreach my $role (_array $p->{roles}){
                            my $dasboard_role = $c->model('Baseliner::BaliDashboardRole')->create(
                                                {
                                                    id_dashboard  => $dashboard->id,
                                                    id_role => $role,
                                                });
                        }
                    }
                    
                    $c->stash->{json} = { msg => _loc('Dashboard added'), success => \1, dashboard_id => $dashboard->id };
                }else{
                    $c->stash->{json} = { msg => _loc('Dashboard name already exists, introduce another dashboard'), failure => \1 };
                }
            }
            catch{
                $c->stash->{json} = { msg => _loc('Error adding dashboard: %1', shift()), failure => \1 }
            }
        }
        when ('update') {
            try{
                my $dashboard_id = $p->{id};
                my $dashboard = $c->model('Baseliner::BaliDashboard')->find( $dashboard_id );
                $dashboard ->name( $p->{name} );
                $dashboard ->description( $p->{description} );
                $dashboard ->is_main ( $p->{dashboard_main_check} ? '1': '0');
                $dashboard ->is_columns ( $p->{type} eq 'T' ? '1': '0');
                $dashboard ->dashlets( _dump \@dashlets );
                $dashboard ->update();

                $dashboard = $c->model('Baseliner::BaliDashboardRole')->search( {id_dashboard => $dashboard_id} );
                $dashboard->delete();
                
                foreach my $role (_array $p->{roles}){
                    my $dasboard_role = $c->model('Baseliner::BaliDashboardRole')->create(
                                        {
                                            id_dashboard  => $dashboard_id,
                                            id_role => $role,
                                        });
                }				
                
                
                $c->stash->{json} = { msg => _loc('Dashboard modified'), success => \1, dashboard_id => $dashboard_id };
            }
            catch{
                $c->stash->{json} = { msg => _loc('Error modifying dashboard: %1', shift()), failure => \1 };
            }
        }
        when ('delete') {
            my $dashboard_id = $p->{id};
            
            try{
                my $row = $c->model('Baseliner::BaliDashboard')->find( $dashboard_id );
                $row->delete;
                
                $row = $c->model('Baseliner::BaliDashboardRole')->search( {id_dashboard => $dashboard_id} );
                if($row){
                    $row->delete;	
                }
                
                
                $c->stash->{json} = { success => \1, msg=>_loc('Dashboard deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting dashboard') };
            }
        }
    }
    $c->forward('View::JSON');    
}


sub list : Local {
    my ($self, $c, $dashboard_name) = @_;
    my $p = $c->req->params;

    # **********************************************************************************************************
    # TODO: Hay que controlar los dashboards por perfil ********************************************************
    # **********************************************************************************************************
    
    given ($dashboard_name) {
        when ('project') {
            my $system_dashboard = $c->model('Baseliner::BaliDashboard')->search({name => 'Clarive projects'})->first();
            my @dashlets;
            my $is_columns;
            my $dashboard_id;
            
            if($system_dashboard){
                @dashlets = _array _load $system_dashboard->dashlets;
                $is_columns = $system_dashboard->is_columns;
                $dashboard_id = $system_dashboard->id;
            }
            else{
                ##Dashlets para el dashboard de proyectos.
                @dashlets = ({ html => '/dashlets/baselines.html', url => '/dashboard/list_baseline', order => 1},
                             { html => '/dashlets/lastjobs.html', url => '/dashboard/list_lastjobs', order => 2},
                            );
                $is_columns = '1';
                
                my @params = qw /projects/; #Aqui van las variables no configurables por el usuario.
                my $dashboard = $c->model('Baseliner::BaliDashboard')->create(
                                {
                                    name  => 'Clarive projects',
                                    description => 'System dashboard',
                                    dashlets => _dump (\@dashlets),
                                    is_columns => '1',
                                    is_system => '1',
                                    system_params => _dump (\@params),
                                    
                                });
                $dashboard_id = $dashboard->id;
                if ($dashboard->id){
                    my $dasboard_role = $c->model('Baseliner::BaliDashboardRole')->create(
                                        {
                                            id_dashboard  => $dashboard->id,
                                            id_role => 100, #Public
                                        });
                }
            }
    
            
            my @params;
            my %valores;
            $valores{projects} = $p->{id_project};
            push @params, 'system/' . $dashboard_id; 
            push @params, \%valores;
            
            for my $dash ( @dashlets ) {
                $c->forward( $dash->{url}, \@params );
                $c->stash->{is_columns} = $is_columns;
                $c->stash->{dashboardlets} = \@dashlets;
            }			
    
        } #End Dashboard Project
        default {
            my $dashboard_id = $p->{dashboard_id};
            my @dashlets;
            
            if ($dashboard_id){
                my $dashboard = $c->model('Baseliner::BaliDashboard')->find($dashboard_id);
                @dashlets = _array _load $dashboard->dashlets;
                for my $dash ( @dashlets ) {
                    if($dash->{url}){
                        $c->forward( $dash->{url} . '/' . $dashboard_id );
                    }
                }
                $c->stash->{is_columns} = $dashboard->is_columns;
                $c->stash->{dashboardlets} = \@dashlets;
            }else{
                my $where = {};
                my $is_root = $c->model('Permissions')->is_root( $c->username );
                if (!$is_root) {                
                    my @roles = map { $_->{id} } $c->model('Permissions')->user_roles( $c->username );
                    $where->{"dashboard_roles.id_role"} = \@roles;
                }
                $where->{"is_system"} = '0';
                
                #my $dashboard = $c->model('Baseliner::BaliDashboard')->search( {is_system=>'0'}, {order_by => 'is_main desc'} );
                my $dashboard = $c->model('Baseliner::BaliDashboard')->search( $where, {join => ['dashboard_roles'],order_by => 'is_main desc'} );
                
                if ($dashboard->count > 0){
                    my $i = 0;
                    my @dashboard;
                    my %dash;
                    while (my $dashboard = $dashboard->next){
                        if($i == 0){
                            @dashlets = _array _load $dashboard->dashlets;
                            for my $dash ( @dashlets ) {
                                if($dash->{url}){
                                    $c->forward( $dash->{url} . '/' . $dashboard->id );
                                }
                            }
                            $c->stash->{is_columns} = $dashboard->is_columns;
                            $c->stash->{dashboardlets} = \@dashlets;
                        }else{
                            $dash{$dashboard->id} = { name => $dashboard->name,
                                               id   => $dashboard->id,
                                             };
                        }
                        $i++;
                    }
                    @dashboard = values %dash;
                    $c->stash->{dashboards} = \@dashboard;
                    
                }else{
                    ##Dashboard proporcionado por clarive (default)
                    @dashlets = (	{ html => '/dashlets/baselines.html', url => '/dashboard/list_baseline', order => 1},
                                    { html => '/dashlets/lastjobs.html', url => '/dashboard/list_lastjobs', order => 2},
                                    { html => '/dashlets/topics.html', url => '/dashboard/list_topics', order => 3},
                                    { html => '/dashlets/emails.html', url => '/dashboard/list_emails', order => 4},
                                    { html => '/dashlets/jobs.html', url => '/dashboard/list_jobs', order=> 5},
#                                    { html=> '/dashlets/sqa.html', url=> '/sqa/grid_json/Dashboard', order=> 6},
                                );
                    
                    my $dashboard = $c->model('Baseliner::BaliDashboard')->search({is_system => 1, name => 'Clarive'})->first;
                    if (!$dashboard) {
                        $dashboard = $c->model('Baseliner::BaliDashboard')->create(
                                        {
                                            name  => 'Clarive',
                                            description => 'Demo dashboard Clarive configurable',
                                            dashlets => _dump (\@dashlets),
                                            is_system => '1',
                                        });
                        
                        if ($dashboard->id){
                            my $dasboard_role = $c->model('Baseliner::BaliDashboardRole')->create(
                                                {
                                                    id_dashboard  => $dashboard->id,
                                                    id_role => 100, #Public
                                                });
                        }
                    }
                    
                    for my $dash ( @dashlets ) {
                        $c->forward( $dash->{url} . '/' . $dashboard->id );
                        $c->stash->{is_columns} = $dashboard->is_columns;
                        $c->stash->{dashboardlets} = \@dashlets;
                    }	
                }
            }
        } # End default
    }	
    $c->stash->{template} = '/comp/dashboard.html';
}

sub get_config : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my @rows = ();
    my @html_url = split(/#/, $p->{id});

    if($p->{config}){
        my $default_config = $c->model('Registry')->get( $p->{config} )->metadata;
        my %dashlet_config;
        my %key_description;
        foreach my $field (_array $default_config){
            $dashlet_config{$field->{id}} = $field->{default};
            $key_description{$field->{id}} = $field->{label};
        }		
        
        my $dashboard = $c->model('Baseliner::BaliDashboard')->find($p->{dashboard_id});
        my @config_dashlet = grep {$_->{html}=~ $html_url[0]} _array _load($dashboard->dashlets);
        

        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} } ){
                $dashlet_config{$key} = $config_dashlet[0]->{params}->{$key};
            };
        }
        
        if($p->{system} eq 'true'){
            foreach my $system_id (_array _load($dashboard->system_params)){
                delete $dashlet_config{$system_id};
                delete $key_description{$system_id};
            };			
        }
        
        foreach my $key (keys %dashlet_config){
            push @rows,
                {
                    id 			=> $key,
                    dashlet		=> $html_url[0],
                    description	=> $key_description{$key},
                    value 		=> $dashlet_config{$key}
                };		
        }
    }
    
    $c->stash->{json} = { data=>\@rows};		
    $c->forward('View::JSON');	
    
}

sub set_config : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    
    my $dashboard_id = $p->{id_dashboard};
    my $dashboard_rs = $c->model('Baseliner::BaliDashboard')->find($dashboard_id);
    my $dashlet = $p->{dashlet};

    my @dashlet = grep {$_->{html}=~ $dashlet} _array _load($dashboard_rs->dashlets);
    $dashlet[0]->{params}->{$p->{id}} = $p->{value};
    
    my @dashlets = grep {$_->{html}!~ $dashlet} _array _load($dashboard_rs->dashlets);

    push @dashlets, @dashlet;
    $dashboard_rs->dashlets(_dump \@dashlets);
    $dashboard_rs->update();
    
    $c->stash->{json} = { success => \1, msg=>_loc('Configuration changed') };	
    $c->forward('View::JSON');	
    
}

sub get_config_dashlet{
    my ($parent_method, $dashboard_id, $params) = @_;
    
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.baselines');

    if($dashboard_id && looks_like_number($dashboard_id)){
        $default_config->{dashboard_id} = $dashboard_id;
        
        my $dashboard_rs = Baseliner->model('Baseliner::BaliDashboard')->find($dashboard_id);
        my @config_dashlet = grep {$_->{url}=~ $parent_method} _array _load($dashboard_rs->dashlets);
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };				
        }		
    }else{
        
        my @dashboard_system_id = split "/", $dashboard_id;		
        $default_config->{dashboard_id} = $dashboard_system_id[1];
        
        my $dashboard_rs = Baseliner->model('Baseliner::BaliDashboard')->find($dashboard_system_id[1]);
        my @config_dashlet = grep {$_->{url}=~ $parent_method} _array _load($dashboard_rs->dashlets);
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };				
        }			
        
        my %params = _array $params;
        if($params){
            foreach my $key (keys %params){
                $default_config->{$key} = $params{$key};
            };				
        }			
    }
    return $default_config;
}

sub list_baseline : Private {
    my ( $self, $c, $dashboard_id, $params ) = @_;
    my $username = $c->username;
    my ( @jobs, $job, @datas, @temps, $SQL );

    #######################################################################################################
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $config = get_config_dashlet( 'list_baseline', $dashboard_id, $params );
    ##########################################################################################################
    $c->stash->{dashboard_id} = $config->{dashboard_id};

    my $bl_days = $config->{bl_days};

    #Cojemos los proyectos que el usuario tiene permiso para ver jobs
    my @ids_project = $c->model( 'Permissions' )->user_projects_ids(
        username => $c->username
    );
    my $ids;
    $c->stash->{projects} = $config->{projects};

    # my $is_root = $c->model('Permissions')->is_root( $c->username );

    #if (!$is_root) {  
        if ( $config->{projects} ne 'ALL' ) {
            $ids = 'MID=' . join( '', grep { $_ =~ $config->{projects} } grep { length }  @ids_project ). ' AND' if grep { length } @ids_project;

        } else {
            $ids = 'MID=' . join( ' OR MID=', grep { length } @ids_project ). ' AND' if grep { length } @ids_project;
        }
    #} else {
    #    $ids = '';
    #}

    if ( @ids_project ) {

        my $date = Class::Date->now();
        my $days = $bl_days.'D';
        $date = $date - $days;
        my $date_str = $date->ymd;
        $date_str  =~ s/\//\-/g;


        my @jobs_ok = _array(mdb->master_doc->aggregate([
            { '$match' => { 'collection' => 'job', 'status' => 'FINISHED', 'endtime' => {'$gte' => ''.$date_str} } },
            { '$group' => { _id => '$bl', 'result' => {'$max' => 'OK'} , 'tot' => {'$sum' => 1} } }
        ]));

        my @jobs_ko = _array(mdb->master_doc->aggregate([
            { '$match' => { 'collection' => 'job', 'status' => mdb->in( ('ERROR','CANCELLED','KILLED','REJECTED') ), 'endtime' => {'$gte' => ''.$date_str} } },
            { '$group' => { _id => '$bl', 'result' => {'$max' => 'ERROR'} , 'tot' => {'$sum' => 1} } }
        ])); 

        @jobs = ( @jobs_ok, @jobs_ko );

        #my @entornos = ('TEST', 'PREP', 'PROD');
        my $states = $config->{states};
        my @entornos = split ",", $states;

        foreach my $entorno ( @entornos ) {
            my ( $totError, $totOk, $total, $porcentError, $porcentOk, $bl ) = ( 0, 0, 0, 0, 0);
            @temps = grep { $_->{_id} eq $entorno } @jobs;
            foreach my $temp ( @temps ) {
                $bl = $temp->{_id};
                if ( $temp->{result} eq 'OK' ) {
                    $totOk = $temp->{tot};
                } else {
                    $totError = $temp->{tot};
                }
            } ## end foreach my $temp ( @temps )
            $total = $totOk + $totError;
            if ( $total ) {
                $porcentOk    = $totOk * 100 / $total;
                $porcentError = $totError * 100 / $total;
            } else {
                $bl           = $entorno;
                $totOk        = '';
                $totError     = '';
                $porcentOk    = 0;
                $porcentError = 0;
            } ## end else [ if ( $total ) ]
            push @datas,
                {
                bl           => $bl,
                porcentOk    => $porcentOk,
                totOk        => $totOk,
                total        => $total,
                totError     => $totError,
                porcentError => $porcentError
                };
        } ## end foreach my $entorno ( @entornos)
    } ## end if ( $ids_project )
    $c->stash->{entornos} = \@datas;
} ## end sub list_baseline:


sub list_lastjobs: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $perm = Baseliner->model('Permissions');
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.lastjobs');	
    my @mid_filters = ();
    my $limit = $default_config->{rows} // 10;
    my $username = $c->username;

    if( !$perm->is_root($username) ) {
            @mid_filters = $perm->user_projects_with_action(username => $username,
                                                                action => 'action.job.viewall',
                                                                level => 1);
            
    }

    my $where = {};
    $where->{'projects.mid'} = mdb->in(@mid_filters) if @mid_filters;
    $where->{collection} = 'job';
    my @rs_search = mdb->master_doc->find( $where )->sort({ starttime => -1 })->all;

    my $numrow = 0;
    my @lastjobs;
    
    #######################################################################################################
    #CONFIGURATION DASHLET
    ##########################################################################################################
    
    if($dashboard_id && looks_like_number($dashboard_id)){
        my $dashboard_rs = $c->model('Baseliner::BaliDashboard')->find($dashboard_id);
        my @config_dashlet = grep {$_->{url}=~ 'list_lastjobs'} _array _load($dashboard_rs->dashlets);
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };				
        }		
    }	
    ##########################################################################################################

    for my $doc ( @rs_search ) {
        last if $numrow > $limit;
        try {
            my $job = ci->new( $doc->{mid} );
            push @lastjobs,
                {
                mid       => $job->mid,
                name      => $job->name,
                type      => $job->job_type,
                rollback  => $job->rollback,
                status    => $job->status,
                starttime => $job->starttime,
                endtime   => $job->endtime
                };
            $numrow++;
        } catch {
            _log "FAILURE Searching job ".$doc->{mid}.": " . shift;
        };
    }
    $c->stash->{lastjobs} =\@lastjobs;
}

sub list_emails: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    my @datas;
    
    
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.emails');	
    
    if($dashboard_id && looks_like_number($dashboard_id)){
        my $dashboard_rs = $c->model('Baseliner::BaliDashboard')->find($dashboard_id);
        my @config_dashlet = grep {$_->{url}=~ 'list_emails'} _array _load($dashboard_rs->dashlets);
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} } ){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };				
        }		
    }	
    ##########################################################################################################	
    
    my $rows = $default_config->{rows};
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $SQL = "SELECT SUBJECT, SENDER, B.SENT, ID
                FROM BALI_MESSAGE A,
                    (SELECT * FROM ( SELECT ID_MESSAGE,  SENT
                                        FROM BALI_MESSAGE_QUEUE
                                        WHERE USERNAME = ? AND SWREADED = 0
                                        ORDER BY SENT DESC ) WHERE ROWNUM <= ?) B
                WHERE A.ID = B.ID_MESSAGE";
                

    my @emails = $db->array_hash( $SQL , $username, $rows);
    foreach my $email (@emails){
        push @datas, $email;
    }	
        
    $c->stash->{emails} =\@datas;
}

sub list_topics: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    #my (@topics, $topic, @datas, $SQL);
    
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.topics');	
    
    if($dashboard_id && looks_like_number($dashboard_id)){
        my $dashboard_rs = $c->model('Baseliner::BaliDashboard')->find($dashboard_id);
        my @config_dashlet = grep {$_->{url}=~ 'list_topics'} _array _load($dashboard_rs->dashlets);
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };				
        }		
    }	
    ##########################################################################################################		
    
    # go to the controller for the list
    my $p = { limit => $default_config->{rows}, username=>$c->username };
    my ($cnt, @rows) = $c->model('Topic')->topics_for_user( $p );
    $c->stash->{topics} = \@rows ;
}

sub list_jobs : Private {
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    my @datas;
    my $SQL;
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );

    #Cojemos los proyectos que el usuario tiene permiso para ver jobs
   #Cojemos los proyectos que el usuario tiene permiso para ver jobs
    my @ids_project = $c->model( 'Permissions' )->user_projects_ids(
        username => $c->username
    );
    
    if ( @ids_project ) {

        #CONFIGURATION DASHLET
        ##########################################################################################################
        my $default_config = Baseliner->model( 'ConfigStore' )->get( 'config.dashlet.jobs' );

        if ( $dashboard_id && looks_like_number( $dashboard_id ) ) {
            my $dashboard_rs = $c->model( 'Baseliner::BaliDashboard' )->find( $dashboard_id );
            my @config_dashlet =
                grep { $_->{url} =~ 'list_jobs' } _array _load( $dashboard_rs->dashlets );

            if ( $config_dashlet[ 0 ]->{params} ) {
                foreach my $key ( keys %{$config_dashlet[ 0 ]->{params} || {}} ) {
                    $default_config->{$key} = $config_dashlet[ 0 ]->{params}->{$key};
                }
            }
        } ## end if ( $dashboard_id && ...)
        ##########################################################################################################

        my $rows = $default_config->{rows};
        
        my %jobs = map { $_->{mid} => $_ } ci->job->find
             ->fields({ mid=>1, starttime=>1, endtime=>1, projects=>1, bl=>1, status=>1, jobid=>1 })->all; #{ endtime=>{ '$gt'=>'2013-11-31 00:00' } })->all;
        my %projects = map { $_->{mid} => $_ } ci->project->find({ mid=>mdb->in(@ids_project) })->all;
        my %rep;
        my $now = _ts();
        # for all jobs
        for my $job ( values %jobs ) {
            my $bl = $job->{bl};
            my $endt = Class::Date->new($job->{endtime});
            my $days = int( ($now - $endt)->day );
            my $status = $job->{status};
            my $type = $status =~ /ERROR|KILLED/ ? 'err' 
                : $status=~/CANCELLED|APPROVAL|PAUSED|REJECTED/ ? next : 'ok';
            # for project in job
            for my $prj ( _array( $job->{projects} ) ) {
                my $name = $projects{$prj}->{name};
                next unless $name;
                my $r = $rep{ $name }{$bl} //= {};
                # last error by type
                if( !defined $r->{"last_$type"} || $days < $r->{"last_$type"} ) {
                    $r->{"last_$type"} = $days;
                    $r->{"id_$type"} = $job->{jobid};
                    $r->{"mid_$type"} = $job->{mid};
                    $r->{"name_$type"} = $job->{name};
                    $r->{status} = $status;
                }
                # last durantion and top mid
                if( !defined $r->{top_mid} || $job->{mid} > $r->{top_mid} ) {  
                    my $secs = ($endt-Class::Date->new($job->{starttime}))->second;
                    $r->{last_duration} = sprintf '%dm%ds', int($secs/60), ($secs % 60);
                    $r->{top_mid} = $job->{mid};
                }
            }
        }
        
        # now create something we can send to the template
        @datas = sort {
            #$a->{project}.'#'.$a->{bl} cmp $b->{project}.'#'.$b->{bl}; 
            $b->{top_mid} <=> $a->{top_mid}
        } map {
            my $prj = $_;
            my $bls = $rep{$prj};
            my @rows;
            for my $bl ( keys $bls ) {
                my $r = $bls->{$bl};
                push @rows, { project=>$prj, bl=>$bl, %$r };
            }
            @rows;
        } keys %rep;
        
        @datas = @datas[0..$rows] if $rows < @datas;  # cut to top rows per config

    } ## end if ( @ids_project )
    $c->stash->{jobs} = \@datas;
} 


sub viewjobs : Local {
    my ( $self, $c, $dashboard_id, $projects, $type, $bl ) = @_;
    my $p = $c->request->parameters;

    my $config = get_config_dashlet('list_baseline', $dashboard_id);
    $config->{projects} = $projects;

    #Cojemos los proyectos que el usuario tiene permiso para ver jobs
    my @ids_project = $c->model( 'Permissions' )->user_projects_with_action(username => $c->username,
                                                                            action => 'action.job.viewall',
                                                                            level => 1);
    
    #Filtramos por la parametrización cuando no son todos
    if($config->{projects} ne 'ALL'){
        @ids_project = grep {$_ =~ $config->{projects}} @ids_project;
    }
    
    my $states    = $config->{states};
    my @baselines = split ",", $states;
    
    
    my @jobs;
    
    if($type){
        my @status;
        given ($type) {
            when ('ok') {
                @status = ('FINISHED');
            }
            when ('nook'){
                @status = ('ERROR','CANCELLED','KILLED');
            }
        }
        
        my $days = ( $config->{bl_days} // 7 ) . 'D';
        my $start = mdb->now - $days; 
        @jobs = ci->job->find({ endtime => { '$gt' => "$start" }, status=>mdb->in(@status), bl=>$bl })->all;
        
    }else{
        @jobs = ci->job->find({ status=>'RUNNING', bl=>mdb->in(@baselines) })->all;
    }
    
    #my $jobsid = join(',', map {$_->{id_job}} @jobs);

    $c->stash->{jobs} = @jobs ? join(',', map {$_->{mid}} @jobs) : -1;
    $c->forward('/job/monitor/Dashboard');
}

sub topics_by_category: Local{
    my ( $self, $c, $action ) = @_;
    #my $p = $c->request->parameters;
    my (@topics_by_category, @datas);


    my $where = {};
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
                $_->{id};
            } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    $where->{'category.id'} = mdb->in(@user_categories);

    if( $username && ! $perm->is_root( $username )){
            my @proj_coll_roles = Baseliner->model('Permissions')->user_projects_ids_with_collection(username=>$username);
            my @ors;
            for my $proj_coll_ids ( @proj_coll_roles ) {
                my $wh = {};
                my $count = scalar keys %{ $proj_coll_ids || {} };
                while ( my ( $k, $v ) = each %{ $proj_coll_ids || {} } ) {
                    if ( $k eq 'project' && $count gt 1) {
                        $wh->{"_project_security.$k"} = {'$in' => [ undef, keys %{$v || {}} ]};
                    } else {
                        $wh->{"_project_security.$k"} = {'$in' => [ keys %{$v || {}} ]};
                    }
                } ## end while ( my ( $k, $v ) = each...)
                push @ors, $wh;
            }
            my $where_undef = { '_project_security' => undef };
            push @ors, $where_undef;
            $where->{'$or'} = \@ors;
        }

    @topics_by_category = _array (mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { _id => '$category.id', 'category' => {'$max' => '$category.name'},'color' => {'$max' => '$category.color'}, 'total' => { '$sum' => 1 }} },
        { '$sort' => { total => -1}}
    ]));
    
    foreach my $topic (@topics_by_category){
        push @datas, {
                    total           => $topic->{total},
                    category        => $topic->{category},
                    color           => $topic->{color},
                    category_id     => $topic->{_id}
                };
     }
    $c->stash->{topics_by_category} = \@datas;
    $c->stash->{topics_by_category_title} = _loc('Topics by category');

}

sub topics_open_by_category: Local{
    my ( $self, $c, $action ) = @_;
    #my $p = $c->request->parameters;
    my ($SQL, @topics_open_by_category, @datas);


    my $where = {};
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
                $_->{id};
            } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    $where->{'category.id'} = mdb->in(@user_categories);
    $where->{'category_status.type'} = mdb->nin(('F','FC'));

    if( $username && ! $perm->is_root( $username )){
            my @proj_coll_roles = Baseliner->model('Permissions')->user_projects_ids_with_collection(username=>$username);
            my @ors;
            for my $proj_coll_ids ( @proj_coll_roles ) {
                my $wh = {};
                my $count = scalar keys %{ $proj_coll_ids || {} };
                while ( my ( $k, $v ) = each %{ $proj_coll_ids || {} } ) {
                    if ( $k eq 'project' && $count gt 1) {
                        $wh->{"_project_security.$k"} = {'$in' => [ undef, keys %{$v || {}} ]};
                    } else {
                        $wh->{"_project_security.$k"} = {'$in' => [ keys %{$v || {}} ]};
                    }
                } ## end while ( my ( $k, $v ) = each...)
                push @ors, $wh;
            }
            my $where_undef = { '_project_security' => undef };
            push @ors, $where_undef;
            $where->{'$or'} = \@ors;
        }

    @topics_open_by_category = _array (mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { _id => '$category.id', 'category' => {'$max' => '$category.name'},'color' => {'$max' => '$category.color'}, 'total' => { '$sum' => 1 }} },
        { '$sort' => { total => -1}}
    ]));
    
    foreach my $topic (@topics_open_by_category){
        push @datas, {
                    total 			=> $topic->{total},
                    category		=> $topic->{category},
                    color			=> $topic->{color},
                    category_id		=> $topic->{_id}
                };
     }
    $c->stash->{topics_open_by_category} = \@datas;
    $c->stash->{topics_open_by_category_title} = _loc('Topics open by category');

}

sub topics_by_status: Local{
    my ( $self, $c, $action ) = @_;
    #my $p = $c->request->parameters;
    my (@topics_by_status, @datas);

    my $where = {};
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
                $_->{id};
            } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    $where->{'category.id'} = mdb->in(@user_categories);

    if( $username && ! $perm->is_root( $username )){
            my @proj_coll_roles = Baseliner->model('Permissions')->user_projects_ids_with_collection(username=>$username);
            my @ors;
            for my $proj_coll_ids ( @proj_coll_roles ) {
                my $wh = {};
                my $count = scalar keys %{ $proj_coll_ids || {} };
                while ( my ( $k, $v ) = each %{ $proj_coll_ids || {} } ) {
                    if ( $k eq 'project' && $count gt 1) {
                        $wh->{"_project_security.$k"} = {'$in' => [ undef, keys %{$v || {}} ]};
                    } else {
                        $wh->{"_project_security.$k"} = {'$in' => [ keys %{$v || {}} ]};
                    }
                } ## end while ( my ( $k, $v ) = each...)                push @ors, $wh;
            }
            my $where_undef = { '_project_security' => undef };
            push @ors, $where_undef;
            $where->{'$or'} = \@ors;
        }

    @topics_by_status = _array(mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { _id => '$category_status.id', 'status' => {'$max' => '$category_status.name'},'color' => {'$max' => '$category_status.color'}, 'total' => { '$sum' => 1 }} },
        { '$sort' => { total => -1}}
    ]));
    
    foreach my $topic (@topics_by_status){
        push @datas, {
                    total         => $topic->{total},
                    status        => $topic->{status},
                    color		  => $topic->{color},
                    status_id     => $topic->{_id}
                };
     }
    $c->stash->{topics_by_status} = \@datas;
    $c->stash->{topics_by_status_title} = _loc('Topics by status');

}

sub topics_open_by_status: Local{
    my ( $self, $c, $action ) = @_;
    #my $p = $c->request->parameters;
    my (@topics_open_by_status, @datas);

    my $where = {};
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
                $_->{id};
            } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    $where->{'category.id'} = mdb->in(@user_categories);
    $where->{'category_status.type'} = mdb->nin(('F','FC'));

    if( $username && ! $perm->is_root( $username )){
            my @proj_coll_roles = Baseliner->model('Permissions')->user_projects_ids_with_collection(username=>$username);
            my @ors;
            for my $proj_coll_ids ( @proj_coll_roles ) {
                my $wh = {};
                my $count = scalar keys %{ $proj_coll_ids || {} };
                while ( my ( $k, $v ) = each %{ $proj_coll_ids || {} } ) {
                    if ( $k eq 'project' && $count gt 1) {
                        $wh->{"_project_security.$k"} = {'$in' => [ undef, keys %{$v || {}} ]};
                    } else {
                        $wh->{"_project_security.$k"} = {'$in' => [ keys %{$v || {}} ]};
                    }
                } ## end while ( my ( $k, $v ) = each...)                push @ors, $wh;
            }
            my $where_undef = { '_project_security' => undef };
            push @ors, $where_undef;
            $where->{'$or'} = \@ors;
        }

    @topics_open_by_status = _array(mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { _id => '$category_status.id', 'status' => {'$max' => '$category_status.name'},'color' => {'$max' => '$category_status.color'}, 'total' => { '$sum' => 1 }} },
        { '$sort' => { total => -1}}
    ]));
    
    foreach my $topic (@topics_open_by_status){
        push @datas, {
                    total         => $topic->{total},
                    status        => $topic->{status},
                    color		  => $topic->{color},
                    status_id     => $topic->{_id}
                };
     }
    $c->stash->{topics_open_by_status} = \@datas;
    $c->stash->{topics_open_by_status_title} = _loc('Topics open by status');

}

sub list_status_changed: Local{
    my ( $self, $c ) = @_;
    
    my $now1 = my $now2 = mdb->now;
    $now2 += '1D';
    
    my $fecha1 = $now1->ymd;
    $fecha1 =~ s/\//-/g;
    
    my $fecha2 = $now2->ymd;
    $fecha2 =~ s/\//-/g;
    
    my $query = {
        event_key   => 'event.topic.change_status',
        ts			=> { '$lte' => ''.$fecha2, '$gte' => ''.$fecha1 },
    };
    
    #my @user_categories =  map { $_->{id} } $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view' );
    #my @user_project_ids = Baseliner->model("Permissions")->user_projects_ids( username => $c->username);
    #
    #my $topic_project = DB->BaliMasterRel->search({to_mid=>\@user_project_ids, rel_type=>'topic_project'}, 
    #                          {select=>'from_mid', group_by=>'from_mid'} )->as_query;

    
    
    #my %my_topics;
    #map { $my_topics{$_->{mid}} = 1 } DB->BaliTopic->search({mid=>{ -in=> $topic_project } , id_category => \@user_categories, modified_on=> {'between' => [ $now1->ymd, $now2->ymd ]}})->hashref->all;
    
    my %my_topics;
    my ($cnt, @rows ) = Baseliner->model('Topic')->topics_for_user({ username => $c->username, limit=>1000, query=>undef });
    map { $my_topics{$_->{mid}} = 1 } @rows;

    

    my @status_changes;
    my @mid_topics;
    my @topics = mdb->event->find($query)->sort({ ts=>-1 })->all;
    map {
        my $ed = _load( $_->{event_data} );
        if ( (exists $my_topics{$ed->{topic_mid}} || Baseliner->model("Permissions")->is_root( $c->username ) ) && $ed->{old_status} ne $ed->{status}){
            push @status_changes, { old_status => $ed->{old_status}, status => $ed->{status}, username => $ed->{username}, when => $_->{ts}, mid => $ed->{topic_mid} };
            push @mid_topics, $ed->{topic_mid};
        }
    } @topics;
    
    @status_changes = sort { $a->{mid} <=> $b->{mid} } @status_changes;
    @mid_topics = _unique map {$_} @mid_topics ;
    
    my %topics_categories;
    map { $topics_categories{$_->{mid}} = { color => $_->{categories}->{color},
    										name => $_->{categories}->{name}} }  Baseliner->model('Baseliner::BaliTopic')->search(
                            { mid => \@mid_topics},
                            { prefetch=>['categories'] }
                            )->hashref->all;
    
    $c->stash->{list_topics} = \%topics_categories;
    $c->stash->{list_status_changed} = \@status_changes;
    $c->stash->{list_status_changed_title} = _loc('Daily highlights');    
};



1;
