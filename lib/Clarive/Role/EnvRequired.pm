package Clarive::Role::EnvRequired;
use Mouse::Role;

has env => qw(is rw isa Str required 1);

1;
