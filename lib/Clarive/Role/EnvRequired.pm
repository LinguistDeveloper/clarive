package Clarive::Role::EnvRequired;
use Mouse::Role;

#has env => qw(is rw isa Str required 1);

before BUILD => sub {
    die "ERROR: argument env is required\n" unless length $_[0]->env || $_[0]->help;
};

1;
