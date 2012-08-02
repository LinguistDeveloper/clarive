package BaselinerX::Session::ConfigState;
    use Catalyst qw/
      Session
      Session::Store::FastMmap
      Session::State::Cookie
      /;
use Baseliner::Utils;      
my $DefaultBL = "*";
my $DefaultNS = "/";
      
sub setConfigState{
    my ($self,$c,$ns,$bl,$key) = @_;
    
    my $ns_key = $key . "/ns";
    my $bl_key = $key . "/bl";
    
    $c->session->{$ns_key} = $ns || $c->request->parameters->{ns} || $DefaultNS;		
    $c->session->{$bl_key} = $bl || $c->request->parameters->{bl} || $DefaultBL;		
    
    _log "EL CONFIG_STATE ($key) ASIGNADO NS = " . $c->session->{$ns_key} . " Y BL = " .$c->session->{$bl_key};
    
} 

sub getConfigState{
    my ($self,$c,$key) = @_;
    my $ns_key = $key . "/ns";
    my $bl_key = $key . "/bl";
    
    my $ns = $c->session->{$ns_key} || $c->request->parameters->{ns} || $DefaultNS;
    my $bl = $c->session->{$bl_key} || $c->request->parameters->{bl} || $DefaultBL;
    
    _log "EL CONFIG_STATE ($key) ES NS = $ns Y BL = $bl";	
    
    return ($ns,$bl);
}

sub getRequestState{
    my ($self,$c) = @_;
    
    my $ns = $c->request->parameters->{ns} || $DefaultNS;
    my $bl = $c->request->parameters->{bl} || $DefaultBL;

    return ($ns,$bl);
} 
 

sub reset{
    my ($self,$c, $key) = @_;
    my $ns_key = $key . "/ns";
    my $bl_key = $key . "/bl";
    
    $c->session->{$ns_key} = '/';
    $c->session->{$bl_key} = '*';
    
}