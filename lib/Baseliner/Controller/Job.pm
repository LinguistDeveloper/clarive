package Baseliner::Controller::Job;
use v5.10;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use DateTime;
use JSON::XS;
use Try::Tiny;
use List::Util qw(max);
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
      default => [qw/EXPIRED RUNNING FINISHED CANCELLED ERROR KILLED 
          WAITING IN-EDIT READY APPROVAL ROLLBACK REJECTED PAUSED RESUME SUSPENDED ROLLBACKFAIL ROLLEDBACK PENDING SUPERSEDED/]
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
    $c->stash->{action} = 'action.job.create';
    $c->stash->{template} = '/comp/job_new.js';
}

# fill job_new.js combo_baselines
sub bl_combo : Local {
    my ($self,$c)=@_;
    my $p = $c->req->{body_data} // $c->req->params;
  _debug( $p );
    my $bls = $p->{bls};
    my $action = 'action.job.create';  # we use the action to find which bls this role can create jobs on
    my @bl_arr = ();
    my @bl_list = Baseliner::Core::Baseline->baselines_no_root();
    return $c->stash->{baselines} = [ [ '*', 'Common' ] ] unless @bl_list > 0;

    my $is_root = $c->model('Permissions')->is_root( $c->username );
    foreach my $n ( @bl_list ) {
        next unless $is_root or $c->model('Permissions')->user_has_action( username=>$c->username, action=>$action, bl=>$n->{bl} );
        my $arr = { bl=>$n->{bl}, name=>_loc($n->{name}) };
        push @bl_arr, $arr if !defined $bls || $bls->{$n->{bl}};
    }
    $c->stash->{json} = { data=>\@bl_arr, totalCount=>scalar(@bl_arr) };
    $c->forward('View::JSON');
}

sub chains : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $type = $p->{type} // 'promote';
    
    try {
        my $where;
        if ( !Baseliner->model('Permissions')->is_root($c->username) ) {
            $where = { rule_type=>'chain', rule_active => mdb->true, rule_when => $type };
        } else {
            $where = { rule_type=>'chain', rule_active => mdb->true };
        }
        my @rules = sort {
           my $r = $a->{rule_when} eq $type ? -1
           : $b->{rule_when} eq $type ? 1
           : $a cmp $b;
           $r;
        } 
        sort mdb->rule->find({ rule_type=>'chain', rule_active => mdb->true })->fields({ rule_tree=>0 })->all;
        # TODO check action.rule.xxxxx for user
        $c->stash->{json} = { success => \1, data=>\@rules, totalCount=>scalar(@rules) };
    } catch {
        $c->stash->{json} = { success => \0, msg=>"".shift() };
    };
    $c->forward('View::JSON');
}

sub rollback : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $job = ci->new( $p->{mid} ) // _fail _loc 'Job %1 not found', $p->{name};
        _fail _loc 'Job %1 is currently running', $job->name if $job->is_running;
        if( my @deps = $job->find_rollback_deps ) {
            $c->stash->{json} = { success => \0, msg=>_loc('Job has dependencies due to later jobs. Baseline cannot be updated. Rollback cancelled.'), deps=>\@deps };
        } else {
            my $exec = $job->exec + 1;
            $job->exec( $exec );
            $job->step( 'RUN' );
            $job->final_status( '' );  # reset status, so that POST runs in rollback 
            $job->rollback( 1 );
            $job->status( 'READY' );
            $job->maxstarttime(_ts->set(day => _ts->day + 1).''); 
            $job->save;
            $job->logger->info( _loc('Job rollback requested by %1', $c->username) );
            $c->stash->{json} = { success => \1, msg=>_loc('Job %1 rollback scheduled', $job->name ) };
        }
    } catch {
        $c->stash->{json} = { success => \0, msg=>"".shift() };
    };
    $c->forward('View::JSON');
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
    $c->stash->{json}  = try {
        my $job = ci->new( $p->{mid} );
        my $file = $job->logfile;
        #$file //= Baseliner->loghome( $job->name . '.log' ); 
        _fail _loc( "Error: logfile not found or invalid: %1", $file ) if !$file || ! -f $file;
        my $data = _file( $file )->slurp; 
        { data=>$data, success=>\1 };
    } catch {
        my $err = shift;
        { success=>\0, msg=>"$err" };
    };
    $c->forward( 'View::JSON' );
}

sub job_stash : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $job = ci->new( $p->{mid} );
    $c->stash->{json}  = try {
        my $stash = $job->job_stash;
        $stash = _dump( $stash );
        #Encode::_utf8_on( $stash );
        #$c->stash->{job_stash} = $stash;
        { stash=>$stash, success=>\1 };
    } catch {
        { success=>\0 };
    };
    $c->forward( 'View::JSON' );
}

sub job_stash_save : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $c->stash->{json}  = try {
        my $job = ci->new( $p->{mid} );
        my $d = _load( $p->{stash} );
        $job->job_stash( $d );
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
    $p->{username} = $c->username;
    $p->{language} = $c->languages->[0];
    
    my ($cnt, @rows ) = Baseliner->model('Jobs')->monitor($p);

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
    my $p = $c->request->parameters;
    my $username = $c->username;
    my $need_refresh = \0;
    my $magic = 0;
    my $real_top;

    try {
        my $filter = $p->{filter} // {};
        if( $p->{top} > 0 ) {
            $filter->{username} = $c->username;
            $filter->{language} = $c->languages->[0];
            $filter->{list_only} = 1;
            my ($cnt, @rows ) = Baseliner->model('Jobs')->monitor($filter);
            my $max_id = max map { $_->{mid} } @rows;
            _debug "Comparing max_id=$max_id and top_id=$p->{top}";
            if( $max_id != $p->{top} ) {
                $need_refresh = \1;
            }
        }
        if( $p->{ids} ) {
            # are there more info for current jobs?
            my @rows = ci->job->find({ mid=>mdb->in($p->{ids}) })->fields({ _id=>-1, status=>1, exec=>1, step=>1, last_log_message=>1 })->sort({ mid=>-1 })->all;
            my $data ='';
            map { $data.= join(',', sort(%$_) ) } @rows;  # TODO should use step and exec also
            $magic = Util->_md5( $data );
            my $last_magic = $p->{last_magic};
            if( $magic ne $last_magic ) {
                _debug "LAST MAGIC=$last_magic != CURRENT MAGIC $magic";
                $need_refresh = \1;
            }
        }
    } catch { 
        _error( shift );
    };
    $c->stash->{json} = { success=>\1, magic=>$magic, need_refresh => $need_refresh, stop_now=>\0, real_top=>$real_top };	
    $c->forward('View::JSON');
}

register 'event.job.new' => {
    description => 'New job',
    vars => ['username', 'bl', 'jobname', 'id_job']
};
register 'event.job.delete' => {
    description => 'Job deleted',
    vars => ['username', 'bl', 'jobname', 'id_job']
};
register 'event.job.cancel' => {
    description => 'Job cancelled',
    vars => ['username', 'bl', 'jobname', 'id_job']
};
register 'event.job.cancel_running' => {
    description => 'Running job cancelled',
    vars => ['username', 'bl', 'jobname', 'id_job']
};

sub submit : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $config = $c->registry->get('config.job')->data;
    my $runner = $config->{runner};
    my $job_name;
    my $username = $c->username;
    
    #TODO move this whole thing to the Model Jobs
    try {
        use Baseliner::Sugar;
        if( $p->{action} eq 'delete' ) {
            my $job_ci = ci->new( $p->{mid} );
            my $msg = '';
            if( $job_ci->status =~ /CANCELLED|KILLED|FINISHED|ERROR/ ) {
                event_new 'event.job.delete' => { username => $c->username, bl => $job_ci->bl, mid=>$p->{mid}, id_job=>$job_ci->jobid, jobname => $job_ci->name  }  => sub {
                    # be careful: may be cancelled already
                    $p->{mode} ne 'delete' and _fail _loc('Job already cancelled'); 
                    try { $job_ci->delete } catch { ci->delete( $p->{mid} ) };  # delete should work always
                };
                $msg = "Job %1 deleted";
            }
            elsif( $job_ci->status =~ /RUNNING/ ) {
                event_new 'event.job.cancel_running' => { username => $c->username, bl => $job_ci->bl, mid=>$p->{mid}, id_job=>$job_ci->jobid, jobname => $job_ci->name  } => sub {
                    $job_ci->status( 'CANCELLED' );
                    $job_ci->save;
                    $job_ci->logger->error( _loc('Job cancelled by user %1', $c->username ) );
                    sub job_submit_cancel_running : Private {};
                    $c->forward( 'job_submit_cancel_running', $job_ci, $job_name, $username );
                };
                $msg = "Job %1 cancelled";
            } else {
                event_new 'event.job.cancel'  => { username => $c->username, bl => $job_ci->bl, mid=>$p->{mid}, id_job=>$job_ci->jobid, jobname => $job_ci->name  } => sub {
                    $job_ci->status( 'CANCELLED' );
                    $job_ci->save;
                    $job_ci->logger->error( _loc('Job cancelled by user %1', $c->username ) );
                };
                $msg = "Job %1 cancelled";
            }
            $c->stash->{json} = { success => \1, msg => _loc( $msg, $job_name) };
        }
        else { # new job
            my $bl = $p->{bl};
            my $comments = $p->{comments};
            my $job_date = $p->{job_date};
            my $job_time = $p->{job_time};
            my $job_type = $p->{job_type};
            my $bl_to    = $p->{bl_to};
            my $state_to    = $p->{state_to};
            my $id_rule = $p->{id_rule};
            my $job_stash = try { _decode_json( $p->{job_stash} ) } catch { undef };
            
            my $contents = $p->{changesets};
            if( !defined $contents ) {
                # TODO deprecated, use the changesets parameter only
                $contents = _decode_json $p->{job_contents};
                _fail _loc('No job contents') if( !$contents );
                $contents = [ map { $_->{mid} } _array($contents) ];  # now use just mids
            }

            # create job
            my $approval = undef;
            my $job_data = {
                    bl           => $bl,
                    job_type     => $job_type,
                    window_type  => $p->{window_type},  # $p->{check_no_cal} has 'on' if no job window available
                    status       => 'IN-EDIT',
                    approval     => $approval,
                    step         => 'PRE',
                    username     => $username,
                    runner       => $runner,
                    id_rule      => $id_rule,
                    description  => $comments,
                    comments     => $comments,
                    stash_init   => $job_stash, # only used to create the stash
                    changesets   => $contents, 
                    bl_to        => $bl_to,
                    state_to        => $state_to
            };
            
            $job_data->{schedtime} = Class::Date->new("$job_date $job_time")->string if length $job_date && length $job_time;

            event_new 'event.job.new' => { username => $c->username, bl => $job_data->{bl}  } => sub {
                my $job = ci->job->new( $job_data );
                $job->save;  # after save, CHECK and INIT run
                $job_name = $job->name;
                { jobname => $job_name, mid=>$job->mid, id_job=>$job->jobid };
            };
            
            $c->stash->{json} = { success => \1, msg => _loc("Job %1 created", $job_name) };
        }
    } catch {
        my $err = shift;
        #$err =~ s{ at./.*line.*}{}g;
        my $msg = _loc("Error creating job: %1", $err ) ;
        _error( $msg );
        $c->stash->{json} = { success => \0, msg=>$msg };
    };
    $c->forward('View::JSON');	
}

sub natures_json {
    #my @data = sort { uc $a->{name} cmp uc $b->{name} } 
    #         map { { key=>$_->{key}, id=>$_->{id}, name => $_->{name}, ns => $_->{ns}, icon => $_->{icon}} }
    #         map { Baseliner::Core::Registry->get($_) }
    #         Baseliner->registry->starts_with('nature');
             
    my @data = sort { uc $a->{name} cmp uc $b->{name} } 
            map { { id=>$_->{mid}, name => $_->{name}, ns => $_->{ns}, icon => $_->{icon}} }
            BaselinerX::CI::nature->search_cis;             
  
  _encode_json \@data;
}

sub job_states_json {
  my @data = map { {name => $_} }
             sort @{config_get('config.job.states')->{states}};
  _encode_json \@data;
}

sub job_states : Path('/job/states') {
  my ( $self, $c ) = @_;
  my @data = map { {id=>$_, name => _loc($_)} }
             sort @{config_get('config.job.states')->{states}};
  _encode_json \@data;
  $c->stash->{json} = { data => \@data };
  $c->forward('View::JSON'); 
}

sub envs_json {
  #my @data =  grep { ! $_->{bl} eq '*' } Baseliner::Core::Baseline->baselines;
    my @data = sort { ($a->{seq}//0) <=> ($b->{seq}//0) } map { {name => $_->{name}, bl => $_->{bl}}}  grep {$_->{moniker} ne '*'}  BaselinerX::CI::bl->search_cis;
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

sub jc_store : Local  {
    my ( $self, $c ) = @_;
    my $p = $c->req->{body_data} // $c->req->params;
    my $topics = $$p{topics} || {} ;
    my @data;
    my $k = 1;
    
    my %deploys;
    my %children;
 
    my %deploy_changesets;
    my $add_deploy = sub{
        my ($cs,$id_project)=@_;
        my ($static,$promote,$demote) = BaselinerX::LcController->promotes_and_demotes( 
            username   => $c->username, 
            topic      => $cs, 
            id_project => $id_project,
        );
        # this assumes $static->{$_} is always true (\1)
        $deploys{static}{$_}++ for keys %{ $static || {} };
        $deploys{promote}{$_}++ for keys %{ $promote || {} };
        $deploys{demote}{$_}++ for keys %{ $demote || {} };
        $deploy_changesets{ $$cs{mid} }=1; # keep unique count
    };
    
    for my $node ( values %$topics ) {
        my $node_data = $$node{data};
        my $mid = $$node_data{topic_mid} ;
        my $ci = ci->new( $mid );
        my $status_from = $ci->is_release ? $$node_data{state_id} : $ci->id_category_status;
        my $id_project = $$node_data{id_project};
        my $id = $k++;
        
        my @chi;
        if( $ci->is_release ) {
            my @changesets = grep { $_->is_changeset } $ci->children( isa=>'topic', no_rels=>1 );
            my @cs_mids = map { $_->mid } @changesets;
            my ($cnt, @cs_user) = model->Topic->topics_for_user({ username=>$c->username, clear_filter=>1, id_project=>$id_project, statuses=>[$status_from], topic_list=>\@cs_mids });
            @chi = map {
               my $cs_data = $_;
               $children{ $$cs_data{mid} } = 1;
               $add_deploy->( $cs_data, $id_project );
               +{
                    _id => $$cs_data{mid},
                    _parent => ''.$mid,
                    _is_leaf => \1,
                    item     => {
                        mid            => $$cs_data{mid},
                        title          => $$cs_data{title},
                        category_name  => $$cs_data{category}{name},
                        category_color => $$cs_data{category}{color},
                        is_release     => $$cs_data{category}{is_release},
                        is_changeset   => $$cs_data{category}{is_changeset},
                    },
                    text=>$$cs_data{title},
                    date=>$$cs_data{modified_on},
                    modified_by=>$$cs_data{modified_by},
                    created_by=>$$cs_data{created_by},
                    ns=> "changeset/" . $$cs_data{mid},
                    mid=>$$cs_data{mid},
                    id_project => $id_project,
                }
            } 
            grep {
                $$_{category}{is_changeset}
            } @cs_user;
        }
        my $topic_data = $ci->get_data;
        
        my $row = {
            _id      => ''.$mid,
            _is_leaf => @chi?\0:\1,
            _parent  => undef,
            item     => {
                mid            => $mid,
                title          => $$topic_data{title},
                category_name  => $$topic_data{category}{name},
                category_color => $$topic_data{category}{color},
                is_release     => $ci->is_release,
                is_changeset   => $ci->is_changeset
            },
            date=>$$topic_data{modified_on},
            modified_by=>$$topic_data{modified_by},
            created_by=>$$topic_data{created_by},
            text => $$node{text},
            ns   => $$node_data{ns},
            mid  => $$node_data{topic_mid},
            id_project => $id_project,
        };
        push @data, $row;
        push @data, @chi if @chi;
        
        # now get all changesets and find where they can deploy
        $add_deploy->( $topic_data, $id_project ) if $ci->is_changeset;
    }
    
    # filter out first level changesets if inside release
    @data = grep { !( $$_{_parent} xor $children{$$_{mid}} ) } @data;
    
    # now reduce to common deployables
    my $total_cs = keys %deploy_changesets;
    for my $jt ( keys %deploys ) {
        for my $bl ( keys %{ $deploys{$jt} } ) {
            delete $deploys{$jt}{$bl} if  $deploys{$jt}{$bl} < $total_cs;
        }
    }
    
    for my $t ( @data ) {
        my $type = $$t{item}{is_release} ? 'release' : $$t{item}{is_changeset} ? 'changeset' : '';
        next if $type ne 'changeset';
    }
    
    if( @data ){  # make sure we initialize to get the blocked ones if we have data but no deploys
        $deploys{$_} //= {} for qw(promote demote static) 
    }
    
    #@data = sort{ $$a{_id} <=> $$b{_id} } @data;
    $c->stash->{json} = { data=>\@data, totalCount=>scalar(@data), success=>\1, deploys=>\%deploys }; 
    $c->forward('View::JSON');  
}

1;
