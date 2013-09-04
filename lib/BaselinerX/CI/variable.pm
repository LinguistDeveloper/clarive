package BaselinerX::CI::variable;
use Baseliner::Moose;
use Baseliner::Utils;

has var_type         => qw(is rw isa Str);
has var_ci_class     => qw(is rw isa Maybe[Str]);
has var_ci_role      => qw(is rw isa Maybe[Str]);
has var_ci_mandatory => qw(is rw isa BoolCheckbox coerce 1);
has var_ci_multiple  => qw(is rw isa BoolCheckbox coerce 1);
has var_opts         => qw(is rw isa Any);
has var_default      => qw(is rw isa Any);

with 'Baseliner::Role::CI::Variable';

sub icon { '/static/images/icons/element_copy.png' }

sub has_bl { 0 }

1;

