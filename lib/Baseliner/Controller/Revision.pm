package Baseliner::Controller::Revision;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' };
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Moose::Autobox;
use JSON::XS;

register 'action.job.view_job_revisions' => {name => "Can view job revisions"};

register 'menu.job.revisions' => {label    => 'Revisions',
                                  url_comp => '/revision/grid',
                                  title    => 'Revisions',
                                  icon     => '/static/images/scm/package.gif',
                                  action   => 'action.job.view_job_revisions'};

register 'portlet.revisions' =>
	{ label => 'Revisions', url_comp=>'/revision/grid_portlet',
		url_max=>'/revision/grid',
		title=>'Revisions',
        active => 0,
		icon=>'/static/images/scm/package.gif' }; #, actions=>['action.package.view'] };

sub grid : Local {
	my ($self,$c) = @_;
	$c->stash->{template} = '/comp/revision/grid.mas';
}

sub grid_portlet : Local {
    my ( $self, $c ) = @_;
	$c->forward('/revision/grid');
	$c->stash->{is_portlet} = 1;
}


sub request : Local {
	my ($self,$c) = @_;
	my $p = $c->req->params;

	try {
		my $item = $p->{item};
		my $action = $p->{action};
		my $username = $c->username;
		my $bl = 'PREP';
		my $approval_type = 'Pruebas Funcionales';
		my $action_type = 'action.approve.pruebas_integradas';
		Baseliner->model('Request')->request(
				name   => $approval_type,
				action => $action_type,
				data   => {}, #{ rfc=>$rfc, project=>$project->{envname}, app=>$project->{envname}, state=>$hist_state },
				callback => 'service.harvest.approval.callback',
				template => 'email/approval.html',
				vars   => { reason=>'' },
				username => $username,
				#TODO role_filter => $p->{role},    # not working, no user selected??
				ns     => $item,
				bl     => $bl,
		);
		$c->stash->{json} = { success=>\1 };
	} catch {
		$c->stash->{json} = { success=>\0, message=>shift };
	};
	$c->forward('View::JSON');
}

sub delete : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;

    my $ret={};
    try {
        my $nsid = $p->{ns};
        _throw "Missing parameter ns" unless $nsid;
        my $obj = ns_get $nsid;
        _throw _loc('Could not find %1', $nsid) unless ref $obj;
        _throw _loc("Delete not available for this revision type")
            unless $obj->does('Baseliner::Role::Namespace::Delete');
        $ret = $obj->delete;
        _throw _loc('Error during delete') if $ret->{rc};
        $c->stash->{json} = { success=>\1 };
    } catch {
        $c->stash->{json} = { success=>\0, msg=>shift, output=>$ret->{output} };
    };
    $c->forward('View::JSON');
}

sub rename : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;

    try {
        my $nsid = $p->{ns};
        _throw "Missing parameter ns" unless $nsid;
        my $newname = $p->{newname};
        _throw "Missing parameter newname" unless $newname;
        my $obj = ns_get $nsid;
        _throw _loc('Could not find %1', $nsid) unless ref $obj;
        _throw _loc("Rename not available for this revision type")
            unless $obj->does('Baseliner::Role::Namespace::Rename');
        $obj->rename( $newname );
        $c->stash->{json} = { success=>\1 };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg=>$err };
    };
    $c->forward('View::JSON');
}

# list provider names so that they can be put in a menu or as tabs
sub list_providers : Local {
	my ($self,$c) = @_;
	try {
		my @providers = $c->model('Namespaces')->provider_instances({
			   does => ['Baseliner::Role::Namespace::Package', 'Baseliner::Role::Namespace::Release']
		}); 
		my @list;
		for my $provider ( @providers ) {
			push @list, $provider->name;
		}
		$c->stash->{json} = { success=>\1, list=>\@list };
	} catch {
		my $err = shift;
		_log $err;
		$c->stash->{json} = { success=>\0, message=>$err };
	};
	$c->forward('View::JSON');
}

sub list : Local {
	my ($self,$c) = @_;
	my $p = $c->req->params;

	my $grid_view = $p->{grid_view};

    my $filter_bl = try { decode_json( $p->{filter_bl} ) } catch { $p->{filter_bl} };
	$filter_bl = try { [ grep { $filter_bl->{$_} } keys %{ $filter_bl } ] } catch { '*' };

    my %where;
    %where = (
		start      => $p->{start},
		limit    => $p->{limit},
		username => $c->username,
        bl         => $filter_bl || '*',
		query => $p->{query},
		cache => 'maybe',
		#bl=>$p->{bl},
		#states=>$p->{states},
		#job_type=>$p->{job_type},
	);
    $p->{isa} and $where{isa} = $p->{isa};
    !defined $where{isa} and $where{does} = $p->{does} || ['Baseliner::Role::Namespace::Release','Baseliner::Role::Namespace::Package' ];
    defined $p->{checkin} && $p->{checkin} eq 'true' and $where{checkin}=1;

    my $list = $c->model('Namespaces')->list(%where);

    # create json struct
	my @items;
	my $cnt=1;

	# requests / approval
	my %req_status;
	my $rs_req = $c->model('Baseliner::BaliRequest')->search(
		{
			action => { -like => 'action.approve.%' },
			status => { '<>'  => 'cancelled' },
		},
		{ order_by => 'id', columns=>['ns'] }
	);
	rs_hashref( $rs_req);
	while( my $r = $rs_req->next ) {
		$req_status{ $r->{ns} } = $r;
	}

	# _log "Array.";
	my @ns_list = _array $list->{data};
	my @ns_list_ns = map { $_->ns } @ns_list;

	# jobs
	# _log 'Jobs';
	my %jobs;
	my $rs_job = $c->model('Baseliner::BaliJobItems')->search(
		{ item=>{ -in=>\@ns_list_ns } },
		{ prefetch=>['id_job'],
		  columns=>['item'],
		order_by=>'id_job desc' }
	);
	rs_hashref( $rs_job );
	while( my $r = $rs_job->next ) {
		next if ref $jobs{ $r->{item} };
		$jobs{ $r->{item} } = { 
			jobname => $r->{id_job}->{name},
			jobid   => $r->{id_job}->{id},
		};
	}

    # releases
	# _log "Releases.";
    my %releases;
    my $rs_rel = Baseliner->model('Baseliner::BaliRelease')->search(
		{ 'bali_release_items.ns'=> { -in => \@ns_list_ns } },
		{
		prefetch=>'bali_release_items',
		+columns=>['name', 'id', 'bali_release_items.ns']
	});
	#_log "Query=" . _dump $rs_rel->as_query;
	rs_hashref( $rs_rel );
	while( my $r = $rs_rel->next ) {
	#_log "REL======" . $r->{name};
	#_log "REL======" . _dump( $r );
        try {
            for my $item ( _array $r->{bali_release_items} ) {
                my $ns = $item->{ns};
                $releases{ $ns } = { name=>$r->{name}, id=>$r->{id} };
            }
        };
	}
	# _log "Start.";
	my %apps;
	for my $n ( @ns_list ) {
		# application
		my $app = try {
			my $first = $n->related->shift or die;
			return $apps{$first} if $apps{$first};
            $first = "application/$first" if $first !~ /\//; # fix old app names
			$apps{$first} = Baseliner->model('Namespaces')->get( $first )->ns_name;
			return $apps{$first};
		} catch { $n->related };

		my $top_job = $jobs{ $n->ns };
		my $jobname = ref $top_job ? $top_job->{jobname} : '';
		my $jobid   = ref $top_job ? $top_job->{jobid} : '';

		my $bl = [ $n->bl ];
		my $inspector = try { $n->inspector->stringify } catch { '' };
        push @items,
          {
			id => $cnt++,
            provider  => $n->provider,
            related   => $app, #$n->related,
            ns_type   => $n->ns_type,
            icon      => $n->icon,
            item      => $n->ns_name,
            ns        => $n->ns,
            bl        => $bl,
            user      => $n->user,
            service   => $n->service,
            text      => $n->ns_info,
            date      => $n->date,
			last_job  => $jobname,
            id_job    => $jobid,
			release   => $releases{$n->ns}->{name} || '',
			id_rel    => $releases{$n->ns}->{id} || '',
			inspector => $inspector, 
			status    => _loc( $req_status{ $n->ns }->{status} || '-' ),
			status_type  => $req_status{ $n->ns }->{name} || '-' ,
			id_req    => $req_status{ $n->ns }->{id},
			id_message=> $req_status{ $n->ns }->{id_message},
			action  => $req_status{ $n->ns }->{action} ,
            can_job   => '',
			recordCls => '',
            why_not   => '',
            can_rename => \( $n->does('Baseliner::Role::Namespace::Rename') ),
            can_delete => \( $n->does('Baseliner::Role::Namespace::Delete') ),
            data      => $n->ns_data,
          };
    }
    $c->stash->{json} = {
        totalCount => $list->{total},
        data => [ @items ]
    };
    $c->forward('View::JSON');
}

sub list_simple : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;

    my $grid_view = $p->{grid_view};

    my $filter_bl = try { decode_json( $p->{filter_bl} ) } catch { $p->{filter_bl} };
    $filter_bl = try { [ grep { $filter_bl->{$_} } keys %{ $filter_bl } ] } catch { '*' };

    my %where;
    %where = (
        start      => $p->{start},
        limit      => $p->{limit},
        username   => $c->username,
        bl         => $filter_bl || '*',
        query      => $p->{query},
        cache      => 'maybe',
        #bl=>$p->{bl},
        #states=>$p->{states},
        #job_type=>$p->{job_type},
    );
    $p->{isa} and $where{isa} = $p->{isa};
    !defined $where{isa} and $where{does} = $p->{does} || ['Baseliner::Role::Namespace::Release','Baseliner::Role::Namespace::Package' ];
    defined $p->{checkin} && $p->{checkin} eq 'true' and $where{checkin}=1;

    my $list = $c->model('Namespaces')->list(%where);

    # create json struct
    my @items;
    my $cnt=1;

    my %apps;
    for my $n ( $list->list ) {
        my $bl = [ $n->bl ];
        #my $inspector = try { $n->inspector->stringify } catch { '' };
        push @items,
          {
            id => $cnt++,
            provider  => $n->provider,
            #related   => $app, #$n->related,
            ns_type   => $n->ns_type,
            icon      => $n->icon,
            item      => $n->ns_name,
            ns        => $n->ns,
            bl        => $bl,
            user      => $n->user,
            service   => $n->service,
            text      => $n->ns_info,
            date      => $n->date,
            data      => $n->ns_data
          };
	}
	$c->stash->{json} = {
		totalCount => $list->{total},
		data => [ @items ]
	};
	$c->forward('View::JSON');
}

sub create_providers : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $data = [
        map { { name=>_loc($_->name), package=>$_, url=>$_->create_form_url } }
        packages_that_do( 'Baseliner::Role::Namespace::Create') ];
    $c->stash->{json} = {
        totalCount => scalar(@$data),
        data => $data,
    };
    $c->forward('View::JSON');
}

1;
