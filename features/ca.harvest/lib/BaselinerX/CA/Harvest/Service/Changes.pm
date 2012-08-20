package BaselinerX::CA::Harvest::Service::Changes;
use Baseliner::Plug;
use Baseliner::Utils;
use Data::Dumper;

with 'Baseliner::Role::Service';

register 'config.ca.harvest.changes' => {
    name => 'Changes in Commonfiles and Menu associated to harvest packages',
    metadata => [
        { id=>'packageList', type=>'str' },
        { id=>'environment', type=>'str' },
    ]
};

register 'service.harvest.changes' => {
    name    => 'Detect changes in common files and menu associated to a list of packages',
    config  => 'config.ca.harvest.dependencies',
    show_in_menu => 0,
    handler => \&run,
};

sub run {
    my ( $self, $c, $p ) = @_;
    my $mensaje = "Cambios asociados a los paquetes " . _dump $p->{packageList};
    $mensaje .= "\n";
    $self->log->info( _loc($mensaje) );
    $mensaje = "";
	 
    _check_parameters( $p, qw/packageList/ );
	my @packages = _array $p->{packageList};
	
	my $packageList = "'harvest.package/" . join ('\', \'harvest.package/', _array $p->{packageList}) . "'";
    my $SQL = "";

    my %changes = ();
	my $dbh = Baseliner::Core::DBI->new({ model=>'Baseliner' });
    $SQL = "SELECT  v.id, SUBSTR(v.NS,17) \"Paquete\",
                    SRC_DIR||'/'||NOMBRE \"Fichero\",
                    change_type \"Tipo Accion\",
                    v.f_modif \"Fecha Modificacion\",
                    v.last_user \"Usuario\",
                    Clave || ' => ' || Valor \"Cambio => Valor\"
            FROM BALI_COMMONFILES f, BALI_COMMONFILES_VALUES v
            WHERE TRIM(v.ns) in ($packageList)
            AND v.fileid = f.ID
            order by 1,2,4";

    # print "$SQL\n";
 	%changes = $dbh->hash ( $SQL );
    $mensaje .= "\n\nCambios en Ficheros Comunes";
    if (%changes) {
        my $paqueteAnterior="";
        my $ficheroAnterior="";
        foreach my $id (sort(keys %changes)) {
            my ($paquete, $fichero, $accion, $f_modif, $user, $cambio) = @{$changes{$id}};
            if ($paquete ne $paqueteAnterior) {
                $mensaje .= "\n   |----PAQUETE: $paquete";
                $paqueteAnterior = $paquete;
                $ficheroAnterior="";
                }
            if ($fichero ne $ficheroAnterior) {
                $mensaje .= "\n   |   |---- FICHERO: $fichero";
                $mensaje .= "\n   |   |     |" . sprintf ("%-6s\t| %-19s\t| %-8s\t| %-80s","Accion","Fecha Modificacion","Usuario","Cambio => Valor") ;
                $ficheroAnterior = $fichero;
                }
            $mensaje .= "\n   |   |     |" . sprintf ("%-6s\t| %-19s\t| %-8s\t| %-80s",$accion,$f_modif,$user,$cambio) ;
            }
        $mensaje.="\n   |";
		$self->log->warn( _loc($mensaje) );
    } else {
		$mensaje.="\n   No se detectaron cambios en Ficheros Comunes para los paquetes $packageList\n";
        $self->log->info( _loc($mensaje) );
        }

    $mensaje=undef;
    $SQL = "SELECT PARENT || ID, NS, TEXTO FROM (
                SELECT C.PARENT_ID PARENT, C.ID ID, SUBSTR(C.NS,17) NS,
                CASE C.ACTION WHEN 'A' THEN 'Alta' WHEN 'B' THEN 'Baja' ELSE 'Modificación' END || ' de la carpeta \"' || C.ID || ': ' || C.NOM_ES|| '\" situada en la carpeta \"' || P.ID || ': ' || P.NOM_ES || '\"' TEXTO 
                FROM BALI_TP_MENU_CPT C,BALI_TP_MENU_CPT P
                WHERE 1=1
                  AND C.NS IN ($packageList)
                  AND C.PARENT_ID = P.ID
                UNION
                SELECT C.CPT_ID PARENT, C.ID ID, SUBSTR(C.NS,17) NS,
                CASE C.ACTION WHEN 'A' THEN 'Alta' WHEN 'B' THEN 'Baja' ELSE 'Modificación' END || ' de la operación \"' || C.ID || ': ' || C.TEXT_ES|| '\" situada en la carpeta \"' || P.ID || ': ' || P.NOM_ES || '\"' TEXTO 
                FROM BALI_TP_MENU_TRANS C,BALI_TP_MENU_CPT P
                WHERE 1=1
                  AND C.NS IN ($packageList)
                  AND C.CPT_ID = P.ID
                )
                ORDER BY 2, 1";

    # print "$SQL\n";
 	%changes = $dbh->hash ( $SQL );

    $mensaje .= "\nCambios en Menu de TP";
    if (%changes) {
		my $paqueteAnterior="";
        foreach my $key (sort {$changes{$a}[0] cmp $changes{$b}[0]} (keys(%changes))) {  
            my ($paquete, $texto) = @{$changes{$key}};
            if ($paquete ne $paqueteAnterior) {
				$mensaje .= "\n   |----PAQUETE: $paquete";
                $mensaje .= "\n   |   |---- FICHERO: menu_es-ES.xml";
                $paqueteAnterior = $paquete;
				}
			$mensaje .=  "\n   |   |     |----$texto";
			}
		$self->log->warn( _loc($mensaje) );
	} else {
		$mensaje .= "\n   No se detectaron cambios en el menu\n";
		$self->log->info( _loc($mensaje) );
		}		
	}
