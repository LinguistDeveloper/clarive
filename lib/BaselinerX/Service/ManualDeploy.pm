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

register 'catalog.type.manual_deploy' => {
    name        => 'Manual Deployment',
    description => 'Deploy Files Manually by manual intervention',
    url         => '/manualdeploy/configure',
    #list        => sub { [ { ns=>'/', bl=>'*', for=>
};

# [path], desc, action

# register 'action.manual.

register 'service.manual_deploy.request' => {
    name => 'Check and Send Requests for Manual Deployments',
    config=> 'config.manual_deploy',
    handler => \&send_requests 
};

register 'service.manual_deploy' => {
    name => 'Job Service for Manual Deployments',
    config=> 'config.manual_deploy',
    handler => \&run_and_suspend,
};

register 'service.manual_deploy.check' => {
    name => 'Job Service for Manual Deployments',
    config=> 'config.manual_deploy',
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

    $log->debug( _loc('Checking Manual Deploy Paths') );

    my @mapping;
    my $elements = $job->job_stash->{elements};
    my %actions;
    my $rs = kv->find( provider=>'manual_deploy' );
    while( my $r = $rs->next ) {
        my $data = $r->kv;
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
            } map { $_->filepath } _array( $elements->elements );
            _log "Checking regex finished. " . join "\n", @checked;
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
                        $log->debug( _loc("File <code>%1</code> zipped for manual deploy", "$file" ) );
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
                    my $zipname = $job->name . '_manualdeploy.zip';
                    $log->info(
                        _loc( "Publishing file %1 for manual deploy", "<b><code>$zipname</code></b>" ),
                        data      => _slurp( $zip ),
                        more      => 'zip',
                        data_name => $zipname,
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
    my %actions = $self->check_paths( $c, $config );
    for my $key ( keys %actions ) {
        my $action = $actions{ $key };
        my $name = $action->{data}{name} || $key;
        my $desc = $action->{data}{description};
        my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d&annotate_now=1", _notify_address(), $job->jobid ); 
        my $reason = _loc('Manual deploy action: %1', $name);
        $log->info( _loc('Requesting manual deploy for job %1, baseline %2: %3', $job->name , $bl, '<b>' . $reason . '</b>') );
        try {
            Baseliner->model('Request')->request(
                name            => _loc( "Manual Deploy for %1", $job->name ),
                action          => $key,
                item            => $name,
                template        => '/email/approval_manual.html',
                template_engine => 'mason',
                username        => $job->job_data->{username},
                comments_job    => $job->job_data->{comments},
                ns              => '/',
                bl              => $bl,
                id_job          => $job->jobid,
                vars            => {
                    jobname  => $job->name,
                    url_log  => $url_log,
                    reason   => $reason,
                    comments => _textile( $desc ),
                },
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


1;
