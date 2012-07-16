package Baseliner::Controller::Dashboard;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

register 'menu.admin.dashboard' => {
    label    => 'Dashboard',
    title    => _loc ('Admin Dashboard'),
    action   => 'action.admin.dashboard',
    url_comp => '/dashboard/grid',
    icon     => '/static/images/icons/home.gif',
    tab_icon => '/static/images/icons/home.gif'
};

register 'action.admin.dashboard' => { name=>'View and Admin dashboards' };

##Configuración del dashboard
register 'config.dashboard' => {
	metadata => [
	       { id=>'states', label=>'States for job statistics', default => 'DESA,IT,TEST,PREP,PROD' },
	       { id=>'job_days', label=>'Days for job statistics', default => 7 },
	       { id=>'bl_days', label=>'Days for baseline graph', default => 7 },
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
    
    my $rs = $c->model('Baseliner::BaliDashboard')->search( $where,
															{ page => $page,
															  rows => $limit,
															  order_by => $sort ? { "-$dir" => $sort } : undef
															}
													);
	
	my $pager = $rs->pager;
	$cnt = $pager->total_entries;		
	
    my @rows;
    while( my $r = $rs->next ) {
	    # produce the grid

		my @roles = map { $_->{id_role} } $c->model('Baseliner::BaliDashboardRole')->search( {id_dashboard => $r->id})->hashref->all;
		my @dashlets = map {$_->{html} . '#' . $_->{url}} @{_load $r->dashlets};
		
		push @rows,
		  {
			id 			=> $r->id,
			name		=> $r->name,
			description	=> $r->description,
			is_main 	=>     $r->is_main,
			roles 		=> \@roles,
			dashlets	=> \@dashlets,
		  };
    }
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};		
    $c->forward('View::JSON');
}

sub list_dashlets : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    
	my @dash_dirs = 
	map {
		_dir( $_->root, 'dashlets' )->stringify  
	} Baseliner->features->list;
	push @dash_dirs, $c->path_to( 'root/dashlets' ) . "";
	@dash_dirs = grep { -d } @dash_dirs;
	my @dashlets = map {
		my @ret;
		for my $f ( grep { -f } _dir( $_ )->children ) { 
		my $d = $f->slurp;
		my ( $yaml, $html ) = $d =~ /^<!--(.*)\n---.?\n(.*)$/gs;
	   
		my $metadata;
		if(length $yaml && length $html ) {
			$metadata =  _load( $yaml );    
		} else {
			$metadata = {};
			$html = $d; 
		}
		my @rows = map {
			+{  field=>$_, value => $metadata->{$_} } 
		} keys %{ $metadata || {} };
		push @ret, {
			file => "$f",
			html => $html,
			yaml => $yaml,
			metadata => $metadata,
			rows => \@rows,
		};
		}
	   @ret;
	} @dash_dirs;
	@dashlets;
	
	my @rows;
    for my $dash ( @dashlets ) {
        $c->forward( $dash->{metadata}->{url} );
		push @rows,
		  {
			id			=> $dash->{metadata}->{html} .'#' . $dash->{metadata}->{url},
			name		=> $dash->{metadata}->{name},
			description	=> $dash->{metadata}->{description},
			
		  };		
    }	
	
    $c->stash->{json} = { data=>\@rows };		
    $c->forward('View::JSON');
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
	my (@dashlets, $i);
	
	my $i = 0;
	foreach my $dashlet (_array $p->{dashlets}){
		my @html_url = split(/#/, $dashlet);
		push @dashlets, { html	=>	$html_url[0],
						  url	=>  $html_url[1],
						  order	=>  ++$i	};
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
                $dashboard ->update();
                
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
    my ($self, $c) = @_;
	my $p = $c->req->params;
	my $dashboard_id = $p->{dashboard_id};

    # list dashboardlets, only active ones
    #my @dashs = Baseliner->model('Registry')->search_for( key => 'dashboard.' ); #, allowed_actions => [@actions] );
    #@dashs = grep { $_->active } @dashs;
	my @dashlets;
	
	if ($dashboard_id){
		my $dashboard = $c->model('Baseliner::BaliDashboard')->find($dashboard_id);
		@dashlets = @{_load $dashboard->dashlets};
		for my $dash ( @dashlets ) {
			$c->forward( $dash->{url} );
		}
		$c->stash->{dashboardlets} = \@dashlets;
	}else{
		my $dashboard = $c->model('Baseliner::BaliDashboard')->search( undef, {order_by => 'is_main desc'} );
		
		if ($dashboard->count > 0){
			my $i = 0;
			my @dashboard;
			while (my $dashboard = $dashboard->next){
				if($i == 0){
					@dashlets = @{_load $dashboard->dashlets};
					for my $dash ( @dashlets ) {
						$c->forward( $dash->{url} );
					}
					$c->stash->{dashboardlets} = \@dashlets;
				}else{
					push @dashboard, { name => $dashboard->name,
									   id   => $dashboard->id,
									 };
				}
				$i++;
			}
			$c->stash->{dashboards} = \@dashboard;
			
		}else{
			##Dashboard proporcionado por clarive (default)
			@dashlets = (	{ html => '/dashlets/baselines.html', url => '/dashboard/list_baseline', order => 1},
							{ html => '/dashlets/lastjobs.html', url => '/dashboard/list_lastjobs', order => 2},
							{ html => '/dashlets/topics.html', url => '/dashboard/list_topics', order => 3},
							{ html => '/dashlets/emails.html', url => '/dashboard/list_emails', order => 4},
							{ html => '/dashlets/jobs.html', url => '/dashboard/list_jobs', order=> 5},
							{ html=> '/dashlets/sqa.html', url=> '/sqa/grid_json/Dashboard', order=> 6},
						);
			
			my $dashboard = $c->model('Baseliner::BaliDashboard')->create(
							{
								name  => 'Clarive',
								description => 'Demo dashboard Clarive configurable',
								dashlets => _dump \@dashlets,
							});
			
			if ($dashboard->id){
				my $dasboard_role = $c->model('Baseliner::BaliDashboardRole')->create(
									{
										id_dashboard  => $dashboard->id,
										id_role => 100, #Public
									});
			}
			for my $dash ( @dashlets ) {
				$c->forward( $dash->{url} );
				$c->stash->{dashboardlets} = \@dashlets;
			}	
		}
	}
    
    $c->stash->{template} = '/comp/dashboard.html';
}

sub list_baseline: Private{
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my (@jobs, $job, @datas, @temps, $SQL);
	
    my $bl_days = config_get('config.dashboard')->{bl_days} // 7;
	
	#Cojemos los proyectos que el usuario tiene permiso para ver jobs
	my @ids_project = $c->model( 'Permissions' )->user_projects_with_action(username => $c->username,
																			action => 'action.job.viewall',
																			level => 1);
	my $ids_project =  'MID=' . join (' OR MID=', @ids_project);
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	

	$SQL = "SELECT BL, 'OK' AS RESULT, COUNT(*) AS TOT FROM BALI_JOB
                WHERE 	TO_NUMBER(SYSDATE - ENDTIME) <= ? AND STATUS = 'FINISHED'
						AND ID IN (SELECT ID_JOB FROM BALI_JOB_ITEMS A,
														(SELECT NAME FROM BALI_PROJECT WHERE $ids_project AND ACTIVE = 1) B 
                        WHERE SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = B.NAME)
                GROUP BY BL
			UNION				
			SELECT BL, 'ERROR' AS RESULT, COUNT(*) AS TOT FROM BALI_JOB
			WHERE 	TO_NUMBER(SYSDATE - ENDTIME) <= ? AND STATUS IN ('ERROR','CANCELLED','KILLED')
					AND ID IN (SELECT ID_JOB FROM BALI_JOB_ITEMS A,
													(SELECT NAME FROM BALI_PROJECT WHERE $ids_project AND ACTIVE = 1) B 
					WHERE SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = B.NAME)
			GROUP BY BL";				
	
	@jobs = $db->array_hash( $SQL, $bl_days, $bl_days);

	#my @entornos = ('TEST', 'PREP', 'PROD');
    my $config     = Baseliner->model('ConfigStore')->get('config.dashboard');
	my @entornos = split ",", $config->{states};
	
	foreach my $entorno (@entornos){
		my ($totError, $totOk, $total, $porcentError, $porcentOk, $bl);
		@temps = grep { ($_->{bl}) =~ $entorno } @jobs;
		foreach my $temp (@temps){
			$bl = $temp->{bl};
			if($temp->{result} eq 'OK'){
				$totOk = $temp->{tot};
			}else{
				$totError = $temp->{tot};
			}
		}
		$total = $totOk + $totError;
		if($total){
			$porcentOk = $totOk * 100/$total;
			$porcentError = $totError * 100/$total;
		}else{
			$bl = $entorno;
			$totOk = '';
			$totError = '';
			$porcentOk = 0;
			$porcentError = 0;			
		}
		push @datas, {
						bl 				=> $bl,
						porcentOk		=> $porcentOk,
						totOk			=> $totOk,
						total			=> $total,
						totError		=> $totError,
						porcentError	=> $porcentError
					};			
	}
	$c->stash->{entornos} =\@datas;
}

sub list_lastjobs: Private{
	my ( $self, $c ) = @_;
	my $order_by = 'STARTTIME DESC'; 
	my $rs_search = $c->model('Baseliner::BaliJob')->search(
        undef,
		{
			order_by => $order_by,
		}
	);
	my $numrow = 0;
	my @lastjobs;
	while( my $rs = $rs_search->next ) {
		if ($numrow >= 7) {last;}
	    push @lastjobs,{ 	id => $rs->id,
							name => $rs->name,
							type => $rs->type,
							rollback => $rs->rollback,
							status => $rs->status,
							starttime => $rs->starttime,
							endtime=> $rs->endtime};
		$numrow = $numrow + 1;
	}
	$c->stash->{lastjobs} =\@lastjobs;
}

sub list_emails: Private{
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my (@emails, $email, @datas, $SQL);
	
	
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	$SQL = "SELECT SUBJECT, SENDER, B.SENT, ID
				FROM BALI_MESSAGE A,
					(SELECT * FROM ( SELECT ID_MESSAGE,  SENT
										FROM BALI_MESSAGE_QUEUE
										WHERE USERNAME = ? AND SWREADED = 0
										ORDER BY SENT DESC ) WHERE ROWNUM < 6) B
				WHERE A.ID = B.ID_MESSAGE";
				

	@emails = $db->array_hash( $SQL , $username);
	foreach $email (@emails){
	    push @datas, $email;
	}	
		
	$c->stash->{emails} =\@datas;
}

sub list_topics: Private{
    my ( $self, $c ) = @_;
	my $username = $c->username;
	#my (@topics, $topic, @datas, $SQL);
	
	my $limit = 5;
	my @columns = ('topic_mid','title', 'category_name', 'created_on', 'created_by', 'category_status_name', 'numcomment');
	my ($select, $as, $order_by,  $group_by) = ([map {'me.' . $_} @columns], #select
												[@columns], #as
												[{-desc => 'me.created_on' }], #order_by
												[@columns] #group_by
												);
	my $where = {};
    $where->{'me.status'} = 'O';
	
	my @datas = $c->model('Baseliner::TopicView')->search(  
        $where,
        { select=>$select, as=>$as, order_by=>$order_by, rows=>$limit, group_by=>$group_by }
    )->hashref->all; 	
	
	$c->stash->{topics} =\@datas;
}

sub list_jobs: Private {
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my @datas;	
	my $SQL;
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );

	#Cojemos los proyectos que el usuario tiene permiso para ver jobs
	my @ids_project = $c->model( 'Permissions' )->user_projects_with_action(username => $c->username,
																			action => 'action.job.viewall',
																			level => 1);
	my $ids_project =  'MID=' . join (' OR MID=', @ids_project);
	
	
	$SQL = "SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY PROJECT1, G.ID) AS MY_ROW_NUM, E.ID, E.PROJECT1, F.BL, G.ID AS ORDERBL, F.STATUS, F.ENDTIME, F.STARTTIME, TRUNC(SYSDATE) - TRUNC(F.ENDTIME) AS DIAS, F.NAME, ROUND ((F.ENDTIME - STARTTIME) * 24 * 60) AS DURATION
						FROM (SELECT * FROM (SELECT MAX(ID_JOB) AS ID, SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) AS PROJECT1, BL
							FROM BALI_JOB_ITEMS A, BALI_JOB B
							WHERE A.ID_JOB = B.ID
							GROUP BY  SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))), BL) C,
						(SELECT DISTINCT SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) AS PROJECT, BL
							FROM BALI_JOB_ITEMS A,
								(SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY FECHA DESC) AS MY_ROW_NUM , ID, FECHA, STATUS, ENDTIME, BL 
													FROM (SELECT  ID, SYSDATE + MY_ROW_NUM/(24*60*60)  AS FECHA, STATUS, ENDTIME, BL 
															FROM (SELECT ID, STARTTIME, ROW_NUMBER() OVER(ORDER BY STARTTIME ASC) AS MY_ROW_NUM, STATUS, ENDTIME, BL 
																		FROM BALI_JOB
																		WHERE STATUS = 'RUNNING' AND ID IN (SELECT ID_JOB FROM BALI_JOB_ITEMS A,
																															(SELECT NAME FROM BALI_PROJECT WHERE $ids_project AND ACTIVE = 1) B 
																													WHERE SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = B.NAME))
																		
																		
																		
																		
														  UNION
														  SELECT  ID, ENDTIME AS FECHA, STATUS, ENDTIME, BL FROM BALI_JOB
																					WHERE ENDTIME IS NOT NULL AND ID IN (SELECT ID_JOB FROM BALI_JOB_ITEMS A,
																																		(SELECT NAME FROM BALI_PROJECT WHERE $ids_project AND ACTIVE = 1) B 
																																WHERE SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = B.NAME)
														 
														 
														 )
											   )
								) B
							WHERE A.ID_JOB = B.ID ) D WHERE C.PROJECT1 = D.PROJECT AND C.BL = D.BL) E, BALI_JOB F, BALI_BASELINE G WHERE E.ID = F.ID AND F.BL = G.BL)
				WHERE MY_ROW_NUM < 11";				
	my @jobs = $db->array_hash( $SQL);
	
	foreach my $job (@jobs){
		my ($lastError, $lastOk, $idError, $idOk, $nameOk, $nameError, $lastDuration);
		given ($job->{status}) {
			when ('RUNNING') {
				my @jobError = get_last_jobError($job->{project1},$job->{bl},$username);

				if(@jobError){
					foreach my $jobError (@jobError){
						$idError = $jobError->{id};
						$lastError = $jobError->{dias};
						$nameError = $jobError->{name};
						$lastDuration = $jobError->{duration};
					}
				}
				my @jobOk = get_last_jobOk($job->{project1},$job->{bl},$username);
				
				if(@jobOk){
					foreach my $jobOk (@jobOk){
						$idOk = $jobOk->{id};
						$lastOk = $jobOk->{dias};
						$nameOk = $jobOk->{name};
						if($lastOk < $lastError){
							$lastDuration = $jobOk->{duration};	
						}
					}
				}				
				
			}
			when ('FINISHED') {
				$idOk = $job->{id};
				$lastOk = $job->{dias};
				$nameOk = $job->{name};
				$lastDuration = $job->{duration};
				
				my @jobError = get_last_jobError($job->{project1},$job->{bl});

				if(@jobError){
					foreach my $jobError (@jobError){
						$idError = $jobError->{id};
						$lastError = $jobError->{dias};
						$nameError = $jobError->{name};
					}
				}
				
			}
			when ('ERROR' || 'CANCELLED' || 'KILLED') {
				$idError = $job->{id};
				$lastError = $job->{dias};
				$nameError = $job->{name};
				$lastDuration = $job->{duration};

				my @jobOk = get_last_jobOk($job->{project1},$job->{bl});
				
				if(@jobOk){
					foreach my $jobOk (@jobOk){
						$idOk = $jobOk->{id};
						$lastOk = $jobOk->{dias};
						$nameOk = $jobOk->{name};
					}
				}
			}
		}
			
		push @datas, {
					project 		=> $job->{project1},
					bl				=> $job->{bl},
					lastOk			=> $lastOk,
					idOk			=> $idOk,
					nameOk			=> $nameOk,
					idError			=> $idError,
					lastError		=> $lastError,
					nameError		=> $nameError,
					lastDuration 	=> $lastDuration
				};	
	}	
	
	$c->stash->{jobs} =\@datas;
}

sub get_last_jobOk: Private{
	my $project = shift;
	my $bl = shift;
	my $username = shift;
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	
	my $SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS, ROUND ((ENDTIME - STARTTIME) * 24 * 60) AS DURATION 
								FROM BALI_JOB_ITEMS A, BALI_JOB B 
								WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
										AND BL = ? AND STATUS = 'FINISHED' AND ENDTIME IS NOT NULL)
					WHERE MY_ROW_NUM < 2";
	return $db->array_hash( $SQL, $project, $bl);
}

sub get_last_jobError: Private{
	my $project = shift;
	my $bl = shift;
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	
	my $SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS, ROUND ((ENDTIME - STARTTIME) * 24 * 60) AS DURATION 
								FROM BALI_JOB_ITEMS A, BALI_JOB B 
								WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
										AND BL = ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND ENDTIME IS NOT NULL)
					WHERE MY_ROW_NUM < 2";
	return $db->array_hash( $SQL, $project, $bl );	
}

sub viewjobs: Local{
	my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $username = $c->username;
	my ($status, @jobs, $job, $jobsid, $SQL);
	my $jobsid = '';
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	
	if($p->{ent} eq 'All'){
		$SQL = "SELECT ID FROM BALI_JOB WHERE STATUS = 'RUNNING' AND USERNAME = ?";
		@jobs = $db->array_hash( $SQL, $username );
	}else{
		my $job_days = config_get('config.dashboard')->{bl_days};
		$SQL = $p->{swOk} ?
				"SELECT ID FROM BALI_JOB WHERE TO_NUMBER(SYSDATE - ENDTIME) <= ? AND BL = ? AND STATUS = 'FINISHED' AND USERNAME = ?" :
				"SELECT ID FROM BALI_JOB WHERE TO_NUMBER(SYSDATE - ENDTIME) <= ? AND BL = ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND USERNAME = ?";
		@jobs = $db->array_hash( $SQL, $job_days, $p->{ent}, $username );
	}
	
	foreach $job (@jobs){
	    $jobsid .= $job->{id} . ",";
 	}
	$c->stash->{jobs} =$jobsid;
	$c->forward('/job/monitor/Dashboard');
}


1;
