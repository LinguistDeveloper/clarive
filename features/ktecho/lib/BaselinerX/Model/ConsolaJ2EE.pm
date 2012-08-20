package BaselinerX::Model::ConsolaJ2EE;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Ktecho::CamUtils;
use utf8;
BEGIN { extends 'Catalyst::Model' }

### get_list_of_cams : -> ArrayRef[Str]
sub get_list_of_cams {
  my $args = {select => {distinct => 'cam'}, as => 'cam'};
  my $rs = Baseliner->model('Inf::InfForm')->search(undef, $args);
  rs_hashref($rs);
  my @cams = $rs->all;
  \@cams;
}

### get_sub_appl : Str -> ArrayRef[HashRef]
sub get_sub_appl {
  my ($self, $cam) = @_;
  my @data = map +{sub_appl => $_}, sub_apps $cam, 'java';
  \@data;
}

### get_entornos : Str -> ArrayRef[HashRef]
sub get_entornos {
  my ($self, $cam) = @_;
  my $inf = inf $cam;
  [{test => $inf->tiene_test,
    ante => $inf->tiene_ante,
    prod => $inf->tiene_prod}];
}

1;
