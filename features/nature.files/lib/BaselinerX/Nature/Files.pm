package BaselinerX::Nature::Files;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.j2ee' => { name=>'J2EE administration'};

register 'nature.files' => {name => 'FICHEROS', icon => 'files', ns   => 'nature/files', action => 'action.admin.j2ee'};

1;
