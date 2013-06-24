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
#:int_asi:
BEGIN { extends 'Catalyst::Controller' }
 
sub init : Path {
    my ($self, $c) = @_;
    $c->launch('service.load.ldif.ftp.files');
    return;
}

1
