package BaselinerX::Service::Dispatcher;
use Baseliner::Plug;
use Baseliner::Utils;
use Proc::Background;
use Proc::Exists qw(pexists);
use Try::Tiny;
use Sys::Hostname;
use Class::Date;

use constant RESTART_SIGNAL => 30;    # THE USR1 signal

with 'Baseliner::Role::Service';

=head1 DESCRIPTION

Brings up all daemons. 

Checks the daemon table to see if they are active. Stops daemons when they are not.

=cut

register 'config.dispatcher' => {
    name     => 'Dispatcher configuration',
    metadata => [ { id => 'frequency', default => 30 }, ],
};

register 'service.dispatcher' => {
    name    => 'Dispatcher Service',
    config  => 'config.dispatcher',
    daemon => 1,
    handler => \&run,
};

has failed_services => qw(is rw isa HashRef), default=>sub{ +{} };
has disp_id => qw(is rw isa Any), default => sub{ $ENV{BASELINER_DISPATCHER_ID} || lc( Sys::Hostname::hostname() ) };

sub run {
    my ( $self, $c, $config ) = @_;

    #TODO if 'start' fork and go nohup .. or proc::background my self in windows
    #TODO if 'stop' go die
    _log "Starting dispatcher ...";
    if ( exists $config->{list} ) {
        $self->list;
    }
    else {
        _log "Starting daemons...";
        sleep 3;
        $self->dispatcher( $c, $config );
    }
}

sub list {
    my ( $self, $c, $config ) = @_;

    _log "Listing active daemons...";
    for my $daemon ( Baseliner->model('Daemons')->list( all => 1 ) ) {
        my $pid = $daemon->pid;
        if ($pid) {
            my $exists = pexists( $daemon->pid );
            my $e_text = $exists ? 'running' : 'missing';
            my $host   = $daemon->hostname;
            print $daemon->service . " ($host:$pid): $e_text", "\n";
        }
        else {
            print $daemon->service . ": inactive", "\n";
        }
    }
}

sub stop_all {
    my ( $self, $c, $config ) = @_;

    _log "Stopping all daemons...";

    # kill everybody
    for my $daemon ( Baseliner->model('Daemons')->list( all => 1 ) ) {
        if ( $daemon->active ) {
            next unless $daemon->pid;
            next unless pexists( $daemon->pid );
            _log "Stopping daemon " . $daemon->service;
            Baseliner->model('Daemons')->kill_daemon($daemon);
        }
    }

    # bye!
    _log "Goodbye!";
    exit 0;
}

sub restart_all {
    my ( $self, $c, $config ) = @_;

    _log "Restarting all daemons nicely (via signal USR1)...";

    # kill everybody
    for my $daemon ( Baseliner->model('Daemons')->list( all => 1 ) ) {
        if ( $daemon->active ) {
            next unless $daemon->pid;
            next unless pexists( $daemon->pid );
            _log "Stopping daemon " . $daemon->service;
            Baseliner->model('Daemons')->kill_daemon( $daemon, RESTART_SIGNAL );
        }
    }

    # bye!
    #_log "Goodbye!";
    _log "Restarting...";
    #exit 0;
}

sub dispatcher {
    my ( $self, $c, $config ) = @_;
    my @args = @_;

    my $frequency = $config->{frequency};

    my %sigs = map {
        $_ => $SIG{$_} 
    } qw(HUP TERM STOP USR1);
    
    $SIG{HUP}  = sub { $self->restart_all( $c, @args ); $sigs{HUP} and $sigs{HUP}->() };
    $SIG{TERM} = sub { $self->stop_all( $c, @args ); $sigs{TERM} and $sigs{TERM}->() };
    $SIG{STOP} = sub { $self->stop_all( $c, @args ); $sigs{STOP} and $sigs{STOP}->() };
    $SIG{USR1} = sub { $self->restart_all( $c, @args ); $sigs{USR1} and $sigs{USR1}->() };

    # reaps child process to avoid zombies
    $SIG{CHLD} = 'IGNORE';

    #require POSIX unless( $^O eq 'Win32' );
    #sub REAPER { 1 until waitpid(-1 , POSIX::WNOHANG) == -1 };
    #$SIG{CHLD} = \&REAPER;

    my $first_time = 1;
    while (1) {
        _log _loc('Checking for daemons started/stopped');
        my @daemons = ();

        # Block table and start transaction
        my $dbh = Baseliner->model('Baseliner')->storage->dbh;
        $dbh->begin_work();
        $dbh->do("lock table bali_daemon in exclusive mode");

        try {
            # in case of DB failure
            @daemons = Baseliner->model('Daemons')->list( all => 1 );
        }
        catch {
            _log _loc "Error trying to read daemon list from DB: %1", shift();
        };
        for my $daemon (@daemons) {
            if ( $daemon->hostname eq $self->disp_id ) {
                $self->check_daemon( { daemon => $daemon }, $config );
            } elsif ( !$first_time ) {
                my $now = Class::Date->now;
                my $last_ping = Class::Date->new( $daemon->last_ping );
                if ( $now - 2*$frequency."s" > $last_ping ) {
                    $self->check_daemon( { daemon => $daemon, new_disp => 1 }, $config );
                }
            }
        }
        $dbh->commit();
        $first_time = 0;
        sleep $frequency;
    }
}

sub check_daemon {
    my ($self, $p, $config ) = @_;

    my $daemon = $p->{daemon};
    my $new_disp = $p->{new_disp} // 0;

    my $now = Class::Date->now;

    if ( !$daemon->active ) {
        if ( !$new_disp ) {
            return unless $daemon->pid;
            return unless pexists( $daemon->pid );
            _debug "Stopping daemon " . $daemon->service;
            Baseliner->model('Daemons')->kill_daemon($daemon);
        }
    }

    elsif ( $daemon->active ) {
        if ( !$new_disp ) {
            if (  $daemon->pid > 0 && pexists( $daemon->pid ) ) {
                $daemon->last_ping( "$now" );
                $daemon->update;
                return;          
            };
            if ( exists $self->failed_services->{ $daemon->service } ) {
                $daemon->last_ping( "$now" );
                $daemon->update;
                return;                              
            }  # ignore failing services
        }
        _debug "Starting daemon " . $daemon->service;

        my $reg = try {
            Baseliner->model('Registry')->get( $daemon->service ) if $daemon->service
        } catch {
            _error( _loc("Could not start service %1. Service ignored.", $daemon->service ) );
            $self->failed_services->{ $daemon->service } = ();
        };

        next if !$reg;

        # bring it back up
        my $params = {};
        my @started;
        if ( ref($reg) && exists $reg->{frequency_key} ) {

            # determine frequency
            my $conf = try {
                Baseliner->model('ConfigStore')
                  ->get( $reg->{frequency_key} );
            }
            catch {};
            my $freq = 60;    #TODO use the configstore also
            _log "Using frequency ${freq}s";

            # launch loop
            @started =
              Baseliner->model('Daemons')->service_start_forked(
                frequency => $freq,
                id        => $daemon->id,
                service   => $daemon->service,
                hostname  => $self->disp_id,
                params    => $params
              );
        }
        elsif ( exists $config->{fork} || exists $config->{forked} ) {

            # forked
            @started =
              Baseliner->model('Daemons')->service_start_forked(
                id      => $daemon->id,
                service => $daemon->service,
                hostname  => $self->disp_id,
                params  => $params
              );
        }
        else {
            # background proc
            @started = Baseliner->model('Daemons')->service_start(
                id      => $daemon->id,
                service => $daemon->service,
                hostname  => $self->disp_id,
                params  => $params
            );
        }
        my $started = shift @started;
        $daemon->last_ping( "$now" );
        $daemon->pid( $started->{pid} );
        $daemon->hostname( $self->disp_id );
        $daemon->update;

        #REAPER() unless $^O eq 'Win32';

        # $c->launch( $daemon->{service} );
    }
}
=head1 nohup

use POSIX qw/setsid/;
my $pid = fork();
die "can't fork: $!" unless defined $pid;
exit 0 if $pid;
setsid();
open (STDIN, "</dev/null");
open (STDOUT, ">/dev/null");
open (STDERR,">&STDOUT");
exec "some_system_command";

=cut

1;

