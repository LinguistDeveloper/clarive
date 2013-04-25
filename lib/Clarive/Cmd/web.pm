package Clarive::Cmd::web;
use Moo;
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'Start/Stop web server';

has f          => qw(is rw default) => sub { 0 };
has r          => qw(is rw default) => sub { 0 };
has signal     => qw(is rw default) => sub { 'TERM' };
has wait       => qw(is ro default) => sub { 30 };
has env        => qw(is ro default) => sub { $ENV{CLARIVE_ENV} // 'local' };
has host       => qw(is ro);
has listen     => qw(is ro default) => sub { [] };
has workers    => qw(is ro);
has socket     => qw(is ro);
has daemon     => qw(is ro);
has port       => qw(is ro default) => sub { '3000' };
has engine     => qw(is ro default) => sub { 'Starman' };
has restarter  => qw(is rw default) => sub { 0 };
has trace      => qw(is rw default) => sub { 0 };

has pid_file      => qw(is rw);
has pid_web_file  => qw(is rw);
has log_file      => qw(is rw lazy 1 default), sub { $_[0]->tmp_dir . '/' . $_[0]->instance_name . '.log' };
has log_keep      => qw(is rw default) => sub { 10 };
has instance_name => qw(is rw);
has id            => qw(is ro default) => sub { 'cla-web' };

with 'Clarive::Role::Daemon';
with 'Clarive::Role::Baseliner';  # yes, I run baseliner stuff

sub BUILD {
    my $self = shift;

    my $logdir = $ENV{BASELINER_LOGHOME} || join('/', $self->tmp_dir, 'log' );
    unless( -d $logdir ) {
        require File::Path;
        File::Path::make_path( $logdir );
        die "ERROR: could not access log directory '$logdir'"
            unless -d $logdir;
    }
    
    $self->instance_name( $self->id . '-' . $self->port );
    my $pid_name = $self->tmp_dir . '/' . $self->instance_name ;
    $self->pid_file( $pid_name . '.pid' );
    $self->pid_web_file( $pid_name . '-web.pid' );
    
    # log file (only created by daemonize/nohup, but used by tail)
    
    
    #
    # restarter ? 
    #
    
    if( defined $self->opts->{r} ) {
        $self->opts->{R} = join ' ', ('lib', glob( '*.conf' ), grep( !/^features\/#/, glob 'features/*/lib' ) );
    }
    if( defined $self->opts->{R} ) {
        $self->restarter(1);
    }

    $self->setup_baseliner;
    
}

sub setup_vars {
    my ($self,%opts) = @_;
    
    $ENV{PLACK_ENV} = 'deployment'; # $self->debug ? 'development' : 'deployment';
    
    say "home: " . $self->home;
    say "env: " . $self->env; 

    if( $ENV{BASELINER_LIBPATH} ) {
        $ENV{LIBPATH} = join ':', $ENV{BASELINER_LIBPATH}, $ENV{LIBPATH};
    }
    
    $self->setup_pid_file();

    if( $self->daemon ) {
        say 'logfile: ' . $self->log_file;
        $self->_log_zip( $self->log_file ); 
        $self->_cleanup_logs( $self->log_file ); 
    }
    
=pod

    export LIBPATH=$BASELINER_LIBPATH:$LIBPATH

    if [ ! -e "$LOGDIR" ]; then
        echo "Log directory does not exist or not accesible: $LOGDIR"
        exit 12
    fi

    export BASELINER_ID="$BASELINER_SERVER-$BASELINER_PORT"
    export STATUSFILE=$LOGDIR/bali-web-$BASELINER_ID.status
=cut

}

sub _write_pid {
    my ($self, $pid) = @_;
    # write pid to pidfile
    open(my $pf, '>', $self->pid_file ) or die "Could not open pidfile: $!";
        print $pf $pid // $$;
        close $pf; 
}

sub run {
    goto &run_start;
}

sub run_start {
    my ($self, %opts)=@_; 
    
    require Plack::Runner;
    require Proc::Exists;
    my $runner = Plack::Runner->new( default_middleware => 0 );
    
    # prepare plackup options (Plack::Runner)
    if( !exists $self->opts->{standalone} && $self->engine ) {
        $runner->{server} = $self->engine;
    }
    if( my $arg = $self->opts->{R} ) {
        $runner->{loader} = "Restarter";
        $runner->loader->watch(split ",", $arg );
    }
    
    $self->setup_vars( %opts );
    
    TOP:
    
    say sprintf "Starting web server: http://%s:%s", $self->host // '*', $self->port;
    
    $runner->{argv} = [];
    my $proc = sub { 
        $runner->run('Clarive::PSGI::Web');
    };
    my $super_runner = sub{
        my @sigs=();
        my $pid = fork; # again
        if( $pid ) {
            # parent
            $self->_write_pid();
            $SIG{CHLD} = 'IGNORE'; # avoid zombies
            $SIG{HUP} = sub {
                push @sigs, 'HUP';
            };
            $SIG{TERM} = sub {
                push @sigs, 'TERM';
            };
            $SIG{INT} = sub {
                push @sigs, 'INT';
            };
            while(1){
                while( @sigs ) {
                    my $sig = shift @sigs;
                    if( $sig eq 'HUP' ) {
                        kill TERM => $pid;
                        #warn "KILLED $pid child. Restarting.";
                        while( Proc::Exists::pexists( $pid ) ) {
                            #warn "WAITING SHUTDWON of $pid...";
                            sleep 1;
                        }
                        unlink $self->pid_web_file;
                        #warn "RESTARTING FROM TOP...";
                        goto TOP;
                    }
                    elsif( $sig ~~ ['TERM', 'INT'] ) {
                        kill TERM => $pid;
                        #warn "KILLED $pid child (SIG $sig)";
                        while( Proc::Exists::pexists( $pid ) ) {
                            #warn "WAITING SHUTDWON of $pid...";
                            sleep 1;
                        }
                        $self->_exit(0);
                    }
                }
                sleep(1);
            }
        } else {
            $proc->();
            $self->_exit(0);
        }
    };
    
    $runner->{options} = [ 
        $self->workers ? (workers => $self->workers) : (),
        pid => $self->pid_web_file,
        $runner->mangle_host_port_socket( $self->host, $self->port, $self->socket, @{ ref $self->listen ? $self->listen : [$self->listen] } )
    ];
    if( exists $self->opts->{daemon} ) {
        
        $self->nohup( $super_runner );
        
        # $self->_install_server_starter();
        #require Clarive::Starter;
        #Clarive::Starter::start_server(
        #    port     => $self->port,
        #    pid_file => $self->pid_file,
        #    exec     => [],
        #    proc     => $proc
        #);
    } else {
        $super_runner->();
        #$self->_write_pid();
        #$proc->();
    }

=pod 

_loader: !!perl/hash:Plack::Loader::Restarter
  watch:
    - lib
access_log: ~
app: ~
argv: []
daemonize: ~
default_middleware: 1
env: ~
eval: ~
help: ~
includes: []
loader: Restarter
modules: []
options:
  - t
  - 1
  - host
  - 9
  - port
  - 3000
  - listen
  -
    - 9:3000
  - socket
  - ~
path: ~
server: HTTP::Server::Simple
version: ~

=cut

}

sub run_stop {
    my ($self,%opts) = @_;
    
    require Proc::Exists;
    my $pid = $self->_find_pid;
    
    if( Proc::Exists::pexists( $pid ) ) {
        say "Shutting down server with process $pid...";
        $self->_kill( $self->signal, $pid, $opts{no_wait_kill} );

        # in case server is nested within a server_starter
        if( -e $self->pid_file . '2' ) {
            my $pid2 = $self->_find_pid( 2 );
            $self->_kill( $self->signal, $pid2, $opts{no_wait_kill} );
        }
    } else {
        say "Server was not up (process $pid not found). Nothing to do.";
    }
    unlink $self->pid_file unless $opts{keep_pidfile};
}

sub run_restart {
    my ($self,%opts) = @_;
    require Proc::Exists;
    my $pid = $self->_find_pid;
    $self->_kill( 'HUP', $pid, 1 );
    say "Restart in progress.";
}

sub run_log {
    my ($self,%opts) = @_;
    say "logfile: " . $self->log_file;
    open( my $log,'<', $self->log_file ) or die sprintf "ERROR: could not open log file %s: %s", $self->log_file, $!;
    while( <$log> ) {
        print $_;
    }
    close $log;
    exit 0;
}

sub run_tail {
    my ($self,%opts) = @_;
    require File::Tail;
    say "logfile: " . $self->log_file;
    my $file = File::Tail->new(
        name        => $self->log_file,
        tail        => $opts{tail} // 500,
        interval    => $opts{interval} // .5,
        maxinterval => $opts{maxinterval} // 1,
    );
    while (defined( my $line=$file->read)) {
        print "$line";
    }
}

sub _kill {
    my ($self, $sig, $pid, $no_wait_kill ) = @_;
    die "ERROR: could not find process $pid\n" unless Proc::Exists::pexists( $pid );
    kill $sig => $pid;
    unless( $no_wait_kill ) {
        my $cnt = 0;
        print "Waiting for server to stop";
        while( Proc::Exists::pexists( $pid ) && $cnt++ < $self->wait ) {
            print '.';
            sleep 1;
        }
        print "\r" . ( ' ' x ( 26 + $cnt ) ) . "\r";
        if( Proc::Exists::pexists( $pid ) ) {
            if( $self->f() ) {
                $self->f( 0 );
                warn "Could not stop server. Sending KILL signal\n";
                $self->_kill( 9 => $pid, $no_wait_kill );
            } 
            die "ERROR: could not stop server with process $pid.\n";
        } else {
            say "Server stopped.";
        }
    } else {
        say "Signal $sig sent to server $pid."; 
    }
}

sub _find_pid {
    my ($self, $cnt )  = @_;
    my $pidfile = $self->pid_file . ($cnt ? $cnt : '' );
    my $clean_pid = sub { $_[0] =~ /^([0-9]+)/ ? $1 : $_[0] };
    if( defined $self->opts->{pid} ) {
        return $clean_pid->( $self->opts->{pid} );
    } elsif( -e $pidfile ) {
        open(my $pf, '<', $pidfile ) or die "Could not open pidfile: $!";
        my $pid = join '',<$pf>;
        close $pf;
        return $clean_pid->( $pid );
    } else {
        die sprintf "pid file not found: %s\n", $pidfile;
    }
}

sub _exit {
    my ($self,$rc) = @_;
    
    unlink $self->pid_file;
    unlink $self->pid_web_file;
    
    exit $rc;
}

sub _install_server_starter { 
    no strict;
    no warnings;
    require Clarive::Starter;
    
    # monkey patch
    *Server::Starter::_start_worker = sub {
        my $opts = shift;
        my $pid;
        while (1) {
            $ENV{SERVER_STARTER_GENERATION}++;
            $pid = fork;
            die "fork(2) failed:$!"
                unless defined $pid;
            if ($pid == 0) {
                # child process
                $opts->{proc}->();
                warn "================> DONE ";
                exit 0;
            }
            print STDERR "starting new worker $pid\n";
            sleep $opts->{interval};
            if ((grep { $_ ne 'HUP' } @signals_received)
                    || waitpid($pid, WNOHANG) <= 0) {
                last;
            } else {
                warn "Server stopped on signal=@signals_received.";
            }
            print STDERR "new worker $pid seems to have failed to start, exit status:$?\n";
        }
        $pid;
    };
}

1;
