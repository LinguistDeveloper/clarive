package Baseliner::Controller::User;
use Baseliner::Plug;
use Baseliner::Utils;
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
		      role		=> $r->{role},
		      description	=> $r->{description},
		      projects		=> $projects_txt
		    };
    }
    $c->stash->{json} = { data=>\@rows};		
    $c->forward('View::JSON');    
}

sub infoactions : Local {
    my ($self, $c, $role) = @_;
    $c->stash->{role}  = $role;
    $c->stash->{template} = '/comp/user_infoactions.mas';
}

sub infodetailactions : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $role = $p->{role};
    if( defined $role ) {
        my $r = $c->model('Baseliner::BaliRole')->search({ role=>$role })->first;
        if( $r ) {
            my @actions;
            my $rs_actions = $r->bali_roleactions;
            while( my $ra = $rs_actions->next ) {
                my $desc = $ra->action;
                eval { # it may fail for keys that are not in the registry
                    my $action = $c->model('Registry')->get( $ra->action );
                    $desc = $action->name;
                }; 
                push @actions,{ action=>$ra->action, description=>$desc, bl=>$ra->bl };
            }
            $c->stash->{json} =  { data=>\@actions};
            $c->forward('View::JSON');
        }
    }
}

sub update : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};

            switch ($action) {
                case 'add' {
		    try{
			$c->model('Baseliner::BaliUser')->create({
			    username    => $p->{username},
			    realname  => $p->{realname},
			    alias=> $p->{alias},
			    email=> $p->{email},
			    phone=> $p->{phone}
			    });
			    $c->stash->{json} = { msg=>_loc('User updated'), success=>\1 };
		    }
		    catch{
			$c->stash->{json} = { msg=>_loc('Error updating User: %1', shift()), success=>\1 }
		    }
		}
		case 'edit' { _log 'edit'; }
		case 'delete' { _log 'delete'; }
            }
    $c->forward('View::JSON');
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
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/user_grid.mas';
}
sub can_surrogate : Local {
    my ( $self, $c ) = @_;
    return 0 unless $c->username;
	$c->stash->{can_surrogate} =
		$c->model('Permissions')
			->user_has_action( username=> $c->username, action=>'action.surrogate' );
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
        ? { 'lower(username||realname||alias)' => { -like => "%".lc($query)."%" } } 
        : undef;   
    
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
	    username	=> $r->username,
	    realname	=> $r->realname,
	    alias	=> $r->alias
	  };
    }
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};		
    $c->forward('View::JSON');
}
1;
