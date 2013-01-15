package BaselinerX::Nature::Oracle;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.oracle' => { name=>'Oracle administration' };

register 'nature.sql' => {name => 'ORACLE', icon => 'oracle', ns   => 'nature/oracle', action => 'action.admin.oracle'};


1;
