package BaselinerX::Nature::FILES::Service::Filedist;
use utf8;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Filesys;
use BaselinerX::Session::ConfigState;
use BaselinerX::Job::Elements;
use BaselinerX::Job::Element;
use YAML::Syck;
use constant TIPO_J2EE => "J2EE";
use constant TIPO_FICHEROS => "FICHEROS";
use BaselinerX::Nature::FILES::Filedist;
use BaselinerX::Nature::J2EE::Service::Deploy;

with 'Baseliner::Role::Service';

register 'config.nature.filedist' => {
          metadata=> [
                      { id=>'id', type=>'hidden' },
                      { id=>'ns', type=>'hidden' },
                      { id=>'bl', type=>'hidden' },
                      { id=>'isrecursive', type=>'checkbox', label=>"Recursivo?",text=>'El mapeo se aplicará de forma recursiva.',value=>1 },
                      { id=>'src_dir', label=>'Directorio Origen', type=>'text', nullable=>0, extjs =>{width=>250}  },
                      { id=>'dest_dir', label=>'Directorio Destino', type=>'text', nullable=>0, extjs =>{width=>250}  },
                      { id=>'ssh_host', label=>'Conexion', type=>'text', nullable=>1, extjs =>{width=>250}  },
                      { id=>'xtype', label=>'Tipo', type=>'combo', store =>BaselinerX::Nature::J2EE::Service::Deploy->getTipoDistribuciones() },
                      { id=>'sys', label=>'Sistema', type=>'combo', store =>BaselinerX::Nature::FILES::Filedist->getSistemas() },
                      { id=>'filter', type=>'listbox',
												title=>'Listado de Filtros',
												width=>410,height=>200,
												newLabel=>'Nuevo filtro',
												delLabel=>'Eliminar filtro'},
                      { id=>'exclussions', type=>'listbox',
												title=>'Listado de Exclusiones',
												width=>410,height=>200,
												newLabel=>'Nueva exclusión',
												delLabel=>'Eliminar exclusión'}
          ]
};

register 'config.nature.filedist_comp' => {
          metadata=> [
                      { id=>'ns', label=>_loc('Namespace'),  type=>'namespaces', url=>'/filedist/json_bl_ns', reloadChildren=>\1 },
                      { id=>'bl', label=>_loc('Baseline'),  type=>'baselines', url=>'/filedist/json_bl_ns', reloadChildren=>\1 },          
                      
          ]
};

register 'service.nature.filedist' => {
		name => _loc('FILES Service'),
		config => 'config.nature.filedist',   
		handler => sub {
			my ( $self, $c )=@_;
			my $job = $c->stash->{job};
			my $log = $job->logger;  
			my $job_stash = $job->job_stash;
			
			my $elements = $job_stash->{elements};					
			$elements = $elements->cut_to_subset( 'nature', 'FILES' );					
			my @applications = $elements->list('application');
			$log->debug("Inicio <b>distribucion de ficheros</b>");
			$log->debug("Aplicaciones", data=>YAML::Syck::Dump(@applications));
			foreach my $application ( @applications ) {
					my $ns = "application/" . $application;
					use File::Spec;
					my $path = $job_stash->{path}; 
					$path = File::Spec->catdir( $path, $application );
					$path = File::Spec->catdir( $path, 'FILES' );
					$path = File::Spec->canonpath($path);	              
				
					my $filedist = BaselinerX::Nature::FILES::Filedist->new( $ns, $job->bl, TIPO_FICHEROS );
					$filedist->load($c);
					$log->debug("Configuración de Ficheros <b>$ns</b>:", data=>YAML::Syck::Dump($filedist));
					$filedist->distribuir($c,$path);
			}
		}            
};

1;
