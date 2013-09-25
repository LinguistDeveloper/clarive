package Baseliner::Role::CI::Server;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';

sub icon { '/static/images/ci/server.png' }

has os          => qw(is rw isa Str default unix);
has hostname    => qw(is rw isa Any required 1);
has remote_temp => qw(is rw isa Any lazy 1), default => sub {
    my $self = shift;
    return $self->os eq 'win' ? 'C:\TEMP' : '/tmp';
    };
has remote_perl => qw(is rw isa Str default perl);
has remote_tar  => qw(is rw isa Str default tar);

1;

