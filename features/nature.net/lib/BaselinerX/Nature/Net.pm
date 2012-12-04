package BaselinerX::Nature::Net;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.net' => { name=>'.NET administration' };

register 'nature.net' => {name => '.NET', icon => 'net', ns   => 'nature/.net', action => 'action.admin.net'};


1;
