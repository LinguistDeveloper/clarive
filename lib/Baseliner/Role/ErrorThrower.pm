package Baseliner::Role::ErrorThrower;
use Moose::Role;

# error control 
has throw_errors => qw(is rw isa Bool default 0 lazy 1);
has ret          => qw(is rw isa Any), default => '';   # return value/hash from command
has rc           => qw(is rw isa Maybe[Num] default 0); # return code, 0 is ok, !0 bad
has output       => qw(is rw isa Maybe[Str] lazy 1), default=>sub{   # stdout + stderr
    my $self = shift;
    return $self->ret;
};

requires 'error';

sub _throw_on_error {
    my $self = shift;
    return unless $self->throw_errors;
    use Baseliner::Utils;
    _throw sprintf '%s: %s', $self->error, $self->output if $self->rc;
}

1;
