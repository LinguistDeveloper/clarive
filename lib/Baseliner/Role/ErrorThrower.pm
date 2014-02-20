package Baseliner::Role::ErrorThrower;
use Moose::Role;

# error control 
has throw_errors => qw(is rw isa Bool default 0 lazy 1);
has ret          => qw(is rw isa Any), default => '';
has rc           => qw(is rw isa Maybe[Num] default 0);
has output       => qw(is rw isa Maybe[Str] lazy 1), default=>sub{
    my $self = shift;
    return $self->ret;
};

requires 'error';

sub _throw_on_error {
    my $self = shift;
    return unless $self->throw_errors;
    use Baseliner::Utils;
    _throw sprintf '%s: %s', $self->error, $self->ret if $self->rc;
}

#sub output { shift->ret }

1;
