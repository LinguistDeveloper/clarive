package BaselinerX::Type::Model::Services;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use Try::Tiny;
use Carp;
use Baseliner::Utils;
use Baseliner::Core::Registry;

sub search_for {
    my ($self, %p) = @_;
    my @services = Baseliner::Core::Registry->search_for(key=>'service.', %p );
    return @services;
}

sub launch {
    my ($self, $service_name, %p ) = @_;
    my $c = $p{c};
    my $ns = $p{ns} || '/';
    my $bl = $p{bl} || '*';
    my $data = $p{data} || {};
    my $service = Baseliner::Core::Registry->find($service_name) || Baseliner::Core::Registry->find("service.$service_name") || die "Could not find service '$service_name'\n";

    # load the service's config data
    my $config_name = $service->config;
    my $config_data;
    if( defined $config_name ) {
        $config_data = Baseliner->model('ConfigStore')->get( $config_name, ns=>$ns, bl=>$bl, data=>$data );
    } else {
        $config_data = $data;
    }
    #_log 'CONFIG ' . _dump $config_data;
    defined $p{quiet} and $service->quiet( $p{quiet} );

    # create the job environment for the service
    if( $p{'job-continue'} ) {  # creates a new job exec
        $c->stash->{job} ||= $self->job_continue( jobid=>$p{'job-continue'}, exec=>$p{'job-exec'}, service_name=>$service_name );
        _log "Job continue ok." . $c->stash->{job};
    } elsif( $p{'job-new'} ) { # creates a new job
        $c->stash->{job} ||= $self->job_new( $p{'job-new'} );
    } elsif( $p{'job-clone'} ) { # new job from a cloned row
        $c->stash->{job} ||= $self->job_clone( $p{'job-clone'} );
    } elsif( ref $p{logger} ) {
        $service->logger( $p{logger} );
    } else {
        # just give him a logger
        $p{logger_class} and $service->logger_class( $p{logger_class} );
    }

    #
    # put logfile in the stash
    #
    if( defined $data->{logfile} && length $data->{logfile} ) {
        _log _loc "Service logfile '%1'", $data->{logfile};
        $c->stash->{logfile} = $data->{logfile};
    }
    
    # maybe we have an object that should be the main instance
    $config_data->{obj} = $p{obj} if ref $p{obj};

    #
    # ******************** RUN *****************
    # 
    _debug "Running service $service_name...";
    my $ret;
    if( $p{capture} ) {
        require Capture::Tiny;
        my ($output) = Capture::Tiny::tee_merged(sub {
            $ret = $service->run( $c, $config_data );
        });
        utf8::downgrade( $output );
        $service->logger->console( $output );
    } else {
        $ret = $service->run( $c, $config_data );
    }
    _debug "Done running service $service_name";

    # save stash at the end -- default: no
    ref $c->stash->{job}
    && ( exists $p{'stash-save'} || exists $p{'save-stash'} )
    and try {
        _log "Saving job stash...";
        $c->stash->{job}->freeze;
    } catch {
        _log "Warning: Could not freeze stash"
    };
    return $ret;
}

sub job_continue {
    my ($self,%p)=@_;
    return BaselinerX::Service::Runner->new_from_id( jobid=>$p{jobid}, exec=>$p{exec}, service_name=>$p{service_name} );
}

sub job_clone {
    my ($self,$jobid)=@_;
    _throw 'Not implemented yet';
    #return BaselinerX::Service::Runner->clone_from_id( jobid=>$jobid );
}

sub job_new {
    my ($self, %p)=@_;
    _throw 'Not implemented yet';
}

# print usage info for all services
sub usage {
    my $self = shift;
    my $RET="";
    foreach my $service ( keys %{ $self->services } ) {
        $RET.= $service."\n";
        if ( ref $self->services->{$service}->{config} ) {
            my $config = $self->services->{$service}->{config};
            my $task = join ' ', map { "-".join '=', split /\|/, $_ } map { $config->{task}{$_}{opt} } keys %{$config->{task}};
            $RET .= "\tbali $service ".$task." ".$config->{cmd}{line}."\n";
            $RET .= "\t".$config->{cmd}{desc}."\n";
        }
        else {
            $RET .= $self->services->{$service}->{usage}."\n";
            $RET .= $self->services->{$service}->{description}."\n";
        }
    }
    $RET =~ s/\n\n/\n/g; ## cleanup
    return $RET;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
