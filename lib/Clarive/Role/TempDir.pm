package Clarive::Role::TempDir;
use Mouse::Role;
use v5.10;

requires 'home';

has tmp_dir    => qw(is rw isa Str lazy 1 default), sub {
    my $self = shift;
    # TMPDIR
    my $tmpdir = $ENV{CLARIVE_TEMP} || join('/', $self->base, 'tmp' );
    $self->_ensure_path( $tmpdir );
    $tmpdir;
};

has log_dir    => qw(is rw isa Str lazy 1 default), sub {
    my $self = shift;
    # LOG DIR
    my $logdir = $ENV{CLARIVE_LOGDIR} || join('/', $self->base, 'logs' );
    $self->_ensure_path( $logdir );
    $logdir;
};

has job_dir    => qw(is rw isa Str lazy 1 default), sub {
    my $self = shift;
    # LOG DIR
    my $jobdir = $ENV{CLARIVE_JOBDIR} || join('/', $self->base, 'jobs' );
    $self->_ensure_path( $jobdir );
    $jobdir;
};

has pid_dir    => qw(is rw isa Str lazy 1 default), sub {
    my $self = shift;
    # PID DIR uses log dir
    my $logdir = $ENV{CLARIVE_PIDDIR} || join('/', $self->base, 'logs' );
    $self->_ensure_path( $logdir );
    $logdir;
};

sub _ensure_path {
    my($self,$dir) = @_;
    unless( -d $dir ) {
        require File::Path;
        File::Path::make_path( $dir );
    }
}

1;
