package Baseliner::Exception::Semaphore::Cancelled;
use Moose;

with 'Baseliner::Role::Exception';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
