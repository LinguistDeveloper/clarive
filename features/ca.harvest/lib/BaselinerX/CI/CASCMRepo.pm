package BaselinerX::CI::CASCMRepo;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Repository';

has itempath => qw(is rw isa Str);
has viewname => qw(is rw isa Str);
has project_name => qw(is rw isa Str);

sub collection { 'GitRepository' }
sub icon       { '/static/images/icons/gitrepository.gif' }

sub checkout { }
sub list_elements { }
sub repository { }
sub update_baselines { }



1;
