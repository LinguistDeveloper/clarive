package Baseliner::Controller::Dashboard;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

##Configuración del dashboard
register 'config.dashboard' => {
	metadata => [
	       { id=>'states', label=>'States for job statistics', default => 'DESA,TEST,PREP,PROD' }
	    ]
};

sub list : Local {
    my ($self, $c) = @_;
    $c->forward('/dashboard/list_entornos');
    $c->forward('/dashboard/list_emails');
	$c->forward('/dashboard/list_issues');	
	$c->forward('/dashboard/list_jobs');	
    $c->forward('/dashboard/list_sqa');
    $c->stash->{template} = '/comp/dashboard.js';
}

sub list_entornos: Private{
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my (@jobs, $job, @datas, @temps, $SQL);
	
	
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	$SQL = "SELECT BL, 'OK' AS RESULT, COUNT(*) AS TOT FROM BALI_JOB
				WHERE TO_NUMBER(SYSDATE - ENDTIME) <= 7 AND STATUS = 'FINISHED' AND USERNAME = ?
				GROUP BY BL
			UNION
			SELECT BL, 'ERROR' AS RESULT, COUNT(*) AS TOT FROM BALI_JOB
				WHERE TO_NUMBER(SYSDATE - ENDTIME) <= 7 AND STATUS IN ('ERROR','CANCELLED','KILLED') AND USERNAME = ?
				GROUP BY BL";

	#$SQL = "SELECT DISTINCT A.ID_JOB, NAME, SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) AS PROJECT, STATUS, BL
	#			FROM BALI_JOB_ITEMS A,
	#				(SELECT * FROM ( SELECT ID, NAME, STATUS, BL
	#									FROM BALI_JOB
	#									WHERE USERNAME = ?
	#									ORDER BY MAXSTARTTIME DESC ) WHERE ROWNUM < 6) B
	#			WHERE A.ID_JOB = B.ID
	#			ORDER BY A.ID_JOB";

	@jobs = $db->array_hash( $SQL, $username, $username );
	
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
			push @datas, {
							bl 				=> $bl,
							porcentOk		=> $porcentOk,
							totOk			=> $totOk,
							total			=> $total,
							totError		=> $totError,
							porcentError	=> $porcentError
						};			
		}
	}
	$c->stash->{entornos} =\@datas;
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

sub list_issues: Private{
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my (@issues, $issue, @datas, $SQL);
	
	
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	$SQL = "SELECT * FROM (SELECT C.ID, TITLE, DESCRIPTION, CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT
								FROM  BALI_ISSUE C
								LEFT JOIN
										(SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
									ON C.ID = D.ID 
								WHERE STATUS = 'O'
								ORDER BY CREATED_ON DESC)
					  WHERE ROWNUM < 6";

	@issues = $db->array_hash( $SQL );
	foreach $issue (@issues){
	    push @datas, $issue;
	}	
		
	$c->stash->{issues} =\@datas;
}

sub list_jobs: Private {
    my ( $self, $c ) = @_;
	my $username = $c->username;
	my @datas;	
	my $SQL;
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	
	$SQL = "SELECT E.ID, E.PROJECT1, F.BL, F.STATUS, F.ENDTIME, F.STARTTIME, TRUNC(SYSDATE) - TRUNC(F.ENDTIME) AS DIAS, F.NAME, ROUND ((F.ENDTIME - STARTTIME) * 24 * 60) AS DURATION
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
																	WHERE STATUS = 'RUNNING' AND USERNAME = ?)
													  UNION
													  SELECT  ID, ENDTIME AS FECHA, STATUS, ENDTIME, BL FROM BALI_JOB
																				WHERE ENDTIME IS NOT NULL AND USERNAME = ?
													 )
										   )
							) B
						WHERE A.ID_JOB = B.ID ) D WHERE C.PROJECT1 = D.PROJECT AND C.BL = D.BL) E, BALI_JOB F WHERE E.ID = F.ID
						ORDER BY PROJECT1";
	my @jobs = $db->array_hash( $SQL, $username, $username );
	
	
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
				
				my @jobError = get_last_jobError($job->{project1},$job->{bl},$username);

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
				
				my @jobOk = get_last_jobOk($job->{project1},$job->{bl},$username);
				
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
										AND BL = ? AND STATUS = 'FINISHED' AND ENDTIME IS NOT NULL
										AND USERNAME = ?)
					WHERE MY_ROW_NUM < 2";
	return $db->array_hash( $SQL, $project, $bl , $username );
}

sub get_last_jobError: Private{
	my $project = shift;
	my $bl = shift;
	my $username = shift;
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	my $SQL = "SELECT * FROM (SELECT B.ID, NAME, ROW_NUMBER() OVER(ORDER BY endtime DESC) AS MY_ROW_NUM, ENDTIME, STARTTIME, TRUNC(SYSDATE)-TRUNC(ENDTIME) AS DIAS, ROUND ((ENDTIME - STARTTIME) * 24 * 60) AS DURATION 
								FROM BALI_JOB_ITEMS A, BALI_JOB B 
								WHERE A.ID_JOB = B.ID AND SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) = ? 
										AND BL = ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND ENDTIME IS NOT NULL
										AND USERNAME = ?)
					WHERE MY_ROW_NUM < 2";
	return $db->array_hash( $SQL, $project, $bl , $username );
}

sub list_sqa: Private{
	my ( $self, $c ) = @_;
	$c->forward('/sqa/grid_json/Dashboard');
}

sub viewjobs: Local{
	my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $username = $c->username;
	my ($status, @jobs, $job, $jobsid, $SQL);
	
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
		$SQL = $p->{swOk} ?
				"SELECT ID FROM BALI_JOB WHERE TO_NUMBER(SYSDATE - ENDTIME) <= 7 AND BL = ? AND STATUS = 'FINISHED' AND USERNAME = ?" :
				"SELECT ID FROM BALI_JOB WHERE TO_NUMBER(SYSDATE - ENDTIME) <= 7 AND BL = ? AND STATUS IN ('ERROR','CANCELLED','KILLED') AND USERNAME = ?";	
		@jobs = $db->array_hash( $SQL, $p->{ent}, $username );
	}
	
	foreach $job (@jobs){
	    $jobsid .= $job->{id} . ",";
 	}
	$c->stash->{jobs} =$jobsid;
	$c->forward('/job/monitor/Dashboard');
	
}


1;
