package Clarive::Cmd::migra;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Run migrations';

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Baseliner';

use Try::Tiny;
use Clarive::mdb;
use Class::Load qw(load_class);

sub run {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection( $opts{'--force'} ? ( no_migration_ok => 1, no_init_ok => 1 ) : () );

    die 'ERROR: It seems that the last migration did not succeed. '
      . 'Fix the issue and run migra-fix. Error is: `'
      . $clarive->{migration}->{error} . '`'
      if $clarive->{migration}->{error};

    my $migrations_path = $opts{'--path'} || $self->app->home . '/lib/Baseliner/Schema/Migrations';

    opendir( my $dh, $migrations_path ) || die "can't opendir $migrations_path $!";
    my @migrations = sort grep { /^\d+_.*?\.pm/ && -f "$migrations_path/$_" } readdir($dh);
    closedir $dh;

    foreach my $migration (@migrations) {
        my ( $version, $name ) = $migration =~ m/^(\d+)_(.*?)\.pm/;
        next unless $version && $name;

        next unless ( $clarive->{migration}->{version} || '' ) lt $version;

        my $error;
        try {
            my ( $package, $code ) = $self->_compile_migration("$migrations_path/$migration");

            $package->new->upgrade;

            mdb->clarive->update(
                { _id => $clarive->{_id} },
                {
                    '$set'  => { 'migration.version' => $version },
                    '$push' => { 'migration.patches' => { version => $version, name => $name } }
                }
            );
        }
        catch {
            $error = shift;

            mdb->clarive->update( { _id => $clarive->{_id} }, { '$set' => { 'migration.error' => $error } } );
        };

        last if $error;
    }

    return 1;
}

sub run_init {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection( no_migration_ok => 1 );

    mdb->clarive->update( { _id => $clarive->{_id} }, { '$set' => { migration => { version => '0100' } } } );
}

sub run_fix {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection;

    mdb->clarive->update( { _id => $clarive->{_id} }, { '$unset' => { 'migration.error' => '' } } );
}

sub _compile_migration {
    my $self = shift;
    my ($path) = @_;

    my $code = do { local $/; open my $fh, '<', $path or die $!; <$fh> };
    my ($package) = $code =~ m/^\s*package\s*(.*?);/ms;

    require $path;

    return ( $package, $code );
}

sub _load_collection {
    my $self = shift;
    my (%params) = @_;

    my $clarive = mdb->clarive->find_one;

    die 'ERROR: System not initialized' unless $params{no_init_ok} || $clarive;
    die 'ERROR: Migrations are not initialized. Run migra-init first'
      unless $params{no_migration_ok} || $clarive->{migration};

    return $clarive;
}

1;
__END__

=head1 Run migrations

Common options:

    --env <environment>
    --force do not perform safety checks

=head1 migra- subcommands:

=cut
