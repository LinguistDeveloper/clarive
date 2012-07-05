package BaselinerX::CI::Project;
use Moose;
with 'Baseliner::Role::CI::Internal';

sub collection { 'bali_project' }
sub icon { '/static/images/icons/project.png' }

1;
