package Baseliner::Core::Logger::Base;
use Baseliner::Utils;
use Moose;
use Carp;

with 'Baseliner::Role::Logger';

sub info {
    my $self = shift;
    return unless @_;
    my $msg = join('', grep { defined } @_ ) . "\n"; 
    my $cb_ret = $self->cb->( $msg );
    $msg = $cb_ret if defined $cb_ret && !ref $cb_ret;
    $self->output( $msg ) unless $self->quiet;
    $self->msg( $self->msg . $msg );
}

sub output {
    my ($self, $msg ) = @_;
    print $msg;
}

sub warn { info(@_) }
sub debug {
    my $self = shift;
    $self->info(@_) if $self->verbose || $ENV{BASELINER_DEBUG};
}
sub error {
    my $self = shift;
    $self->rc( $self->rc + 1 ); # rudimentary
    $self->info(@_);
}

sub fatal {
    my $self = shift;
    $self->error(@_);
    my $callback = $self->fatal_callback;
    $callback->($self,@_);
}
#TODO write to db too

no Moose;
__PACKAGE__->meta->make_immutable;

1;

