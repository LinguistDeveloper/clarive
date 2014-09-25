package BaselinerX::CI::DBDest;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::DatabaseConnection';

has_cis 'projects';
has dests => qw(is rw isa Maybe[ArrayRef] default), sub { [] };
has tables => qw(is rw isa Maybe[ArrayRef] default), sub { [] };

sub rel_type { { projects => [ from_mid => 'dbdest_project' ] } }

sub has_bl { 1 }
sub icon { '/static/images/icons/local.png' }
sub ci_form {  '/ci/DBDest.js' }


sub ping {}
1;
