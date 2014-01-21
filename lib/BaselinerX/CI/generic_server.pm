package BaselinerX::CI::generic_server;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _file _dir);
use Try::Tiny;

has connect_worker => qw(is rw isa Bool default 1);
has connect_balix  => qw(is rw isa Bool default 1);
has connect_ssh    => qw(is rw isa Bool default 1);

with 'Baseliner::Role::CI::Server';

sub error {}
sub rc {}
sub ping {
	my ( $self ) = @_;

	my $return = 'KO';

	my $server = $self->hostname;
	my $out = `ping -c 1 "$server"`;
	my $rc = $? >> 8;
	if ( $rc == 0 ) {
		$return = 'OK';
	}
	return ( $return, $out );

};

method connect( :$user='' ) {
    # Worker Agent
    my $err = '';
    my $agent;
    my $tmout;
    if( $tmout = $self->connect_timeout ) {
        alarm $tmout;
    }
    local $SIG{ALRM} = sub { _fail _loc("Agent connection timeout (> %1 sec)", $tmout); }
        if $tmout;
    if( $self->connect_worker ) {
        $agent = try {
            my ($chi) = $self->children( isa=>'worker_agent' ) if $self->mid;
            do { alarm 0; return $chi } if ref $chi;
            BaselinerX::CI::worker_agent->new( server=>$self, timeout=>$self->agent_timeout, cap=>$user.'@'.$self->hostname );
        } catch { $err.=shift . "\n" };       
    } 
    if( !$agent && $self->connect_balix ) {
        $agent = try { 
            my ($chi) = $self->children( isa=>'balix_agent' ) if $self->mid;
            do { alarm 0; return $chi } if ref $chi;
            BaselinerX::CI::balix_agent->new( user=>$user, server=>$self, timeout=>$self->agent_timeout );
        } catch { $err.=shift . "\n" };       
    }
    if( !$agent && $self->connect_ssh ) {
        $agent = try { 
            my ($chi) = $self->children( isa=>'ssh_agent' ) if $self->mid;
            do { alarm 0; return $chi } if ref $chi;
            BaselinerX::CI::ssh_agent->new( user=>$user, server=>$self, timeout=>$self->agent_timeout );
        } catch { $err.=shift . "\n" };       
    }
    if( $err ) {
        my $meths = join ',', grep { defined } map { my $m="connect_".$_; ($self->$m ? $_ : undef); } qw(worker balix ssh); 
        if( !$agent ) {
            _fail _loc 'ERROR: could not find agent for this server (methods attempted: %1): %2', $meths, $err;
        } 
        else {
            _debug 'Some connection methods failed: ' . $err;
        }
    }
    alarm 0;
    return $agent;
}

1;
