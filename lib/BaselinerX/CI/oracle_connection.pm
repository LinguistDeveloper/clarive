package BaselinerX::CI::oracle_connection;
use Moose;
with 'Baseliner::Role::CI::DatabaseConnection';

sub collection { 'oracle_connection' }

sub error {}
sub rc {}

1;
