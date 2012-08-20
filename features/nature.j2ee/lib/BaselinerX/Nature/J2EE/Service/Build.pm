package BaselinerX::Nature::J2EE::Service::Build;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Eclipse;
use BaselinerX::Eclipse::J2EE;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Common;
use BaselinerX::Job::Elements;
use BaselinerX::Job::Element;
use BaselinerX::CA::Harvest::CLI::Version;
use YAML::Syck;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'config.nature.j2ee.build' => {
          name=> _loc('J2EE Build Configuration'),
          metadata=> [
                      { id=>'ns', label=>_loc('Namespace'),  type=>'namespaces', url=>'/j2ee/build/json' },
                      { id=>'bl', label=>_loc('Baseline'),  type=>'baselines', url=>'/j2ee/build/json' },
                      { id=>'host', label=>'Host de staging', type=>'text', nullable=>0, vtype=>'alphanum' },
                      { id=>'user', label=>'Usuario', type=>'text', nullable=>0, vtype=>'alphanum' },
                      { id=>'was_lib', label=>'WAS lib', type=>'text', nullable=>0, extjs =>{width=>'250'} },
                      { id=>'jdk', label=>'JDK', type=>'text', nullable=>1, extjs =>{width=>'250'}  },
                      { id=>'build_path', label=>'Carpeta build', type=>'text', nullable=>0, extjs =>{width=>'250'}  },
                      { id=>'variables', label=>'Variables', type=>'hash' },
                      { id=>'extensiones_ear', type=>'listbox', nullable=>1,
                      	title=>'Extensiones para EAR',
			          	width=>350, height=>200,
			          	newLabel=>_loc('Nueva extensión'),
			          	delLabel=>_loc('Borrar extensión')
                      },
                      { id=>'classpath', type=>'listbox', nullable=>1,
                      	title=>'Listado de ClassPaths',
			          	width=>350, height=>200,
			          	newLabel=>'Nuevo ClassPath',
			          	delLabel=>'Eliminar ClassPath'
                      },
          ]
};
  
use utf8;

register 'service.nature.j2ee.build' => {
          name => _loc('J2EE Build Service'),
          config => 'config.nature.j2ee.build',
          handler => 	sub {
						my ( $self, $c )=@_;
						my $job = $c->stash->{job};
						my $log = $job->logger;
						my $job_stash = $job->job_stash;
						my $elements = $job_stash->{elements};

						$elements = $elements->cut_to_subset( 'nature', 'J2EE' );

						my @packages = $elements->list('package');
						my @aplicaciones = $elements->list('application');
						my @naturalezas = $elements->list('nature');
						my @projects = $elements->list('project');
						my @subapls = $elements->list('subapplication');
						my @builds = ();
						if(@aplicaciones){
							$log->info("Inicio <b>naturaleza</b> J2EE");
							$log->debug("Paquetes", data=>YAML::Syck::Dump(@packages));
							$log->debug("Aplicaciones", data=>YAML::Syck::Dump(@aplicaciones));
							$log->debug("Proyectos", data=>YAML::Syck::Dump(@projects));
							$log->debug("Sub-Aplicaciones", data=>YAML::Syck::Dump(@subapls));

							foreach my $aplicacion ( @aplicaciones ) {
								my $sub_elements = $elements->cut_to_subset( 'application', $aplicacion );
								@packages = $sub_elements->list('package');
								@projects = $sub_elements->list('project');

								use File::Spec;
								my $path = $job_stash->{path};
								$path = File::Spec->catdir( $path, $aplicacion );
								$path = File::Spec->catdir( $path, 'J2EE' );
								$path = File::Spec->canonpath($path);
								push @builds, $self->get_builds($c,$log,$path,$job,$sub_elements,$aplicacion,@projects);
								}

							#Guardo todas las builds
							$job_stash->{builds} = \@builds;
							$log->debug("Listado de builds resultante",data=>YAML::Syck::Dump($job_stash->{builds}));
							}
						}
};

sub get_partial_projects{
	my ($self, $log ,$earprj,  $sub_elements, $Workspace, $clean_path) = @_;
	my @projects = ();
	my %white_list = {};
	my @SUBAPL_PRJ = $Workspace->getChildren( $earprj );
	$log->debug("Buscando ficheros java o jar en los proyectos: " . join(@SUBAPL_PRJ));
	foreach my $subapl ( @SUBAPL_PRJ ) {
		my $project_elements =  $sub_elements->cut_to_subset( 'project', $subapl );
		my( $elems_con, $elems_sin ) = $project_elements->split_by_extension( 'java','jar' );
		if( $elems_con->count <= 0 ){
			push @projects,$subapl;
			$white_list{$subapl} =  $self->parse_elements($clean_path,$elems_sin->elements);
			$log->debug("Para el proyecto <b>$subapl</b>:",data=>YAML::Syck::Dump($white_list{$subapl}));
		}
	}
	return (\@projects, \%white_list);
}

sub get_project_whitelist {
	my ($self, $log , $subaplicacion, $sub_elements, $clean_path) = @_;
	$log->debug("Buscando ficheros a distribuir en $subaplicacion.");
	return $self->parse_elements($clean_path,$sub_elements->elements);
}

sub parse_elements{
	my($self,$clean_path,$elements) = @_;
	my @formated_elements = ();
	for my $element (@{$elements}){
		my $formated_path = File::Spec->catfile($element->{path},$element->{name});
		$formated_path = File::Spec->canonpath($formated_path);
		#Desactivado de momento
		#$formated_path =~ s/$clean_path//g;
		push @formated_elements,$formated_path;
	}

	return \@formated_elements;
}

sub get_builds{
my ($self,$c,$log,$path,$job, $sub_elements,$aplicacion,@projects) = @_;
my $clean_path = "/$aplicacion/J2EE";
my @builds = ();

$log->debug("Parseando Worspace en $path"); 

# analisys
my $Workspace = try {BaselinerX::Eclipse::J2EE->parse( workspace=>$path ) } ;


if ( ref $Workspace ) { # return () unless ref $Workspace;
	$Workspace->cutToSubset( $Workspace->getRelatedProjects( @projects ) ) ;
	my @EARS = $Workspace->getEarProjects();
	#my @WARS = $Workspace->getWebProjects();
	#my @EJBS = $Workspace->getEjbProjects();

	# $log->debug("EARS=" . join ',', @EARS);

	foreach my $earprj ( @EARS ) {
		my $subaplicacion = $earprj;
		my ($partial_projects, $white_list ) = $self->get_partial_projects($log, $subaplicacion, $sub_elements, $Workspace, $clean_path);
		my $cfg = $c->model('ConfigStore')->get( 'config.nature.j2ee.build', ns=>"harvest.subapplication/$subaplicacion", bl=>$job->{job_data}->{bl} );

		if($cfg->{jdk}){
			$log->debug("Cambiando ubicacion del JDK...", data=>$cfg->{jdk} );
			$ENV{PATH} = $cfg->{jdk} . "/bin:" . $ENV{PATH};
			$ENV{JAVA_HOME} = $cfg->{jdk};
			$ENV{CLASS_PATH} = $cfg->{was_lib} . ":" . $ENV{CLASS_PATH} if($cfg->{was_lib});
			}

		if(scalar(@$partial_projects)<=0){
			$log->info("Se ha detectado una distribucion <b>" . BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_EAR . "</b>");

			# mis build propietarios
			my $manual = $self->build_xml_propietario( $c, path=>File::Spec->catdir( $path, $subaplicacion ), application=>$aplicacion );
			my @projects_manual = @{ $manual->{projects} || [] };
			my @builds_manual = @{ $manual->{builds} || [] };
			push @builds, @builds_manual;

			$log->debug("Chequeando build.xml para $subaplicacion...",data=>YAML::Syck::Dump(@projects_manual));
			if(not $self->existe_build_propietario($subaplicacion, @projects_manual)){

			# IMPORTANTE!!!
			# Se ha deshabilitado temporalmente la posibilidad de cargar configuraciones por subaplicacion.
			# La clase ConfigStore esta fallando en el método best_match_on_viagra, linea 100
			# la llamada Baseliner->model('Namespaces')->get( $ns ); devuelve un valor vacio
			my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.build', ns=>"harvest.subapplication/$subaplicacion", bl=>$job->bl );
			#my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.build', ns=>"/", bl=>"*" );
			$log->info("Parseando la subaplicacion <b>$subaplicacion</b> J2EE", data=>YAML::Syck::Dump($datos));

			my @classpath = split /;/, $datos->{classpath};
			my $variables = $datos->{variables}; # ie. 'org.eclipse.jdt.USER_LIBRARY' => '/opt/ca/j2ee/harsol',

			$log->debug( "Classpath para la subaplicacion $subaplicacion", data=>_dump([ @classpath ]) );
			$log->debug( "Varibles para la subaplicacion $subaplicacion", data=>_dump($variables) );

			my @SUBAPL_PRJ = $Workspace->getChildren( $earprj );
			my $buildxml = $Workspace->getBuildXML(
			mode=> 'ear',
			# static_ext => [ qw/jpg gif html htm js css/ ],
			# static_file_type => 'tar',
			variables=> $variables,
			classpath=> [ @classpath ],
			ear => [ $earprj ],
			projects => [ @SUBAPL_PRJ ],
			j2ee_build_config=>$datos,
			);

			my $buildFileName = "build_$earprj.xml";
			my $buildFilePath = File::Spec->catfile( $path, $buildFileName );

			$log->info( "Fichero <b>build.xml</b> generado", data=>_replace_tags($buildxml->data), name=>'build.xml' );
			$buildxml->save($buildFilePath);
			$log->debug("Generacion de $buildFileName.",data=>Dump $Workspace->output());


			$log->info("Generando $earprj...");

			my $ret = `cd $path; ant -buildfile $buildFileName 2>&1`;
			my $rc = $?;

			if($rc==0){
				$log->debug("Salida de ANT $buildFileName.", data=>$ret);
				my $earFileName = $earprj;
				$earFileName .=  ".ear" if(not $earprj=~ m/\.ear/);

				my $earFilePath = File::Spec->catdir( $path, $datos->{build_path});
				$earFilePath = File::Spec->catfile( $earFilePath, $earFileName );
				my $earLOB = BaselinerX::Nature::J2EE::Common->getFileLOB($earFilePath);
				if($earLOB!=-1){
					$log->info("Se ha generado el EAR $earprj.", data=>$earLOB, more=>'file', data_name=>$earprj );
				} else {
					$log->warn("Se ha generado el EAR $earprj pero no puedo acceder a el.", $earFilePath);
				}

				push @builds, {application=>$aplicacion, subapplication=>$subaplicacion, ear_path=>$earFilePath, config=>$datos, tipo=>BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_EAR};
			} else {
				$log->error("No se ha podido generar el EAR $earprj con ANT $buildFileName.", data=>$ret);
				_throw "Error durante la construccion J2EE";
				}
			} else {
				$log->debug( "No se ha generado build.xml para $subaplicacion, por que tiene el suyo propio.");
				}
		} else {
			for my $partial_project (@$partial_projects){
				$log->info("Se ha detectado una distribucion <b>" . BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_PARCIAL . "</b> en <b>$subaplicacion</b> para el <b>proyecto $partial_project</b>.", data=>YAML::Syck::Dump($white_list->{$partial_project}));
				push @builds, {application=>$aplicacion, subapplication=>$partial_project, white_list=>$white_list->{$partial_project}, tipo=>BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_PARCIAL};
				}
			}
		}
	}

#Estudiamos la casuistica de distribucion de ficheros solamente
if(scalar(@builds)<=0){
	$log->debug("No hay ninguna distribucion completa o parcial, vamos a parsear las de ficheros...");
	foreach my $subaplicacion ( @projects ) {
		my  $white_list  = $self->get_project_whitelist($log, $subaplicacion, $sub_elements, $clean_path);
		$log->info("Se ha detectado una distribucion <b>" . BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_FICHEROS . "</b> en <b>$subaplicacion</b>.", data=>YAML::Syck::Dump($white_list));
		push @builds, {application=>$aplicacion, subapplication=>$subaplicacion, white_list=>$white_list, tipo=>BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_FICHEROS};
		#push @builds, {application=>$aplicacion, subapplication=>$subaplicacion, tipo=>BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_FICHEROS};
		}
	}
#Fin de casuistica

return @builds;
}

sub build_xml_propietario {
	my($self,$c, %p)=@_;
	my $application = $p{application};
	my $path = $p{path};

	my $job = $c->stash->{job};
	my $log = $job->logger;
	my $job_stash = $job->job_stash;

	# search for build_*.xml
	$log->debug( "Chequeando path $path para build.xml propietario...");
	my @build_files = grep /^.*\/build_.*xml$/, <$path/*/*>;
	my @build_prjs=map { $1 if m{build_(.*?).xml} } @build_files;
	#$log->info( "Encontrado build.xml propietario", data=>(join"\n",@build_files) );

	# ant
	for my $buildFileName ( @build_files ) {
		my $ret = `cd $path; ant -buildfile $buildFileName 2>&1`;
		my $rc = $?;
		if($rc==0){
			$log->debug("Salida de ANT $buildFileName.", data=>$ret);
		} else {
			$log->error("No se ha podido compilar el fichero $buildFileName con ANT.", data=>$ret);
			_throw "Error durante la construccion Java/J2EE manual";
		}
	}

	# buscar ficheros generados en
	my @builds;
	push @builds, {application=>$application, subapplication=>$_ , tipo=>BaselinerX::Nature::J2EE::Service::Deploy->J2EE_TIPO_EAR}
	for @build_prjs;
	return { builds=>\@builds, projects=>\@build_prjs };
}

sub existe_build_propietario{
	my($self,$subaplicacion,@projects_manual) = @_;
	return grep /$subaplicacion/, @projects_manual;
}

1;
