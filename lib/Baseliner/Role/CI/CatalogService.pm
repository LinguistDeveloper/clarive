package Baseliner::Role::CI::CatalogService;
use Moose::Role;

with 'Baseliner::Role::CI' => { -excludes => ['has_bl'] };

sub error {}
sub rc {}
sub has_bl { 0 }

sub hide_service { 0 }

1;
