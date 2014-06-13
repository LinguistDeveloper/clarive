package BaselinerX::Service::Purge;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
use Carp;
use Try::Tiny;
use File::Path;
use utf8;
use Time::Piece;
use Time::Seconds;
use File::Copy;
#use Baseliner::LogfileRotate;
use Switch;

with 'Baseliner::Role::Service';


register 'config.daemon.purge' => {
    name => 'Event daemon configuration',
    metadata => [
        { id=>'frequency', label=>'event puge daemon frequency (secs)', default=>86400 },    
    ]
};


register 'config.purge' => {
    metadata => [
        #{ id => 'keep_log_files', default => 30, name=> 'Number of days to keep /log files' },
        { id => 'keep_job_files', default => 30, name=> 'Number of days to keep job files' },
        { id => 'keep_jobs_ok', default => 30, name=> 'Number of days to keep OK job logs' },
        { id => 'keep_jobs_ko', default => 30, name=> 'Number of days to keep KO job logs' },
        #{ id => 'keep_log_size', default => (1024*1024*4), name=> 'Max size in Bytes to keep logs' },   # 4MB to start with
        { id => 'keep_rotation_level', default => 7, name=> 'Number of compressed files  associated to a log file' },
        { id => 'keep_nginx-error_log_size', default => 4, name=> 'Max size in MBytes to keep nginx-error log' },
        { id => 'keep_nginx-access_log_size', default => 4, name=> 'Max size in MBytes to keep nginx-access log' },
        { id => 'keep_mongod_log_size', default => 4, name=> 'Max size in MBytes to keep mongod log' },
        { id => 'keep_redis_log_size', default => 4, name=> 'Max size in MBytes to keep redis log' },
        { id => 'keep_disp_log_size', default => 4, name=> 'Max size in MBytes to keep cla-disp log' },
        { id => 'keep_web_log_size', default => 4, name=> 'Max size in MBytes to keep cla-web log' },
    ]
};


register 'service.purge.daemon' => {
    daemon => 1,
    name => 'Purge Daemon',
    scheduled => 1,
    config => 'config.daemon.purge',
    handler => sub {
                    my ($self, $c, $config ) = @_;
                    $config->{frequency} ||= 86400;
                    for( 1..1000 ) {
                        $self->run_once();
                        sleep( $config->{frequency} );
                    }
                }
};

register 'service.purge.run_once' => {
    handler => \&run_once,
};


sub run_once {
    my ( $self, $c, $opts )=@_;
    $opts //= {};
    my $now = Util->_ts(); # Class::Date->now object
    my $job_purge_count = 0;
    my $config_runner = Baseliner->model('ConfigStore')->get( 'config.job.runner');
    my $job_home = $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir();
    $job_home = $job_home."/";
    my $logs_home = $ENV{CLARIVE_BASE}.'/logs/';
    $config_runner->{root} = $job_home;
    #my @purged_jobs=[];
    if( ref $config_runner && $config_runner->{root} ) {
        #_log "Config root: ". $config_runner->{root};
        my $jobs = ci->job->find({})->sort({ _id=>1 });
        while (my $job= $jobs->next){
            my $job_name = $job->{name};
            my $endtime = $job->{endtime};
            my $config = Baseliner->model('ConfigStore')->get('config.purge', bl => $job->{bl});
            my $ci_job = ci->new($job->{mid});
            my $configdays = $ci_job->is_failed ? $config->{keep_jobs_ko} : $config->{keep_jobs_ok};
            my $limitdate = $now - "${configdays}D";
            if ( length $endtime && $endtime < $limitdate && !$job->{purged} ) {
                next if $ci_job->is_active;
                _log "Purging job $job_name with mid $job->{mid} ($endtime < $limitdate)....";
                $job_purge_count++;
                $ci_job->update( purged=>1 );
                next if $opts->{dry_run};              
                # delete job logs
                my $deleted_job_logs = mdb->job_log->find({ mid => $job->{mid}, lev => 'debug' });
                while( my $actual = $deleted_job_logs->next ) {
                    my $query = mdb->job_log->find_one({ mid => "$job->{mid}", data=>{'$exists'=> '1'} }); 
                    my $data;
                    mdb->job_log->remove({ mid => $actual->{mid} });
                    if(ref $query){
                        _log "\tDeleting field data of ".$job->{mid}."....";
                        $data = $query->{data};
                        mdb->grid->delete($data);
                    }
                }
                # delete job directories
                my $purged_job_path = $job_home."$job->{name}";
                my $purged_job_log_path = $logs_home."$job->{name}.log";
                my $max_job_time = Time::Piece->strptime($endtime, "%Y-%m-%d %H:%M:%S");
                $max_job_time = $max_job_time + ONE_DAY * $config->{keep_job_files};
                my @temp = split( " ", $now );
                #_log "Condition to delete job_dir and job_log  ".$max_job_time->datetime."<------>$temp[0]T$temp[1]";
                if( $max_job_time->datetime lt "$temp[0]T$temp[1]" ) {
                    _log "\tDeleting log $purged_job_log_path"; 
                    unlink $purged_job_log_path;
                    _log "\tDeleting job directory $purged_job_path....";
                    File::Path::remove_tree( $purged_job_path, {error => \my $err} );
                    unlink $purged_job_path;
                }
            } elsif( !$job->{purged} ) {
                _log _loc 'Job not ready to purge yet: %1 (%2): %3', $job_name, $job->{mid}, "$endtime >= $limitdate";
            }
        }
        ############## Control of logsize and old .gz ######################
        my $log_dir = Path::Class::dir( $logs_home );
        my $config_files = Baseliner->model('ConfigStore')->get( 'config.purge');
        require Proc::Exists;
        _log "\n\n\nAnalyzing logs....";
        while (my $file = $log_dir->next) {
            next unless -f $file;
            if ( $file->basename =~ /(?<filename>.+)\.log$/ ){
                my $filename = $+{filename};
                my $filesize = -s $file;
                my @particular_logs = ("nginx-error.log", "nginx-access.log", "redis.log", "mongod.log");
                if ( $file->basename =~ qr/^cla\-web\-(.+)\.log$/ or $file->basename =~ qr/^cla\-disp\-(.+)\.log$/ ) {
                    push( @particular_logs, $file->basename );
                }
                next unless grep { $_ eq $file->basename } @particular_logs;
                #switch ($file->basename) {
                #    case qr/^cla\-disp\-(.+)\.log$/  { next unless $filesize-1 > $config_files->{keep_disp_log_size}; }
                #    case qr/^cla\-web\-(.+)\.log$/ { next unless $filesize-1 > $config_files->{keep_web_log_size};  }
                #    else { next unless $filesize-1 > $config_files->{"keep_".$filename."_log_size"}; }
                #}
                if( $file->basename =~ qr/^cla\-disp\-(.+)\.log$/ ){
                    next unless $filesize-1 > $config_files->{keep_disp_log_size}*(1024*1024);
                } elsif( $file->basename =~ qr/^cla\-web\-(.+)\.log$/ ){
                    next unless $filesize-1 > $config_files->{keep_web_log_size}*(1024*1024);
                } else {
                    next unless $filesize-1 > $config_files->{"keep_".$filename."_log_size"}*(1024*1024);
                }
                # PID location
                #my $pid_file;
                #if($file->basename eq "mongod.log"){ 
                #    $pid_file = Path::Class::file( $file->dir."/data/mongo/", "mongod.pid" ); 
                #}else{
                #    $pid_file = Path::Class::file( $file->dir, "$filename.pid" );
                #}
                my $pid_file = Path::Class::file( $file->dir, "$filename.pid" );
                next unless -e $pid_file;
                require Baseliner::LogfileRotate;
                my $log = new Baseliner::LogfileRotate( File   => $file, 
                                Count  => $config_files->{keep_rotation_level},
                                Gzip  => 'lib',
                                Post   => sub{
                                    open( my $opened_file, $pid_file );
                                    kill( "HUP", chomp( $opened_file ) ); 
                                    },
                                Dir    => $file->dir,
                                Flock  => 'yes',
                                Persist => 'yes',
                                );
                $log->rotate();
                _log "\tDone truncating: ".$file->basename;
            }
        }
    }
    _log 'Done purging.';
}


1;
