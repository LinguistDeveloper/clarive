package Baseliner::Role::CI::ApplicationServer;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/ci/appserver.svg' }

# has_ci 'start_script';
# has_ci 'stop_script';
# has_ci 'backup_script';
# has_ci 'update_script';

1;
