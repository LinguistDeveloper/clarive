#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.PROD0000054289
#	Fecha de pase .................... 2011/11/21 20:21:23
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/sqa/lib/BaselinerX/Service/SQAPurge.pm
#	Versión del elemento ............. 0
#	Propietario de la version ........ q74612x (Q74612X - RICARDO MARTINEZ HERRERA)

package BaselinerX::Service::SQAPurge;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
has 'config' => ( is=>'rw', isa=>'Any' );

register 'service.sqa.purge' => {  config   => 'config.sqa.purge',   handler => \&run, };

sub run {
    my ($self,$c, $config) = @_;
    _log "Starting service.sqa.purge";
    
    my $days = $config->{days_to_keep} || 7;
    my $sm = Baseliner->model('SQA');
    
    my @new_jobs = $self->new_jobs( days => $days );
    
    for ( @new_jobs ) {
    	$sm->purge_job( id => $_->{id}, job_name => $_->{job}, CAM => $_->{ns} );
    }
    _log "Ending service.sqa.purge";
}

sub new_jobs {
	my ($self, %p ) = @_;
	
	my $days = $p{days};
	my $db = new Baseliner::Core::DBI( { model => 'Baseliner' } );
	my @jobs = $db->array_hash("select id, job, ns from bali_sqa where type = 'PKG' AND tsstart <= sysdate - ".$days);
	
	return @jobs;
}

1;