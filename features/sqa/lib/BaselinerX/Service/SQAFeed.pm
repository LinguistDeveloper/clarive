#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.PROD0000052812
#	Fecha de pase .................... 2011/10/27 07:01:46
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/sqa/lib/BaselinerX/Service/SQAFeed.pm
#	Versión del elemento ............. 21
#	Propietario de la version ........ q74612x (Q74612X - RICARDO MARTINEZ HERRERA)

package BaselinerX::Service::SQAFeed;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
has 'config' => ( is=>'rw', isa=>'Any' );

register 'service.sqa.feed' => {  config   => 'config.sqa.feed',   handler => \&run, };

sub run { # bucle de demonio aqui
    my ($self,$c, $config) = @_;
    _log "Starting service.sqa.feed";
    
    my $sm = Baseliner->model('SQA');
    
    my $iterations = $config->{iterations};
    for( 1..$iterations ) {  # bucle del servicio, se pira a cada 1000, y el dispatcher lo rearranca de nuevo
        $self->run_once($c,$config);
        $sm->road_kill();
        sleep $config->{frequency};
    }
    _log "Ending service.sqa.feed";
}

register 'service.sqa.feed_once' => {  config   => 'config.sqa.feed',   handler => \&run_once, };

sub run_once {
    my ($self,$c, $config) = @_;
    $self->config( $config );
    my $pid = '';
    my $job_home = $config->{job_home};
    
    # heavy work here
    if (-d $job_home) {
	    my @jobs = $self->new_jobs;    # find new jobs to dispatch
	    _log "Number of jobs to dispatch: ".@jobs;
	    for my $job ( @jobs ) {
	         #cada #job contiene una estructura de info de job: paquetes, status, naturalezas
	         $pid = fork;
	         if ( $pid ) {	
			next;  #FIXME this leaves zombies behind - use POSIX::_exit() instead?
		 }
		 _log 'Starting to work...';
         	 _log "Job started with PID $$";
         	$self->dispatch_job( $job );    # dispatch to sqa
         	_log 'Work finished';
         	 exit 0;
	    }
    } else {
    	_log "Directory $job_home does not exist" ;
    }
}

register 'service.sqa.dispatch_job' => {  config   => 'config.sqa.feed',   handler => \&dispatch_job, };

sub dispatch_job {   # se encarga de llamar al modelo, al lanzador de SQA
    my ($self, $job) = @_;
	
	my $config = $self->config;
    my $sm = Baseliner->model('SQA'); # para no repetir
    my $job_name = $job->{job};
    my $job_bl = $job->{bl};
    my $job_dir = $job->{path};
    my $job_type = $job->{type};
    my $username = $job->{user};
    my $job_status = $job->{status};
    
    my $job_id = '';
    my $processed_file = $config->{ processed_file };
    
    
    #my $num_projects = $self->job_projects( $job );
    
    #_log "Number of projects in job: $num_projects";
    
    _log "Dipatching job $job_name in $job_bl environment";
    if ($job_type eq "N") {
    	if ( $job_status eq 'F') { # El pase finalizó correctamente
	    	_log "Job de tipo análisis de subaplicación/naturaleza";
		    for my $project ( keys %{$job->{projects} || {}} ) {   # project es cada subapl+naturaleza
		    	my $CAM=substr($project,0,3);
		    	_log "CAM=$CAM";
		    	_log "Project=$project";
		    	for my $subproject ( @{ $job->{projects}->{$project} || [] } ) {
		         $job_id = $sm->update_status( project=>$CAM, subproject=>$subproject, bl=>$job_bl, status=>'STARTING', username=>$username, tsstart=>1 );  # so the user knows we're working on it
		         
		         #Creamos el fichero de tratado para evitar que se vuelva a tratar el pase
		         open my $done, '>', file $job_dir, $processed_file;
		    	 close $done;
		    	 
		         _log "Llamando a ship_project con ... ".qq{project=>$project, subproject=>$subproject, bl=>$job_bl, job_id=>$job_id, path=>$job_dir, job_name=>$job_name};
		         $sm->ship_project( project=>$project, subproject=>$subproject, bl=>$job_bl, job_id=>$job_id, job_dir=>$job_dir, job_name=>$job_name, username=>$username );
		}
	    }
    	} else { # El pase finalizó mal.  Se termina el job en BALI_SQA
    		open my $done, '>', file $job_dir, $processed_file;
		    close $done;
    		$job_id = $sm->update_status( status => 'BUILD ERROR', pass => $job_name, tsend => 1 );
    	}
   } else {
	_log "Job de análisis de paquetes";
	for my $project ( keys %{$job->{projects} || {}} ) {   # project es cada subapl+naturaleza
		my $CAM=substr($project,0,3);
		_log "CAM=$CAM";
		_log "Project=$project";
		my @packages = @{ $job->{projects}->{$project} };
		_log join("\n", @packages);
		$job_id = $sm->update_status( project=>$CAM, bl=>$job_bl, status=>'STARTING', type=>'package', tsstart=>1, nivel=>'CAM', username=>$username);  # so the user knows we're working on it

		#Creamos el fichero de tratado para evitar que se vuelva a tratar el pase
		open my $done, '>', file $job_dir, $processed_file;
		close $done;

		$sm->ship_packages_project( project=>$project, job_id=>$job_id, job_dir=>$job_dir, job_name=>$job_name, packages=>\@packages, username=>$username );
        }
   }
   _log "Finished job $job_name";
}

sub new_jobs {
    my ($self) = @_;
    my $config = $self->config; 
    my $job_home = $config->{job_home};
    my $job_file_name = $config->{job_file_name};
    my $processed_file = $config->{ processed_file };
    my @jobs = ();
    
    for my $job_dir( <$job_home/*> ) {
    	#_log "Processing directory $job_dir";
    	my $job_done_file = file $job_dir, $processed_file;
    	#_log "Looking for file $job_done_file";
    	next if -e $job_done_file; #si ya está tratado a por el siguiente
    	#_log "Directory $job_dir not processed";
        my $job_file = file $job_dir, $job_file_name; # un YAML vamos a dejar
        #_log "Looking for file $job_file";
        next unless -e $job_file; # si no existe, a por otro
        _log "File $job_file found";
        open my $ff, '<', $job_file or die $!;
        my $data = join'',<$ff>;   # slurp the file
        close $ff;
        # convert to a data struct:
        $data = _load( $data );
        push @jobs, $data;
    }
    return @jobs;
}

1;