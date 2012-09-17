package BaselinerX::CI::value;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Variable';

sub icon { '/static/images/icons/element_copy.png' }

has projects => qw(is rw isa CIs coerce 1);
sub rel_type { { projects=>[ to_mid => 'project_variable'] } }

1;


