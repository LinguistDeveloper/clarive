package BaselinerX::Service::Purge;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
use Carp;
use Try::Tiny;
use File::Path;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.purge.files' => {
    name => 'Purge job directories',
    scheduled => 1,
    frequency_key => 'config.job.purge.files.frequency',
    config => 'config.job',
    handler => \&run,
};

sub run {
    my ($self,$c,$config)=@_;
    my $log = $self->log;

    my $now = DateTime->now;
    $now->set_time_zone(_tz);
     my $days = $config->{keep_log_days} || 7;

    _log "Starting job directory purge. Days to keep: $days";
    my $duration = DateTime::Duration->new( days=> $days );

    my $config_runner = Baseliner->model('ConfigStore')->get( 'config.job.runner');
    if( ref $config_runner && $config_runner->{root} ) {
        _log "Config root: ". $config_runner->{root};
        my @dirs = grep { $_->is_dir } Path::Class::dir( $config_runner->{root} )->children;
        foreach my $job_dir ( @dirs ) {
            my $job_name = $job_dir->relative( $job_dir->parent )->stringify;
            my $job = $c->model('Jobs')->get( $job_name );
            next unless ref $job;
            $log->debug( "Checking if $job_name is running...");
            next unless $job->is_not_running;
            $log->debug( "Ok. Not runnning." );
            # check max time
            my $time = $job->endtime || $job->starttime;
            $log->debug( "Job $job_name last activity time: " . $time );
            next if ref $time eq 'DateTime' && DateTime::Duration->compare( $now - $time, $duration ) <= 0;
            # delete it
            $log->info( "Deleting job directory tree for $job_name: '$job_dir'");
            File::Path::remove_tree( $job_dir, {error => \my $err} ); 
            unlink $job_dir;
            $log->info( "$job_name directories deleted" );
        }
    }
    $log->info( "Done purging job directories." );
}

1;
