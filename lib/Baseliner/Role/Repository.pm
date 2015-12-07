package Baseliner::Role::Repository;
use Moose::Role;

requires 'name';
requires 'config_component';

has tags_mode => qw(is rw isa Str);

sub provider_info {
    my $self = shift;
    return +{
        name => $self->name,
        config_component => $self->config_component,
    }
}

1;
