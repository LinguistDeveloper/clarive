package BaselinerX::Nature::J2EE;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.j2ee' => { name=>'J2EE administration'};
register 'nature.j2ee' => {name => 'J2EE', icon => 'j2ee', ns   => 'nature/j2ee', action=>'action.admin.j2ee'};

1;
