package Clarive::Cmd::pack;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

use Cwd qw(getcwd);
use File::Spec;
use File::Copy qw(copy);
use Capture::Tiny qw(capture_merged);

our $CAPTION = 'Pack binary distribution ready for release';

has os   => qw(is rw isa Str);
has arch => qw(is rw isa Str);
has
  version => qw(is rw isa Str lazy 1 default),
  sub {
    my $self = shift;

    return $self->_slurp_version('VERSION');
  };
has cygwin_dist  => qw(is rw isa Str);
has clarive_dist => qw(is rw isa Str);
has makensis     => qw(is rw isa Str);
has nsis         => qw(is rw isa Str);
has compile      => qw(is rw isa Bool);
has fatpack      => qw(is rw isa Bool);
has encode       => qw(is rw isa Bool);

my $BINARY_NAME = 'cla.exe';
my $BINARY_PATH = "bin/$BINARY_NAME";

$SIG{INT} = \&_cleanup;

sub run { &run_dist }

sub run_source {
    my $self = shift;
    my (%opts) = @_;

    my $dist = sprintf 'clarive_%s', $self->version;
    my $archive = "$dist.tar.gz";

    my $cmd = sprintf 'git archive --format=tar --prefix=%s/ HEAD | gzip > %s', $dist, $archive;

    warn "Packing $archive...\n";
    system($cmd);

    if ( -f $archive ) {
        print $archive, "\n";
        exit 0;
    }
    else {
        exit 1;
    }
}

sub run_dist {
    my $self = shift;
    my (%opts) = @_;

    die "Detected '$BINARY_PATH'. It is important to remove it first before running this command\n" if -f $BINARY_PATH;

    if ( !$self->os && $^O =~ m/linux/i ) {
        require Linux::Distribution;
        my $dist_name = Linux::Distribution::distribution_name() // 'generic';
        my $dist_version = eval { Linux::Distribution::distribution_version() };

        my $os = 'linux';

        if ( $dist_version && $dist_version =~ m/^(\d+(?:\.\d+)?)/ ) {
            $dist_version = $1;
        }
        else {
            $dist_version = undef;
        }
        $os .= "-$dist_name";
        $os .= "-$dist_version" if $dist_version;

        $self->os($os);
    }

    if ( !$self->arch ) {
        my $arch;
        chomp( $arch //= `uname -m` );
        $arch = lc $arch;

        $self->arch($arch);
    }

    die 'os required'   unless $self->os;
    die 'arch required' unless $self->arch;

    die "Version is required. Create VERSION file or pass --version option\n" unless $self->version;

    $self->_burp('VERSION', $self->version);

    warn sprintf "Packing for %s-%s\n", $self->os, $self->arch;

    my $base = $ENV{CLARIVE_BASE};

    my @exclude = qw(
      clarive/.git
      clarive/.gitignore
      clarive/.gitmodules
      clarive/build
      clarive/t
      clarive/tselenium
      clarive/ui-tests
      clarive/rec-tests
    );

    if ( -d '.git' ) {
        `git ls-files | sed -e 's#^#clarive/#' > MANIFEST`;
    }
    else {
        `find $base/clarive -type f | sed -e 's#^$base/##' > MANIFEST`;
    }

    if ( $self->compile || $self->encode || $self->fatpack ) {
        my @files = do { open my $fh, '<', 'MANIFEST' or die $!; <$fh> };

        @files = grep { !m{^clarive/lib/(?:Clarive|Baseliner|Girl|MVS)} } @files;

        push @files, "clarive/$BINARY_PATH\n";
        push @files, 'clarive/lib/Baseliner/I18N.pm', "\n";
        push @files, map { "clarive/$_\n" } glob 'lib/Baseliner/I18N/*.po';
        push @files, map { "clarive/$_\n" } glob 'lib/Baseliner/Schema/Migrations/*.pm';

        $self->_burp('MANIFEST', join "\n", @files);

        my $cla_cmd = $self->_slurp('bin/cla-cmd');

        open my $fh2, '>', 'bin/cla-cmd.packed';
        print $fh2 <<'EOF';
        BEGIN {
        unshift @INC, sub {
            my ($coderef, $filename) = @_;

            my ($fatpacker) = grep { ref($_) && ref($_) =~ m/FatPack/ } @INC;

            if (my $module = $fatpacker->{$filename}) {
                my ($line, $code) = split /\r?\n/, $module, 2;
                $code = pack 'H*', $code;

                $code =~ s/^  //mg;
                $code =~ s{.$}{};

                $module = $line . "\n" . $code;

                open my $fh, '<', \$module;
                return $fh;
            }

            return;
        };
        }

        #================================
        package main;
EOF
        print $fh2 $cla_cmd;
        close $fh2;

        print 'Fatpacking';
        $self->_execute("cla exec fatpack-simple bin/cla-cmd.packed lib -o $BINARY_PATH");

        my $packed = $self->_slurp($BINARY_PATH);

        my @exceptions = ( qr{Baseliner\/I18N\.pm}, qr{Baseliner\/Schema\/Migrations\/.*?\.pm} );
        for my $exception (@exceptions) {
            no warnings 'uninitialized';

            $packed =~ s{\$fatpacked\{"$exception"\}.*?(?=\$fatpacked)}{}gmse;
        }

        $self->_burp($BINARY_PATH, $packed);

        if ( $self->compile || $self->encode ) {
            my $packed = $self->_slurp($BINARY_PATH);

            warn "Encoding...\n";
            $packed =~ s{<<'(.*?)';\n(.*?)\n\1}{"<<'$1';\n" . _encode($2) . "\n$1"}gmse;

            $self->_burp($BINARY_PATH, $packed);

            if ( $self->compile ) {
                warn "Compiling...\n";

                my ( $output, $exit_code ) = capture_merged {
                    system qq{cla exec perlcc $BINARY_PATH};
                };

                if ($exit_code) {
                    die "ERROR: Compiling aborted due to perlcc error: $output\n";
                }
            }
        }
    }

    `find $base/local -type f | sed -e 's#^$base/##' >> MANIFEST`;
    `echo 'clarive/VERSION' >> MANIFEST`;

    my $dist = sprintf 'clarive_%s_%s-%s', $self->version, $self->os, $self->arch;

    print "Archiving '$dist'";

    my $destdir = "/tmp/";
    mkdir $destdir;

    my $final_archive_path;
    if ( $self->os =~ m/windows|cygwin/i ) {
        my $archive = "$dist.zip";
        my $archive_path = File::Spec->catfile( $destdir, $archive );
        unlink $archive_path;

        my $exclude_str = join ' ', map { "clarive/$_" } @exclude;
        $exclude_str = '--exclude ' . $exclude_str if $exclude_str;

        my $cmd = sprintf q{cd ..; cat clarive/MANIFEST | zip -@ %s %s; cd -}, $archive_path, $exclude_str;
        $self->_execute( $cmd, every => 100 );

        $final_archive_path = $archive_path;
    }
    else {
        my $archive = "$dist.tar.gz";
        my $archive_path = File::Spec->catfile( $destdir, $archive );
        unlink $archive_path;

        my $exclude_str = join ' ', map { "--exclude '$_'" } @exclude;

        my $cmd = sprintf q{cat MANIFEST | tar -C %s --transform 's#^#%s/#' %s -cvzf %s --files-from=-}, $base, $dist,
          $exclude_str, $archive_path;

        $self->_execute( $cmd, every => 100 );

        $final_archive_path = $archive_path;
    }

    _cleanup();

    if ( -f $final_archive_path ) {
        print $final_archive_path, "\n";
        exit 0;
    }
    else {
        print 'ERROR', "\n";
        exit 1;
    }
}

sub run_nsi {
    my $self = shift;

    for (qw/cygwin clarive/) {
        my $method = "${_}_dist";

        die "$method required" unless $self->$method;
        die "$method must be a .zip file" unless -f $self->$method && $self->$method =~ m/\.zip$/;
    }

    if ( $self->nsis ) {
        die "nsis does not exist" unless -f $self->nsis;

        system( sprintf "unzip %s", $self->nsis );
        $self->makensis("NSIS/makensis.exe");
    }
    elsif ( $self->makensis ) {
        die "makensis does not exist" unless -f $self->makensis;
    }
    else {
        die "Either path to nsis.zip or path to makensis.exe should be present";
    }

    my $template = do { local $/; open my $fh, '<', "data/nsi/clarive.nsi.template" or die $!; <$fh> };

    my $version      = $self->version;
    my $cygwin_dist  = $self->cygwin_dist;
    my $clarive_dist = $self->clarive_dist;

    chomp( $cygwin_dist  = `cygpath -w $cygwin_dist` );
    chomp( $clarive_dist = `cygpath -w $clarive_dist` );

    my ($cygwin_dist_basename)  = $cygwin_dist =~ m/([^\\\/]+)$/;
    my ($clarive_dist_basename) = $clarive_dist =~ m/([^\\\/]+)$/;

    copy( $cygwin_dist,  $cygwin_dist_basename );
    copy( $clarive_dist, $clarive_dist_basename );

    $template =~ s{## VERSION ##}{$version}g;
    $template =~ s{## CYGWIN_DIST ##}{$cygwin_dist_basename}g;
    $template =~ s{## CLARIVE_DIST ##}{$clarive_dist_basename}g;

    open my $fh, '>', 'clarive.nsi' or die $!;
    print $fh $template;
    close $fh;

    system("cat LICENSE THIRD-PARTY-NOTICES >> LICENSE.merged");
    system( $self->makensis, 'clarive.nsi' );

    my $final_archive_path = "clarive_${version}_setup.exe";

    if ( -f $final_archive_path ) {
        print $final_archive_path, "\n";
        exit 0;
    }
    else {
        print 'ERROR', "\n";
        exit 1;
    }
}

sub _encode {
    my ($body) = @_;

    return unpack 'H*', $body;
}

sub _slurp_version {
    my $self = shift;
    my ($file) = @_;

    my $version = $self->_slurp($file);

    $version =~ s{\s+}{}gms;

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

sub _burp {
    my $self = shift;
    my ($file, $content) = @_;

    open my $fh, '>', $file or die "Can't open '$file': $!";
    print $fh $content;
    close $fh;
}

sub _cleanup {
    warn "Cleanup\n";

    unlink $BINARY_PATH;
    unlink 'MANIFEST';
    unlink 'bin/cla-cmd.packed';
}

sub _execute {
    my $self = shift;
    my ( $cmd, %params ) = @_;

    my $every = $params{every} || 10;

    open my $fh, "$cmd 2>&1 |" or die "Can't start '$cmd' command: $!";
    my $line = 0;
    while (<$fh>) {
        print '.' if $line % $every == 0;
        $line++;
    }
    print "DONE\n";
    close $fh;
}

1;
__END__

=head1 Pack

Common options:

    --os        use this OS in archive (detected automatically)
    --arch      use this ARCH in archive (detected automatically)
    --version   use this VERSION in archive (detected automatically)

=head1 pack- subcommands:

=head2 source

Pack the sources.

=head2 dist

Pack the distribution (default). Options:

    --fatpack      fatpack sources
    --encode       encode sources (includes fatpacking)
    --compile      compile sources (includes fatpacking & encoding)

=head2 nsi

Build windows intallable binary. Options:

    --makensis      path to makensis.exe
    --nsis          path to nsis distribution
    --cygwin_dist   path to cygwin distribution
    --clarive_dist  path to Clarive distribution

=cut
