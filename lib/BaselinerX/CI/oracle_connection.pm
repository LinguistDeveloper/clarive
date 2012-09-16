package BaselinerX::CI::oracle_connection;
use Moose;
with 'Baseliner::Role::CI::DatabaseConnection';

has server => qw(is rw isa CI coerce 1);

sub rel_type { { server=>[ from_mid => 'database_server' ] } }

sub error {}
sub rc {}

1;
