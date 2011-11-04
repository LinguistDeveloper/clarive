#INFORMACIÓN DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.PROD0000053337
#	Fecha de pase .................... 2011/11/03 20:21:11
#	Ubicación del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/sqa/lib/BaselinerX/Service/SQASendJU.pm
#	Versión del elemento ............. 10
#	Propietario de la version ........ q74612x (Q74612X - RICARDO MARTINEZ HERRERA)

package BaselinerX::Service::SQASendJU;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
has 'config' => ( is=>'rw', isa=>'Any' );

register 'service.sqa.send_ju' => {  config   => 'config.sqa.send_ju',   handler => \&run, };

sub run { # bucle de demonio aqui
    my ($self,$c, $config) = @_;
    _log "Starting service.sqa.send_ju";
    my $iterations = $config->{iterations};
    for( 1..$iterations ) {  # bucle del servicio, se pira a cada 1000, y el dispatcher lo rearranca de nuevo
        $self->run_once($c,$config);
        sleep $config->{frequency};
    }
    _log "Ending service.sqa.send_ju";
}

register 'service.sqa.send_ju_once' => {  config   => 'config.sqa.send_ju',   handler => \&send_mail, };

sub run_once {
    my ($self,$c, $config) = @_;
    $self->config( $config );
    my $pid = '';
    use Class::Date;
	
	my $nextDate = Class::Date->new($config->{next_mail});
	my $mailTime = $config->{mail_time};
	
	
	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Year += 1900;
	$Month +=1;
	
	my $now= Class::Date->new([$Year,$Month,$Day,$Hour]);
	
	_log "Next date is: $nextDate";
	_log "Now is $now";
	
	if ($nextDate < $now) {
		_log "I have to check";
		$self->send_mail;
		my $date= Class::Date->new([$Year,$Month,$Day,$mailTime]);
		$c->model('ConfigStore')->set( key=>'config.sqa.send_ju.next_mail', value=> $date+"1D" );
	}
}

sub send_mail {
    my ( $self, %p ) = @_;

    my $config = Baseliner->model( 'ConfigStore' )->get( 'config.comm.email', ns => 'feature/SQA' );
    my $url    = $config->{baseliner_url};
	
	_log "Looking for ju_mails(sqa) to send";
    for ( Baseliner->model( 'Repository' )->list( provider => 'sqa.ju_email' ) ) {
        my $data = Baseliner->model( 'Repository' )->get( ns => $_ );
        my $ns = $_;
        $_ =~ s{sqa.ju_email/}{}g;
        _log "Correo: $_";
        _log join ",", @{$data->{correos}} if $data->{correos};
        _log _dump($data->{correos});
        next if !$data->{correos};

		my $to = [$_];
		
        Baseliner->model( 'Messaging' )->notify(
            to              => { users => $to },
            subject         => _loc("Daily SQA summary"),
            sender          => "$config->{from}",
            carrier         => 'email',
            template        => 'email/analisys_ju.html',
            template_engine => 'mason',
            vars            => {
                message => "Resumen de an&aacute;lisis de calidad t&eacute;cnico",
                filas => $data->{correos},
                url => "$url"
            }
        );
        
        Baseliner->model( 'Repository' )->delete( ns => $ns );
	}
}

1;