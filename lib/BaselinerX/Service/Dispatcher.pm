package BaselinerX::Service::Dispatcher;
use Baseliner::Plug;
use Baseliner::Utils;
use Proc::Background;
use Proc::Exists qw(pexists);
use Try::Tiny;

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
    handler => \&run,
};

sub run {
    my ( $self, $c, $config ) = @_;
    my $isrunning = qx{ps uwwx|grep perl|grep "bali.pl"|grep "service.dispatcher"|grep -v grep|grep -v $$};
    if ($isrunning) {
        _log "Another instance of 'service.dispatcher' is running\n$isrunning";
        return 1;
    }

    #TODO if 'start' fork and go nohup .. or proc::background my self in windows
    #TODO if 'stop' go die
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
    _log "Goodbye!";
    exit 0;
}

sub dispatcher {
    my ( $self, $c, $config ) = @_;
    my @args = @_;

    my $frequency = $config->{frequency};

    $SIG{HUP}  = sub { $self->stop_all( $c, @args ) };
    $SIG{TERM} = sub { $self->stop_all( $c, @args ) };
    $SIG{STOP} = sub { $self->stop_all( $c, @args ) };
    $SIG{USR1} = sub { $self->restart_all( $c, @args ) };

    # reaps child process to avoid zombies
    $SIG{CHLD} = 'IGNORE';

    #require POSIX unless( $^O eq 'Win32' );
    #sub REAPER { 1 until waitpid(-1 , POSIX::WNOHANG) == -1 };
    #$SIG{CHLD} = \&REAPER;

    while (1) {
        _log _loc('Checking for daemons started/stopped');
        my @daemons = ();
        try {
            # in case of DB failure
            @daemons = Baseliner->model('Daemons')->list( all => 1 );
        }
        catch {
            _log _loc "Error trying to read daemon list from DB: %1", shift();
        };
        for my $daemon (@daemons) {
            if ( !$daemon->active ) {
                next unless $daemon->pid;
                next unless pexists( $daemon->pid );
                _debug "Stopping daemon " . $daemon->service;

                Baseliner->model('Daemons')->kill_daemon($daemon);

            }
            elsif ( $daemon->active ) {
                next if $daemon->pid > 0 && pexists( $daemon->pid );
                _debug "Starting daemon " . $daemon->service;

                my $reg = Baseliner->model('Registry')->get( $daemon->service )
                  if $daemon->service;

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
                        params    => $params
                      );
                }
                elsif ( exists $config->{fork} || exists $config->{forked} ) {

                    # forked
                    @started =
                      Baseliner->model('Daemons')->service_start_forked(
                        id      => $daemon->id,
                        service => $daemon->service,
                        params  => $params
                      );
                }
                else {
                    # background proc
                    @started = Baseliner->model('Daemons')->service_start(
                        id      => $daemon->id,
                        service => $daemon->service,
                        params  => $params
                    );
                }
                my $started = shift @started;
                $daemon->pid( $started->{pid} );
                $daemon->update;

                #REAPER() unless $^O eq 'Win32';

                # $c->launch( $daemon->{service} );
            }
        }
        sleep $frequency;
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
