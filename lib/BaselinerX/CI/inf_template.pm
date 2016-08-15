package BaselinerX::CI::inf_template;
use Baseliner::Moose;
use Baseliner::Utils;
use Baseliner::Model::Permissions;
use BaselinerX::CI::variable;

with 'Baseliner::Role::CI::Template';
with 'Baseliner::Role::CI::VariableStash';

sub icon { '/static/images/icons/template.ico' }

1;
