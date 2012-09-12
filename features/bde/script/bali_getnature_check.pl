use strict;
use warnings;
use 5.010;
use FindBin;
use Data::Dumper;
use lib "$FindBin::Bin/../lib";
require Baseliner;
use Baseliner::Utils;

## Get the packages from user input.
my @packages = @ARGV;
my @projects = qw/SCT SCM/;            # TODO Get from first level of BALI_PROJECT

sub filter_path {
  my ($path, @projects) = @_;
  my @ls = _pathxs $path;
  while (my $current = shift @ls) {
    return join '/', @ls if $current ~~ @projects;
  }
}

say "Obteniendo identificadores de los paquetes " . (join ', ', @packages);
my $rs = Baseliner->model('Harvest::Harpackage')->search({packagename => [@packages]}, {select => 'packageobjid'});
rs_hashref($rs);
my @packageobjids = map { $_->{packageobjid} } $rs->all;

say "Obteniendo naturalezas...";
$rs = Baseliner->model('Harvest::Harversions')->search({packageobjid => [@packageobjids]}, {select => 'clientpath'});
rs_hashref($rs);
my @natures = map { _pathxs $_, 0 }              # Get only the nature
              map { filter_path $_, @projects }  # Trim the path, starting with the nature
              map { $_->{clientpath} }
              $rs->all;

say "Naturalezas del pase: " . (join ', ', @natures);