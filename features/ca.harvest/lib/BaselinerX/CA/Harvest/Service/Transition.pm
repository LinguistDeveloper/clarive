package BaselinerX::CA::Harvest::Service::Transition;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

use utf8;

with 'Baseliner::Role::Service';

register 'service.harvest.transition' => {
	name => 'Transition Packages from one state to another',
	handler => \&run,
};

register 'config.harvest.transition.states' => {
    metadata => [
        { id=>'bl_to_state', label=>_loc('Baseline to State'), type=>'hash', }, 
        { id=>'promote', label=>_loc('Promote States'), type=>'hash' },   #TODO 'text' no, 'commas'
        { id=>'demote', label=>_loc('Demote States'), type=>'hash' },   #TODO 'text' no, 'commas'
    ]
};

has 'transition_type' => ( is=>'rw', isa=>'Str' );

sub run {
	my ($self, $c, $p ) = @_;

	my $job = $c->stash->{job};
	my $log = $job->logger;

	my $bl = $job->bl;
	my $job_type = $job->job_type;

	if( $job->rollback ) {
		$self->transition_type( $job_type eq 'promote' ? 'demote' : 'promote' );
	}
	elsif( $job_type =~ m/promote|demote/ )  {
		$self->transition_type( $job_type );
	}

	unless( $self->transition_type ) {
		$log->debug( _loc('No transition for job type "%1"', $job_type ) );
		return;
	}

	my $contents = $job->job_stash->{contents};
	my $inf = $c->model('ConfigStore')->get('config.harvest.transition.states', ns=>'/', bl=>$job->bl );
	my $inf_cli = Baseliner->model('ConfigStore')->get('config.ca.harvest.cli', ns=>'/', bl=>$job->bl );

	# get packages to transition and group
	my %packages; 
	if( $job->rollback ) {
		my $pkgs = $job->job_stash->{rollback}->{transition}->{packages}; 
		unless( ref $pkgs ) {
			$job->logger->info( _loc('No transition harvest packages detected. Skipping') );
			return;
		} 
		%packages = %{ $pkgs };	
	} else {
		foreach my $job_item ( _array $contents ) {
			#my $data = YAML::Load( $job_item->{data} );
			my $item = $job_item->{item};
			my $ns_package = $c->model('Namespaces')->get( $item ); 
			next unless ref $ns_package;
			next unless $ns_package->isa('BaselinerX::CA::Harvest::Namespace::Package');

			# group packages by application:state
			my $env = $ns_package->environmentname;
			my $state = $ns_package->state; 
			my $key = "$env-$state";
			$log->debug( _loc('Aplicacion:Estado %1 para el paquete %2', $key, $ns_package->ns_data->{packagename} ) );
			$packages{$key}{env} = $env;
			$packages{$key}{state} = $state;
			push @{ $packages{$key}{packages} }, $ns_package->ns_data->{packagename};
		}
	}
	$log->debug('Agrupacion de paquetes por aplicacion', data=>_dump \%packages );

	my $to_state;
	ref $job->job_stash->{harvest_data} and $to_state = $job->job_stash->{harvest_data}->{to_state};

	# for each promotion group...
	foreach my $key ( keys %packages ) {
		my ($env, $state ) = ( $packages{ $key }{env}, $packages{ $key }{state} );
		my @env_packages = _array $packages{ $key }{packages};
		my $env_packages = join ',', @env_packages;

		# get variables from previous run
		if( $job->rollback ) {
			$state = $job->job_stash->{rollback}->{transition}->{to_state}->{$key};
			$to_state = $job->job_stash->{rollback}->{transition}->{state}->{$key};
			$log->debug( "Rollback set from_state=" . $state .", to_state=" . $to_state );
		} else {
			# find to_state in case the job_stash doesn't have it
			$to_state ||= $self->find_to_state( project=>$env, state=>$state, bl=>$bl, config=>$inf );
		}

		# make sure there's a to_state
		$to_state or _throw _loc('No to_state found in the job stash or in config.ca.harvest.map for baseline %1 and job type %2. Harvest package transition cancelled.', $bl, $job_type);

		# skip if from and to states are the same
		if( $state eq $to_state ) {
			$log->debug( _loc("From state '%1' and to state '%2' are the same. Promote/demote skipped", $state, $to_state) );
			next;
		}

        Encode::_utf8_on($to_state);
        Encode::_utf8_on($state); 

		my $verb = $self->transition_type eq 'promote' ? 'Promoting' : 'Demoting';
		$log->info( _loc('%1 packages %2 from state %3 to state %4 in project %5', _loc_unaccented($verb), $env_packages, $state, $to_state, $env) ); 	

		my $ret;
		my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$inf_cli->{broker}, login=>$inf_cli->{login} });
		try {
			# decide if it's a promote or demote depending on to_state or state
			my ( $process_name, $type ) = $self->find_process( project=>$env, state=>$state, to_state=>$to_state)
				or _throw _loc('Could not find a Harvest process to promote/demote from state "%1"', $state );

			$log->debug( _loc('Found "%1" process name "%2"', $type, $process_name ) );

			# transition
			$ret = $cli->transition( cmd=>$type, project=>$env, process=>$process_name, state=>$state, packages=>[ @env_packages ] );
		} catch {
			my $err = shift;
			$log->debug( _loc("No process found, using failback default promote: %1", $err) );
			$ret = $cli->transition( cmd=>$self->transition_type, project=>$env, state=>$state, packages=>[ @env_packages ] );
		};
		
		# now store it for a possible rollback
		unless( $job->rollback) {
			$job->job_stash->{rollback}->{transition}->{packages}->{$key} = $packages{$key};
			$job->job_stash->{rollback}->{transition}->{state}->{$key} = $state;
			$job->job_stash->{rollback}->{transition}->{to_state}->{$key} = $to_state;
		}

		# publish log
		$log->info( _loc('Harvest %1 results (rc=%2)', _loc_unaccented($verb), $ret->{rc} ), data=>$ret->{msg} );

        # update releases status
        Baseliner->model('Releases')->update_bl;
	}
}

sub find_to_state {
	my ($self, %p ) = @_;
	my $project = $p{project};
	my $bl = $p{bl};
	my $state = $p{state};
	my $to_state;
    my $key = 'config.harvest.transition.states'; 
	my $config = $p{config}
		|| Baseliner->model('ConfigStore')->get(ns=>'/', bl=>$bl );
	try {
		my $env = Baseliner->model('Harvest::Harenvironment')->search({ environmentname=>$project })->first or _throw "Harvest Project '$project' not found";
		my $eid = $env->envobjid; 
		my $trans = $config->{ $self->transition_type() } or _throw _loc("Transition system not configured for type '%1'. Check config key '%2'", $self->transition_type, $key );
		my $candidates = $trans->{$bl};
		for my $state ( _array $candidates ) {
			my $row = Baseliner->model('Harvest::Harstate')->search({ statename=>$state, envobjid=>$eid })->first;
			if( ref $row ) {  # this candidate state exists in this project
				$to_state = $state;
				last;
			}
		}
	} catch {
		my $err = shift;
		_log "Error while finding to_state: " . $err;
	};
	return $to_state;
}

sub find_process {
	my ($self, %p ) = @_;
	my $project = $p{project};
	my $state = $p{state};
	my $to_state = $p{to_state};
	my $env_row = Baseliner->model('Harvest::Harenvironment')->search({ environmentname=>$project })->first;
	ref $env_row or _throw _loc 'Could not find Harvest project "%1"', $project;
	my $eid = $env_row->envobjid;
	my $state_row = Baseliner->model('Harvest::Harstate')->search({ envobjid=>$eid, statename=>$state })->first;
	ref $state_row or _throw _loc 'Could not find Harvest state "%1"', $state;
	my $state_id = $state_row->stateobjid;
	my $to_state_row = Baseliner->model('Harvest::Harstate')->search({ envobjid=>$eid, statename=>$to_state })->first;
	ref $to_state_row or _throw _loc 'Could not find Harvest state "%1"', $to_state;
	my $to_state_id = $to_state_row->stateobjid;
	
	my $proc = Baseliner->model('Harvest::Harpromoteproc')->search({ stateobjid=>$state_id, tostateid=>$to_state_id })->first;
	if( ref $proc ) {
		return ( $proc->processname, 'promote' );
	}
	
	$proc = Baseliner->model('Harvest::Hardemoteproc')->search({ stateobjid=>$state_id, tostateid=>$to_state_id })->first;
	ref $proc or _throw _loc 'Could not find a promote/demote process in Harvest';
	return ( $proc->processname, 'demote' );
}

1;
