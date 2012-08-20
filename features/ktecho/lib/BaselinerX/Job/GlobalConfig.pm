package BaselinerX::Job::GlobalConfig;
use Baseliner::Plug;
use Baseliner::Utils;

##Configuraci�n del daemon
register 'config.load.bali.project' => {
	metadata => [
       { id=>'frequency', label=>'Daemon Frequency', default => 600 },
       { id=>'iterations', label=>'Service iterations', default => 10},
    ]
};

1;