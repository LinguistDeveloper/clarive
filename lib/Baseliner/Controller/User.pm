package Baseliner::Controller::User;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Switch;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

register 'config.user.global' => {
    preference=>1,
    desc => 'Global Preferences',
    metadata => [
        { id=>'language', label=>'Language', type=>'combo', default=>Baseliner->config->{default_lang}, store=>['es','en']  },
    ]
};
register 'config.user.view' => {
    preference=>1,
    desc => 'View Preferences',
    metadata => [
        { id=>'theme', label=>'Theme', type=>'combo', default=>Baseliner->config->{default_theme}, store=>['gray','blue','slate']  },
    ]
};
register 'menu.admin.users' => { label => 'Users', url_comp=>'/user/grid', actions=>['action.admin.role'], title=>'Users', index=>80, icon=>'/static/images/icons/user.gif' };
register 'action.maintenance.users' => {
	name => 'User maintenance',
};

sub preferences : Local {
    my ($self, $c) = @_;
    my @config = $c->model('Registry')->search_for(key=>'config', preference=>1 );
    $c->stash->{ns} = 'user/'. ( $c->user->username || $c->user->id );
    $c->stash->{bl} = '*';
    $c->stash->{title} = _loc 'User Preferences';
    if( @config ) {
        $c->stash->{metadata} = [ map { $_->metadata } @config ];
	$c->stash->{ns_query} = { does=>'Baseliner::Role::Namespace::User' }; 
        $c->forward('/config/form_render'); 
    }
}

sub actions : Local {
    my ($self, $c) = @_;

	$c->stash->{username} = $c->username;
	$c->stash->{template} = '/comp/user_actions.mas';
}

sub info : Local {
    my ($self, $c, $username) = @_;
   
    my $u = $c->model('Users')->get( $username );
    if( ref $u ) {
	my $user_data = $u->{data} || {};
	$c->stash->{username}  = $username;
	$c->stash->{realname}  = $u->{realname};
	$c->stash->{alias} = $u->{alias};
	$c->stash->{email}  = $u->{email};
	$c->stash->{phone}  = $u->{phone};	
	
	# Data from LDAP, or other user data providers:
        $c->stash->{$_} ||= $user_data->{$_} for keys %$user_data;
    }
    $c->stash->{template} = '/comp/user_info.mas';
}

sub infodetail : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $username = $p->{username};
    
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'me.role';
    $dir ||= 'asc';

    my @rows;
    my $roles = $c->model('Baseliner::BaliRole')->search(
						    {'bali_roleusers.username' => $username},
						    {
							select=>[qw/id role description/],
							join=>['bali_roleusers'],
							group_by=>[qw/id role description/], 
							order_by=> $sort ? "$sort $dir" : undef
						    }
						);
    rs_hashref($roles);
    
    while( my $r = $roles->next ) {
	my $rs_userprojects = $c->model('Baseliner::BaliRoleUser')->search( { username => $username ,  id_role => $r->{id}} );
	rs_hashref($rs_userprojects);
	my @projects;
	while( my $rs = $rs_userprojects->next ) {
	    my ($ns, $prjid) = split "/", $rs->{ns};
	    my $str;
	    my $parent;
	    my $allpath;
	    my $nature;
	    if($prjid){
		my @path;
		my $project = $c->model('Baseliner::BaliProject')->find($prjid);
		push @path, $project->name;
		$parent = $project->id_parent;
		while($parent){
		    my $projectparent = $c->model('Baseliner::BaliProject')->find($parent);
		    push @path, $projectparent->name . '/';
		    $parent = $projectparent->id_parent;
		}
		while(@path){
		    $allpath .= pop (@path)
		}
		if($project->nature){ $nature= ' (' . $project->nature . ')';}
		$str = $allpath . $nature;
	    }
	    else{
		$str = '';
	    }
	    push @projects, $str;
 	}
	@projects = sort(@projects);
	my @jsonprojects;
	foreach my $project (@projects){
	    my $str = { name=>$project };
	    push @jsonprojects, $str;
	}
        my $projects_txt = \@jsonprojects;

	push @rows,
		    {
		      id_role		=> $r->{id},
		      role		=> $r->{role},
		      description	=> $r->{description},
		      projects		=> $projects_txt
		    };
    }
    $c->stash->{json} = { data=>\@rows};		
    $c->forward('View::JSON');    
}

sub infoactions : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $username = $p->{username};
    my $id_role = $p->{id_role};
    
    my @actions;
    my @datas;
    my $data;
    my $SQL;
    
    if ($id_role) {
	my $rs_actions = $c->model('Baseliner::BaliRoleAction')->search( { id_role => $id_role} );
	while( my $rs = $rs_actions->next ) {
	    my $desc = $rs->action;
	    eval { # it may fail for keys that are not in the registry
		my $action = $c->model('Registry')->get( $rs->action );
		$desc = $action->name;
	    }; 
	    push @actions,{ action=>$rs->action, description=>$desc, bl=>$rs->bl };
	}
    }
    else{
	my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
	
	$SQL = "SELECT ACTION, BL
		FROM BALI_ROLEUSER A, BALI_ROLEACTION B
		WHERE A.USERNAME = ? AND A.ID_ROLE = B.ID_ROLE
		GROUP BY ACTION, BL
		ORDER BY ACTION ASC";
	
	@datas = $db->array_hash( "$SQL" , $username);
	foreach $data (@datas){
	    my $desc = $data->{action};
	    eval { # it may fail for keys that are not in the registry
		my $action = $c->model('Registry')->get( $data->{action} );
		$desc = $action->name;
	    }; 
	    push @actions,{ action=>$data->{action}, description=>$desc, bl=>$data->{bl} };
	}
    }
    
    $c->stash->{json} =  { data=>\@actions};
    $c->forward('View::JSON');   
}

##sub infodetailactions : Local {
##    my ($self, $c) = @_;
##    my $p = $c->request->parameters;
##    my $role = $p->{role};
##
##    if( defined $role ) {
##        my $r = $c->model('Baseliner::BaliRole')->search({ role=>$role })->first;
##        if( $r ) {
##            my @actions;
##            my $rs_actions = $r->bali_roleactions;
##            while( my $ra = $rs_actions->next ) {
##                my $desc = $ra->action;
##                eval { # it may fail for keys that are not in the registry
##                    my $action = $c->model('Registry')->get( $ra->action );
##                    $desc = $action->name;
##                }; 
##                push @actions,{ action=>$ra->action, description=>$desc, bl=>$ra->bl };
##            }
##            $c->stash->{json} =  { data=>\@actions};
##            $c->forward('View::JSON');
##        }
##    }
##}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    my $projects_checked = $p->{projects_checked};
    my $projects_parents_checked = $p->{projects_parents_checked};
    my $roles_checked = $p->{roles_checked};
    my $project;

    switch ($action) {
	case 'add' {
	    try{
		my $row = $c->model('Baseliner::BaliUser')->search({username => $p->{username}, active => 1})->first;
		if(!$row){
		    my $user = $c->model('Baseliner::BaliUser')->create(
							{
							    username    => $p->{username},
							    realname  	=> $p->{realname},
							    alias	=> $p->{alias},
							    email	=> $p->{email},
							    phone	=> $p->{phone}
							});
		
		    $c->stash->{json} = { msg=>_loc('User added'), success=>\1, user_id=> $user->id };
		}else{
		    $c->stash->{json} = { msg=>_loc('User name already exists, introduce another user name'), failure=>\1 };
		}
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error adding User: %1', shift()), failure=>\1 }
	    }
	}
	case 'update' {
	    try{
		my $type_save = $p ->{type};
		if ($type_save eq 'user') {
		    my $user = $c->model('Baseliner::BaliUser')->find( $p->{id} );
		    $user->username( $p->{username} );
		    $user->realname( $p->{realname} );
		    $user->alias( $p->{alias} );
		    $user->email( $p->{email} );
		    $user->phone( $p->{phone} );
		    $user->update();
		}
		else{
		    tratar_proyectos($c, $p->{username}, $roles_checked, $projects_checked);
		    tratar_proyectos_padres($c, $p->{username}, $roles_checked, $projects_parents_checked, 'update');
		}
		$c->stash->{json} = { msg=>_loc('User modified'), success=>\1, user_id=> $p->{id} };
	    }
	    catch{
		$c->stash->{json} = { msg=>_loc('Error modifying User: %1', shift()), failure=>\1 }
	    }
	}
	case 'delete' {
	    try{
		my $SQL;
		my $row = $c->model('Baseliner::BaliUser')->find( $p->{id} );
		$row->active(0);
		$row->update();
		
		my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$p->{username} });
		$rs->delete;
		$c->stash->{json} = {  success => 1, msg=>_loc('User deleted') };
	    }
	    catch{
		$c->stash->{json} = {  success => 0, msg=>_loc('Error deleting User') };
	    }
	}
	case 'delete_roles_projects' {
	    try{
		
		my $user_name = $p->{username};
		my $rs;
		
		if ($roles_checked){
		    foreach my $role (_array $roles_checked){
			if ($projects_checked || $projects_parents_checked){
			    my @ns_projects =
				_unique
				map { $_ eq 'todos'?'/':'project/' . $_ }
				_array $projects_checked;
				
			    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, id_role=>$role, ns=>\@ns_projects });
			    $rs->delete;
			    
			    tratar_proyectos_padres($c, $p->{username}, $roles_checked, $projects_parents_checked, 'delete');
	
			}
			else{
			    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, id_role=>$role });
			    $rs->delete;
			}
		    }		    
		}
		else{
			my @ns_projects =
			    _unique
			    map { $_ eq 'todos'?'/':'project/' . $_ }
			    _array $projects_checked;
			    
			my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, ns=>\@ns_projects });
			$rs->delete;
			
			tratar_proyectos_padres($c, $p->{username}, $roles_checked, $projects_parents_checked, 'delete');
		}
		$c->stash->{json} = { msg=>_loc('User modified'), success=>\1};
	    }
	    catch{
		$c->stash->{json} = {  success => 0, msg=>_loc('Error modifying User: %1', shift()) };
	    }
	}
    }
    $c->forward('View::JSON');
}

sub tratar_proyectos{
    my $c = shift;
    my $user_name = shift;
    my $roles_checked = shift;
    my $projects_checked = shift;
    my $role;
    my $project;
    my $rs;
    my @roles_checked;

    if(!$roles_checked){
        my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
        my $dbh = $db->dbh;
        my $sth = $dbh->prepare("SELECT DISTINCT ID_ROLE FROM BALI_ROLEUSER WHERE USERNAME = ? ");
	$sth->bind_param( 1, $user_name );
	$sth->execute();
	@roles_checked = map { $_->[0] } _array $sth->fetchall_arrayref;
    }
    else{
	foreach $role (_array $roles_checked){
	    push @roles_checked, $role;
	}
    }

    foreach $role ( @roles_checked ){
	foreach $project (_array $projects_checked){
	    if ($project eq 'todos'){
		my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, id_role=>$role });
		$rs->delete;
		my $role_user = $c->model('Baseliner::BaliRoleUser')->find_or_create(
								    {	username => $user_name,
									    id_role => $role,
									    ns => '/'
								    },
								    { key => 'primary' });
		$role_user->update();
		last				
	    }else{
		my $all_projects = $c->model('Baseliner::BaliRoleUser')->find(	{username => $user_name,
										 id_role => $role,
										 ns => '/'
										},
										{ key => 'primary' });
		if($all_projects){
		    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, id_role=>$role, ns=>'/'});
		    $rs->delete;
		}
		
		my $role_user = $c->model('Baseliner::BaliRoleUser')->find_or_create(
								    {	username => $user_name,
									id_role => $role,
									ns => 'project/' . $project
								    },
								    { key => 'primary' });
		$role_user->update();
	    }
	}
    }
}

sub tratar_proyectos_padres(){
    my $c = shift;
    my $user_name = shift;
    my $roles_checked = shift;
    my $projects_parents_checked = shift;
    my $accion = shift;
    
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $dbh = $db->dbh;
    my $sth = $dbh->prepare("SELECT ID FROM BALI_PROJECT START WITH ID = ? CONNECT BY PRIOR ID = ID_PARENT");
		   
    switch ($accion) {
	case 'update' {
	    my @roles_checked;
	    if(!$roles_checked){
		my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
		my $dbh = $db->dbh;
		my $sth = $dbh->prepare("SELECT DISTINCT ID_ROLE FROM BALI_ROLEUSER WHERE USERNAME = ? ");
		$sth->bind_param( 1, $user_name );
		$sth->execute();
		@roles_checked = map { $_->[0] } _array $sth->fetchall_arrayref;
	    }
	    else{
		foreach my $role (_array $roles_checked){
		    push @roles_checked, $role;
		}
	    }
	    foreach my $role ( @roles_checked){
		my $all_projects = $c->model('Baseliner::BaliRoleUser')->find(
								{username => $user_name,
								 id_role => $role,
								 ns => '/'
								},
								{ key => 'primary' });
		if(!$all_projects){
		    foreach my $project (_array $projects_parents_checked){
			$sth->bind_param( 1, $project );
			$sth->execute();
			while(my @row = $sth->fetchrow_array){
			    my $role_user = $c->model('Baseliner::BaliRoleUser')->find_or_create(
								       {
									username => $user_name,
									id_role => $role,
									ns => 'project/' . $row[0]
								       },
								       { key => 'primary' });
			    $role_user->update();
			}
		   }
		}
		
	    }
	}
	case 'delete' {
	    my $rs;
	    if($roles_checked){
		foreach my $role (_array $roles_checked){
		    foreach my $project (_array $projects_parents_checked){
			$sth->bind_param( 1, $project );
			$sth->execute();
			my @ns_projects = _unique
					  map { 'project/' . $_->[0] }
					  _array $sth->fetchall_arrayref;
					  
			$rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, id_role=>$role, ns=>\@ns_projects });
			$rs->delete;
		    }
		}
	    }
	    else{
		foreach my $project (_array $projects_parents_checked){
		    $sth->bind_param( 1, $project );
		    $sth->execute();
		    my @ns_projects = _unique
				      map { 'project/' . $_->[0] }
				      _array $sth->fetchall_arrayref;
				      
		    $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username=>$user_name, ns=>\@ns_projects });
		    $rs->delete;
		}
	    }
	}
    }
}

sub actions_list : Local {
    my ($self, $c) = @_;

	my @data;
	for my $role ( $c->model('Permissions')->user_roles( $c->username ) ) {
		for my $action ( _array $role->{actions} ) {
			push @data, {  role=>$role->{role}, description=>$role->{description}, ns=>$role->{ns}, action=>$action };
		}
	}
	$c->stash->{json} = { data=>\@data, totalCount => scalar( @data ) };
	$c->forward('View::JSON');
}

=head2 application_json

List the user applications (projects)

=cut
sub application_json : Local {
    my ($self, $c) = @_;
	my $p = $c->request->parameters;
	my @rows;
	my $mask = $p->{mask};
    my $query = $p->{query};
    $query and $query =~ s{\s+}{.*}g;  # convert query in regex

	foreach my $ns ( Baseliner->model('Permissions')->user_namespaces( $c->username ) ) {
        my ($domain, $item ) = ns_split( $ns );
        next unless $item;
        next unless $domain =~ /application/;
        next if $query && $item !~ m/$query/i;
		next if $mask && $item !~ m/$mask/i;
		push @rows, {
			name => $item,
			ns => $ns
		};
	}
	$c->stash->{json} = { 
		totalCount => scalar @rows,
		data => \@rows
	};	
	$c->forward('View::JSON');
}

=head2 project_json

List the user applications (projects)

=cut
sub project_json : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my @rows;
    my $mask = $p->{mask};
    my $query = $p->{query};
    $query and $query =~ s{\s+}{.*}g;  # convert query in regex

    foreach my $ns ( Baseliner->model('Permissions')->user_namespaces( $c->username ) ) {
        my ($domain, $item ) = ns_split( $ns );
        next unless $item;
        next unless $domain =~ /application/;
        next if $query && $item !~ m/$query/i;
        next if $mask && $item !~ m/$mask/i;
        push @rows, {
            name => $item,
            ns => $ns
        };
    }
    $c->stash->{json} = { 
        totalCount => scalar @rows,
        data => \@rows
    };  
    $c->forward('View::JSON');
}

sub application_json_old : Local {
    my ($self, $c) = @_;
	my $p = $c->request->parameters;
	my @rows;
	my $mask = $p->{mask};
	my @ns_list = $c->model('Namespaces')->list(
		does => 'Baseliner::Role::Namespace::Application',
		username=> $c->username,
	);
	foreach my $ns ( @ns_list ) {
		next if $mask && $ns->{ns_name} !~ m/$mask/i;
		if( $p->{mask} ) {
		}
		push @rows, {
			name => $ns->{ns_name},
			ns => $ns->{ns}
		};
	}
	$c->stash->{json} = { 
		totalCount => scalar @rows,
		data => \@rows
	};	
	$c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;
	#$c->forward('/namespace/load_namespaces');
    $c->forward('/user/can_surrogate');
    $c->forward('/user/can_maintenance');
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/user_grid.mas';
}

sub can_surrogate : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
    $c->stash->{can_surrogate} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.surrogate' );
}

sub can_maintenance : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
    $c->stash->{can_maintenance} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.maintenance.users' );
}

sub projects_list : Local {
    my ($self,$c) = @_;
    my $id = $c->req->params->{node};
    my $project = $c->req->params->{project} ;
    my $id_project = $c->req->params->{id_project} ;
    my $parent_checked = $c->req->params->{parent_checked} || 0 ;
   
    my @tree;
    my $rsprojects;
    my $rsprojects_parent;
   
    my @datas;
    my $data;
    my $SQL;
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );

    if($id_project && $id_project ne 'todos'){
	$SQL = "SELECT B.ID, B.NAME, 1 AS LEAF, B.NATURE 
				 FROM BALI_PROJECT B
				 WHERE B.ID_PARENT = ?
				 AND B.ID NOT IN (SELECT DISTINCT A.ID_PARENT
						  FROM BALI_PROJECT A
						  WHERE A.ID_PARENT IS NOT NULL) 
				 UNION
				 SELECT DISTINCT D.ID, D.NAME, 0 AS LEAF, D.NATURE
				 FROM BALI_PROJECT D,  
				 BALI_PROJECT C
				 WHERE D.ID_PARENT = ? AND
				 D.ID = C.ID_PARENT";
	
	@datas = $db->array_hash( "$SQL" , $id_project, $id_project);					 
    }
    else{
	$SQL = "SELECT B.ID, B.NAME, 1 AS LEAF, B.NATURE 
					 FROM BALI_PROJECT B
					 WHERE B.ID_PARENT IS NULL
					 AND B.ID NOT IN (SELECT DISTINCT A.ID_PARENT
							  FROM BALI_PROJECT A
							  WHERE A.ID_PARENT IS NOT NULL) 
					 UNION
					 SELECT DISTINCT D.ID, D.NAME, 0 AS LEAF, D.NATURE
					 FROM BALI_PROJECT D,  
					 BALI_PROJECT C
					 WHERE D.ID_PARENT IS NULL AND
					 D.ID = C.ID_PARENT";
	
	@datas = $db->array_hash( "$SQL" );					 
    }
    
    my $nature;
    
    foreach $data(@datas){
	if($data->{nature}){
	    $nature = " ($data->{nature})";
	}
	else{
	    $nature = "";
	}
        push @tree, {
            text       => $data->{name} . $nature,
            url        => 'user/projects_list',
            data       => {
                id_project => $data->{id},
                project    => $data->{name},
		parent_checked => 0,
            },	    
            icon       => '/static/images/icons/project.gif',
            leaf       => \$data->{leaf},
	    checked    => \$parent_checked
        };	
    }
    
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'me.username';
    $dir ||= 'asc';
    $start||= 0;
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    
    
    my $where = $query
        ? { 'lower(username||realname||alias)' => { -like => "%".lc($query)."%" }, active => 1 }
        : { active => 1 };   
    
    my $rs = $c->model('Baseliner::BaliUser')->search(
	$where,
	{ page => $page,
	  rows => $limit,
	  order_by => $sort ? "$sort $dir" : undef
	}
    );
	
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;	
	
    my @rows;
    while( my $r = $rs->next ) {
    # produce the grid
	push @rows,
	  {
	    id 		=> $r->id,
	    username	=> $r->username,
	    realname	=> $r->realname,
	    alias	=> $r->alias,
	    email	=> $r->email,
	    phone	=> $r->phone
	  };
    }
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};		
    $c->forward('View::JSON');
}
1;
