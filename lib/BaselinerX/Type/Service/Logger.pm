package BaselinerX::Type::Service::Logger;
use Baseliner::Utils;
use Moose;

extends 'Baseliner::Core::Logger::Base';

sub output { }  # make it silent  

no Moose;
__PACKAGE__->meta->make_immutable;

1;
