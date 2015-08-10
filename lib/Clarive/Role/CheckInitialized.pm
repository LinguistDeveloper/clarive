package Clarive::Role::CheckInitialized;
use Mouse::Role;

sub check_initialized {
    my $self = shift;

    require Clarive::Cmd::init;
    my $init = Clarive::Cmd::init->new( app => $self->app, env => $self->env, opts => {} );

    my $check = $init->check;

    if ( !$check ) {
        if ( $self->opts->{args}->{init} ) {
            $init->run;
        }
        else {
            die "ERROR: System is not initialized. Run with --init flag or use init command\n";
        }
    }
}

1;
