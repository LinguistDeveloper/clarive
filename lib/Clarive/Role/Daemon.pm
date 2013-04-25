package Clarive::Role::Daemon;
use v5.10;
use Moo::Role;

requires 'pid_file';
requires 'log_file';
requires 'log_keep';

sub nohup {
    my ($self, $proc ) = @_;
    ref $proc eq 'CODE' or die "missing parameter proc";
    
    # TODO redirect stdout and error somewhere else
    #open STDOUT, '>', '/dev/null' or die "Could not redirect STDOUT: $!";
    #open STDERR, '>&STDOUT' or die "Could not redirect STDERR: $!";
    open STDIN, '/dev/null' or die "Could not redirect STDIN: $!";
    open STDOUT, '>>', $self->log_file or die sprintf "Could not redirect STDIN to %s: $!", $self->log_file;
    open STDERR, '>&STDOUT' or die "Could not redirect STDERR: $!";
    
    require POSIX;
    local $SIG{HUP} = 'IGNORE';
    my $pid = fork;
    if ($pid) { 
        return $pid
    } # parent
    else { # child
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
    if( -e $self->pid_file ) {
        open(my $pf, '<', $self->pid_file ) or die "Could not open pidfile: $!";
        my $pid = join '',<$pf>;
        require Proc::Exists;
        if( Proc::Exists::pexists( $pid ) ) {
            say sprintf "Error: Server is already running on port %s. PID: %s", $self->port, $pid;
            exit 1;
        } else {
            unlink $self->pid_file;
        }
    } 
    
    say 'pidfile: ' . $self->pid_file;
}

1;
