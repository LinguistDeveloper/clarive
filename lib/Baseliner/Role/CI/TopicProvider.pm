package Baseliner::Role::CI::TopicProvider;
use Moose::Role;
with 'Baseliner::Role::CI' => { -excludes => ['has_bl'] };

sub has_bl { 0 }

1;
