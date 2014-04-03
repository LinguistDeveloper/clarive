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

with 'Baseliner::Role::Service';


register 'config.daemon.purge' => {
    name => 'Event daemon configuration',
    metadata => [
        { id=>'frequency', label=>'event puge daemon frequency (secs)', default=>86400 },    
    ]
};


register 'config.purge' => {
    metadata => [
        { id => 'keep_log_files', default => 30, name=> 'Number of days to keep /log files' },
        { id => 'keep_job_files', default => 30, name=> 'Number of days to keep job files' },
        { id => 'keep_jobs_ok', default => 30, name=> 'Number of days to keep OK job logs' },
        { id => 'keep_jobs_ko', default => 30, name=> 'Number of days to keep KO job logs' },
        #{ id => 'keep_log_lines', default => 500, name=> 'Number of lines that logs can store' },
        { id => 'keep_log_size', default => (1024*1024*4), name=> 'Max size in Bytes to keep logs' },   # 4MB to start with
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

# sub truncate_log {
#     my @p = @_;
#     my $filename = $p[0];
#     my $numlines  = $p[1];
#     my $byte;
#     open FILE, "<$filename" or die "Couldn't open $filename: $!";
#     seek FILE,-1, 2;
#     my $count=0;
#      while (1){
#        seek FILE,-1,1;
#        read FILE,$byte,1;
#        if(ord($byte) == 10 ){
#         $count++;
#         if($count == $numlines){last}
#        }
#        seek FILE,-1,1;
#      if (tell FILE == 0){last}
#     }
#     $/=undef;
#     my $tail = <FILE>;
#     close(FILE);
#     open FILE, ">>$filename"."_new" or die "Couldn't open $filename"."_new: $!";
#     print FILE "$tail\n";
#     close (FILE);
#     unlink $filename;
#     move("$filename"."_new","$filename");
# }



sub truncate_log {
    my @p = @_;
    my $filename = $p[0];
    my $filesize  = $p[1];
    # Open the file in read mode 
    open FILE, "<$filename" or die "Couldn't open $filename: $!";
    seek FILE,0, 2; 
    seek FILE,-$filesize,2;
    $/=undef;
    my $tail = <FILE>;
    close(FILE);
    open FILE, ">>$filename"."_new" or die "Couldn't open $filename"."_new: $!";
    print FILE "$tail\n";
    close (FILE);
    unlink $filename;
    move("$filename"."_new","$filename");
}


sub run_once {
    my ( $self )=@_;
    my $now = mdb->ts;
    my $config_runner = Baseliner->model('ConfigStore')->get( 'config.job.runner');
    my $job_home = $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir();
    $job_home = $job_home."/";
    my $logs_home = $ENV{CLARIVE_BASE}.'/logs/';
    $config_runner->{root} = $job_home;
    #my @purged_jobs=[];
    if( ref $config_runner && $config_runner->{root} ) {
        #_log "Config root: ". $config_runner->{root};
        my $jobs = ci->job->find({});
        while (my $job= $jobs->next){
            my $job_name = $job->{name};
            #next unless $job->{status} ne 'is_not_running';
            my $config = Baseliner->model('ConfigStore')->get('config.purge', bl => $job->{bl});
            my $endtime = $job->{endtime};
            #_log $endtime."<----->".$now;
            if ( $endtime lt $now and !$job->{purged} ) {
                my $ci_job = ci->new($job->{mid});
                next if $ci_job->is_active;
                _log "Purging job $job_name with mid ".$job->{mid}."....";
                $ci_job->purged(1);
                $ci_job->save;
                #push(@purged_jobs, $job->{name});
                #_log "Purging $job_name ===mid===> ".$job->{mid};
                my $deleted_job_logs = mdb->job_log->find({ mid => $job->{mid}, lev => 'debug' });
                while( my $actual = $deleted_job_logs->next ) {
                    my $query = mdb->job_log->find_one({ mid => "$job->{mid}", data=>{'$exists'=>'1'} }); 
                    my $data;
                    mdb->job_log->remove({ mid => $actual->{mid} });
                    if(ref $query){
                        _log "\tDeleting field data of ".$job->{mid}."....";
                        $data = $query->{data};
                        mdb->grid->delete($data);
                    }
                }
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
            }
        }

        ############## Control of logsize and old .gz ######################
        my $log_dir = Path::Class::dir( $logs_home );
        my $config_files = Baseliner->model('ConfigStore')->get( 'config.purge');
        require Proc::Exists;
        _log "\n\n\nAnalyzing logs....";
        while (my $file = $log_dir->next) {
            next unless -f $file;
            my @parts = split('\\.', $file->basename);
            if ( $file->basename =~ /\w*\.log\.\d{4}_\d{2}_\d{2}T\d{2}_\d{2}_\d{2}\.gz$/ ){
                my $date_time = $parts[-2];
                #_log $date_time;
                my $original_time = Time::Piece->strptime($date_time, "%Y_%m_%dT%H_%M_%S");
                my $days = $config_files->{keep_log_files};
                my $time_to_remove = $original_time + ONE_DAY * $days;
                my @temp = split( " ", $now );
                #_log $time_to_remove->datetime." <----> ". "$temp[0]T$temp[1]";
                if ( $time_to_remove->datetime lt "$temp[0]T$temp[1]" ){
                    _log "\tDeleting old GZ file ".$file->basename."....";
                    unlink $file;
                }
            }
            if ( $file->basename =~ /(?<filename>.+)\.log$/ ){
                my $filename = $+{filename};
                my $filesize = -s $file;
                next unless $filesize-1 > $config_files->{keep_log_size};
                next if ci->job->find_one({ name=>$filename });
                _log _loc 'Found log file %1 (filename=%2)', $file, $filename;
                next if $self->pid_file_and_process($file->dir, $filename);
                #my $job_name = (split( '\\.', $file->basename ))[0];
                #my $job = ci->job->find({name => $job_name})->next;
                #my $config = Baseliner->model('ConfigStore')->get('config.purge', bl => $job->{bl});
                _log "\tTruncate log ".$file->basename." ($filesize > $config_files->{keep_log_size})...";
                truncate_log( $file, $config_files->{keep_log_size} );
                _log "\tDone truncating: ".$file->basename;
            }
        }
    }
    _log 'Done purging.';
    #_log _dump @purged_jobs;
}

sub pid_file_and_process {
    my ($self, $dir, $filename)=@_;
    my $pid_file = Path::Class::file( $dir, "$filename.pid" ); 
    return 1 if $filename =~ /nginx|mongod|redis/;  # do not purge these
    _log _loc 'Checking pid file %1', $pid_file;
    return unless -e $pid_file;
    my $pid = $pid_file->slurp;
    $pid =~ s{[^0-9]}{}g;
    _log _loc 'Checking that pid %1 exists', $pid;
    require Proc::Exists;
    my $ex =  Proc::Exists::pexists( $pid );
    _log _loc 'Pid %1 exists=%2', $pid, $ex?'YES':'NO';
    return $ex;
}

1;
