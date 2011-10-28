package Baseliner::Controller::Release;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use Carp;
use JSON::XS;
use Try::Tiny;
use utf8;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller' }
BEGIN { 
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}
use JavaScript::Dumper;

register 'config.release.create' => {
	name => 'Release Creation Options',
	metadata=> [
		{ id=>'mask', label => 'Release Name Mask', type=>'text', default=>'"R." . substr(${application}, 4,4) . "." . ${name}' },
		{ id=>'state_bl_map', label => 'Release State to Baseline Map', type=>'hash', },
		{ id=>'bl_state_map', label => 'Release Baseline to State Map', type=>'hash', },
	],
};

register 'config.release' => {
	name => 'Release Record',
	metadata=> [
		{ id=>'jobid', label => 'Job ID', type=>'text', width=>200 },
		{ id=>'name', label => 'Job Name', type=>'text', width=>180 },
		{ id=>'starttime', label => 'StartDate', type=>'text', },
		{ id=>'maxstarttime', label => 'MaxStartDate', type=>'text', },
		{ id=>'endtime', label => 'EndDate', type=>'text' },
		{ id=>'status', label => 'Status', type=>'text', default=>'READY' },
		{ id=>'mask', label => 'Job Naming Mask', type=>'text', default=>'%s.%s-%08d' },
		{ id=>'runner', label => 'Registry Entry to run', type=>'text', default=>'service.job.dummy' },
		{ id=>'comment', label => 'Comment', type=>'text' },
		{ id=>'create_active', label => 'Release Active on creation', type=>'bool', default=>1 },
	],
};

register 'menu.job.release' => { label => 'Releases', icon=>'/static/images/scm/release.gif' };
register 'menu.job.release.new' => { label => 'Create a new Release', url=>'/release/create', title=>'New Release' };
register 'menu.job.release.list' => { label => 'List Releases', url_comp => '/release/list', title=>'Releases' };

sub release_contents :Private {
    my ( $self, $c ) = @_;
	my $id_rel = $c->stash->{id};
	my $rs = $c->model('Baseliner::BaliReleaseItems')->search({ id_rel=> $id_rel });
	my @rows;
	my @items;
	while( my $r = $rs->next ) {
		push @items, $r->item;
		try {
			my $ns = $c->model('Namespaces')->get( $r->ns );
			push @rows, { %{ $ns }, item=>$ns->ns_name, id=>$r->id };
		} catch {
			my $desc = " (" . $c->localize($r->provider) . ")" if $r->provider;
			push @rows, { id=>$r->id, ns=>$r->ns, ns_name=>$r->ns_name || $r->ns, item=>$r->item, provider=>$r->provider, data=>$r->data  };
		}
	}
	$c->stash->{item_list} = \@items;
	$c->stash->{contents} =  \@rows;
}

sub create : Local {
    my ( $self, $c ) = @_;
	$c->stash->{ns_filter} = { does=>[ 'Baseliner::Role::Package' ] };
    $c->stash->{can_edit} = 1;
	#$c->forward('/namespace/load_namespaces');
	$c->forward('load_state_bl_maps');
	$c->forward('/baseline/load_baselines_no_root');
    $c->stash->{template} = '/comp/release_form.mas';
}

sub load_state_bl_maps : Private {
    my ( $self, $c ) = @_;
	my $inf = Baseliner->model('ConfigStore')->get('config.release.create' );
	$c->stash->{state_bl_map} = $inf->{state_bl_map} ;
	$c->stash->{bl_state_map} = $inf->{bl_state_map} ;
	my %sm = %{ $inf->{bl_state_map} || {} };
	$c->stash->{release_states} = [ map { [ $_, $sm{$_}] } keys %sm ];
}

sub edit : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $id_rel = $p->{id_rel};

	my $row = $c->model('Baseliner::BaliRelease')->search({ id=> $id_rel })->first;
	if( $row ) {
        my $release = BaselinerX::Release::Namespace::Release->new({ row=>$row });
        my $app = ns_split( $row->ns );
		my $bl = $release->bl;

        if( ! $release->user_can_edit( $c->username ) ) {
            $c->stash->{why_not} = _loc('User unauthorized');
            $c->stash->{can_edit} = 0;
        }
        elsif( $release->locked ) {
            $c->stash->{why_not} = $release->locked_reason,
            $c->stash->{can_edit} = 0;
        } else {
            $c->stash->{can_edit} = 1;
        }
		$c->stash->{id} = $id_rel;
		$c->stash->{name} = $row->name;
		$c->stash->{bl} = $row->bl;
		$c->stash->{rfc} = $release->rfc;
		$c->stash->{ns} = $app;
		$c->stash->{bl} = $bl;
		$c->stash->{text} = $release->text;
		$c->stash->{description} = $row->description;
	}
	#$c->forward('/namespace/load_namespaces');
	$c->forward('load_state_bl_maps');
	$c->forward('/baseline/load_baselines_no_root');
    $c->stash->{template} = '/comp/release_form.mas';
}

sub load : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $id_rel = $p->{id};

    my $data = {};
	my $row = $c->model('Baseliner::BaliRelease')->search({ id=> $id_rel })->first;
	if( $row ) {
        my $release = BaselinerX::Release::Namespace::Release->new( { row => $row } );
        my $app = ns_split( $row->ns );
        my $bl  = $release->bl;
        $data->{can_edit} = $release->user_can_edit( $c->username ) && $bl ne 'PROD';
        $data->{id}          = $id_rel;
        $data->{name}        = $row->name;
        $data->{bl}          = $row->bl;
        $data->{rfc}         = $release->rfc;
        $data->{ns}          = $app;
        $data->{bl}          = $bl;
        $data->{text}        = $release->text;
        $data->{description} = $row->description;
	}
    $c->stash->{json} = { data=>[$data] };
    $c->forward('View::JSON');
}

sub add_item : Local {
    my ( $self, $c ) = @_;
    my $p      = $c->request->parameters;
    my $id_rel = $p->{id_rel};
    my $ns     = $p->{ns};
    my $bl     = $p->{bl};
	my $username = $c->username;

	try {
		# get the parent relese 
		my $release = $c->model('Baseliner::BaliRelease')->find( $id_rel );
		_throw _loc("Release %1 not found", $id_rel) unless ref $release;
		my $rel_ns = $release->namespace;
		my $rel_bl = $rel_ns->bl; 
		my $rel_name = $rel_ns->ns_name; 
		my $owner = $rel_ns->user;
		# check if bl match
		_throw _loc("Release is in %1 but item is in %2", $rel_bl, $bl ) unless $rel_bl eq $bl || $rel_bl eq '*';

		my ($domain,$name) = ns_split( $ns );
		#check if its in it already
		my $first = $c->model('Baseliner::BaliReleaseItems')->search({ ns=>$ns, id_rel=>$id_rel })->first;
		_throw _loc("Item %1 already in release %2", $name, $rel_name ) if ref $first;

		my ($app,$rfc) = ("application/GBP.$1",$2) if $rel_name =~ m/.*\.(.*)\.(.*)\..*/;
		$c->model('RFC')->check_rfc( "$app", "$rfc" );
		
		# now create
        my $row = $c->model('Baseliner::BaliReleaseItems')->create({
            #data => _dump($item->{data}),
            ns => $ns,
            item => $name,
            provider => $domain, #FIXME namespace.harvest.package - from namespaces->get
            id_rel => $id_rel,
        });
		die _loc("item %1 not found", $ns ) . "\n" unless ref $row; 

		# notify the release owner that a new item has been included
        $c->model('Messaging')->notify(
            to       => { users => [ $owner ] },
            sender   => $username,
            subject  => _loc('New item added to release %1', $rel_name ),
            carrier  => 'email',
            template => 'email/generic.html',
			template_engine => 'mason',
            vars     => {
                message => _loc("User '%1' added item '%2' to release '%3'", $username, $name, $rel_name)
			} 
		);
		$c->stash->{json} = { success => \1, msg => _loc("Item %1 added.", $name ) };
	} catch {
		my $err = shift;
		$c->stash->{json} = { success => \0, msg => _loc("Error adding item to the release: %1", $err )  };
	};
	$c->forward('View::JSON');	
}

sub remove_item : Local {
    my ( $self, $c ) = @_;
    my $p      = $c->request->parameters;
    my $id_rel = $p->{id_rel};
    my $ns     = $p->{ns};

	try {
		my $row = $c->model('Baseliner::BaliReleaseItems')->search({ id_rel=> $id_rel, ns=>$ns })->first;
		die _loc("item %1 not found", $ns ) . "\n" unless ref $row; 
		my ($domain,$name) = ns_split( $ns );
		$row->delete;
        $row->commit;
		$c->stash->{json} = { success => \1, msg => _loc("Item %1 removed.", $name ) };
	} catch {
		my $err = shift;
		$c->stash->{json} = { success => \0, msg => _loc("Error creating the release: %1", $err )  };
	};
	$c->forward('View::JSON');	
}

# search items query in the form
sub release_items_json : Path('/release/items/json') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;

	# fetch JobItems
    my $list = $c->model('Namespaces')->list(
        does     => 'Baseliner::Role::Namespace::Package',
        start    => $p->{start},
        limit    => $p->{limit},
        username => $c->username,
        bl       => $p->{bl},
		rfc      => $p->{rfc},
        states   => $p->{states},
        job_type => $p->{job_type},
        query    => $p->{query}
    );

	# items in releases list
	my %already;
	my $rs = $c->model('Baseliner::BaliReleaseItems')->search({},{ prefetch=>['id_rel'] });
	while( my $r = $rs->next ) {
		$already{ $r->ns } = $r->id_rel->name;
	}

    # create json struct
	my @job_items;
	my $cnt=1;
	for my $n ( $list->list ) {
		my $ns = $n->ns;
		my $why_not = exists $already{ $ns } ? _loc("Already in release %1", $already{$ns} ) : '';
		my $can_job = $why_not ? 0 : 1; 
		my $rfc = try { $n->rfc } catch { '' };
		my $app = try { $n->application } catch { '' };
		$app = (ns_split( $app ))[1];
        push @job_items,
          {
			id => $cnt++,
            provider  => $n->provider,
            related   => $n->related,
            ns_type   => $n->ns_type,
            icon      => $why_not ? $n->icon_off : $n->icon_on,
            item      => $n->ns_name,
            ns        => $n->ns,
            user      => $n->user,
            service   => $n->service,
            text      => $n->ns_info,
            date      => $n->date,
			rfc       => $rfc,
			app       => $app,
            can_job   => $can_job,
			recordCls => $can_job ? '' : 'cannot-job',
            why_not   => $why_not,
            data      => $n->ns_data
          };
	}
	$c->stash->{json} = {
		totalCount => $list->{total},
		data => [ @job_items ]
	};
	$c->forward('View::JSON');
}

sub release_contents_json : Path('/release/contents/json') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	$c->stash->{id} = $p->{id};
	$c->forward('load_state_bl_maps');
	$c->forward('/release/release_contents');
	$c->stash->{json} = { 
		totalCount => scalar @{$c->stash->{contents}},
		data => $c->stash->{contents}
	};
	$c->forward('View::JSON');
}

sub release_list : Path('/release/list') {
    my ( $self, $c ) = @_;
	$c->stash->{template} = '/comp/release_grid.mas';
}

sub json : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;

	# fetch release namespaces
    my $list = $c->model('Namespaces')->list(
        does     => 'Baseliner::Role::Namespace::Release',
        does_not => 'Baseliner::Role::Namespace::PackageGroup',
        start    => $p->{start},
        limit    => $p->{limit},
        dir      => $p->{dir},
        sort     => $p->{'sort'},
        username => $p->{all} ? undef : $c->username,
        bl       => $p->{bl},
        states   => $p->{states},
        job_type => $p->{job_type},
        query    => $p->{query}
    );

    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};

	my @rows;
	for my $release ( _array $list->{data} ) {
		# get the release contents
		my $id = $release->ns_data->{id};
		$c->stash->{id} = $id;
        #faster: my @contents =  map { { %$_ } } grep { ref $_ } $release->contents;
        my @contents =  map { 
			my $n = $_;
			try { # try to get the namespace object, to see if it exists
				my $ns = $c->model('Namespaces')->get( $n->{ns} ); 
				+{ ns=>$ns->ns, ns_name=>$n->ns_name, valid=>1 };
			} catch {  # doesn't exist, point it out to the user
				+{ ns=>$n->{ns}, ns_name=>$n->{ns_name} , valid=>0 };
			};
		} grep { ref $_ } $release->contents;
		# prepare data
		#FIXME sooo slow: my $app = Baseliner->model('Namespaces')->get( $ns->ns_data->{ns} );
        my ($domain,$app) = ns_split( $release->ns_data->{ns} );

        push @rows, {
            id            => $id,
            name          => $release->ns_data->{name},
            description   => $release->ns_data->{description},
            username      => $release->ns_data->{username},
            active        => $release->ns_data->{active},
            locked        => $release->locked,
            locked_reason => $release->locked_reason,
            ts            => $release->created_on,
            application   => $app,
            bl_name       => Baseliner::Core::Baseline->name( $release->bl ),
            bl            => $release->bl,
            contents      => \@contents
          };
	}
	$c->stash->{json} = { 
		totalCount => $list->{total},
		data => \@rows
	};	
	$c->forward('View::JSON');
}

sub update : Local {

    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $action   = $p->{action};
    my $config   = $c->registry->get('config.release')->data;
    my $text     = $p->{release_name} || $p->{text};
    my $ns       = $p->{ns};
    my $comments = $p->{comments} || $p->{description};
    my $verb     = $p->{id_rel} ? 'altered' : 'created';
    my $app_code = '?';
    my $rfc      = $p->{rfc};

	try {
		# in case the state is defined and bl is unset
		if( ( ! $p->{bl} || $p->{bl} eq '*' ) && $p->{state} ) {
			my $inf = Baseliner->model('ConfigStore')->get('config.release.create' );
			my $s_bl = $inf->{state_bl_map}->{$p->{state}} ;
			$p->{bl} = $s_bl if defined $s_bl;
		}

		# take letter out of the rfc
		# $rfc =~ s{^[A-Z]}{};
		if ( $ns =~ m/GBP\.([]0-9]+)/ ) { $app_code = $1; }    #TODO mask this baby

		sub make_name { 'R.' . join( '.', @_ ) }

		my $release_name = $p->{id_rel} ? $text : make_name($app_code, $rfc, $text); #TODO mask this
		my $bl = $p->{bl} || '*'; 
		$p->{action} eq 'create' && $p->{bl} eq '*' and _throw _loc("Invalid release state");
		$ns = $p->{ns} || '/';
		my @nss = ns_split( $ns );
		$ns = 'application/' . $ns unless $nss[0]; # in case the domain is missing

        if( $action eq 'delete' ) {
            my $release = $c->model('Baseliner::Balirelease')->search({ id=> $p->{id_rel} })->first;
            $release->delete;
        }
        else {  # create or update
            # transactionalize this
            Baseliner->model('Baseliner')->txn_do( sub{
                # check if release name exists 
                unless( $p->{id_rel} ) {
                    my $other = $c->model('Baseliner::BaliRelease')->search({ name=>$release_name });
                    if( $other->first ) {
                        die _loc("Release Name '%1' already exists.",$release_name); 
                    }
                }

                # check if rfc is really valid
                $c->model('RFC')->check_rfc( $ns, $rfc );

                my $contents = decode_json( $p->{release_contents} );
                die _loc('No release contents') if( !$contents );
                my $release;

                # updating 
                if( $p->{id_rel} ) {
                    $release = $c->model('Baseliner::BaliRelease')->search({ id=> $p->{id_rel} })->first;
                    if( $release ) {
                        ( my $text = $release_name ) =~ s{^.*\.(.*?)$}{$1};
                        $release_name = make_name($app_code, $rfc, $text);
                        $release->name( $release_name );
                        $release->bl( $bl );
                        $release->ns( $ns );
                        $release->description( $comments );
                        $release->update;
                    }
                    # delete all old items, add new list later on...
                    my $rs = $c->model('Baseliner::BaliReleaseItems')->search({ id_rel=>$p->{id_rel} });
                    while( my $r = $rs->next ) {
                        $r->delete;
                    }
                    
                } else {
                    # brand new release
                    my $inf_rel = Baseliner->model('ConfigStore')->get('config.release', bl=>$bl);
                    my $active = $inf_rel->{create_active} || '0';
                    $release = $c->model('Baseliner::Balirelease')->create({
                            name         => $release_name,
                            username     => $c->username || 'internal',
                            bl           => $bl,
                            ns 			 => $ns,
                            description  => $comments,
                            active 	     => $active,
                    });
                }
                # add release items
                for my $ns ( _array $contents ) {
                    my $item = Baseliner->model('Namespaces')->get( $ns->{ns} );
                    die _loc("Invalid item %1", $ns->{item} || $ns->{ns} )."\n" unless ref $item;
                    my $items = $c->model('Baseliner::BaliReleaseItems')->create({
                            data     => _dump( $item->ns_data ),
                            ns       => $ns->{ns},
                            item     => $item->ns_name,
                            provider => $item->provider,
                            id_rel   => $release->id,
                     });
                }
                # add to project items
                if( $ns && defined( $release->id ) ) {
                    $c->model('Projects')->add_item( ns=>'release/'.$release->id, project=>$ns );
                }
            });  # txn_do
        }
		$c->stash->{json} = { success => \1, msg => _loc("Release %1 $verb.", $release_name) };
	} catch {
        my $err = shift;
		$c->stash->{json} = { success => \0, msg => _loc("Error creating the release: %1", $err) };
	};
	$c->forward('View::JSON');	
}
1;
