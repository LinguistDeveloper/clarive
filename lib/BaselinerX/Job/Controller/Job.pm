package BaselinerX::Job::Controller::Job;
use v5.10;
use Baseliner::Core::Namespace;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use JSON::XS;
use JavaScript::Dumper;
use Baseliner::Core::Namespace;
use Try::Tiny;
use utf8;

BEGIN { extends 'Catalyst::Controller' }
BEGIN { 
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}

register 'action.job.viewall' => { name=>'View All Jobs' };
register 'action.job.restart' => { name=>'Restart Jobs' };

register 'config.job.states' => {
  metadata => [
    { id      => "states",
      default => [qw/EXPIRED READY APPROVAL REJECTED RUNNING FINISHED CANCELLED ERROR KILLED WAITING/]
    }
  ]
};

sub job_create : Path('/job/create')  {
    my ( $self, $c ) = @_;

    my @features_list = Baseliner->features->list;
    $c->stash->{custom_forms} = [
         map { "/include/job_new/" . $_->basename }
         map {
            $_->children
         }
         grep { -e $_ } map { Path::Class::dir( $_->path, 'root', 'include', 'job_new') }
                @features_list 
    ];
    # rgo: new stuff, untested in bde:
    # $c->stash->{action} = 'action.job.create';
    # $c->forward('/baseline/load_baselines_for_action');

    $c->stash->{$_} = $c->config->{header_init}->{$_} for keys %{$c->config->{header_init} || {}};
    push my @baselines, $c->model('Permissions')->user_baselines_for_action(username=>$c->username, action=>'action.job.create');
    push @baselines, $c->model('Permissions')->user_baselines_for_action(username=>$c->username, action=>'action.job.create.Z');
    
    # @baselines=_unique @baselines;
    _debug _dump @baselines;
    $c->stash->{baselines} =  \@baselines;
    $c->stash->{template} = '/comp/job_new.js';
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

        my $packages_text;
        my $package_join = "<img src=\"static/images/package.gif\"/>";
        $packages_text = $package_join
                       . join("<br>${package_join}", @{$n->{packages}})
                       . '<br>' if exists $n->{packages};

        # id MUST be unique for the ns, otherwise Ext will allow duplicates, etc.
        my $id = $n->ns;
        $id =~ s{\W}{}g;  # clean up id, as this floats around the browser
        push @job_items,
          {
            id                 => $id,
            provider           => $n->provider,
            related            => $n->related,
            ns_type            => $n->ns_type,
            icon               => $n->icon_job,
            item               => $n->ns_name,
            packages           => $packages_text ? $packages_text : q{},
            subapps            => $n->{subapps},
            inc_id             => exists $n->{inc_id} ? $n->{inc_id} : q{},
            ns                 => $n->ns, 
            user               => $n->user,
            service            => $n->service,
            text               => do { my $a = $n->ns_info; Encode::from_to($a, 'utf8', 'iso-8859-1'); $a },
            more_info          => $n->more_info,  # TODO which one?
            moreInfo           => exists $n->{moreInfo} ? $n->{moreInfo} : q{},
            date               => $n->date,
            can_job            => $can_job,
            recordCls          => $can_job ? '' : 'cannot-job',
            why_not            => $can_job ? '' : _loc($n->why_not),
            data               => $n->ns_data
          };
    }
    # _log "-----------Job total item: " . $ns_list->{total};
    #_log Data::Dumper::Dumper \@job_items;
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
        _fail _log "Error: logfile not found or invalid: %1", $file if ! -f $file;
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

our %CACHE_ICON;

sub monitor_json : Path('/job/monitor_json') {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $username = $c->username;
    my $perm = $c->model('Permissions');
    my $state_filter = $p->{job_state_filter} || '{"CANCELLED":0,"REJECTED":0,"APPROVAL":1,"READY":1,"ERROR":1,"EXPIRED":1,"FINISHED":1,"KILLED":1,"RUNNING":1,"WAITING":1}'; 

    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt ) = @{$p}{qw/start limit query query_id dir sort/};
    $start||=0;
    $limit||=50;

    my ($select,$order_by, $as) = $sort
        ? (['me.id' ,$sort]         , [ { "-$dir" => $sort }, { -desc => 'me.starttime' } ], [ 'id', $sort ])
        : (['me.id' ,'me.starttime'], [ { -desc => "me.starttime" }, { -desc => 'me.id' } ] , ['id', 'starttime'] );

    $start=$p->{next_start} if $p->{next_start} && $start && $query;

    my $page = to_pages( start=>$start, limit=>$limit );

    ### WHERE
    _log "Job search...";
    my $where = {};
    defined $query and $query =~ s/\*/%/g;
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

=head
    if( exists $p->{job_state_filter}) {
        my @job_state_filters = do {
                my $job_state_filter = decode_json $p->{job_state_filter};
                _unique grep { $job_state_filter->{$_} } keys %$job_state_filter;
        };
        $where->{status} = \@job_state_filters;
    }
=cut

    # Filter by status


    # Filter by nature
    my @job_state_filters = do {
       my $job_state_filter = decode_json $state_filter;
       _unique grep { $job_state_filter->{$_} } keys %$job_state_filter;
    };
    $where->{status} = \@job_state_filters;

    if (exists $p->{filter_nature} && $p->{filter_nature} ne 'ALL' ) {      
      $where->{'bali_job_items_2.item'} = $p->{filter_nature};
    }

    # Filter by environment name:
    if (exists $p->{filter_bl}) {      
      $where->{bl} = $p->{filter_bl};
    }

    # Filter by job_type
    if (exists $p->{filter_type}) {      
      $where->{type} = $p->{filter_type};
    }

    #dashboard
    if($query_id){
        my @arreglo = split(",",$query_id);
        $where->{'me.id'} = \@arreglo;
    }  

    # user content
    if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
        my @user_apps = $perm->user_projects_names( username=>$username ); # user apps
        $where->{'bali_job_items.application'} = { -in => \@user_apps } if ! ( grep { $_ eq '/'} @user_apps );
        # username can view jobs where the user has access to view the jobcontents corresponding app
        # username can view jobs if it has action.job.view for the job set of job_contents projects/app/subapl
    }
    _debug $where;

    ### FROM 
    my $from = {
        select   => 'me.id',
        as       => $as,
        join     => [ 'bali_job_items', 'bali_job_items' ],  # one for application, another for filter_nature 
    };
    _debug $from;
    my $rs_search = $c->model('Baseliner::BaliJob')->search( $where, $from );
    # rs_hashref( $rs_search );
    # my @ids = map { $_->{id} } $rs_search->all; 
    my $id_rs = $rs_search->search( undef, { select=>[ 'me.id' ] } );

    #_error _dump $id_rs->as_query ;

    _debug "Job search end.";
    my $rs_paged = $c->model('Baseliner::BaliJob')->search(
        { 'me.id'=>{ -in => $id_rs->as_query } },
        {
            page=>$page, rows=>$limit,
            order_by => $order_by,
        }
    );
    my $pager = $rs_paged->pager;
    $cnt = $pager->total_entries;

    # Job items cache
    _log "Job data start...";
    my %job_items = $c->model('Baseliner::BaliJobItems')
        ->search(
            { id_job=>{ -in => $rs_paged->search(undef,{ select=>'id'})->as_query } },
            { select=>[qw/id id_job application item/] }
    )->hash_on( 'id_job' );
    _log "Job data end.";

    my @rows;
    #while( my $r = $rs->next ) {
    my $now = _dt();
    my $today = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>0, minute=>0, second=>0) ; 
    my $ahora = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>$now->hour, minute=>$now->minute, second=>$now->second ) ; 

    #foreach my $r ( _array $results->{data} ) {
    _debug "Looping start...";
    for my $r ( $rs_paged->hashref->all ) {
        my $step = _loc( $r->{step} );
        my $status = _loc( $r->{status} );
        my $type = _loc( $r->{type} );
        my %app;
        my @items = _array $job_items{ $r->{id} };
        my $contents = @items ? [
              grep { defined } map {
                  $app{ $_->{application} }=() if defined $_->{application};
                  my ( $dom,$nsid) = ns_split( $_->{item} );
                  my $ret;
                  if( $dom eq 'changeset' ) {
                    $ret = try { $c->model('Baseliner::BaliTopic')->find( $nsid )->full_name } catch { $nsid };
                  } elsif( $dom !~ /nature/ ) {
                    my $icon = $CACHE_ICON{ $dom } // do {
                        my $m = $c->registry->get( $dom )->module;
                        $CACHE_ICON{ $dom } = $m->icon;
                    };
                    $ret = $icon 
                          ? qq{<img src="$icon">&nbsp;$nsid}
                          : $nsid;
                  }
                  $ret;
              } @items
          ] : [];
        my $apps = [ map { (ns_split( $_ ))[1] } grep {$_} keys %app ];
        my $last_log_message = $r->{last_log_message};

        my @subapps = _unique map {
            (ns_split( $_->{item} ))[1];
        } grep {
            $_->{item} =~ /^subap/
        } _array $job_items{ $r->{id} };

        my @natures = _unique map {
            $_->{item}  # the ns name of the nature
        } grep {
            $_->{item} =~ /^nature/
        } _array $job_items{ $r->{id} };

        # Scheduled, Today, Yesterday, Weekdays 1..7, 1..4 week ago, Last Month, Older
        my $grouping='';
        my $day;  
        #my $sdt = parse_dt( '%Y-%m-%d %H:%M', $r->{starttime}  );
        my $sdt = parse_dt( '%Y-%m-%d', $r->{starttime}  );
        my $dur =  $today - $sdt; 
        $sdt->{locale} = DateTime::Locale->load( $c->languages->[0] || 'en' ); # day names in local language
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
          : $dur->{days} == 0  ? $sdt < $today ? [ 2,  _loc( $sdt->day_name ) ]
                               : $sdt > $ahora ? [ 0,  _loc('Upcoming') ] : [ 1,  _loc('Today') ]
          :                      [ 0,  _loc('Upcoming') ];
        $grouping = $day->[0];

        push @rows, {
            id           => $r->{id},
            mid           => $r->{mid},
            name         => $r->{name},
            bl           => $r->{bl},
            bl_text      => $r->{bl},                        #TODO resolve bl name
            starttime    => $r->{starttime},
            schedtime    => $r->{schedtime},
            maxstarttime => $r->{maxstarttime},
            endtime      => $r->{endtime},
            comments     => $r->{comments},
            username     => $r->{username},
            rollback     => $r->{rollback},
            key          => $r->{job_key},
            last_log     => $last_log_message,
            grouping     => $grouping,
            day          => ucfirst( $day->[1] ),
            contents     => $contents,
            applications => $apps,
            step         => $step,
            step_code    => $r->{step},
            exec         => $r->{'exec'},
            pid          => $r->{pid},
            owner        => $r->{owner},
            host         => $r->{host},
            status       => $status,
            status_code  => $r->{status},
            type_raw     => $r->{type},
            type         => $type,
            runner       => $r->{runner},
            natures      => \@natures,
            subapps      => \@subapps,   # maybe use _path_xs from Utils.pm?
          }; # if ( ( $cnt++ >= $start ) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    _debug "Looping end ";

    $c->stash->{json} = { 
        totalCount=> $cnt,
        #next_start => $results->{next_start},
        data => \@rows,
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
    my $need_refresh = \0;
    my $magic = 0;
    my $real_top;

    try {
        if( exists $p->{top} ) {
            # are there newer jobs?
            my $row = DB->BaliJob->search(undef, { order_by=>{ -desc =>'id' } })->first;
            $real_top= $row->id;
            if( $real_top ne $p->{top} && $real_top ne $p->{real_top} ) {
                $need_refresh = \1;
            }
        }
        if( $p->{ids} ) {
            # are there more info for current jobs?
            my @rows = DB->BaliJob->search({ id=>$p->{ids} }, { order_by=>{ -desc =>'id' } })->hashref->all;
            my $data ='';
            map { $data.= ( $_->{status} // '') . ( $_->{last_log_message} // '') } @rows;
            $magic = String::CRC32::crc32( $data );
            my $last_magic = $p->{last_magic};
            if( $magic ne $last_magic ) {
                _debug "LAST MAGIC=$last_magic != CURRENT MAGIC $magic";
                $need_refresh = \1;
            }
        }
    } catch { _log shift };
    $c->stash->{json} = { success=>\1, magic=>$magic, need_refresh => $need_refresh, stop_now=>\0, real_top=>$real_top };	
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
        use Baseliner::Sugar;
        if( $p->{action} eq 'delete' ) {
            my $job = $c->model('Baseliner::BaliJob')->search({ id=> $p->{id_job} })->first;
            my $msg = '';
            if( $job->status =~ /CANCELLED|KILLED/ ) {

                event_new 'event.job.delete' => { c=>$c, self=>$self, job=>$job }  => sub {
                    # be careful: may be cancelled already
                    $p->{mode} ne 'delete' and die _loc('Job already cancelled'); 
                    # cancel pending requests
                    $c->model('Request')->cancel_for_job( id_job=>$job->id );
                    $job->delete;
                    $job->update;
                };
                $msg = "Job %1 deleted";
            }
            elsif( $job->status =~ /RUNNING/ ) {
                event_new 'event.job.cancel_running' => { c=>$c, self=>$self, job=>$job } => sub {
                    $job->status( 'CANCELLED' );
                    $c->model('Request')->cancel_for_job( id_job=>$job->id );

                    sub job_submit_cancel_running : Private {};
                    $c->forward( 'job_submit_cancel_running', $job, $job_name, $username );
                };
                $msg = "Job %1 cancelled";
            } else {
                event_new 'event.job.cancel'  => { c=>$c, self=>$self, job=>$job } => sub {
                    $job->status( 'CANCELLED' );
                    # cancel pending requests
                    $c->model('Request')->cancel_for_job( id_job=>$job->id );

                };
                $msg = "Job %1 cancelled";
            }
            $c->stash->{json} = { success => \1, msg => _loc( $msg, $job_name) };
        } elsif( $p->{action} eq 'rerun' ) {
            my $job = $c->model('Jobs')->rerun( jobid=>$p->{id_job}, username=>$username ); 
        }
        else { # new job
            my $id_job;
            my $bl = $p->{bl};
            my $comments = $p->{comments};
            my $job_date = $p->{job_date};
            my $job_time = $p->{job_time};
            my $job_type = $p->{job_type};
            my $job_stash = try { _decode_json( $p->{job_stash} ) } catch { +{} };
            
            my $contents = _decode_json $p->{job_contents};
            die _loc('No job contents') if( !$contents );

            _debug "*** Job Stash: " . _dump $job_stash;
            # create job
            #my $start = parse_date('Y-mm-dd hh:mi', "$job_date $job_time");
            my $start = parse_dt( '%Y-%m-%d %H:%M', "$job_date $job_time");
            #$start->set_time_zone('CET');
            my $end = $start->clone->add( hours => 1 );
            my $ora_start =  $start->strftime('%Y-%m-%d %T');
            my $ora_end =  $end->strftime('%Y-%m-%d %T');
            my $approval = undef;
            
            # U -- urgent calendar
            if ( config_value('job_new.approve_urgent') && $p->{window_type} eq 'U') {
                $approval = { reason=>_loc('Urgent Job') };
            }
                
            # not in an authorized calendar
            if ( config_value('job_new.approve_no_cal') && $p->{check_no_cal} eq 'on') {
                $approval = { reason=>_loc('Job not in a window') };
            }
                
            my $job_data = {
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
                    items        => $contents, 
                    job_stash    => $job_stash
            };
            event_new 'event.job.new' => { c=>$c, self=>$self, job_data=>$job_data } => sub {
                my $job = $c->model('Jobs')->create( %$job_data );
                $job_name = $job->name;
                $id_job = $job->id;
                { job=>$job }; 
            };
            
            $c->stash->{json} = { success => \1, msg => _loc("Job %1 created", $job_name), job_name=>$job_name, id_job => $id_job };
        }
    } catch {
        my $err = shift;
        _error "Error during job creation: $err";
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

sub natures_json {
  my @data = sort { uc $a->{name} cmp uc $b->{name} } 
             map { { key=>$_->{key}, id=>$_->{id}, name => _loc($_->{name}), ns => $_->{ns}, icon => $_->{icon}} }
             map { Baseliner::Core::Registry->get($_) }
             Baseliner->registry->starts_with('nature');
  _encode_json \@data;
}

sub job_states_json {
  my @data = sort {_loc($a->{name}) cmp _loc($b->{name})} map { {name => $_} }
                 @{config_get('config.job.states')->{states}};
  _encode_json \@data;
}

sub envs_json {
  my @data =  Baseliner::Core::Baseline->baselines;
  _encode_json \@data;
}

sub types_json {
  my $data = [{name => 'SCM', text => 'Distribuidor'},
              {name => 'SQA', text => 'SQA'         },
              {name => 'ALL', text => 'Todos'       }];
  _encode_json $data;
}

sub monitor : Path('/job/monitor') {
    my ( $self, $c, $dashboard ) = @_;
    $c->languages( ['es'] );
    my $config = $c->registry->get( 'config.job' );
    $c->forward('/permissions/load_user_actions');
    if($dashboard){
        $c->stash->{query_id} = $c->stash->{jobs};
    }

    $c->stash->{natures_json}    = $self->natures_json;
    $c->stash->{job_states_json} = $self->job_states_json;
    $c->stash->{envs_json}       = $self->envs_json;
    $c->stash->{types_json}      = $self->types_json; # Tipo de elementos en Monitor. SCM|SQA.

    $c->stash->{template} = '/comp/monitor_grid.js';
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
