package Baseliner::Controller::Project;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' };
use Baseliner::Utils;
use Baseliner::Sugar;
use Switch;
use Try::Tiny;
use Moose::Autobox;
use JSON::XS;
use namespace::clean;

register 'menu.admin.project' => {
	label => 'Projects', url_comp=>'/project/grid', actions=>['action.admin.role'],
	title=>'Projects', index=>80,
	icon=>'/static/images/icons/project.gif' };

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query) = ( @{$p}{qw/start limit query/}, 0 );
    $limit ||= 50;
    
    my $page = to_pages( start=>$start, limit=>$limit );
    my $id_project;
    
    my @datas;
    my $data;
    my $SQL;
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );

    if ($p->{anode}){
	$id_project=$p->{anode};
    }else{
	$id_project='todos';
    }

    my @tree;
    my $total_rows;
	
    if($query ne ''){
	$c->stash->{anode} = undef;
	$SQL = "SELECT ROWNUM, LEVEL, ID, NAME, DESCRIPTION, NATURE FROM BALI_PROJECT A START WITH ID_PARENT IS NULL AND ACTIVE = 1 CONNECT BY PRIOR ID = ID_PARENT AND ACTIVE = 1";
	@datas = $db->array_hash( "$SQL" );
	
	@datas = grep { lc($_->{name}) =~ $query } @datas if $query;

	foreach $data (@datas){
	    
	    push @tree, {
		name => $data->{name},
		description => $data->{description},
		nature => $data->{nature},
		_id => $data->{id},
		_parent => undef,
		_level => 1,
		_num_fila => $data->{rownum},
		_lft => ($data->{rownum} - 1) * 2 + 1,
		_rgt => ($data->{rownum} - 1) * 2 + 1 + 1,
		_is_leaf => \1
	    };
	}
	$total_rows = $#tree + 1 ;	
	
    }
    else{
	if($id_project ne 'todos'){
	    $SQL = "SELECT * FROM (SELECT B.ID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION
				   FROM BALI_PROJECT B
				   WHERE B.ID_PARENT = ? AND B.ACTIVE = 1
					 AND B.ID NOT IN (SELECT DISTINCT A.ID_PARENT
							  FROM BALI_PROJECT A
							  WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
				   UNION ALL
				   SELECT E.ID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION
				   FROM BALI_PROJECT E
				   WHERE E.ID IN (SELECT DISTINCT D.ID 
						  FROM BALI_PROJECT D,  
						  BALI_PROJECT C
						  WHERE D.ID_PARENT = ? AND C.ACTIVE = 1 AND
							D.ID = C.ID_PARENT)) RESULT, 
			     (SELECT ROWNUM, LEVEL, ID FROM BALI_PROJECT A START WITH ID_PARENT IS NULL AND ACTIVE = 1 CONNECT BY PRIOR ID = ID_PARENT AND ACTIVE = 1 ) RESULT1 
			     WHERE RESULT.ID = RESULT1.ID
		    ORDER BY ROWNUM ASC";
	    @datas = $db->array_hash( "$SQL" , $id_project, $id_project);
	}
	else{
	    $SQL = "SELECT * FROM (SELECT B.ID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION
				   FROM BALI_PROJECT B
				   WHERE B.ID_PARENT IS NULL AND B.ACTIVE = 1
					 AND B.ID NOT IN (SELECT DISTINCT A.ID_PARENT
							  FROM BALI_PROJECT A
							  WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
				   UNION ALL
				   SELECT E.ID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION
				   FROM BALI_PROJECT E
				   WHERE E.ID IN (SELECT DISTINCT D.ID 
						  FROM BALI_PROJECT D,  
						  BALI_PROJECT C
						  WHERE D.ID_PARENT IS NULL AND C.ACTIVE = 1 AND
							D.ID = C.ID_PARENT)) RESULT, 
			     (SELECT ROWNUM, LEVEL, ID FROM BALI_PROJECT A START WITH ID_PARENT IS NULL AND ACTIVE = 1 CONNECT BY PRIOR ID = ID_PARENT AND ACTIVE = 1) RESULT1 
			     WHERE RESULT.ID = RESULT1.ID
		    ORDER BY ROWNUM ASC";
	    
	    @datas = $db->array_hash( "$SQL" );					 
	}
	
	foreach $data (@datas){
	    
	    push @tree, {
		name => $data->{name},
		description => $data->{description},
		nature => $data->{nature},
		_id => $data->{id},
		_parent => undef,
		_level => $data->{level},
		_num_fila => $data->{rownum},
		_lft => ($data->{rownum} - 1) * 2 + 1,
		_rgt => undef,
		_is_leaf => \$data->{leaf}
	    };
	}
	
	$total_rows = $#tree + 1 ;
	
	if ($id_project eq 'todos'){
	    for(0..$#tree){
		if($_ == $#tree){
		    $tree[$_]->{_rgt} = $tree[$_]->{_lft} + 1;
		}else{
		    $tree[$_]->{_rgt} = $tree[$_+1]->{_lft} - 1;
		}
	    }	    
	}else{
	    $tree[0]->{_lft} = $p->{lft_padre} + 1;
	    $tree[0]->{_rgt} = $p->{hijos_node};
	    for(1..$#tree){
		if($_ == $#tree){
		    $tree[$_]->{_lft} = ($tree[$_]->{_num_fila} - $tree[$_-1]->{_num_fila}) * 2 + $tree[$_-1]->{_lft};  
		    $tree[$_]->{_rgt} = $p->{hijos_node};
		    $tree[$_-1]->{_rgt} = $tree[$_]->{_lft} - 1;
		}else{
		    $tree[$_]->{_lft} = ($tree[$_]->{_num_fila} - $tree[$_-1]->{_num_fila}) * 2 + $tree[$_-1]->{_lft};
		    $tree[$_-1]->{_rgt} = $tree[$_]->{_lft} - 1;
		}
	    }	    
	}	    
    }    

    $c->stash->{json} = {data =>\@tree, success=>\1, total=>$total_rows};
    $c->forward('View::JSON');
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    my $id_project = $p->{id};
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $SQL;
    my @datas;
    
    switch ($action) {
	case 'delete' {
	    try{
		my $row = $c->model('Baseliner::BaliProject')->find( $id_project );
		$row->active(0);
		$row->update();
		
		$SQL = "SELECT ROWNUM, LEVEL, ID, NAME, DESCRIPTION, NATURE FROM BALI_PROJECT A START WITH ID_PARENT = ? AND ACTIVE = 1 CONNECT BY PRIOR ID = ID_PARENT AND ACTIVE = 1";
		@datas = $db->array_hash( "$SQL", $id_project );
		my @ids_projects_hijos = map $_->{id}, @datas;
		
		my $rs = $c->model('Baseliner::BaliProject')->search({ id=>\@ids_projects_hijos});
		$rs->update({ active => 0});
		$c->stash->{json} = {  success => 1, msg=>_loc('Project deleted') };
		
		@ids_projects_hijos = map 'project/' . $_, @ids_projects_hijos;
		push @ids_projects_hijos, 'project/' . $id_project;
		$rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ ns=>\@ids_projects_hijos });
		$rs->delete;		
	    }
	    catch{
		$c->stash->{json} = {  success => 0, msg=>_loc('Error deleting Project') };
	    }
	}
    }
    $c->forward('View::JSON');
}

sub add : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my $name = $p->{name};
    try {
        $name or die "Missing name";
        my $ns = $p->{ns};
        $ns ||= $name;
        $ns = "project/$ns" unless $ns =~ /\//;
        my $row = { name => $name, ns => $ns, description => $p->{description} };
        Baseliner->model('Baseliner::BaliProject')->create( $row );
        $c->stash->{json} = { success=>\1, msg=>'ok' };
    } catch {
        my $err = shift;
        _log $err;
        my $msg = _loc("Error adding project %1: %2", $name, $err);
        $c->stash->{json} = { success=>\1, msg=>$msg };
    };
	$c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/project_grid.js';
}

=head2 all_projects

returns all projects

    include_root => 1     includes the "all prroject" or "/" namespace

=cut
sub all_projects : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'name';
    $dir ||= 'asc';
    $limit ||= 100;
    my $where = {};
    $query and $where = query_sql_build( query=>$query, fields=>[qw/name ns/] );
	my $rs = $c->model('Baseliner::BaliProject')->search($where);
    rs_hashref($rs);
    #my @rows = map { $_->{data}=_load($_->{data}); $_ } $rs->all;
    my @rows = $rs->all;
	$c->stash->{json} = { data => \@rows, totalCount=>scalar(@rows) };		
	$c->forward('View::JSON');
}
sub delete : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my $id = $p->{id};
    try {
        Baseliner->model('Baseliner::BaliProject')->find($id)->delete;
        $c->stash->{json} = { success=>\1, msg=>'Delete Ok' };
    } catch {
        my $err = shift;
        _log $err;
        my $msg = _loc("Error deleting project %1: %2", $id, $err);
        $c->stash->{json} = { success=>\1, msg=>$msg };
    };
	$c->forward('View::JSON');
}

sub show : Local {
    my ( $self, $c, $id ) = @_;
	my $p = $c->request->parameters;
	$id ||= $p->{id};
	my $prj = Baseliner->model('Baseliner::BaliProject')->search({ id=>$id })->first;

    $c->stash->{id} = $id;
    $c->stash->{prj} = $prj;
    $c->stash->{template} = '/site/project/project.html';
}

=head2 user_projects

returns the user project json

    include_root => 1     includes the "all prroject" or "/" namespace

=cut
sub user_projects : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'name';
    $dir ||= 'asc';
    $limit ||= 100;
    $query and $query = qr/$query/i;
    my @rows;
    my $username = $c->username;
    my $perm = $c->model('Permissions');
    #if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
        #$where->{'bali_job_items.application'} = { -in => \@user_apps } if ! ( grep { $_ eq '/'} @user_apps );
        # username can view jobs where the user has access to view the jobcontents corresponding app
        # username can view jobs if it has action.job.view for the job set of job_contents projects/app/subapl
    #}
    @rows =  $perm->user_namespaces( $username ); # user apps
    @rows = grep { $_ ne '/' } @rows unless $c->is_root || $p->{include_root};
    @rows = grep { $_ =~ $query } @rows if $query;
	my $rs = $c->model('Baseliner::BaliProject')->search({ ns=>\@rows });
    rs_hashref($rs);
    @rows = map { $_->{data}=_load($_->{data}); $_ } $rs->all;
	$c->stash->{json} = { data => \@rows, totalCount=>scalar(@rows) };		
	$c->forward('View::JSON');
}

1;
