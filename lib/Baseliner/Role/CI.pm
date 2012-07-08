package Baseliner::Role::CI;
use Moose::Role;

use Moose::Util::TypeConstraints;

subtype CI => as 'Baseliner::Role::CI';
coerce 'CI' =>
  from 'Num' => via { Baseliner::CI->new( $_ ) }; 


sub icon_class { '/static/images/ci/class.gif' }
requires 'icon';
requires 'collection';

# from Node
has uri      => qw(is rw isa Str);   # maybe a URI someday...
has resource => qw(is rw isa Baseliner::CI::URI), 
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

