package BaselinerX::Job::Service::Clearstep;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Carp;
use Try::Tiny;

use utf8;

with 'Baseliner::Role::Service';

register 'service.job.clearstep' => { name => 'Job step cleanup',
    config => 'config.job.runner', handler => \&clear_step, };

our %next_step = ( PRE => 'RUN',   RUN => 'POST',  POST => 'END' );
our %next_state  = ( PRE => 'READY', RUN => 'READY', POST => 'FINISHED' );

# executes jobs sent by the daemon in an independent process

sub clear_step {
    my ($self,$c,$config)=@_;
    
    my $job = $c->stash->{job};
    my $log = $job->logger;

    $log->debug( 'Finalizando STEP ' . $job->job_stash->{step} );
}

1;
