package Clarive::Cmd::pack;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

use Cwd qw(getcwd);
use File::Spec;

our $CAPTION = 'Pack';

has os   => qw(is rw isa Str);
has arch => qw(is rw isa Str);
has
  version => qw(is rw isa Str lazy 1 default),
  sub {
    my $self = shift;

    return $self->_slurp('VERSION');
  };

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

    if (!$self->arch) {
        my $arch;
        chomp( $arch //= `uname -m` );
        $arch = lc $arch;

        $self->arch($arch);
    }

    die 'os required'   unless $self->os;
    die 'arch required' unless $self->arch;

    warn sprintf "Packing for %s-%s...\n", $self->os, $self->arch;

    my $base = $ENV{CLARIVE_BASE};

    my @exclude = qw(
      clarive/.git
      clarive/.gitignore
      clarive/.gitmodules
      clarive/build
      clarive/t
      clarive/ui-tests
      clarive/rec-tests
    );
    my $exclude_str = join ' ', map { "--exclude '$_'" } @exclude;

    if (-d '.git') {
        `git ls-files | sed -e 's#^#clarive/#' > MANIFEST`;
    }
    else {
        `find $base/clarive -type f | sed -e 's#^$base/##' > MANIFEST`;
    }

    `find $base/local -type f | sed -e 's#^$base/##' >> MANIFEST`;
    `echo 'stew.snapshot' >> MANIFEST`;
    `echo 'clarive/VERSION' >> MANIFEST`;

    my $dist = sprintf 'clarive_%s_%s-%s', $self->version, $self->os, $self->arch;

    my $destdir = "/tmp/";
    mkdir $destdir;

    my $final_archive_path;
    if ($self->os =~ m/windows|cygwin/i) {
        my $archive = "$dist.zip";
        my $archive_path = File::Spec->catfile( $destdir, $archive );
        unlink $archive_path;

        my $cmd = sprintf q{cd ..; cat clarive/MANIFEST | zip -@ %s %s; cd -}, $dist,
          $exclude_str;
        system($cmd);

        $final_archive_path = $archive_path;
    }
    else {
        my $archive = "$dist.tar.gz";
        my $archive_path = File::Spec->catfile( $destdir, $archive );
        unlink $archive_path;

        my $cmd = sprintf q{cat MANIFEST | tar -C %s --transform 's#^#%s/#' %s -czf %s --files-from=-}, $base, $dist,
          $exclude_str, $archive_path;
        system($cmd);

        $final_archive_path = $archive_path;
    }

    if ( -f $final_archive_path ) {
        print $final_archive_path, "\n";
        exit 0;
    }
    else {
        exit 1;
    }
}

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    local $/;
    open my $fh, '<', $file or die "Can't open VERSION file '$file': $!";
    my $version = <$fh>;
    close $fh;

    $version =~ s{\s+}{}g;

    return $version;
}

1;
__END__

=head1 Pack

Common options:

=cut
