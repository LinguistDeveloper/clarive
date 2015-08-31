package Clarive::Cmd::migra;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION         = 'Run migrations';
our $DEFAULT_VERSION = '0099';

with 'Clarive::Role::EnvRequired';
with 'Clarive::Role::Baseliner';

use Try::Tiny;
use Capture::Tiny qw(capture);
use Clarive::mdb;
use Class::Load qw(load_class);

sub run { &run_start }

sub run_start {
    my $self = shift;
    my (%opts) = @_;

    if ( $opts{args}->{init} ) {
        my $ok = $self->run_init(%opts);
        return unless $ok;
    }

    my $clarive = $self->_load_collection( $opts{args}->{force} ? ( no_migration_ok => 1, no_init_ok => 1 ) : () );

    $self->_dry_run_banner(%opts);

    my @migrations = $self->_load_migrations(%opts);

    my $current_version = $clarive->{migration}->{version} || $DEFAULT_VERSION;
    my $newest_local_migration = $migrations[-1];

    my $migration_direction = $self->_migration_direction( $current_version, $newest_local_migration );

    if ($migration_direction) {
        if ( $migration_direction > 0 ) {
            my $yes = $opts{args}->{yes} || $self->_ask_me( msg => 'Database needs un upgrade. Run migrations?' );
            return unless $yes;

            my @upgrade_migrations = grep { $_->{version} gt $current_version } @migrations;

            $self->_upgrade( $clarive, \@upgrade_migrations, %opts );
        }
        elsif ( $migration_direction < 0 ) {
            my $yes = $opts{args}->{yes} || $self->_ask_me( msg => 'Database needs a downgrade. Run migrations?' );
            return unless $yes;

            $self->_downgrade( $clarive, $newest_local_migration, %opts );
        }
    }
    else {
        $self->_say( 'Nothing to migrate', %opts );
        return 1;
    }

    $self->_say( 'OK', %opts );

    return 1;
}

sub check {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection;

    my @migrations = $self->_load_migrations(%opts);

    my $current_version = $clarive->{migration}->{version} || $DEFAULT_VERSION;
    my $newest_local_migration = $migrations[-1];

    return $self->_migration_direction( $current_version, $newest_local_migration );
}

sub _migration_direction {
    my $self = shift;
    my ( $current_version, $newest_local ) = @_;

    if ( $newest_local->{version} gt $current_version ) {
        return 1;
    }
    elsif ( $newest_local->{version} lt $current_version ) {
        return -1;
    }
    else {
        return 0;
    }
}

sub _load_migrations {
    my $self = shift;
    my (%opts) = @_;

    my $migrations_path = $opts{args}->{path} || $self->app->home . '/lib/Baseliner/Schema/Migrations';

    opendir( my $dh, $migrations_path ) || die "ERROR: Can't opendir '$migrations_path': $!";
    my @migrations;
    foreach my $file ( sort readdir($dh) ) {
        next unless -f "$migrations_path/$file" && $file =~ /^(\d+)_(.*?)\.pm/;

        push @migrations,
          {
            version => $1,
            name    => $2,
            file    => "$migrations_path/$file"
          };
    }
    closedir $dh;

    return @migrations;
}

sub _upgrade {
    my $self = shift;
    my ( $clarive, $migrations, %opts ) = @_;

    foreach my $migration (@$migrations) {
        my $version = $migration->{version};
        my $name    = $migration->{name};
        my $file    = $migration->{file};

        $self->_say( "Upgrading to '$version-$name'", %opts );

        next if $self->_is_dry_run(%opts);

        my $error;
        try {
            my ( $package, $code ) = $self->_compile_migration_from_file($file);

            capture {
                $package->new->upgrade;
            };

            mdb->clarive->update(
                { _id => $clarive->{_id} },
                {
                    '$set'  => { 'migration.version' => $version },
                    '$push' => { 'migration.patches' => { version => $version, name => $name, code => $code } }
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
}

sub _downgrade {
    my $self = shift;
    my ( $clarive, $newest_local_migration, %opts ) = @_;

    my @downgrade_migrations =
      reverse grep { $_->{version} gt $newest_local_migration->{version} } @{ $clarive->{migration}->{patches} };

    if ( !@downgrade_migrations ) {
        die 'Downgrade is needed, but no patches were found';
    }

    for ( my $i = 0 ; $i < @downgrade_migrations ; $i++ ) {
        my $migration = $downgrade_migrations[$i];

        my $version = $migration->{version};
        my $name    = $migration->{name};
        my $file    = $migration->{file};

        $self->_say( "Downgrading to '$version-$name'", %opts );

        next if $self->_is_dry_run(%opts);

        my $error;
        try {
            my $code = $migration->{code};
            die "No code found in patch '$migration->{version} $migration->{name}'" unless $code;

            my $package = $self->_compile_migration($code);

            capture {
                $package->new->downgrade;
            };

            my $prev_version =
              $i + 1 < @downgrade_migrations ? $downgrade_migrations[ $i + 1 ] : $newest_local_migration->{version};

            mdb->clarive->update(
                { _id => $clarive->{_id} },
                {
                    '$set' => { 'migration.version' => $prev_version },
                    '$pop' => { 'migration.patches' => 1 }
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
        mdb->clarive->update( { _id => $clarive->{_id} },
            { '$set' => { migration => { version => $DEFAULT_VERSION } } } );
    }

    return 1;
}

sub run_fix {
    my $self = shift;
    my (%opts) = @_;

    my $clarive = $self->_load_collection( error_ok => 1 );

    $self->_dry_run_banner(%opts);
    my $doc = mdb->clarive->find_one({ _id => $clarive->{_id} });
    $self->_say( length $doc->{migration}{error} ? "Last error: $doc->{migration}{error}" : "(no error)" ); 

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

sub run_specific {
    my $self = shift;
    my (%opts) = @_;

    die '--name is required' unless my $name = $opts{args}->{name};

    $self->_dry_run_banner(%opts);

    my $migrations_path = $opts{args}->{path} || $self->app->home . '/lib/Baseliner/Schema/Migrations';
    my $migration_path = "$migrations_path/$name.pm";

    die "Cannot find migration with name '$name'" unless -f $migration_path;

    my $direction = $opts{args}->{downgrade} ? 'downgrade' : 'upgrade';

    my $yes =
      $opts{args}->{yes} || $self->_ask_me( msg => "Are you sure you want to _${direction}_ '$name' migration?" );
    return unless $yes;

    my ( $migration, $code ) = $self->_compile_migration_from_file($migration_path);

    if ( !$self->_is_dry_run(%opts) ) {
        $migration->new->$direction;
    }

    $self->_say( 'OK', %opts );

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

sub _compile_migration_from_file {
    my $self = shift;
    my ($path) = @_;

    my $code = do { local $/; open my $fh, '<', $path or die $!; <$fh> };

    my ($package) = $code =~ m/^\s*package\s*(.*?);/ms;

    capture {
        require $path;
    };

    return ( $package, $code );
}

sub _compile_migration {
    my $self = shift;
    my ($code) = @_;

    my ($package) = $code =~ m/^\s*package\s*(.*?);/ms;

    eval $code or die $@;

    return $package;
}

sub _load_collection {
    my $self = shift;
    my (%params) = @_;

    my $clarive = mdb->clarive->find_one;

    die 'ERROR: System not initialized' unless $params{no_init_ok} || $clarive;
    die 'ERROR: Migrations are not initialized. Run migra-init first'
      unless $params{no_migration_ok} || $clarive->{migration};

    unless ( $params{error_ok} ) {
        die 'ERROR: It seems that the last migration did not succeed. '
          . 'Fix the issue and run migra-fix. Error is: `'
          . $clarive->{migration}->{error} . '`'
              if $clarive->{migration}->{error};
    }

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

=head2 start

Upgrade/Downgrade the migrations. Options:

    --init run initialization before migrating
    --path path to migrations instead of default

=head2 set

Manually set the latest migrations version

    --version the version to be set

=head2 fix

Removes the error from last migration. Use *ONLY* when the issue is really fixed

=head2 specific

Upgrade/Downgrade manually by passing the migration name (upgrade by default). Options:

    --name name of the migration
    --downgrade run downgrade instead of upgrading

=cut
