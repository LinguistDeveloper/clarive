package BaselinerX::Service::Dispatcher;
use Moose;
use Baseliner::Core::Registry ':dsl';
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
has disp_id => qw(is rw isa Any), default => sub{ $ENV{CLARIVE_DISPATCHER_ID} || lc( Sys::Hostname::hostname() ) };
#has hostname => qw(is rw isa Any), default => sub{ lc( Sys::Hostname::hostname() ) };
has session => qw(is rw isa Any), default => sub{ mdb->run_command({'whatsmyuri' => 1})->{you} };

sub run {
    my ( $self, $c, $config ) = @_;

    #TODO if 'start' fork and go nohup .. or proc::background my self in windows
    #TODO if 'stop' go die
    _log "Starting dispatcher $self->{disp_id}...";

    my $dispatcher = mdb->dispatcher->find_one( { disp_id => $self->disp_id } );

    if ( $dispatcher && $dispatcher->{hostname} ne $self->hostname && $dispatcher->{status} eq 'running' ) {
        _fail _loc("Cannot start instance %1. Already running in host %2", $self->{disp_id}, $dispatcher->{hostname});
    }

    mdb->dispatcher->update(
        { disp_id => $self->disp_id },
        {   '$set' => {
                disp_id  => $self->disp_id,
                hostname => $self->hostname,
                ts       => mdb->ts,
                session  => $self->session,
                status => 'running'
            }
        },
        { upsert => 1}
    );

    if ( exists $config->{list} ) {
        $self->list;
    }
    else {
        _log "Starting daemons...";
        $self->dispatcher( $c, $config );
    }
}

sub list {
    my ( $self, $c, $config ) = @_;

    _log "Listing active daemons...";
    for my $daemon ( Baseliner->model('Daemons')->list( all => 1, disp_id => $self->disp_id ) ) {
        my ($instance) = grep { $_->{disp_id} eq $self->{disp_id} } _array $daemon->{active_instances};
        
        if ( $instance ) {
            my $pid = $instance->{pid};

            if ($pid) {
                my $exists = pexists( $instance->{pid} );
                my $e_text = $exists ? 'running' : 'missing';
                my $disp_id   = $daemon->{disp_id};
                print $daemon->{service} . " ($disp_id:$pid): $e_text", "\n";
            }
            else {
                print $daemon->{service} . ": inactive", "\n";
            }
        }
    }
}

sub stop_all {
    my ( $self, $c, $config ) = @_;

    _log "Stopping all daemons...";

    # kill everybody
    for my $daemon ( Baseliner->model('Daemons')->list( all => 1, disp_id => $self->disp_id ) ) {
        if ( $daemon->{active} ) {
            my ($instance) = grep { $_->{disp_id} eq $self->{disp_id} } _array $daemon->{active_instances};
            
            if ( $instance ) {
                next unless $instance->{pid};
                next unless pexists( $instance->{pid} );
                _log "Stopping daemon " . $daemon->{service};
                Baseliner->model('Daemons')->kill_daemon($daemon, 9, $self->disp_id);
            }
        }
    }
    mdb->dispatcher->remove(
        { disp_id => $self->disp_id }
    );


    # bye!
    _log "Goodbye!";
    exit 0;
}

sub restart_all {
    my ( $self, $c, $config ) = @_;

    _log "Restarting all daemons nicely (via signal USR1)...";

    # kill everybody
    for my $daemon ( Baseliner->model('Daemons')->list( all => 1, disp_id => $self->disp_id ) ) {
        if ( $daemon->{active} ) {
            my ($instance) = grep { $_->{disp_id} eq $self->{disp_id} } _array $daemon->{active_instances};
            
            if ( $instance ) {
                next unless $instance->{pid};
                next unless pexists( $instance->{pid} );
                _log "Stopping daemon " . $daemon->{service};
                Baseliner->model('Daemons')->kill_daemon( $daemon, RESTART_SIGNAL, $self->disp_id );
            }
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
    
    $SIG{HUP}  = sub { $self->restart_all( $c, @args ); $sigs{HUP} and $sigs{HUP}->() unless ref $sigs{HUP}  ne 'CODE' };
    $SIG{TERM} = sub { $self->stop_all( $c, @args ); $sigs{TERM} and $sigs{TERM}->() };
    $SIG{STOP} = sub { $self->stop_all( $c, @args ); $sigs{STOP} and $sigs{STOP}->() };
    $SIG{INT} = sub { $self->stop_all( $c, @args ); $sigs{INT} and $sigs{INT}->() };
    $SIG{USR1} = sub { $self->restart_all( $c, @args ); $sigs{USR1} and $sigs{USR1}->() };

    # reaps child process to avoid zombies
    $SIG{CHLD} = 'IGNORE';

    #require POSIX unless( $^O eq 'Win32' );
    #sub REAPER { 1 until waitpid(-1 , POSIX::WNOHANG) == -1 };
    #$SIG{CHLD} = \&REAPER;

    while (1) {
        _log _loc('Checking for daemons started/stopped');

        mdb->dispatcher->update(
            { disp_id => $self->disp_id },
            {   '$set' => {
                    ts       => mdb->ts
                }
            }
        );

        my @daemons = ();

        try {
            # in case of DB failure
            @daemons = Baseliner->model('Daemons')->list( all => 1, disp_id => $self->disp_id );
        }
        catch {
            _log _loc "Error trying to read daemon list from DB: %1", shift();
        };
        for my $daemon (@daemons) {
            my ($instance) = grep { $_->{disp_id} eq $self->{disp_id} } _array $daemon->{active_instances};
            
            if ( $instance ) {
                $self->check_daemon( { daemon => $daemon }, $config );
            } else {
                $self->check_daemon( { daemon => $daemon, new_disp => 1 }, $config );
            }
        }
        try {
            # in case of DB failure
            @daemons = Baseliner->model('Daemons')->list( no_id => $self->disp_id );
        }
        catch {
            _log _loc "Error trying to read daemon list from DB: %1", shift();
        };
        for my $daemon (@daemons) {
            my ($instance) = grep { $_->{disp_id} eq $self->{disp_id} } _array $daemon->{active_instances};
            
            if ( $instance ) {
                _debug "Stopping daemon " . $daemon->{service} . " not active any more in instance ".$self->disp_id;
                Baseliner->model('Daemons')->kill_daemon($daemon, 9, $self->disp_id);
            }
        }        
        sleep $frequency;
    }
}

sub check_daemon {
    my ($self, $p, $config ) = @_;  

    my $daemon = $p->{daemon};
    my $new_disp = $p->{new_disp} // 0;

    my ($instance) = grep { $_->{disp_id} eq $self->disp_id } _array $daemon->{active_instances};
#    _debug("Found instance: "._dump $instance);
    
    if ( !$daemon->{active} ) {
        if ( !$new_disp ) {
            return unless $instance && $instance->{pid};
            return unless pexists( $instance->{pid} );
            _debug "Stopping daemon " . $daemon->{service};
            Baseliner->model('Daemons')->kill_daemon($daemon, 9, $self->disp_id);
        }
    }

    elsif ( $daemon->{active} ) {
        if ( !$new_disp ) {
            if (  $instance && $instance->{pid} > 0 && pexists( $instance->{pid} ) ) {
                mdb->daemon->update(
                    {_id => $daemon->{_id}, 'active_instances.disp_id' => $self->disp_id},
                    {   '$set' => {
                            'active_instances.$.last_ping' => mdb->ts
                        }
                    });
                return;          
            };
            if ( exists $self->failed_services->{ $daemon->{service} } ) {
                mdb->daemon->update(
                    {_id => $daemon->{_id}, 'active_instances.disp_id' => $self->disp_id},
                    {   '$set' => {
                            'active_instances.$.last_ping' => mdb->ts
                        }
                    });
                return;                              
            }  # ignore failing services
        }
        _debug "Starting daemon " . $daemon->{service};

        if ( $instance ) {
            mdb->daemon->update(
                {_id => $daemon->{_id} },
                {   '$pull' => { active_instances => {
                        disp_id => $self->disp_id
                    }
                }
            });
        }
        my $reg = try {
            Baseliner->model('Registry')->get( $daemon->{service} ) if $daemon->{service}
        } catch {
            my $err = shift;
            _error( _loc("Could not start service %1. Service ignored: %2", $daemon->{service}, $err ) );
            $self->failed_services->{ $daemon->{service} } = ();
        };

        return if !$reg;

        # bring it back up
        my $params = {};
        my @started;
        if ( ref($reg) && exists $reg->{frequency_key} ) {
            _debug("Starting forked with frequency $reg->{frequency_key}");
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
                id        => $daemon->{_id}.'',
                service   => $daemon->{service},
                disp_id  => $self->disp_id,
                params    => $params
              );
        }
        elsif ( exists $config->{fork} || exists $config->{forked} ) {

            _debug("Starting forked");
            # forked
            @started =
              Baseliner->model('Daemons')->service_start_forked(
                id      => $daemon->{_id}.'',
                service => $daemon->{service},
                disp_id  => $self->disp_id,
                params  => $params
              );
        }
        else {
            # background proc
            _debug("Starting normal (no fork)");
            @started = Baseliner->model('Daemons')->service_start(
                id      => $daemon->{_id}.'',
                service => $daemon->{service},
                disp_id  => $self->disp_id,
                params  => $params
            );
        }
        my $started = shift @started;
        _debug($started);
        mdb->daemon->update(
            {_id => $daemon->{_id} },
            {   '$push' => { active_instances => {
                    last_ping => mdb->ts,
                    pid => $started->{pid},
                    disp_id => $self->disp_id,
                    status => 'running'
                }
            }
        });
        _debug("Daemon started");
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

no Moose;
__PACKAGE__->meta->make_immutable;

1;

