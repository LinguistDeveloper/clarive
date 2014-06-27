package Clarive::Cmd::version;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'report our version';

sub run {
    my ($self)=@_;
    my $v = Clarive->version;
    say sprintf "clarive version %s (sha %s)", @{ ref $v ? $v : [$v,$v] } ;
}

1;
