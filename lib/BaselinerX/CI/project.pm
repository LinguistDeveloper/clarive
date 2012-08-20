package BaselinerX::CI::project;
use Moose;
with 'Baseliner::Role::CI::Internal';

sub icon { '/static/images/icons/project.png' }
sub storage { 'BaliProject' }

1;
