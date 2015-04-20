package Clarive::Role::Daemon;
use Mouse::Role;
use Proc::Exists;
use v5.10;

requires 'instance_name'; 

has f          => qw(is rw default) => sub { 0 };
has pid_name => qw(is rw isa Str);
has pid_file => qw(is rw isa Str);
has opts_file => qw(is rw isa Str lazy 1 default), sub {
    my ($self)=@_;
    $self->pid_dir . '/' . $self->instance_name . '.yml';
};
has signal     => qw(is rw default) => sub { 'TERM' };  # standard kill signal
has wait       => qw(is ro default) => sub { 30 };  # seconds to wait for shutdown before killing
has log_file      => qw(is rw lazy 1 default), sub { $ENV{BASELINER_LOGHOME} ? $ENV{BASELINER_LOGHOME}.'/'. $_[0]->instance_name . '.log' : $_[0]->log_dir . '/' . $_[0]->instance_name . '.log' };
has log_keep      => qw(is rw default) => sub { 10 };

with 'Clarive::Role::TempDir';

sub nohup {
    my ($self, $proc ) = @_;
    ref $proc eq 'CODE' or die "missing parameter proc";
    
    # TODO redirect stdout and error somewhere else
    #open STDOUT, '>', '/dev/null' or die "Could not redirect STDOUT: $!";
    #open STDERR, '>&STDOUT' or die "Could not redirect STDERR: $!";
    
    require POSIX;
    local $SIG{HUP} = 'IGNORE';
    my $pid = fork;
    if ($pid) { 
        $self->_write_pid( $pid );
        $self->save_opts();
        return $pid
    } # parent
    else { # child
        open STDIN, '/dev/null' or die "Could not redirect STDIN: $!";
        open STDOUT, '>>', $self->log_file or die sprintf "Could not redirect STDIN to %s: $!", $self->log_file;
        open STDERR, '>&STDOUT' or die "Could not redirect STDERR: $!";
        POSIX::setsid() or die "Cannot establish session id: $!\n";
        $proc->();
        exit 0;
    }
}

sub _cleanup_logs {
    my ($self, $logfile ) = @_;

    $logfile //= $self->log_file;
    
    return unless $logfile;

    # cleanup > 10
    my @old = sort glob $logfile . '.*.gz';
    my $keep = $self->log_keep;
    while( @old > $keep ) {
        my $f = shift @old;
        say "Deleting old log file $f (log_keep = $keep)";
        unlink $f;
    }
}

sub _log_zip {
    my ($self, $logfile ) = @_;

    if( -e ( $logfile // $self->log_file ) ) {
        require DateTime;
        my $dt = DateTime->now;
        $dt =~ s{\W}{_}g;
        my $oldlog = $self->log_file . ".$dt.gz"; 
        #rename $self->log_file, $oldlog;
        require IO::Compress::Gzip;
        IO::Compress::Gzip::gzip( $self->log_file, $oldlog );
        unlink $self->log_file; 
        say "Previous log file renamed to $oldlog";
    }
} 

sub setup_pid_file {
    my ($self)=@_;
   
    $self->pid_name( $self->pid_dir . '/' . $self->instance_name );
    $self->pid_file( $self->pid_name . '.pid' );
    say 'pid_file: ' . $self->pid_file;
}

sub error_pid_is_running {
    my ($self, $pid)=@_;
    say sprintf "ERROR: Server is already running with pid %s", $pid;
}

sub check_pid_exists {
    my ($self)=@_;

    if( -e $self->pid_file ) {
        my $pid = $self->_find_pid;
        if( Proc::Exists::pexists( $pid ) ) {
            $self->error_pid_is_running( $pid );
            exit 1;
        } else {
            # should not be there
            unlink $self->pid_file;
        }
    } 
}

sub run_stop {
    my ($self,%opts) = @_;
    
    my $pid = $self->_find_pid;
    
    if( Proc::Exists::pexists( $pid ) ) {
        say "Shutting down server with process $pid...";
        $self->_kill( $self->signal, $pid, $opts{no_wait_kill} );
    } else {
        say "Server was not up (process $pid not found). Nothing to do.";
    }
    unlink $self->pid_file unless $opts{keep_pidfile};
}

sub run_tail {
    my ($self,%opts) = @_;
    require File::Tail;
    say "logfile: " . $self->log_file;
    die sprintf "ERROR: file does not exist: %s\n", $self->log_file unless -e $self->log_file;
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

sub setup_log_dir {
    my ($self) = @_;

    my $logdir = $ENV{BASELINER_LOGHOME} || join('/', $self->log_dir, 'log' );
    unless( -d $logdir ) {
        require File::Path;
        File::Path::make_path( $logdir );
        die "ERROR: could not access log directory '$logdir'"
            unless -d $logdir;
    }
    return $logdir;
}

sub _write_pid {
    my ($self, $pid) = @_;
    # write pid to pidfile
    open(my $pf, '>', $self->pid_file ) or die "Could not open pidfile: $!";
        print $pf $pid // $$;
    close $pf; 
}

sub save_opts {
    my ($self, $pid) = @_;
    # write opts to pidfile
    open(my $pf, '>', $self->opts_file ) or die "Could not open opts file: $!";
        print $pf $self->app->yaml( $self->opts ); 
    close $pf; 
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

sub run_restart {
    my ($self,%opts) = @_;
    my $pid = $self->_find_pid;
    $self->_kill( 'HUP', $pid, 1 );
    say "Restart in progress.";
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

sub _exit {
    my ($self,$rc) = @_;
    unlink $self->pid_file;
    exit $rc;
}

1;
__END__

=head2 stop

stops the server.

=head2 restart

restarts the server.

=head2 log 

prints the logfile to screen.

=head2 tail

follows the server log file.

=cut
