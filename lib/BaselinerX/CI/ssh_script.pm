package BaselinerX::CI::ssh_script;
use Moose;

has server => qw(is rw isa CI coerce 1); # ssh_agent
has script => qw(is rw isa Any);

with 'Baseliner::Role::CI::Script';

sub run {
    my ($self) = @_;
    use Baseliner::Utils;
    _log _dump $self->arg; 
    $self->server->execute( $self->script, $self->args );
}

sub args { @{ shift->arg } }

sub error {}
sub rc {}

1;
