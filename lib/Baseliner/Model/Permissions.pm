package Baseliner::Model::Permissions;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Data::Dumper;
use Baseliner::Sugar;

=head1 NAME

Baseliner::Model::Permissions - Role and action management

=head1 DESCRIPTION

This module has several utilities to manage users' actions and roles. 

=head1 ACTIONS

=head2 action.admin.root

This is the master action that allows a user to do anything in the system.

=cut

register 'action.admin.root' => { name=>'Root action - can do anything' };

=head1 METHODS

=head2 create_role $name, $description

Creates a Role

=cut
sub create_role {
    my ($self, $name, $description ) = @_;

    $description ||= _loc( 'The %1 role', $name );

    my $role = Baseliner->model('Baseliner::BaliRole')->find_or_create({ role=>$name });
    $role->description( $description );
    $role->update;
    return $role;
}

=head2 role_exists $role_name

Returns a role row or undef if it doesn't exist.

=cut
sub role_exists {
    my ($self, $role_name ) = @_;
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    return ref $role;
}

=head2 add_action $action, $role_name

Adds an action to a role.

=cut
sub add_action {
    my ($self, $action, $role_name, %p ) = @_;
    my $bl = $p{bl} || '*';
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    if( ref $role ) {
        my $actions = $role->bali_roleactions->search({ action=>$action })->first;
        if( ref $actions ) {
            die _loc( 'Action %1 already belongs to role %2', $action, $role_name );
        } else {
            return $role->bali_roleactions->create({ action => $action, bl=>$bl });
        }
    } else {
        die _loc( 'Role %1 not found', $role_name );
    }
}

=head2 remove_action $action, $role_name

Removes an action from a role.

=cut
sub remove_action {
    my ($self, $action, $role_name, %p ) = @_;
    my $bl = $p{bl} || '*';
    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$role_name })->first;
    if( ref $role ) {
        my $actions = $role->bali_roleactions->search({ action=>$action })->delete;
    } else {
        die _loc( 'Role %1 not found', $role_name );
    }
}

=head2 delete_role [ id=>Int or role=>Str ]

Deletes a role by role id or by role name.

=cut
sub delete_role {
    my ( $self, %p ) = @_;
    
    if( $p{id} ) {
        my $role = Baseliner->model('Baseliner::BaliRole')->find({ id=>$p{id} });

        die _loc( 'Role with id "%1" not found', $p{id} ) unless ref $role;

        my $role_name = $role->role;
        $role->delete;
        return $role_name;
    } else {
        my @role_names;
        my $roles = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} });
        unless( ref $roles ) {
            die _loc( 'Role with id "%1" or name "%2" not found', $p{id}, $p{role} );
        } else {
            while( my $role = $roles->next ) {
                push @role_names, $role->role;
                $role->delete;
            }
        }
        return @role_names;
    }
}

=head2 grant_role username=>Str, role=>Str, [ ns=>Str, bl=>Str ]

Grants a role to a user. Optionally for a given project (ns). 

=cut
sub grant_role {
    my ($self, %p ) = @_;

    $p{ns} ||= '/';
    $p{bl} ||= '*';  #TODO not used here

    my $role = Baseliner->model('Baseliner::BaliRole')->search({ role=>$p{role} })->first;
    unless( ref $role ) {
        $role = $self->create_role( $p{role} )
          or die "Could not create role '$p{role}'";
    } 

    # search 
    my $row = Baseliner->model('Baseliner::BaliRoleuser')->search({
        username => $p{username},
        ns => $p{ns},
        id_role => $role->id,
    })->first;
    
    # create
    unless( ref $row ) {
        my $row = Baseliner->model('Baseliner::BaliRoleuser')->create({
            username => $p{username},
            ns => $p{ns},
            id_role => $role->id,
        });
        $row->update;
    }
    return 1 if ref $row;
}

=head2 user_address_for_action username=>Str, action=>Str, bl=>Str

Returns a list of address to notify for a user and an action

=cut
sub user_address_for_action {
  my ($self, %p ) = @_;
  my $ret=undef;
  _check_parameters( \%p, qw/username action bl cam/ );

  my @rs=Baseliner->model('Baseliner::BaliRoleUser')->search(
     {  
       'me.username'=>$p{username}, 
       'bali_roleactions.action'=>$p{action},
       'bali_roleactions.bl'=>{in=>[$p{bl},'*']
     }
     },{ 
       join=>[{'role'=>'bali_roleactions'},'projects'], 
       select=>['me.ns','role.mailbox', 'projects.name'], 
       as=>['ns','address', 'cam'] 
     }
     )->hashref->all;
  my %address;
  
  map { my $pattern=$_->{cam};( grep /$pattern/, @{$p{cam}} ) ? $address{$_->{cam}}=$_->{address}//$p{username} : $_->{ns} eq '/' ? $address{'/'}=$_->{address}//$p{username} : undef } @rs;
  
  for (keys %address) {
     $ret=$address{$_} unless $_ eq '/';
  }

  return defined $ret ? $ret : $address{"/"};
}

=head2 user_baselines_for_action username=>Str, action=>Str

Returns a list of baslines for a username and action.

=cut
sub user_baselines_for_action  {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines_no_root();
    my $is_root = $self->is_root( $p{username} );
    foreach my $n ( @bl_list ) {
        next unless $is_root or $self->user_has_action( username=>$p{username}, action=>$p{action}, bl=>$n->{bl} );
        my $arr = [ $n->{bl}, $n->{name} ];
        push @bl_arr, $arr;
    }
    return @bl_arr;
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = delete $p{action};

    if ( $p{mid} ) {
        my @return = grep { /$action/ } $self->user_actions_by_topic(%p);
        return @return;
    } else {
        push my @bl, _array $p{bl}, '*';
        
        return 1 if $self->is_root( $username ) && $action ne 'action.surrogate';

        return Baseliner->model('Baseliner')->dbi->value(qq{
            select count(*)
            from bali_roleuser ru, bali_roleaction ra
            where ru.USERNAME = ?
              and ru.ID_ROLE = ra.ID_ROLE
              and ra.ACTION = ?
              and ra.bl in (} . join( ',', map { '?' } @bl ) . qq{)
        },$username, $action, @bl);        
    }
}

=head2 user_has_action username=>Str, action=>Str

Returns true if a user has a given action.

=cut
sub user_has_read_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = $p{action};

    my @roles = _unique map { $_->{id_role} } DB->BaliRoleuser->search({ username => $username })->hashref->all;
    my @actions = DB->BaliRoleaction->search({ id_role => \@roles, action => $action})->hashref->all;

    my $has_action;
    if (scalar @roles == scalar @actions) {
     $has_action = 1;
    } else {
     $has_action = 0;
    }
    return $has_action;
}

sub user_has_any_action {
    my ($self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ ); 
    my $username = $p{username};
    my $action = $p{action};
    my $bl = $p{bl} // '*';
    
    return 1 if $self->is_root( $username );

    my @actions = $self->user_actions_list( %p );
    return scalar @actions;
}

sub user_actions_list {
    my ( $self, %p ) = @_;
    _check_parameters( \%p, qw/username/ );
    my $username = $p{username};
    my $actionSQL = $p{action};
    my $action   = delete $p{action} // qr/.*/;
    my $mid = $p{mid};
    my $regexp_action;

    if ( !ref $action ) {
        $action =~ s/\./\\\./g;
        $action =~ s/%/\.\*/g;
        $regexp_action = qr/$action/;
    } elsif ( ref $action eq 'Regexp' ) {
        $regexp_action = $action;
    } else {
        return ();
    }
    push my @bl, _array $p{bl}, '*';

    my $where = {};

    $where->{'me.username'} = $username;
    $where->{'actions.bl'} = \@bl unless '*' ~~ @bl;

    my @actions;
    if ( $self->is_root( $username ) ) {
        @actions = map { $_->{key} } Baseliner->model( 'Actions' )->list;
    } elsif ( $mid ) {
        @actions = $self->user_actions_by_topic( %p );
        _log "por mid";
    } else {
        _log "sin mid";

        _log $regexp_action;
        @actions = map { $_->{'action'} } DB->BaliRoleuser->search(

            $where,
            {
                distinct => 1,
                join     => [ 'actions' ],
                select   => [ 'actions.action' ],
                as       => [ 'action' ]
            }
        )->hashref->all;
    } ## end else [ if ( $self->is_root( $username...))]
    return grep { $_ =~ $regexp_action } @actions;
} ## end sub user_actions_list

sub user_actions_by_topic {
    my ( $self, %p ) = @_;

    my @return;

    my @roles = $self->user_roles_for_topic( %p );
    
    for my $role ( @roles ) {
        my @actions = _array(Baseliner->cache_get(":role:actions:$role:"));
        if ( !@actions ) {
           _debug "NO CACHE for :role:actions:$role:";
           @actions = map { $_->{action} } DB->BaliRoleaction->search({ id_role => $role })->hashref->all;
           Baseliner->cache_set(":role:actions:$role:",\@actions);
        } else {
            _debug "CACHE HIT for :role:actions:$role:";
        }
        push @return, @actions;
    }
    return _unique @return;
}

=head2 user_has_project( username=>Str, project_name=>Str | project_id )

Returns an array of ns for the projects the user has access to.

=cut
sub user_has_project {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};
    my $qr=qr{^\/$};

    # is root?
    return 1 if $self->is_root( $p{username} );

    if( my $name = delete $p{project_name} ) {
        my @ns=$self->user_projects_names( %p );
        return 1 if scalar grep /$qr/, @ns;
        return scalar grep /^$name$/, @ns;
    } elsif( my $id = delete $p{project_id} ) {
        my @ns=$self->user_projects_ids( %p );
        return 1 if scalar grep /$qr/, @ns;
        return scalar grep /$id/,@ns
    }
    return 0;
}

=head2 user_projects( username=>Str )

Returns an array of ns for the projects the user has access to, 
ie, if the user has ANY role in them.

=cut
sub user_projects {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{ username };
    my $is_root = $self->is_root( $p{username} );
    if($is_root){
        return _unique( map { $p{with_role}?"1/".$_->{ns}:$_->{ns} } Baseliner->model( 'Baseliner::BaliProject' )->search()->hashref->all );
    }else{
        my @projects;
    	my @all_projects = Baseliner->model( 'Baseliner::BaliRoleUser' )->search({ username => $p{username}, ns => '/'})->hashref->all;
        if ( @all_projects ) {
            my @projs = Baseliner->model( 'Baseliner::BaliProject' )->search()->hashref->all;
            for my $role_all ( @all_projects ) {
                my $id_role = $role_all->{id_role};
                push @projects, map { $p{with_role}?$id_role."/".$_->{ns}:$_->{ns} } @projs;
            }
        }
        push @projects, map { $p{with_role}?$_->{id_role}."/".$_->{ns}:$_->{ns}} Baseliner->model( 'Baseliner::BaliRoleuser' )->search({ username => $p{username}, ns => {'<>','/'} }, { select => [ 'ns','id_role' ] })->hashref->all;
        return _unique( grep { length } @projects );
	}
}

=head2 user_projects_query

Returns a query ready to use as an EXISTS filter.

Before it used to be a query for a IN, which is highly inefficient. 

Usage:

    $where->{'exists'} =  $c->model( 'Permissions' )->user_projects_query( username=>$username, join_id=>'mid' )
        unless $c->is_root;

join_id: the outside query attribute (id,mid,project_id, etc.)
    

=cut
sub user_projects_query {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};
    _throw 'Missing join_id' unless exists $p{join_id};
    if ( $self->is_root( $p{username} )) {
        DB->BaliRoleuser->search({}, { select=>\'1' })->as_query        
    }
    else {
            if ( DB->BaliRoleuser->search( {username => $p{username}, ns => '/'} )->hashref->first ) {
                DB->BaliRoleuser->search({}, { select=>\'1' })->as_query        
            } else {
                DB->BaliRoleuser->search(
                    {username => $p{username}, id_project => {'=' => \"$p{join_id}"}},
                    {select   => \'1'} )->as_query;
            } ## end else [ if ( DB->BaliRoleuser->search...)]
    } ## end else

} 

=head2 user_projects_ids( username=>Str )

Returns an array of project ids for the projects the user has access to.

=cut
sub user_projects_ids {
    my ( $self, %p ) = @_;
    _throw 'Missing username' unless exists $p{username};
    my $is_root = $self->is_root( $p{username} );
    my $all_projects = Baseliner->model( 'Baseliner::BaliRoleUser' )->search({ username => $p{username}, ns => '/'})->first;
    if ($all_projects || $is_root){
        map { $_->{mid} } Baseliner->model( 'Baseliner::BaliProject' )->search()->hashref->all;
    }else{
        _unique map { s{^(.*?)/}{}g; $_ } $self->user_projects( %p );   
    }
}

=head2 user_projects_ids_with_collection( username=>Str )

Returns an array of project ids for the projects the user has access to with their collection

=cut
sub user_projects_ids_with_collection {
    my ( $self, %p ) = @_;
    my $sec_projects;
    my $with_role = $p{with_role} // 0;
    my $username = $p{username};

    my @projects;
    my @sec;

    $sec_projects = Baseliner->cache_get(":user:security:$username:");
    @sec = Baseliner->cache_get(":user:security:roles:$username:");

    if ( !$sec_projects || !@sec ) {
        if ( $p{action} ) {
            @projects = $self->user_projects_for_action( %p, with_role => 1 );
        } else {
            @projects = $self->user_projects( %p, with_role => 1 );
        }
        map { 
            my ($id_role,$id_project) = $_ =~ /^(.*?)\/.*\/(.*)$/;
            my $doc = mdb->master_doc->find_one({mid=>"$id_project"},{ collection=>1, mid=>1,_id=>0 });
            $sec_projects->{$id_role}{$doc->{collection}}{$id_project} = 1 if $doc;
        } @projects;    

        for my $role ( keys %$sec_projects ) {
            push @sec, $sec_projects->{$role};
        }
        Baseliner->cache_set(":user:security:$username:",$sec_projects);
        Baseliner->cache_get(":user:security:roles:$username:", \@sec);
        _debug "NO CACHE for :user:security:$username:";
    } else {
        _debug "CACHE HIT for :user:security:$username:";
    }
	if ( $with_role ) {
        return $sec_projects;
    } else {
        return @sec;
    }
}

sub user_projects_for_action {
    my ( $self, %p ) = @_;

    my $is_root = $self->is_root( $p{username} );
    if ( $is_root ) {
        return _unique( map { "1/".$_->{ns} }
                Baseliner->model( 'Baseliner::BaliProject' )->search()->hashref->all );
    } else {
        _log "AAAAAAAAA".$p{action};
        my @projects;
        my @all_projects =
            Baseliner->model( 'Baseliner::BaliRoleUser' )
            ->search( {username => $p{username}, ns => '/', 'actions.action' => $p{action}},{join => ['actions']} )->hashref->all;
        if ( @all_projects ) {
            my @projs_all = Baseliner->model( 'Baseliner::BaliProject' )->search()->hashref->all;
            for my $role_all ( @all_projects ) {
                my $id_role = $role_all->{id_role};
                push @projects, map { $p{with_role}?$id_role."/".$_->{ns}:$_->{ns} } @projs_all;
            }            
        }
        push @projects,
            map { $_->{id_role} . "/" . $_->{ns} }
            Baseliner->model( 'Baseliner::BaliRoleUser' )->search(
                {username => $p{username}, 'actions.action' => $p{action}},
                {join => [ 'actions' ], select => [ 'ns', 'id_role' ]}
            )->hashref->all;

        return _unique( grep { length } @projects );
    } ## end else [ if ( $all_projects || ...)]
} ## end sub user_projects_for_action

sub user_can_topic_by_project {
    my ($self,%p)=@_; 
    my $username = $p{username};
    my $mid = $p{mid} // _fail('Missing mid');
    return 1 if $self->is_root($username);
    my @proj_coll_roles = $self->user_projects_ids_with_collection(%p);
    my $where = { mid=>"$mid" };
    my @ors;
    for my $proj_coll_ids ( @proj_coll_roles ) {
        my $wh = {};
        while( my ($k,$v) = each %{ $proj_coll_ids || {} } ) {
            $wh->{"_project_security.$k"} = { '$in'=>[ undef, keys %{ $v || {} } ] }; 
        }
        push @ors, $wh;
    }
    $where->{'$or'} = \@ors;
    return !!mdb->topic->find($where)->count;
}

sub user_roles_for_topic {
    my ($self,%p)=@_; 
    my $username = $p{username};
    my $mid = $p{mid};

    
    my $proj_coll_roles = $self->user_projects_ids_with_collection(%p, with_role => 1);

    my @roles;
    for my $role ( keys %{$proj_coll_roles} ) {
        my $where = { mid=>"$mid" };
        my $proj_coll_ids = $proj_coll_roles->{$role};
        while( my ($k,$v) = each %{ $proj_coll_ids || {} } ) {
            $where->{"_project_security.$k"} = { '$in'=>[ undef, keys %{ $v || {} } ] }; 
        }
        #_log _dump $where;
        push @roles, $role if !!mdb->topic->find($where)->count;
    }
    return @roles;
}

=head2 user_projects_names( username=>Str )

Returns an array of project names to which the user has access.

=cut
sub user_projects_names {
    my ( $self, %p ) = @_;
    my @ns = $self->user_projects( %p );
    my @ids=map{ my ($d,$it)=ns_split($_); $it } _array @ns;
    my $rs = Baseliner->model('Baseliner::BaliProject')->search({ mid=>\@ids });
    rs_hashref( $rs );
    my $parentcache;
    my @ret;
    while( my $r = $rs->next ) {
    if (! $r->{id_parent} ) {
        push @ret, qq{application/$r->{name}};
    } else {
        if ( ! $parentcache->{$r->{id_parent}} ) {
            my $parent = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$r->{id_parent} } )->first;
            $parent and $parentcache->{$parent->mid}={
                name    =>$parent->name,
                parent  =>$parent->id_parent,
                id      =>$parent->mid
                };
            }
        if ($r->{nature}) {
            if ( ! $parentcache->{$parentcache->{$r->{id_parent}}->{parent}} ) {
                my $cam = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$parentcache->{$r->{id_parent}}->{parent} } )->first;
                $cam and $parentcache->{$cam->mid}={
                    name   =>$cam->name,
                    parent =>$cam->id_parent,
                    id     =>$cam->mid
                    };
                }
            push @ret, qq{nature/$parentcache->{$parentcache->{$r->{id_parent}}->{parent}}->{name}/$parentcache->{$r->{id_parent}}->{name}/$r->{nature}} ;
        } elsif ($r->{id_parent}) {
            push @ret, qq{subapplication/$parentcache->{$r->{id_parent}}->{name}/$r->{name}};
            }
        }
    }
    push @ret, '/' if scalar grep /^\/$/, @ns;
    return sort { $a cmp $b } _unique( @ret );
    # _unique map { $_->{name} } $rs->all;
}

=head2 user_projects_with_action( username=>Str, action=>[ ... ] )

List of projects for which a user has a given action.

=cut

sub user_projects_with_action {
    my ( $self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ );
    my $username  = $p{username};
    my $action    = $p{action};
    my $bl        = $p{bl} || '*';
    my $level     = $p{level} || 'all';
    my $bl_filter = '';
    $bl_filter = qq{ AND ra.bl in ('$bl','*') } if $bl ne '*';
    my @granted_projects = [];

    my $rs;

    # check if all
    my $roles_all = DB->BaliRoleuser->search(
        { username=>$username, action=>$action, ns=>'/' },
        { join=>['actions', 'role' ], select=>'id_project' }
    );
    if( $self->is_root($username) || $roles_all->count ) {
        $rs = DB->BaliProject->search({ id_parent=>undef },{ select=>'mid' });
    } else {
        my $roles = DB->BaliRoleuser->search(
            { username=>$username, action=>$action, ns=>{ '!='=>'/' } },
            { join=>['actions', 'role' ], select=>'id_project' }
        );

        # app
        $rs = DB->BaliProject->search(
            { mid => {-in => $roles->as_query }, id_parent=>undef }, 
            { select=>'mid', distinct=>1 }
        );
    }

    my ($lev2, $lev3);
    if ( $level eq 'all' || $level ge 2 ) {
        # supapp
        $lev2 = DB->BaliProject->search(
            { id_parent => {-in => $rs->as_query }, nature=>undef }, 
            { select=>'mid', distinct=>1 }
        );
        $rs = $rs->union( $lev2 );
    }

    if ( $level eq 'all' || $level ge 3 ) {
        # nature
        $lev3 = DB->BaliProject->search(
            { id_parent => {-in => $lev2->as_query }, nature=>{ '!=' => undef } }, 
            { select=>'mid', distinct=>1 }
        );
        $rs = $rs->union( $lev3 );
    }

    if( $p{as_query} ) {
        return $rs->as_query ;
    } else {
        my @mids = map { $_->{mid} } $rs->hashref->all;
        return wantarray ? @mids : \@mids; 
    }
}

# XXX deprecated: 
sub user_projects_with_action_old {
    my ( $self, %p ) = @_;
    _check_parameters( \%p, qw/username action/ );
    my $username  = $p{username};
    my $action    = $p{action};
    my $bl        = $p{bl} || '*';
    my $level     = $p{level} || 'all';
    my $bl_filter = '';
    $bl_filter = qq{ AND ra.bl in ('$bl','*') } if $bl ne '*';
    my @granted_projects = [];

    if ( $self->is_root($username) ) {
        @granted_projects = $self->all_projects();
    } else {
        my $db = new Baseliner::Core::DBI( { model => 'Baseliner' } );
        my @data = $db->array(
            qq{
                select distinct p.mid
                from BALI_ROLE r, BALI_ROLEUSER ru, BALI_ROLEACTION ra, BALI_PROJECT p
                WHERE  r.ID = ru.ID_ROLE AND
                r.ID = ra.ID_ROLE AND
                username = ? AND
                action = ? AND
                 (
                       ( ru.NS like 'project/%' AND p.mid = to_number( replace( ru.NS, 'project/','' ) ) )
                       OR
                       ( ru.NS = '/' )
                    ) AND
                p.id_parent IS NULL
                $bl_filter
                ORDER BY 1
            }, $username, $action
        );
        if ( @data && $data[0] eq '/' ) {

            # XXX does not apply anymore in any case
            @granted_projects = $self->all_projects();
        } else {

            sub parent_ids {
                my $rs = shift;
                rs_hashref($rs);
                map { $_->{mid} } $rs->all;
            }
            my @natures;
            my @subapls;
            @granted_projects = @data;
            if ( $level eq 'all' || $level ge 2 ) {
                @natures    = parent_ids(
                    scalar Baseliner->model('Baseliner::BaliProject')
                        ->search( { id_parent => \@data, nature => { '=', undef } }, { select => [qw/mid/] } ) );
                @granted_projects = _unique @granted_projects, @subapls
            }

            if ( $level eq 'all' || $level ge 3 ) {
                @subapls    = parent_ids(
                    scalar Baseliner->model('Baseliner::BaliProject')
                        ->search( { id_parent => \@subapls, nature => { '!=', undef } }, { select => [qw/mid/] } ) );
                @granted_projects = _unique @granted_projects, @natures
            }
            @granted_projects =_unique @granted_projects;
        }
    }
    return wantarray ? @granted_projects : \@granted_projects;
}


#### Ricardo (21/6/2011): Listado de todos los proyectos
sub all_projects {
    my @projects = [];
    my $rs = Baseliner->model('Baseliner::BaliProject')->search( undef, { select=>['mid'] } );
    rs_hashref($rs);
    
    @projects = map {
        $_->{mid}
    } $rs->all;
    
    return @projects;
}

=head2 user_grants $username [ action=>Str, ns=>Str ]

Returns a list of roles a user has.

=cut
sub user_grants {
    my ($self, $username, %p ) = @_;
    my $root_user = $self->is_root( $username );
    my $where = {};
    $where->{username} = $username unless $root_user;
    $p{action} and $where->{action} = $p{action};
    $p{ns} and $where->{action} = $p{ns};
    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search( $where, { prefetch=>['role'] } );
    rs_hashref( $rs );
    my @ret;
    while( my $r = $rs->next ) {
        $root_user and $r->{username} = $username;
        push @ret, $r;
    }
    if( $root_user ) {  # no duplicates
        my %grant;
        $grant{ join(',', grep { defined } values %$_ ) } = $_ for @ret;
        @ret = values %grant;
    }

    return @ret;
}

=head2 user_namespaces

Returns a list of ns from roleuser,
which means that there's some role in there

=cut
sub user_namespaces {
    my ($self, $username ) = @_;
    my @perms = Baseliner->model('Permissions')->user_grants( $username );
    return sort { $a cmp $b } _unique( map { $_->{ns} } @perms );
}

=head2 user_namespaces_name

Returns a list of applications from roleuser,
which means that there's some role in there

=cut
sub user_namespaces_name {
    my ($self, $username ) = @_;
    my @perms = Baseliner->model('Permissions')->user_grants( $username );
    my @appId;

    foreach (@perms) {
        push @appId, $1 if ($_->{ns} =~ m{project/(.+)});
        }
        
    my $rs = Baseliner->model('Baseliner::BaliProject')->search( { mid=>{ 'in' => [ _unique @appId ] } } );
    rs_hashref( $rs );
    my @ret;
    my $parentcache;
    while( my $r = $rs->next ) {
        if (! $r->{id_parent} ) {
            push @ret, qq{application/$r->{name}};
        } else {
            if ( ! $parentcache->{$r->{id_parent}} ) {
                my $parent = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$r->{id_parent} } )->first;
                $parent and $parentcache->{$parent->mid}={
                    name=>$parent->name,
                    parent=>$parent->id_parent,
                    id=>$parent->mid
                    };
                }
            if ($r->{nature}) {
                if ( ! $parentcache->{$parentcache->{$r->{id_parent}}->{parent}} ) {
                    my $cam = Baseliner->model('Baseliner::BaliProject')->search( { mid=>$parentcache->{$r->{id_parent}}->{parent} } )->first;
                    $cam and $parentcache->{$cam->mid}={
                        name=>$cam->name,
                        parent=>$cam->id_parent,
                        id=>$cam->mid
                        };
                    }
                push @ret, qq{nature/$parentcache->{$parentcache->{$r->{id_parent}}->{parent}}->{name}/$parentcache->{$r->{id_parent}}->{name}/$r->{nature}} ;
            } elsif ($r->{id_parent}) {
                push @ret, qq{subapplication/$parentcache->{$r->{id_parent}}->{name}/$r->{name}};
                }
            }
        }

    return sort { $a cmp $b } _unique( @ret );
}

=head2 list

List users that have an action

     action=>Str, [ ns=>Str, bl=>Str ]

 or actions that a user has

     username=>Str, [ bl=>Str ]

=cut
sub list {
    my ( $self, %p ) = @_;
    my $ns = defined $p{ns} ? $p{ns} : 'any';
    ref $ns eq 'ARRAY' and _throw "Parameter ns: ARRAY of namespaces not supported yet.";
    my $bl = $p{bl} || 'any';

    $p{recurse} = defined $p{recurse} ? $p{recurse} : 1;
    $p{action} or $p{username} or die _loc( 'No action or username specified' );

    # if its root, gimme all actions period.
    return map { $_->{key} } Baseliner->model('Actions')->list
      if $p{username} && $self->is_root( $p{username} );

    # build query
    my $query = $p{action}
        ? { action=> [ -or => [ $p{action}, { -like => "$p{action}.%" } ] ] }
        : { username=>$p{username} };
    
    $query->{bl} = [ -or => [ $bl, '*' ] ]
        unless $bl eq 'any';

    $query->{ns} = [ -or => [ $ns, '/' ] ]
        unless $ns eq 'any';

    # search roles
    my $roles = Baseliner->model('Baseliner::BaliRole')->search(
        $query,
        { join     => ['bali_roleusers', 'bali_roleactions'],
          prefetch=>[ $p{action} ? 'bali_roleusers' : 'bali_roleactions']
        }
    );

    $roles->result_class('DBIx::Class::ResultClass::HashRefInflator');

    # now, foreach role
    my @list;
    while( my $role = $roles->next ) {
        my $role_name = $role->{role};
        # if asked for, don't include certain roles
        next if $p{role_filter} and ! grep( /$role_name/i, _array($p{role_filter}) );
        # return either users or roles, depending on the query
        my $data= $p{action} ? $role->{bali_roleusers} : $role->{bali_roleactions};
        
        push @list,
            # map { $p{action} ? $_->{username} : $_->{action} }
            map { $p{action} ? ( $role->{mailbox} ? split ",",$role->{mailbox} : $_->{username} ) : $_->{action} }
            _array( $data );
    }

    # recurse $self->list on parents
    if( $p{recurse} && $ns ne 'any' ) {
        my $item = Baseliner->model('Namespaces')->get( $ns );
        _throw "No he podido encontrar el item '$ns'" unless ref $item;
        if (blessed $item && $item->does('Baseliner::Role::Namespace') ) {
            for my $parent ( _array $item->parents ) {		
                next if $parent eq '/';
                push @list,
                $self->list(
                    ns          => $parent,
                    bl          => $bl,
                    role_filter => $p{role_filter},
                    recurse     => 0,
                    (
                        $p{action}
                        ? ( action => $p{action} )
                        : ( username => $p{username} )
                    )
                );
            }
        }
    }
    # _log "LIST: $p{username} got \n";_log Dumper _unique @list;
    return _unique @list;
}

=head2 is_root

Return true if a user has the root action C<action.admin.root>.
Or if its username is 'root'

=cut
our $root_username;

sub is_root {
    my ( $self, $username ) = @_;
    $username or die _loc('Missing username');
    $root_username //= Baseliner->config->{root_username} || '';
    return 1 if $username eq 'root' || length $root_username && $username eq $root_username;

    return Baseliner->model('Baseliner')->dbi->value(qq{
        select count(*) 
        from bali_roleaction ra,     
             bali_role r,     
             bali_roleuser ru 
        where   ru.username = ?         
                and ra.action = 'action.admin.root' 
                and r.id = ru.id_role 
                and r.id = ra.id_role				
    },$username);
}

=head2 role $role

Returns an array of actions for a given role.

=cut
sub role {
    my ( $self, $role ) = @_;
    $role or _throw 'Missing argument role';	
    my @roles;
    my $rs = Baseliner->model('Baseliner::BaliRole')->search({ role => $role });
    while( my $role = $rs->next ) {
        my @actions;
        my $actions = $role->bali_roleactions;
        while( my $action = $actions->next ) {
            push @actions, $action->action;
        }
        push @roles, { role=>$role->role, description=>$role->description, actions=>[ @actions ] };
    }
    return shift @roles;
}

=head2 user_roles

Returns everything a user has.

=cut
sub user_roles {
    my ( $self, $username ) = @_;
    $username or _throw 'Missing parameter username';	
    my @roles;
    my $rs = Baseliner->model('Baseliner::BaliRoleuser')->search({ username => $username });

    while( my $r = $rs->next ) {
        my $role = $r->id_role;
        my $ns = $r->ns;
        my @actions;
        my $actions = $role->bali_roleactions;
        while( my $action = $actions->next ) {
            push @actions, $action->action;
        }
        push @roles, { id=>$role->id, role=>$role->role, ns=>$ns, description=>$role->description, actions=>[ @actions ] };
    }
    # _log "user_roles: $username got \n";_log Dumper _unique @roles;
    return @roles;
}

=head2 all_users

List all users that have roles

=cut
sub all_users {
    my ( $self ) = @_;
    my @users;
    my $rs = Baseliner->model('Baseliner::BaliRoleUser')->search;
    return unless ref $rs;
    while( my $r = $rs->next ) {
        push @users, $r->username;
    }
    return _unique @users;
}

=head2 user_has_action_fast

Checks a user has an action... only faster. 

=cut
sub user_has_action_fast {
    my ( $self, %p ) = @_;
    my $username = delete $p{username};
    return unless $username;
    return 1 if $self->is_root( $username );
    return grep { $username eq $_ } $self->list( %p );
}

sub users_with_actions {
    my ( $self, %p ) = @_;
    
    my @actions = _array $p{actions};
    my @projects = _array $p{projects};
    my $include_root = $p{include_root} // 1;

    @projects = map { 'project/'.$_ } @projects;
    push @projects, '/';


    my $query = {};
    $query->{action} = \@actions;
    $query->{username} = {'!=', undef};
    $query->{'bali_roleusers.ns'} = \@projects;

    delete $query->{action} if (scalar @actions == 1 && $actions[0] eq '*');    

    my @users = map{ $_->{username} } DB->BaliRoleaction->search( $query ,
                                    { join => {'id_role' => {'bali_roleusers' => 'bali_user'}}, 
                                      select => ['bali_roleusers.username'], as => ['username'],
                                      group_by => ['username']} )->hashref->all;
    my @root_users;
    if ( $include_root ) {        
        @root_users = map{ $_->{username} } DB->BaliRoleaction->search( { action => 'action.admin.root'} ,
                                        { join => {'id_role' => {'bali_roleusers' => 'bali_user'}}, 
                                          select => ['bali_roleusers.username'], as => ['username'],
                                          group_by => ['username']} )->hashref->all;
        push @root_users,Baseliner->config->{root_username} if Baseliner->config->{root_username};

    }

    return @users, @root_users;
}

sub users_with_roles {
    my ( $self, %p ) = @_;
    
    my @roles = _array $p{roles};
    my @projects = _array $p{projects};
    my $include_root = $p{include_root} // 1;


    @projects = map { 'project/'.$_ } @projects if @projects;
    push @projects, '/';


    my $query = {};
    $query->{id_role} = \@roles;
    $query->{username} = {'!=', undef};
    $query->{'ns'} = \@projects;

    delete $query->{role} if (scalar @roles == 1 && $roles[0] eq '*');    

    my @users = map{ $_->{username} } DB->BaliRoleuser->search( $query ,
                                    { select => ['username'], as => ['username'],
        
                                  group_by => ['username']} )->hashref->all;
    my @root_users;
    if ( $include_root ) {        
        @root_users = map{ $_->{username} } DB->BaliRoleaction->search( { action => 'action.admin.root'} ,
                                        { join => {'id_role' => {'bali_roleusers' => 'bali_user'}}, 
                                          select => ['bali_roleusers.username'], as => ['username'],
                                          group_by => ['username']} )->hashref->all;
        push @root_users,Baseliner->config->{root_username} if Baseliner->config->{root_username};

    }
    return @users, @root_users;

}

1;
