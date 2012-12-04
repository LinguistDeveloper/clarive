package BaselinerX::Nature::sistemas;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.sistemas' => { name=>'Systems adminitration' };

register 'nature.sistemas' => {name => 'Sistemas', icon => 'sistemas', ns   => 'nature/sistemas', action => 'action.admin.sistemas'};

1;
