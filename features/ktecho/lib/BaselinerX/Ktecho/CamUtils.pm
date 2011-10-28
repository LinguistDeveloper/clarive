package BaselinerX::Ktecho::CamUtils;
use BaselinerX::Ktecho::Utils;
use Switch;
use Exporter::Tidy default => [
  qw( inf
    tiene_java
    entornos
    public
    tiene_ante
    sub_apps )
];

sub inf { return BaselinerX::Model::InfUtil->new(cam => shift) }

sub tiene_java { inf(shift)->tiene_java }

sub entornos { @{inf(shift)->entornos} }

sub public { inf(shift)->is_public_bool }

sub tiene_ante { inf(shift)->tiene_ante }

sub sub_apps {
  # Returns an array of every sub-application (java + .net)
  # for a given CAM.
  my $cam       = shift;
  my $nat       = shift || '';
  my $inf       = inf $cam;
  my @subs_java = @{$inf->sub_apps_java};
  my @subs_net  = @{$inf->sub_apps_net};
  my @xs;
  switch ($nat) {
    case /java/xi { @xs = @subs_java }
    case /net/xi  { @xs = @subs_net }
    else {
      my @sub_apps = @{$inf->sub_apps_java};
      push @sub_apps, @{$inf->sub_apps_net} if @subs_net;
      @xs = @sub_apps;
    }
  }
  wantarray ? @xs : \@xs;
}

1;

