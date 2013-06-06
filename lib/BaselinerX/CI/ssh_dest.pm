package BaselinerX::CI::ssh_dest;
use Baseliner::Moose;

has path => qw(is rw isa Any);

extends 'BaselinerX::CI::ssh_agent';   # XXX not sure, use delegation instead
with 'Baseliner::Role::CI::Destination';

# inherited from ssh_agent: has server => 'CI'
has_ci server => 'CI';  # not inherited or not visible as meta->get_attribute
sub rel_type { { server=>[ from_mid => 'ssh_dest_ssh_server'] } }

sub error {  }
sub rc {
    my $self = shift;
    $self->error ? 1 : 0;
}

sub ping {'OK'};

1;

