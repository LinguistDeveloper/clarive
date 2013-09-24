package BaselinerX::CI::generic_server;
use Baseliner::Moose;

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

method connect( :$user ) {
    # Worker Agent
    my $agent = try {
        if( $self->connect_worker ) {
            return BaselinerX::CI::worker_agent->new( cap=>$user.'@'.$self->hostname );       
        } 
        elsif( $self->connect_balix ) {
            return BaselinerX::CI::balix_agent->new( user=>$user, host=>$self->hostname );       
        }
        elsif( $self->connect_ssh ) {
            return BaselinerX::CI::ssh_agent->new( user=>$user, host=>$self->hostname );       
        }
    }
}

1;
