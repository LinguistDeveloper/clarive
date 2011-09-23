package Baseliner::Role::Node;
use Moose::Role;

has uri      => qw(is rw isa Str required 1);   # maybe a URI someday...
has resource => qw(is rw isa Baseliner::Node::URI required 1), 
                handles => qr/.*/;

has debug => qw(is rw isa Bool), default=>sub { $ENV{BASELINER_DEBUG} };


# error control 
has throw_errors => qw(is rw isa Bool default 1 lazy 1);
has ret => qw(is rw isa Str), default => '';

requires 'error';
requires 'rc';

sub _throw_on_error {
    my $self = shift;
    return unless $self->throw_errors;
    use Baseliner::Utils;
    _throw sprintf '%s: %s', $self->error, $self->ret if $self->rc;
}

sub output { shift->ret }

1;
