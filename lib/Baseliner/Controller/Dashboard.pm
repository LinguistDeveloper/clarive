package Baseliner::Controller::Dashboard;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }


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
	my (@jobs, $job, @datas, $SQL);
	
	
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	$SQL = "SELECT DISTINCT A.ID_JOB, NAME, SUBSTR(APPLICATION, -(LENGTH(APPLICATION) - INSTRC(APPLICATION, '/', 1, 1))) AS PROJECT, STATUS, BL
				FROM BALI_JOB_ITEMS A,
					(SELECT * FROM ( SELECT ID, NAME, STATUS, BL
										FROM BALI_JOB
										WHERE USERNAME = ?
										ORDER BY MAXSTARTTIME DESC ) WHERE ROWNUM < 6) B
				WHERE A.ID_JOB = B.ID
				ORDER BY A.ID_JOB";

	@jobs = $db->array_hash( $SQL , $username);
	foreach $job (@jobs){
	    push @datas, $job;
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
	$SQL = "SELECT * FROM (SELECT C.ID, TITLE, DESCRIPTION, to_char(created_on,'DD/MM/YYYY HH24:MI:SS') AS CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT
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
	_log "sdad>>>>>>>>>>>>>>>>>>>>>>>>>" . _dump($c->stash->{sqas}) . "\n";
}

1;
