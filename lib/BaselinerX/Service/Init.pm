package BaselinerX::Service::Init;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Carp;
use Try::Tiny;
use File::Spec;
use File::Path qw/mkpath remove_tree/;

use utf8;

with 'Baseliner::Role::Service';

register 'service.job.init' => { 
    name => 'Init Job Home',
    job_service  => 1,
    handler => \&job_init, 
};

sub job_init {
    my ($self,$c,$config)=@_;
    
    my $job = $c->stash->{job};
    my $log = $job->logger;
    my $job_dir = $job->job_dir;
    
    $log->debug( _loc( 'Creating job home: %1', $job_dir ) );
    if( -e $job_dir ) {
        if( length $job_dir > 5 ) {
            remove_tree $job_dir, { keep_root=>1 };
            $log->debug( _loc( "Job home '%1' reset clean", $job_dir ) );
        } else {
            $log->warn( _loc('Job dir too short, not removed for safety: %1', $job_dir) );
        }
    } else {
        my $err;
        mkpath $job_dir, { error=>\$err };
        if( @$err ) {
            _fail( _log( 'Error creating job home `%1`: %2', %{ $err->[0] || {} } ) );
        } else {
            $log->debug( _loc( "Job home '%1' created", $job_dir ) );
        }
    }
    
    return { init=>1, job_dir=>$job_dir };
}

1;
