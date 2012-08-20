package BaselinerX::Controller::Temp;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Ktecho::Utils;
use BaselinerX::Ktecho::CamUtils;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

sub test : Path {
  my ($self, $c) = @_;
  $c->model('Temp')->load();
  return;
}

1;
