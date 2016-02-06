package BaselinerX::Type::Service::Container;
use Baseliner::Moose;

has stash => qw(is rw isa HashRef required 1);
has config => qw(is rw isa HashRef), default => sub { +{} };

sub job    { $_[0]->stash->{job} }
sub logger { $_[0]->job->logger }

1;
