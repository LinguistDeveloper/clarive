package Clarive::Config;
use strict;

sub new {
    my $class = shift;
    my $data = shift;
    bless $data => $class;
}

1;
