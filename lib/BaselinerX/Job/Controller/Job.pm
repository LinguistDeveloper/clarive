package BaselinerX::Job::Controller::Job;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use YAML;
use JavaScript::Dumper;
use Baseliner::Core::Namespace;
use JSON::XS;
use Try::Tiny;
use utf8;

BEGIN { extends 'Catalyst::Controller' }
BEGIN { 
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}

register 'action.job.viewall' => { name=>'View All Jobs' };
register 'action.job.restart' => { name=>'Restart Jobs' };

sub job_create : Path('/job/create')  {
    my ( $self, $c ) = @_;
	#$c->stash->{ns_query} = { does=> 'Baseliner::Role::JobItem' };
	#$c->forward('/namespace/load_namespaces'); # all namespaces
	$c->stash->{action} = 'action.job.create';
	$c->forward('/baseline/load_baselines_for_action');

    $c->stash->{template} = '/comp/job_new.mas';
}

# list objects ready for a job
sub job_items_json : Path('/job/items/json') {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;

	my $ns_list = $c->model('Namespaces')->list(
		can_job  => 1,
		does     => 'Baseliner::Role::JobItem',
		start    => $p->{start},
		limit    => $p->{limit},
		username => $c->username,
		bl       => $p->{bl},
		states   => $p->{states},
		job_type => $p->{job_type},
		query    => $p->{query}
	);
    # create json struct
	my @job_items;
	for my $n ( _array $ns_list->{data} ) {
		my $can_job = $n->can_job( job_type=>$p->{job_type}, bl=>$p->{bl} );
		# _log $n->ns . '.....CAN_JOB: ' . $can_job  . ( defined $n->{why_not} ? ', WHY_NOT: ' . $n->{why_not} : '' );

		# check if it's been processed by approval daemon
		if( $n->bl eq 'PREP' && $p->{job_type} eq 'promote' && ! $n->is_contained ) {
			unless( $n->is_verified ) {	
				$can_job = 0; 
				$n->{why_not} = _loc('Unverified');
			}
		}
		# id MUST be unique for the ns, otherwise Ext will allow duplicates, etc.
		my $id = $n->ns;
		$id =~ s{\W}{}g;  # clean up id, as this floats around the browser
        push @job_items,
          {
			id => $id,
            provider  => $n->provider,
            related   => $n->related,
            ns_type   => $n->ns_type,
            icon      => $n->icon_job,
            item      => $n->ns_name,
            ns        => $n->ns,
            user      => $n->user,
            service   => $n->service,
            text      => $n->ns_info,
            date      => $n->date,
            can_job   => $can_job,
			recordCls => $can_job ? '' : 'cannot-job',
            why_not   => $can_job ? '' : _loc($n->why_not),
            data      => $n->ns_data
          };
	}
	# _log "-----------Job total item: " . $ns_list->{total};
	$c->stash->{json} = {
		totalCount => $ns_list->{total},
		data => [ @job_items ]
	};
	$c->forward('View::JSON');
}

sub rs_filter {
    my ( $self, %p ) = @_;
    my $rs = $p{rs};
    my $start = $p{start};
    my $limit = $p{limit};
    my $filter = $p{filter};
    my $skipped = 0;
    my @ret;
    my $curr_rec = $start;
    my $processed = 0;
    OUTER: while(1) {
        my $cnt = 0;
        my $page = to_pages( start=>$start, limit=>$limit );
        _log "Fetch page=$page, start=$start, limit=$limit (count: $processed, fetched so far: " . @ret . ")...:";
        my $rs_paged = $rs->page( $page ); 
        last OUTER unless $rs_paged->count;
        while( my $r = $rs_paged->next ) {
            last OUTER unless defined $r;
            $processed++;
            if( ref $filter && $filter->($r) ) {
                push @ret, $r;  
            } else {
                $skipped++;
            }
            $cnt = @ret;
            if( @ret >= $limit ) {
                _log "Done with $cnt >= $limit, from $processed rows.";
                last OUTER; 
            }
        }
        $start+=$limit;
    }
    _log "Total: " . scalar(@ret);
    return { data=>\@ret, skipped=>$skipped, next_start=>$curr_rec + $processed };
}

sub job_logfile : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $job = $c->model('Baseliner::BaliJob')->find( $p->{id_job} );
    $c->stash->{json}  = try {
        my $file = _load( $job->stash )->{logfile};
        _throw _log "Error: logfile not found or invalid: %1", $file if ! -f $file;
        my $data = _file( $file )->slurp; 
        { data=>$data, success=>\1 };
    } catch {
        { success=>\0, msg=>"".shift() };
    };
    $c->forward( 'View::JSON' );
}

sub job_stash : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $job = $c->model('Baseliner::BaliJob')->find( $p->{id_job} );
    $c->stash->{json}  = try {
        my $stash = $job->stash;
        $c->stash->{job_stash} = $stash;
        { stash=>$stash, success=>\1 };
    } catch {
        { success=>\0 };
    };
    $c->forward( 'View::JSON' );
}

sub job_stash_save : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $job = $c->model('Baseliner::BaliJob')->find( $p->{id_job} );
    $c->stash->{json}  = try {
        $job->stash( $p->{stash} );
        { msg=>_loc( "Stash saved ok"), success=>\1 };
    } catch {
        { success=>\0, msg=>shift() };
    };
    $c->forward( 'View::JSON' );
}

sub monitor_json : Path('/job/monitor_json') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $username = $c->username;
	my $perm = $c->model('Permissions');

    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    $start||=0;
    $limit||=50;
	defined $query and $query =~ s/\*/%/g;
	my ($select,$order_by, $as) = $sort
		? ([{ distinct=>'me.id'} ,$sort]         , "$sort $dir, me.starttime desc", ['id'])
		: ([{ distinct=>'me.id'} ,'me.starttime'], "me.starttime desc"            , ['id', 'starttime']);

    $start=$p->{next_start} if $p->{next_start} && $start && $query;

	my $page = to_pages( start=>$start, limit=>$limit );
    my $where = {};
	my $query_limit = 300;

	# user content
	if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
		my @user_apps = $perm->user_namespaces( $username ); # user apps
		$where->{'bali_job_items.application'} = { -in => \@user_apps } if ! ( grep { $_ eq '/'} @user_apps );
		# username can view jobs where the user has access to view the jobcontents corresponding app
		# username can view jobs if it has action.job.view for the job set of job_contents projects/app/subapl
	}
	_log "Job search...";
    $query and $where = query_sql_build( query=>$query, fields=>{
        name     =>'me.name',
        id       =>'to_char(me.id)',
        user     =>'me.username',
        comments =>'me.comments',
        status   =>'me.status',
        start    =>"me.starttime",
        sched    =>"me.schedtime",
        end      =>"me.endtime",
        items    =>"bali_job_items.item",
    });
	my $rs_search = $c->model('Baseliner::BaliJob')->search(
        $where,
		{
			select => $select,
			as => $as,
			join => [ 'bali_job_items' ],	
			page=>0, rows=>$query_limit,
			order_by => $order_by,
		}
	);
	rs_hashref( $rs_search );
	my @ids = map { $_->{id} } $rs_search->all; 
	_log "Job search end.";
	my $rs = $c->model('Baseliner::BaliJob')->search(
        { 'me.id'=>{ -in =>\@ids } },
		{
			page=>$page, rows=>$limit,
			order_by => $order_by,
		}
	);
	my $pager = $rs->pager;
	$cnt = $pager->total_entries;
	#$cnt = $query ? $pager->total_entries : $query_limit;
	#$cnt = 1000;

	# Job items cache
	_log "Items cache start...";
	my $rs_items = $c->model('Baseliner::BaliJobItems')->search({ id_job=>\@ids },{ select=>[qw/id id_job application item/] } );
	rs_hashref( $rs_items );
	my %job_items;
	for( $rs_items->all ) {
		push @{ $job_items{ $_->{id_job} } }, $_;
	}
	_log "Items cache end.";
=head1
    my $results = $self->rs_filter( rs=>$rs, start=>$start, limit=>$limit, query=>$query, filter=>sub {
		return 1 unless $query;	
        my $r = shift;
        my $step = _loc( $r->step );
        my $status = _loc( $r->status );
        my $type = _loc( $r->type );
		my $last_log_message = ""; #$r->last_log_message;
        return !( $query && !query_array($query, $last_log_message, $status, $step, $r->name, $r->comments, $r->type, $type, $r->bl, $r->owner, $r->username ) );
    });
=cut
	my @rows;
	#while( my $r = $rs->next ) {
	my $now = _dt();
	my $today = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>0, minute=>0 ) ; 
	my $ahora = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>$now->hour, minute=>$now->minute ) ; 

    #foreach my $r ( _array $results->{data} ) {
    while( my $r = $rs->next ) {
        my $step = _loc( $r->step );
        my $status = _loc( $r->status );
        my $type = _loc( $r->type );
		my %app;
		my @items = _array $job_items{$r->id};
        my $contents = @items ? [
			  map {
				  $app{ $_->{application} }=() if defined $_->{application};
				  ( ns_split( $_->{item} ) )[1]
			  } @items
		  ] : [];
		my $apps = [ map { (ns_split( $_ ))[1] } grep {$_} keys %app ];
		my $last_log_message = $r->last_log_message;

		# Scheduled, Today, Yesterday, Weekdays 1..7, 1..4 week ago, Last Month, Older
		my $grouping='';
		my $day;  
		my $dur =  $today - $r->starttime ; 
		my $sdt = $r->starttime;
		$sdt->{locale} = DateTime::Locale->load( $c->languages->[0] || 'en' );
        $day =
            $dur->{months} > 3 ? [ 90, _loc('Older') ]
          : $dur->{months} > 2 ? [ 80, _loc( '%1 Months', 3 ) ]
          : $dur->{months} > 1 ? [ 70, _loc( '%1 Months', 2 ) ]
          : $dur->{months} > 0 ? [ 60, _loc( '%1 Month',  1 ) ]
          : $dur->{days} >= 21  ? [ 50, _loc( '%1 Weeks',  3 ) ]
          : $dur->{days} >= 14  ? [ 40, _loc( '%1 Weeks',  2 ) ]
          : $dur->{days} >= 7   ? [ 30, _loc( '%1 Week',   1 ) ]
          : $dur->{days} == 6   ? [ 7,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 5   ? [ 6,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 4   ? [ 5,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 3   ? [ 4,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 2   ? [ 3,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 1   ? [ 2,  _loc( $sdt->day_name ) ]
          : $dur->{days} == 0  ? $r->starttime < $today ? [ 2,  _loc( $sdt->day_name ) ]
                               : $r->starttime > $ahora ? [ 0,  _loc('Upcoming') ] : [ 1,  _loc('Today') ]
          :                      [ 0,  _loc('Upcoming') ];
		$grouping = $day->[0];

        push @rows, {
            id           => $r->id,
            name         => $r->name,
            bl           => $r->bl,
            bl_text      => $r->bl,                        #TODO resolve bl name
            starttime    => $r->get_column('starttime'),
            schedtime    => $r->get_column('schedtime'),
            maxstarttime => $r->get_column('maxstarttime'),
            endtime      => $r->get_column('endtime'),
            comments     => $r->get_column('comments'),
            username     => $r->get_column('username'),
            rollback     => $r->get_column('rollback'),
            key          => $r->get_column('key'),
			last_log     => $last_log_message,
			grouping     => $grouping,
			day          => ucfirst( $day->[1] ),
			contents     => $contents,
			applications => $apps,
            step         => $step,
            step_code    => $r->step,
            exec         => $r->get_column('exec'),
            pid          => $r->get_column('pid'),
            owner        => $r->get_column('owner'),
            host         => $r->get_column('host'),
            status       => $status,
            status_code  => $r->status,
            type_raw     => $r->get_column('type'),
            type         => $type,
            runner       => $r->runner,
          }; # if ( ( $cnt++ >= $start ) && ( $limit ? scalar @rows < $limit : 1 ) );
	}
    
    my @sorted = sort { $b->{grouping}<=>$a->{grouping} || $b->{starttime} cmp $a->{starttime} } @rows;
    
	$c->stash->{json} = { 
        totalCount=> $cnt,
        #next_start => $results->{next_start},
        data => \@sorted
     };	
	$c->forward('View::JSON');
}

sub monitor_json_from_config : Path('/job/monitor_json_from_config') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $config = $c->registry->get( 'config.job' );
	my @rows = $config->rows( query=> $p->{query}, sort_field=> $p->{'sort'}, dir=>$p->{dir}  );
	#my @jobs = qw/N0001 N0002 N0003/;
	#push @rows, { job=>$_, start_date=>'22/10/1974', status=>'Running' } for( $p->{dir} eq 'ASC' ? reverse @jobs : @jobs );
	$c->stash->{json} = { cat => \@rows };	
	$c->forward('View::JSON');
}

sub refresh_now : Local {
    my ( $self, $c ) = @_;
	use String::CRC32;
	my $p = $c->request->parameters;
	my $username = $c->username;
	my $need_refresh = 0;
	my $magic = 0;
	try {
		if( exists $p->{top} ) {
			# are there newer jobs?
			my $max = ( reverse( sort( _array( $p->{ids} ))) )[0];
			my $where;
			my $w = $c->session->{job_refresh_where};
			if( 'HASH' eq ref $w ) {
				$where = $w;
			} else {
				$where = {};
				my $perm = $c->model('Permissions');
				if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
					my @user_apps = $perm->user_namespaces( $username ); # user apps
					$where->{'bali_job_items.application'} = { -in => \@user_apps };
				}
				$c->session->{job_refresh_where} = $where;
			}
			$where->{'me.id'} = { '>' => $p->{top} };
			delete $where->{id} if defined $where->{id}; # leftover from seesion object
			my $row = $c->model('Baseliner::BaliJob')->search( $where, { join=>['bali_job_items'], order_by=>'me.id desc' })->first;
			if( ref $row ) {
				$need_refresh = 1;
			}
		}
		if( $p->{ids} ) {
			# are there more info for current jobs?
			my $rs = $c->model('Baseliner::BaliJob')->search({ id=>$p->{ids} }, { order_by=>'id desc' });
			my $data ='';
			while( my $r = $rs->next ) {
				$data.=$r->status . $r->last_log_message; 
			}
			$magic = String::CRC32::crc32( $data );
		}
	} catch { _log shift };
	$c->stash->{json} = { magic=>$magic, need_refresh => $need_refresh, stop_now=>\0 };	
	$c->forward('View::JSON');
}

# sub job_check_time : Path('/job/check_time') {
    # my ( $self, $c ) = @_;
	# my $p = $c->request->parameters;
	# my $day = $p->{job_date};
    # my $contents = _decode_json $p->{job_contents};
    # my @ns;
    # for my $item ( @{ $contents || [] } ) {
        # my $provider = $item->{provider};
        # push @ns, @{ $item->{related} || [] };
        # push @ns, $item->{ns};
        
    # }
    # warn "....................NS: " . join ',', @ns;
#	get calendar range list
    # $c->stash->{day} = $day;
    # $c->stash->{bl} = $p->{bl};
    # $c->stash->{ns} = \@ns;
	# $c->forward('/calendar/calendar_range');
#    warn Dump $c->stash->{calendar_range_expand} ; 
	# $c->stash->{json} = { data => $c->stash->{calendar_range_expand} };	
	# $c->forward('View::JSON');
# }

sub get_namespaces{
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $contents = _decode_json $p->{job_contents};

	my @ns;
    for my $item ( @{ $contents || [] } ) {
     	my $namespace = $c->model('Namespaces')->get($item->{ns});
        push @ns, "/";
        push @ns, $item->{ns};
        push @ns, $namespace->application;
        push @ns, _array $namespace->nature;
    }
	my %tmp_hash   = map { $_ => 1 } @ns;
	
	@ns = keys %tmp_hash;    
	return \@ns;
}


sub get_namespaces_calendar{
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $contents = _decode_json $p->{job_contents};
	my @ns;
	my @ns_list;
    $contents = $c->model('Jobs')->container_expand( $contents );
    for my $item ( @{ $contents || [] } ) {
		_debug "Check NS=" . $item->{ns};
     	my $namespace = $c->model('Namespaces')->get($item->{ns});
        push @ns_list, $item->{ns};
        @ns_list = ( @ns_list , _array $namespace->nature );
        push @ns_list, $namespace->application;
        push @ns_list, "/";
		foreach my $curr_ns (@ns_list){
			my $r = $c->model('Baseliner::BaliCalendar')->search({ns=>{ -like => $curr_ns } });
			if($r->next){
				push @ns, $curr_ns;
				next;
			}
		}
    }
	_debug "Selected NS=" . join ',',@ns;
	my %tmp_hash   = map { $_ => 1 } @ns;
	
	@ns = keys %tmp_hash;    
	return \@ns;
}

sub job_check_date : Path('/job/check_date') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $date = $p->{job_date};
    my $contents = _decode_json $p->{job_contents};
    $contents = $c->model('Jobs')->container_expand( $contents );
	my $month_days = 31;	
 
	try {
		#warn "....................NS: " . join ',', @ns;
		# get calendar range list
		$c->stash->{start_date} = ($date)?BaselinerX::Job::Controller::Calendar->parseDateTime($date):DateTime->now;
		# Se calculan los dias visibles en el calendario dando una semana de gracia para visualizar la primera semana del siguiente mes
		my $add_days = ($month_days - $c->stash->{start_date}->day() ) + $month_days + 7;
		
		$add_days = $month_days * 3;
		$c->stash->{end_date} = BaselinerX::Job::Controller::Calendar->addDaysToDateTime($c->stash->{start_date},$add_days);
		$c->stash->{bl} = $p->{bl};
		$c->stash->{ns} = $self->get_namespaces_calendar($c);
		_debug "------Checking dates for namespaces: " . _dump($c->stash->{ns});
		$c->forward('/calendar/date_intersec_range');
		_debug _dump( $c->stash->{calendar_range_expand} ); 
		$c->stash->{json} = {success=>\1, data => $c->stash->{range_enabled} };	
	} catch {
		my $error = shift;
		$c->stash->{json} = {success=>\0, data => $error };	
	};
	$c->forward('View::JSON');
}

sub job_check_time : Path('/job/check_time') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $date = $p->{job_date};

	try {
		my $contents = _decode_json $p->{job_contents};
        $contents = $c->model('Jobs')->container_expand( $contents );
		#warn "....................NS: " . join ',', @ns;
		# get calendar range list
		$c->stash->{date_selected} = BaselinerX::Job::Controller::Calendar->parseDateTime($date);
		# Se calculan los dias visibles en el calendario dando una semana de gracia para visualizar la primera semana del siguiente mes

		$c->stash->{bl} = $p->{bl};
		$c->stash->{ns} = $self->get_namespaces_calendar($c);
		$c->forward('/calendar/time_range_intersec');
		#warn Dump $c->stash->{calendar_range_expand} ; 
		$c->stash->{json} = {success=>\1, data => $c->stash->{time_range} };	
	} catch {
		my $error = shift;
		$c->stash->{json} = {success=>\0, data => $error };	
	};
	$c->forward('View::JSON');
}

sub job_submit : Path('/job/submit') {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	my $config = $c->registry->get('config.job')->data;
	my $runner = $config->{runner};
	my $job_name;
    my $username = $c->user ? $c->user->username || $c->user->id : '';

	#TODO move this whole thing to the Model Jobs
	try {
		if( $p->{action} eq 'delete' ) {
			my $job = $c->model('Baseliner::BaliJob')->search({ id=> $p->{id_job} })->first;
			if( $job->status =~ /CANCELLED|KILLED/ ) {
                # be careful: may be cancelled already
                $p->{mode} ne 'delete' and die _loc('Job already cancelled'); 
				# cancel pending requests
				$c->model('Request')->cancel_for_job( id_job=>$job->id );
				$job->delete;
				$job->update;
			}
			elsif( $job->status =~ /RUNNING/ ) {
				$job->status( 'CANCELLED' );
				$c->model('Request')->cancel_for_job( id_job=>$job->id );
				$job->update;
			} else {
				$job->status( 'CANCELLED' );
				# cancel pending requests
				$c->model('Request')->cancel_for_job( id_job=>$job->id );
				$job->update;
				my $log = new BaselinerX::Job::Log({ jobid=>$job->id });
				$log->error(_loc("Job cancelled by user %1", $username));
			}
		}
		elsif( $p->{action} eq 'rerun' ) {
			my $job = $c->model('Jobs')->rerun( jobid=>$p->{id_job}, username=>$username ); 
		}
		else { # new job
			my $bl = $p->{bl};
			my $comments = $p->{comments};
			my $job_date = $p->{job_date};
			my $job_time = $p->{job_time};
			my $job_type = $p->{job_type};
			my $contents = _decode_json $p->{job_contents};
			die _loc('No job contents') if( !$contents );
			# create job
			#my $start = parse_date('Y-mm-dd hh:mi', "$job_date $job_time");
			my $start = parse_dt( '%Y-%m-%d %H:%M', "$job_date $job_time");
			#$start->set_time_zone('CET');
			my $end = $start->clone->add( hours => 1 );
			my $ora_start =  $start->strftime('%Y-%m-%d %T');
			my $ora_end =  $end->strftime('%Y-%m-%d %T');

            # not in an authorized calendar
            my $approval = { reason=>_loc('Pase fuera de ventana') }
				if $p->{window_check} eq 'on';
			my $job = $c->model('Jobs')->create( 
					starttime    => $start,
					maxstarttime => $end,
					status       => 'IN-EDIT',
                    approval     => $approval,
                    step         => 'PRE',
					type         => $job_type,
					ns           => '/',
					bl           => $bl,
                    username     => $username,
					runner       => $runner,
					comments     => $comments,
					items => $contents
			);
            $job_name = $job->name;
			#$job_name = $c->model('Jobs')->job_name({ mask=>'%s.%s%08d', type=>$job_type, bl=>$bl, id=>$job->id });
			#$job->name( $job_name );
			#$job->update;
		}
		$c->stash->{json} = { success => \1, msg => _loc("Job %1 created", $job_name) };
	} catch {
		my $err = shift;
		_log "Error during job creation: $err";
		$err =~ s{DBIx.*\(\):}{}g;
		$c->stash->{json} = { success => \0, msg => _loc("Error creating the job: %1", $err ) };
	};
	$c->forward('View::JSON');	
}

sub restart : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	
	try {
		my $job = $c->model('Jobs')->rerun(
			jobid    =>$p->{id_job},
            username =>$p->{username},
            step     => $p->{step},
            run_now  => $p->{run_now} eq 'on',
			realuser =>$c->username,
			starttime=>$p->{starttime} ); 
		$c->stash->{json} = { success => \1, msg => _loc("Job %1 restart", $p->{job_name} ) };
	} catch {
		my $err = shift;
		$c->stash->{json} = { success => \0, msg => _loc("Error creating the job: %1", $err ) };
	};
	$c->forward('View::JSON');	
}

sub monitor : Path('/job/monitor') {
    my ( $self, $c ) = @_;
    $c->languages( ['es'] );
	my $config = $c->registry->get( 'config.job' );
	$c->forward('/permissions/load_user_actions');
    $c->stash->{template} = '/comp/monitor_grid.mas';
}

sub monitor_portlet : Local {
    my ( $self, $c ) = @_;
	$c->forward('/job/monitor');
	$c->stash->{is_portlet} = 1;
}

sub export : Local {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
	return unless ref $c->model('Jobs')->user_has_access(id=>$p->{id_job}, username=>$c->username );

	my $file = $c->model('Jobs')->export( id=>$p->{id_job}, format=>'tar', file=>1 );
	return unless $file;

	my $filename = $p->{filename} || "job-$p->{id_job}.tar.gz";

    $c->res->headers->remove_header('Cache-Control');
    $c->res->header('Content-Disposition', qq[attachment; filename=$filename]);
	$c->res->content_type('application-download;charset=utf-8');
	$c->serve_static_file( $file );
	#$c->res->body( $data );
}

sub resume : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id_job};
    try {
        my $job = $c->model('Jobs')->resume( id=>$id, username=>$c->username );
        $c->stash->{json} = { success => \1, msg => _loc("Job %1 resumed", $p->{job_name} ) };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => _loc("Error resuming the job: %1", $err ) };
    };
    $c->forward('View::JSON');  
}

1;
