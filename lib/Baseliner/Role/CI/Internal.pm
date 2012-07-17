package Baseliner::Role::CI::Internal;
use Moose::Role;
with 'Baseliner::Role::CI' => { -excludes => ['has_bl'] };

sub error {}
sub rc {}
sub has_bl { 0 }

1;
