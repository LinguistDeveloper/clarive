package BaselinerX::Nature::ZOS;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'nature.linklist_db2' => {name => 'ZOS-Linklist-DB2', ns   => 'nature/zos-linklist-db2'};

register 'nature.linklist' => {name => 'ZOS-Linklist', ns   => 'nature/zos-linklist'};

register 'nature.bd2' => {name => 'ZOS-DB2', ns   => 'nature/zos-db2'};

register 'nature.zos' => {name => 'ZOS', ns   => 'nature/zos'};

1;
