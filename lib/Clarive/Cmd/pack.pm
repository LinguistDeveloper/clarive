package Clarive::Cmd::pack;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

use Cwd qw(getcwd);
use File::Spec;

our $CAPTION = 'Pack';

has os   => qw(is rw isa Str required 1);
has arch => qw(is rw isa Str required 1);
has
  version => qw(is rw isa Str lazy 1 default),
  sub {
    my $self = shift;

    return $self->_slurp('VERSION');
  };

sub run { &run_dist }

sub run_dist {
    my $self = shift;
    my (%opts) = @_;

    my $dist = sprintf 'clarive_%s_%s-%s', $self->version, $self->os, $self->arch;
    my $archive = "$dist.tar.gz";

    my $base = $ENV{CLARIVE_BASE};

    my $destdir = "/tmp/";
    mkdir $destdir;

    my $archive_path = File::Spec->catfile($destdir, $archive);
    unlink $archive_path;

    my @sources = ("$base/local", "$base/clarive");
    my $cmd = sprintf 'tar czf %s ', $archive_path;
    $cmd .= " $_" for @sources;

    system($cmd);

    if (-f $archive_path) {
        print $archive_path, "\n";
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
