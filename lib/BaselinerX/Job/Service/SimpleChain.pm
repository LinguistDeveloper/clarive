package BaselinerX::Job::Service::SimpleChain;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.runner.simple.chain' => { name => 'Simple Chain Job Runner', config => 'config.job', handler => \&job_simple_chain, };

has 'job_log' => is=>'rw', isa=>'Any';

# process the chained services 
sub job_simple_chain {
	my ($self,$c, $config)=@_;

	my $job = $c->stash->{job};
	my $log = $job->logger;
    $self->job_log( $log );

    my $step = $job->step;
    _throw "Missing job chain step" unless $step;

    $log->debug( _loc('Starting Simple Chain Runner, STEP=%1, PID=%2', $step, $job->job_data->{pid} ) );

    my $chain = $job->job_stash->{chain};
    if( !ref($chain) || $chain->step ne $step ) {
        # reload chain 1) first time 2) job changed steps
        $chain = $self->init_chain( chain_id=>1, step=>$step, job=>$job ); #FIXME needs to get the current job chain, not 1
	}
    $log->debug( _loc('Current execution chain'), data=>_dump($chain->services) ) if defined $chain;

	while(1) {
		my $service_desc;
        #eval {

		# always get the latest from the stash, in case it has changed
		my $chain = $job->job_stash->{chain};

        my $continue = try {
			# get the next service in the chain
			my $service = $chain->next_service or last;
			$service_desc = $service->{name} || $service->{key};

            $log->debug( _loc("Starting chained service '%1' for step %2" , $service_desc, $step ) );
            $c->launch( $service->{key} );
            if( $job->status eq 'SUSPENDED' ) {
                return 0;
            }
            $log->debug( _loc("Finished chained service '%1' for step %2" , $service_desc, $step ) );
            return 1;
		} catch {
			my $error = shift;
			if( $error =~ m/^Could not find key/ ) {  #TODO should throw-catch an exception class type
				$log->warn( _loc("Warning while running chained service '%1' for step %2: %3" , $service_desc, $step, $error ) ); 
			} else {
            $log->error( _loc("Error while running chained service '%1' for step %2: %3" , $service_desc, $step, $error ) ); 
			_throw $error;
			}
            return 1;
		};

        # suspended? 
        last unless $continue;

		# are there more services to run?
		last if $chain->done;
    }
}

sub init_chain {
    my ($self, %p) = @_;
    my $chain_id = $p{chain_id} or _throw 'Missing chain_id';
    my $step     = $p{step} or _throw 'Missing step';
    my $job      = $p{job} or _throw 'Missing job object';
    my $chain_row = Baseliner->model('Baseliner::BaliChain')->search({ id=> $chain_id })->first;
    _throw _loc( 'Missing default job chain id %1', $chain_id ) unless ref $chain_row;
    my $chain_name = $chain_row->name;
    my $rs_chain = Baseliner->model('Baseliner::BaliChainedService')->search(
        { step=>$step, chain_id=>$chain_row->id, active=>'1' },
        { order_by=>'seq' }
    );
    my @chained_services;

    while( my $service = $rs_chain->next ) {
        push @chained_services, { $service->get_columns } ;
	}

    my $chain_obj = new BaselinerX::Job::Chain( 
        services => [ @chained_services ],
        step => $step,
        current_index => 0,
        chain => { $chain_row->get_columns },
        id => $chain_id,
    );

    $job->job_stash->{chain} = $chain_obj;
    $self->job_log->debug( _loc('Chain %1 loaded', $chain_name ), data=>_dump $chain_obj );
    return $chain_obj;
}

# never break the Chain!

1;
