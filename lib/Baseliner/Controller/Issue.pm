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
    $sort ||= 'id';
    $dir ||= 'asc';
    $start||= 0;
    $limit ||= 100;

	my @datas = Baseliner::Model::Issue->GetIssues({orderby => "$sort $dir"});
	
	#Viene por la parte de dashboard, y realiza el filtrado por ids.
	if($query_id){ 
		@datas = grep { ($_->{id}) =~ $query_id } @datas if $query_id;
	#Comportamiento normal.
	}else{
		#Filtramos por el estado de las issues, abiertas 'O' o cerradas 'C'.
		@datas = grep { uc($_->{status}) =~ $filter } @datas;
		#Filtramos por lo que han introducido en el campo de búsqueda.
		@datas = grep { lc($_->{title}) =~ $query } @datas if $query;
	}
    my @rows;
          
    #Creamos el json para la carga del grid de issues.
	foreach my $data (@datas){
		push @rows, {
			id 		=> $data->{id},
			title	=> $data->{title},
			description	=> $data->{description},
			created_on 	=> $data->{created_on},
			created_by 	=> $data->{created_by},
			numcomment 	=> $data->{numcomment},
			category	=> $data->{category}
		};
    }
    $cnt = $#rows + 1 ;	
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    $p->{username} = $c->username;
	
	_log ">>>>>>>>Parametros: " . _dump $p . "\n";

	try  {    
	    my ($msg, $id) = Baseliner::Model::Issue->update( $p );
	    $c->stash->{json} = { success => \1, msg=>_loc($msg), issue_id => $id };
	} catch {
		my $e = shift;
		$c->stash->{json} = { success => \0, msg=>_loc($e) };
	};
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

sub list_category : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
	my $cnt;
	my $row;
	my @rows;
	$row = $c->model('Baseliner::BaliIssueCategories')->search();
	
	if($row){
		while( my $r = $row->next ) {
			push @rows,
			  {
				id          => $r->id,
				name	    => $r->name,
				description	=> $r->description,
			  };
		}  
	}
    $cnt = $#rows + 1 ;	
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update_category : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};

    given ($action) {
        when ('add') {
            try{
                my $category = $c->model('Baseliner::BaliIssueCategories')->create(
                                    {
                                        name  => $p->{name},
                                        description=> $p->{description},
                                    });
                $c->stash->{json} = { msg=>_loc('Category added'), success=>\1, baseline_id=> $category->id };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Category: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {
            try{
                my $id_category = $p->{id};
                my $category = $c->model('Baseliner::BaliIssueCategories')->find( $id_category );
                $category->name( $p->{name} );
                $category->description( $p->{description} );
                $category->update();
                
                $c->stash->{json} = { msg=>_loc('Category modified'), success=>\1, baseline_id=> $id_category };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Category: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            my $id_category = $p->{id};
            
            try{
                my $row = $c->model('Baseliner::BaliIssueCategories')->find( $id_category );
                $row->delete;
                
                $c->stash->{json} = { success => \1, msg=>_loc('Category deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Category') };
            }
        }
    }
    
    $c->forward('View::JSON');    
}

1;
