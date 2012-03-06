package Baseliner::Controller::Issue;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  
register 'menu.tools.issues' => {
    label    => 'Issues',
    title    => 'Issues',
    action   => 'action.issues.view',
    url_comp => '/issue/grid',
    icon     => '/static/images/icons/tasks.gif',
    tab_icon => '/static/images/icons/tasks.gif'
};

register 'action.issues.view' => { name=>'View and Admin issues' };

sub grid : Local {
    my ($self, $c) = @_;
	my $p = $c->req->params;
	$c->stash->{query_id} = $p->{query};	
    $c->stash->{template} = '/comp/issue_grid.js';
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $query_id, $dir, $sort, $filter, $cnt) = ( @{$p}{qw/start limit query query_id dir sort filter/}, 0 );
    $sort ||= 'me.id';
    $dir ||= 'asc';
    $start||= 0;
    $limit ||= 100;

    #my $page = to_pages( start=>$start, limit=>$limit );
    #
    #my $where = $query
    #    ? { 'lower(id||title)' => { -like => "%".lc($query)."%" }, status => $filter}
    #    : { status => $filter };   
    #
    #
#    $query and $where = query_sql_build(
#       query  => $query,
#       fields => {
#	   id           => 'me.id',
#	   title	=> 'me.title',
#	   description	=> 'me.description',
#	   created_on	=> "to_char(me.created_on,'DD/MM/YYYY HH24:MI:SS')",
#	   created_by	=> 'me.created_by',
#       }
#   );
# 
# 
#    my $rs = $c->model('Baseliner::BaliIssue')->search(
#	$where,
#	{ page => $page,
#	  rows => $limit,
#	  order_by => $sort ? "$sort $dir" : undef
#	}
#    );
#	
#	
#    my $pager = $rs->pager;
#    $cnt = $pager->total_entries;	
#	
#    my @rows;
#    while( my $r = $rs->next ) {
#    # produce the grid
#	push @rows,
#	  {
#	    id 		=> $r->id,
#	    title	=> $r->title,
#	    description	=> $r->description,
#	    created_on => defined $r->created_on
#	    ? $r->created_on->dmy('/') . ' ' . $r->created_on->hms
#	    : '',	    
#	    created_by 	=> $r->created_by
#	  };
#
#    }
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    
    my $SQL = "SELECT C.ID, TITLE, DESCRIPTION, to_char(created_on,'DD/MM/YYYY HH24:MI:SS') AS CREATED_ON, CREATED_BY, STATUS, NUMCOMMENT
			FROM  BALI_ISSUE C
			      LEFT JOIN
			      (SELECT COUNT(*) AS NUMCOMMENT, A.ID FROM BALI_ISSUE A, BALI_ISSUE_MSG B WHERE A.ID = B.ID_ISSUE GROUP BY A.ID) D
			      ON C.ID = D.ID ORDER BY C.ID ASC";
   
    my @datas = $db->array_hash( $SQL );
	
	
	if($query_id){ #Viene por la parte de dashboard
		@datas = grep { ($_->{id}) =~ $query_id } @datas if $query_id;
	}else{
		@datas = grep { uc($_->{status}) =~ $filter } @datas;
		
		@datas = grep { lc($_->{title}) =~ $query } @datas if $query;
	}
    my @rows;
          
    foreach my $data (@datas){
	push @rows, {
	    id 		=> $data->{id},
	    title	=> $data->{title},
	    description	=> $data->{description},
	    created_on 	=> $data->{created_on},
	    created_by 	=> $data->{created_by},
	    numcomment 	=> $data->{numcomment}
	};
    }
    $cnt = $#rows + 1 ;	
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    
    given ($action) {
	when ('add') {
	    try{
	        my $issue = $c->model('Baseliner::BaliIssue')->create(
						    {
							title	=> $p->{title},
							description => $p->{description},
							created_by => $c->username
						    });
		    
		$c->stash->{json} = { msg=>_loc('Issue added'), success=>\1, issue_id=> $issue->id };

	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error adding Issue: %1', shift()), failure=>\1 }
	    }
	}
	when ('update') {
	    try{
		my $id_issue = $p->{id};
		my $issue = $c->model('Baseliner::BaliIssue')->find( $id_issue );
		$issue->title( $p->{title} );
		$issue->description( $p->{description} );
		$issue->update();
		$c->stash->{json} = { msg=>_loc('Issue modified'), success=>\1, issue_id=> $id_issue };
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error modifying Issue: %1', shift()), failure=>\1 };
	    }
	}
	when ('delete') {
	    my $id_issue = $p->{id};
	    
	    try{
		my $row = $c->model('Baseliner::BaliIssue')->find( $id_issue );
		$row->delete;
	
		$c->stash->{json} = { success => \1, msg=>_loc('Issue deleted') };
	    }
	    catch{
		$c->stash->{json} = { success => \0, msg=>_loc('Error deleting issue') };
	    }
	}
	when ('close') {
	    try{
		my $id_issue = $p->{id};
		my $issue = $c->model('Baseliner::BaliIssue')->find( $id_issue );
		$issue->status( 'C' );
		$issue->update();
		$c->stash->{json} = { msg=>_loc('Issue closed'), success=>\1, issue_id=> $id_issue };
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error closing Issue: %1', shift()), failure=>\1 };
	    }
	}
    }

    $c->forward('View::JSON');
}

sub view : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $id_issue = $p->{id_rel};

    my $issue = $c->model('Baseliner::BaliIssue')->find( $id_issue );
    $c->stash->{title} = $issue->title;
    $c->stash->{description} = $issue->description;
    
    $c->stash->{id_rel} = $id_issue;
    $c->stash->{template} = '/comp/issue_msg.js';
}

sub viewdetail: Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $id_issue = $p->{id_rel};
    
    if ($p->{action}){
	$id_issue = $p->{action};

	    try{
	        my $issue = $c->model('Baseliner::BaliIssueMsg')->create(
						    {
							id_issue	=> $id_issue,
							text => $p->{text},
							created_by => $c->username
						    });
		    
	    $c->stash->{json} = { msg=>_loc('Comment added'), success=>\1, issue_id=> $issue->id };

	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error adding Comment: %1', shift()), failure=>\1 }
	    }
    }
    else{
	my $rs = $c->model('Baseliner::BaliIssueMsg')->search( {id_issue=>$id_issue},	    
							{
							    order_by=> 'created_on desc'
							}
							);
	my @rows;
	while( my $r = $rs->next ) {
	# produce the grid
	    push @rows,
	      {
		created_by	=> $r->created_by,
		text		=> $r->text
	      };
	}
	$c->stash->{json} = { data=>\@rows, success => \1 };
    }
    $c->forward('View::JSON');    
}
1;
