package Clarive::Role::CheckMigrations;
use Mouse::Role;

has skip_migration_check  => qw(is ro isa Bool default 0);

sub check_migrations {
    my $self = shift;

    if( $self->skip_migration_check ) {
        warn "WARN: Migrations skipped on user request\n";
        return;
    }

    require Clarive::Cmd::migra;
    my $migra = Clarive::Cmd::migra->new( app => $self->app, env => $self->env, opts => {} );

    my $check = $migra->check;

    my $is_empty = 0;

    if (my $clarive = mdb->clarive->find_one) {
        $is_empty = $clarive->{empty} ? 1 : 0;

        if ($is_empty) {
            mdb->clarive->update( { _id => $clarive->{_id} }, { '$unset' => { 'empty' => '' } } );
        }
    }

    if ($check) {
        if ( $self->opts->{args}->{migrate} ) {
            $migra->run;
        }
        elsif ( $self->opts->{args}->{'migrate-yes'} || $is_empty ) {
            $migra->run(args => {yes => 1});
        }
        else {
            die "ERROR: Migrations are not up to date. Run with --migrate flag or use migra- commands\n";
        }
    }
}

1;
