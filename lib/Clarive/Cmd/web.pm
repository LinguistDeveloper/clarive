package Clarive::Cmd::web;
use Mouse;
use Sys::Hostname;
extends 'Clarive::Cmd';
use v5.10;
use experimental 'smartmatch';

our $CAPTION = 'Start/Stop web server';

has r          => qw(is rw default) => sub { 0 };
has host       => qw(is ro);
has listen     => qw(is ro), default => sub{ [] };
has workers    => qw(is ro);
has socket     => qw(is ro);
has daemon     => qw(is ro);
has port       => qw(is ro default) => sub { '3000' };
has engine     => qw(is ro default) => sub { Clarive->opts->{websockets} ? 'Twiggy::Prefork' : 'Starman' };
has restarter  => qw(is rw default) => sub { 0 };
has trace      => qw(is rw default) => sub { 0 };

has pid_web_file  => qw(is rw);
has instance_name => qw(is rw);
has id            => qw(is ro default) => sub { lc( Sys::Hostname::hostname() ) };

# From Starman (check lib/Starman/Server.pm for options)
has max_requests => qw(is rw isa Any);
has [qw(backlog min_servers min_spare_servers max_spare_servers max_servers)] => qw(is rw isa Any);

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Daemon';
with 'Clarive::Role::Baseliner';  # yes, I run baseliner stuff

sub BUILD {
    my $self = shift;

    # log file (only created by daemonize/nohup, but used by tail)
    $self->setup_log_dir();
    
    $self->instance_name( 'cla-web-'. $self->id . '-' . $self->port );
    
    $self->setup_pid_file();
    $self->pid_web_file( $self->pid_name . '-web.pid' );
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
    
    $self->check_migrations;
}

sub setup_vars {
    my ($self,%opts) = @_;
    
    $ENV{PLACK_ENV} = 'deployment'; # $self->debug ? 'development' : 'deployment';
    
    say "home: " . $self->home;
    say "env: " . $self->env; 

    if( $ENV{BASELINER_LIBPATH} ) {
        $ENV{LIBPATH} = join ':', $ENV{BASELINER_LIBPATH}, $ENV{LIBPATH};
    }
    
    if( $self->daemon ) {
        say 'log_file: ' . $self->log_file;
        $self->_log_zip( $self->log_file ); 
        $self->_cleanup_logs( $self->log_file ); 
    }
}

sub check_migrations {
    my $self = shift;

    require Clarive::Cmd::migra;
    my $migra = Clarive::Cmd::migra->new(app => $self->app, env => $self->env, opts => {});

    my $check = $migra->check;

    if ($check) {
        if ($self->opts->{args}->{migrate}) {
            $migra->run;
        }
        else {
            die "ERROR: Migrations are not up to date. Run with --migrate flag or use migra- commands\n";
        }
    }
}

sub run {
    goto &run_start;
}

sub run_start {
    my ($self, %opts)=@_; 
    
    $self->check_pid_exists();

    require Plack::Runner;
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
    
    my @listen = ref $self->listen eq 'ARRAY' ? @{ $self->listen } : ($self->listen);
    say 'Starting web server: ' . 
        ( @listen 
            ? join(' ', @listen) 
            : sprintf( "http://%s:%s", $self->host // '*', $self->port)
    );
    
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
        ( 
            map { ( $_ => $self->$_ ) }
                grep { defined $self->$_ } 
                qw(min_servers min_spare_servers max_spare_servers max_requests max_servers) 
        ),
        # TODO Starlet: --max-workers --timeout --keepalive-timeout --max-keepalive-reqs --max-reqs-per-child --min-reqs-per-child --spawn-interval
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
}

before '_exit' => sub {
    my $self = shift;
    unlink $self->pid_web_file;
};

sub error_pid_is_running {
    my ($self, $pid)=@_;
    say sprintf "ERROR: Server is already running on port %s with pid %s", $self->port, $pid;
}

# deprecated ? 

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

=head1 Clarive Web-Server

Common options:

    --env <environment>
    --host <host>           hostname or ip address
    --port <portnum>        web port
    --listen                host:port
    --daemon                fork and start server
    --pid_file <file>       where to save the pid
    --log_file <file>       where to write the log to
    --log_keep <file>       days to keep log file
    --engine [Standalone|Twiggy|Starman|Starlet] default=Starman

=head1 web- subcommands:

=head2 start

Starts the server. Options:

    --workers <num>              number of web workers (default 5)
    --max_requests <num>         max requests per worker
    --min_servers <num>          min servers allowed (default =workers)
    --min_spare_servers <num>    min free workers allowed (default =workers-1)
    --max_spare_servers <num>    max free workers allowed (default =workers-1)
    --max_servers <num>          max servers allowed (default =workers)
    --backlog <num>              backlog of sockets available, lower numbers fails faster on high load (default 1024)

=cut
