package Baseliner::Role::CI::DatabaseConnection;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/ci/dbconn.png' }

1;


