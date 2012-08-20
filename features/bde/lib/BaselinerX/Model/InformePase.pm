#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.TEST0000057263
#	Fecha de pase .................... 2012/01/23 17:13:55
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/bde/lib/BaselinerX/Model/InformePase.pm
#	Versión del elemento ............. 1
#	Propietario de la version ........ q74613x (Q74613X - ERIC LORENZANA CANALES)

package BaselinerX::Model::InformePase;
use Moose;
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);

#BEGIN { extends 'Catalyst::Model' }
#
#sub send_ju_email {
#	my ( $self, %p ) = @_;
#	my $bl         = $p{bl};
#	my $project_id = $p{project_id};
#
#	my @users = Baseliner->model('Permissions')->list(
#		action => 'action.informepase.ju_mail',
#		ns     => 'project/' . $project_id,
#		bl     => $bl,
#	);
#
#	my $project_row = Baseliner->model('Baseliner::BaliProject')->find($project_id);
#
#	if ($project_row) {
#
#		push @users, Baseliner->model('Permissions')->list(
#			action => 'action.informepase.ju_mail',
#			ns     => 'project/' . $project_row->parent->id,
#			bl     => $bl,
#		) if $project_row->parent;
#
#		push @users, Baseliner->model('Permissions')->list(
#			action => 'action.informepase.ju_mail',
#			ns     => 'project/' . $project_row->parent->parent->id,
#			bl     => $bl,
#		) if $project_row->parent && $project_row->parent->parent;
#
#	}
#
#	_log "Usuarios: " . join ",", @users;
#
#	foreach ( _unique(@users) ) {
#		my $corr = \%p;
#		my $ns   = 'informepase.ju_email/' . $_;
#		my $data = Baseliner->model('Repository')->get( ns => $ns );
#		$data ||= {};    # inicializa si está vacio
#		push @{ $data->{correos} }, $corr;
#		Baseliner->model('Repository')->set( ns => $ns, data => $data );
#		_log "dando de alta para $_";
#	}
#
#}

1;