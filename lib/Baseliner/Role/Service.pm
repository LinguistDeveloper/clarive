package Baseliner::Role::Service;
use Moose::Role;

has 'log' => (
    is      => 'rw',
    does    => 'Baseliner::Role::Logger',
    lazy    => 1,
    default=>sub {
        my $self = shift; 
        require Baseliner::Core::Logger::Base;
        return Baseliner::Core::Logger::Base->new();
    }
);

has 'job' => ( 
    is       => 'rw',
    does     => 'Baseliner::Role::JobRunner',
    weak_ref => 1,
    lazy    => 1,
    default  => sub {
        require Baseliner::Core::JobRunner;
        Baseliner::Core::JobRunner->new;
    },
    trigger => sub {
        my $self = shift;
        $self->log( $self->job->logger );
    },
);

1;
