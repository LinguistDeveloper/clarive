package BaselinerX::Nature::biztalk;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.biztalik' => { name=>'Biztalk administration'};

register 'nature.biztalk' => {name => 'Biztalk', icon => 'biztalk', ns   => 'nature/biztalk', action=>'action.admin.biztalik'};

1;
