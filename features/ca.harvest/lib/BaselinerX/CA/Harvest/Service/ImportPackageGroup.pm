package BaselinerX::CA::Harvest::Service::ImportPackageGroup;
use Baseliner::Plug;
use Baseliner::Utils;

use utf8;

with 'Baseliner::Role::Service';

register 'action.harvest.pkggrpimport' => {
	name => 'Import Harvest Package Groups as Releases',
};

register 'config.harvest.import.pkggrp' => {
	name => 'Import Harvest Package Groups as Releases',
	metadata => [
		{ id=>'filter', label=>'Regular Expression to select package groups', type=>'text', default=>'.*' },
		{ id=>'states', label=>'Harvest States to select package groups from', type=>'array', default=>'' },
		{ id=>'packagegroups', label=>'Package Groups', type=>'array', default=>'' },
	]
};

register 'service.harvest.import.pkggrp' => {
	name => 'Import Harvest Package Groups as Releases',
	handler => \&run,
};

sub run {
	my ($self, $c, $p ) = @_;
	
	my $filter = $p->{filter};
	my @pkggrps;
	
	@pkggrps = _array( $p->{packagegroups} ) if ref $p->{packagegroups} eq 'ARRAY';

	unless( @pkggrps > 0 ) {
		my $rs = Baseliner->model('Harvest::Harpackagegroup')->search;	
		while( my $r = $rs->next ) {
			push @pkggrps, $r->pkggrp;
		}
	}
}

=head1 USAGE

bali harvest.pkggrpimport
	--filter '.*'
	--states 'Desarrollo, Producción'

=cut
1;

