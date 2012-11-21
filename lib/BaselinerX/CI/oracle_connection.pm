package BaselinerX::CI::oracle_connection;
use Moose;
use Baseliner::Utils;
with 'Baseliner::Role::CI::DatabaseConnection';

has server => qw(is rw isa CI coerce 1);
has sid => qw(is rw isa Any);
has port => qw(is rw isa Any);

sub rel_type { { server=>[ from_mid => 'database_server' ] } }

sub error {}
sub rc {}
sub ping {
	my ( $self ) = @_;

	my $return = 'KO';

	my $server = $self->server->hostname;
	my $port = $self->{port};
	my $sid = $self->{sid};
	my $out = `tnsping "(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = $server)(PORT = $port)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = $sid)))"`;
	my $rc = $? >> 8;
	if ( $rc == 0 ) {
		$return = 'OK';
	}
	return ( $return, $out );

};

1;
