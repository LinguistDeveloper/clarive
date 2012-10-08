package BaselinerX::Nature::ZOS;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'nature.linklist_db2' => {name => 'z/OS-Linklist-DB2', ns   => 'nature/zos.linklist.db2', icon=>'zos' };

register 'nature.linklist' => {name => 'z/OS-Linklist', ns   => 'nature/zos.linklist', icon=>'zos' };

register 'nature.bd2' => {name => 'z/OS-DB2', ns   => 'nature/zos.db2', icon=>'zos' };

register 'nature.zos' => {name => 'z/OS', ns   => 'nature/zos', icon=>'zos' };

1;
