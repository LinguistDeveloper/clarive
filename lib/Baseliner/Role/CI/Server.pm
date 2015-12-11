package Baseliner::Role::CI::Server;
use Moose::Role;
use Moose::Util::TypeConstraints;
use BaselinerX::Type::Model::ConfigStore;
with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::Infrastructure';
with 'Baseliner::Role::HasAgent';

#sub icon { '/static/images/ci/server.png' }
sub icon { '/static/images/icons/server.png' }


has os          => qw(default unix lazy 1 required 1 is rw isa), enum [qw(unix win mvs)];
has osver       => qw(is rw isa Str);
has arch        => qw(default x86_64 is rw isa), enum [qw(x86_64 x86)];
has hostname    => qw(is rw isa Any required 1);
has remote_temp => qw(is rw isa Any lazy 1), default => sub {
    my $self = shift;
    return $self->is_win ? 'C:\TEMP' : '/tmp';
    };
has remote_perl => qw(is rw isa Str default perl);
has remote_tar  => qw(is rw isa Str default tar);
has agent_timeout => qw(is rw isa Num default 0);  # timeout for executes, send_file, etc., disabled by default
has connect_timeout => qw(is rw isa Num), default => sub{
    30; # 30 seconds
};

sub parse_vars {
    my ($self,$str, %parameters) = @_;
    my $wl_config = BaselinerX::Type::Model::ConfigStore->get('config.weblogic');
    my $instance_parameters = $self->can('parameters') ? ( $self->parameters // {} ) : {};
    my %vars = ( %$wl_config, %{ +{%$self} }, %$instance_parameters, %parameters );
    return Util->parse_vars(\%vars,\%vars) unless length $str;
    return Util->parse_vars( $str, \%vars );
}

sub is_win {
    my $self = shift;
    return $self->os eq 'win';
}

1;

