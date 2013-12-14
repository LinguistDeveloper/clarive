package Baseliner::Controller::User;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

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
register 'menu.admin.users' => { label => 'Users',
    url_comp=>'/comp/user_main.js', actions=>['action.admin.role'],
    title=>'Users', index=>80, icon=>'/static/images/icons/user.gif' };
register 'action.admin.users' => {
    name => 'User Admin',
};

register 'event.user.create' => {
    text => 'New user created: %2',
    description => 'User posted a comment',
    vars => ['username', 'realname', 'email']
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
    my ( $self, $c, $username ) = @_;
    $c->stash->{swAsistentePermisos} = 0;

    if ( $username eq '' ) {
        $username = $c->username;
        $c->stash->{swAsistentePermisos} = 1;
    }

    my $u = $c->model('Users')->get($username);
    if ( ref $u ) {
        my $user_data = $u->{data} || {};
        $c->stash->{username} = $username;
        $c->stash->{realname} = $u->{realname};
        $c->stash->{alias}    = $u->{alias};
        $c->stash->{email}    = $u->{email};
        $c->stash->{phone}    = $u->{phone};

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
        { 'bali_roleusers.username' => $username },
        {   select   => [qw/id role description/],
            join     => ['bali_roleusers'],
            group_by => [qw/id role description/],
            order_by => $sort ? { "-$dir" => "$sort" } : undef
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
                if($project){
                    push @path, $project->name;
                    $parent = $project->id_parent;
                    while($parent){
                        my $projectparent = $c->model('Baseliner::BaliProject')->find($parent);
                        push @path, $projectparent->name . '/';
                        $parent = $projectparent->id_parent;
                    }
                    while(_unique @path){
                        $allpath .= pop (@path)
                    }
                    if($project->nature){ $nature= ' (' . $project->nature . ')';}
                    $str = $allpath . $nature;
                }
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
                  id      	    => $r->{id},
                  id_role		=> $r->{id},
                  role		    => $r->{role},
                  description	=> $r->{description},
                  projects		=> $projects_txt
                };
    }
    $c->stash->{json} = { data=>\@rows};		
    $c->forward('View::JSON');    
}

sub user_data : Local {
    my ($self, $c) = @_;
    try {
        my $user = DB->BaliUser->search({ username => $c->username })->first;
        _fail _loc('User not found: %1', $c->username ) unless $user;
        $c->stash->{json} = { data=>{ $user->get_columns }, msg=>'ok', success=>\1 };
    } catch {
        my $err = shift;
        $c->stash->{json} = { msg=>"$err", success=>\0 };
    };
    $c->forward('View::JSON');    
}

sub user_info : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $username = $p->{username};

    try {
        if ( !$username ) {
            _fail _loc('Missing parameter username');
        }
        my $user = DB->BaliUser->search({ username => $username }, {select=>[qw(username active realname alias email active phone mid)]})->first;
        _fail _loc('User not found: %1', $c->username ) unless $user;
        $c->stash->{json} = { $user->get_columns, msg=>'ok', success=>\1 };
    } catch {
        my $err = shift;
        $c->stash->{json} = { msg=>"$err", success=>\0 };
    };
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

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my $action = $p->{action};
    my $projects_checked = $p->{projects_checked};
    my $projects_parents_checked = $p->{projects_parents_checked};
    my $roles_checked = $p->{roles_checked};
    my $project;
    
    given ($action) {
    when ('add') {
        try{
            my $swOk = 1;
            my $row = $c->model('Baseliner::BaliUser')->search({username => $p->{username}, active => 1})->first;
            if(!$row){
                my $user_mid;
               
                my $ci_data = {
                    name 		=> $p->{username},
                    bl 			=> '*',
                    username	=> $p->{username},
                    realname  	=> $p->{realname},
                    alias       => $p->{alias},
                    email     	=> $p->{email},
                    phone      	=> $p->{phone},            
                    active 		=> '1',
                    password    => BaselinerX::CI::user->encrypt_password( $p->{username}, $p->{pass} )
                };           
                
                my $ci = BaselinerX::CI::user->new( %$ci_data );
                $user_mid = $ci->save;
                $c->stash->{json} = { msg=>_loc('User added'), success=>\1, user_id=> $user_mid };
                
            }else{
                $c->stash->{json} = { msg=>_loc('User name already exists, introduce another user name'), failure=>\1 };
            }
        }
        catch{
            $c->stash->{json} = { msg=>_loc('Error adding User: %1', shift()), failure=>\1 }
        }
    }
    when ('update') {
        try{
            my $type_save = $p ->{type};
            if ($type_save eq 'user') {
                my $user;
                my $user_id = $p->{id};
                if ( $p->{id} ) {
                    $user = $c->model('Baseliner::BaliUser')->find( $p->{id} );
                } else {
                    $user = $c->model('Baseliner::BaliUser')->search( { username => $p->{username} } )->first;
                    _fail _loc("User not found") if !$user;
                    $user_id = $user->id;
                }
                my $old_username = $user->username;
                if ($old_username ne $p->{username}){
                    my $row = $c->model('Baseliner::BaliUser')->search({username => $p->{username}, active => 1})->first;
                    if ($row) {
                        $c->stash->{json} = { msg=>_loc('User name already exists, introduce another user name'), failure=>\1 };    
                    }else{
                        my $user_mid;
                        my $user_new;
                        $user_mid = master_new 'user' => $p->{username} => sub {
                            my $mid = shift;
                            
                            $user_new = Baseliner->model('Baseliner::BaliUser')->create(
                                {
                                    mid			=> $mid,
                                    username    => $p->{username},
                                    realname  	=> $p->{realname},
                                    password	=> BaselinerX::CI::user->encrypt_password( $p->{username}, $p->{pass} ),
                                    alias	=> $p->{alias},
                                    email	=> $p->{email},
                                    phone	=> $p->{phone},
                                    active  => '1'
                                }
                            );
                        };
                        ##BaliRoleUser
                        my $rs_role_user = $c->model('Baseliner::BaliRoleUser')->search({username => $old_username });
                        $rs_role_user->update( {username => $p->{username}} );
                        ##BaliMasterRel
                        my $user_from = $c->model('Baseliner::BaliMasterRel')->search( {from_mid => $p->{id}} );
                        if ($user_from) {
                            $user_from->update( {from_mid => $user_new->mid} );
                        }
                        my $user_to = $c->model('Baseliner::BaliMasterRel')->search( {to_mid => $p->{id}} );
                        if ($user_to){
                            $user_to->update( {to_mid => $user_new->mid} );    
                        }
                        ##Borramos el antiguo
                        $user->delete();
                    }
                }
                else{
                    $user->realname( $p->{realname} ) if $p->{realname};
                    if( $p->{pass} ){
                        $user->password( BaselinerX::CI::user->encrypt_password( $p->{username}, $p->{pass} ));
                    }
                    $user->alias( $p->{alias} ) if $p->{alias};
                    $user->email( $p->{email} ) if $p->{email};
                    $user->phone( $p->{phone} ) if $p->{phone};                 
                    $user->phone( $p->{active} ) if $p->{active};                 
                    $user->update();                    
                }
                
                $c->stash->{json} = { msg=>_loc('User modified'), success=>\1, user_id=> $user_id };
            }
            else {
                tratar_proyectos($c, $p->{username}, $roles_checked, $projects_checked);
                tratar_proyectos_padres($c, $p->{username}, $roles_checked, $projects_parents_checked, 'update');
                $c->stash->{json} = { msg=>_loc('User modified'), success=>\1, user_id=> $p->{id} };
            }
        }
        catch{
            $c->stash->{json} = { msg=>_loc('Error modifying User: %1', shift()), failure=>\1 }
        }
    }
    when ( 'delete' ) {
        try {
            my $user;
            my $user_id = $p->{id};
            if ( $p->{id} ) {
                $user = $c->model( 'Baseliner::BaliUser' )->find( $p->{id} );
            } else {
                $user =
                    $c->model( 'Baseliner::BaliUser' )->search( {username => $p->{username}} )
                    ->first;
                _fail _loc( "User not found" ) if !$user;
                $user_id = $user->id;
            } ## end else [ if ( $p->{id} ) ]
            $user->active( 0 );
            $user->update();

            my $rs =
                Baseliner->model( 'Baseliner::BaliRoleuser' )
                ->search( {username => $p->{username}} );
            $rs->delete;
            $c->stash->{json} = {success => \1, msg => _loc( 'User deleted' )};
        } ## end try
        catch {
            $c->stash->{json} = {
                failure => \1, msg => _loc( 'Error deleting User: %1', shift() )
            };
        }
    } ## end when ( 'delete' )
    when ('delete_roles_projects') {
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
    Baseliner->cache_remove(qr/:$p->{username}:/);

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
                                                ns => '/',
                                                id_project => undef,
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
                                            ns => 'project/' . $project,
                                            id_project => $project,
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
    my $sth;
    
    if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
        $sth = $dbh->prepare("SELECT MID FROM BALI_PROJECT START WITH MID = ? AND ACTIVE = 1 CONNECT BY PRIOR MID = ID_PARENT AND ACTIVE = 1");
    }
    else{
        ##INSTRUCCION PARA COMPATIBILIDAD CON SQL SERVER ###############################################################################
        $sth = $dbh->prepare("WITH N(MID) AS (SELECT MID FROM BALI_PROJECT WHERE MID = ? AND ACTIVE = 1
                            UNION ALL
                            SELECT NPLUS1.MID FROM BALI_PROJECT AS NPLUS1, N WHERE N.MID = NPLUS1.ID_PARENT AND ACTIVE = 1)
                            SELECT N.MID FROM N ");
    }
    
    given ($accion) {
        when ('update') {
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
                                                    ns => 'project/' . $row[0],
													id_project => $row[0],
                                                       },
                                                       { key => 'primary' });
                                $role_user->update();
                            }
                    }
                }
            
            }
        }
        when ('delete') {
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
    $c->stash->{template} = '/comp/user_grid.js';
}

sub can_surrogate : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
    $c->stash->{can_surrogate} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.surrogate' );
}

sub can_maintenance : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
    $c->stash->{can_maintenance} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.admin.users' );
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

    if($id_project ne 'todos'){
    $SQL = "SELECT * FROM (SELECT B.MID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION
                   FROM BALI_PROJECT B
                   WHERE B.ID_PARENT = ? AND B.ACTIVE = 1
                                     AND B.MID NOT IN (SELECT DISTINCT A.ID_PARENT
                                                      FROM BALI_PROJECT A
                                                      WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
                               UNION ALL
                               SELECT E.MID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION
                               FROM BALI_PROJECT E
                               WHERE E.MID IN (SELECT DISTINCT D.MID 
                                              FROM BALI_PROJECT D,  
                                              BALI_PROJECT C
                                              WHERE D.ID_PARENT = ? AND C.ACTIVE = 1 AND
                                                    D.MID = C.ID_PARENT)) RESULT
           ORDER BY NAME ASC";
    @datas = $db->array_hash( "$SQL" , $id_project, $id_project);					 
    }
    else{
    $SQL = "SELECT * FROM (SELECT B.MID, B.NAME, 1 AS LEAF, B.NATURE, B.DESCRIPTION
                   FROM BALI_PROJECT B
                   WHERE B.ID_PARENT IS NULL AND B.ACTIVE = 1
                                     AND B.MID NOT IN (SELECT DISTINCT A.ID_PARENT
                                                      FROM BALI_PROJECT A
                                                      WHERE A.ID_PARENT IS NOT NULL AND A.ACTIVE = 1) 
                               UNION ALL
                               SELECT E.MID, E.NAME, 0 AS LEAF, E.NATURE, E.DESCRIPTION
                               FROM BALI_PROJECT E
                               WHERE E.MID IN (SELECT DISTINCT D.MID 
                                              FROM BALI_PROJECT D,  
                                              BALI_PROJECT C
                                              WHERE D.ID_PARENT IS NULL AND C.ACTIVE = 1 AND
                                                    D.MID = C.ID_PARENT)) RESULT
           ORDER BY NAME ASC";
    
    @datas = $db->array_hash( "$SQL" );					 
    }

    foreach $data(@datas){


    push @tree, {
        text        => $data->{name} . ($data->{nature}?" (" . $data->{nature} . ")":''),
        nature	=> $data->{nature}?$data->{nature}:"",
        description => $data->{description}?$data->{description}:"",
        url         => 'user/projects_list',
        data        => {
            id_project => $data->{mid},
            project    => $data->{name},
            parent_checked => 0,
        },	    
        icon       => ci->new($data->{mid})->icon,
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
    
    
    my $where={};
    $query and $where = query_sql_build( query=>$query, fields=>[qw(username realname alias)] );

    $where->{active} = 1 if $p->{active_only};
	
	$where->{mid} = {'!=', undef};

    my $rs = DB->BaliUser->search(
        $where,
        { page => $page,
          rows => $limit,
          select=>[qw(username realname alias email active phone mid)],
		  as=>[qw(username realname alias email active phone mid)],
          distinct => 1,
          order_by => $sort ? { "-$dir" => $sort } : undef
        }
    );

    # my %userdata = DB->BaliRoleuser->search(
    #         { username=>{ -in => $rs->as_query } },
    #         { prefetch=>['role'] })->hash_on( 'username' );
    
    my $pager = $rs->pager;
    $cnt = $pager->total_entries;	
    
    #my @rows = map {
    #    $_
    #} $rs->hashref->all;
	
    my @rows = map {
		+{ id => $_->{mid}, %{$_}};
    } $rs->hashref->all;	

    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};		
    $c->forward('View::JSON');
}

sub list_all : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'username';
    $dir ||= 'asc';
    $start||= 0;
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    
    
    my $where={};
    $query and $where = query_sql_build( query=>$query, fields=>[qw( me.username role.description realname alias projects.name email actions.action)] );

    $where->{active} = 1 if $p->{active_only};

    my $rs = DB->BaliUser->search(
        $where,
        { 
          page => $page,
          rows => $limit,
          +select => [ qw( me.username me.mid me.realname me.email me.alias me.active role.role role.description actions.action projects.name ) ],
          +as => [ qw( username mid realname email alias active role role_desc action project ) ],
          join => [ { 'roles' => ['role', 'actions','projects'] } ],
          order_by => [ { "-$dir" => "me.$sort" } , { -asc=>'role' }, { -asc=>'project' } ] 
        }
    );

   my $id = 1;
    my @rows = map { 
        $_->{project} ||= _loc('(all projects)');
        $_->{id} = $id++;
        $_;
    } $rs->hashref->all;
    $c->stash->{json} = { data=>\@rows, totalCount=>try { $rs->pager->total_entries } catch { scalar @rows } };		
    $c->forward('View::JSON');
}

sub change_pass : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $username = lc $c->username;

    my $row = $c->model('Baseliner::BaliUser')->search({username => $username, active => 1})->first;
    
    if ($row) {
        if ( BaselinerX::CI::user->encrypt_password( $username, $p->{oldpass} ) eq $row->password ) {
            if ( $p->{newpass} ) {
                $row->password( BaselinerX::CI::user->encrypt_password( $username, $p->{newpass} ) );
                $row->update();
                $c->stash->{json} = { msg => _loc('Password changed'), success => \1 };
            } else {
                $c->stash->{json} = { msg => _loc('You must introduce a new password'), failure => \1 };
            }
        } else {
            $c->stash->{json} = { msg => _loc('Password incorrect'), failure => \1 };
        }
    } else {
        $c->stash->{json} = { msg => _loc( 'Error changing Password %1', shift() ), failure => \1 };
    }

    $c->forward('View::JSON');
}

sub avatar : Local {
    my ( $self, $c, $username, $dummy_filename ) = @_;
    my ($file, $body, $filename, $extension);
    if( ! $dummy_filename ) {
        $dummy_filename = $username;
        $username = $c->username; 
    }
    $filename = "$username.png";
    try {
        $file = _dir( $c->path_to( "/root/identicon" ) );
        $file->mkpath unless -d $file;
        $file = _file( $file, $username . ".png");
        unless( -e $file ) {   # generate identicon
            my $png = $self->identicon($c, $username);
            my $fh = $file->openw or _fail $!;
            binmode $fh;
            print $fh $png;
            close $fh;
        }
    } catch {
        my $err = shift;
        _log "Identicon failed: $err";
        $file = $c->path_to( "/root/static/images/icons/user.png" );
    };
    if( defined $file ) {
        $c->serve_static_file( $file );
    } 
    elsif( defined $body ) {
        $c->res->body( $body );
    }
    else {
        _throw 'Missing serve_file or serve_body on stash';
    }
    #$c->res->headers->remove_header('Cache-Control');
    #$c->res->header('Content-Disposition', qq[attachment; filename=$filename]);
    #$c->res->headers->remove_header('Pragma');
    $c->res->content_type('image/png');
}

sub avatar_refresh : Local {
    my ( $self, $c ) = @_;
    my $p      = $c->req->params;
    try {
        my $avatar = _file( $c->path_to( "/root/identicon" ), $c->username . '.png' );
        unlink $avatar or _fail $!;
        $c->stash->{ json } = { success => \1, msg => _loc( 'Avatar refreshed' ) } ;            
    } catch {
        my $err = shift;
        _error "Error refreshing avatar: " . $err;
        $c->stash->{ json } = { success => \0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub avatar_upload : Local {
    my ( $self, $c ) = @_;
    my $p      = $c->req->params;
    my $filename = $p->{qqfile};
    my ($extension) =  $filename =~ /\.(\S+)$/;
    $extension //= '';
    my $f =  _file( $c->req->body );
    _log "Uploading avatar " . $filename;
    try {
        require File::Copy;
        my $avatar = _file( $c->path_to( "/root/identicon" ), $c->username . '.png' );
        _debug "Avatar file=$avatar";
        File::Copy::copy( "$f", "$avatar" ); 
        $c->stash->{ json } = { success => \1, msg => _loc( 'Changed user avatar' ) } ;            
    } catch {
        my $err = shift;
        _error "Error uploading avatar: " . $err;
        $c->stash->{ json } = { success => \0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub identicon {
    my ($self, $c, $username)=@_;
    my $user = $c->model('Baseliner::BaliUser')->search({ username=>$username })->first;
    my $generate = sub {
            # generate png identicon from random
            require Image::Identicon;
            my $salt = '1234';
            my $identicon = Image::Identicon->new({ salt=>$salt });
            my $image = $identicon->render({ code=> int(rand( 2 ** 32)), size=>32 });
            return $image->{image}->png;
    };
    if( ref $user ) {
        if( length $user->avatar ) {
            _debug "Avatar from db";
            return $user->avatar;
        } else {
            _debug "Generating and saving avatar";
            my $png = try { 
                $generate->();
            } catch {
                my $user_png = $c->path_to( "/root/static/images/icons/user.png");
                $user_png->slurp;
            };
            # save to user
            $user->avatar( $png );
            $user->update;
            return $png;
        }
    }
    else {
        _debug "User not found, avatar generated anyway";
        return $generate->();
    }
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try{
        my $r = $c->model('Baseliner::BaliUser')->find({ mid => $p->{id_user} });
        if( $r ){
            my $user;
            my $new_user;
            # my $user_mid = master_new 'user' => 'Duplicate of ' . $r->username => sub {
            #     my $mid = shift;
            #     $new_user = $r->username . '-' . $mid;
            #     $user = Baseliner->model('Baseliner::BaliUser')->create(
            #         {
            #             mid			=> $mid,
            #             username    => $new_user,
            #         }
            #     );
            # };

            my $row;
            my $cont = 2;
            $new_user = "Duplicate of ".$r->username;
            $row = $c->model('Baseliner::BaliUser')->search({username => $new_user, active => 1})->first;
            while ($row) {
                $new_user = "Duplicate of ".$r->username." ".$cont++;
                $row = $c->model('Baseliner::BaliUser')->search({username => $new_user, active => 1})->first;                
            }
            if(!$row){
                my $user_mid;
               
                my $ci_data = {
                    name        => $new_user,
                    bl          => '*',
                    username    => $new_user,
                    realname    => $r->realname,
                    alias       => $r->alias,
                    email       => $r->email,
                    phone       => $r->phone,            
                    active      => '1',
                };           
                
                my $ci = BaselinerX::CI::user->new( %$ci_data );
                $user_mid = $ci->save;
                $c->stash->{json} = { msg=>_loc('User added'), success=>\1, user_id=> $user_mid };

                my @rs_roles =  $c->model('Baseliner::BaliRoleUser')->search({ username => $r->username })->hashref->all;
                for (@rs_roles){
                    Baseliner->model('Baseliner::BaliRoleUser')->create(
                        {
                            username    => $new_user,
                            id_role     => $_->{id_role},
                            ns          => $_->{ns},
                            id_project  => $_->{id_project},
                        }
                    );
                }
            }
        }
        $c->stash->{json} = { success => \1, msg => _loc("User duplicated") };  
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error duplicating user') };
    };

    $c->forward('View::JSON');  
}

1;
