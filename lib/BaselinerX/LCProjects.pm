package BaselinerX::LCProjects;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

#with 'Baseliner::Role::

__PACKAGE__->config->{namespace} = 'lifecycle';
no Moose;
__PACKAGE__->meta->make_immutable;

1;
