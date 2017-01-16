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
use Switch;

with 'Baseliner::Role::Service';


register 'config.daemon.purge' => {
    name     => _locl('Event daemon configuration'),
    metadata => [
        { id => 'sleep_period',    label => 'sleep period between checks', default => 3600 },
        { id => 'next_purge_date', label => 'Next date to execute purge' },
        { id => 'min_purge_time', default => '02:00', label => 'Minimum time in the day to execute the purge' },
        { id => 'max_purge_time', default => '04:00', label => 'Maximum time in the day to execute the purge' },
    ]
};


register 'config.purge' => {
    metadata => [
        { id => 'keep_job_files', default => 30, label=> _locl('Number of days to keep job files') },
        { id => 'keep_jobs_ok', default => 30, label=> _locl('Number of days to keep OK job logs') },
        { id => 'keep_jobs_ko', default => 30, label=> _locl('Number of days to keep KO job logs') },
        #{ id => 'keep_log_size', default => (1024*1024*4), label=> _locl('Max size in Bytes to keep logs') },   # 4MB to start with
        { id => 'keep_rotation_level', default => 7, label=> _locl('Number of compressed files  associated to a log file') },
        { id => 'keep_nginx-error_log_size', default => 4, label=> _locl('Max size in MBytes to keep nginx-error log') },
        { id => 'keep_nginx-access_log_size', default => 4, label=> _locl('Max size in MBytes to keep nginx-access log') },
        { id => 'keep_mongod_log_size', default => 4, label=> _locl('Max size in MBytes to keep mongod log') },
        { id => 'keep_redis_log_size', default => 4, label=> _locl('Max size in MBytes to keep redis log') },
        { id => 'keep_disp_log_size', default => 4, label=> _locl('Max size in MBytes to keep cla-disp log') },
        { id => 'keep_web_log_size', default => 4, label=> _locl('Max size in MBytes to keep cla-web log') },
        { id => 'no_file_purge', default =>'0', label=> _locl('Set this to true (1) to prevent Clarive from purging log files') },
        { id => 'no_job_purge', default =>'0', label=> _locl('Set this to true (1) to prevent Clarive from purging job logs') },
        { id => 'keep_sent_messages', default =>'30D', label=> _locl('Keep sent messages in duration format: 1M, 2D, etc.') },
        { id => 'event_log_keep', default =>'7D', label=> _locl('Keep event log entries for how long, in duration format: 1M, 2D, etc. Set to blank to stop this purge.') },
        { id => 'event_ko_purge', default =>'1', label=> _locl('Keep ko event log entries (0 or 1)') },
        { id => 'event_ok_purge', default =>'1', label=> _locl('Keep ok event log entries (0 or 1)') },
        { id => 'event_auth_purge', default =>'0', label=> _locl('Keep login event log entries (0 or 1)') },
    ]
};


register 'service.purge.daemon' => {
    daemon    => 1,
    name      => _locl('Purge Daemon'),
    icon      => '/static/images/icons/daemon.svg',
    scheduled => 1,
    config    => 'config.daemon.purge',
    handler   => sub {
        my ( $self, $c, $config ) = @_;

        require Baseliner::Sem;

        for ( 1 .. 1000 ) {
            _log( _loc("Checking purge daemon configuration") );

            if ( $self->time_to_run($config) ) {
                my $sem = Baseliner::Sem->new( key => 'purge_daemon', who => "purge_daemon", internal => 1 );

                $sem->take;

                $self->run_once();

                if ($sem) {
                    $sem->release;
                }

                my $tomorrow     = Class::Date->now() + "1D";
                my $config_store = Baseliner->model('ConfigStore')->new;

                $config_store->set(
                    key   => 'config.daemon.purge.next_purge_date',
                    value => $tomorrow->ymd,
                    bl    => '*'
                );
            }

            _log( _loc( "Sleeping for %1 seconds", $config->{sleep_period} ) );
            sleep( $config->{sleep_period} || 3600 );
        }
    }
};

register 'service.purge.run_once' => {
    handler => \&run_once,
};

sub time_to_run {
    my $self = shift;
    my ($config) = @_;

    my $today = Class::Date->now()->ymd;
    my $date = $config->{next_purge_date} || $today;

    if ( $date le $today ) {
        my $time = Class::Date->now()->hms;
        if ( $time gt $config->{min_purge_time} && $time lt $config->{max_purge_time} ) {
            return 1;
        }
        else {
            _log(
                _loc(
                    "Not purging now. Purging between %1 and %2", $config->{min_purge_time},
                    $config->{max_purge_time}
                )
            );
        }
    }
    else {
        _log( _loc( "Not purging until %1", $date ) );
    }

    return 0;
}

sub run_once {
    my ( $self, $c, $opts )=@_;
    $opts //= {};

    my %stats = ( grid => 0, job => 0, job_log => 0 );

    my $now = Util->_ts();
    my $config = BaselinerX::Type::Model::ConfigStore->new;
    my $config_runner = $config->get( 'config.job.runner');
    my $config_purge = $config->get( 'config.purge');
    my $job_home = ( $ENV{BASELINER_JOBHOME} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir()) . "/";
    my $logs_home = $ENV{BASELINER_LOGHOME};

    my $purge_job_available = !$config_purge->{no_job_purge} && (ref $config_runner && $job_home);
    if( $purge_job_available ) {
        my $jobs = ci->job->find({ purged => { '$ne' => '1'}})->fields({name=>1,endtime=>1,mid=>1,})->sort({_id=>1});
        while (my $job= $jobs->next){
            my $job_mid = $job->{mid};
            my $ci_job = try {
                ci->new($job_mid);
            } catch {
                _warn( "INVALID JOB = $job_mid" );
                undef;
            };
            next unless $ci_job;

            next if $ci_job->is_active;

            my $job_name = $job->{name};
            my $endtime = $job->{endtime};
            my $config = $config->get('config.purge', bl => $job->{bl});

            my $configdays = $ci_job->is_failed ? $config->{keep_jobs_ko} : $config->{keep_jobs_ok};
            _debug("Days to keep for ".$ci_job->bl.": ".$configdays);
            my $limitdate = $now - "${configdays}D";

            my $purged_job_path = $job_home."$job->{name}";
            my $purged_job_log_path = $logs_home."$job->{name}.log";
            my $max_job_time = Time::Piece->strptime($endtime, "%Y-%m-%d %H:%M:%S")
                            + ONE_DAY * $config->{keep_job_files};
            my $now_standard_date = $now =~ s/" "/T/g;

            if ( length $endtime && $endtime < $limitdate && !$job->{purged} ) {
                _log "Purging job $job_name with mid $job_mid ($endtime < $limitdate)....";

                try {
                    _log "Purging job $job_name with mid $job->{mid} ($endtime < $limitdate)....";

                    return if $opts->{dry_run};

                    _log "Deleting log $purged_job_log_path";
                    unlink $purged_job_log_path;

                    my $deleted_job_logs =
                      mdb->job_log->find( { mid => $job->{mid} } )
                      ->fields( { id => 1, mid => 1, data => 1, lev => 1, more => 1 } );

                    my $logs_deleted = 0;
                    while ( my $actual = $deleted_job_logs->next ) {
                        if ( $actual->{lev} eq 'debug' ) {
                            mdb->job_log->remove( { mid => $actual->{mid}, id => $actual->{id} } );
                            $logs_deleted++;
                        }

                        if ( $actual->{data} ) {
                            _log "Deleting field data of " . $job_mid . "....";
                            mdb->grid->delete( $actual->{data} );
                            $stats{grid}++;
                        }

                        if ( $actual->{more} && $actual->{more} eq 'jes' ) {
                            _log "Removing jes data of " . $job_mid . "....";
                            mdb->jes_log->remove( { id_log => 0 + $actual->{id} } );
                        }
                    }

                    $stats{job_log} += $logs_deleted;
                    $stats{job}++;

                    _log(_loc("Deleted %1 debug lines of job %2 ", $logs_deleted, $job->{name}));

                    $ci_job->update( purged=>'1' );
                } catch {
                    my $error = shift;

                    _log "Error trying to delete job $job_name. Job skipped: ".$error;
                };
            }

            if( $max_job_time->datetime lt $now_standard_date && -d $purged_job_path ) {
                _log "Deleting job directory $purged_job_path....";

                File::Path::remove_tree( $purged_job_path, {error => \my $err} );
                unlink $purged_job_path;
            }
        }
        ############## Control of logsize and old .gz ######################
        my $log_dir = Path::Class::dir( $logs_home );
        unless( $config_purge->{no_file_purge} || !$log_dir) {
            require Proc::Exists;
            _log "Analyzing logs....";
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

                    _log "Truncating: ".$file->basename;
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
                    _log "Done truncating: ".$file->basename;
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
    return \%stats;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
