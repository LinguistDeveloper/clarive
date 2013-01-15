package BaselinerX::Nature::ssrs;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.ssrs' => { name=>'SSRS administration' };

register 'nature.ssrs' => {name => 'Reporting Services', icon => 'ssrs', ns   => 'nature/ssrs', action => 'action.admin.ssrs'};



1;
