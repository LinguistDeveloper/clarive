package Baseliner::Core::Filesys;
use strict;
use Baseliner::Utils;

# ssh://usuario@servideor:93849=c:/
# balix://usuario@servideor:93849=c:/
sub new {
	my $class = shift;
	my %p = @_;
	my $agent = 'ssh';
	my $home = $p{home};
	my $os = $p{os} || 'unix';

	# get the agent name (ssh, balix), if any:
	if( $home =~ /^(\w+)\:(\/\/)(.*)/ ) {
		$agent = lc $1;
		$home  = $3;
	}

    my $base_class = "Baseliner::Core::Filesys::";
    my $agent_class = $class->find_class_for_agent( $base_class, $agent );
    return $agent_class->new( @_, home => $home, os => $os );
}

sub find_class_for_agent {
    my ( $self, $base_class, $agent ) = @_;
    for ( uc($agent), lc($agent), $self->camelcase($agent) ) {
        my $class = $base_class . $_;
		eval "require $class";
        return $class unless $@;
        _throw _loc( "Error loading class %1: %2", $class, $@)  if $@ !~ /Can't locate/;
	}
    _throw "Could not require agent class for agent $agent (${base_class}${agent}): $@";
	}

sub camelcase {
    my ( $self, $str ) = @_;
    $str =~ s/^(\w)(\w+)$/uc($1).lc($2)/ge;
    $str =~ s/_(\w)/uc($1)/ge;
    $str;
}

1;
