package BaselinerX::Job::Chain;
use Moose;
use Baseliner::Utils;

has 'id'            => ( is => 'rw', isa => 'Int',      required => 1 );
has 'step'          => ( is => 'rw', isa => 'Str',      required => 1 );
has 'chain'         => ( is => 'rw', isa => 'HashRef',  required => 1 );
has 'services'      => ( is => 'rw', isa => 'ArrayRef', required => 1 );
has 'current_index' => ( is => 'rw', isa => 'Int',      default  => 0 );
has 'job_exec'      => ( is => 'rw', isa => 'Int',      default  => 1 );

sub next_service {
    my $self = shift;
    return if $self->done;
    my $index = $self->current_index;
    $self->current_index( $index + 1 );
    return $self->services->[ $index ];
}

sub current_service {
    my $self = shift;
    return $self->services->[ $self->current_index ];
}

sub done {
    my $self = shift;
    my $index = $self->current_index;
    my @services = _array $self->services;
    return $index >= scalar(@services);
}

1;
