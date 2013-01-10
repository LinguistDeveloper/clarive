package BaselinerX::CA::Harvest::Provider::Nature;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::CA::Harvest::Namespace::Nature;
use Baseliner::Core::DBI;

with 'Baseliner::Role::Provider';

register 'namespace.harvest.nature' => {
	name	=>_loc('Harvest Nature'),
	domain  => domain(),
	can_job => 1,
    finder =>  \&find,
	handler =>  \&list,
};

#TODO needs to be in config:
our %from_states = ( 
	DESA => {  promote => [ 'Desarrollo', 'Desarrollo Integrado' ], demote => 0 },
	PREP => {  promote => [ 'Desarrollo Integrado' ], demote => [ 'Pruebas Integradas', 'Pruebas de Acceptación', 'Pruebas Sistemas' ] },
	PROD => {  promote => [ 'Pruebas Sistemas' ], demote => [ 'Producción' ] },
);

sub namespace { 'BaselinerX::CA::Harvest::Namespace::Nature' }
sub domain    { 'harvest.nature' }
sub icon      { '/static/images/icon/nature.gif' }
sub name      { 'Natures' }

register 'config.harvest.natures' => {
   name => 'Harvest Natures',
   metadata => [
            { id=>'harvest', label=>'Natures to process', type=>'hash', 
              default=>qq{BIZTALK=>'Biztalk','ECLIPSE'=>'Eclipse','FICHEROS'=>'Ficheros','J2EE'=>'J2EE','.NET'=>'.Net',ORACLE=>'Oracle','RS'=>'Reporting Services','SISTEMAS'=>'Sistemas','VIGNETTE'=>'Vignette' } }
      ]
};

sub find {
    my ($self, $item ) = @_;
	$self->not_implemented;
    #my $package = Baseliner->model('Harvest::Harpackage')->search({ packagename=>$item })->first;
    #return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub list {
    my ($self, $c, $p) = @_;
	_log "provider list started...";
	my @ns;
    my $natures=config_get('config.harvest.natures');

    foreach ( keys %{ $natures->{harvest} || {} } ) {
        push @ns, BaselinerX::CA::Harvest::Namespace::Nature->new({
            ns      => 'harvest.nature/' . $_,
            ns_name => $natures->{harvest}{$_},
            ns_type => _loc('Harvest Nature'),
            ns_id   => 0,
            ns_data => { },
            provider=> 'namespace.harvest.nature',
        });
    }

	_log "provider list finished.";
	return \@ns;
}

sub list_query {
    my ($self, $c, $p) = @_;
	_log "provider list started...";
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
	my @ns;
	my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });

	my $config = Baseliner->registry->get('config.harvest.natures')->data;
	my $cnt = $config->{position};

	my @folders = $db->array(qq{
		SELECT DISTINCT
		 SUBSTR(SUBSTR(pa.pathfullname,INSTR(pa.pathfullname,'\\',2)+1)||'\\',1,
		 	INSTR(SUBSTR(pa.pathfullname,INSTR(pa.pathfullname,'\\',2)+1)||'\\','\\',1)-1)
		 FROM HARPATHFULLNAME pa
		});
	my %done;
	foreach my $folder ( map { uc } @folders ) {
		next unless $folder;
		push @ns, BaselinerX::CA::Harvest::Namespace::Nature->new({
			ns      => 'harvest.nature/' . $folder,
			ns_name => $folder,
			ns_type => _loc('Harvest Nature'),
			ns_id   => 0,
			ns_data => { },
			provider=> 'namespace.harvest.nature',
		});
	}
	_log "provider list finished.";
	return \@ns;
}

sub list_slow {
    my ($self, $c, $p) = @_;
    my $bl = $p->{bl};
    my $job_type = $p->{job_type};
    my $query = $p->{query};
    my $sql_query;
	my $rs = Baseliner->model('Harvest::Harpathfullname')->search({  }); #TODO find a condition to make this query fast
	my @ns;
	my $config = Baseliner->registry->get('config.harvest.natures')->data;
	my $cnt = $config->{position};
	my %done;
	while( my $r = $rs->next ) {
		my $path = $r->pathfullname;
		my @parts = split /\\/, $path;
		next unless @parts == ($cnt+1); ## the preceding \ counts as the first item
		my $nature = $parts[$cnt];
		next if $done{ $nature };
		$done{ $nature } =1;
		push @ns, BaselinerX::CA::Harvest::Namespace::Nature->new({
			ns      => 'harvest.nature/' . $nature,
			ns_name => $nature,
			ns_type => _loc('Harvest Nature'),
			ns_id   => 0,
			ns_data => { $r->get_columns },
			provider=> 'namespace.harvest.nature',
		});
	}
	return \@ns;
}

1;
