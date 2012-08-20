package Baseliner::Node::ssh_script;
use Moose;
use Baseliner::Utils;

extends 'Baseliner::Node::ssh';
with 'Baseliner::Role::Node::Script';

sub run {
    my ($self) = @_;
    _log _dump $self->arg; 
    $self->execute( $self->script, $self->args );
}

sub args { @{ shift->arg } }

1;
