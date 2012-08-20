package BaselinerX::InformePaseMain;
use Baseliner::Plug;
use Baseliner::Utils;
use utf8;

##Acciones
register 'action.informepase.global_config' => {
	name => "Can configure the global InformePase properties"
};

register 'action.informepase.ju_mail' => {
	name => "Receive a daily mail with the jobs launched during the day"
};

##Configuración del daemon
register 'config.informepase.send_ju' => {
	metadata => [
       { id => 'frequency',  label => 'InformePase send_ju Daemon Frequency', default => 600 },
       { id => 'iterations', label => 'Iteraciones del servicio', default => '10'},
       { id => 'bl',		 label => 'Baselines en las que se enviará correo al JU', default => 'ANTE|PROD'},
       { id => 'mail_time',  label => 'Hora en la que se notificará diariamente al Jefe de Unidad de los pases diarios de sus CAMS', default => '22'},
       { id => 'next_mail',  label => 'Ultimo mail de JUs enviado', default => '2011-07-24 20:00:00'},
    ]
};

1;