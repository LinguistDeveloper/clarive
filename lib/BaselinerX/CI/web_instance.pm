package BaselinerX::CI::web_instance;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/webservice.png' }

has ip 	=> qw(is rw isa Str), default => '';
has web_port => qw(is rw isa Str), default => '';
has executable 	=> qw(is rw isa Str), default => '';
has install => qw(is rw isa Str), default => '';
has contingency => qw(is rw isa Str), default => '';
has doc_root_dynamic_fixed => qw(is rw isa Str), default => '';
has doc_root_static_fixed => qw(is rw isa Str), default => '';

1;