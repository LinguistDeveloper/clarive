package Baseliner::Role::CI::ApplicationServer;
use Moose::Role;
with 'Baseliner::Role::CI::Server';

sub icon { '/static/images/ci/appserver.png' }

# has_ci 'start_script';
# has_ci 'stop_script';
# has_ci 'backup_script';
# has_ci 'update_script';

1;


