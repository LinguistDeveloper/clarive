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

    my $file = $opts{patch} or die "--patch required\n";

    die "Can't open file '$file'\n" unless -f $file;

    my $home = $self->app->home;

    my $current_version = $self->_slurp_version( File::Spec->catfile( $home, 'VERSION' ) );

    my $tempdir = tempdir( CLEANUP => 1 );

    system("tar xzf '$file' -C '$tempdir'");

    my $old_version = $self->_slurp_version("$tempdir/VERSION.old");
    my $new_version = $self->_slurp_version("$tempdir/VERSION.new");

    if ( $old_version ne $current_version ) {
        die "Can't apply patch when $current_version != $old_version\n";
    }

    warn "Applying patches for '$new_version'\n" unless $opt_quiet;

    my @patches = glob "$tempdir/*patch";
    foreach my $patch (@patches) {
        my $basename = basename $patch;

        warn "Checking '$basename'...\n" unless $opt_quiet;

        my $exit_code = $self->_run_patch_cmd($patch, dry_run => 1);
        die "ERROR\n" if $exit_code;
    }

    if (!$opt_dry_run) {
        foreach my $patch (@patches) {
            my $basename = basename $patch;

            warn "Applying '$basename'...\n" unless $opt_quiet;

            my $exit_code = $self->_run_patch_cmd($patch);
            die "ERROR\n" if $exit_code;
        }
    }

    warn "Updating VERSION\n" unless $opt_quiet;

    if (!$opt_dry_run) {
        copy( File::Spec->catfile( $home, 'VERSION' ), File::Spec->catfile( $home, 'VERSION.orig' ) );
        $self->_write_version( File::Spec->catfile( $home, 'VERSION' ), $new_version );
    }

    print "Done\n";
}

sub run_rollback {
    my $self = shift;
    my (%opts) = @_;

    my $opt_dry_run = $opts{'dry-run'};
    my $opt_quiet   = $opts{'quiet'};
    my $file = $opts{patch} or die "--patch required\n";

    die "Can't open file '$file'\n" unless -f $file;

    my $home = $self->app->home;

    my $current_version = $self->_slurp_version( File::Spec->catfile( $home, 'VERSION' ) );

    my $tempdir = tempdir( CLEANUP => 1 );

    system("tar xzf '$file' -C '$tempdir'");

    my $old_version = $self->_slurp_version("$tempdir/VERSION.old");
    my $new_version = $self->_slurp_version("$tempdir/VERSION.new");

    if ( $new_version ne $current_version ) {
        die "Can't rollback patch when $current_version != $new_version\n";
    }

    warn "Rollbacking patches for '$old_version'\n" unless $opt_quiet;

    my @patches = glob "$tempdir/*patch";
    foreach my $patch (@patches) {
        my $basename = basename $patch;

        warn "Checking reverse '$basename'...\n" unless $opt_quiet;

        my $exit_code = $self->_run_patch_reverse_cmd($patch, dry_run => 1);
        die "ERROR\n" if $exit_code;
    }

    if (!$opt_dry_run) {
        foreach my $patch (@patches) {
            my $basename = basename $patch;

            warn "Applying reverse '$basename'...\n" unless $opt_quiet;

            my $exit_code = $self->_run_patch_reverse_cmd($patch);
            die "ERROR\n" if $exit_code;
        }
    }

    warn "Updating VERSION\n" unless $opt_quiet;

    if (!$opt_dry_run) {
        $self->_write_version( File::Spec->catfile( $home, 'VERSION' ), $old_version );
    }

    print "Done\n";
}

sub run_create {
    my $self = shift;
    my (%opts) = @_;

    my $opt_quiet = $opts{'quiet'};

    my $old_version = $opts{old} or die "--old required\n";
    my $new_version = $opts{new} or die "--new required\n";

    my $home = $self->app->home;

    my $diffs = $opts{diff} or die "--diff required\n";
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

    warn "Creating '$output'...\n" unless $opt_quiet;

    system("tar czf '$output' -C '$tempdir' '.'");

    print "Done\n";
}

sub _write_version {
    my $self = shift;
    my ( $file, $version ) = @_;

    open my $fh, '>', $file or die "Can't create '$file': $!";
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
    open my $fh, '<', $file or die "Can't open file '$file': $!";
    my $content = <$fh>;
    close $fh;

    return $content;
}

sub _run_patch_cmd {
    my $self = shift;
    my ($patch, %options) = @_;

    my $home = $self->app->home;

    my $dry_run = $options{'dry_run'} ? '--dry-run' : '';

    return system("cd $home; patch --batch --quiet --forward -p1 --backup $dry_run < '$patch'");
}

sub _run_patch_reverse_cmd {
    my $self = shift;
    my ($patch, %options) = @_;

    my $home = $self->app->home;

    my $dry_run = $options{'dry_run'} ? '--dry-run' : '';

    return system("cd $home; patch --batch --quiet -p1 --reverse $dry_run < '$patch'");
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

=head2 apply

Apply patch. Options:

    --patch <file>      path to a patch file
    --dry-run           dry run mode

=head2 rollback

Rollback patch. Options:

    --patch <file>      path to a patch file
    --dry-run           dry run mode

=cut
