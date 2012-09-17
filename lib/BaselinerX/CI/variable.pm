package BaselinerX::CI::variable;
use Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Variable';

sub icon { '/static/images/icons/element_copy.png' }

sub has_bl { 0 }
1;

