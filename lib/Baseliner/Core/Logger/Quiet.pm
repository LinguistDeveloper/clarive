package Baseliner::Core::Logger::Quiet;
use Baseliner::Utils;
use Moose;
use Carp;

extends 'Baseliner::Core::Logger::Base';

sub output { }

1;

