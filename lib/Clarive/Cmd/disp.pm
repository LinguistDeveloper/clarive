package Clarive::Cmd::disp;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'Start/Stop dispatcher';

has env        => qw(is ro default) => sub { 'local' };
has host       => qw(is ro default), sub { 'localhost' };
has daemon     => qw(is ro);
has restarter  => qw(is rw default) => sub { 0 };
has trace      => qw(is rw default) => sub { 0 };

has log_file      => qw(is rw lazy 1 default), sub { $_[0]->tmp_dir . '/' . $_[0]->instance_name . '.log' };
has log_keep      => qw(is rw default) => sub { 10 };
has id            => qw(is ro default) => sub { 'cla-disp' };
has instance_name => qw(is rw);

with 'Clarive::Role::Daemon';
with 'Clarive::Role::Baseliner';  # yes, I run baseliner stuff

sub BUILD {
    my $self = shift;
    $self->setup_log_dir();
    $self->instance_name( $self->id );
    $self->setup_pid_file();
    $self->setup_baseliner();
}

sub run_start {
    my ($self,%opts) = @_;
    $self->check_pid_exists();
    if( $self->daemon ) {
        say 'log_file: ' . $self->log_file;
        $self->_log_zip( $self->log_file ); 
        $self->_cleanup_logs( $self->log_file ); 
        $self->nohup( sub { 
            $self->bali_service( 'service.dispatcher', %opts ); 
        });
    } else {
        $self->_write_pid();
        $self->bali_service( 'service.dispatcher', %opts ); 
    }
}

1;
