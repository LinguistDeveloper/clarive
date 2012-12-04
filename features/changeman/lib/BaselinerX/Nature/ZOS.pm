package BaselinerX::Nature::ZOS;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.admin.zos' =>  { name=>'z/OS administration' };

register 'nature.zos.linklist.db2' => {name => 'ZOS-Linklist-DB2', ns   => 'nature/zos.linklist.db2', icon=>'zos', action=>'action.admin.zos' };
register 'nature.zos.linklist' => {name => 'ZOS-Linklist', ns   => 'nature/zos.linklist', icon=>'zos', action=>'action.admin.zos'};
register 'nature.zos.db2' => {name => 'ZOS-DB2', ns   => 'nature/zos.db2', icon=>'zos', action=>'action.admin.zos'};
register 'nature.zos' => {name => 'ZOS', ns   => 'nature/zos', icon=>'zos', action=>'action.admin.zos'};


1;
