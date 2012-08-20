package Baseliner::Core::Filesys;
use strict;
use Baseliner::Utils;

our %agent_class = ( 
    ssh   => 'Baseliner::Core::Filesys::SSH',
    balix => 'Baseliner::Core::Filesys::Balix',
);

# ssh://usuario@servideor:93849=c:/
# balix://usuario@servideor:93849=c:/
sub new {
    my $class = shift;
    my %p = @_;
    my $agent = 'ssh';
    my $home = $p{home};
    my $os = $p{os} || 'unix';
    _log "home1 = $home";
    # get the agent name (ssh, balix), if any:
    if( $home =~ /^(\w+)\:(\/\/)(.*)/ ) {
        $agent = lc $1;
        $home  = $3;
    }
    _log "home2 = $home";
    if( defined $agent_class{ $agent } ) {
        my $class = $agent_class{$agent};
        eval "require $class";
        die "Could not require $class: $@" if($@);
        return $class->new( @_, home=>$home, os=>$os );
    }
    else {
        #_throw _loc 'Filesys agent %1 not supported', $agent;
        die sprintf('Filesys agent %s not supported', $agent);
    }
}

1;
