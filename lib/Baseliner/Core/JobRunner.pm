=head DESCRIPTION

A simple Job Runner

=cut
package Baseliner::Core::JobRunner;
use Moose;
use Baseliner::Utils;

has stash => qw(is rw isa HashRef), default=>sub{{}};
has logger => qw(is rw isa Baseliner::Role::Logger), default=>sub{ 
    require Baseliner::Core::Logger::Base;
    Baseliner::Core::Logger::Base->new
};

with 'Baseliner::Role::JobRunner';

sub jobid { 0 }
sub bl { '*' }
sub step { 1 }
sub status { }
sub exec { }
sub job_stash { 
    my $self = shift;
    $self->stash;
}

1;
