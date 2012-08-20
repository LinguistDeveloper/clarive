package BaselinerX::BdeActions;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

register 'action.bde.view_j2ee_console' =>
  {name => "Can view J2EE app console"};

register 'action.bde.view_disk_report' =>
  {name => "Can view disk space consumption report"};

register 'action.bde.view_distribution_chains' =>
  {name => 'Can access and modify distribution chains'};

register 'action.bde.receive.ldif_errors' =>
  {name => 'Receives mails with information regarding Ldif file load errors'};

1;
