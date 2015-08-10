package Clarive::Role::CheckMigrations;
use Mouse::Role;

sub check_migrations {
    my $self = shift;

    require Clarive::Cmd::migra;
    my $migra = Clarive::Cmd::migra->new( app => $self->app, env => $self->env, opts => {} );

    my $check = $migra->check;

    if ($check) {
        if ( $self->opts->{args}->{migrate} ) {
            $migra->run;
        }
        else {
            die "ERROR: Migrations are not up to date. Run with --migrate flag or use migra- commands\n";
        }
    }
}

1;
