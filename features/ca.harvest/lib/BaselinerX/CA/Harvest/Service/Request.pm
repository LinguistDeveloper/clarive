package BaselinerX::CA::Harvest::Service::Request;
use Baseliner::Plug;
use Baseliner::Utils;

use utf8;

with 'Baseliner::Role::Service';

register 'action.approve.package' => {
	name => 'Approve Harvest packages',
};

register 'service.harvest.request.new' => {
	name => 'Create an approval request for a package',
	handler => \&run,
};

sub run {
	my ($self, $c, $p ) = @_;

	my $bl = $p->{bl} || '*';

	local *STDERR = *STDOUT;  # send stderr to stdout to avoid false error msg logs
	_throw _loc('Missing parameter package') unless defined $p->{package};

	my $action = 'action.approve.package';

	for my $package ( _array $p->{package} ) {

		#my $item = Baseliner->model('Namespaces')->get( "harvest.package/$_" );

        my $req = Baseliner->model('Request')->request(
            name     => 'Aprobación del paquete ' . $package,
            action   => $action,
            vars     => { reason => 'promoción a producción' },
            template => '/email/approve_package.html',
            ns       => 'harvest.package/' . $package,
            bl       => $bl,
        );
		#_throw _loc 'Could not find package "%1"', $_ unless ref $item;
	}

}

=head1 USAGE

bali harvest.request.new
	--bl DESA
	--job_type promote
	--username "[user]"
	--project "[project]"
	--from_state "[state]"
	--to_state "[state]"
	--packages ["package"]

=cut
1;
