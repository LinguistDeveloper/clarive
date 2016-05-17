package Clarive::Code::Base;
use Moose;

has strict_mode => qw(is ro isa Bool default 1);
has filename    => qw(is ro isa Str default EVAL);

1;
