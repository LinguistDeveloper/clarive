package BaselinerX::Service::ManualDeploy;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
with 'Baseliner::Role::Service';

=head1 DESCRIPTION

The Manual Deploy service stops jobs until a manual intervention
is done by the user.

=cut

=pod
register 'config.manual_deploy' => {
    name => 'Manual Deploy Configuration',
    metadata => [
        { id=>'paths', label=>'Sed map array of hashes', type=>'eval', default=>q[[
              {  path=>'/FILES/', text=>"Manual deploy of general files", action=>'action.manual.approve.files' } ,
              {  path=>'/ORACLE/', text=>"Manual deploy of oracle files", action=>'action.manual.approve.oracle' } 
              ]
            ]
        },
    ]
};
=cut

register 'config.manualdeploy.reply' => {
    name => 'ManualDeploy reply Daemon configuration',
    metadata => [
        { id=>'frequency', name=>'Email daemon frequency', default=>10 },
        { id=>'active', name=>'Approvals activation flag', default=>0 }
    ]
};

register 'catalog.type.manual_deploy' => {
    name        => 'Manual Deployment',
    description => 'Deploy Files Manually by manual intervention',
    url         => '/manualdeploy/configure',
    #list        => sub { [ { ns=>'/', bl=>'*', for=>
};

# [path], desc, action

register 'action.manualdeploy.role' => {
    name => 'Manual deployment finished'
};


register 'service.manual_deploy.request' => {
    name => 'Check and Send Requests for Manual Deployments',
    config=> 'config.manual_deploy',
    handler => \&send_requests 
};

register 'service.manual_deploy.reply' => {
    name => 'Check Replies for Manual Deployments',
    config=> 'config.manualdeploy.reply',
    handler => \&reply_daemon 
};

register 'service.manual_deploy' => {
    name => 'Job Service for Manual Deployments',
    config=> 'config.manual_deploy',
    handler => \&run_and_suspend,
};

register 'service.manual_deploy.check' => {
    name => 'Job Service for Manual Deployments',
    config=> 'config.manualdeploy.reply',
    handler => \&check_paths 
};

sub run_and_suspend {
    my ($self,$c,$config) =@_;

    my $job = $c->stash->{job};
    my $log = $job->logger;
    $log->info( _loc('Starting service Manual Deploy') );

    my $elements = $job->job_stash->{elements};
    unless( ref $elements ) {
        $log->debug( _loc('No elements loaded in path') );
        return 0; 
    }
    for my $path ( _array $config->{paths} ) {
        $elements = $elements->cut_to_subset( 'nature', $path );
        $self->process_path( elements=>$elements, path=>$path );
    }
    #$job->pause( timeout=>20, reason=>_loc('Manual deployment'), callback=>sub{} );
    $job->suspend;

    $log->info( _loc('Manual Deploy service finished.' ));
    return 1;
}

sub check_paths {
    my ($self,$c,$config) =@_;
    my $job = $c->stash->{job};
    my $job_stash = $job->job_stash;
    my $log = $job->logger;

    $log->debug( _loc('Checking Manual Deploy Paths'));

    my @mapping;
    my $elements = $job->job_stash->{elements};
    my %actions;
    my $rs = kv->find( provider=>'manual_deploy' );
    while( my $r = $rs->next ) {
        my $data = $r->kv;
        next unless $data->{bl} eq '*' || $data->{bl} eq $job->bl;
        push @mapping, $data;
        my $paths = $data->{paths};
        for my $path ( split /,/, $paths ) {
            $log->debug( _loc("Processing path %1, action %2", $path, $data->{action} ) ); 
            # if( $elements
            my @checked;
            _log "Checking regex started...";
            my @elements = grep {
                push @checked, "Checking " . $_ . " =~ $path";
                $_ =~ $path
            } map { $_->filepath if $_->action eq 'write' } _array( $elements->elements );
            # _log "Checking regex finished. " . join "\n", @checked;
            if( @elements ) {
                my $key = $data->{action} ;
                push @{ $actions{ $key }{path} }, $path;
                push @{ $actions{ $key }{elements} }, @elements;
                $actions{$key}{data} = $data;
                # publish file to log
                my @files;
                for my $elem ( @elements ) {
                    my $file = _file( $job->root, $elem );
                    next if $file->is_dir;
                    next if -d "$file";
                    if( -e "$file" ) {
                        push @files, "$file";
                        $log->debug( _loc("File <code>%1</code> zipped for manual deploy", "$file" ), data=> $file );
                    } else {
                        $log->info( _loc("Could not find file <code>%1</code> for manual deploy", "$file" ),
                            data=>"$file" );
                    }
                }
                # publish zip
                if( @files ) {
                    my $zip = zip_files(
                        prefix => $job->name,
                        files  => \@files,
                        base   => $job->root
                    );
                    my $zipname = $data->{name} . '_' . $job->name . '.zip';
                    $zipname =~ s{ }{_}g;
                    $log->info(
                        _loc( "Publishing file %1 for manual deploy", "<b><code>$zipname</code></b>" ),
                        data      => _slurp( $zip ),
                        more      => 'zip',
                        data_name => $zipname
                    );
                }
            }
        }
        #$elements = $elements->cut_to_subset( 'nature', $path );
        #$self->process_path( elements=>$elements, path=>$path );
    }
    $log->debug( _loc('Paths'), data=>_dump( \@mapping ) );
    if( %actions ) {
        $log->debug( _loc('Actions detected in manual deploy'), data=>_dump(\%actions) );
        $job->stash( manual_deploy_actions => \%actions );
    } else {
        $log->debug( _loc('No actions detected for manual deploy') );
    }
    return %actions; 
}

sub send_requests {
    my ($self,$c,$config) =@_;

    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $bl = $job->bl;
    my $rfcs = join (', ',_unique map {$_->{rfc}} _array $job->job_stash->{contents});
    my $apps = join (', ',_unique map { my ($a,$b)=ns_split($_->{application}); $b} _array $job->job_stash->{contents});
    my $comment = $job->job_data->{comments};
    my %actions = $self->check_paths( $c, $config );
    
    my $scheduled_actions = undef;
    
    #análisis de impacto de las aprobaciones, para un pase con más de una
    for ( keys %actions ) {
        $scheduled_actions.= qq{<ul>};
        $scheduled_actions.= qq{<li><b>$actions{$_}->{data}->{name}</b><br>};
        $scheduled_actions.= qq{$actions{$_}->{data}->{description}<br>};
        $scheduled_actions.= qq{<b>Rol de los aprobadores</b><br>};
        my $roles = $c->model('Baseliner::BaliRole')->search({ id=> { -in => $actions{$_}->{data}->{role} } });
        $scheduled_actions.= qq{<ul>};
        while (my $role = $roles->next){
            $scheduled_actions.= qq{<li>}. $role->name .qq{</li>};
        }
        $scheduled_actions.= qq{</ul>};
        $scheduled_actions.= qq{<b>Elementos a tratar:</b><br>};
        $scheduled_actions.= qq{<ul>};
        foreach (_array $actions{$_}->{elements}) {
            $scheduled_actions.= qq{<li>$_</li>};
        }
        $scheduled_actions.= qq{</ul>};
        $scheduled_actions.= qq{</li>};
        $scheduled_actions.= qq{</ul>};
    }
    _log "\n$scheduled_actions";    
        
    for my $key ( keys %actions ) {
        my $action = $actions{ $key };
        my $name = $action->{data}{name} || $key;
        my $desc = $action->{data}{description};
        my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d&annotate_now=1", _notify_address(), $job->jobid ); 
        my $url_job = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $job->jobid ); 
        my $reason = _loc('Manual deploy action: %1', $name);
        my $subject = _loc('Requesting manual deploy for job %1, baseline %2: %3', $job->name , $bl, '<b>' . $reason . '</b>');
        $log->info( $subject );
        my @users = Baseliner->model('Permissions')->list(action => $action, ns => '/', bl => '*');
        my $to = [ _unique(@users) ];

        try {
            Baseliner->model('Request')->request(
                name            => _loc( "Manual Deploy for %1", $job->name ),
                action          => $key,
                item            => $name,
                template        => '/email/approval_manual.html',
                template_engine => 'mason',
                username        => $job->job_data->{username},
                comments_job    => $job->job_data->{comments},
                ns              => 'job/'. $job->name,
                bl              => $bl,
                id_job          => $job->jobid,
                vars            => {
                    scheduled_actions  => $scheduled_actions,
                    statename  => $job->bl,
                    jobname  => $job->name,
                    to       => $to,
                    url_log  => $url_log,
                    url      => _notify_address(),
                    reason   => $reason,
                    comments => _textile( $desc ),
                },
                data         => {
                        rfc     => $rfcs,
                        project => $apps, #FIXME not used, could be the harvest project though
                        app     => $apps,
                        comment => $comment,
                        ts      => _now(),
                }
            );
            my $job_row = $c->model('Baseliner::BaliJob')->find({ id=>$job->jobid });
            $log->debug( _loc('Changing status to %1', 'APPROVAL' ) );
            $job->status('APPROVAL');
        } catch {
            my $e = shift;
            $log->info( _loc("Error while trying to create request: %1", "$e" ) );
        };
    }
}

sub process_path {
    my ( $self, %p ) = @_;

    # find who to notify

    # send notifications

    # notify pause in log, with special button for continuation

    # pause job status
}

sub reply_daemon {
    my ( $self, $c, $config ) = @_;
_debug _dump $config;   
    my $frequency = $config->{frequency};
    my $dbh = Baseliner::Core::DBI->new({ model=>'Baseliner' });
    _log "Starting manual deploy reply daemon with frequency ${frequency}s";
    for( 1..200 ) {
        $self->reply( $dbh );
        sleep $frequency;
    }
    $dbh->disconnect;
    _log 'Manual deploy reply daemon.';
}

sub reply {
    my ( $self, $dbh ) = @_;

    return unless $dbh;
    my $query = qq{
        SELECT BRQ.ID_JOB, BRQ.ID, BRQ.ACTION, BRQ.STATUS, BRQ.FINISHED_BY FROM 
        BALI_REPO BR, BALI_REPOKEYS BRK, BALI_REQUEST BRQ
        WHERE 1=1
          AND BR.NS LIKE 'manual_deploy/%'
          AND BR.NS = BRK.NS
          AND BRK.K = 'action'
          AND DBMS_LOB.SUBSTR( BRK.V, 255, 1 ) = BRQ.ACTION
          AND BRQ.STATUS NOT IN ('cancelled', 'pending') 
        };
    my %values= $dbh->hash( $query);
    foreach my $id_job (keys %values) {
        my ($id_req, $action, $status, $user) = @{$values{$id_job}};
        my $job = Baseliner->model('Baseliner::BaliJob')->search({ id=>$id_job })->first;
        my $request = Baseliner->model('Baseliner::BaliRequest')->search({ "me.id"=>$id_req}, { prefetch=>['my_comment'] })->first;
        my $stash = _load $job->stash;
        $status = _loc($status);
        my $manual_deploy = $stash->{manual_deploy_actions};
        my $subject = "Pase $status";
        my $url_job = sprintf( "%s/tab/job/log/list?id_job=%d", _notify_address(), $id_job );
        my $comment = 'Sin comentarios';
        try{$comment = $request->my_comment->text;}catch{};
        foreach (keys %$manual_deploy){
            next if $$manual_deploy{$_}->{notified};
            next if $_ eq $action;  ## Si fuera necesario notificar a la propia acción, quitar esto

            #_log "notificar pase $id_job $status a ". $_;
            my $msg = Baseliner->model('Messaging')->notify(
                    subject  => $subject,
                    sender   => _loc('Approvals'),
                    to       => { action=> $_ },
                    carrier  => 'email',
                    template => 'email/approval_reply.html',
                    vars     => {
                        status        => $status,
                        username      => $user,
                        subject       => $subject,
                        jobname       => $job->name,
                        url_job       => $url_job,
                        comment       => $comment,
                        template      => 'email/approval_reply.html',
                    }
                );

            $$manual_deploy{$_}->{notified}=1;
            $stash->{manual_deploy_actions}=$manual_deploy;
            $job->stash(_dump $stash);
        }
    }
}

1;
