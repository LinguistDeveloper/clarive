package BaselinerX::Job::Service::SingleService;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.runner.single' => { name => 'Single Service Job Runner', config => 'config.job', handler => \&job_single, };

# run a single service for job
sub job_single {
    my ($self,$c, $config)=@_;

    _check_parameters( $config, qw/service/ );   

    my $job = $c->stash->{job};
    my $log = $job->logger;

    $log->debug('Iniciando Single Service Run PID=' . $job->job_data->{pid} );

    my $service_key = $config->{service};
    _throw "Missing service name" unless $service_key;

        try {
            $log->debug( _loc('Starting chained service %1' , $service_key ) );
            $c->launch( $service_key );
            $log->debug( _loc('Finished chained service %1' , $service_key ) );

        } catch {
            my $error = shift;
            $log->error( _loc('Error while running chained service %1: %2' , $service_key, $error ) ); 
            _throw $error;
        };
}

# never break the Chain!

1;

