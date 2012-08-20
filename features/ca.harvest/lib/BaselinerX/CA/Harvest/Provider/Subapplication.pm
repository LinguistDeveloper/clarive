package BaselinerX::CA::Harvest::Provider::Subapplication;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::CA::Harvest::Namespace::Subapplication;
use BaselinerX::CA::Harvest;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.subapplication' => {
	name	=>_loc('Harvest Subapplication'),
			domain  => domain(),
			can_job => 0,
			finder =>  \&find,
			handler => \&list,
};

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Subapplication' }
sub domain    { 'harvest.subapplication' }
sub icon      { '/static/images/scm/subapp.gif' }
sub name      { 'HarvestSubapplication' }

sub find {
	my ($self, $item ) = @_;
	my $row = Baseliner->model('Harvest::Haritems')->search({ itemname=>$item, itemtype=>0 , parentobjid=>{ '<>', 0 } })->first;
	return BaselinerX::CA::Harvest::Namespace::Subapplication->new({ row => $row }) if( ref $row );
}

sub get { find(@_) }

sub list {
	my ($self, $c, $p) = @_;
	my $config = Baseliner->registry->get('config.harvest.subapl')->data;
	my $cnt = $config->{position};
	my $nature = $p->{nature} || '%';
	my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });
	my @rows = 
		$db->array_hash(qq{
				SELECT DISTINCT 
				SUBSTR(  pathfullname, 1) path, itemobjid
				FROM HARPATHFULLNAME pa
				WHERE pathfullname LIKE '\\%\\$nature\%'
				AND pathfullname NOT LIKE '\\%\\$nature\\%\\%'
				});
	my @ns;
	my %done;
	for my $row ( @rows ) {
		my $path = $row->{path};
		my @parts = split /\\/, $path;
		next unless @parts == ($cnt+1); ## the preceding \ counts as the first item
			my $subapl = "$parts[$cnt]";
		my @envs = BaselinerX::CA::Harvest::envs_for_item( $row->{itemobjid} );
		for my $env ( @envs ) {
			( my $env_short =  $env->{environmentname} )=~ s/\s/_/g;
			next if exists $done{ $subapl };
			$done{$subapl}=();
			push @ns, BaselinerX::CA::Harvest::Namespace::Subapplication->new({
					ns      => 'harvest.subapplication/' . $subapl,
					ns_name => "$parts[1]=>$subapl",
					ns_type => _loc('Harvest Subapplication'),
					ns_id   => $env->{envobjid},
					ns_parent => 'application/' . $env_short,
					parent_class => [ 'application' ],
					ns_data => { 
					itemobjid => $row->{itemobjid},
					pathfullname => $path,
					pathfullnameupper => uc($path),
					},
					provider=> 'namespace.harvest.subapplication',
					});
		}
	}
	my $total = scalar @ns;
	_log "provider list finished (records=$total/$total).";
	return { data=>\@ns, total=>$total, count=>$total };
}

1;
