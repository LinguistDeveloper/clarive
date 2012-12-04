package BaselinerX::Nature::eclipse;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.eclipse' => { name=>'Eclipse administration'};

register 'nature.eclipse' => {name => 'Eclipse', icon => 'eclipse', ns   => 'nature/eclipse', action => 'action.admin.eclipse'};

1;
