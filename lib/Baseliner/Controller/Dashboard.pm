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
    ##$c->stash->{username} = $c->username;
    $c->forward('/dashboard/list_jobs');
    $c->forward('/dashboard/list_sqa');
    $c->forward('/dashboard/list_emails');
	$c->forward('/dashboard/list_issues');
    $c->stash->{template} = '/comp/dashboard.js';
}

sub list_jobs: Private{
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

	my ($totError, $totOk, $total, $porcentError, $porcentOk, $bl);
	
	foreach my $entorno (@entornos){
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
	
	$c->stash->{jobs} =\@datas;
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
