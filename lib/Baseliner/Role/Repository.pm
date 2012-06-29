package Baseliner::Role::Repository;
use Moose::Role;

requires 'name';
requires 'config_component';

sub provider_info {
    my $self = shift;
    return +{
        name => $self->name,
        config_component => $self->config_component,
    }
}

1;
