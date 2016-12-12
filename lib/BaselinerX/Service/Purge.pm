package BaselinerX::Service::Purge;
use Moose;

use Path::Class;
use Carp;
use Try::Tiny;
use File::Path;
use Time::Piece;
use Time::Seconds qw(ONE_DAY);
use File::Copy;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sem;

with 'Baseliner::Role::Service';

has 'file_size_factor', is => 'ro', isa => 'Int', default => sub { 1024 * 1024 };


register 'config.daemon.purge' => {
    name     => _locl('Event daemon configuration'),
    metadata => [
        { id => 'sleep_period',    label => 'Sleep period between checks', default => 3600 },
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
    daemon => 1,
    name => _locl('Purge Daemon'),
    icon => '/static/images/icons/service-purge-daemon.svg',
    scheduled => 1,
    config    => 'config.daemon.purge',
    handler => \&daemon_handler
};

register 'service.purge.run_once' => {
    handler => \&run_once,
};

sub daemon_handler {
    my ( $self, $c, $config ) = @_;

    for ( 1 .. 1000 ) {
        _log( _loc("Checking purge daemon configuration") );

        $self->daemon_run_once( $c, $config );

        _log( _loc( "Sleeping for %1 seconds", $config->{sleep_period} ) );
        sleep( $config->{sleep_period} || 3600 );
    }

    return $self;
}

sub daemon_run_once {
    my $self = shift;
    my ($c, $config) = @_;

    my $config_store = BaselinerX::Type::Model::ConfigStore->new;
    $config = $config_store->get( 'config.daemon.purge' );

    return unless $self->time_to_run($config);

    my $sem = Baseliner::Sem->new( key => 'purge_daemon', who => "purge_daemon", internal => 1 );

    $sem->take;

    $self->run_once($c, $config);

    if ($sem) {
        $sem->release;
    }

    my $tomorrow = Class::Date->now() + "1D";

    $config_store->set(
        key   => 'config.daemon.purge.next_purge_date',
        value => $tomorrow->ymd,
        bl    => '*'
    );

    return $self;
}

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

    my $config = BaselinerX::Type::Model::ConfigStore->new;

    my @to_purge = qw(jobs logs events messages);

    my @stats;
    foreach my $to_purge (@to_purge) {
        my $method = "purge_$to_purge";
        my $stats = $self->$method($opts, $config);

        foreach my $key (sort(keys %$stats)) {
            push @stats, "$key=$stats->{$key}";
        }
    }

    _rmpath( _dir( _tmp_dir(), 'downloads' ) );

    _log 'Done purging ' . join( ', ', @stats );

    return;
}

sub purge_jobs {
    my $self = shift;
    my ($opts, $config) = @_;

    my %stats;

    my $now = Util->_ts();

    return {} if $config->get('config.purge')->{no_job_purge};

    _log "Purging jobs logs and files";

    my $jobs = ci->job->find(
        {
            purged => { '$ne'  => '1' },
            status => { '$nin' => [ BaselinerX::CI::job->running_statuses ] },
        }
      )->fields(
        {
            bl      => 1,
            logfile => 1,
            job_dir => 1,
            name    => 1,
            endtime => 1,
            mid     => 1,
        }
      )->sort( { _id => 1 } );

    while ( my $job = $jobs->next ) {
        my $job_mid = $job->{mid};

        my $ci_job = try {
            ci->new($job_mid);
        } catch {
            _warn( "INVALID JOB = $job_mid" );
            undef;
        };
        next unless $ci_job;

        my $job_name = $job->{name};
        my $endtime = $job->{endtime};
        my $config_purge = $config->get('config.purge', bl => $job->{bl});

        my $configdays = $ci_job->is_failed ? $config_purge->{keep_jobs_ko} : $config_purge->{keep_jobs_ok};
        next unless $configdays;

        my $limitdate = $now - "${configdays}D";

        if ( length $endtime && $endtime < $limitdate ) {
            _log "Purging job $job_name with mid $job_mid ($endtime < $limitdate)....";

            next if $opts->{dry_run};

            try {
                my $job_log_file = $job->{logfile};
                if ( -f $job_log_file ) {
                    _log "Deleting log $job_log_file";
                    unlink $job_log_file;

                    $stats{job_log_file}++;
                }

                my $job_logs_to_delete =
                  mdb->job_log->find( { mid => $job->{mid} } )
                  ->fields( { id => 1, mid => 1, data => 1, lev => 1, more => 1 } );

                while ( my $log = $job_logs_to_delete->next ) {
                    if ( $log->{lev} eq 'debug' ) {
                        mdb->job_log->remove( { _id => $log->{_id} } );

                        $stats{job_log}++;
                    }

                    if ( $log->{data} ) {
                        mdb->grid->delete( $log->{data} );
                        mdb->job_log->update( { _id => $log->{_id} }, { '$unset' => { 'data' => 1 } } );

                        $stats{job_log_grid}++;
                    }

                    if ( $log->{more} && $log->{more} eq 'jes' ) {
                        _log "Removing jes data of " . $job_mid . "....";

                        mdb->jes_log->remove( { id_log => 0 + $log->{id} } );

                        $stats{job_log_jes}++;
                    }
                }

                $ci_job->update( purged=>'1' );
            } catch {
                my $error = shift;

                _log "Error trying to delete job $job_name. Job skipped: ".$error;
            };
        }

        my $max_job_time =
          Time::Piece->strptime( $endtime, "%Y-%m-%d %H:%M:%S" ) + ONE_DAY * $config_purge->{keep_job_files};
        $max_job_time = $max_job_time->datetime;
        $max_job_time =~ s{T}{ };

        my $job_dir = $job->{job_dir};
        if ( $max_job_time lt $now && -d $job_dir ) {
            _log "Deleting job directory $job_dir....";

            File::Path::remove_tree( $job_dir, { error => \my $err } );
            unlink $job_dir;

            $stats{job_dir}++;
        }
    }

    return \%stats;
}

sub purge_events {
    my $self = shift;
    my ($opts, $config) = @_;

    my %stats;

    my $config_purge = $config->get('config.purge');

    my $event_log_keep   = $config_purge->{event_log_keep};
    my $event_ok_purge   = $config_purge->{event_ok_purge};
    my $event_ko_purge   = $config_purge->{event_ok_purge};
    my $event_auth_purge = $config_purge->{event_auth_purge};

    return {} unless ( $event_ok_purge || $event_ko_purge || $event_auth_purge ) && $event_log_keep;

    my $min_ts = '' . ( mdb->now() - $event_log_keep );

    _log "Purging events";

    if ( $event_ok_purge ) {
        my @events_ok = map { $_->{id} } mdb->event->find(
            {   event_status => 'ok',
                ts           => { '$lt' => $min_ts },
                event_key    => { '$nin' => [qr/event\.auth/]}
            }
        )->fields({id => 1})->all;

        if (@events_ok) {
            _log _loc("Purging %1 ok events",scalar @events_ok);

            mdb->event->remove({ id=>mdb->in(@events_ok)}, { multiple=>1 });
            mdb->event_log->remove({ id_event=>mdb->in(@events_ok)}, { multiple=>1 });

            $stats{events_ok} += @events_ok;
        }
    }

    if ( $event_ko_purge ) {
        my @events_ko = map { $_->{id} } mdb->event->find(
            {   event_status => 'ko',
                ts           => { '$lt' => $min_ts },
                event_key    => { '$nin' => [qr/event\.auth/]}
            }
        )->fields({id => 1})->all;

        if (@events_ko) {
            _log _loc("Purging %1 ko events",scalar @events_ko);

            mdb->event->remove({ id=>mdb->in(@events_ko)}, { multiple=>1 });
            mdb->event_log->remove({ id_event=>mdb->in(@events_ko)}, { multiple=>1 });

            $stats{events_ko} += @events_ko;
        }
    }

    if ( $event_auth_purge ) {
        my @events_auth = map { $_->{id} } mdb->event->find(
            {   ts           => { '$lt' => $min_ts },
                event_key    => qr/event\.auth/
            }
        )->fields({id => 1})->all;

        if (@events_auth) {
            _log _loc("Purging %1 auth events",scalar @events_auth);

            mdb->event->remove({ id=>mdb->in(@events_auth)}, { multiple=>1 });
            mdb->event_log->remove({ id_event=>mdb->in(@events_auth)}, { multiple=>1 });

            $stats{events_auth} += @events_auth;
        }
    }

    return \%stats;
}

sub purge_logs {
    my $self = shift;
    my ($opts, $config) = @_;

    my %stats;

    my $config_purge = $config->get('config.purge');

    my $logs_home = $ENV{BASELINER_LOGHOME};

    my $log_dir = Path::Class::dir( $logs_home );
    return if $config_purge->{no_file_purge} || !$log_dir;

    _log "Purging logs";

    while (my $file = $log_dir->next) {
        next unless -f $file;
        next unless $file->basename =~ /(?<filename>.+)\.log$/;

        my @particular_logs = ("nginx-error.log", "nginx-access.log", "redis.log", "mongod.log");
        if ( $file->basename =~ qr/^cla\-web\-(.+)\.log$/ or $file->basename =~ qr/^cla\-disp\-(.+)\.log$/ ) {
            push( @particular_logs, $file->basename );
        }
        next unless grep { $_ eq $file->basename } @particular_logs;

        my $filename = $+{filename};
        my $filesize = -s $file;

        my $max_size;
        if ( $file->basename =~ qr/^cla\-disp\-(.+)\.log$/ ) {
            $max_size = $config_purge->{keep_disp_log_size};
        }
        elsif ( $file->basename =~ qr/^cla\-web\-(.+)\.log$/ ) {
            $max_size = $config_purge->{keep_web_log_size};
        }
        else {
            $max_size = $config_purge->{ "keep_" . $filename . "_log_size" };
        }

        next unless $max_size && $filesize > $max_size * $self->file_size_factor;

        require Baseliner::LogfileRotate;

        _log "Rotating: " . $file->basename;

        my $log = Baseliner::LogfileRotate->new(
            File    => $file,
            Count   => $config_purge->{keep_rotation_level},
            Gzip    => 'lib',
            Dir     => $file->dir,
            Flock   => 'yes',
            Persist => 'yes',
        );
        $log->rotate();

        _log "Done rotating: ".$file->basename;

        $stats{log_rotate}++;
    }

    return \%stats;
}

sub purge_messages {
    my $self = shift;
    my ( $opts, $config ) = @_;

    my %stats;

    my $config_purge = $config->get('config.purge');

    _log "Purging messages";

    my $keep_sent_messages = $config_purge->{keep_sent_messages};
    return {} unless $keep_sent_messages;

    my $min_ts = '' . ( mdb->now() - $keep_sent_messages );

    my @old_messages = mdb->message->find( { created => { '$lt' => $min_ts } } )->all;
    my @old_messages_ids = map { $_->{_id} } @old_messages;

    if (@old_messages_ids) {
        mdb->message->remove( { _id => { '$in' => \@old_messages_ids } } );

        $stats{messages} += @old_messages_ids;
    }

    return \%stats;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
