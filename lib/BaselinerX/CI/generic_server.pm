package BaselinerX::CI::generic_server;
use Baseliner::Moose;
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

sub connect {
	my ( $self, %p ) = @_;
    
    # TODO choose best method 
    
    # Worker Agent
    my $user = $p{user};
    my $agent = BaselinerX::CI::worker_agent->new( cap=>$user.'@'.$self->hostname );
}

1;
