package Baseliner::Model::Jobs;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use namespace::clean;
use Baseliner::Utils;
use Baseliner::Sugar;
use Compress::Zlib;
use Archive::Tar;
use Path::Class;
use Try::Tiny;
use Data::Dumper;
use utf8;
use Class::Date;

sub monitor {
    my ($self,$p) = @_;
    my $perm = Baseliner->model('Permissions');
    my $username = $p->{username};

    my ($start, $limit, $query, $query_id, $dir, $sort, $filter, $cnt ) = @{$p}{qw/start limit query query_id dir sort filter/};
    $start||=0;
    $limit||=50;

    $sort = 'step' if $sort && $sort eq 'step_code';
    $sort ||= 'mid';
    $dir = !$dir ? -1 : lc $dir eq 'desc' ? -1 : 1; 
    my $order_by = { $sort => $dir };

    $start=$p->{next_start} if $p->{next_start} && $start && $query;

    my $page = to_pages( start=>$start, limit=>$limit );

    ### WHERE
    my $where = {};
    my @mid_filters;
    if( length($query) ) {
        $query =~ s{(\w+)\*}{job "$1"}g;  # apparently "<str>" does a partial, but needs something else, so we put the collection name "job"
        $query =~ s{([\w\-\.]+)}{"$1"}g;  # fix the "N.ENV-00000319" type search
        $query =~ s{\+(\S+)}{"$1"}g;
        $query =~ s{""+}{"}g;
        _debug "Job QUERY=$query";
        my @mids_query = map { $_->{obj}{mid} } 
            _array( mdb->master_doc->search( query=>$query, limit=>1000, project=>{mid=>1}, filter=>{ collection=>'job' })->{results} );
        push @mid_filters, { mid=>mdb->in(@mids_query) };
    }
    
    # user content
    #if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
    #    my @user_apps = $perm->user_projects_names( username=>$username ); # user apps
    #    # TODO check cs topics relationship with projects
    #    # $where->{'bali_job_items.application'} = { -in => \@user_apps } if ! ( grep { $_ eq '/'} @user_apps );
    #    # username can view jobs where the user has access to view the jobcontents corresponding app
    #    # username can view jobs if it has action.job.view for the job set of job_contents projects/app/subapl
    #}
    
    if( !Baseliner->is_root($username) ) {
        my @ids_project = $perm->user_projects_with_action(username => $username,
                                                            action => 'action.job.viewall',
                                                            level => 1);
        
        my $rs_jobs1 = Baseliner->model('Baseliner::BaliMasterRel')->search({rel_type => 'job_project', to_mid => \@ids_project}
                                                                           ,{select=>'from_mid'});
        push @mid_filters, { mid=>mdb->in( map { $_->{from_mid} } $rs_jobs1->hashref->all ) };
    }
    
    if( length $p->{job_state_filter} ) {
        my @job_state_filters = do {
                my $job_state_filter = Util->decode_json( $p->{job_state_filter} );
                _unique grep { $job_state_filter->{$_} } keys %$job_state_filter;
        };
        $where->{status} = mdb->in( \@job_state_filters );
    }

    # Filter by nature
    if (length $p->{filter_nature} && $p->{filter_nature} ne 'ALL' ) {
        # TODO nature only exists after PRE executes, "Load natures" $where->{'bali_job_items_2.item'} = $p->{filter_nature};
        $where->{natures} = mdb->in( _array( $p->{filter_nature} ) );
    }

    # Filter by environment name:
    if (exists $p->{filter_bl}) {      
      $where->{bl} = $p->{filter_bl};
    }

    # Filter by job_type
    if (exists $p->{filter_type}) {      
      $where->{job_type} = $p->{filter_type};
    }
        
    if($query_id ne '-1'){
        #Cuando viene por el dashboard
        my @jobs = split(",",$query_id);
        $where->{'mid'} = mdb->in( \@jobs );
    }
    
    $where->{'$and'} =\@mid_filters if @mid_filters;
    _debug $where;

    if( $filter ) {
        $filter = Util->_decode_json( $filter );
        my $where_filter = {};
        for my $fi ( _array( $filter ) ) {
            my $val = $fi->{value};
            if( $fi->{type} eq 'date' ) {
                $val = Class::Date->new( $val )->string ;
                my $oper = $fi->{comparison};
                if( $oper eq 'eq' ) {
                    $where_filter->{$fi->{field}}={ '$gt'=>$val, '$lt'=>(Class::Date->new($val)+'1D')->string };
                } else {
                    $where_filter->{$fi->{field}}{'$'.$oper }=$val;
                }
            }
            elsif( $fi->{type} eq 'string' ) {
                $where_filter->{$fi->{field}} = qr/$val/i;
            }
        }
        $where = { %$where, %$where_filter };
    }
    
    _debug $where;

    my $rs = mdb->master_doc->find({ collection=>'job', %$where })->sort($order_by);
    $cnt = $rs->count;
    $rs->limit($limit)->skip($start);

    my @rows;
    #while( my $r = $rs->next ) {
    my $now = _dt();
    my $today = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>0, minute=>0, second=>0) ; 
    my $ahora = DateTime->new( year=>$now->year, month=>$now->month, day=>$now->day, , hour=>$now->hour, minute=>$now->minute, second=>$now->second ) ; 
    
    #foreach my $r ( _array $results->{data} ) {
    #local $Baseliner::CI::no_rels = 1;
    _debug "Looping start...";

    local $Baseliner::CI::mid_scope = {};

    for my $job ( $rs->all ) {
        my $step = _loc( $job->{step} );
        my $status = _loc( $job->{status} );
        my $type = _loc( $job->{type} );
        my @changesets = (); #_array $job_items{ $job->{id} };
        
        # list_contents, list_apps are cache vars
        if( !exists $job->{list_contents} || !exists $job->{list_apps} || !exists $job->{list_natures} ) {
            if ( my $ci = try { ci->new( $job->{mid} ) } catch { '' } ) {   # if -- support legacy jobs without cis?
                $job->{list_contents} //= [ map { $_->topic_name } _array( $ci->changesets ) ];
                $job->{list_releases} //= [ map { $_->topic_name } _array( $ci->releases ) ];
                $job->{list_apps} //= [ map { $_->name } _array( $ci->projects ) ];
                $job->{list_natures} //= [ map { $_->name } _array( $ci->natures ) ];
                _warn "Saving job lists for mid " . _dump($job->{_id});
                mdb->master_doc->save( $job );
            }
        }
        my $last_log_message = $job->{last_log_message};

        # Scheduled, Today, Yesterday, Weekdays 1..7, 1..4 week ago, Last Month, Older
        my $grouping='';
        my $day;  
        my $sdt = parse_dt( '%Y-%m-%d %H:%M:%S', $job->{starttime} // $job->{ts}  );
        my $dur =  $today - $sdt; 
        $sdt->{locale} = DateTime::Locale->load( $p->{language} || 'en' ); # day names in local language
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
            id           => $job->{jobid},
            mid          => $job->{mid},
            name         => $job->{name},
            bl           => $job->{bl},
            bl_text      => $job->{bl},  #TODO resolve bl name
            ts           => $job->{ts},
            starttime    => $job->{starttime},
            schedtime    => $job->{schedtime},
            maxstarttime => $job->{maxstarttime},
            endtime      => $job->{endtime},
            comments     => $job->{comments},
            username     => $job->{username},
            rollback     => $job->{rollback},
            has_errors   => $job->{has_errors},
            has_warnings => $job->{has_warnings},
            key          => $job->{job_key},
            last_log     => $last_log_message,
            grouping     => $grouping,
            day          => ucfirst( $day->[1] ),
            step         => $step,
            step_code    => $job->{step},
            exec         => $job->{'exec'},
            pid          => $job->{pid},
            owner        => $job->{owner},
            host         => $job->{host},
            status       => $status,
            status_code  => $job->{status},
            type_raw     => $job->{type},
            type         => $type,
            runner       => $job->{runner},
            id_rule      => $job->{id_rule},
            contents     => $job->{list_contents} || [],
            releases     => $job->{list_releases} || [],
            applications => $job->{list_apps} || [],
            natures      => $job->{list_natures} || [],
            #subapps      => \@subapps,   # maybe use _path_xs from Utils.pm?
          }; # if ( ( $cnt++ >= $start ) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    _debug "Looping end ";
    #_debug \@rows;

    return ( $cnt, @rows );
}


with 'Baseliner::Role::Search';
with 'Baseliner::Role::Service';

sub search_provider_name { 'Jobs' };
sub search_provider_type { 'Job' };
sub search_query {
    my ($self, %p ) = @_;
    
    $p{limit} //= 1000;
    $p{query_id} = -1;
    my ($cnt, @rows ) = Baseliner->model('Jobs')->monitor(\%p);
    return map {
        my $r = $_;
        #my $summary = join ',', map { "$_: $r->{$_}" } grep { defined $_ && defined $r->{$_} } keys %$r;
        my @text = 
            grep { length }
            map { "$_" }
            map { _array( $_ ) }
            grep { defined }
            map { $r->{$_} }
            keys %$r;
        chomp @text;
        +{
            title => $r->{name},
            info  => $r->{ts},
            text  => join(', ', @text ),
            url   => [ $r->{id}, $r->{name}, undef, undef, '/static/images/icons/job.png' ],
            type  => 'log'
        }
    } @rows;
}

sub get {
    my ($self, $id ) = @_;
    return Baseliner->model('Baseliner::BaliJob')->find($id) if $id =~ /^[0-9]+$/;
    return Baseliner->model('Baseliner::BaliJob')->search({ name=>$id })->first;
}

register 'event.job.rerun';
register 'event.job.reschedule';

sub status {
    my ($self,%p) = @_;
    my $jobid = $p{jobid} or _throw 'Missing jobid';
    my $status = $p{status} or _throw 'Missing status';
    my $job = ci->find( ns=>'job/'.$jobid );
    $job->status( $status );
    $job->save;
}

sub notify { #TODO : send to all action+ns users, send to project-team
    my ($self,%p) = @_;
    my $type = $p{type};
    my $jobid = $p{jobid} or _throw 'Missing jobid';
    my $job = Baseliner->model('Baseliner::BaliJob')->find( $jobid )
        or _throw "Job id $jobid not found";
    my $log = new BaselinerX::Job::Log({ jobid=>$jobid });
    my $status = $p{status} || $job->status || $type;
    my $mailcfg   = Baseliner->model('ConfigStore')->get( 'config.comm.email' );

    if( $job->step ne 'RUN' && $job->status !~ /ERROR|KILLED/ ) {
        $log->debug(_loc( "Notification skipped for job %1 step %2 status %3",
            $job->name,
            $job->step,
            $job->status ));
    }
    try {
        my $subject = _loc('Job %1: %2', $job->name, _loc($status) );
        my $last_log = $job->last_log_message;
        my $message = ref $last_log ? $last_log->{text} : _loc($type);
        my $username = $job->username;
        my $u = Baseliner->model('Users')->get( $username );
        my $realname = $u->{realname};
        $log->debug( _loc("Notifying user %1: %2", $username, $subject) );
        my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $jobid );
        Baseliner->model('Messaging')->notify(
            subject => $subject,
            message => $message,
            sender  => $mailcfg->{from},
            to => { users => [ $username ] },
            carrier =>'email',
            template => 'email/job.html',
            template_engine => 'mason',
            vars   => {
                action    => _loc($type), #started or finished
                job       => $job->name,
                message   => $message,  # last log msg
                realname  => $realname,
                status    => _loc($status),
                subject   => $subject,  # Job xxxx: (error|finished|started|cancelled...)
                to        => $username,
                username  => $username,
                url_log   => $url_log,
            }
            #cc => { actions=> ['action.notify.job.end'] },
        );
    } catch {
        my $err = shift;
        my $msg =  _loc( 'Error sending job notification: %1', $err );
        _log $msg;
        $log->warn( _loc("Failed to notify users"), data=> $msg );
    };
}

sub export {
    my ($self,%p) = @_;
    exists $p{mid} or _throw 'Missing job id';
    return eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 60;
        $p{format} ||= 'raw';
        my $job = ci->new( $p{mid} ) or _throw "Job id $p{id} not found";

        my $data = _dump({ job=>$job });
        alarm 0;
        return $data if $p{format} eq 'raw';
        return compress($data) if $p{format} eq 'zip';

        my $tar = Archive::Tar->new or _throw $!;
        # dump
        $tar->add_data( 'data.txt', $data );
        # job files
        my $name = $job->{name};
        my $inf = Baseliner->model('ConfigStore')->get( 'config.job.runner' );
        my $job_dir = File::Spec->catdir( $inf->{root}, $name );
        if( -e $job_dir ) {
            #$tar->setcwd( $inf->{root} );
            my @files;
            Path::Class::dir( $job_dir )->recurse(callback=>sub{
                my $f = shift;
                return if $f->is_dir;
                push @files, "" . $f->relative($inf->{root});
            });
            chdir $inf->{root};
            $tar->add_files( @files );
        }
        my $tmpfile = File::Spec->catdir( $inf->{root}, "job-export-$name.tgz" );
        return $tar->write unless $p{file};
        $tar->write($tmpfile,COMPRESS_GZIP);;
        return $tmpfile;
    };
    if( $@ eq "alarm\n" ) {
        _log "*** Job export timeout: $p{id}";
    }
    return undef;
}


sub log_this {
    my ($self,%p) = @_;
    $p{jobid} or _throw 'Missing jobid';
    my $args = { jobid=>$p{jobid} };
    $args->{exec} = $p{job_exec} if $p{job_exec} > 0;

    return new BaselinerX::Job::Log( $args );
}

sub get_contents {
    my ( $self, %p ) = @_;
    defined $p{jobid} or _throw "Missing jobid"; 
    my $result;

    my $job = _ci( ns=>'job/' . $p{jobid} );
    my $job_stash = $job->job_stash;
    my @changesets = _array( $job->changesets );
    my $changesets_by_project = {};
    my @natures = map { $_->name } _array( $job->natures );
    my $items = $job_stash->{items};
    for my $cs ( @changesets ) {
        my @projs = _array $cs->projects;
        push @{ $changesets_by_project->{$  projs[0]->{name}} }, $cs;
    }
    $result = {
        packages => $changesets_by_project,
        items => $items, 
        technologies => \@natures,
    };
    
    return $result;

} ## end sub get_contents

1;
