package BaselinerX::CA::Harvest::Service::Dependencies;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'config.ca.harvest.dependencies' => {
    name => 'Harvest solve dependencies for package',
    metadata => [
        { id=>'packageList', type=>'str' },
        { id=>'action', type=>'str' },
        { id=>'environment', type=>'str' },
    ]
};

register 'service.harvest.dependencies' => {
    name    => 'Solve SCM file and folder version dependencies for a SCM package',
    config  => 'config.ca.harvest.dependencies',
    show_in_menu => 0,
    handler => \&run,
};

sub run {
	use Data::Dumper;
    my ( $self, $c, $p ) = @_;
	my $mensaje="";
	 
    # _check_parameters( $p, qw/packageList action/ );
	my @packages = _array $p->{packageList};
	
	my $packageList = "'" . join ('\', \'', _array $p->{packageList}) . "'";
	my $passType = $p->{action} eq 'Promote'?'>':'<';
	$self->log->info( "Resolviendo dependencias de los paquetes: $packageList\n" );
	
	my $dbh = Baseliner::Core::DBI->new({ model=>'Baseliner' });
	my $SQL = "SELECT DISTINCT P2.PACKAGEOBJID||V2.VERSIONOBJID, I2.ITEMTYPE, P2.PACKAGENAME PAQUETE, PFN2.PATHFULLNAME || '\\' || IN2.ITEMNAME ITEM, V2.MAPPEDVERSION VERSION
			FROM 
				HARPACKAGE P1,
				HARSTATE S1, 
				HARVERSIONS V1, 
				HARITEMNAME IN1, 
				HARPATHFULLNAME PFN1, 
				HARPACKAGE P2, 
				HARSTATE S2, 
				HARVERSIONS V2, 
				HARITEMNAME IN2,
				HARITEMS I2,
				HARPATHFULLNAME PFN2
			WHERE 1=1
				AND P1.PACKAGENAME IN ($packageList)
				AND P1.STATEOBJID = S1.STATEOBJID
				AND P1.PACKAGEOBJID = V1.PACKAGEOBJID
				AND V1.ITEMNAMEID = IN1.NAMEOBJID
				AND V1.PATHVERSIONID = PFN1.VERSIONOBJID
				AND P2.PACKAGENAME NOT IN ($packageList, 'BASE')
				AND P2.STATEOBJID = S2.STATEOBJID
				AND S1.STATEORDER $passType= S2.STATEORDER
				AND P2.PACKAGEOBJID = V2.PACKAGEOBJID
				AND V2.ITEMNAMEID = IN2.NAMEOBJID
				AND V2.ITEMOBJID = I2.ITEMOBJID
				AND V2.PATHVERSIONID = PFN2.VERSIONOBJID
				AND V1.ITEMOBJID = V2.ITEMOBJID
				AND V1.VERSIONOBJID $passType V2.VERSIONOBJID";
		$SQL .= " UNION
			SELECT DISTINCT V3.PACKAGEOBJID||V3.VERSIONOBJID, I3.ITEMTYPE, P3.PACKAGENAME PAQUETE, PFN3.PATHFULLNAME || '\\' || IN3.ITEMNAME ITEM, V3.MAPPEDVERSION VERSION
			FROM 
				HARPACKAGE P1,
				HARSTATE S1, 
				HARVERSIONS V1, 
				HARITEMNAME IN1, 
				HARPATHFULLNAME PFN1, 
				HARPACKAGE P3, 
				HARSTATE S3, 
				HARVERSIONS V3, 
				HARITEMNAME IN3,
				HARITEMS I3,
				HARPATHFULLNAME PFN3
			WHERE 1=1
				AND P1.PACKAGENAME IN ($packageList)
				AND P1.STATEOBJID = S1.STATEOBJID
				AND P1.PACKAGEOBJID = V1.PACKAGEOBJID
				AND V1.ITEMNAMEID = IN1.NAMEOBJID
				AND V1.PATHVERSIONID = PFN1.VERSIONOBJID
				AND V1.PATHVERSIONID = V3.VERSIONOBJID
				AND V3.PATHVERSIONID = PFN3.VERSIONOBJID
				AND V3.PACKAGEOBJID = P3.PACKAGEOBJID
				AND V3.ITEMNAMEID = IN3.NAMEOBJID
				AND V3.ITEMOBJID = I3.ITEMOBJID
				AND P3.PACKAGENAME NOT IN ($packageList, 'BASE')
				AND P3.STATEOBJID = S3.STATEOBJID
				AND S1.STATEORDER $passType= S3.STATEORDER" if $p->{action} eq 'Promote';
		$SQL .= " UNION
			SELECT DISTINCT V3.PACKAGEOBJID||V3.VERSIONOBJID, I3.ITEMTYPE, P3.PACKAGENAME PAQUETE, PFN3.PATHFULLNAME || '\\' || IN3.ITEMNAME ITEM, V3.MAPPEDVERSION VERSION
			FROM 
				HARPACKAGE P1,
				HARSTATE S1, 
				HARVERSIONS V1, 
				HARITEMNAME IN1, 
				HARPATHFULLNAME PFN1, 
				HARPACKAGE P3, 
				HARSTATE S3, 
				HARVERSIONS V3, 
				HARITEMNAME IN3,
				HARITEMS I3,
				HARPATHFULLNAME PFN3
			WHERE 1=1
				AND P1.PACKAGENAME IN ($packageList)
				AND P1.STATEOBJID = S1.STATEOBJID
				AND P1.PACKAGEOBJID = V1.PACKAGEOBJID
				AND V1.ITEMNAMEID = IN1.NAMEOBJID
				AND V1.PATHVERSIONID = PFN1.VERSIONOBJID
				AND V1.VERSIONOBJID = V3.PATHVERSIONID
				AND V3.PATHVERSIONID = PFN3.VERSIONOBJID
				AND V3.PACKAGEOBJID = P3.PACKAGEOBJID
				AND V3.ITEMNAMEID = IN3.NAMEOBJID
				AND V3.ITEMOBJID = I3.ITEMOBJID
				AND P3.PACKAGENAME NOT IN ($packageList, 'BASE')
				AND P3.STATEOBJID = S3.STATEOBJID
				AND S1.STATEORDER $passType= S3.STATEORDER" if $p->{action} eq 'Demote';
		$SQL .= " ORDER BY 3,2,4,5 DESC";

	# warn $SQL;
 	my %dependencias = $dbh->hash ( $SQL );
	if (%dependencias) {
		my $paqueteDepAnterior="";
		foreach (sort(keys %dependencias)) {
			my ($type, $paqueteDep, $item, $version) = @{$dependencias{$_}};
			$type=$type eq 0?'Carpeta':'Fichero';
			if ($paqueteDep ne $paqueteDepAnterior) {
				$mensaje .= "   Dependencia detectada en paquete: $paqueteDep\n";
				$paqueteDepAnterior = $paqueteDep;
				}
			$mensaje .=  "        |_ $type $item version $version\n";
			}
		$self->log->warn( $mensaje );
	} else {
		$mensaje .= "   No se detecto ninguna dependencia\n";
		$self->log->info( $mensaje );
		}		
	}

