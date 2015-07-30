package BaselinerX::GitRepository;
use Moose;
use Baseliner::Utils;
with 'Baseliner::Role::Repository';

sub name { 'Git Repository' }
sub config_component { '/git/comp/git/repository.js' }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
