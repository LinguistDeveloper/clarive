package BaselinerX::CI::OracleConnection;
use Moose;
with 'Baseliner::Role::CI::DatabaseConnection';

sub collection { 'oracle_connection' }

1;
