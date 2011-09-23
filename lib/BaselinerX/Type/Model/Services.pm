package BaselinerX::Type::Model::Services;
use Moose;
extends qw/Catalyst::Model/;
use Try::Tiny;
use Baseliner::Utils;
use Carp;
use namespace::autoclean;

sub search_for {
    my ($self, %p) = @_;
    my $c = Baseliner->app;
    my @services = $c->model('Registry')->search_for(key=>'service.', %p );
    return @services;
}

sub launch {
    my ($self, $service_name, %p ) = @_;
    my $c = $p{c} || Baseliner->app;
    my $ns = $p{ns} || '/';
    my $bl = $p{bl} || '*';
    my $data = $p{data} || {};
    my $service = $c->registry->get($service_name) || die "Could not find service '$service_name'";

    # load the service's config data
	my $config_name = $service->config;
    my $config_data;
    if( defined $config_name ) {
		#my $config = $c->registry->get( $service->config ) if( $service->config );
        #$config_data = $config->factory( $c, ns=>$ns, bl=>$bl, getopt=>1, data=>$data );
        #$config_data = $config->factory( $c, ns=>$ns, bl=>$bl, data=>$data );
        $config_data = Baseliner->model('ConfigStore')->get( $config_name, ns=>$ns, bl=>$bl, data=>$data );
    } else {
		$config_data = $data;
	}
	#_log 'CONFIG ' . _dump $config_data;
	defined $p{quiet} and $service->quiet( $p{quiet} );

	# create the job environment for the service
	if( $p{'job-continue'} ) {  # creates a new job exec
		$c->stash->{job} ||= $self->job_continue( jobid=>$p{'job-continue'}, exec=>$p{'job-exec'} );
		_log "Job continue ok." . $c->stash->{job};
	} elsif( $p{'job-new'} ) { # creates a new job
		$c->stash->{job} ||= $self->job_new( $p{'job-new'} );
	} elsif( $p{'job-clone'} ) { # new job from a cloned row
		$c->stash->{job} ||= $self->job_clone( $p{'job-clone'} );
	} else {
		# just give him a logger
		$p{logger_class} and $service->logger_class( $p{logger_class} );
	}
    #
    # ******************** RUN *****************
    # 
    my $ret = $service->run( $c, $config_data );

    # save stash at the end -- default: no
    ref $c->{stash}->{job} && exists $p{'stash-save'} and try {
        _log "Saving job stash...";
        $c->{stash}->{job}->freeze;
    } catch {
        _log "Warning: Could not freeze stash"
    };
    return $ret;
}

sub job_continue {
	my ($self,%p)=@_;
	return BaselinerX::Job::Service::Runner->new_from_id( jobid=>$p{jobid}, exec=>$p{'job-exec'} );
}

sub job_clone {
	my ($self,$jobid)=@_;
	_throw 'Not implemented yet';
	#return BaselinerX::Job::Service::Runner->clone_from_id( jobid=>$jobid );
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


1;
