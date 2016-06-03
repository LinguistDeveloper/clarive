package Clarive::Cmd::patch;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

use File::Basename qw(basename);
use File::Temp qw(tempdir);
use File::Copy qw(copy);

our $CAPTION = 'Create/Apply/Rollback patches';

sub run { &run_apply }

sub run_apply {
    my $self = shift;
    my (%opts) = @_;

    my $opt_dry_run = $opts{'dry-run'};
    my $opt_quiet   = $opts{'quiet'};

    $self->_dry_run_banner if $opt_dry_run && !$opt_quiet;

    my $file = $opts{patch} or $self->_error("--patch required");

    $self->_error("Can't open file '$file'") unless -f $file;
    $self->_error("File '$file' is not a tar.gz file") unless $file =~ m/\.(tar\.gz|tgz)/;

    my $home = $self->app->home;

    my $current_version = $self->_slurp_version( File::Spec->catfile( $home, 'VERSION' ) );

    my $tempdir = tempdir( CLEANUP => 1 );

    system("tar xzf '$file' -C '$tempdir'");

    my $old_version = $self->_slurp_version("$tempdir/VERSION.old");
    my $new_version = $self->_slurp_version("$tempdir/VERSION.new");

    if ( $old_version ne $current_version ) {
        $self->_error("Can't apply patch when $current_version != $old_version");
    }

    $self->_log( "Applying patches for '$new_version'", \%opts );

    my @patches = glob "$tempdir/*patch";
    foreach my $patch (@patches) {
        my $basename = basename $patch;

        $self->_log( "Checking '$basename'...", \%opts );

        my $exit_code = $self->_run_patch_cmd( $patch, dry_run => 1 );
        $self->_error("Patch failed") if $exit_code;
    }

    if ( !$opt_dry_run ) {
        foreach my $patch (@patches) {
            my $basename = basename $patch;

            $self->_log( "Applying '$basename'...", \%opts );

            my $exit_code = $self->_run_patch_cmd($patch);
            $self->_error("Patch failed") if $exit_code;
        }
    }

    $self->_log( "Updating VERSION", \%opts );

    if ( !$opt_dry_run ) {
        copy( File::Spec->catfile( $home, 'VERSION' ), File::Spec->catfile( $home, 'VERSION.orig' ) );
        $self->_write_version( File::Spec->catfile( $home, 'VERSION' ), $new_version );
    }

    $self->_log( "Done", \%opts );
}

sub run_rollback {
    my $self = shift;
    my (%opts) = @_;

    my $opt_dry_run = $opts{'dry-run'};
    my $opt_quiet   = $opts{'quiet'};
    my $file        = $opts{patch} or $self->_error("--patch required");

    $self->_dry_run_banner if $opt_dry_run && !$opt_quiet;

    $self->_error("Can't open file '$file'") unless -f $file;
    $self->_error("File '$file' is not a tar.gz file") unless $file =~ m/\.(tar\.gz|tgz)/;

    my $home = $self->app->home;

    my $current_version = $self->_slurp_version( File::Spec->catfile( $home, 'VERSION' ) );

    my $tempdir = tempdir( CLEANUP => 1 );

    system("tar xzf '$file' -C '$tempdir'");

    my $old_version = $self->_slurp_version("$tempdir/VERSION.old");
    my $new_version = $self->_slurp_version("$tempdir/VERSION.new");

    if ( $new_version ne $current_version ) {
        $self->_error("Can't rollback patch when $current_version != $new_version");
    }

    $self->_log( "Rollbacking patches for '$old_version'", \%opts );

    my @patches = glob "$tempdir/*patch";
    foreach my $patch (@patches) {
        my $basename = basename $patch;

        $self->_log( "Checking reverse '$basename'...", \%opts );

        my $exit_code = $self->_run_patch_reverse_cmd( $patch, dry_run => 1 );
        $self->_error("Patch failed") if $exit_code;
    }

    if ( !$opt_dry_run ) {
        foreach my $patch (@patches) {
            my $basename = basename $patch;

            $self->_log( "Applying reverse '$basename'...", \%opts );

            my $exit_code = $self->_run_patch_reverse_cmd($patch);
            $self->_error("Patch failed") if $exit_code;
        }
    }

    $self->_log( "Updating VERSION", \%opts );

    if ( !$opt_dry_run ) {
        $self->_write_version( File::Spec->catfile( $home, 'VERSION' ), $old_version );
    }

    $self->_log( "Done", \%opts );
}

sub run_create {
    my $self = shift;
    my (%opts) = @_;

    my $opt_quiet = $opts{'quiet'};

    my $old_version = $opts{old} or $self->_error("--old required");
    my $new_version = $opts{new} or $self->_error("--new required");

    my $home = $self->app->home;

    my $diffs = $opts{diff} or $self->_error("--diff required");
    $diffs = [$diffs] unless ref $diffs eq 'ARRAY';

    my $tempdir = tempdir( CLEANUP => 1 );

    my $count = 1;
    foreach my $diff (@$diffs) {
        my $filename = sprintf "%04d.patch", $count;

        copy $diff, "$tempdir/$filename";

        $count++;
    }

    $self->_write_version( "$tempdir/VERSION.old", $old_version );
    $self->_write_version( "$tempdir/VERSION.new", $new_version );

    my $output = $opts{output} || "clarive_$old_version-$new_version.patch.tar.gz";

    $self->_log( "Creating '$output'...", \%opts );

    system("tar czf '$output' -C '$tempdir' '.'");

    $self->_log( "Done", \%opts );
}

sub _write_version {
    my $self = shift;
    my ( $file, $version ) = @_;

    open my $fh, '>', $file or $self->_error("Can't create '$file': $!");
    print $fh "$version\n";
    close $fh;
}

sub _slurp_version {
    my $self = shift;
    my ($file) = @_;

    my $version = $self->_slurp($file);

    $version =~ s{\s+}{}g;

    return $version;
}

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    local $/;
    open my $fh, '<', $file or $self->_error("Can't open file '$file': $!");
    my $content = <$fh>;
    close $fh;

    return $content;
}

sub _run_patch_cmd {
    my $self = shift;
    my ( $patch, %options ) = @_;

    my $home = $self->app->home;

    my $dry_run = $options{'dry_run'} ? '--dry-run' : '';

    return system("cd $home; patch --batch --quiet --forward -p1 --backup $dry_run < '$patch'");
}

sub _run_patch_reverse_cmd {
    my $self = shift;
    my ( $patch, %options ) = @_;

    my $home = $self->app->home;

    my $dry_run = $options{'dry_run'} ? '--dry-run' : '';

    return system("cd $home; patch --batch --quiet -p1 --reverse $dry_run < '$patch'");
}

sub _dry_run_banner {
    my $self = shift;

    warn "DRY RUN: Not actually updating anything\n\n";
}

sub _log {
    my $self = shift;
    my ( $message, $options ) = @_;

    return if $options->{quiet};

    my $prefix = '';

    if ( $options->{'dry-run'} ) {
        $prefix = 'DRY RUN: ';
    }

    warn "$prefix$message\n";
}

sub _error {
    my $self = shift;
    my ($message) = @_;

    die "Error: $message\n";
}

1;
__END__

=head1 Patch

Create/Apply/Rollback patches.

=head1 patch- subcommands:

=head2 create

Create patch. Options:

    --old <num>         old version
    --new <num>         new version
    --diff <file>       path to a diff file (multiple values are allowed)
    --output <file>     output file (optional)
    --quiet             be quiet

=head2 apply

Apply patch. Options:

    --patch <file>      path to a patch file
    --dry-run           dry run mode (not actually updating anything)
    --quiet             be quiet

=head2 rollback

Rollback patch. Options:

    --patch <file>      path to a patch file
    --dry-run           dry run mode (not actually updating anything)
    --quiet             be quiet

=cut
