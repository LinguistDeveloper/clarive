package Baseliner::Controller::Dashboard;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

##Configuración del dashboard
register 'config.dashboard' => {
	metadata => [
	       { id=>'states', label=>'States for job statistics', default => 'DESA,TEST,PREP,PROD' },
	       { id=>'job_days', label=>'Days for job statistics', default => 7 },
	       { id=>'bl_days', label=>'Days for baseline graph', default => 7 },
	    ]
};

#register 'dashboard.jobs.envs' => {
#    name => 'Jobs By Baseline'
#    url  => '/dashboard/list_entornos',
#};

sub list : Local {
    my ($self, $c) = @_;
    $c->forward('/dashboard/list_entornos');
	$self->list_lastjobs( $c );
    $c->forward('/dashboard/list_emails');
	$c->forward('/dashboard/list_topics');	
	$c->forward('/dashboard/list_jobs');	

    # list dashboardlets, only active ones
    my @dashs = Baseliner->model('Registry')->search_for( key => 'dashboard.' ); #, allowed_actions => [@actions] );
    @dashs = grep { $_->active } @dashs;
    for my $dash ( @dashs ) {
        $c->forward( $dash->url );
    }
    $c->stash->{dashboardlets} = \@dashs;
    $c->stash->{template} = '/comp/dashboard.html';
}

sub list_entornos: Private{
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my (@jobs, $job, @datas, @temps, $SQL);
	
    my $bl_days = config_get('config.dashboard')->{bl_days} // 7;
	
	#Cojemos los proyectos que el usuario tiene permiso para ver jobs
	my @ids_project = $c->model( 'Permissions' )->user_projects_with_action(username => $c->username,
																			action => 'action.job.viewall',
																			level => 1);
	my $ids_project =  'ID=' . join (' OR ID=', @ids_project);
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	
	#$SQL = "SELECT BL, 'OK' AS RESULT, COUNT(*) AS TOT FROM BALI_JOB
	#			WHERE TO_NUMBER(SYSDATE - ENDTIME) <= ? AND STATUS = 'FINISHED' AND USERNAME = ?
	#			GROUP BY BL
	#		UNION
	#		SELECT BL, 'ERROR' AS RESULT, COUNT(*) AS TOT FROM BALI_JOB
	#			WHERE TO_NUMBER(SYSDATE - ENDTIME) <= ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND USERNAME = ?
	#			GROUP BY BL";
	
	#@jobs = $db->array_hash( $SQL, $bl_days, $username, $bl_days, $username );	

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
		if ($numrow >= 5) {last;}
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
	my (@topics, $topic, @datas, $SQL);
	
	
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	$SQL = "SELECT * FROM (SELECT C.ID, TITLE, DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT
								FROM  BALI_TOPIC C
								LEFT JOIN
										(SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_TOPIC A, BALI_POST B, BALI_MASTER_REL REL
                                        WHERE A.MID = REL.FROM_MID AND B.MID = REL.TO_MID AND REL_TYPE = 'topic_post'
                                        GROUP BY A.ID) D
									ON C.ID = D.ID 
								WHERE STATUS = 'O'
								ORDER BY CREATED_ON DESC)
					  WHERE ROWNUM < 6";

	@topics = $db->array_hash( $SQL );
	foreach $topic (@topics){
	    push @datas, $topic;
	}	
		
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
	my $ids_project =  'ID=' . join (' OR ID=', @ids_project);
	
	
	#$SQL = "SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY PROJECT1, G.ID) AS MY_ROW_NUM, E.ID, E.PROJECT1, F.BL, G.ID AS ORDERBL, F.STATUS, F.ENDTIME, F.STARTTIME, TRUNC(SYSDATE) - TRUNC(F.ENDTIME) AS DIAS, F.NAME, ROUND ((F.ENDTIME - STARTTIME) * 24 * 60) AS DURATION
	#					FROM (SELECT * FROM (SELECT MAX(ID_JOB) AS ID, SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) AS PROJECT1, BL
	#						FROM BALI_JOB_ITEMS A, BALI_JOB B
	#						WHERE A.ID_JOB = B.ID
	#						GROUP BY  SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))), BL) C,
	#					(SELECT DISTINCT SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) AS PROJECT, BL
	#						FROM BALI_JOB_ITEMS A,
	#							(SELECT * FROM (SELECT ROW_NUMBER() OVER(ORDER BY FECHA DESC) AS MY_ROW_NUM , ID, FECHA, STATUS, ENDTIME, BL 
	#												FROM (SELECT  ID, SYSDATE + MY_ROW_NUM/(24*60*60)  AS FECHA, STATUS, ENDTIME, BL 
	#														FROM (SELECT ID, STARTTIME, ROW_NUMBER() OVER(ORDER BY STARTTIME ASC) AS MY_ROW_NUM, STATUS, ENDTIME, BL 
	#																	FROM BALI_JOB
	#																	WHERE STATUS = 'RUNNING' AND USERNAME = ?)
	#													  UNION
	#													  SELECT  ID, ENDTIME AS FECHA, STATUS, ENDTIME, BL FROM BALI_JOB
	#																				WHERE ENDTIME IS NOT NULL AND USERNAME = ?
	#													 )
	#										   )
	#							) B
	#						WHERE A.ID_JOB = B.ID ) D WHERE C.PROJECT1 = D.PROJECT AND C.BL = D.BL) E, BALI_JOB F, BALI_BASELINE G WHERE E.ID = F.ID AND F.BL = G.BL)
	#			WHERE MY_ROW_NUM < 11";
	#my @jobs = $db->array_hash( $SQL, $username, $username);		

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
				
				#$SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS 
				#							FROM BALI_JOB_ITEMS A, BALI_JOB B 
				#							WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
				#									AND BL = ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND ENDTIME IS NOT NULL
				#									AND USERNAME = ?)
				#				WHERE MY_ROW_NUM < 2";
				#my @jobError = $db->array_hash( $SQL, $job->{project1},$job->{bl}, $username );
				
				#my @jobError = get_last_jobError($job->{project1},$job->{bl},$username);
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
				#$SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS 
				#							FROM BALI_JOB_ITEMS A, BALI_JOB B 
				#							WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
				#									AND BL = ? AND STATUS = 'FINISHED' AND ENDTIME IS NOT NULL
				#									AND USERNAME = ?)
				#				WHERE MY_ROW_NUM < 2";
				#my @jobOk = $db->array_hash( $SQL, $job->{project1},$job->{bl}, $username );
				
				#my @jobOk = get_last_jobOk($job->{project1},$job->{bl},$username);
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
	#my $SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS, ROUND ((ENDTIME - STARTTIME) * 24 * 60) AS DURATION 
	#							FROM BALI_JOB_ITEMS A, BALI_JOB B 
	#							WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
	#									AND BL = ? AND STATUS = 'FINISHED' AND ENDTIME IS NOT NULL
	#									AND USERNAME = ?)
	#				WHERE MY_ROW_NUM < 2";
	#return $db->array_hash( $SQL, $project, $bl , $username );
	
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
	#my $username = shift;
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	#my $SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS, ROUND ((ENDTIME - STARTTIME) * 24 * 60) AS DURATION 
	#							FROM BALI_JOB_ITEMS A, BALI_JOB B 
	#							WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
	#									AND BL = ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND ENDTIME IS NOT NULL
	#									AND USERNAME = ?)
	#				WHERE MY_ROW_NUM < 2";
	#return $db->array_hash( $SQL, $project, $bl , $username );
	
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
	
	#ERROR, CANCELLED, KILLED 
	#$status = $p->{swOk} ? "FINISHED" : "('ERROR', 'CANCELLED', 'KILLED')";
	#$SQL = "SELECT ID FROM BALI_JOB
	#			WHERE TO_NUMBER(SYSDATE - STARTTIME) <= 7 AND BL = ? AND STATUS IN ? AND USERNAME = ?";
	#
	#@jobs = $db->array_hash( $SQL, $p->{ent}, $status, $username );
	
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
