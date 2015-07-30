package Baseliner::Core::Logger::Quiet;
use Baseliner::Utils;
use Moose;
use Carp;

extends 'Baseliner::Core::Logger::Base';

sub output { }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

