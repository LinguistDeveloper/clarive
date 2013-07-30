package BaselinerX::Service::ServerService;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
use File::Slurp;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
register 'service.restart_server' => { name => 'Restarts Clarive server', handler => \&run, }; 

sub run {
    my ($self,$c,$config) = @_;
 
    my $port = $config->{port};

    _log _loc("Trying to restart server in port $port");

    if ( -e $ENV{CLARIVE_HOME}."/tmp/cla-web-$port.pid") {
        my $pid=read_file( $ENV{CLARIVE_HOME}."/tmp/cla-web-$port.pid" ) ;
        _log _loc "Server restart requested. Using kill HUP $pid"; 
        kill HUP => $pid;
        return 1;
    } else {
        _log _loc "Can't restart server. cla-web-$port.pid file not found";
        return 0;
    }
}


1;