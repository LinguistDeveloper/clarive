package Clarive::Cmd::disp;
use Mouse;
use Sys::Hostname;
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'Start/Stop dispatcher';

has id         => qw(is ro default) => sub { lc( Sys::Hostname::hostname() ) };
has host       => qw(is ro default), sub { 'localhost' };
has daemon     => qw(is ro);
has restarter  => qw(is rw default) => sub { 0 };
has trace      => qw(is rw default) => sub { 0 };
has instance_name => qw(is rw);

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Daemon';
with 'Clarive::Role::Baseliner';  # yes, I run baseliner stuff

sub BUILD {
    my $self = shift;
    $self->setup_log_dir();
    $self->instance_name( 'cla-disp-'. $self->id . '-' . $self->env );
    $self->setup_pid_file();
    $self->setup_baseliner();
    
    $ENV{CLARIVE_DISPATCHER_ID} = $self->id;
}

sub run {
    goto &Clarive::Cmd::disp::run_start;
}

sub run_start {
    my ($self,%opts) = @_;
    $self->check_pid_exists();
    if( $self->daemon ) {
        say 'log_file: ' . $self->log_file;
        #$self->_log_zip( $self->log_file );
        #$self->_cleanup_logs( $self->log_file );
        $self->nohup( sub { 
            $self->bali_service( 'service.dispatcher', %opts ); 
        });
    } else {
        $self->_write_pid();
        $self->bali_service( 'service.dispatcher', %opts ); 
    }
}

#sub run_reload {
#    my ($self,%opts) = @_;
#    $self->run_stop(%opts);
#    say "Reload in progress: dispatcher will be stopped and reloaded again.";
#    my $orig_opts = $self->load_opts;
#    $self->run_start( %$orig_opts );
#}

1;

=head1 Clarive Dispatcher

Common options:

    --daemon        forks and starts the server

=cut
