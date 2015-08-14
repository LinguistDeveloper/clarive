package BaselinerX::Service::Purge;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Path::Class;
use Carp;
use Try::Tiny;
use File::Path;
use Time::Piece;
use Time::Seconds;
use File::Copy;
#use Baseliner::LogfileRotate;
use Switch;

with 'Baseliner::Role::Service';


register 'config.daemon.purge' => {
    name => 'Event daemon configuration',
    metadata => [
        { id=>'frequency', label=>'event purge daemon frequency (secs)', default=>86400 },    
    ]
};


register 'config.purge' => {
    metadata => [
        { id => 'keep_job_files', default => 30, label=> 'Number of days to keep job files' },
        { id => 'keep_jobs_ok', default => 30, label=> 'Number of days to keep OK job logs' },
        { id => 'keep_jobs_ko', default => 30, label=> 'Number of days to keep KO job logs' },
        #{ id => 'keep_log_size', default => (1024*1024*4), label=> 'Max size in Bytes to keep logs' },   # 4MB to start with
        { id => 'keep_rotation_level', default => 7, label=> 'Number of compressed files  associated to a log file' },
        { id => 'keep_nginx-error_log_size', default => 4, label=> 'Max size in MBytes to keep nginx-error log' },
        { id => 'keep_nginx-access_log_size', default => 4, label=> 'Max size in MBytes to keep nginx-access log' },
        { id => 'keep_mongod_log_size', default => 4, label=> 'Max size in MBytes to keep mongod log' },
        { id => 'keep_redis_log_size', default => 4, label=> 'Max size in MBytes to keep redis log' },
        { id => 'keep_disp_log_size', default => 4, label=> 'Max size in MBytes to keep cla-disp log' },
        { id => 'keep_web_log_size', default => 4, label=> 'Max size in MBytes to keep cla-web log' },
        { id => 'no_file_purge', default =>'0', label=> 'Set this to true (1) to prevent Clarive from purging log files' },
        { id => 'no_job_purge', default =>'0', label=> 'Set this to true (1) to prevent Clarive from purging job logs' },
        { id => 'keep_sent_messages', default =>'30D', label=> 'Keep sent messages in duration format: 1M, 2D, etc.' },
        { id => 'event_log_keep', default =>'7D', label=> 'Keep event log entries for how long, in duration format: 1M, 2D, etc. Set to blank to stop this purge.' },
        { id => 'event_ko_purge', default =>'1', label=> 'Keep ko event log entries (0 or 1)' },
        { id => 'event_ok_purge', default =>'1', label=> 'Keep ok event log entries (0 or 1)' },
        { id => 'event_auth_purge', default =>'0', label=> 'Keep login event log entries (0 or 1)' },
    ]
};


register 'service.purge.daemon' => {
    daemon => 1,
    name => 'Purge Daemon',
    icon => '/static/images/icons/daemon.gif',
    scheduled => 1,
    config => 'config.daemon.purge',
    handler => sub {
                    my ($self, $c, $config ) = @_;
                    $config->{frequency} ||= 86400;
                    require Baseliner::Sem;
                    for( 1..1000 ) {
                        my $sem = Baseliner::Sem->new( key=>'purge_daemon', who=>"purge_daemon", internal=>1 );
                        $sem->take;
                        $self->run_once();
                        if ( $sem ) {
                            $sem->release;
                        }
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
    my $config_purge = Baseliner->model('ConfigStore')->get( 'config.purge');
    my $job_home = $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir();
    $job_home = $job_home."/";
    my $logs_home = $ENV{CLARIVE_BASE}.'/logs/';
    $config_runner->{root} = $job_home;

    if( !$config_purge->{no_job_purge} && (ref $config_runner && $config_runner->{root}) ) {
        #_log "Config root: ". $config_runner->{root};
        my $jobs = ci->job->find({})->sort({ _id=>1 });
        while (my $job= $jobs->next){
            my $job_name = $job->{name};
            my $endtime = $job->{endtime};
            my $config = Baseliner->model('ConfigStore')->get('config.purge', bl => $job->{bl});
            my $ci_job = try {
                ci->new($job->{mid});
            } catch {
                _warn( "INVALID JOB=$job->{mid}" );
                undef;
            };
            next unless $ci_job;
            my $configdays = $ci_job->is_failed ? $config->{keep_jobs_ko} : $config->{keep_jobs_ok};
            my $limitdate = $now - "${configdays}D";
            # delete job directories
            my $purged_job_path = $job_home."$job->{name}";
            my $purged_job_log_path = $logs_home."$job->{name}.log";
            my $max_job_time = Time::Piece->strptime($endtime, "%Y-%m-%d %H:%M:%S");
            $max_job_time = $max_job_time + ONE_DAY * $config->{keep_job_files};
            my @temp = split( " ", $now );
            #_log "Condition to delete job_dir and job_log  ".$max_job_time->datetime."<------>$temp[0]T$temp[1]";
            if ( length $endtime && $endtime < $limitdate && !$job->{purged} ) {
                next if $ci_job->is_active;
                try {
                    _log "Purging job $job_name with mid $job->{mid} ($endtime < $limitdate)....";
                    $job_purge_count++;
                    $ci_job->update( purged=>1 );
                    next if $opts->{dry_run};              
                    # delete job logs
                    _log "\tDeleting log $purged_job_log_path"; 
                    unlink $purged_job_log_path;
                    my $deleted_job_logs = mdb->job_log->find({ mid => $job->{mid}, lev => 'debug' });
                    while( my $actual = $deleted_job_logs->next ) {
                        my $query = mdb->job_log->find_one({ mid => "$job->{mid}", data=>{'$exists'=> '1'} }); 
                        my $data;
                        mdb->job_log->remove({ mid => $actual->{mid} }) if $actual->{level} eq 'debug';
                        if(ref $query){
                            _log "\tDeleting field data of ".$job->{mid}."....";
                            $data = $query->{data};
                            mdb->grid->delete($data);
                        } else {
                            if ( $actual->{more} eq 'jes' ) {
                                _log "\tRemoving jes data of ".$job->{mid}."....";
                                mdb->jes_log->remove({ id_log => 0+$actual->{id}});
                            }
                        }
                    }
                } catch {
                    _log "Error trying to delete job $job_name. Job skipped: ".shift;
                }
            } elsif( !$job->{purged} ) {
                _log _loc('Job not ready to purge yet: %1 (%2)', $job_name, $job->{mid});
            }
            if( $max_job_time->datetime lt "$temp[0]T$temp[1]" && -d $purged_job_path ) {
                _log "\tDeleting job directory $purged_job_path....";
                File::Path::remove_tree( $purged_job_path, {error => \my $err} );
                unlink $purged_job_path;
            }
        }
        ############## Control of logsize and old .gz ######################
        my $log_dir = Path::Class::dir( $logs_home );
        unless( $config_purge->{no_file_purge} ) {
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

                    if( $file->basename =~ qr/^cla\-disp\-(.+)\.log$/ ){
                        next unless $filesize-1 > $config_purge->{keep_disp_log_size}*(1024*1024);
                    } elsif( $file->basename =~ qr/^cla\-web\-(.+)\.log$/ ){
                        next unless $filesize-1 > $config_purge->{keep_web_log_size}*(1024*1024);
                    } else {
                        next unless $filesize-1 > $config_purge->{"keep_".$filename."_log_size"}*(1024*1024);
                    }

                    #my $pid_file = Path::Class::file( $file->dir, "$filename.pid" );
                    #next unless -e $pid_file;
                    require Baseliner::LogfileRotate;
                    
                    _log "\tTruncating: ".$file->basename;
                    my $log = new Baseliner::LogfileRotate( File   => $file, 
                                    Count  => $config_purge->{keep_rotation_level},
                                    Gzip  => 'lib',
                                    # Post   => sub{
                                    #         if( $file->basename !~ qr/^cla\-disp\-(.+)\.log$/ ) {                                    
                                    #             my $pid = _file( $pid_file )->slurp;
                                    #             #open( my $opened_file, $pid_file );
                                    #             _log _loc("Restarting process ".$pid." for file ".$file->basename);
                                    #             kill( "HUP", $pid ); 
                                    #         }
                                    #     },
                                    Dir    => $file->dir,
                                    Flock  => 'yes',
                                    Persist => 'yes',
                                    );
                    $log->rotate();
                    _log "\tDone truncating: ".$file->basename;
                }
            }
        }
        
        ####################### purge old event_log

        ############################ PURGE OLD SENT MESSAGES ###########################################
        my $keep_sent_messages = $config_purge->{keep_sent_messages};
        my @old_messages = mdb->message->find({created=>{'$lt'=>''.(mdb->now()-$keep_sent_messages)}})->all;
        my @old_messages_ids = map {$_->{id}} @old_messages;
        mdb->message_queue->remove({id_message=>{'$in'=>\@old_messages_ids}});
        mdb->message->remove({id=>{'$in'=>\@old_messages_ids}});


        ############################ DELETE SPECIFICATIONS OF RELEASES ###########################################
        _rmpath(_dir(_tmp_dir(),'downloads'));
    }
    
    my $event_log_keep = $config_purge->{event_log_keep};
    my $event_ok_purge = $config_purge->{event_ok_purge};
    my $event_ko_purge = $config_purge->{event_ok_purge};
    my $event_auth_purge = $config_purge->{event_auth_purge};

    if ( $event_ok_purge || $event_ko_purge || $event_auth_purge ) {
        if( length $event_log_keep ) { 
            _log "Purging events";

            if ( $event_ok_purge ) {
                _log "Purging ok events";
                my @events_ok = map { $_->{id} } mdb->event->find(
                    {   event_status => 'ok',
                        ts           => { '$lt' => '' . ( mdb->now() - $event_log_keep )},
                        event_key    => { '$nin' => [qr/event\.auth/]}
                    }
                )->all;
                _log _loc("Purging %1 auth events",scalar @events_ok);
                mdb->event->remove({ id=>mdb->in(@events_ok)}, { multiple=>1 });
                mdb->event_log->remove({ id_event=>mdb->in(@events_ok)}, { multiple=>1 });
            }
            if ( $event_ko_purge ) {
                _log "Purging ko events";
                my @events_ko = map { $_->{id} } mdb->event->find(
                    {   event_status => 'ko',
                        ts           => { '$lt' => '' . ( mdb->now() - $event_log_keep )},
                        event_key    => { '$nin' => [qr/event\.auth/]}
                    }
                )->all;
                _log _loc("Purging %1 ko events",scalar @events_ko);
                mdb->event->remove({ id=>mdb->in(@events_ko)}, { multiple=>1 });
                mdb->event_log->remove({ id_event=>mdb->in(@events_ko)}, { multiple=>1 });
            }
            if ( $event_auth_purge ) {
                my @events_auth = map { $_->{id} } mdb->event->find( 
                    {   ts           => { '$lt' => '' . ( mdb->now() - $event_log_keep )},
                        event_key    => qr/event\.auth/
                    }
                )->all;
                _log _loc("Purging %1 auth events",scalar @events_auth);
                mdb->event->remove({ id=>mdb->in(@events_auth)}, { multiple=>1 });
                mdb->event_log->remove({ id_event=>mdb->in(@events_auth)}, { multiple=>1 });
            }
        }
    }
    _log 'Done purging.';
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
