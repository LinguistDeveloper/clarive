package BaselinerX::CI::oracle_connection;
use Moose;
with 'Baseliner::Role::CI::DatabaseConnection';

sub error {}
sub rc {}

1;
