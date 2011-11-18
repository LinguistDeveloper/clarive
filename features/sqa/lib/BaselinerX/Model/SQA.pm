#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.PROD0000054132
#	Fecha de pase .................... 2011/11/18 07:01:32
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/sqa/lib/BaselinerX/Model/SQA.pm
#	Versión del elemento ............. 2
#	Propietario de la version ........ infroox (INFROOX - RODRIGO DE OLIVEIRA GONZALEZ)

package BaselinerX::Model::SQA;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);

BEGIN { extends 'Catalyst::Model' }

sub update_status {    # actualiza el status de una fila en el portal
	my ( $self, %p ) = @_;
	my $project              = $p{project};
	my $sp                   = $p{subproject};
	my $subproject           = $sp->{subproject};
	my $nature               = $sp->{nature};
	my $status               = $p{status};
	my $job_bl               = $p{bl};
	my $job_id               = $p{job_id};
	my $job_row              = {};
	my $projectid            = '';
	my $subproject_row       = '';                          #fila de subproyecto
	my $subprojectnature_row = '';                          #fila de subproyecto
	my $nivel                = $p{nivel} || 'subproject';
	my $tsstart              = $p{tsstart};
	my $tsend                = $p{tsend};
	my $type                 = $p{type};
	my $packages             = $p{packages};
	my $username             = $p{username};
	my $pass                 = $p{pass};
	my $pid                  = $p{pid};
	my $path                 = $p{path};
	my $job_name               = $p{job_name};
	
	my $harvest_project 	 = $project;

	_log( _loc("####### Updating status to $status") );
	if ( $pass && $tsend ) {
		$job_row =
		  Baseliner->model('Baseliner::BaliSqa')->search( { job => $pass } )
		  ->first;
	}
	else {
		if ($job_id) {
			$job_row = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
		}
		else {
			$project = substr( $project, 0, 3 );
			_log "Buscando project con nombre *$project*";
			my $project_row;

			$project_row =
			  Baseliner->model('Baseliner::BaliProject')
			  ->search( { name => $project, id_parent => { '=', undef } } )
			  ->first;

			if ( !$project_row ) {
				_log "El project *$project* no existe";
				$project_row =
				  Baseliner->model('Baseliner::BaliProject')
				  ->create( { name => $project, ns => '/', bl => '*' } );
				_log "El project *$project* ahora existe.  File creada";
				if ( $type ne 'package' ) {
					$subproject_row =
					  Baseliner->model('Baseliner::BaliProject')->create(
						{
							name      => lc($subproject),
							id_parent => $project_row->id,
							ns        => '/',
							bl        => '*'
						}
					  ) if $nivel ne 'CAM';
					_log "Subproject $subproject creado";
					$subprojectnature_row =
					  Baseliner->model('Baseliner::BaliProject')->create(
						{
							name      => $subproject,
							id_parent => $project_row->id,
							nature    => $nature,
							ns        => '/',
							bl        => '*'
						}
					  ) if $nivel !~ /CAM|subapp/;
					_log "SubprojectNature $subproject/$nature creado";
				}
			}
			else {

				if ( $nivel ne 'CAM' ) {
					$subproject_row =
					  Baseliner->model('Baseliner::BaliProject')->search(
						{
							name      => lc($subproject),
							id_parent => $project_row->id
						}
					  )->first;

					if ( !$subproject_row ) {
						_log
						  "No he encontrado ninguna fila para el subproyecto "
						  . lc($subproject)
						  . " hijo de "
						  . $project_row->id;
						$subproject_row =
						  Baseliner->model('Baseliner::BaliProject')->create(
							{
								name      => lc($subproject),
								id_parent => $project_row->id,
								ns        => '/',
								bl        => '*'
							}
						  );
					}
					if ( $nivel ne 'subapp' ) {
						$subprojectnature_row =
						  Baseliner->model('Baseliner::BaliProject')->search(
							{
								name      => $subproject,
								nature    => $nature,
								id_parent => $subproject_row->id
							}
						  )->first;

						if ( !$subprojectnature_row ) {
							$subprojectnature_row =
							  Baseliner->model('Baseliner::BaliProject')
							  ->create(
								{
									name      => $subproject,
									nature    => $nature,
									id_parent => $subproject_row->id,
									ns        => '/',
									bl        => '*'
								}
							  );
						}
					}
				}
			}
			if ( $nivel eq 'CAM' ) {
				if ( $type ne 'package' ) {
					$job_row = Baseliner->model('Baseliner::BaliSqa')->search(
						{
							ns     => $project,
							bl     => $job_bl,
							id_prj => $project_row->id
						}
					)->first;
					if ( !$job_row ) {
						$job_row =
						  Baseliner->model('Baseliner::BaliSqa')->create(
							{
								ns     => $project,
								bl     => $job_bl,
								id_prj => $project_row->id,
								type   => 'CAM'
							}
						  );
					}
				}
				else {
					$job_row = Baseliner->model('Baseliner::BaliSqa')->create(
						{
							ns     => $project,
							bl     => $job_bl,
							id_prj => $project_row->id,
							type   => 'PKG'
						}
					);
					_log(
						_loc("########## Analysis row for packages created") );
				}
			}
			elsif ( $nivel eq 'subapp' ) {
				$job_row = Baseliner->model('Baseliner::BaliSqa')->search(
					{
						ns     => $project,
						bl     => $job_bl,
						id_prj => $subproject_row->id
					}
				)->first;
				if ( !$job_row ) {
					$job_row = Baseliner->model('Baseliner::BaliSqa')->create(
						{
							ns     => $project,
							bl     => $job_bl,
							id_prj => $subproject_row->id,
							type   => 'SUB'
						}
					);
				}
			}
			else {
				$job_row = Baseliner->model('Baseliner::BaliSqa')->search(
					{
						ns     => $project,
						bl     => $job_bl,
						nature => $nature,
						id_prj => $subprojectnature_row->id
					}
				)->first;
				if ( !$job_row ) {
					$job_row = Baseliner->model('Baseliner::BaliSqa')->create(
						{
							ns     => $project,
							bl     => $job_bl,
							nature => $nature,
							id_prj => $subprojectnature_row->id,
							type   => 'NAT'
						}
					);
				}
			}
		}
	}

	if ($job_row) {
		my $hash_data;
		#_log "Lo que hay en el data de la fila: "._dump $hash_data;
		$job_id = $job_row->id;

		if ( $tsend || $tsstart ) {
			my $db = new Baseliner::Core::DBI( { model => 'Baseliner' } );
			my @date = $db->array_hash("SELECT sysdate FROM dual");

			my $value   = shift @date;
			my $sysdate = $value->{sysdate};

			if ($tsstart) {
				$job_row->tsstart($sysdate);
				$job_row->tsend(undef);
				$job_row->data(undef);
				$job_row->update;
			}
			if ($tsend) {
				$job_row->tsend($sysdate);
				$job_row->pid(undef);
				$job_row->path(undef);
			}			
		}

		_log "Miro si hay paquetes";
		if ( $packages ) {
			$hash_data->{PACKAGES} = [ _array $packages ];
		}
				
		$job_row->data( _dump $hash_data ) if $hash_data;
		$job_row->job($job_name)	  if $job_name;
		$job_row->job($pass)          if $pass;
		$job_row->username($username) if $username;
		$job_row->pid($pid)           if $pid;
		$job_row->path($path)           if $path;
		$job_row->status($status);
		$job_row->update;

		_log "Id de la fila: " . $job_id;
	}
	$job_id;
}

sub ship_project {    # envia un proyecto (subapl+nature) a SQA
	my ( $self, %p ) = @_;

	my $config     = Baseliner->model('ConfigStore')->get('config.sqa');
	my $job_id     = $p{job_id};
	my $sp         = $p{subproject};
	my $subproject = $sp->{subproject};
	my $project    = $p{project};
	my $nature     = $sp->{nature};
	my $bl         = $p{bl};
	my $path       = $p{job_dir};
	my $job_name   = $p{job_name};
	my $IAS        = $sp->{IAS};
	my $username   = $p{username};

	my ( $rc, $ret, $xml, $html, $compileTests, $mstestResults, $junitResults );

	#Cambiamos el nombre del proceso, que mola mucho
	$0 = "baseliner SQA_Analysis_${project}_${subproject}_${nature}_${bl}_${job_name}_${job_id}";

	$self->update_status( job_id => $job_id, status => 'WAITING FOR SLOT' );

	my $sem = Baseliner->model('Semaphores')->request(
		sem => 'sqa.analysis',
		who => "SQA Job: $job_id  $project/$subproject/$nature",
		bl  => '*'
	);

	$self->update_status( job_id => $job_id, status => 'RUNNING', pid => $$, path => $config->{dir_pase} . "\\" . $job_name . $subproject . $nature, job_name => $job_name );

	#	if ($nature) {
	#		$self->start_analisys_mail(
	#			bl         => $bl,
	#			project    => $project,
	#			subproject => $subproject,
	#			nature     => $nature,
	#			username   => $username,
	#			job_id     => $job_id
	#		);
	#	}

	_log "CAM: $project";
	_log "Subaplicación: $subproject";
	_log "Naturaleza: $nature";

	$compileTests = 0;

	for my $source ( _array $sp->{sources} ) {
		_log "Source: $source";
		$compileTests = 1
		  if $nature =~ /J2EE|JAVABATCH/ && $source eq $subproject . "_TEST";
	}

	for my $output ( _array $sp->{output} ) {
		_log "Output: $output";
	}

	# XML
	my $bx;
	try {
		$bx = BaselinerX::Comm::Balix->new(
			host => $config->{server},
			port => $config->{port},
			key  => $config->{key}
		);
	} catch {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$sem->release;
		$self->write_sqa_error( job_id => $job_id, html => _loc( "Could not connect to sqa server %1",$config->{server}) , type => "pre", reason => 'No se ha podido conectar al servidor de SQA.  Consulte con el administrador de SQA' );
		die _loc( "Could not connect to sqa server %1",
			$config->{server} )
		  . "\n";		
	};

	# Creamos el directorio de pase
	my $dir_pase =
	  $config->{dir_pase} . "\\" . $job_name . $subproject . $nature;
	( $rc, $ret ) = $bx->execute(qq{ mkdir "$dir_pase" });

	if ( $rc gt 1 ) {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al crear el directorio en el servidor de SQA. ¿No hay espacio en disco?  Consulte con el administrador de SQA' );
		$bx->close();
		$sem->release;
		die _loc( "Error when creating job dir RC=%1:%2", $rc, $ret ) . "\n";
	}
	else {
		_log "Job directory created succesfully ... " . $dir_pase . " (RC=$rc)";
	}

	#Generamos el tar con los fuentes
	my $CAM     = substr( $project, 0, 3 );
	my $CAMPath = substr( $project, 0, 3 );
	if ( $nature =~ /NET/ ) {
		$CAMPath = $CAM;
	}
	else {
		$CAMPath = $CAM;
	}

	my $natureFinal = '';
	if ( $nature eq 'JAVABATCH' ) {
		$natureFinal = 'J2EE';
	}
	else {
		$natureFinal = $nature;
	}

	my $tarfile = "$path/$CAMPath/${subproject}_${nature}_src.jar";
	my $prjs = join " ", _unique _array $sp->{sources};
	_log "cd $path/$CAMPath/$natureFinal;jar cvf $tarfile $prjs";
	my $RET = `cd "$path/$CAMPath/$natureFinal";jar cvf "$tarfile" $prjs`;

	#Enviamos el tar al directorio de trabajo del job en la máquina de SQA
	_log "Sending file $dir_pase\\src.jar";
	$rc = 1;
	( $rc, $ret ) = $bx->sendFile( $tarfile, "$dir_pase\\src.jar" );
	if ( $rc ne 0 ) {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al enviar el fichero de fuentes al servidor de SQA. ¿No hay espacio en disco?  Consulte con el administrador de SQA' );
		$bx->close();
		$sem->release;
		die _loc( "Error when sending sources tar file %1:%2", $tarfile, $ret )
		  . "\n";
	}

	#Descomprimimos el tar de fuentes en el destino
	_log "Unjarring $dir_pase\\src.jar";
	$rc = 1;
	( $rc, $ret ) = $bx->execute(
qq{ mkdir $dir_pase\\$config->{source_dir} & cd /D "$dir_pase"\\$config->{source_dir} & $config->{jar_exe} xvf ..\\src.jar }
	);
	if ( $rc ne 0 ) {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al descomprimir el fichero de fuentes en el servidor de SQA. ¿No hay espacio en disco?  Consulte con el administrador de SQA' );
		$bx->close();
		$sem->release;
		die _loc( "Error when unjarring sources file RC=%1:%2", $rc, $ret )
		  . "\n";
	}
	else {
		( $rc, $ret ) = $bx->execute(qq{ cd /D "$dir_pase" & del src.jar });
		_log "Fichero src.jar borrado";
	}

	#Enviamos si existe el fichero con los compilados
	if ( $nature =~ /NET/ ) {
		$natureFinal = "NET";
	}
	elsif ( $nature =~ /BIZTALK/ ) {
		$natureFinal = "BIZT";
	}
	else {
		$natureFinal = $nature;
	}
	my $exe_file = "";

	$exe_file = file $path,
	  sprintf( "sqa-%s-%s.jar", $natureFinal, $subproject );

	$natureFinal = $nature =~ /BIZT/ ? 'BIZTALK' : $natureFinal;

	_log "Looking for file $exe_file";

	if ( -e $exe_file ) {
		_log "$exe_file exists";
		$rc = 1;
		( $rc, $ret ) = $bx->sendFile( $exe_file, "$dir_pase\\build.jar" );
		if ( $rc ne 0 ) {
			$self->update_status(
				job_id => $job_id,
				status => 'BALI ERROR',
				tsend  => 1
			);
			$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al enviar el fichero de ejecutables al servidor de SQA. ¿No hay espacio en disco?  Consulte con el administrador de SQA' );
			$bx->close();
			$sem->release;
			die _loc( "Error when sending sources builds file %1:%2",
				$exe_file, $ret )
			  . "\n";
		}
		$rc = 1;

		#Descomprimimos el tar de ejecutables en el destino
		( $rc, $ret ) = $bx->execute(
qq{ mkdir "$dir_pase"\\$config->{builds_dir} & cd /D "$dir_pase"\\$config->{builds_dir} & $config->{jar_exe} xvf ..\\build.jar }
		);
		if ( $rc ne 0 ) {
			$self->update_status(
				job_id => $job_id,
				status => 'BALI ERROR',
				tsend  => 1
			);
			$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al descomprimir el fichero de ejecutables en el servidor de SQA. ¿No hay espacio en disco?  Consulte con el administrador de SQA' );
			$bx->close();
			$sem->release;
			die _loc( "Error when untarring builds file RC=%1:%2", $rc, $ret )
			  . "\n";
		}
		else {
			( $rc, $ret ) =
			  $bx->execute(qq{ cd /D "$dir_pase" & del build.jar });
			_log "Fichero src.jar borrado";
		}
	}
	else {
		_log "$exe_file DOES NOT exists";
	}

	# Hay que compilar la aplicación de tests para J2EE?

	if ($compileTests) {

		my $compileScript =
qq{ call ant -f $config->{compile_script} -DTestProjectDir=$dir_pase\\$config->{source_dir}\\${subproject}_TEST };
		_log
"Ejecutando script de compilación del proyecto de tests $dir_pase\\$config->{source_dir}\\${subproject}_TEST";
		$rc = 1;
		( $rc, $ret ) = $bx->execute($compileScript);

		if ( $rc ne 0 ) {
			_log "Ha habido un error en la compilación del proyecto de TEST";
		}
		_log "$ret";
	}

	#Ejecución del script
	my $recalc = '';
	$recalc = "Recalc" if $config->{debug} eq 1;

	$natureFinal = $nature =~ /NET/ ? "NET" : $natureFinal;

	my $script =
qq{cd /D $config->{script_dir} & call ant -f $config->{script_name} $recalc -Dtecnologia=$natureFinal -DinputDir="$dir_pase" -Dentorno=$bl -DCAM="$CAM" -Dproyecto="$project" -Dsubapp="$subproject" -DlocalReport.dir="$dir_pase" };
	$script = $script . ' -Darquitectura=IAS' if $IAS;

	#$script = $script.' & echo %errorlevel% ';
	_log "Ejecutando ... " . $script;
	$rc = 1;
	( $rc, $ret ) = $bx->execute($script);
	_log "Script ran. RC=$rc. Output=$ret";

	unless ($rc) {
		( $rc, $xml ) = $bx->execute(qq{type "$dir_pase"\\$config->{file}});
		( $rc, $html ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_html}});
		( $rc, $mstestResults ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_mstest}});
		( $rc, $junitResults ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_junit}});

		$self->update_status( job_id => $job_id, status => 'DONE' );
		$self->grab_results(
			xml        => $xml,
			job_id     => $job_id,
			html       => $html,
			project    => $project,
			subproject => $sp,
			nature     => $nature,
			bl         => $bl,
			mstest     => $mstestResults,
			junit      => $junitResults,
			level      => 'NAT'
		);
		$self->calculate_aggregates(
			CAM        => $CAM,
			xml        => $xml,
			job_id     => $job_id,
			project    => $project,
			subproject => $sp,
			nature     => $nature,
			bl         => $bl,
			bx         => $bx,
			dir_pase   => $dir_pase
		);
		if ( $config->{remove_dir} ) {
			_log "Removing $dir_pase";

			my $out;
			( $rc, $out ) = $bx->execute(qq{rmdir /S /Q "$dir_pase"});
			if ( $rc ne 0 ) {
				_log "Could not remove $dir_pase.  Remove manually";
			}
		}
	}
	else {
		$self->update_status(
			job_id => $job_id,
			status => 'SQA ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error en la ejecuci&oacute;n del análisis en el servidor de SQA.  Consulte con el administrador de SQA' );
	}
	$bx->close();
	$sem->release;
}

sub ship_packages_project {    # envia un proyecto (subapl+nature) a SQA
	my ( $self, %p ) = @_;

	my $config   = Baseliner->model('ConfigStore')->get('config.sqa');
	my $job_id   = $p{job_id};
	my $project  = $p{project};
	my $bl       = $p{bl};
	my $path     = $p{job_dir};
	my $job_name = $p{job_name};
	my $packages = $p{packages};
	my $username = $p{username};
	my ( $rc, $ret, $csv );

	$self->update_status( job_id => $job_id, status => 'WAITING FOR SLOT' );

	$0 = "baseliner SQA_Package_Analysis_${project}_${job_name}_${job_id}";

	my $sem = Baseliner->model('Semaphores')->request(
		sem => 'sqa.analysis',
		who => "SQA Packages Job: $job_id  $project",
		bl  => '*'
	);

	_log("##### Starting critical region");

	$self->update_status( job_id => $job_id, status => 'RUNNING', pid => $$, path => $config->{dir_pase} . "\\" . $job_name . "-packages", packages => $packages, job_name => $job_name );

	#	$self->start_pkg_analisys_mail(
	#		project  => $project,
	#		username => $username,
	#		job_id   => $job_id,
	#		packages => $packages
	#	);

	_log "CAM: $project";

	# XML
	my $bx;
	try {
		$bx = BaselinerX::Comm::Balix->new(
			host => $config->{server},
			port => $config->{port},
			key  => $config->{key}
		);
	} catch {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$sem->release;
		$self->write_sqa_error( job_id => $job_id, html => _loc( "Could not connect to sqa server %1",$config->{server}) , type => "pre", reason => 'No se ha podido conectar al servidor de SQA.  Consulte con el administrador de SQA' );
		die _loc( "Could not connect to sqa server %1",
			$config->{server} )
		  . "\n";		
	};

	# Creamos el directorio de pase
	my $dir_pase = $config->{dir_pase} . "\\" . $job_name . "-packages";
	( $rc, $ret ) = $bx->execute(qq{ mkdir "$dir_pase" });

	if ( $rc gt 1 ) {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$bx->close();
		$sem->release;
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al crear el directorio de pase en el servidor de SQA.  ¿No hay espacio en disco? Consulte con el administrador de SQA' );
		die _loc( "Error when creating job dir RC=%1:%2", $rc, $ret ) . "\n";
	}

	#Generamos el tar con los fuentes
	my $CAM = substr( $project, 0, 3 );
	my $CAMPath = $project;

	my $tarfile = "$path/${CAM}_src.jar";
	my $prjs    = ${CAMPath};
	my $RET     = `cd "$path";jar cvf "$tarfile" $prjs`;

	#Enviamos el tar al directorio de trabajo del job en la máquina de SQA
	_log "Sending file $dir_pase\\src.jar";
	( $rc, $ret ) = $bx->sendFile( $tarfile, "$dir_pase\\src.jar" );
	if ( $rc ne 0 ) {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$bx->close();
		$sem->release;
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al enviar el comprimido de fuentes al servidor de SQA.  ¿No hay espacio en disco? Consulte con el administrador de SQA' );
		die _loc( "Error when sending sources tar file %1:%2", $tarfile, $ret )
		  . "\n";
	}

	#Descomprimimos el tar de fuentes en el destino
	_log "Unjarring $dir_pase\\src.jar";

	( $rc, $ret ) = $bx->execute(
qq{ mkdir "$dir_pase"\\$config->{source_dir} & cd /D $dir_pase\\$config->{source_dir} & $config->{jar_exe} xvf ..\\src.jar }
	);
	if ( $rc ne 0 ) {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$bx->close();
		$sem->release;
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al descomprimir el fichero de fuentes en el servidor de SQA.  ¿No hay espacio en disco? Consulte con el administrador de SQA' );
		die _loc( "Error when unjarring sources file RC=%1:%2", $rc, $ret )
		  . "\n";

	}
	else {
		( $rc, $ret ) = $bx->execute(qq{ cd /D "$dir_pase" & del src.jar });
		_log "Fichero src.jar borrado";
	}

	#ejecuci&oacute;n del script
	my $recalc = '';
	$recalc = "paquete";

	my $script =
qq{cd /D $config->{script_dir} & call ant -f $config->{script_name} $recalc -DinputDir="$dir_pase" -DCAM="$CAM" -Dpaquete="$job_name" -Dproyecto="$project" };
	_log "Ejecutando ... " . $script;
	( $rc, $ret ) = $bx->execute($script);
	_log "Script ran. RC=$rc. Output=$ret";

	unless ($rc) {
		( $rc, $csv ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{languages_file}});
		$self->update_status( job_id => $job_id, status => 'DONE' );
		$self->grab_package_results(
			csv      => $csv,
			job_id   => $job_id,
			project  => $project,
			bl       => $bl,
			packages => $packages
		);
		if ( $config->{remove_dir} ) {
			_log "Removing $dir_pase";

			my $out;
			( $rc, $out ) = $bx->execute(qq{rmdir /S /Q "$dir_pase"});
			if ( $rc ne 0 ) {
				_log "Could not remove $dir_pase.  Remove manually";
			}
		}
		$self->write_sqa_error( job_id => $job_id, html => $ret );
	}
	else {
		$self->update_status(
			job_id => $job_id,
			status => 'SQA ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al ejecutar el script de ejecuci&oacute;n de análisis de la subaplicación/naturaleza.  Consulte con el administrador de SQA' );
		
	}
	$bx->close();
	$sem->release;
}

sub calculate_aggregates {
	my ( $self, %p ) = @_;
	my $project    = $p{project};
	my $sp         = $p{subproject};
	my $CAM        = $p{CAM};
	my $subproject = $sp->{subproject};
	my $bl         = $p{bl};
	my $bx         = $p{bx};
	my $dir_pase   = $p{dir_pase};
	my ( $rc, $ret, $xml, $html );

	my $config = Baseliner->model('ConfigStore')->get('config.sqa');
	my $job_id = $p{job_id};

	#Calculamos el agregado por subaplicación
	my $script =
qq{cd /D $config->{script_dir} & call ant -f $config->{script_name} Subaplicacion -Dsubapp="$subproject" -Dentorno=$bl -DCAM="$CAM" -Dproyecto="$project" -DinputDir="$dir_pase"};
	_log "Ejecutando ... " . $script;
	$job_id = $self->update_status(
		status     => 'RUNNING',
		project    => $CAM,
		subproject => $sp,
		bl         => $bl,
		nivel      => 'subapp',
		tsstart    => 1,
		pid        => $$
	);
	( $rc, $ret ) = $bx->execute($script);
	_log "Script ran. RC=$rc. Output=$ret";
	unless ($rc) {
		( $rc, $xml ) = $bx->execute(qq{type "$dir_pase"\\$config->{file}});
		( $rc, $html ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_html}});
		$self->update_status( job_id => $job_id, status => 'DONE' );
		_log "He pasado el DONE";
		$self->grab_results(
			xml        => $xml,
			job_id     => $job_id,
			html       => $html,
			project    => $project,
			subproject => $sp,
			bl         => $bl,
			level      => 'SUB'
		);
	}
	else {
		$self->update_status( job_id => $job_id, status => 'SQA ERROR', tsend => 1 );
		$self->write_sqa_error( job_id => $job_id, html => $ret , type => "pre", reason => 'Ha ocurrido un error al ejecutar el script de ejecuci&oacute;n de análisis de la subaplicación.  Consulte con el administrador de SQA' );
	}

	#Calculamos el agregado por CAM
	$script =
qq{cd /D $config->{script_dir} & call ant -f $config->{script_name} CAM -Dentorno=$bl -DCAM="$CAM" -Dproyecto="$project" -DinputDir="$dir_pase" };
	_log "Ejecutando ... " . $script;
	$job_id = $self->update_status(
		status  => 'RUNNING',
		project => $CAM,
		bl      => $bl,
		nivel   => 'CAM',
		tsstart => 1,
		pid     => $$
	);
	( $rc, $ret ) = $bx->execute($script);
	_log "Script ran. RC=$rc. Output=$ret";
	unless ($rc) {
		( $rc, $xml ) = $bx->execute(qq{type "$dir_pase"\\$config->{file}});
		( $rc, $html ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_html}});
		$self->update_status( job_id => $job_id, status => 'DONE' );
		$self->grab_results(
			xml        => $xml,
			job_id     => $job_id,
			html       => $html,
			project    => $project,
			subproject => $sp,
			bl         => $bl,
			level      => 'CAM'
		);
	}
	else {
		$self->update_status( job_id => $job_id, status => 'SQA ERROR', tsend => 1 );
		$self->write_sqa_error( job_id => $job_id, html => $ret, type => "pre", reason => 'Ha ocurrido un error al ejecutar el script de ejecuci&oacute;n de análisis del CAM.  Consulte con el administrador de SQA' );
	}
}

sub calculate_aggregate {
	my ( $self, %p ) = @_;
	my $project    = $p{project};
	my $CAM        = substr( $project, 0, 3 );
	my $subproject = $p{subproject};
	my $nature     = $p{nature};
	my $bl         = $p{bl};
	my $level      = $p{level};
	my $job_id     = $p{job_id};

	my ( $rc, $ret, $xml, $html, $return, $mstestResults, $junitResults );
	_log "**************************** Empiezo el calculate_aggregate ";
	my $config = Baseliner->model('ConfigStore')->get('config.sqa');
	_log "**************************** Después del config ";
	my $dir_pase = $config->{dir_pase} . "\\" . $CAM . "_PACKAGES_" . _nowstamp;

	_log "************ DIRECTORIO DE PASE: $dir_pase";

	# XML
	my $bx;
	try {
		$bx = BaselinerX::Comm::Balix->new(
			host => $config->{server},
			port => $config->{port},
			key  => $config->{key}
		);
	} catch {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => _loc( "Could not connect to sqa server %1",$config->{server}) , type => "pre", reason => 'No se ha podido conectar al servidor de SQA.  Consulte con el administrador de SQA' );
		die _loc( "Could not connect to sqa server %1",
			$config->{server} )
		  . "\n";		
	};

	( $rc, $ret ) = $bx->execute(qq{mkdir "$dir_pase"});

	my $subnature = '';
	if ( $subproject ne '*none' ) {
		$subnature = " -Dsubapp=" . $subproject;
	}
	if ( $nature ne '*none' ) {
		my $natureFinal = $nature eq ".NET" ? "NET" : $nature;
		$subnature .= " -Dtecnologia=" . $natureFinal;
	}

	my $script =
qq{cd /D $config->{script_dir} & call ant -f $config->{script_name} $level $subnature -Dentorno=$bl -DCAM="$CAM" -Dproyecto="$project" -DinputDir="$dir_pase"};
	_log "Ejecutando ... " . $script;
	if ( $level eq "Subaplicacion" ) {
		$job_id = $self->update_status(
			status     => 'RUNNING',
			project    => $CAM,
			subproject => { subproject => $subproject, nature => $nature },
			bl         => $bl,
			nivel      => 'subapp',
			tsstart    => 1,
			job_id     => $job_id,
			pid        => $$
		);
	}
	elsif ( $level eq "CAM" ) {
		$job_id = $self->update_status(
			status  => 'RUNNING',
			project => $CAM,
			bl      => $bl,
			nivel   => 'CAM',
			tsstart => 1,
			job_id  => $job_id,
			pid     => $$
		);
	}
	else {
		$job_id = $self->update_status(
			status     => 'RUNNING',
			project    => $CAM,
			subproject => { subproject => $subproject, nature => $nature },
			bl         => $bl,
			nivel      => 'nature',
			tsstart    => 1,
			job_id     => $job_id,
			pid        => $$
		);
	}

	( $rc, $ret ) = $bx->execute($script);
	_log "Script ran. RC=$rc. Output=$ret";
	unless ($rc) {
		( $rc, $xml ) = $bx->execute(qq{type "$dir_pase"\\$config->{file}});
		( $rc, $html ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_html}});
		( $rc, $mstestResults ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_mstest}});
		( $rc, $junitResults ) =
		  $bx->execute(qq{type "$dir_pase"\\$config->{file_junit}});

		$self->update_status( job_id => $job_id, status => 'DONE' );
		$self->grab_results(
			xml        => $xml,
			job_id     => $job_id,
			html       => $html,
			project    => $project,
			subproject => { subproject => $subproject, nature => $nature },
			bl         => $bl,
			mstest     => $mstestResults,
			junit      => $junitResults
		);
		if ( $config->{remove_dir} ) {
			_log "Removing $dir_pase";

			my $out;
			( $rc, $out ) = $bx->execute(qq{rmdir /S /Q "$dir_pase"});
			if ( $rc ne 0 ) {
				_log "Could not remove $dir_pase.  Remove manually";
			}
		}
		$return = 1;
	}
	else {
		$self->update_status( job_id => $job_id, status => 'SQA ERROR', tsend => 1 );
		$self->write_sqa_error( job_id => $job_id, html => $ret, type => "pre", reason => 'Ha ocurrido un error al ejecutar el script de ejecuci&oacute;n de an&aacute;lisis de agregado.  Consulte con el administrador de SQA' );
		$return = 0;
	}

	$bx->end if ref $bx;

	# Calculamos los agregados

	if ( $level eq "Recalc" ) {
		$self->calculate_aggregate(
			bl         => $bl,
			project    => $project,
			subproject => $subproject,
			nature     => $nature,
			level      => "Subaplicacion"
		);
	}
	elsif ( $level eq "Subaplicacion" ) {
		$self->calculate_aggregate(
			bl         => $bl,
			project    => $project,
			subproject => $subproject,
			nature     => $nature,
			level      => "CAM"
		);
	}

	return $return;
}

sub write_sqa_error {
	my ( $self, %p ) = @_;
	my $job_id = $p{job_id};
	my $html   = $p{html};
	my $pass   = $p{pass};
	my $type   = $p{type} || 'out';
	my $reason = $p{reason};

	$html =~ s/\n/<br>/g;

	my $row       = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $hash_data = $row->data;
	my $html_final = "";
	
	if ( $type eq 'pre' ) {
		$html_final = "<body>\n";
		$html_final .= "<p>$reason</p>\n";
		$html_final .= "<hr>\nDETALLES\n";
		$html_final .= "<pre>".$html."</pre>\n";
		$html_final .= "</body>";
	} else {
		$html_final = $html;
	}

	$hash_data->{html} = $html_final;

	$row->data( _dump $hash_data );
	$row->job($pass) if $pass;
	$row->update;

	if ( !$pass ) {
		$self->error_analisys_mail( job_id => $job_id );
	}
}

sub grab_results {    # recupera resultados
	my ( $self, %p ) = @_;

	my $config     = Baseliner->model('ConfigStore')->get('config.sqa');
	my $sp         = $p{subproject};
	my $subproject = $sp->{subproject};
	my $project    = $p{project};
	my $nature     = $sp->{nature};
	my $bl         = $p{bl};
	my $job_id     = $p{job_id};
	my $xml        = $p{xml};
	my $html       = $p{html};
	my $mstest     = $p{mstest};
	my $junit      = $p{junit};
	my $level      = $p{level};

	my $hash_data = {};

	$self->update_status( job_id => $job_id, status => 'ANALYZING RESULTS' );

	my $x = XML::Simple->new;
	my $data;
	my $row = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $result;

	try {

		#$xml =~ s{>}{>\n}gs;
		$data = $x->XMLin($xml);
	}
	catch {
		$xml =~ s{>}{>\n}gs;
		$data = $x->XMLin($xml);
		$result = "SQA ERROR" unless $data;
	};

	my $global_hash = {};
	my $qualification;

	if ($data) {
		$result        = $data->{result}{value};
		$qualification = $data->{result}{qualification};
		my $ts         = $data->{timestamp};
		my $category   = $config->{indicadores_category};
		my $checkpoint = $config->{indicadores_checkpoint};
		my $global;

		if ( ref $data->{category}{$category} ) {
			$global =
			  $data->{category}{$category}{checkpoint}{$checkpoint}{violation};
		}
		else {
			$global = $data->{category}{checkpoint}{$checkpoint}{violation};
		}

		for my $linea ( _array $global ) {
			$linea =~ s/\"| |\n|.$//g;

			my ( $indicador, $valor ) = split ":", $linea;
			$valor =~ s/,/\./g;

			#$valor= sprintf("%.2f", $valor);
			$global_hash->{$indicador} = $valor;
		}

		if ( $nature =~ /NET|J2EE/ ) {
			my @fichero = ();

			my $URL                 = "";
			my $URL_prefix          = "";
			my $URL_suffix_errors   = "";
			my $URL_suffix_coverage = "";

			if ( $nature =~ /NET/ && $mstest ) {
				@fichero             = split "\n", $mstest;
				$URL_prefix          = $config->{url_mstest};
				$URL_suffix_errors   = $config->{file_mstest_errors};
				$URL_suffix_coverage = $config->{file_mstest_coverage};
			}
			elsif ( $nature =~ /J2EE/ && $junit ) {
				@fichero             = split "\n", $junit;
				$URL_prefix          = $config->{url_junit};
				$URL_suffix_errors   = $config->{file_junit_errors};
				$URL_suffix_coverage = $config->{file_junit_coverage};
			}
			if ( @fichero eq 2 ) {
				my @cabecera = split ";", $fichero[0];
				my @valores  = split ";", $fichero[1];
				my %datos    = {};
				my $i        = 0;
				foreach (@cabecera) {
					my $clave;
					if ( $_ =~ /cobertura/ ) {
						$clave = "cobertura";
					}
					else {
						$clave = $_;
					}
					$datos{$clave} = $valores[ $i++ ];
				}

				$URL =
				  $URL_prefix . $datos{proyecto} . "/" . $URL_suffix_coverage;
				$hash_data->{url_cobertura} = $URL;
				$URL =
				  $URL_prefix . $datos{proyecto} . "/" . $URL_suffix_errors;
				$hash_data->{url_errores} = $URL;

				$hash_data->{tests_errores}   = $datos{"% error/fallo"};
				$hash_data->{tests_cobertura} = $datos{"cobertura"};
			}
		}

		#_log _dump ( $data );

		$hash_data->{scores}      = $global;
		$hash_data->{html}        = $html;
		$hash_data->{indicadores} = $global_hash;
		$hash_data->{harvest_project} = $project;

		my $url       = $config->{url};
		my $file_html = $config->{file_html};

	#$hash_data->{ URL } = $url."/$bl/$project/$subproject/$nature/".$file_html;

		$hash_data->{prev_qualification} = $row->qualification;

		#$row->qualification( $qualification );
		$row->qualification( $global_hash->{GLOBAL} );
		$qualification = $global_hash->{GLOBAL};

		if ( $level && $level eq 'NAT' ) {
			$self->end_analisys_mail(
				bl            => $bl,
				project       => $project,
				subproject    => $subproject,
				nature        => $nature,
				qualification => $qualification,
				result        => _loc($result),
				job_id        => $job_id,
				status        => $result,
				indicators    => _dump $hash_data->{scores}
			);
		}
	} else {
		$hash_data->{xml} = $xml;
		write_sqa_error( job_id => $job_id, html => $xml, type => "pre", reason => "Ha ocurrido un error al interpretar el XML de resultado del an&aacute;lisis.  Consulte con el administrador de SQA" );
		$result = "SQA ERROR";
	}

	$row->data( _dump $hash_data );
	$row->update;

	$self->update_status( job_id => $job_id, status => $result, tsend => 1 );

}

sub grab_package_results {    # recupera resultados
	my ( $self, %p ) = @_;

	my $config   = Baseliner->model('ConfigStore')->get('config.sqa');
	my $project  = $p{project};
	my $job_id   = $p{job_id};
	my $csv      = $p{csv};
	my $packages = $p{packages};

	my $hash_data = {};

	_log "*********************FICHERO DE RESULTADOS;\n\n$csv";

	$self->update_status( job_id => $job_id, status => 'ANALYZING RESULTS' );

	my $row = Baseliner->model('Baseliner::BaliSqa')->find($job_id);

	#$hash_data = _load( $row->data ) if $row->data;

	my @acsv = split "\n", $csv;

	_log "***********************filas en csv: @acsv";

	my $cnt   = 0;
	my $links = {};

	for my $linea (@acsv) {
		unless ( $cnt eq 0 ) {
			_log "***********************fila $cnt .... $linea";
			my @fields = split ";", $linea;
			$hash_data->{URLS}->{ $fields[2] } =
			    $config->{url_reports}
			  . $fields[1]
			  . "/report"
			  . $fields[2] . ".html";
			$links->{ $fields[2] } =
			    $config->{url_reports}
			  . $fields[1]
			  . "/report"
			  . $fields[2] . ".html";
			_log "****************************** añadido "
			  . $config->{url_reports}
			  . $fields[1]
			  . "/report"
			  . $fields[2]
			  . ".html al hash";
		}
		$cnt++;
	}

	$hash_data->{PACKAGES} = [ _array $packages ];

	$hash_data->{harvest_project} = $project;
	
	$row->data( _dump $hash_data );
	$row->update;

	$self->update_status( job_id => $job_id, status => "OK", tsend => 1 );

	$self->end_pkg_analisys_mail(
		project  => $project,
		job_id   => $job_id,
		packages => $packages,
		links    => $links
	);
}

sub request_analysis {
	my ( $self, %p ) = @_;

	my $config     = Baseliner->model('ConfigStore')->get('config.sqa');
	my $project    = $p{project};
	my $subproject = $p{subproject};
	my $nature     = $p{nature};
	my $user       = $p{user};
	my $bl         = $p{bl};
	my $job_id     = $p{job_id};
	my $return     = 1;

	my $type = 'pre';
	my $reason = '';
	
	my $bx;
	try {
		$bx = BaselinerX::Comm::Balix->new(
			host => $config->{dist_server},
			port => $config->{dist_port},
			key  => $config->{dist_key}
		);
	} catch {
		$return = 0;
		$self->update_status(
			status => 'SCM ERROR',
			job_id => $job_id,
			tsend  => 1,
			tsstart    => 1
		);
		$self->write_sqa_error( html=> _loc("Could not connect to dist server %1", $config->{dist_server}), job_id => $job_id, type => "pre", reason => "Ha ocurrido un error al conectar al servidor de SCM.  Probablemente está desconectado o existe algún problema de red.  Consulte con el administrador de SCM");
		die _loc("Could not connect to dist server %1", $config->{dist_server});
	  };

	my $script =
qq{cd $config->{dist_udp_dir} ; perl AltaDistribucionNodist.pl N $user "$project" "$subproject" $nature $bl now now };
	_log "Ejecutando ... " . $script;

	my ( $rc, $ret ) = $bx->executeas( $config->{dist_user}, $script );
	my $pass = '';

	if ( $rc ne 0 ) {
		$return = 0;
		$self->update_status(
			status => 'SCM ERROR',
			job_id => $job_id,
			tsend  => 1,
			tsstart    => 1
		);
		$self->write_sqa_error( html=> $ret, job_id => $job_id, type => "pre", reason => "Ha ocurrido un error solicitar el alta de pase sin distribuci&oacute;n.  Probablemente no hay código fuente para hacer el an&aacute;lisis en el estado seleccionado para la aplicación");
	}
	else {
		$ret =~ /.*\?pase\=(.*)'>.*/;
		$pass = $1;
		$job_id = $self->update_status(
			status     => 'ANALYSIS REQUESTED',
			project    => $project,
			subproject => { subproject => $subproject, nature => $nature },
			bl         => $bl,
			tsstart    => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => $ret, pass => $pass );	
	}
	
	_log "$ret";
	return $return;
}

sub getProjectConfigAll {
	my ( $self, %p ) = @_;
	my $bl         = $p{bl};
	my $value      = $p{value};
	my $project    = $p{project};
	my $subproject = $p{subproject};
	my $nature     = $p{nature};

	my $config;
	my $return;
	my $row_config;

	my $row_subproject =
	  Baseliner->model('Baseliner::BaliProject')
	  ->search( { name => lc($subproject), nature => { '=', undef } } )->first;
	my $row_project =
	  Baseliner->model('Baseliner::BaliProject')
	  ->search( { name => $project, id_parent => { '=', undef } } )->first;

	# rod: find first matching parent
	#    try - protects against null method calling in ->parent->parent
	my $row_subnat = try {
		my @rows = Baseliner->model('Baseliner::BaliProject')
		->search( { name => $subproject, nature => $nature,  } )->all;
		for( @rows ) {
			return $_ if $_->parent->parent->id == $row_project->id;
		}
	};
	
	my $row_subnat_config;
	my $row_camnat_config;
	my $row_subproject_config;
	my $row_project_config;
	my $row_global_nature;
	my $row_global;

	if ($row_subnat) {    # Hay fila de proyecto busco su configuraci—n
		$row_subnat_config =
		  Baseliner->model('Baseliner::BaliConfig')
		  ->search(
			{ bl => $bl, ns => 'project/' . $row_subnat->id, key => $value } )
		  ->first;
		if ($row_subnat_config) {    # Si hay configuraci—n, la uso
			$return = $row_subnat_config->value;
			_log "************ CONFIGURACION DE SUBAPLICACION/NATURALEZA";
		}
		else
		{   # No hay configuraci—n, busco la configuraci—n de CAM/naturaleza
			_log "************ NO HAY SUBAPLICACION/NATURALEZA";
			$row_camnat_config =
			  Baseliner->model('Baseliner::BaliConfig')->search(
				{
					bl  => $bl,
					ns  => 'nature/' . $nature . '/' . $row_project->id,
					key => $value
				}
			  )->first;
			if ($row_camnat_config)
			{    # Hay configuraci—n CAM/Naturaleza.  La uso
				$return = $row_camnat_config->value;
				_log "************ CONFIGURACION DE CAM/NATURALEZA";
			}
			else
			{ # No hay configuraci—n de CAM/Naturaleza.  Uso la de subaplicaci—n
				_log "************ NO HAY DE CAM/NATURALEZA";
				if ($row_subproject)
				{    # Hay fila de subproyecto. Busco su configuraci—n
					$row_subproject_config =
					  Baseliner->model('Baseliner::BaliConfig')->search(
						{
							bl  => $bl,
							ns  => 'project/' . $row_subproject->id,
							key => $value
						}
					  )->first;
					if ($row_subproject_config)
					{    #Hay configuraci—n de subproyecto.  La uso
						$return = $row_subproject_config->value;
						_log "************ CONFIGURACION DE SUBAPLICACION";
					}
					else
					{  #No hay configuraci—n de subproyecto.  Busco la del CAM
						_log "************ NO HAY DE SUBAPLICACION";
						$row_project_config =
						  Baseliner->model('Baseliner::BaliConfig')->search(
							{
								bl  => $bl,
								ns  => 'project/' . $row_project->id,
								key => $value
							}
						  )->first;
						if ($row_project_config)
						{    # Hay configuraci—n del CAM.  La uso
							$return = $row_project_config->value;
							_log "************ CONFIGURACION DE CAM";
						}
						else
						{ # No hay configuraci—n del CAM.  Uso de de la naturaleza global.  Si no hay se usar‡ la global

#							$config = Baseliner->model('ConfigStore')->get('config.sqa',ns =>'nature/'.$nature, bl => $bl);
#							$return = $config->{$value};
							_log "************ NO HAY DE CAM";
							$row_global_nature =
							  Baseliner->model('Baseliner::BaliConfig')->search(
								{
									bl  => $bl,
									ns  => 'nature/' . $nature,
									key => $value
								}
							  )->first;
							if ($row_global_nature)
							{    # Hay configuraci—n del CAM.  La uso
								$return = $row_global_nature->value;
								_log
"************ CONFIGURACION GLOBAL DE NATURALEZA";
							}
							else
							{ # No hay configuraci—n global de naturaleza.  Uso la global.
								_log "************ NO HAY GLOBAL DE NATURALEZA";
								$row_global =
								  Baseliner->model('Baseliner::BaliConfig')
								  ->search(
									{ bl => $bl, ns => '/', key => $value } )
								  ->first;
								if ($row_global)
								{    # Hay configuraci—n del CAM.  La uso
									$return = $row_global->value;
									_log "************ CONFIGURACION GLOBAL";
								}
							}
						}
					}
				}
				else
				{   # No hay fila de subproyecto. Uso la configuraci—n del CAM
					$row_project_config =
					  Baseliner->model('Baseliner::BaliConfig')->search(
						{
							bl  => $bl,
							ns  => 'project/' . $row_project->id,
							key => $value
						}
					  )->first;
					if ($row_project_config)
					{    # Hay configuraci—n del CAM.  La uso
						$return = $row_project_config->value;
						_log "************ CONFIGURACION DE CAM";
					}
					else
					{ # No hay configuraci—n del CAM.  Uso de de la naturaleza global.  Si no hay se usar‡ la global
						$row_global_nature =
						  Baseliner->model('Baseliner::BaliConfig')->search(
							{
								bl  => $bl,
								ns  => 'nature/' . $nature,
								key => $value
							}
						  )->first;
						if ($row_global_nature)
						{    # Hay configuraci—n del CAM.  La uso
							$return = $row_global_nature->value;
							_log
"************ CONFIGURACION GLOBAL DE NATURALEZA";
						}
						else
						{ # No hay configuraci—n global de naturaleza.  Uso la global.
							$row_global =
							  Baseliner->model('Baseliner::BaliConfig')
							  ->search(
								{ bl => $bl, ns => '/', key => $value } )
							  ->first;
							if ($row_global)
							{    # Hay configuraci—n del CAM.  La uso
								$return = $row_global->value;
								_log "************ CONFIGURACION GLOBAL";
							}
						}
					}
				}
			}
		}
	}
	else
	{ # No hay fila de subaplicaci—n/naturaleza, busco la configuraci—n de CAM/naturaleza
		$row_camnat_config = Baseliner->model('Baseliner::BaliConfig')->search(
			{
				bl  => $bl,
				ns  => 'nature/' . $nature . '/' . $row_project->id,
				key => $value
			}
		)->first;
		if ($row_camnat_config) {  # Hay configuraci—n CAM/Naturaleza.  La uso
			$return = $row_camnat_config->value;
			_log "************ CONFIGURACION DE CAM/NATURALEZA";
		}
		else
		{ # No hay configuraci—n de CAM/Naturaleza.  Uso la de subaplicaci—n
			if ($row_subproject)
			{    # Hay fila de subproyecto. Busco su configuraci—n
				$row_subproject_config =
				  Baseliner->model('Baseliner::BaliConfig')->search(
					{
						bl  => $bl,
						ns  => 'project/' . $row_subproject->id,
						key => $value
					}
				  )->first;
				if ($row_subproject_config)
				{    #Hay configuraci—n de subproyecto.  La uso
					$return = $row_subproject_config->value;
					_log "************ CONFIGURACION DE SUBAPLICACION";
				}
				else { #No hay configuraci—n de subproyecto.  Busco la del CAM
					$row_project_config =
					  Baseliner->model('Baseliner::BaliConfig')->search(
						{
							bl  => $bl,
							ns  => 'project/' . $row_project->id,
							key => $value
						}
					  )->first;
					if ($row_project_config)
					{    # Hay configuraci—n del CAM.  La uso
						$return = $row_project_config->value;
						_log "************ CONFIGURACION DE CAM";
					}
					else
					{ # No hay configuraci—n del CAM.  Uso de de la naturaleza global.  Si no hay se usar‡ la global
						$row_global_nature =
						  Baseliner->model('Baseliner::BaliConfig')->search(
							{
								bl  => $bl,
								ns  => 'nature/' . $nature,
								key => $value
							}
						  )->first;
						if ($row_global_nature)
						{    # Hay configuraci—n del CAM.  La uso
							$return = $row_global_nature->value;
							_log
"************ CONFIGURACION GLOBAL DE NATURALEZA";
						}
						else
						{ # No hay configuraci—n global de naturaleza.  Uso la global.
							$row_global =
							  Baseliner->model('Baseliner::BaliConfig')
							  ->search(
								{ bl => $bl, ns => '/', key => $value } )
							  ->first;
							if ($row_global)
							{    # Hay configuraci—n global.  La uso
								$return = $row_global->value;
								_log "************ CONFIGURACION GLOBAL";
							}
						}
					}
				}
			}
			else {  # No hay fila de subproyecto. Uso la configuraci—n del CAM
				$row_project_config =
				  Baseliner->model('Baseliner::BaliConfig')->search(
					{
						bl  => $bl,
						ns  => 'project/' . $row_project->id,
						key => $value
					}
				  )->first;
				if ($row_project_config)
				{    # Hay configuraci—n del CAM.  La uso
					$return = $row_project_config->value;
					_log "************ CONFIGURACION DE CAM";
				}
				else
				{ # No hay configuraci—n del CAM.  Uso de de la naturaleza global.  Si no hay se usar‡ la global
					$row_global_nature =
					  Baseliner->model('Baseliner::BaliConfig')
					  ->search(
						{ bl => $bl, ns => 'nature/' . $nature, key => $value }
					  )->first;
					if ($row_global_nature)
					{    # Hay configuraci—n del CAM.  La uso
						$return = $row_global_nature->value;
						_log "************ CONFIGURACION GLOBAL DE NATURALEZA";
					}
					else
					{ # No hay configuraci—n global de naturaleza.  Uso la global.
						$row_global =
						  Baseliner->model('Baseliner::BaliConfig')
						  ->search( { bl => $bl, ns => '/', key => $value } )
						  ->first;
						if ($row_global) { # Hay configuraci—n global.  La uso
							$return = $row_global->value;
							_log "************ CONFIGURACION GLOBAL";
						}
					}
				}
			}
		}
	}
	return $return;
}

sub getProjectConfigAll_old {
	my ( $self, %p ) = @_;
	my $bl         = $p{bl};
	my $value      = $p{value};
	my $project    = $p{project};
	my $subproject = $p{subproject};
	my $nature     = $p{nature};

	my $return;

	my $row =
	  Baseliner->model('Baseliner::BaliProject')
	  ->search( { name => $subproject, nature => $nature } )->first;

	if ( !$row ) {

	}

	my $config;

	if ($row) {
		_log "***** Project id: " . $row->id;
		$config =
		  Baseliner->model('ConfigStore')
		  ->get( 'config.sqa', ns => 'project/' . $row->id, bl => $bl );
		if ( $config->{$value} ) {
			$return = $config->{$value};
			_log "****** Nivel: subaplicaci—n/naturaleza";
			_dump $config;
		}
		elsif ( $row->parent && $row->parent->parent ) {
			$config = Baseliner->model('ConfigStore')->get(
				'config.sqa',
				ns => 'nature/' . $nature . '/' . $row->parent->parent->id,
				bl => $bl
			);
			if ( $config->{$value} ) {
				$return = $config->{$value};
			}
			elsif ( $row->parent ) {
				$config = Baseliner->model('ConfigStore')->get(
					'config.sqa',
					ns => 'project/' . $row->parent->id,
					bl => $bl
				);
				if ( $config->{$value} ) {
					$return = $config->{$value};
				}
				elsif ( $row->parent->parent ) {
					$config = Baseliner->model('ConfigStore')->get(
						'config.sqa',
						ns => 'project/' . $row->parent->parent->id,
						bl => $bl
					);
					if ( $config->{$value} ) {
						$return = $config->{$value};
					}
				}
				else {
					$config =
					  Baseliner->model('ConfigStore')
					  ->get( 'config.sqa', ns => '/', bl => $bl );
					$return = $config->{$value};
				}
			}
		}
		else {
			$config =
			  Baseliner->model('ConfigStore')
			  ->get( 'config.sqa', ns => '/', bl => $bl );
			$return = $config->{$value};
		}
	}
	else {
		$row =
		  Baseliner->model('Baseliner::BaliProject')
		  ->search( { name => lc($subproject) } )->first;
		if ( !$row ) {
			$row =
			  Baseliner->model('Baseliner::BaliProject')
			  ->search( { name => $project } )->first;
		}
		$config =
		  Baseliner->model('ConfigStore')
		  ->get( 'config.sqa', ns => '/', bl => $bl );
		$return = $config->{$value};
	}
	return $return;
}

sub getProjectLastStatus {
	my ( $self, %p ) = @_;
	my $bl_dest    = $p{bl};
	my $project    = $p{project};
	my $subproject = $p{subproject};
	my $nature     = $p{nature};

	my $bl = { TEST => 'DESA', ANTE => 'TEST', PROD => 'ANTE' };
	my $return = {};

	my $rs =
	  Baseliner->model('Baseliner::BaliProject')
	  ->search( { name => $subproject, nature => $nature } );

	$return->{value} = 'N';
	while ( my $row = $rs->next ) {
		if (   $row->parent
			&& $row->parent->parent
			&& $row->parent->parent->name eq $project )
		{
			my $row_sqa =
			  Baseliner->model('Baseliner::BaliSqa')
			  ->search( { id_prj => $row->id, bl => $bl->{$bl_dest} } )->first;
			if ($row_sqa) {
				_log "Último status en "
				  . $bl->{$bl_dest} . ": "
				  . $row_sqa->status;
				_log "Última auditor&iacute;a en "
				  . $bl->{$bl_dest} . ": "
				  . $row_sqa->qualification;
				my $config =
				  Baseliner->model('ConfigStore')->get('config.comm.email');
				my $url = $config->{baseliner_url};
				$return->{link} = $url . "/sqa/view_html/" . $row_sqa->id;
			}
			if ( $row_sqa && $row_sqa->status eq 'OK' ) {
				$return->{value} = 'Y';
			}
			last;
		}
	}

	return $return;
}

sub getProjectConfig {
	my ( $self, %p ) = @_;
	my $row   = $p{row};
	my $bl    = $p{bl};
	my $value = $p{value};
	my $return;

	my $config =
	  Baseliner->model('ConfigStore')
	  ->get( 'config.sqa', ns => 'project/' . $row->id, bl => $bl );
	if ( $config->{$value} ) {
		$return = $config->{$value};
	}

	return $return;
}

sub end_pkg_analisys_mail {
	my ( $self, %p ) = @_;

	my $project  = $p{project};
	my $job_id   = $p{job_id};
	my $packages = $p{packages};
	my $links    = $p{links};

	my $row        = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $project_id = $row->id_prj;
	my $username   = $row->username;

	my $config =
	  Baseliner->model('ConfigStore')
	  ->get( 'config.comm.email', ns => 'feature/SQA' );
	my $url = $config->{baseliner_url};

	my @regulars = Baseliner->model('Permissions')->list(
		action => 'action.sqa.pkg_analisys_mail',
		ns     => 'project/' . $project_id
	);
	
	my @ju = Baseliner->model('Permissions')->list(
		action => 'action.sqa.ju_mail',
		ns     => 'project/' . $project_id
	);

	my  @users = grep { !($_ ~~ @ju) } @regulars;
	 
	push @users, $username;

	_log "Usuarios: " . join ",", @users;
	_log "Paquetes: " . join ",", _array $packages;

	my $to = [ _unique(@users) ];

	Baseliner->model('Messaging')->notify(
		to              => { users => $to },
		subject         => _("SQA Package analysis finished"),
		sender            => $config->{from},
		carrier         => 'email',
		template        => 'email/pkg_analisys_finished.html',
		template_engine => 'mason',
		vars            => {
			subject => "An&aacute;lisis de calidad de paquetes finalizado",
			message =>
"Finalizado An&aacute;lisis de calidad de $project solicitado por el usuario $username",
			project  => $project,
			username => $username,
			packages => $packages,
			links    => $links,
			url      => $url,
			to       => $to
		}
	);
}

sub start_pkg_analisys_mail {
	my ( $self, %p ) = @_;

	my $project  = $p{project};
	my $job_id   = $p{job_id};
	my $packages = $p{packages};

	my $row        = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $project_id = $row->id_prj;
	my $username   = $row->username;

	my $config =
	  Baseliner->model('ConfigStore')
	  ->get( 'config.comm.email', ns => 'feature/SQA' );
	my $url = $config->{baseliner_url};

	my @regulars = Baseliner->model('Permissions')->list(
		action => 'action.sqa.pkg_analisys_mail',
		ns     => 'project/' . $project_id
	);
	
	my @ju = Baseliner->model('Permissions')->list(
		action => 'action.sqa.ju_mail',
		ns     => 'project/' . $project_id
	);

	my  @users = grep { !($_ ~~ @ju) } @regulars;

	push @users, $username;

	_log "Usuarios: " . join ",", @users;
	_log "Paquetes: " . join ",", _array $packages;

	my $to = [ _unique(@users) ];

	Baseliner->model('Messaging')->notify(
		to              => { users => $to },
		subject         => "An&aacute;lisis de calidad de paquetes iniciado",
		sender            => $config->{from},
		carrier         => 'email',
		template        => 'email/pkg_analisys_started.html',
		template_engine => 'mason',
		vars            => {
			subject => "An&aacute;lisis de calidad de paquetes iniciado",
			message =>
"Iniciado An&aacute;lisis de calidad de $project solicitado por el usuario $username",
			project  => $project,
			username => $username,
			packages => $packages,
			url      => $url,
			to       => $to
		}
	);
}

sub start_analisys_mail {
	my ( $self, %p ) = @_;

	my $bl         = $p{bl};
	my $project    = $p{project};
	my $subproject = $p{subproject};
	my $nature     = $p{nature};
	my $job_id     = $p{job_id};

	my $row        = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $project_id = $row->id_prj;
	my $username   = $row->username;

	my $config =
	  Baseliner->model('ConfigStore')
	  ->get( 'config.comm.email', ns => 'feature/SQA' );
	my $url = $config->{baseliner_url};

	my @regulars = Baseliner->model('Permissions')->list(
		action => 'action.sqa.analisys_mail',
		ns     => 'project/' . $project_id,
		bl	   => $bl
	);
	
	my @ju = Baseliner->model('Permissions')->list(
		action => 'action.sqa.ju_mail',
		ns     => 'project/' . $project_id,
		bl	   => $bl
	);

	my  @users = grep { !($_ ~~ @ju) } @regulars;

	my $project_row =
	  Baseliner->model('Baseliner::BaliProject')->find($project_id);

	push @users, $username;

	_log "Usuarios" . \@users;

	my $to = [ _unique(@users) ];

	Baseliner->model('Messaging')->notify(
		to              => { users => $to },
		subject         => "An&aacute;lisis de calidad iniciado",
		sender            => $config->{from},
		carrier         => 'email',
		template        => 'email/analisys_started.html',
		template_engine => 'mason',
		vars            => {
			subject => "An&aacute;lisis de calidad iniciado",
			message =>
"Iniciado An&aacute;lisis de calidad de $bl/$project/$subproject/$nature por el usuario $username",
			project    => $project,
			bl         => $bl,
			subproject => $subproject,
			nature     => $nature,
			username   => $username,
			url        => $url,
			to         => $to
		}
	);
}

sub error_analisys_mail {
	my ( $self, %p ) = @_;

	my $job_id = $p{job_id};

	my $row        = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $project_id = $row->id_prj;
	my $username   = $row->username;
	my $project    = $row->ns;
	my $bl         = $row->bl;
	my $nature     = $row->nature;

	my $config =
	  Baseliner->model('ConfigStore')
	  ->get( 'config.comm.email', ns => 'feature/SQA' );
	my $url = $config->{baseliner_url};

	my @regulars = Baseliner->model('Permissions')->list(
		action => 'action.sqa.analisys_mail',
		ns     => 'project/' . $project_id,
		bl	   => $bl
	);
	
	my @ju = Baseliner->model('Permissions')->list(
		action => 'action.sqa.ju_mail',
		ns     => 'project/' . $project_id,
		bl	   => $bl
	);

	my  @users = grep { !($_ ~~ @ju) } @regulars;

	my $project_row =
	  Baseliner->model('Baseliner::BaliProject')->find($project_id);

	my $subproject = $project_row->name;

	push @users, $username;

	_log "Usuarios" . \@users;

	my $to = [ _unique(@users) ];

	Baseliner->model('Messaging')->notify(
		to              => { users => $to },
		subject         => "Analisis de calidad finalizado con error",
		sender            => $config->{from},
		carrier         => 'email',
		template        => 'email/analisys_error.html',
		template_engine => 'mason',
		vars            => {
			subject => "An&aacute;lisis de calidad finalizado con error",
			message =>
"An&aacute;lisis de calidad de $bl/$project/$subproject/$nature por el usuario $username ha finalizado con error",
			url => $url,
			to  => $to
		}
	);
}

sub end_analisys_mail {
	my ( $self, %p ) = @_;

	my $bl            = $p{bl};
	my $project       = $p{project};
	my $subproject    = $p{subproject};
	my $nature        = $p{nature};
	my $qualification = $p{qualification};
	my $indicators    = $p{indicators};
	my $result        = $p{result};
	my $status        = $p{status};
	my $job_id        = $p{job_id};

	my $row        = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
	my $project_id = $row->id_prj;
	my $username   = $row->username;

	my $config =
	  Baseliner->model('ConfigStore')
	  ->get( 'config.comm.email', ns => 'feature/SQA' );
	my $url = $config->{baseliner_url};

	my @regulars = Baseliner->model('Permissions')->list(
		action => 'action.sqa.analisys_mail',
		ns     => 'project/' . $project_id,
		bl	   => $bl
	);
	
	my @ju = Baseliner->model('Permissions')->list(
		action => 'action.sqa.ju_mail',
		ns     => 'project/' . $project_id,
		bl	   => $bl
	);

	my  @users = grep { !($_ ~~ @ju) } @regulars;

	my $project_row =
	  Baseliner->model('Baseliner::BaliProject')->find($project_id);

	push @users, $username;

	_log "Usuarios" . \@users;

	$indicators =~ s /\n.*GLOBAL.*\n//g;
	$indicators =~ s /\n.*-/<\/li><li>/g;
	$indicators =~ s /---//g;
	$indicators =~ s /<li>$//g;
	$indicators =~ s /^.*-/<li>/g;

	my $to = [ _unique(@users) ];

	Baseliner->model('Messaging')->notify(
		to              => { users => $to },
		subject         => _loc("SQA analysis finished"),
		sender            => $config->{from},
		carrier         => 'email',
		template        => 'email/analisys_finished.html',
		template_engine => 'mason',
		vars            => {
			subject => "An&aacute;lisis de calidad finalizado",
			message =>
"An&aacute;lisis de calidad de $bl/$project/$subproject/$nature ha finalizado",
			project       => $project,
			bl            => $bl,
			subproject    => $subproject,
			nature        => $nature,
			qualification => $qualification,
			indicators    => $indicators,
			result        => $result,
			status        => $status,
			username      => $username,
			url           => $url,
			to            => $to
		}
	);

	$config = Baseliner->model('ConfigStore')->get('config.sqa.send_ju');

	
	if ( $bl =~ /$config->{bl}/ && $qualification ) {
		$self->send_ju_email(
			project_id    => $project_id,
			project       => $project,
			bl            => $bl,
			subproject    => $subproject,
			nature        => $nature,
			qualification => $qualification,
			indicators    => $indicators,
			result        => $result,
			status        => $status,
			username      => $username,
			url           => $url
		);
	}

}

sub send_ju_email {
	my ( $self, %p ) = @_;
	my $bl         = $p{bl};
	my $project_id = $p{project_id};
	my $qualification = $p{qualification};
	my $project = $p{project};
	my $subproject = $p{subproject};
	my $nature = $p{nature};
	
	my @users = Baseliner->model('Permissions')->list(
		action => 'action.sqa.ju_mail',
		ns     => 'project/' . $project_id,
		bl     => $bl,
	);

	_log "Usuarios: " . join ",", @users;

	foreach ( _unique(@users) ) {
		my $corr = \%p;
		my $ns   = 'sqa.ju_email/' . $_;
		my $data = Baseliner->model('Repository')->get( ns => $ns );
		$data ||= {};    # inicializa si está vacio
		my $hash_data = $data->{hcorreos} || {};
		push @{ $data->{correos} }, $corr;
		#$data->{substr($project,0,3).".$subproject.$nature.$bl"} = _dump $corr;
		for ( keys %p ) {
			$hash_data->{ substr($project,0,3).".$subproject.$nature.$bl"}->{$_} = $p{$_};
			_log "Añadiendo $p{$_} al hash".substr($project,0,3).".$subproject.$nature.$bl";
		}
		_log _dump $hash_data;
		$data->{hcorreos} = $hash_data;
		Baseliner->model('Repository')->set( ns => $ns, data => $data );
		_log "dando de alta para $_";
	}

}

sub recover_project {    # recupera un proyecto si se detecta que el proceso ha muerto
	my ( $self, %p ) = @_;

	my $config     = Baseliner->model('ConfigStore')->get('config.sqa');
	my $job_id     = $p{job_id};
	my $dir_pase   = $p{job_dir};
	my $username   = $p{username};
	my $project	   = $p{project};
	my $bl		   = $p{bl};
	my $nature	   = $p{nature};
	my $CAM		   = $project;
	
	my ( $rc, $ret, $xml, $html, $compileTests, $mstestResults, $junitResults );

	$self->update_status( job_id => $job_id, status => 'RECOVERING' );

	# XML
	my $bx;
	try {
		$bx = BaselinerX::Comm::Balix->new(
			host => $config->{server},
			port => $config->{port},
			key  => $config->{key}
		);
	} catch {
		$self->update_status(
			job_id => $job_id,
			status => 'BALI ERROR',
			tsend  => 1
		);
		$self->write_sqa_error( job_id => $job_id, html => _loc( "Could not connect to sqa server %1",$config->{server}) , type => "pre", reason => 'No se ha podido conectar al servidor de SQA.  Consulte con el administrador de SQA' );
		die _loc( "Could not connect to sqa server %1",
			$config->{server} )
		  . "\n";		
	};


	( $rc, $xml ) = $bx->execute(qq{type "$dir_pase"\\$config->{file}});
	if ( $rc ne 0 ) {
		$self->update_status( job_id => $job_id, status => 'KILLED', tsend => 1 );
	} else {
		( $rc, $html ) = $bx->execute(qq{type "$dir_pase"\\$config->{file_html}});
		( $rc, $mstestResults ) = $bx->execute(qq{type "$dir_pase"\\$config->{file_mstest}});
		( $rc, $junitResults ) = $bx->execute(qq{type "$dir_pase"\\$config->{file_junit}});
		
		my $job_row = Baseliner->model('Baseliner::BaliSqa')->find($job_id);
		my $project_row = Baseliner->model('Baseliner::BaliSqa')->find($job_row->{id_prj});
	
		$self->update_status( job_id => $job_id, status => 'DONE' );
		$self->grab_results(
			xml        => $xml,
			job_id     => $job_id,
			html       => $html,
			project    => $project,
			subproject => { subproject => $project_row->{name}, nature => $nature },
			nature     => $nature,
			bl         => $bl,
			mstest     => $mstestResults,
			junit      => $junitResults,
			level      => 'NAT'
		);
#		$self->calculate_aggregates(
#			CAM        => $CAM,
#			xml        => $xml,
#			job_id     => $job_id,
#			project    => $project,
#			subproject => { subproject => $project_row->{name}, nature => $nature },
#			nature     => $nature,
#			bl         => $bl,
#			bx         => $bx,
#			dir_pase   => $dir_pase
#		);		
	}
	if ( $config->{remove_dir} ) {
		_log "Removing $dir_pase";

		my $out;
		( $rc, $out ) = $bx->execute(qq{rmdir /S /Q "$dir_pase"});
		if ( $rc ne 0 ) {
			_log "Could not remove $dir_pase.  Remove manually";
		}
	}
	$bx->close();
}

sub road_kill {

	my ( $self ) = @_;
	my $config     = Baseliner->model('ConfigStore')->get('config.sqa');
	  
    $ENV{ BASELINER_DEBUG } && _log _loc("RUNNING analysis_check_for_roadkill");
    my @states = split ",", $config->{running_states};
    my $rs = Baseliner->model('Baseliner::BaliSqa')->search({ status=>\@states });
    while( my $r = $rs->next ) {
        my $pid = $r->pid;
        #next unless $pid > 0;
        $ENV{ BASELINER_DEBUG } && _log _loc("Checking if process $pid exists");
        next if pexists( $pid );
        $ENV{ BASELINER_DEBUG } && _log _loc("Process $pid does not exist");
		$self->recover_project( job_id => $r->id, job_dir => $r->path, username => $r->username, project => $r->ns, bl => $r->bl, nature => $r->nature );
    }
}

sub delete {
	my ($ self, %p ) = @_;
	
	my $id = $p{id};
	_log "VOY A BORRAR EL ID: $id";
	my $row = Baseliner->model('Baseliner::BaliSqa')->find( $id );
	$row->delete;
}

1;
