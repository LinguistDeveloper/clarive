package Baseliner::Controller::User;
use Baseliner::Plug;
use Baseliner::Utils;
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
        $c->stash->{$_} = $user_data->{$_} for keys %$user_data;
	}
	$c->stash->{template} = '/comp/user_info.mas';
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
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    my $where = $query
        ? { 'lower(me.username||role||description||ns||realname)' => { -like => "%".lc($query)."%" } } 
        : undef;
	my $rs = $c->model('Baseliner::BaliRoleuser')->search(
       $where,
    {
        prefetch => ['role','bali_user'],
		join => ['bali_user'],
        page => $page,
        rows => $limit,
        order_by => $sort ? "$sort $dir" : undef
    });
	my @rows;
	while( my $r = $rs->next ) {
        # produce the grid
        #my $rs_roles = $r->roles;
        my $role = $r->role;
		my $realname = $r->bali_user->realname;
        #while( my $ro = $rs_roles->next ) {
            #my $role = $ro->role;
            #my $ns = $ro->ns;
            push @rows,
              {
                id          => $cnt++,
                username    => $r->username,
				realname    => $realname,
                role        => $role->name . "(" . $role->description . ")",
                ns          => $r->ns,
              };
        #}
    }
	$c->stash->{json} = { data=>\@rows, totalCount=>scalar(@rows) };		
	$c->forward('View::JSON');
}
1;
