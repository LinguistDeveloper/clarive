package BaselinerX::CI::ssh_script;
use Baseliner::Moose;

has_ci server => handles=>['output','rc']; # ssh_agent
has script => qw(is rw isa Any);

with 'Baseliner::Role::CI::Script';

sub rel_type {
    {
        server    => [ from_mid => 'ssh_script_server' ],
    };
}

sub run {
    my ($self) = @_;
    use Baseliner::Utils;
    _debug $self->arg; 
    $self->server->execute( $self->script, $self->args );
}

sub args { @{ shift->arg } }

sub error {}

sub ping {'OK'};

1;
