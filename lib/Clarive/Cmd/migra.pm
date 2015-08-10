package Clarive::Cmd::migra;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Run migrations';

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Baseliner';

use Try::Tiny;
use Clarive::mdb;
use Class::Load qw(load_class);

sub run { &run_upgrade }

sub run_upgrade {
    my $self = shift;
    my (%opts) = @_;

    if ( $opts{args}->{init} ) {
        my $ok = $self->run_init(%opts);
        return unless $ok;
    }

    my $clarive = $self->_load_collection( $opts{args}->{force} ? ( no_migration_ok => 1, no_init_ok => 1 ) : () );

    die 'ERROR: It seems that the last migration did not succeed. '
      . 'Fix the issue and run migra-fix. Error is: `'
      . $clarive->{migration}->{error} . '`'
      if $clarive->{migration}->{error};

    $self->_dry_run_banner(%opts);

    my $migrations_path = $opts{args}->{path} || $self->app->home . '/lib/Baseliner/Schema/Migrations';

    opendir( my $dh, $migrations_path ) || die "ERROR: Can't opendir $migrations_path $!";
    my @migrations = sort grep { /^\d+_.*?\.pm/ && -f "$migrations_path/$_" } readdir($dh);
    closedir $dh;

    my $yes = $opts{args}->{yes} || $self->_ask_me( msg => 'Run migrations on database?' );
    return unless $yes;

    my $count = 0;
    foreach my $migration (@migrations) {
        my ( $version, $name ) = $migration =~ m/^(\d+)_(.*?)\.pm/;
        next unless $version && $name;

        next unless ( $clarive->{migration}->{version} || '' ) lt $version;

        $self->_say( "Upgrading to '$version-$name'", %opts );

        if ( !$self->_is_dry_run(%opts) ) {
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

                print "ERROR: $error\n. Exiting";
            };

            last if $error;
        }

        $count++;
    }

    $self->_say( 'Nothing to migrate', %opts ) unless $count;

    $self->_say( 'OK', %opts ) if $count;

    return 1;
}

sub run_init {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection( no_migration_ok => 1 );

    $self->_dry_run_banner(%opts);

    if ( !$opts{args}->{force} ) {
        die 'Migrations are already initialized' if $clarive->{migration} && $clarive->{migration}->{version};
    }

    $self->_say( 'Initializing migrations', %opts );

    my $yes = $opts{args}->{yes} || $self->_ask_me( msg => 'Initialize migration database?' );
    return unless $yes;

    if ( !$self->_is_dry_run(%opts) ) {
        mdb->clarive->update( { _id => $clarive->{_id} }, { '$set' => { migration => { version => '0100' } } } );
    }

    return 1;
}

sub run_fix {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection;

    $self->_dry_run_banner(%opts);

    my $yes = $opts{args}->{yes} || $self->_ask_me( msg => 'Remove error from last migration?' );
    return unless $yes;

    if ( !$self->_is_dry_run(%opts) ) {
        mdb->clarive->update( { _id => $clarive->{_id} }, { '$unset' => { 'migration.error' => '' } } );
    }

    return 1;
}

sub run_set {
    my $self = shift;
    my (%opts) = @_;

    die '--version is required' unless my $version = $opts{args}->{version};
    die '--version must be in format \d{1,4}' unless $version =~ m/^\d{1,4}$/;
    $version = sprintf '%04d', $version;

    my $clarive = $self->_load_collection;

    $self->_dry_run_banner(%opts);

    my $yes = $opts{args}->{yes} || $self->_ask_me( msg => "Set migrations version to '$version'?" );
    return unless $yes;

    if ( !$self->_is_dry_run(%opts) ) {
        mdb->clarive->update( { _id => $clarive->{_id} }, { '$set' => { 'migration.version' => $version } } );
    }

    return 1;
}

sub _say {
    my $self = shift;
    my ( $msg, %opts ) = @_;

    print "$msg\n" unless $opts{args}->{quiet};
}

sub _is_dry_run {
    my $self = shift;
    my (%opts) = @_;

    return $opts{args}->{'dry-run'};
}

sub _dry_run_banner {
    my $self = shift;
    my (%opts) = @_;

    if ( $opts{args}->{'dry-run'} ) {
        print "DRY-RUN mode. No actions are really performed\n";
    }
}

sub _ask_me {
    my $self = shift;
    my (%p) = @_;

    require Term::ReadKey;

    # flush keystrokes
    while ( defined( my $key = Term::ReadKey::ReadKey(-1) ) ) { }

    print $p{msg};
    print " [y/N/q]: ";

    unless ( ( my $yn = <STDIN> ) =~ /^y/i ) {
        exit 1 if $yn =~ /q/i;    # quit
        return 0;
    }

    return 1;
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
    --yes answer *yes* to all questions
    --dry-run don't really do anything
    --force do not perform safety checks
    --quiet be quiet

=head1 migra- subcommands:

=head2 init

Initializes the migrations

=head2 upgrade

Upgrade the migrations. Options:

    --init run initialization before migrating
    --path path to migrations instead of default

=head2 set

Manually set the latest migrations version

=head2 fix

Removes the error from last migration. Use *ONLY* when the issue is really fixed

=cut
