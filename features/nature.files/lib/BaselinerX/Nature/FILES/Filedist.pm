package BaselinerX::Nature::FILES::Filedist;
use strict;
use Carp;
use Baseliner::Utils;
use File::Find;
use Data::Dumper;
use Try::Tiny;
use utf8;

my %SYSTEM =  (
	AIX => 'IBM AIX',
	WINDOWS => 'WINDOWS',
	LINUX => 'LINUX'
 );
 
my @TYPES = [ "EAR","PARCIAL","FICHEROS","SSRS" ];

## AIX unpack=>'cd "%s"; jar xvfm "%s" 2>%s 1>%s; rm "%s"' ## NO RECOGE EL RC DEL jar, SINO DEL RM
## unpack=>'cd "%s"; jar xvfm "%s" 2>%s 1>%s && rm "%s" || ( rm "%s"; test 1 -eq 2 )',
     
 my $COMMANDS = {
	AIX => {
			os => 'aix',
			home=>'/tmp',
			rmdir=>'rm -Rf "%s"',
			makedir=>'mkdir -p "%s"',
			#Los errores ahora se filtran
			unpack=>'cd "%s"; tar xvfm "%s" 2>%s 1>%s && rm "%s" || ( rm "%s"; test 1 -eq 2 )',
			clean=>'rm -f "%s" "%s" "%s"',	
			clean_remote=>'rm -f "%s"',	
			permission=>'cd "%s"; chmod -R 755 *',
			cat=>'cat "%s"'
	},
	WINDOWS => {
			os =>'win',
			home=>'C:\\TEMP',
			rmdir=>'rm /S/Q "%s"',
			makedir=>'md "%s"',
			unpack=>'cd "%s" && c:\\balix\\balix_tar.exe xvf "%s" 2>%s 1>%s && del "%s"',
			clean=>'del /Q/F "%s" "%s" "%s"',
			clean_remote=>'rm "%s"',	
			permission=>'cd "%s" && cacls * /T /E /C /G Everyone:F && cacls * /T /E /C /G GBP:F',
			unc_copy=>'xcopy /E /Y /R  %s\\*.* %s\\*.*',
			cat=>'type "%s"'
	}
 };

#	unc_copy=>'xcopy /E /Y /R  %s\\*.* %s\\*.* && rd /S/Q %s'

sub new {
    my $class = shift();
    my ($ns,$bl,$xtype) = @_;
    my @mappings = ();

    my $self = {
        bl  => $bl,
        ns => $ns,
        xtype => $xtype,
        mappings => @mappings,
    };
    bless( $self, $class );
}

sub load {
	my $self = shift();
	my $c = shift();
	my $query = shift();
	my @mappings = ();				

	my $finalQuery = "SELECT * FROM BALI_FILE_DIST WHERE NS in ('$self->{ns}','/') AND BL in ('$self->{bl}','*')";
	
	if(ref($self->{xtype}) eq 'ARRAY'){
		$finalQuery .= " AND XTYPE IN('" . join("','",@{$self->{xtype}}) . "')";	
	}else{
		$finalQuery .= " AND XTYPE = '$self->{xtype}'";
	}

	# warn "**********************RESULTADO DE SQL = $finalQuery";
	
	$finalQuery .= " AND (SRC_DIR LIKE '%$query%' OR DEST_DIR LIKE '%$query%' OR SSH_HOST LIKE '%$query%')" if $query;

	use Baseliner::Core::DBI;
    my $db = Baseliner::Core::DBI->new({ model=>'Baseliner' });
	
	# $c->stash->{job}->logger->debug("---------EJECUTANDO SQL: $finalQuery");
    @mappings = $db->array_hash($finalQuery);	
	# $c->stash->{job}->logger->debug("---------SE HA ENCONTRADO " . scalar @mappings . " mapeos.");
	$self->{mappings} = \@mappings;
}

sub save{
	my $self = shift();
	my $c = shift();
	my $mapping = shift();	
	
	my $rs = $c->model('Baseliner::BaliFileDist')->search({ ns=>$self->{ns}, bl=>$self->{bl}, id=>$mapping->{id} });	
			
	if (my $r = $rs->next){
		$r->set_columns($mapping);
		$r->update;
	}else{	
		my $r = $c->model('Baseliner::BaliFileDist')->create($mapping);				
		$r->update;
	}
		
}

sub delete {
	my $self = shift();
	my $c = shift();
	my $id = shift();
	
	#BaselinerX::Nature::FILES::SSHScript->deleteByFileDist($c,$id);	
	my $rs = $c->model('Baseliner::BaliFileDist')->search({ id=>$id });
	if(my $r = $rs->next){
		$r->delete;		
	}
}

sub distribuir{
	my $self = shift();
	my $c = shift();
	my $path = shift();
	my $white_list = shift();
	
	my @distribuciones = ();

	my $job = $c->stash->{job};
	my $log = $job->logger;  
	my $lastDistribucion = undef;
	my %nsScript;

	$log->debug("Distribucion de ficheros <b>" . $self->{xtype} . "</b>.");			

	for my $mapeo (@{$self->{mappings}}){
		$nsScript{$mapeo->{ns}}=$mapeo->{bl};
		}
	
	for my $NS (keys %nsScript){
		$self->ejecutarPreScripts($NS, $nsScript{$NS}, $log, $c, $path);
		}

	#$log->info("Distribucion de ficheros <b>" . $self->{xtype} . "</b>.",data=>YAML::Dump($self->{mappings}));			
	$log->debug("Generando <b>MAPEOS</b> definidos...",data=>YAML::Dump($self->{mappings}));		
	for my $mapeo (@{$self->{mappings}}){
		my $distribucion = $self->generarDistribucion($path,$mapeo,$log, $c, $white_list);
		$lastDistribucion = $distribucion if($distribucion ne undef);		
		push @distribuciones, $distribucion if($distribucion ne undef);			
	}

	$log->debug("Mapeos generados, pulse para ver la lista de paquetes mapeados.",data=>YAML::Dump(@distribuciones));	
	for my $distribucion (@distribuciones){
		$self->ejecutarDistribucion($path,$distribucion,$log, $c);
		$lastDistribucion = $distribucion;
		}
	
	#Despues de todas las distribuciones se ejecutan los scripts (para que este todo ya en destino)
	#Esto puede cambiar y ejecutarse o dentro de la distribucion o en el bucle de arriba, ahora se usa asi
	#Para ejecutar siempre un script en TP16
	for my $NS (keys %nsScript){
		$self->ejecutarPostScripts($NS, $nsScript{$NS}, $log, $c, $path);
		}
	
	$log->debug("Distribuciones ejecutadas.");
}

sub generarDistribucion{
	use File::Spec;

	my ($self, $path, $mapeo, $log, $c, $white_list) = @_;
	my $job = $c->stash->{job}->{job_data};
    my $job_stash = $c->stash->{job}->job_stash;
	   
	my $origen = $mapeo->{src_dir};
	$origen = File::Spec->catdir( $path, $origen );	
	
	$origen = "$1$2Ed$3" if ($origen =~ m/(.*)(TP16)(.*)\/#$/); ###### SOPORTE TP16 ##

	my $destino = $mapeo->{dest_dir};
	if ($destino =~ m/\$\{(.+)\}/) { ######## RESOLUCION VARIABLES DE CONFIGURACION ##
		my $cfgVar = $1 ;
		my $varValue=undef;
		($cfgVar,my $var)=($1,$2) if ($cfgVar =~ m/(.*)\.(\w+)$/);
		my $cfgTP = $c->model('ConfigStore')->get( $cfgVar, ns=>'/', bl=>'*' );
		if ($var eq 'versionTP16') { ###### SOPORTE TP16 ##
			$varValue=$cfgTP->{$var};
			my ($nVersion,$cAnexo)=($1,$2) if $varValue =~ m/^(\d+)(\w*)$/;
			my $nFROM=$1 if $nVersion =~ m/^(\d)\d*$/;
			my $nTO=$nFROM+1;
			
			$varValue="VERSION_${nFROM}01_A_${nTO}00\\ACT_${nVersion}.NET" if ! $cAnexo;
			$varValue="Anexos\\ANEX_${varValue}.NET" if $cAnexo;
			}

		$destino =~ s{\$\{$cfgVar\.$var\}}{$varValue};
		}

	######## RESOLUCION VARIABLES DE JOB ##
	my $_JOB = $job->{name};
	my $_JOBID = $job->{id};
	my $_DATE = $job->{starttime};
	   $_DATE =~ s{-|:|\s}{}g;

	$destino =~ s{\$\_JOB}{$_JOB};
	$destino =~ s{\$\_JOBID}{$_JOBID};
	$destino =~ s{\$\_DATE}{$_DATE};
	######## RESOLUCION VARIABLES DE JOB ##

	######## RESOLUCION VARIABLES DE JOB->STASH ##
	# if ( $job_stash->{filedist} ) {
		# }
	######## RESOLUCION VARIABLES DE JOB->STASH ##
	
	my @filtros = split(";",$mapeo->{filter});
	my @excluded = split(";",$mapeo->{exclussions});
	#my $opts = ($mapeo->{isrecursive} eq 1)?"":"-maxdepth 1";
	#maxdepth es solo soportado por GNU, si quieren cambiar la recursividad hay que meter el find de GNU
	my $opts = "";
	my $ssh_host = $mapeo->{ssh_host};

	$origen  =~ s{\$\_JOBID}{$_JOBID}g;
	$origen  =~ s{\$\_JOB}{$_JOB}g;
	$origen  =~ s{\$\_DATE}{$_DATE}g;
	$destino  =~ s{\$\_JOBID}{$_JOBID}g;
	$destino  =~ s{\$\_JOB}{$_JOB}g;
	$destino  =~ s{\$\_DATE}{$_DATE}g;

	utf8::downgrade($origen);
	utf8::downgrade($destino);
	return undef if(! -d $origen);
	
	my $filename = "tarfile_dist_$mapeo->{id}.tar";	

	my $filtro = "\\( -name \"" . join("\" -o -name \"",@filtros) . "\" \\)" if (scalar @filtros gt 0);
	my $exclude = "\\( ! -name \".harvest.sig\" ! -name \"*.tar\" ";
	if (scalar @excluded gt 0) {
		$exclude .= "! -name \"" . join("\" ! -name \"",@excluded) . "\" \\)" 
	} else {
		$exclude .= "\\)";
		}
	my $ruta = "$origen/$filename";

	my $command = "cd \"$origen\" ; find . $filtro $exclude -type f $opts ";
	my $precommand = $command;

	utf8::downgrade($command);

	_log $command;
	my $ficheros = `$command`;
	my $rc = $?;
	
	#$log->warn("No se han encontrado ficheros.",data=>$command)if(length($ficheros)<=1);
	return undef if(length($ficheros)<=1);
	
	if($rc ne 0){
		$log->warn("Fallo al buscar mapeo ($mapeo->{filter}) en la ruta $origen.", data=> "Comando: $precommand\n Error=$rc \nSalida: $ficheros");
		return undef;
	}
	
	## Damos soporte a la exclusión de elementos por filtros de carpeta. INI ##
	## Formateamos las exclusiones para adecuarlas a expresiones regulares.  ##
	my $EXCLUSSIONS=$mapeo->{exclussions};
	$EXCLUSSIONS=~s/\./\\\./g;
	$EXCLUSSIONS=~s/\*/.*/g;
	my @ExcludedFilters = split(";",$EXCLUSSIONS); 

	#Filtramos los ficheros encontrados con una lista de ficheros valida, esta modificacion viene de las distribuciones parciales
	#la finalidad de esto es evitar que se filtren ficheros no deseados en los mapeos.
	if(ref($white_list)){
		$log->debug("Se ha encontrado una lista de ficheros validos para una distribucion <b>PARCIAL</b>.<br/>Limpiando mapeos...");
		my $job_path = $job_stash->{path};
		my $final_path = $origen;
		$final_path =~ s/$job_path//g;
		my @ficheros_encotrados = split("\n",$ficheros);
		my @ficheros_validos = ();
		for my $fichero (@ficheros_encotrados){
			my $ruta_fichero = $final_path . "/" . $fichero;
			$ruta_fichero = File::Spec->canonpath($ruta_fichero);
			if(grep {$ruta_fichero =~ /$_/} @$white_list){
				push @ficheros_validos,$fichero;
			}
		}
		$ficheros = join("\n", @ficheros_validos);
		my $mapeos_limpiados = scalar(@ficheros_encotrados) - scalar(@ficheros_validos);
		$log->debug("Se han limpiado los mapeos, se han eliminado $mapeos_limpiados mapeos.",data=>"Ficheros validos:\n" . YAML::Dump(@ficheros_validos)); 
	}
	
	## SOPORTE a la exclusión de elementos por filtros de carpeta.       ##
	## Si algún fichero cumple alguna exclusión nos lo saltamos          ##
	my @filtro_ficheros=();
	my @filestoprocess=();
	@filestoprocess=split /\n/, $ficheros; 
	foreach my $fichero (@filestoprocess) {
		my $MATCH=0;
		foreach (@ExcludedFilters) {
			my $filtro = $_;
			$filtro .= "\$" if $_ !~ m/^\/.*\/$/;
			if ($fichero=~m/$filtro/g) {
				$log->debug("Excluido $fichero por filtro $filtro");
				$MATCH=1;
				last;
				}
			}
		next if $MATCH eq 1;
		push @filtro_ficheros,$fichero;
		}
	$ficheros = join("\n", @filtro_ficheros); ## Actualizo la lista de ficheros con los filtros de exclusión aplicados.
	## SOPORTE a la exclusión de elementos por filtros de carpeta.  FIN  ##

	#Para no perder ni una ocurrencia he cambiado la forma de generar la lista que va en el tar	
	#$ficheros=~s/(.*)\n/"$1" /g;
	
	my $tmp_file = _tmp_file prefix=>'tar_filedist';	
	open my $fichero_temporal, ">", $tmp_file;
	print $fichero_temporal $ficheros . "\n";
	close($fichero_temporal);
	
	# $command = "cd \"$origen\" ; cat $tmp_file | xargs tar cvf \"$ruta\"";
	$command = qq(cd "$origen" ; cat $tmp_file | awk ' { printf("%s%s%s","\\"", \$0, "\\"\\n"); } ' | xargs tar cvf "$ruta");
	$precommand = $command;
	utf8::downgrade($command);
	my $ret = `$command`;
	$rc = $?;	
	unlink $fichero_temporal unless $rc;
	
	utf8::downgrade($ruta);
	if(not -e $ruta){
		$log->warn("Fallo al empaquetar el mapeo $mapeo->{id} (Es posible que no exista en el paquete).", data=> "Comando: $precommand\n Error=$rc \nSalida: $ret") if($rc ne 0);
		return undef;
	}
	
	my $script4unc = '';
	#Vamos a incluir mapeo directo para rutas UNC
	if($destino=~ /^(\\*\w+)/ and $mapeo->{sys} eq $SYSTEM{WINDOWS} and $ssh_host eq ''){
		my $staging4unc = $c->model('ConfigStore')->get( 'config.nature.files', ns=>'/', bl=>'*' );
		my $unc_conn = $staging4unc->{staging4unc};
		$ssh_host = $unc_conn;
		if( $unc_conn =~ /^(\w+)\:(\/\/.*)=(.*)/ ) {
			my $home  = "$3\\\\" . $c->stash->{job}->{name} ;
			my $destino_original = $destino;
			$destino =~ s/^(\\*\w+)/$home/;
			
			$script4unc = $self->getCmd($mapeo->{sys}, 'unc_copy', $destino, $destino_original, $destino);	
		}else{
			$log->warn("No se ha podido generar el mapeo $mapeo->{id} no hay cadena de conexion ni maquina de paso para copia UNC.", data=> YAML::Dump($mapeo));
		}
	}

	return {		id=>$mapeo->{id},
					ns=>$mapeo->{ns},
					bl=>$mapeo->{bl},
					dir_origen=>$origen,
					fichero=>$filename,
					dir_destino=>$destino,
					ssh=>$ssh_host,
					sys=>$mapeo->{sys},
					mapeo=>$mapeo,
					script=>$script4unc
					};
}

sub ejecutarDistribucion{
	my ($self, $path, $distribucion, $log, $c) = @_;
	my $command;	
	my $precommand;

	my $tryout = 0;	
	reinicioDistribucion: $tryout = 1;
	
	$log->debug("Ejecutando distribucion.",data=>YAML::Dump($distribucion));
	
	my $fs_remoto = Baseliner::Core::Filesys->new( home=>$distribucion->{ssh} );
	# $log->debug("FS REMOTO CREADO .",data=>YAML::Dump( $fs_remoto ));
	$log->debug("Conexion establecida con " . $distribucion->{ssh});
	
#	$command = $self->getCmd($distribucion->{sys}, 'rmdir', $distribucion->{dir_destino});
	$command = $self->getCmd($distribucion->{sys}, 'makedir', $distribucion->{dir_destino});
	utf8::downgrade($command);
	my ($rc,$ret) = $fs_remoto->execute({cmd=>$command});
	#$log->warn("No se pudo crear el directorio de destino $distribucion->{dir_destino}.", data=>$ret) if($rc!=0);
	
	my $pathOrigen = File::Spec->catfile($distribucion->{dir_origen},$distribucion->{fichero});
	my $pathDestino = File::Spec->catfile($distribucion->{dir_destino},$distribucion->{fichero});
	my $pathLogErr = File::Spec->catfile($distribucion->{dir_destino},$distribucion->{fichero} . "_err.log");
	my $pathLogRet = File::Spec->catfile($distribucion->{dir_destino},$distribucion->{fichero} .  "_ret.log");
	if ($distribucion->{sys} eq 'WINDOWS') {
		$pathDestino =~ s/\//\\\\/g;
		$pathLogErr =~ s/\//\\\\/g;
		$pathLogRet =~ s/\//\\\\/g;
		}
	
	# $log->debug("ORIGEN  = $pathOrigen\nDESTINO = $pathDestino");	
	utf8::downgrade($pathOrigen);
	utf8::downgrade($pathDestino);
	utf8::downgrade($pathLogErr);
	utf8::downgrade($pathLogRet);

	if(-e $pathOrigen){
		# $log->debug("Existe  $pathOrigen ");	
		# Llevamos el archivo tar a la máquina destino.

		try{
			# $log->debug("fs_remoto->put( from=>\"$pathOrigen\", to_file=> \"$pathDestino\" );");
			
			($rc,$ret) = $fs_remoto->put( from=>"$pathOrigen", to_file=> "$pathDestino" ); 		
			$command = $self->getCmd($distribucion->{sys}, 'clean_remote', "$pathOrigen");
			$precommand = $command;
			utf8::downgrade($command);
			
			# $log->debug("COMMAND: $command");
			
			$ret = `$command`;
			$rc = $?;
			$log->warn("No se ha podido eliminar el paquete de distribucion ($precommand).", data=>$ret) if($rc ne 0);		
		}catch {
			my $E = shift;	
			$log->error("Error al transferir $pathOrigen a $pathDestino.", data=>$E);
			die("No es posible copiar el paquete de distribucion $distribucion->{fichero}.");	
		};

		# $log->debug("Copiado $ret ...");	
		
		#Comando de descompresion del tar
		$command = $self->getCmd($distribucion->{sys}, 'unpack', $distribucion->{dir_destino}, $distribucion->{fichero}, $pathLogErr, $pathLogRet, $distribucion->{fichero});
		utf8::downgrade($command);

		# $log->debug("Ejecutando comando de descompresion: $command");
		($rc,$ret) = $fs_remoto->execute({cmd=>$command, pure=>1});
		# DESABILITADO PARA HACER EL SISTEMA TOLERANTE A ERRORES
		# if($rc!=0){
			# if($tryout eq 0){
				# $log->warn("Error al desempaquetar $distribucion->{fichero} en $distribucion->{dir_destino}.<BR>Intentando volver a generar paquete...", data=>$ret);
				# my $nuevaDistribucion = $self->generarDistribucion($path,$distribucion->{mapeo},$log);
				# if($nuevaDistribucion!=undef){
					# goto reinicioDistribucion;
				# }else{
					# $log->error("Error al volver a generar $distribucion->{fichero}.<BR>Se va a proceder a la finalizacion del pase...", data=>$ret);
					# die("Error volver a generar $distribucion->{fichero}, la distribucion finalizara.");				
				# }			
			# }else{
				# $log->error("Error al volver a desempaquetar $distribucion->{fichero} en $distribucion->{dir_destino}.<BR>No se volvera a intentar...", data=>"Comando: $command, Salida: $ret");
				# die("Error desempaquetando $distribucion->{fichero}, la distribucion finalizara.");
			# }
		# }else{
			# $log->info("Se ha distribuido el mapeo contenido en $distribucion->{fichero} en $distribucion->{dir_destino}, revise la salida para preever posibles errores.",data=>$ret);
		# } 	

		# warn "COMMAND: $command\nRC: $rc\nRET: $ret"; 

		my ($tmp_rc,$tmp_logRet,$tmp_logErr);

		$command = $self->getCmd($distribucion->{sys}, 'cat', "$pathLogRet");
		utf8::downgrade($command);
		($tmp_rc, $tmp_logRet) = $fs_remoto->execute({cmd=>$command, pure=>1});
		$command = $self->getCmd($distribucion->{sys}, 'cat', "$pathLogErr");
		utf8::downgrade($command);
		($tmp_rc, $tmp_logErr) = $fs_remoto->execute({cmd=>$command, pure=>1});
		
		if($rc!=0){		
			$log->warn("Se han producido algunos errores al desempaquetar el mapeo de origen $distribucion->{dir_origen} en destino $distribucion->{dir_destino} ", data=>"Comando: $command\n\n Errores:" . $tmp_logErr . "\n\n Salida:" . $tmp_logRet ."\n\n");
			$log->warn("El pase continua pero debe <b>REVISAR</b> el contenido de la salida de la traza anterior.");
		}else{
			$log->info("Se ha distribuido el mapeo contenido en $distribucion->{fichero} en $distribucion->{dir_destino}, revise la salida para preever posibles errores.",data=>$tmp_logRet);
		} 			

		
		#Comando de limpieza
		$command = $self->getCmd($distribucion->{sys}, 'clean', $pathDestino , $pathLogErr, $pathLogRet);
		utf8::downgrade($command);
		($rc,$ret) = $fs_remoto->execute({cmd=>$command});
		$log->warn("No he podido eliminar el paquete temporal $command, debera borrarse de forma manual.", data=>"Comando=$command\nError:$ret") if($rc!=0);
		# warn "Limpieza origen realizada : $command $rc: $ret";


		#Comando de permisos
		my $CanonPath = File::Spec->canonpath($distribucion->{dir_destino});	    
		$command = $self->getCmd($distribucion->{sys}, 'permission', $CanonPath);	
		utf8::downgrade($command);
		# warn "COMANDO PERMISOS: $command";
		($rc,$ret) = $fs_remoto->execute({cmd=>$command});
		$log->warn("No he podido cambiar permisos en $CanonPath.", data=>$ret) if($rc!=0);
		# $log->debug("Cambiados permisos en $CanonPath.", data=>$ret) if($rc eq 0);

		
		#Comando de unc
		if($distribucion->{script} ne ''){
			$command = $distribucion->{script};			
			utf8::downgrade($command);
			($rc,$ret) = $fs_remoto->execute({cmd=>$command});
			if($rc!=0){
				$log->error("No he podido ejecutar el comando UNC $command, la distribucion no se esta realizando como deberia.", data=>"Comando=$command\nError:$ret");
				die("Error ejecutando distribucion UNC");
			}else{
				$log->debug("El comando UNC $command se ha ejecutado correctamente.", data=>"Comando=$command\nResultado:$ret") if($rc==0);
			}
		}
		
		
		# TODO - limpiar directorio intermedio UNC
		
		
		# $log->debug("Distribucion terminada.");	
		$fs_remoto->end();
		return 1;
		# my @scripts = BaselinerX::Nature::FILES::SSHScript->getFromFileDistId($c,$distribucion->{id});	
		# my @sorted_scripts =  sort { $a->{xorder} <=> $b->{xorder} } @scripts;
		
		# for my $script (@sorted_scripts){
			# my $script_command = $script->{script};
			# my $script_params = $script->{params};
			# $script_params =~ s/;/ /;			
			
			# $log->debug("Ejecutando script: '$script_command $script_params'.",data=>YAML::Dump($script));
			
			# $fs_remoto = Baseliner::Core::Filesys->new( home=>'$script->{ssh_host}' );

			# ($rc,$ret) = $fs_remoto->execute(qq{$script_command $script_params});
			# if($rc!=0){
				# $log->error("No es posible ejecutar  '$script_command $script_params'.", data=>$ret);
				# die("El script '$script_command $script_params' ha devuelto un error.");	
			# } 			
			# $fs_remoto->end();			
			# $log->info("El script '$script_command $script_params' se ha ejecutado correctamente.",data=>$ret);
		# }
	}else{
		$log->debug("El fichero de mapeo " . $distribucion->{fichero} ." no se ha creado por que no existe en el paquete.");
		return 0;
	}		
	return 1;
}

sub getFileContents{
	my ($self,$path) = @_;
	my $fileCotents = do {
			local $/;
			open my $fh, $path or return "";
			<$fh>
	};
	return $fileCotents;
}

sub ejecutarPreScripts{
	my ($self, $ns, $bl, $log, $c, $path) = @_;
	$log->debug("Ejecutando <b>PRE-SCRIPTS</b>: $ns, $bl, $path, " . BaselinerX::Nature::FILES::SSHScript->TIPO_PRE . ", " . $self->{xtype});
	$self->ejecutarScripts( $ns, $bl, $log, $c, $path, BaselinerX::Nature::FILES::SSHScript->TIPO_PRE);
}

sub ejecutarPostScripts{
	my ($self, $ns, $bl, $log, $c, $path) = @_;
	$log->debug("Ejecutando <b>POST-SCRIPTS</b>: $ns, $bl, $path, " . BaselinerX::Nature::FILES::SSHScript->TIPO_POST . ", " . $self->{xtype});
	$self->ejecutarScripts( $ns, $bl, $log, $c, $path, BaselinerX::Nature::FILES::SSHScript->TIPO_POST);
}

sub ejecutarScripts{
	my ($self, $ns, $bl, $log, $c, $path, $tipo) = @_;
	
	my $job = $c->stash->{job};
	my $job_stash = $job->job_stash;

	my @scripts = BaselinerX::Nature::FILES::SSHScript->getFromNamespace($c,$ns, $bl, $tipo, $self->{xtype});
	my @sorted_scripts =  sort { $a->{xorder} <=> $b->{xorder} } @scripts;

	for my $script (@sorted_scripts){
		my $script_command = $script->{script};
		my $script_params = $script->{params};
		$script_params =~ s/;/ /g;			
		my $command = $script_command . " " . $script_params;
		$command=~s/\\\\/\\/g;
		
		$command=~s/\{path\}/$path/g;

## PARAMETROS EN $c->stash->{filedist}
	my $Params=$job_stash->{filedist};
	if ($$$Params{nature} eq $self->{xtype}) {
    foreach my $param (keys %$$Params) {
		next if $param eq "nature";
        $command.= " $param $$$Params{$param}";
		}		
	# $log->info("Comando a ejecutar $command");
	}
## ###################################

		my $fs_remoto = Baseliner::Core::Filesys->new( home=>$script->{ssh_host});

		utf8::downgrade($command);
		
		my ($rc,$ret) = $fs_remoto->execute({cmd=>$command});
		if ($rc != 0) {
			$log->error("No es posible ejecutar el ${tipo}-SCRIPT '$command'.", data=>$ret);
			die("El ${tipo}-SCRIPT '$command' ha devuelto un error.");	
		} 			
		$fs_remoto->end();			
		$log->info("El ${tipo}-SCRIPT '$command' se ha ejecutado correctamente.",data=>$ret);
	}
}

sub getCmd{
	my ($self,$sys,$command,@values) = @_;
	my $cmd = $COMMANDS->{$sys};
	my $output = sprintf ($cmd->{$command}, @values);
	$output=~s/\\\\/\\/g;	
	return $output;
}

sub getSistemas{
	my @keys = keys %SYSTEM;
	return \@keys;
}

sub getTipoDistribuciones{
	return @TYPES;
}

sub ahora {
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
	localtime(time);
	$year += 1900;
	$mon  += 1;
	sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour}, ${min}, ${sec};
	}
1;
