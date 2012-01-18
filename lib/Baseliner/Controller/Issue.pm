package Baseliner::Controller::Issue;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Try::Tiny;
use Switch;
BEGIN {  extends 'Catalyst::Controller' }

register 'menu.tools.issues' => {
    label    => 'Issues',
    title    => 'Issues',
    action   => 'action.issues.view',
    url_comp => '/issue/grid',
    icon     => '/static/images/icons/pencil.png',
    tab_icon => '/static/images/icons/pencil.png'
};

register 'action.issues.view' => { name=>'View and Admin issues' };

sub grid : Local {
    my ($self, $c) = @_;
    $c->stash->{template} = '/comp/issue_grid.js';
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $filter, $cnt) = ( @{$p}{qw/start limit query dir sort filter/}, 0 );
    $sort ||= 'me.id';
    $dir ||= 'asc';
    $start||= 0;
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    
    _log ">>>>>>>>>>>>>>>>>>>>" . $filter . "\n";
    
    my $where = $query
        ? { 'lower(id||title)' => { -like => "%".lc($query)."%" }, status => $filter}
        : { status => $filter };   
    
    my $rs = $c->model('Baseliner::BaliIssue')->search(
	$where,
	{ page => $page,
	  rows => $limit,
	  order_by => $sort ? "$sort $dir" : undef
	}
    );
	
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;	
	
    $c->stash->{total_opened} = $cnt;	
	
    my @rows;
    while( my $r = $rs->next ) {
    # produce the grid
	push @rows,
	  {
	    id 		=> $r->id,
	    title	=> $r->title,
	    description	=> $r->description
	  };
    }
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};		
    $c->forward('View::JSON');
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    
    switch ($action) {
	case 'add' {
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
	case 'update' {
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
	case 'delete'{
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
	case 'close' {
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

1;
