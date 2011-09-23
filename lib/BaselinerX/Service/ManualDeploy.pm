package BaselinerX::Service::ManualDeploy;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
with 'Baseliner::Role::Service';
with 'Baseliner::Role::Catalog';

=head1 DESCRIPTION

The Manual Deploy service stops jobs until a manual intervention
is done by the user.

=cut

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

register 'catalog.type.manual_deploy' => {
    name        => 'Manual Deployment',
    description => 'Deploy Files Manually by manual intervention',
    url         => '/manualdeploy/configure',
    #list        => sub { [ { ns=>'/', bl=>'*', for=>
};

# [path], desc, action

# register 'action.manual.

register 'service.manual_deploy' => {
    name => 'Job Service for Manual Deployments',
    config=> 'config.manual_deploy',
    handler => \&run 
};

sub run {
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
    my $paths = $config->{paths} ;

    $log->debug( _loc('Checking Manual Deploy Paths') );
    $log->debug( _loc('Paths'), data=>_dump( $paths ) );

    my $elements = $job->job_stash->{elements};
    my %actions;
    my $rs = kv->find( provider=>'manual_deploy' );
    for my $pe ( _array $paths ) {
        $log->debug( _loc("Processing path %1, action %2", $pe->{path}, $pe->{action} ) ); 
        # if( $elements
        my @elements = grep { $_->{path} =~ $pe->{path} } _array($elements->elements);
        if( @elements ) {
            my $key = $pe->{action} ;
            push @{ $actions{ $key }{path} }, $pe->{path};
            push @{ $actions{ $key }{elements} }, @elements;
            $actions{$key}{desc} = $pe->{text};
        }
        #$elements = $elements->cut_to_subset( 'nature', $path );
        #$self->process_path( elements=>$elements, path=>$path );
    }
    $log->debug( _loc('Actions detected in manual deploy'), data=>_dump(\%actions) );
    return %actions; 
}

register 'service.manual_deploy.request' => {
    name => 'Send Requests Manual Deployments',
    config=> 'config.manual_deploy',
    handler => \&send_requests 
};

sub send_requests {
    my ($self,$c,$config) =@_;

    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $bl = $job->bl;
    my %actions = $self->check_paths( $c, $config );
    for my $key ( keys %actions ) {
        my $action = $actions{ $key };
        my $name = $actions{$key}{name} || $key;
        my $desc = $actions{$key}{text};
        my $url_log = sprintf( "%s/tab/job/log/list?id_job=%d&annotate_now=1", _notify_address(), $job->jobid ); 
        my $reason = _loc('Manual deploy action: %1', $name);
        $log->info( _loc('Requesting manual deploy for job %1, baseline %2: %3', $job->name, $bl, $reason ) );
        try {
            Baseliner->model('Request')->request(
                name            => _loc( "Manual step for %1", $job->name ),
                action          => $key,
                template        => '/email/approval_manual.html',
                template_engine => 'mason',
                username        => $job->job_data->{username},
                comments_job    => $job->job_data->{comments},
                ns              => 'job/' . $job->name,
                bl              => $bl,
                id_job          => $job->jobid,
                vars            => {
                    jobname  => $job->name,
                    url_log  => $url_log,
                    reason   => $reason,
                    comments => $desc,
                },
            );
            my $job_row = $c->model('Baseliner::BaliJob')->find({ id=>$job->jobid });
            $log->debug( _loc('Changing status to %1', 'APPROVAL' ) );
            $job->status('APPROVAL');
        } catch {
            my $e = shift;
            $log->info( _loc("Job '%1' does not need approval (there are no approval users available)", $job->name ) );
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

# catalog role methods 

sub catalog_add { }
sub catalog_icon { '/static/images/icons/manual_deploy.gif' }
sub catalog_del { 
    my ($class, %p)=@_;
    $p{id} or _throw 'Missing id';
    kv->delete( ns=>$p{id} );
}
sub catalog_url { '/comp/catalog/manual_deploy.js' }
sub catalog_list { 
    my ($class, %p)=@_;
    my @list;
    my $rs = kv->find( provider=>'manual_deploy' );
    while( my $r = $rs->next ) {
        my $d = $r->kv;
        push @list, {
            row        =>  { $r->get_columns, %$d },
            name        => $d->{name}, 
            description => $d->{description}, 
            id          => $r->ns,
            for         =>{ paths=>$d->{paths} },
            mapping     => { action=>$d->{action}  },
        };
    }
    return wantarray ? @list : \@list;
}
sub catalog_name { 'Manual Deployment' }
sub catalog_description { 'Deploy Files Manually by manual intervention' }


1;
