package BaselinerX::Controller::CargaLdif;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Data::Dumper;
use Net::FTP;
use Try::Tiny;
use utf8;
BEGIN { extends 'Catalyst::Controller' }
 
register 'menu.admin.cargaldif' => {
  label  => 'Update users and roles',
  url    => 'cargaldif/init',
  title  => 'Update users and roles',
  icon   => 'static/images/scm/icons/approve_16.png',
  action => 'action.admin.root'
};

sub init : Path {
    my ($self, $c) = @_;
    $c->launch('service.update.users');
    return;
}

1
