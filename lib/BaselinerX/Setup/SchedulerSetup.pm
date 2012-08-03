package BaselinerX::Setup::SchedulerSetup;
use Baseliner::Plug;
use Baseliner::Utils;

##Configuración del daemon
register 'config.scheduler' => {
    metadata => [
       { id=>'frequency', label=>'SQA send_ju Daemon Frequency', default => 60 },
       { id=>'iterations', label=>'Iteraciones del servicio', default => 1000 }
    ]
};