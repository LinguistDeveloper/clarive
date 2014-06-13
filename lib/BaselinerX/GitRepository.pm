package BaselinerX::GitRepository;
use Moose;
use Baseliner::Utils;
with 'Baseliner::Role::Repository';

sub name { 'Git Repository' }
sub config_component { '/git/comp/git/repository.js' }

1;
