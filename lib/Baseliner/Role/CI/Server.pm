package Baseliner::Role::CI::Server;
use Moose::Role;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';
with 'Baseliner::Role::HasAgent';

sub icon { '/static/images/ci/server.png' }

has os          => qw(is rw isa Str default unix);
has hostname    => qw(is rw isa Any required 1);
has remote_temp => qw(is rw isa Any lazy 1), default => sub {
    my $self = shift;
    return $self->os eq 'win' ? 'C:\TEMP' : '/tmp';
    };
has remote_perl => qw(is rw isa Str default perl);
has remote_tar  => qw(is rw isa Str default tar);
has agent_timeout => qw(is rw isa Num default 0);  # timeout for executes, send_file, etc., disabled by default
has connect_timeout => qw(is rw isa Num), default => sub{
    30; # 30 seconds
};

sub parse_vars {
    my ($self,$str, %parameters) = @_;
    my $wl_config = Baseliner->model('ConfigStore')->get('config.weblogic');
    my $instance_parameters = $self->can('parameters') ? ( $self->parameters // {} ) : {};
    my %vars = ( %$wl_config, %{ +{%$self} }, %$instance_parameters, %parameters );
    return Util->parse_vars(\%vars,\%vars) unless length $str;
    return Util->parse_vars( $str, \%vars );
}

1;

