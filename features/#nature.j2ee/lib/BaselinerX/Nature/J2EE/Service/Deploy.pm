package BaselinerX::Nature::J2EE::Service::Deploy;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Nature::J2EE::Common;
use YAML::Syck;


use constant J2EE_TIPO_EAR => "EAR";
use constant J2EE_TIPO_PARCIAL => "PARCIAL";
use constant J2EE_TIPO_FICHEROS => "FICHEROS";
use constant J2EE_TIPO_ALL => "*";

my @TipoDistribucionJ2EE =  [J2EE_TIPO_EAR,J2EE_TIPO_PARCIAL,J2EE_TIPO_FICHEROS];
my @AllTipoDistribucionJ2EE =  [J2EE_TIPO_ALL ,J2EE_TIPO_EAR,J2EE_TIPO_PARCIAL,J2EE_TIPO_FICHEROS];
	
with 'Baseliner::Role::Service';

register 'config.nature.j2ee.deploy' => {
          name=> _loc('J2EE Deploy Configuration'),
          metadata=> [
                      { id=>'ns', label=>_loc('Namespace'),  type=>'namespaces', url=>'/j2ee/deploy/json', reloadChildren=>\1 },
                      { id=>'bl', label=>_loc('Baseline'),  type=>'baselines', url=>'/j2ee/deploy/json', reloadChildren=>\1 },          
                      { id=>'was', label=>'Servidor WAS', type=>'text' },
                      { id=>'was_dir', label=>'Directorio destino(WAS)', type=>'text', extjs =>{width=>'250'} },
                      { id=>'xtype', label=>'Tipo (por defecto)', type=>'combo', store =>getTipoDistribuciones() },
                      
          ]
};

register 'service.nature.j2ee.deploy' => {
          name => _loc('J2EE Deploy Service'),
          config => 'config.nature.j2ee.deploy',   
          handler => sub {
                    my ( $self, $c )=@_;
                    my $job = $c->stash->{job};
                    my $log = $job->logger;  
                    my $job_stash = $job->job_stash;
					if(_array $job_stash->{builds}){
	                     $log->info("Inicio <b>despliegue</b> J2EE");
						 $log->debug("Consultando builds...", data=>Dump($job_stash->{builds}));
				         foreach my $build ( _array $job_stash->{builds} ) {
				         	my $subapplication = $build->{subapplication};
				         	my $application = $build->{application};
							my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.deploy', ns=>"harvest.subapplication/$subapplication", bl=>$job->{job_data}->{bl} );
							#my $datos = $c->model('ConfigStore')->get( 'config.nature.j2ee.deploy', ns=>"/", bl=>"*" );	
							$log->debug("Analizando datos de configuracion para <b>$subapplication</b> en <b>" . $job->{job_data}->{bl} . "</b>...", data=>Dump($datos));
							if(ref $datos ){
								$log->info("Desplegando <b>$subapplication</b> J2EE del proyecto $application en el entorno " . $job->{job_data}->{bl}, data=>Dump($datos));
								use File::Spec;
								my $path = $job_stash->{path}; 
								$path = File::Spec->catdir( $path, $application );
								$path = File::Spec->catdir( $path, 'J2EE' );
								$path = File::Spec->canonpath($path);	              
					
								$log->debug("Buscando configuracion de mapeos para <b>$subapplication</b>.",data=>Dump($build));
								my $filedist = BaselinerX::Nature::FILES::Filedist->new( "harvest.subapplication/$subapplication", $job->{job_data}->{bl}, $build->{tipo} );
								$filedist->load($c);
								my $mapeosCount = scalar(@{$filedist->{mappings}});
								if($mapeosCount>0){
									$filedist->distribuir($c,$path, $build->{white_list});
								}else{
									$log->error("No he encontrado configuracion de <b>MAPEOS</b> para <b>$subapplication</b>");
									#exit;																				
								}
							} else {
								$log->error("No he encontrado configuracion de despliegue para <b>$subapplication</b>");
								#exit;										
							}
				        }
					}
          }            
};

sub getTipoDistribuciones{
	return @TipoDistribucionJ2EE;
}

sub getAllTipoDistribuciones{
	return @AllTipoDistribucionJ2EE;
}

1;
