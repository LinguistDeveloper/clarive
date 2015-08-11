package Baseliner::Controller::Dashboard;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(:default _load_yaml_from_comment);
use Baseliner::Sugar;
use Try::Tiny;
use Scalar::Util qw(looks_like_number);
use v5.10;
use experimental 'switch', 'autoderef';

BEGIN {  extends 'Catalyst::Controller' }

# register 'dashlet.job.burndown' => {
#     form=> '/dashlets/job_burndown_config.js',
#     name=> 'Job Burndown', 
#     icon=> '/static/images/icons/job.png',
#     js_file => '/dashlets/job_burndown.js',
#     data => {
#         days_avg  => '1000D',
#         days_last => '100D',
#     }
# };

register 'dashlet.job.last_jobs' => {
    form=> '/dashlets/last_jobs_config.js',
    name=> 'Last jobs by app', 
    icon=> '/static/images/icons/report_default.png',
    js_file => '/dashlets/last_jobs.js'
};

register 'dashlet.job.list_jobs' => {
    form=> '/dashlets/list_jobs_config.js',
    name=> 'List jobs', 
    icon=> '/static/images/icons/report_default.png',
    js_file => '/dashlets/list_jobs.js'
};

register 'dashlet.job.list_baseline' => {
    form=> '/dashlets/baselines_config.js',
    name=> 'List baselines', 
    icon=> '/static/images/icons/report_default.png',
    js_file => '/dashlets/baselines.js'
};

register 'dashlet.job.chart' => {
    form=> '/dashlets/job_chart_config.js',
    name=> 'Job chart', 
    icon=> '/static/images/silk/chart_pie.png',
    js_file => '/dashlets/job_chart.js'
};

register 'dashlet.job.day_distribution' => {
    form=> '/dashlets/job_distribution_day_config.js',
    name=> 'Job daily distribution', 
    icon=> '/static/images/silk/chart_line.png',
    js_file => '/dashlets/job_distribution_day.js'
};

register 'dashlet.topic.number_of_topics' => {
    form=> '/dashlets/number_of_topics_chart_config.js',
    name=> 'Topics chart', 
    icon=> '/static/images/silk/chart_pie.png',
    js_file => '/dashlets/number_of_topics_chart.js'
};

register 'dashlet.topic.list_topics' => {
    form=> '/dashlets/list_topics_config.js',
    name=> 'List topics', 
    icon=> '/static/images/icons/report_default.png',
    js_file => '/dashlets/list_topics.js'
};

register 'dashlet.topic.topics_by_date_line' => {
    form=> '/dashlets/topics_by_date_line_config.js',
    name=> 'Topics time line', 
    icon=> '/static/images/silk/chart_curve.png',
    js_file => '/dashlets/topics_by_date_line.js'
};

register 'dashlet.topic.topics_burndown' => {
    form=> '/dashlets/topics_burndown_config.js',
    name=> 'Topics burndown', 
    icon=> '/static/images/silk/chart_line.png',
    js_file => '/dashlets/topics_burndown.js'
};

register 'dashlet.topic.gauge' => {
    form=> '/dashlets/topics_gauge_config.js',
    name=> 'Topics gauge', 
    icon=> '/static/images/icons/gauge.png',
    js_file => '/dashlets/topics_gauge_d3.js'
};

register 'dashlet.topic.topic_roadmap' => {
    form=> '/dashlets/topic_roadmap_config.js',
    name=> 'Topic Roadmap', 
    icon=> '/static/images/icons/calendar.gif',
    js_file => '/dashlets/topic_roadmap.js'
};

register 'dashlet.iframe' => {
    form=> '/dashlets/iframe_config.js',
    name=> 'Internet frame', 
    icon=> '/static/images/silk/world.png',
    js_file => '/dashlets/iframe.js'
};

register 'dashlet.email' => {
    form=> '/dashlets/emails_config.js',
    name=> 'Email messages', 
    icon=> '/static/images/icons/envelope.png',
    js_file => '/dashlets/emails.js'
};

sub init : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;

    # run the dashboard rule
    # TODO find default
    my $id_rule = $p->{dashboard_id};
    my $project_id = $p->{project_id};

    # find a default dashboard
    my @all_rules = $self->user_dashboards({ username => $c->username });
    if( !$id_rule ) {
        $id_rule = @all_rules?$all_rules[0]->{id}:'';
        if( !$id_rule ) {
            _warn _loc 'No default rule found for user %1', $c->username;
        }
    }

    # Remove old data
    if ( !mdb->rule->count({rule_type=>'dashboard'}) ) {
        mdb->role->update({},{ '$rename'=>{ dashboards => 'dashboards_old'}},{multiple=>1} );
        for my $user ( ci->user->search_cis() ) {
            $user->dashboard('');
            $user->save;
        }
        my $default_dashboards = Util->_load(join '',<DATA>);# || _fail _loc 'Could not find default dashboard data!';
        for my $dashboard ( _array($default_dashboards) ) {
            my $id = mdb->seq('rule');
            mdb->rule->insert({ %$dashboard, ts=>mdb->ts, rule_seq=>0+$id, id=>"$id" });
            if ( $dashboard->{default_dashboard} ) {
                $id_rule = $id;
            }
        }
        @all_rules = $self->user_dashboards({ username => $c->username });
    }

    $id_rule or _fail _loc 'No dashboard defined';

    # now run the dashboard rule
    my $cr = Baseliner::CompiledRule->new( id_rule=>"$id_rule" );
    my $stash = {
        project_id => $project_id,
        dashboard_data => { data=>[], count=>0 },
        dashboard_params => {
            %$p,
        }
    };
    $cr->compile;
    $cr->run( stash=>$stash ); 
    my $dashlets = $$stash{dashlets} // [];

    my $k = 1;
    my $user_config = ci->user->search_ci( name => $c->username )->dashlet_config;

    $dashlets = [ map{ 
        $$_{order} = $k++;
        # merge default data with node
        if( $$_{key} && (my $reg = $c->registry->get($$_{key})) ){
            $$_{data_orig} = +{ %{ $reg->{data} || {} }, %{ $$_{data} || {} } } ;
            if ( keys %$user_config && keys %{$user_config->{$$_{id}}} ) {
                $$_{data} = +{ %{ $reg->{data} || {} }, %{ $user_config->{$$_{id}} || {} } } ;
            } else {
                $$_{data} = +{ %{ $reg->{data} || {} }, %{ $$_{data} || {} } } ;
            }
            $$_{js_file} = $reg->{js_file}; # overwrite important stuff
            $$_{form} = $reg->{form}; # overwrite important stuff
        }
        $_;
    } _array($dashlets) ];

    ## TODO merge user configurations to dashlets
    # _debug( $dashlets );

    # now list the dashboards for user
    #my @rules = mdb->rule->find({ rule_type=>'dashboard' })->all;
    #my $dashboards = [ map{ {id=>$_->{id}, name=>$_->{rule_name} }  } @rules ];

    $c->stash->{json} = { dashlets=>$dashlets, dashboards=>\@all_rules };
    $c->forward( 'View::JSON' );
}

sub json : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my @dashboard_list = ();

    if ( $p->{username} ) {
        my $where = {};
        my @dashboard_ids;
        if ( !$c->model('Permissions')->is_root( $c->username ) ) {
            my @roles = map { $_->{id} } $c->model('Permissions')->user_roles( $c->username );
            $where = { id => mdb->in(@roles) };
            @dashboard_ids = map { _array( $_->{dashboards} ) } mdb->role->find( $where )->all;
        } else {
            @dashboard_ids = map { '' . $_->{id} } mdb->rule->find({ rule_type => 'dashboard' })->fields( { id => 1 } )->all;
        }
        @dashboard_list = map {
            my $name = $_->{rule_name};
            $name = $name.' '._loc('(Default)') if $_->{default_dashboard};
            +{
                name => $name,
                id   => '' . $_->{id}
            }
        } mdb->rule->find( { id => mdb->in(@dashboard_ids) } )->sort({ rule_name => 1})->all;
    }
    else {
        @dashboard_list = map { 
            my $name = $_->{rule_name};
            $name = $name.' '._loc('(Default)') if $_->{default_dashboard};
            +{ name => $name, id => '' . $_->{id} } 
        }
        mdb->rule->find({ rule_type => 'dashboard' })->sort({ rule_name => 1})->all;
    }

    $c->stash->{json}
        = { totalCount => scalar(@dashboard_list), data => \@dashboard_list };
    $c->forward('View::JSON');
}

sub dashboard_list: Local {
    my ($self,$c) = @_;

    my $p = $c->req->params;
    my @trees;
    my @dashboards = $self->user_dashboards({ username => $c->username});

    for my $dash ( @dashboards ) {
        my $dash_name = $dash->{name};
        $dash_name .= ' - '.$p->{project} if $p->{project};
        push @trees, {
                text    => $dash->{name},
                icon    => '/static/images/icons/dashboard.png',
                data    => {
                    title => $dash->{name},
                    id => $dash->{id},
                    project_id => $p->{id_project},
                    click   => {
                        icon    => '/static/images/icons/dashboard.png',
                        url  => '/comp/dashboard.js',
                        type    => 'comp',
                        title   => $dash_name,
                    }
                },
                leaf    => \1
            };
    }

    my %names = map { $_->{text} => $_ } @trees;
    @trees = sort { $a->{text} cmp $b->{text} } values %names;

    $c->stash->{json} = \@trees;
    $c->forward('View::JSON');
}

sub user_dashboards {
    my ($self,$p) = @_;

    my $username = $p->{username};
    my $user_ci = ci->user->search_ci(name=>$username);

    my $where = {};
    my @dashboard_ids = ($user_ci->default_dashboard->{dashboard}) || ();

    if ( !Baseliner->model('Permissions')->is_root( $username ) ) {
        my @roles = map { $_->{id} } Baseliner->model('Permissions')->user_roles( $username );
        $where = { id => mdb->in(@roles) };
        push @dashboard_ids, map { _array( $_->{dashboards} ) } mdb->role->find( $where )->all;

    } else {
        push @dashboard_ids, map { '' . $_->{id} } mdb->rule->find({ rule_type => 'dashboard' })->fields( { id => 1 } )->all;
    }

    # no personal id? no id for role? then show default
    if ( !@dashboard_ids ) {
        push @dashboard_ids, map { '' . $_->{id} } mdb->rule->find({ rule_type => 'dashboard', default_dashboard => '1' })->fields( { id => 1 } )->all;
    }

    # the trick here is to get the data but keep the order, 
    #  because [0] is the user prerred dashboard
    my %dashash =
        map {
            $_->{id} => +{
                name => $_->{rule_name},
                id   => '' . $_->{id}
            }
        } mdb->rule->find( { id => mdb->in(@dashboard_ids) } )->sort({ rule_name => 1})->all;

    my @dashboard_list = map { $dashash{$_} } @dashboard_ids;
    return @dashboard_list;
}

sub list_jobs: Local { 
    my ( $self, $c ) = @_;
    my $perm = Baseliner->model('Permissions');
    my $p = $c->req->params;

    my $project_id = $p->{project_id};

    my $states = $p->{states} || [];
    my $not_in_states = $p->{not_in_states} || 'off';
    my $limit = $p->{limit} || 100;

    my @mid_filters = ();
    my $username = $c->username;
    my @lastjobs;
    my $bls = $p->{bls} || [];

    try {

        my $where = {};

        if ( _array($bls) ) {
            my @all_bls = map {$_->{name}} ci->bl->find({mid=>mdb->in(_array($bls))})->all;
            $where->{bl} = mdb->in(@all_bls);
        }

        if( !$perm->is_root($username) ) {
                @mid_filters = $perm->user_projects_with_action(username => $username,
                                                                    action => 'action.job.viewall',
                                                                    level => 1)            
        }

        $where->{'projects'} = mdb->in(@mid_filters) if @mid_filters;

        if ( $project_id ) {
            $where->{'projects'} = $project_id;
        }

        my @filter_states;
        if ( _array($states) ) {
            if ( $not_in_states eq 'on' ) {
                $where->{status} = mdb->nin(_array($states));
            } else {
                $where->{status} = mdb->in(_array($states));
            }
        }
        my $rs_search = ci->job->find( $where )->sort({ starttime => -1 })->limit($limit);

        while ( my $job = $rs_search->next() ) {
            try {
                push @lastjobs, {
                    mid       => $job->{mid},
                    name      => $job->{name},
                    type      => $job->{job_type},
                    rollback  => $job->{rollback},
                    status    => $job->{status},
                    starttime => $job->{starttime},
                    endtime   => $job->{endtime},
                    bl => $job->{bl},
                    apps => join ",", _array($job->{job_contents}->{list_apps})
                };
            } catch {
                _log "FAILURE Searching job ".$job->{mid}.": " . shift;
            };
        }
    } catch {
        _error _loc("Error listing jobs: %1 ", shift);
    };
    $c->stash->{json} = { data=>\@lastjobs };
    $c->forward( 'View::JSON' );

}

sub last_jobs : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $project_id = $p->{project_id};

    my $bls = $p->{bls};
    my @datas;
    
    try {

        my $where = {};

        if ( _array($bls) ) {
            my @all_bls = map {$_->{name}} ci->bl->find({mid=>mdb->in(_array($bls))})->all;
            $where->{bl} = mdb->in(@all_bls);
        }
        my $username = $c->username;

        my @ids_project;
        if ($project_id) {
            @ids_project = $project_id;
        } else {
            @ids_project = $c->model('Permissions')
                ->user_projects_ids( username => $c->username );
        }
        
        if ( @ids_project ) {

            my %jobs = map { $_->{mid} => $_ } ci->job->find($where)
                 ->fields({ mid=>1, name=>1, starttime=>1, endtime=>1, projects=>1, bl=>1, status=>1, jobid=>1 })->all; #{ endtime=>{ '$gt'=>'2013-11-31 00:00' } })->all;
            my %projects = map { $_->{mid} => $_ } ci->project->find({ mid=>mdb->in(@ids_project) })->all;
            my %rep;
            my $now = _ts();
            # for all jobs
            for my $job ( values %jobs ) {
                my $bl = $job->{bl};
                my $endt = Class::Date->new($job->{endtime});
                my $days = int( ($now - $endt)->day );
                my $status = $job->{status};
                my $type = $status =~ /ERROR|KILLED/ ? 'err' 
                    : $status=~/CANCELLED|APPROVAL|PAUSED|REJECTED/ ? next : 'ok';
                # for project in job
                for my $prj ( _array( $job->{projects} ) ) {
                    my $name = $projects{$prj}->{name};
                    next unless $name;
                    my $r = $rep{ $name }{$bl} //= {};
                    # last error by type
                    if( !defined $r->{"last_$type"} || $days < $r->{"last_$type"} ) {
                        $r->{"last_$type"} = $days;
                        $r->{"id_$type"} = $job->{jobid};
                        $r->{"mid_$type"} = $job->{mid};
                        $r->{"name_$type"} = $job->{name};
                        $r->{status} = $status;
                    }
                    # last durantion and top mid
                    if( !defined $r->{top_mid} || $job->{mid} > $r->{top_mid} ) {  
                        my $secs = ($endt-Class::Date->new($job->{starttime}))->second;
                        $r->{last_duration} = sprintf '%dm %ds', int($secs/60), ($secs % 60);
                        $r->{top_mid} = $job->{mid};
                    }
                }
            }
            
            # now create something we can send to the template
            @datas = sort {
                $b->{top_mid} <=> $a->{top_mid}
            } map {
                my $prj = $_;
                my $bls = $rep{$prj};
                my @rows;
                for my $bl ( keys $bls ) {
                    my $r = $bls->{$bl};
                    push @rows, { project=>$prj, bl=>$bl, %$r };
                }
                @rows;
            } keys %rep;
            
        } ## end if ( @ids_project )

    } catch {
        _error _loc("Error listing last jobs: %1 ", shift);
    };
    $c->stash->{json} = { data=>\@datas };
    $c->forward( 'View::JSON' );

} 

sub topics_by_category: Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my (@topics_by_category, $colors, @data );
    my $group_threshold = $p->{group_threshold};
    my $categories = $p->{categories};
    my $statuses = $p->{statuses};
    my $not_in_status = $p->{not_in_status};
    my $condition = {};

    if ( $p->{condition} ) {
        try {
            my $cond = eval('q/'.$p->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {

        }
    }

    my $where = $condition;
    if ( $statuses ) {
        if ( $not_in_status ) {
            $where->{'category_status.id'} = mdb->nin($statuses);
        } else {
            $where->{'category_status.id'} = mdb->in($statuses);
        }
    }
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( $categories ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    $where->{'category.id'} = mdb->in(@user_categories);

    @topics_by_category = _array(mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { 
            _id => '$category.id', 
            'category' => {'$max' => '$category.name'},
            'color' => {'$max' => '$category.color'}, 
            'total' => { '$sum' => 1 },
            'topics_list' => { '$push' => '$mid'}
          } 
        },
        { '$sort' => { total => -1}}
    ]));
    
    my $total = 0;
    my $topics_list;
    map { $total += $_->{total} } @topics_by_category;
    my $others = 0;
    my @other_topics = ();
    foreach my $topic (@topics_by_category){
        if ( $topic->{total}*100/$total <= $group_threshold ) {
            $others += $topic->{total};
            push @other_topics, _array($topic->{topics_list});
        } else {
            push @data, [
                $topic->{category},$topic->{total}
            ];
            $topics_list->{$topic->{category}} = $topic->{topics_list};
        }

        $colors->{$topic->{category}} = $topic->{color};
    }
    if ( $others ) {
        push @data, [
            _loc('Other'),$others
        ];                    
        $topics_list->{_loc('Other')} = \@other_topics;
        $colors->{_loc('Other')} = "#DDDDDD";
    }
    $c->stash->{json} = { success => \1, colors=>$colors,data=>\@data,topics_list=>$topics_list };
    $c->forward('View::JSON'); 
}

sub topics_by_field: Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my (@topics_by_category, $colors, @data );
    my $group_threshold = $p->{group_threshold};
    my $group_by = $p->{group_by};
    my $categories = $p->{categories};
    my $statuses = $p->{statuses};
    my $not_in_status = $p->{not_in_status};
    my $condition = {};

    if ( $group_by eq 'topics_by_category') {
        $group_by = 'category.name';
    } elsif ( $group_by eq 'topics_by_status') {
        $group_by = 'category_status.name';
    }
    if ( $p->{condition} ) {
        try {
            my $cond = eval('q/'.$p->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {

        }
    }

    my $where = $condition;
    if ( $statuses ) {
        if ( $not_in_status ) {
            $where->{'category_status.id'} = mdb->nin($statuses);
        } else {
            $where->{'category_status.id'} = mdb->in($statuses);
        }
    }
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( $categories ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    $where->{'category.id'} = mdb->in(@user_categories);

    if($p->{project_id}){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    @topics_by_category = _array(mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { 
            _id => '$'.$group_by, 
            'field' => {'$max' => '$'.$group_by},
            'category_color' => {'$max' => '$category.color'}, 
            'status_color' => {'$max' => '$category_status.color'}, 
            'total' => { '$sum' => 1 },
            'topics_list' => { '$push' => '$mid'}
          } 
        },
        { '$sort' => { total => -1}}
    ]));
    
    my $total = 0;
    my $topics_list;
    map { $total += $_->{total} } @topics_by_category;
    my $others = 0;
    my @other_topics = ();
    my $ci_colors = cache->get('ci::colors');

    foreach my $topic (@topics_by_category){

        my $name = $topic->{field};
        $name = _loc('Empty') if (!_array($topic->{field}));

        if ( $topic->{total}*100/$total <= $group_threshold ) {
            $others += $topic->{total};
            push @other_topics, _array($topic->{topics_list});
        } else {
            if ( Util->is_number($topic->{field}) && $topic->{field} > 1 ) {
                try {
                    $name = mdb->master->find_one({mid=>"$topic->{field}"})->{name};#ci->new($topic->{field})->name;
                } catch {

                };
            } elsif ( ref $topic->{field} ) {
                my ($val) = _array($topic->{field});
                try {
                    $name = mdb->master->find_one({mid=>"$val"})->{name};#ci->new($val)->name;
                } catch {

                };                
            };
            push @data, [
                $name,$topic->{total}
            ];
            $topics_list->{$name} = $topic->{topics_list};
        }
        my $color;
        if ( $group_by eq 'category.name' ) {
            $color = $topic->{category_color};
        } elsif ( $group_by eq 'category_status.name' ) {
            $color = $topic->{status_color};
        } else {
            if ( $ci_colors->{$name} ) {
                # $color = $ci_colors->{$name};
            } else {
                # $color = sprintf "#%06X", rand(0xffffff);
                # $ci_colors->{$name} = $color;
                # cache->set('ci::colors',$ci_colors);
            }
        }
        $colors->{$name} = $color;
    }
    if ( $others ) {
        push @data, [
            _loc('Other'),$others
        ];                    
        $topics_list->{_loc('Other')} = \@other_topics;
        $colors->{_loc('Other')} = "#DDDDDD";
    }
    $c->stash->{json} = { success => \1, colors=>$colors,data=>\@data,topics_list=>$topics_list };
    $c->forward('View::JSON'); 
}

sub topics_by_status: Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my (@topics_by_status, $colors, @data, %status );
    my $group_threshold = $p->{group_threshold};
    my $categories = $p->{categories};
    my $statuses = $p->{statuses};
    my $not_in_status = $p->{not_in_status};
    my $condition = {};

    if ( $p->{condition} ) {
        try {
            my $cond = eval('q/'.$p->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {

        }
    }

    my $where = $condition;
    if ( $statuses ) {
        if ( $not_in_status ) {
            $where->{'category_status.id'} = mdb->nin($statuses);
        } else {
            $where->{'category_status.id'} = mdb->in($statuses);
        }
    }
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( $categories ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    $where->{'category.id'} = mdb->in(@user_categories);
    my %status_colors = map { $_->{id_status} => $_->{color} } ci->status->find()->all;

    @topics_by_status = _array(mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { 
            _id => '$category_status.id', 
            'status' => {'$max' => '$category_status.name'},
            'color' => {'$max' => '$category_status.color'}, 
            'total' => { '$sum' => 1 },
            'topics_list' => { '$push' => '$mid'}
          } 
        },
        { '$sort' => { total => -1}}
    ]));
    
    my $total = 0;
    my $topics_list;
    map { $total += $_->{total} } @topics_by_status;
    my $others = 0;
    my @other_topics = ();
    foreach my $topic (@topics_by_status){
        if ( $topic->{total}*100/$total <= $group_threshold ) {
            $others += $topic->{total};
            push @other_topics, _array($topic->{topics_list});
        } else {
            push @data, [
                $topic->{status},$topic->{total}
            ];
            $topics_list->{$topic->{status}} = $topic->{topics_list};
        }
        $status{$topic->{_id}} = $topic->{status};
        $colors->{$topic->{status}} = $status_colors{$topic->{_id}};
    }
    if ( $others ) {
        push @data, [
            _loc('Other'),$others
        ];                    
        $topics_list->{_loc('Other')} = \@other_topics;
        $colors->{_loc('Other')} = "#DDDDDD";
    }
    $c->stash->{json} = { success => \1, colors=>$colors,data=>\@data,topics_list=>$topics_list };
    $c->forward('View::JSON'); 
}


sub topics_by_date: Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;

    my $group = $p->{group} // '';
    my $date_field = $p->{date_field};
    my $categories = $p->{categories};
    my $statuses = $p->{statuses};
    my $not_in_status = $p->{not_in_status};
    my $days_from = $p->{days_from};
    my $days_until = $p->{days_until};
    my $condition = {};

    if ( $p->{condition} ) {
        try {
            my $cond = eval('q/'.$p->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {
            _error "JSON condition malformed (".$p->{condition}."): ".shift;
        }
    }

    my $where = $condition;
    if ( _array($statuses) ) {
        if ( $not_in_status ) {
            $where->{'category_status.id'} = mdb->nin($statuses);
        } else {
            $where->{'category_status.id'} = mdb->in($statuses);
        }
    }
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( _array($categories) ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }
    $where->{'category.id'} = mdb->in(@user_categories);

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    my $date_end = Class::Date->now();
    my $date_start = $date_end - '1D';

    my $now = Class::Date->now();
    if ( $days_from != 0 && $days_until != 0 ) {
        my $inc_from = $days_from."D";
        my $from = $now + $inc_from;
        my $inc_until = $days_until."D";
        my $until = $now + $inc_until;
        $date_start = $from;
        $date_end = $until;
        $where->{'$and'} = [ {$date_field => {'$gte' => "$from"}}, {$date_field => {'$lte' => "$until"}}];
    } elsif ( $days_from != 0 ) {
        my $inc_from = $days_from."D";
        my $from = $now + $inc_from;
        $date_start = $from;
        $where->{$date_field} = {'$gte' => "$from"};        
    } elsif ( $days_until != 0 ) {
        my $inc_until = $days_until."D";
        my $until = $now + $inc_until;
        $date_end = $until;
        $where->{$date_field} = {'$lte' => "$until"};        
    }

    if($p->{project_id}){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    my $rs_topics = mdb->topic->find($where)->fields({_id=>0,_txt=>0});

    my %topic_by_dates = ();
    my %list_topics = ();
    my %colors;
    my $quarters = { 'Q1' => '01-01', 'Q2' => '04-01', 'Q3' => '07-01', 'Q4' => '10-01'};


    #### Let's fill all dates
    my @dates = ('x');
    my $interval = '1D'; #### TODO: Can be variable depending on the group
    my %all_dates = ();

    for (my $date = $date_start->clone; $date <= $date_end; $date = $date + $interval) {
        my $dt = DateTime->from_epoch( epoch => $date->epoch() );
        $dt->set_time_zone( _tz );
        my $fdate;
        if ( $group !~ /day|quarter/ ) {    
            $dt->truncate( to => $group);
            $fdate = substr(''.$dt,0,10);
        } elsif ( $group eq 'quarter' ){
            $fdate = $dt->year . "-". $quarters->{$dt->quarter_abbr};
        } else {
            $fdate = substr(''.$dt,0,10);
        }

        if ( !$all_dates{$fdate} ) {
            push @dates, $fdate;
            $all_dates{$fdate} = 1;
        }
    }
    my %all_categories = ();

    while (my $topic = $rs_topics->next() ) {
        my $date = $topic->{$date_field};

        use DateTime;
        use Class::Date;
        my $date_fmt = Class::Date->new($date);

        if ( !$all_categories{$topic->{category_name}} ) {
            for my $init_date ( keys %all_dates ) {
                $topic_by_dates{$init_date}{ $topic->{category_name} } = 0;
            }
            $all_categories{$topic->{category_name}} = 1;
        }
        if ($date_fmt) {
            my $dt = DateTime->from_epoch( epoch => $date_fmt->epoch() );
            $dt->set_time_zone( _tz );
            if ( $group !~ /day|quarter/ ) {
                $dt->truncate( to => $group);
                $date = substr(''.$dt,0,10);
            } elsif ( $group eq 'quarter' ){
                $date = $dt->year . "-". $quarters->{$dt->quarter_abbr};
            } else {
                $date = substr(''.$dt,0,10);
            }

            $topic_by_dates{$date}{ $topic->{category_name} }
                = $topic_by_dates{$date}{ $topic->{category_name} }
                ? $topic_by_dates{$date}{ $topic->{category_name} } + 1
                : 1;

            my @topics = _array($list_topics{$date}{ $topic->{category_name} });
            push @topics, $topic->{mid};
            $list_topics{$date}{ $topic->{category_name} } = \@topics;

        }

        $colors{$topic->{category}->{name}}= $topic->{category}->{color};
    }

    my %keys = ();
    # my @dates = ('x');
    for my $rel_date ( keys %topic_by_dates ) {
        # push @dates, $rel_date;
        for my $rel_type ( keys %{ $topic_by_dates{$rel_date} } ) {
            $keys{$rel_type} = 1;
        }
    }

    my %temp_data;
    my %final_list_topics;
    my $index = 0;

    for my $rel_date ( sort { $a cmp $b } keys %topic_by_dates ) {
        $final_list_topics{$index++} = $list_topics{$rel_date};

        my @data = ();
       for my $rel_type (keys %keys) {
           if ( !$temp_data{$rel_type} ) {
                $temp_data{$rel_type} = [];
           }
          if ( $topic_by_dates{$rel_date}->{$rel_type} ) {
            push $temp_data{$rel_type}, $topic_by_dates{$rel_date}->{$rel_type};
          } else {
            push $temp_data{$rel_type},0;
          }
       }
    }
    my $matrix = [];


    push $matrix, \@dates;

    
    for ( keys %temp_data ) {
        push $matrix, [ $_, _array($temp_data{$_})];
    }



    $c->stash->{json} = { data=>{ groups => [keys %keys], colors => \%colors, topics_list => \%final_list_topics, matrix => $matrix} };
    $c->forward('View::JSON');
}

sub roadmap : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;

    # we need to determine the first day of the week, going back X weeks
    #   so the start date is always EARLIER than today's date minus X weeks
    my $now = Class::Date->now;
    my $first_weekday = $p->{first_weekday} // 0;  # 0 is Sunday, 6 is Saturday
    my $weeks_from = $p->{weeks_from} // 10;
    my $weeks_until = $p->{weeks_until} // 10;
    my $first_day_of_my_week = $now->_wday - $first_weekday;
    my $first_day = $now - ( ($weeks_from*7).'D' ) - ( ( ${first_day_of_my_week} >= 0 ? ${first_day_of_my_week} : 7 + ${first_day_of_my_week} ). 'D');
    $first_day = substr( $first_day, 0, 10) . ' 00:00';
    my $categories = $p->{categories};
    my $condition = length $p->{condition} ? Util->_decode_json("{" . $p->{condition} . "}") : {};
    my $id_project = $p->{project_id};
    my $topic_mid = $p->{topic_mid};

    # my $id_project = $p->{id_project};
    my @rows;
    my %bls = map{ $$_{name}=>[] } ci->bl->find->all;
    my %cats = map{ $$_{id}=>$_ } mdb->category->find({ id=>mdb->in($categories) })->fields({ id=>1, acronym=>1 })->all;
    my $where = { 'category.id'=>mdb->in(keys %cats), %$condition };
    if( length $topic_mid){
        $where->{mid} = $topic_mid;
    } elsif( $id_project ){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }
    my @topics = mdb->topic->find($where)->fields({ category=>1, mid=>1, title=>1 })->all;
    my %master_cal;
    map{ push @{ $master_cal{$$_{mid}} } => $_ } mdb->master_cal->find({ mid=>mdb->in(map{$$_{mid}}@topics) })->all;

    # distribute topics to their corresponding bl
    for my $topic ( @topics ) {
        my $cal = $master_cal{ $topic->{mid} } || next;
        for my $cc ( _array $cal ) { 
            next unless exists $bls{ $cc->{slotname} };
            push @{ $bls{ $cc->{slotname} } }, { topic=>$topic, cal=>$cc, acronym=>$cats{$topic->{category}{id}}{acronym} }; 
        }
    }

    # week by week, find which topics go where
    for my $st ( map{ Class::Date->new( $first_day ) + (($_*7).'D') } 0..( $weeks_from + $weeks_until ) ) {
        my $row = { date=>"$st" };
        for my $bl ( keys %bls ) {
            my $ed = $st + '7D';
            my @bl_topics = grep { 
                ($$_{cal}{plan_start_date} ge $st && $$_{cal}{plan_start_date} lt $ed ) 
                || ( $$_{cal}{plan_end_date} ge $st && $$_{cal}{plan_end_date} lt $ed ) 
                || ( $$_{cal}{plan_start_date} le $st && $$_{cal}{plan_end_date} ge $ed ) 
            } _array( $bls{ $bl } );
            for my $blt ( @bl_topics ) {
                push @{ $row->{$bl} }, $blt; 
            }
        }

        push @rows, $row;
    }

    $c->stash->{json} = { data=>\@rows};
    $c->forward('View::JSON');    
}

sub topics_gauge: Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $data = gauge_data($c, $p);

    my $data_max;
    if ( $p->{max_selection} && $p->{max_selection} eq 'on' ) {
        my $p_max = $p;

        $p->{categories} = $p->{categories_max};
        $p->{statuses} = $p->{statuses_max};
        $p->{not_in_status} = $p->{not_in_status_max};
        $p->{days_from} = $p->{days_from_max};
        $p->{days_until} = $p->{days_until_max};
        $p->{condition} = $p->{condition_max};

        $data_max = gauge_data($c,$p_max);
        $data->{max} = $data_max->{max};
    }

    $c->stash->{json} = { units => $data->{units}, data=> $data, min => sprintf("%.2f",$data->{min}), max => sprintf("%.2f",$data->{max}) };
    $c->forward('View::JSON');
}

sub gauge_data {
    my ($c, $p) = @_;
    my $date_field_start = $p->{date_field_start};
    my $date_field_end = $p->{date_field_end};

    my $numeric_field = $p->{numeric_field};

    my $categories = $p->{categories};
    my $statuses = $p->{statuses};
    my $not_in_status = $p->{not_in_status};
    my $days_from = $p->{days_from};
    my $days_until = $p->{days_until};
    my $units = $p->{units} || 'day';
    my $input_units = $p->{input_units} || 'day';
    my $condition = {};
    my $end_remaining = $p->{end_remaining} || 'off';

    if ( $p->{condition} ) {
        try {
            my $cond = eval('q/'.$p->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {
            _error "JSON condition malformed (".$p->{condition}."): ".shift;
        }
    }

    my $where = $condition;
    if ( _array($statuses) ) {
        if ( $not_in_status ) {
            $where->{'category_status.id'} = mdb->nin($statuses);
        } else {
            $where->{'category_status.id'} = mdb->in($statuses);
        }
    }
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( _array($categories) ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }
    $where->{'category.id'} = mdb->in(@user_categories);

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    my $date_condition = 'created_on';
    $date_condition = $date_field_start if ( $date_field_start );

    my $now = Class::Date->now();
    if ( $days_from != 0 && $days_until != 0 ) {
        my $inc_from = $days_from."D";
        my $from = $now + $inc_from;
        my $inc_until = $days_until."D";
        my $until = $now + $inc_until;
        $where->{'$and'} = [ {$date_condition => {'$gte' => "$from"}}, {$date_condition => {'$lte' => "$until"}}];
    } elsif ( $days_from != 0 ) {
        my $inc_from = $days_from."D";
        my $from = $now + $inc_from;
        $where->{$date_condition} = {'$gte' => "$from"};        
    } elsif ( $days_until != 0 ) {
        my $inc_until = $days_until."D";
        my $until = $now + $inc_until;
        $where->{$date_condition} = {'$lte' => "$until"};        
    }


    my $rs_topics;
    my $field_mode = 0;

    if($p->{project_id}){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    if ( $numeric_field ) {
        $field_mode = 1;
        $rs_topics = mdb->topic->aggregate(
                    [
                        {'$match' => $where},
                        {'$project' => { _id => 0, mid => '$mid', 'res_time' => '$'.$numeric_field}}
                    ],
                    { cursor => 1}
                );
    } else {
        $rs_topics = mdb->topic->find($where)->fields({_id=>0,_txt=>0});
    }

    my @data = ();
    my $max = 0;
    my $min = 9999999999999999999999999;
    my $count = 0;
    while (my $topic = $rs_topics->next() ) {
        if ( $date_field_start ) {
            next if !_array($topic->{$date_field_start});
            my $date_start = Class::Date->new($topic->{$date_field_start});
            my $date_end = !$topic->{$date_field_end} ? Class::Date->now() : Class::Date->new($topic->{$date_field_end});

            my $rel = $date_end - $date_start;
            my $days = $rel->$units;
            push @data, $days;
            $max = $days if $days > $max;
            $min = $days if $days < $min;
            
        } elsif ( $field_mode ){
            next if !_array($topic->{res_time});
            push @data, $topic->{res_time};
            $max = $topic->{res_time} if $topic->{res_time} > $max;
            $min = $topic->{res_time} if $topic->{res_time} < $min;        
        } elsif ( $end_remaining eq 'on' ) {
            my $date_end = Class::Date->new($topic->{$date_field_end});
            my $now = Class::Date->now();
            my $rel = $date_end - $now;
            my $days = $rel->$units;
            push @data, $days;
            $max = $days if $days > $max;
            $min = $days if $days < $min;
        } else {
            $units = '';
            $count += 1;
            $max += 1;
            $min = 0;
        }
    }


    use List::Util qw(sum);
    my $avg = @data? sprintf("%.2f",sum(@data) / @data): 0;
    my $sum = @data? sprintf("%.2f",sum(@data)): 0; 


    if ( $field_mode ){
        if ( $input_units ne 'number' ) {
            my $sec_res = $avg;
            my $max_res = $max;
            my $min_res = $min;

            if ( $input_units eq 'minute') {
                $sec_res = $avg * 60;
                $max_res = $max * 60;
                $min_res = $min * 60;
            } elsif ( $input_units eq 'hour' ) {
                $sec_res = $avg * 60 * 60;
                $max_res = $max * 60 * 60;
                $min_res = $min * 60 * 60;
            } elsif ( $input_units eq 'day' ) {
                $sec_res = $avg * 60 * 60 * 24;
                $max_res = $max * 60 * 60 * 24;
                $min_res = $min * 60 * 60 * 24;
            }

            if ( $units eq 'month') {
                $sec_res = $sec_res / 30 / 24 / 60 / 60;
                $max_res = $max_res / 30 / 24 / 60 / 60;
                $min_res = $min_res / 30 / 24 / 60 / 60;
            } elsif ( $units eq 'day') {
                $sec_res = $sec_res / 24 / 60 / 60;
                $max_res = $max_res / 24 / 60 / 60;
                $min_res = $min_res / 24 / 60 / 60;
            } elsif ( $units eq 'hour') {
                $sec_res = $sec_res / 60 / 60;
                $max_res = $max_res / 60 / 60;
                $min_res = $min_res / 60 / 60;
            } elsif ( $units eq 'minute') {
                $sec_res = $sec_res / 60;
                $max_res = $max_res / 60;
                $min_res = $min_res / 60;
            }
            $avg = sprintf("%.2f",$sec_res);
            $max = sprintf("%.2f",$max_res);
            $min = sprintf("%.2f",$min_res);
        } else {
            $units = '';
        }
    }

    $units = $units.'s' if $units;
    return { avg => $avg, sum => $sum, min => $min, max => $max, count => $count, units => $units };
}
sub list_topics: Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my (@topics, $colors, @data, %status );
    my $group_threshold = $p->{group_threshold};
    my $categories = $p->{categories} || [];
    my $statuses = $p->{statuses} || [];
    my $not_in_status = $p->{not_in_status};
    my $filter_user = $p->{assigned_to};
    my $limit = $p->{limit} // 100;
    my $condition = {};
    my $where = {};

    if ( $p->{condition} ) {
        try {
            my $cond = eval('q/'.$p->{condition}.'/');
            $condition = Util->_decode_json($cond);
        } catch {
            _error "JSON condition malformed (".$p->{condition}."): ".shift;
        }
    }

    $where = $condition;

    if ( $filter_user && $filter_user ne 'Any') {
        if ( $filter_user eq _loc('Current')) {
            $filter_user = $c->username;
        }
        my $ci_user = ci->user->find_one({ name=>$filter_user });
        if ($ci_user) {
            my @topic_mids = 
                map { $_->{from_mid} }
                mdb->master_rel->find({ to_mid=>$ci_user->{mid}, rel_type => 'topic_users' })->fields({ from_mid=>1 })->all;
            if (@topic_mids) {
                $where->{'mid'} = mdb->in(@topic_mids);
            } else {
                $where->{'mid'} = -1;
            }
        }
    }

    my $main_conditions = {};

    if ( _array($statuses) ) {
        my @local_statuses = _array($statuses);
        if ( $not_in_status ) {
            @local_statuses = map { $_ * -1 } @local_statuses;
            $main_conditions->{'statuses'} = \@local_statuses;
        } else {
            $main_conditions->{'statuses'} = \@local_statuses;
        }
    }
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
        $_->{id};
    } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

    if ( _array($categories) ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect(@categories_ids,@user_categories);
    }

    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }

    if($p->{project_id}){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    $main_conditions->{'categories'} = \@user_categories;

    my $cnt = 0;
    ($cnt, @topics) = Baseliner->model('Topic')->topics_for_user({ limit => $limit, clear_filter => 1, where => $where, %$main_conditions, username=>$username }); #mdb->topic->find($where)->fields({_id=>0,_txt=>0})->all;

    my @topic_cis = map {$_->{mid}} @topics;
    @topics = map { my $t = {};  $t = hash_flatten($_); $t } @topics;
    my @cis = map { ($_->{to_mid},$_->{from_mid})} mdb->master_rel->find({ '$or' => [{from_mid => mdb->in(@topic_cis)},{to_mid => mdb->in(@topic_cis)}]})->all;
    my %ci_names = map { $_->{mid} => $_->{name}} mdb->master->find({ mid => mdb->in(@cis)})->all;

    $c->stash->{json} = { success => \1, data=>\@topics, cis=>\%ci_names };
    $c->forward('View::JSON'); 
}

sub topics_burndown : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $days_from = $p->{days_from} || 0;

    my $date;

    $date = Class::Date->now();
    $date = $date + ($days_from .'D');

    my $today    = substr( $date,        0, 10 );
    my $tomorrow = substr( $date + "1D", 0, 10 );
    my %hours = map { $_ => 0 } 0 .. 23;
    my $date_field = $p->{date_field};
    my $categories = $p->{categories};
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');
    my $where = {};

    my @user_categories
        = map { $_->{id}; }
        $c->model('Topic')
        ->get_categories_permissions( username => $username, type => 'view' );

    if ( _array($categories) ) {
        use Array::Utils qw(:all);
        my @categories_ids = _array($categories);
        @user_categories = intersect( @categories_ids, @user_categories );
    }

    my $is_root = $perm->is_root($username);
    if ( $username && !$is_root ) {
        Baseliner->model('Permissions')
            ->build_project_security( $where, $username, $is_root,
            @user_categories );
    }

    my @closed_status
        = map { $_->{name} } ci->status->find( { type => qr/^F|FC$/ } )->all;
    my @all_tasks
        = map { $_->{mid} }
        mdb->topic->find( { 'category.id' => mdb->in(@user_categories) } )
        ->fields( { mid => 1 } )->all;

    if($p->{project_id}){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    my $remaining_backlog = mdb->topic->find(
        {   'category.id' => mdb->in(@user_categories),
            '$and'          => [
                { $date_field => { '$lt' => $tomorrow } },
                { $date_field => { '$ne' => '' } }
            ],
            'category_status.name' => mdb->nin(@closed_status),
            %$where
        }
    )->fields( { _id => 0, mid => 1 } )->all;

    map { $hours{$_} = $hours{$_} + $remaining_backlog } 0 .. 23;

    my @closed_topic_hours
        = map { Class::Date->new( $_->{ts} )->hour } mdb->activity->find(
        {   mid           => mdb->in(@all_tasks),
            event_key     => 'event.topic.change_status',
            'vars.status' => mdb->in(@closed_status),
            ts            => { '$gte' => $today },
            %$where
        }

        )->fields( { _id => 0, ts => 1 } )->all;

    map {
        my $hour = 0 + $_;
        map { $hours{$_} = $hours{$_} + 1 } 0 .. $hour
    } @closed_topic_hours;

    my @created_topic_hours
        = map { Class::Date->new( $_->{created_on} )->hour }
        mdb->topic->find(
        {   'category.id' => mdb->in(@user_categories),
            '$and'          => [
                { $date_field => { '$lt' => $tomorrow } },
                { $date_field => { '$ne' => '' } }
            ],
            created_on => { '$gte' => $today },
            %$where
        }

        )->fields( { _id => 0, created_on => 1 } )->all;

    map {
        my $hour = 0 + $_;
        map { $hours{$_} = $hours{$_} - 1 } 0 .. $hour
    } @created_topic_hours;

    my @data;
    my @hours_list;
    my @reg_line;

    map { push @hours_list, $_; push @data, $hours{$_}; } 0 .. 23;

    @reg_line = _array( _reg_line( x => \@hours_list, y => \@data ) );

    unshift @data,       'Topics';
    unshift @hours_list, 'x';
    unshift @reg_line,   'Trend';

    $c->stash->{json} = {
        success => \1,
        date    => $date->ymd,
        data    => [ \@hours_list, \@data, \@reg_line ]
    };
    $c->forward('View::JSON');
}

sub list_emails: Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $username = $c->username;
    my @datas;
        
    
    my $emails = Baseliner->model('Messaging')->inbox(username=>$username, carrier=>'email', start => 0, limit => 1000);
    
    foreach my $email (_array $emails->{data}){
        if (!$email->{swreaded}){
            push @datas, $email;
        }
    }   

    $c->stash->{json} = {
        success => \1,
        data    => \@datas
    };
    $c->forward('View::JSON');
}

sub list_baseline : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $days     = $p->{days}     // 7;
    my $projects = $p->{projects} // 'ALL';
    my $bls      = $p->{bls};
    my $project_id = $p->{project_id};


    my $username = $c->username;
    my ( @jobs, $job, @datas, @temps, $SQL );

    #Cojemos los proyectos que el usuario tiene permiso para ver
    my @ids_project = $c->model('Permissions')
        ->user_projects_ids( username => $c->username );

    if ( $project_id ) {
        @ids_project = ($project_id);
    }

    my @filter_bls;
    if ( _array($bls) ) {
        @filter_bls = _array($bls);
    }
    else {
        @filter_bls = map { $_->{name} }
            ci->bl->find( { bl => { '$ne' => '*' } } )->all;
    }
    if (@ids_project) {

        my $date        = Class::Date->now();
        my $date_tocero = Class::Date->new(
            [ $date->year, $date->month, $date->day, "00", "00", "00" ] );
        my $days = $days . 'D';
        $date = $date_tocero - $days;
        my $date_str = $date->ymd;
        $date_str =~ s/\//\-/g;

        my @jobs_ok = _array(
            mdb->master_doc->aggregate(
                [   {   '$match' => {
                            bl           => mdb->in(@filter_bls),
                            'projects'   => mdb->in(@ids_project),
                            'collection' => 'job',
                            'status'     => 'FINISHED',
                            'endtime'    => { '$gte' => '' . $date_str }
                        }
                    },
                    {   '$group' => {
                            _id      => '$bl',
                            'result' => { '$max' => 'OK' },
                            'tot'    => { '$sum' => 1 }
                        }
                    }
                ]
            )
        );

        my @jobs_ko = _array(
            mdb->master_doc->aggregate(
                [   {   '$match' => {
                            bl           => mdb->in(@filter_bls),
                            'projects'   => mdb->in(@ids_project),
                            'collection' => 'job',
                            'status'     => mdb->in(
                                (   'ERROR', 'CANCELLED', 'KILLED',
                                    'REJECTED'
                                )
                            ),
                            'endtime' => { '$gte' => '' . $date_str }
                        }
                    },
                    {   '$group' => {
                            _id      => '$bl',
                            'result' => { '$max' => 'ERROR' },
                            'tot'    => { '$sum' => 1 }
                        }
                    }
                ]
            )
        );

        @jobs = ( @jobs_ok, @jobs_ko );

        foreach my $entorno (@filter_bls) {
            my ( $totError, $totOk, $total, $porcentError, $porcentOk, $bl )
                = ( 0, 0, 0, 0, 0 );
            @temps = grep { $_->{_id} eq $entorno } @jobs;
            foreach my $temp (@temps) {
                $bl = $temp->{_id};
                if ( $temp->{result} eq 'OK' ) {
                    $totOk = $temp->{tot};
                }
                else {
                    $totError = $temp->{tot};
                }
            } ## end foreach my $temp ( @temps )
            $total = $totOk + $totError;
            if ($total) {
                $porcentOk    = $totOk * 100 / $total;
                $porcentError = $totError * 100 / $total;
            }
            else {
                $bl           = $entorno;
                $totOk        = '';
                $totError     = '';
                $porcentOk    = 0;
                $porcentError = 0;
            } ## end else [ if ( $total ) ]
            push @datas,
                {
                bl           => $bl,
                porcentOk    => $porcentOk,
                totOk        => $totOk,
                total        => $total,
                totError     => $totError,
                porcentError => $porcentError
                };
        }
    }
    $c->stash->{json} = {
        success => \1,
        data    => \@datas
    };
    $c->forward('View::JSON');
}

sub viewjobs : Local {
    my ( $self, $c, $days, $type, $bl, $project_id ) = @_;
    my $p = $c->request->parameters;

    #Cojemos los proyectos que el usuario tiene permiso para ver jobs
    my @ids_project = $c->model( 'Permissions' )->user_projects_with_action(username => $c->username,
                                                                            action => 'action.job.viewall',
                                                                            level => 1);
    if ( $project_id ) {
        @ids_project = ($project_id);
    }
    #Filtramos por la parametrización cuando no son todos
    # if($config->{projects} ne 'ALL'){
    #     @ids_project = grep {$_ =~ $config->{projects}} @ids_project;
    # }
    
    my @jobs;
    
    if($type){
        my @status;
        given ($type) {
            when ('ok') {
                @status = ('FINISHED');
            }
            when ('nook'){
                @status = ('ERROR','CANCELLED','KILLED','REJECTED');
            }
        }
        
        my $days = $days . 'D';
        my $start = mdb->now - $days; 
        $start = Class::Date->new( [$start->year,$start->month,$start->day,"00","00","00"]);

        @jobs = ci->job->find({ projects => mdb->in(@ids_project), endtime => { '$gt' => "$start" }, status=>mdb->in(@status), bl=>$bl })->all;
        
    }else{
        @jobs = ci->job->find({ status=>'RUNNING', bl=>mdb->in(($bl)) })->all;
    }

    $c->stash->{jobs} = @jobs ? join(',', map {$_->{mid}} @jobs) : -1;
    $c->forward('/job/monitor/Dashboard');
}

##################################################
#
# TODO 
# old dashlet data, deprecated? move somewhere else?
#
##################################################

sub list_pending_jobs: Private{
    my ( $self, $c, $dashboard_id, $params ) = @_;
    my $perm = Baseliner->model('Permissions');

    #######################################################################################################
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $config = get_config_dashlet( 'list_pending_jobs', $dashboard_id, $params );
    ##########################################################################################################
    $c->stash->{dashboard_id} = $config->{dashboard_id};

    my @mid_filters = ();
    my $limit = $config->{rows} // 10;
    my $statuses = 'APPROVAL,TRAPPED,PAUSED';
    my $username = $c->username;

    if( !$perm->is_root($username) ) {
            @mid_filters = $perm->user_projects_with_action(username => $username,
                                                                action => 'action.job.viewall',
                                                                level => 1);
            
    }

    my $where = {};
    $where->{'projects.mid'} = mdb->in(@mid_filters) if @mid_filters;
    $where->{collection} = 'job';

    my @filter_statuses;
    @filter_statuses = split /,/,$statuses;
    $where->{status} = mdb->in(@filter_statuses);

    my @rs_search = mdb->master_doc->find( $where )->sort({ starttime => -1 })->all;

    my $numrow = 0;
    my @pending_jobs;
    my $default_config;
    
    for my $doc ( @rs_search ) {
        last if $numrow >= $limit;
        try {
            my $job = ci->new( $doc->{mid} );
            push @pending_jobs,
                {
                mid       => $job->mid,
                name      => $job->name,
                type      => $job->job_type,
                rollback  => $job->rollback,
                status    => $job->status,
                starttime => $job->starttime,
                endtime   => $job->endtime,
                bl => $job->bl,
                apps => join ",", _array($job->{job_contents}->{list_apps})
                };
            $numrow++;
        } catch {
            _log "FAILURE Searching job ".$doc->{mid}.": " . shift;
        };
    }
    $c->stash->{pending_jobs} =\@pending_jobs;
}

sub list_filtered_topics_old: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    #my (@topics, $topic, @datas, $SQL);
    
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.filtered_topics');	
    
    ##########################################################################################################      
    
    # go to the controller for the list
    my $p = { limit => $default_config->{rows}, username=>$c->username };
    my ($info, @rows) = $c->model('Topic')->topics_for_user( $p );
    $c->stash->{topics} = \@rows ;
}

sub list_filtered_topics: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    #my (@topics, $topic, @datas, $SQL);
    
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.filtered_topics');    
    if($dashboard_id ){
        my $dashboard_rs = mdb->dashboard->find_one({_id => mdb->oid($dashboard_id)});
        my @config_dashlet = grep {$_->{url}=~ 'list_filtered_topics'} _array $dashboard_rs->{dashlets};
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };              
        }      
    }   
    ##########################################################################################################      
    
    # go to the controller for the list
    my $p = { limit => $default_config->{rows}, username=>$c->username, clear_filter => 1 };

    if ( $default_config->{statuses} && $default_config->{statuses} ne 'ALL') {
        my @statuses = split /,/, $default_config->{statuses};
        my @status_ids = map {$_->{id_status}} ci->status->find({ name => mdb->in(@statuses)})->all;
        $p->{statuses} = \@status_ids;
    }

    if ( $default_config->{categories} && $default_config->{categories} ne 'ALL') {
        my @categories = split /,/, $default_config->{categories};
        my @categories_ids = map {$_->{id}} mdb->category->find({ name => mdb->in(@categories)})->all;
        $p->{categories} = \@categories_ids;
    }

    my ($info, @rows) = $c->model('Topic')->topics_for_user( $p );
    $c->stash->{filtered_topics} = \@rows ;
}

sub list_releases: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    #my (@topics, $topic, @datas, $SQL);
    
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.list_releases');    
    if($dashboard_id ){
        my $dashboard_rs = mdb->dashboard->find_one({_id => mdb->oid($dashboard_id)});
        my @config_dashlet = grep {$_->{url}=~ 'list_releases'} _array $dashboard_rs->{dashlets};
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };              
        }      
    }   
    ##########################################################################################################      
    
    # go to the controller for the list
    my $p = { limit => $default_config->{rows}, username=>$c->username, clear_filter => 1 };

    if ( $default_config->{statuses} && $default_config->{statuses} ne 'ALL') {
        my @statuses = split /,/, $default_config->{statuses};
        my @status_ids = map {$_->{id_status}} ci->status->find({ name => mdb->in(@statuses)})->all;
        $p->{statuses} = \@status_ids;
    }

    if ( $default_config->{categories} && $default_config->{categories} ne 'ALL') {
        my @categories = split /,/, $default_config->{categories};
        # my @categories_ids = map {$_->{id}} mdb->category->find({ name => mdb->in(@categories)})->all;
        my @categories_ids = map {$_->{id}} mdb->category->find({ is_release => '1', name => mdb->in(@categories)})->all;
        $p->{categories} = \@categories_ids;
    }

    my ($info, @rows) = $c->model('Topic')->topics_for_user( $p );
    $c->stash->{list_releases} = \@rows ;
}

sub list_my_topics: Private{
    my ( $self, $c, $dashboard_id ) = @_;
    my $username = $c->username;
    #my (@topics, $topic, @datas, $SQL);
    
    #CONFIGURATION DASHLET
    ##########################################################################################################
    my $default_config = Baseliner->model('ConfigStore')->get('config.dashlet.filtered_topics');	
    if($dashboard_id ){
        my $dashboard_rs = mdb->dashboard->find_one({_id => mdb->oid($dashboard_id)});
        my @config_dashlet = grep {$_->{url}=~ 'list_my_topics'} _array $dashboard_rs->{dashlets};
        
        if($config_dashlet[0]->{params}){
            foreach my $key (keys %{ $config_dashlet[0]->{params} || {} }){
                $default_config->{$key} = $config_dashlet[0]->{params}->{$key};
            };              
        }      
    }   
    ##########################################################################################################		
    
    # go to the controller for the list
    my $limit = $default_config->{rows} && $default_config->{rows} ne 'ALL'? $default_config->{rows}:'';
    my $p = { limit => $limit, username=>$c->username };

    if ( $default_config->{categories} && $default_config->{categories} ne 'ALL') {
        my @categories = split /,/, $default_config->{categories};
        my @categories_ids = map {$_->{id}} mdb->category->find({ name => mdb->in(@categories)})->all;
        $p->{categories} = \@categories_ids;
    }

    $p->{assigned_to_me} = 1;

    my ($info, @rows) = $c->model('Topic')->topics_for_user( $p );
    $c->stash->{my_topics} = \@rows ;
}

sub topics_open_by_category: Local{
    my ( $self, $c, $action ) = @_;
    #my $p = $c->request->parameters;
    my ($SQL, @topics_open_by_category, @datas);


    my $where = {};
    my $username = $c->username;
    my $perm = Baseliner->model('Permissions');

    my @user_categories =  map {
                $_->{id};
            } $c->model('Topic')->get_categories_permissions( username => $username, type => 'view' );


    my $is_root = $perm->is_root( $username );
    if( $username && ! $is_root){
        Baseliner->model('Permissions')->build_project_security( $where, $username, $is_root, @user_categories );
    }
    $where->{'category.id'} = mdb->in(@user_categories);
    $where->{'category_status.type'} = mdb->nin(('F','FC'));

    @topics_open_by_category = _array (mdb->topic->aggregate( [
        { '$match' => $where },
        { '$group' => { _id => '$category.id', 'category' => {'$max' => '$category.name'},'color' => {'$max' => '$category.color'}, 'total' => { '$sum' => 1 }} },
        { '$sort' => { total => -1}}
    ]));
    
    foreach my $topic (@topics_open_by_category){
        push @datas, {
                    total 			=> $topic->{total},
                    category		=> $topic->{category},
                    color			=> $topic->{color},
                    category_id		=> $topic->{_id}
                };
     }
    $c->stash->{topics_open_by_category} = \@datas;
    $c->stash->{topics_open_by_category_title} = _loc('Topics open by category');

}

sub list_status_changed: Local{
    my ( $self, $c ) = @_;
    
    my $now1 = my $now2 = mdb->now;
    $now2 += '1D';
    
    my $fecha1 = $now1->ymd;
    $fecha1 =~ s/\//-/g;
    
    my $fecha2 = $now2->ymd;
    $fecha2 =~ s/\//-/g;
    
    my $query = {
        event_key   => 'event.topic.change_status',
        ts          => { '$lte' => ''.$fecha2, '$gte' => ''.$fecha1 },
    };
    
    #my @user_categories =  map { $_->{id} } $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view' );
    #my @user_project_ids = Baseliner->model("Permissions")->user_projects_ids( username => $c->username);
    
    my %my_topics;
    my ($info, @rows ) = Baseliner->model('Topic')->topics_for_user({ username => $c->username, limit=>1000, query=>undef, clear_filter => 1 });
    map { $my_topics{$_->{mid}} = 1 } @rows;

    

    my @status_changes;
    my @mid_topics;
    my @topics = mdb->activity->find($query)->sort({ ts=>-1 })->all;

    map {
        my $ed = $_->{vars} ;
        if ( (exists $my_topics{$_->{mid}} || Baseliner->model("Permissions")->is_root( $c->username ) ) && $ed->{old_status} ne $ed->{status}){
            push @status_changes, { old_status => $ed->{old_status}, status => $ed->{status}, username => $ed->{username}, when => $_->{ts}, mid => $_->{mid} };
            push @mid_topics, $_->{mid};
        }
    } @topics;
    
    @status_changes = sort { $a->{mid} <=> $b->{mid} } @status_changes;
    @mid_topics = _unique @mid_topics ;
    
    my %topics_categories;
    $topics_categories{ $_->{mid} } = { color=>$_->{category}{color}, name=>$_->{category}{name} } 
     for   mdb->topic->find({ mid=>mdb->in(@mid_topics) })->all;
    
    $c->stash->{list_topics} = \%topics_categories;
    $c->stash->{list_status_changed} = \@status_changes;
    $c->stash->{list_status_changed_title} = _loc('Daily highlights');    
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__DATA__
---
- rule_active: '1'
  rule_desc: ''
  rule_event: ~
  rule_name: Complete Dashboard
  rule_tree: '[{"attributes":{"icon":"/static/images/icons/let.gif","palette":false,"disabled":false,"on_drop_js":null,"key":"statement.var.set_expr","who":"root","text":"SET
    six_months_ago","expanded":false,"id":"rule-ext-gen10859-1431204661737","run_sub":true,"leaf":true,"ts":"2015-05-03T16:58:32","name":"SET
    EXPR","active":1,"holds_children":false,"data":{"expr":"my $now = Class::Date->now();\n''''.($now
    - ''6M'');","variable":"six_months_ago"},"nested":0,"on_drop":""},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_pie.png","palette":false,"disabled":false,"key":"dashlet.job.chart","who":"root","html":"","timeout":"","text":"Job
    status - Last month","expanded":false,"id":"rule-ext-gen10866-1431204661743","semaphore_key":"","leaf":true,"ts":"2015-05-11T08:57:58","name":"Job
    Status pie","trap_timeout_action":"abort","parallel_mode":"none","active":1,"data":{"period":"1M","parallel_mode":"none","trap_timeout_action":"abort","rows":"1","error_trap":"none","needs_rollback_mode":"none","sub_name":"","needs_rollback_key":"<always>","autorefresh":"0","data_key":"","timeout":"","columns":"4","trap_timeout":"0","type":"donut","semaphore_key":""},"trap_rollback":true,"error_trap":"none","needs_rollback_mode":"none","note":"","run_rollback":true,"data_key":"","trap_timeout":"0","run_forward":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_pie.png","palette":false,"disabled":false,"key":"dashlet.job.chart","who":"root","html":"","timeout":"","text":"Job
    status - Last quarter","expanded":false,"id":"rule-ext-gen10865-1431204661742","semaphore_key":"","leaf":true,"ts":"2015-05-15T18:48:42","name":"Job
    Status pie","trap_timeout_action":"abort","parallel_mode":"none","active":1,"data":{"period":"3M","autorefresh":"0","columns":"4","bls":[],"type":"donut","rows":"1"},"trap_rollback":true,"error_trap":"none","needs_rollback_mode":"none","note":"","run_rollback":true,"data_key":"","trap_timeout":"0","run_forward":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_pie.png","palette":false,"disabled":false,"key":"dashlet.job.chart","who":"root","html":"","timeout":"","text":"Job
    status - Last year","expanded":false,"id":"rule-ext-gen10862-1431204661738","semaphore_key":"","leaf":true,"ts":"2015-05-11T08:57:30","name":"Job
    Status pie","trap_timeout_action":"abort","parallel_mode":"none","active":1,"data":{"period":"1Y","parallel_mode":"none","trap_timeout_action":"abort","rows":"1","error_trap":"none","needs_rollback_mode":"none","sub_name":"","needs_rollback_key":"<always>","autorefresh":60000,"data_key":"","timeout":"","columns":"4","trap_timeout":"0","type":"donut","semaphore_key":""},"trap_rollback":true,"error_trap":"none","needs_rollback_mode":"none","note":"","run_rollback":true,"data_key":"","trap_timeout":"0","run_forward":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_line.png","disabled":false,"ts":"2015-05-18T22:56:51","name":"Topics
    burndown","active":1,"data":{"rows":"1","columns":"6","autorefresh":"0","categories":"","date_field":"created_on","date_type":"today"},"key":"dashlet.topic.topics_burndown","html":"","who":"root","text":"Today''s
    topics burndown","expanded":false,"id":"rule-ext-gen10861-1431204661738","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_line.png","isTarget":false,"html":"","text":"Job
    daily distribution","key":"dashlet.job.day_distribution","leaf":true,"id":"rule-ext-gen2666-1431982805405","name":"Job
    daily distribution","data":{"rows":"1","columns":"6","autorefresh":"0","period":"1Y","type":"stack-area","joined":"0","bls":[]},"ts":"2015-05-18T23:01:02","who":"root","expanded":false},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_curve.png","disabled":false,"ts":"2015-05-15T09:31:46","name":"Topics
    by date line chart","active":1,"data":{"days_until":"","days_from":"-365","categories":"","rows":"1","group":"month","autorefresh":"0","date_field":"created_on","columns":"6","type":"stack-area","statuses":"","condition":""},"key":"dashlet.topic.topics_by_date_line","html":"","who":"root","text":"Topics
    created monthly - Last year","expanded":false,"id":"rule-ext-gen10863-1431204661738","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/icons/report_default.png","disabled":false,"ts":"2015-05-18T22:55:52","name":"List
    topics","active":1,"data":{"rows":"1","columns":"8","autorefresh":60000,"statuses":"","categories":"","assigned_to":"","condition":"{\"created_on\":{\"$lte\":\"${six_months_ago}\"},\"category_status.type\":{\"$nin\":[\"F\",\"FC\"]}}","fields":""},"key":"dashlet.topic.list_topics","html":"","who":"root","text":"Open
    topics older than 6 months","expanded":false,"id":"rule-ext-gen10864-1431204661742","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/world.png","palette":false,"disabled":true,"ts":"2015-05-08T04:01:15","active":0,"name":"Internet
    frame","data":{"autorefresh":"0","columns":"12","url":"http://www.clarive.com/","rows":"2"},"key":"dashlet.iframe","who":"root","html":"","text":"Clarive.com","expanded":false,"id":"rule-ext-gen10867-1431204661743","leaf":true},"children":[]}]'
  rule_type: dashboard
- rule_active: '1'
  rule_desc: ''
  rule_event: ~
  rule_name: Release Manager
  rule_tree: '[{"attributes":{"palette":false,"icon":"/static/images/silk/chart_curve.png","disabled":false,"ts":"2015-05-11T12:47:30","name":"Topics
    by date line chart","active":1,"data":{"days_until":"0","days_from":"-60","categories":"","rows":"1","group":"month","autorefresh":"0","date_field":"created_on","columns":"8","type":"area","statuses":"","condition":""},"key":"dashlet.topic.topics_by_date_line","html":"","who":"root","text":"Topics
    created monthly","expanded":false,"id":"rule-ext-gen12563-1431198379635","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_pie.png","isTarget":false,"html":"","text":"Releases
    aprobadas","key":"dashlet.topic.number_of_topics","leaf":true,"id":"rule-ext-gen6948-1431424514648","name":"Topics
    chart","data":{"rows":"1","columns":"4","autorefresh":"0","statuses":"122","categories":["7","44","45"],"condition":"","group_threshold":"5","type":"donut","group_by":"topics_by_category"},"ts":"2015-05-12T11:55:47","who":"root","expanded":false},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_line.png","disabled":false,"ts":"2015-05-08T03:59:38","name":"Topics
    burndown","active":1,"data":{"date_type":"yesterday","autorefresh":"0","date_field":"scheduled_start_date","columns":"6","categories":"","rows":"1"},"key":"dashlet.topic.topics_burndown","html":"","who":"root","text":"Yesterday''s
    topics burndown","expanded":false,"id":"rule-ext-gen12565-1431198379635","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_line.png","disabled":false,"ts":"2015-05-08T03:59:44","name":"Topics
    burndown","active":1,"data":{"date_type":"today","autorefresh":"0","date_field":"scheduled_start_date","columns":"6","categories":"","rows":"1"},"key":"dashlet.topic.topics_burndown","html":"","who":"root","text":"Today''s
    topics burndown","expanded":false,"id":"rule-ext-gen12566-1431198379636","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_pie.png","palette":false,"disabled":false,"ts":"2015-05-11T16:01:34","active":1,"name":"Topics
    chart","data":{"group_threshold":"5","categories":"","rows":"1","autorefresh":"0","columns":"6","group_by":"topics_by_status","type":"pie","statuses":"","condition":""},"key":"dashlet.topic.number_of_topics","who":"root","html":"","text":"Topics
    chart","expanded":false,"id":"rule-ext-gen5382-1431341288631","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/icons/report_default.png","palette":false,"disabled":false,"ts":"2015-05-08T03:56:48","active":1,"name":"List
    topics","data":{"categories":"","rows":"1","autorefresh":"0","fields":"","columns":"8","assigned_to":"","statuses":"","condition":"{\"category_status.type\":{\"$nin\":[\"F\",\"FC\"]}}"},"key":"dashlet.topic.list_topics","who":"root","html":"","text":"Open
    topics","expanded":false,"id":"rule-ext-gen12568-1431198379636","leaf":true},"children":[]}]'
  rule_type: dashboard
- rule_active: '1'
  rule_desc: ''
  rule_event: ~
  rule_name: Operations
  rule_tree: '[{"attributes":{"palette":false,"icon":"/static/images/icons/report_default.png","disabled":false,"ts":"2015-05-11T02:26:00","name":"List
    jobs","active":1,"data":{"autorefresh":"0","columns":"6","states":["APPROVAL","PAUSED","TRAPPED","TRAPPED_PAUSED","PENDING","READY","RUNNING","WAITING","IN-EDIT","RESUME"],"bls":[],"limit":"100","rows":"1"},"key":"dashlet.job.list_jobs","html":"","who":"root","text":"Pending
    jobs","expanded":false,"id":"rule-ext-gen16612-1431299434041","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/icons/report_default.png","disabled":false,"ts":"2015-05-11T02:27:28","name":"List
    jobs","active":1,"data":{"autorefresh":"0","columns":"6","states":["APPROVAL","PAUSED","TRAPPED","TRAPPED_PAUSED","PENDING","READY","RUNNING","WAITING","IN-EDIT","RESUME"],"not_in_states":"on","bls":[],"limit":"100","rows":"1"},"key":"dashlet.job.list_jobs","html":"","who":"root","text":"Last
    finished jobs","expanded":false,"id":"rule-ext-gen20048-1431304009089","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_line.png","palette":false,"disabled":false,"ts":"2015-05-14T13:30:01","active":1,"name":"Job
    daily day_distribution","data":{"period":"1Y","autorefresh":"0","columns":"6","bls":[],"type":"stack-area","rows":"1","joined":"0"},"key":"dashlet.job.day_distribution","who":"root","html":"","text":"Job
    daily distribution - By BL","expanded":false,"id":"rule-ext-gen9103-1431252639222","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_line.png","palette":false,"disabled":false,"ts":"2015-05-14T13:30:13","active":1,"name":"Job
    daily day_distribution","data":{"period":"1Y","autorefresh":"0","columns":"6","bls":[],"type":"stack-area","rows":"1","joined":"1"},"key":"dashlet.job.day_distribution","who":"root","html":"","text":"Job
    daily distribution - Total","expanded":false,"id":"rule-ext-gen14674-1431291038500","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_pie.png","palette":false,"disabled":false,"ts":"2015-05-18T23:04:51","active":1,"name":"Job
    chart","data":{"rows":"1","columns":"4","autorefresh":"0","period":"1Y","type":"donut","bls":[]},"key":"dashlet.job.chart","who":"root","html":"","text":"Jobs
    quality - Last year","expanded":false,"id":"rule-ext-gen14005-1431284044680","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/icons/report_default.png","disabled":false,"ts":"2015-05-11T00:19:37","name":"Last
    jobs by app","active":1,"data":{"autorefresh":"0","columns":"8","bls":[],"rows":"1"},"key":"dashlet.job.last_jobs","html":"","who":"root","text":"Last
    jobs by app","expanded":false,"id":"rule-ext-gen14889-1431292551790","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/icons/report_default.png","disabled":false,"ts":"2015-05-11T11:13:58","name":"List
    topics","active":1,"data":{"categories":"145","rows":"1","autorefresh":"0","fields":"","columns":"6","assigned_to":"","statuses":"","condition":""},"key":"dashlet.topic.list_topics","html":"","who":"root","text":"List
    topics","expanded":false,"id":"rule-ext-gen22244-1431335627966","leaf":true},"children":[]}]'
  rule_type: dashboard
- rule_active: '1'
  default_dashboard: '1'
  rule_desc: ''
  rule_event: ~
  rule_name: Main Dashboard
  rule_tree: '[{"attributes":{"palette":false,"icon":"/static/images/silk/chart_pie.png","disabled":false,"ts":"2015-05-19T00:41:12","name":"Topics
    chart","active":1,"data":{"group_threshold":"5","categories":"","rows":"1","autorefresh":"0","columns":"4","group_by":"topics_by_status","type":"donut","statuses":"","condition":"{\"category_status.type\":{\"$nin\":[\"F\",\"FC\"]}}"},"key":"dashlet.topic.number_of_topics","html":"","who":"root","text":"Open
    topics by status","expanded":false,"id":"rule-ext-gen4715-1431988673581","leaf":true},"children":[]},{"attributes":{"palette":false,"icon":"/static/images/silk/chart_pie.png","disabled":false,"ts":"2015-05-19T00:41:23","name":"Topics
    chart","active":1,"data":{"group_threshold":"5","categories":"","rows":"1","autorefresh":"0","columns":"4","group_by":"topics_by_category","type":"donut","statuses":"","condition":"{\"category_status.type\":{\"$nin\":[\"F\",\"FC\"]}}"},"key":"dashlet.topic.number_of_topics","who":"root","html":"","text":"Open
    topics by category","expanded":false,"id":"rule-ext-gen4884-1431988740944","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_curve.png","palette":false,"disabled":false,"ts":"2015-05-19T00:43:52","active":1,"name":"Topics
    time line","data":{"days_until":"","days_from":"-60","categories":"","rows":"1","group":"month","autorefresh":"0","date_field":"created_on","columns":"4","type":"stack-area","statuses":"","condition":""},"key":"dashlet.topic.topics_by_date_line","who":"root","html":"","text":"Topics
    open last trimester","expanded":false,"id":"rule-ext-gen8029-1431988988253","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/icons/report_default.png","palette":false,"disabled":false,"ts":"2015-05-19T00:45:25","active":1,"name":"List
    topics","data":{"categories":"","rows":"1","autorefresh":"0","fields":"","columns":"6","assigned_to":"Actual","statuses":"","condition":"{\"category_status.type\":{\"$nin\":[\"F\",\"FC\"]}}"},"key":"dashlet.topic.list_topics","who":"root","html":"","text":"My
    open topics","expanded":false,"id":"rule-ext-gen8196-1431989095468","leaf":true},"children":[]},{"attributes":{"icon":"/static/images/silk/chart_line.png","palette":false,"disabled":false,"ts":"2015-05-18T22:56:51","active":1,"name":"Topics
    burndown","data":{"date_type":"today","autorefresh":"0","date_field":"created_on","columns":"6","categories":"","rows":"1"},"key":"dashlet.topic.topics_burndown","who":"root","html":"","text":"Today''s
    changesets burndown","expanded":false,"id":"rule-ext-gen741-1431989460664","leaf":true},"children":[]}]'
  rule_type: dashboard
