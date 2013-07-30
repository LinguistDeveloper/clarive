package BaselinerX::Service::ServerService;
use Baseliner::Plug;
use Baseliner::Utils;
use Path::Class;
#use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
register 'service.restart_server' => { handler => \&run, }; 

sub run { # bucle de demonio aqui
    my ($self,$c) = @_;

    if( defined $ENV{BASELINER_PARENT_PID} ) {
        # normally, this tells a start_server process to restart children
        _log _loc "Server restart requested. Using kill HUP $ENV{BASELINER_PARENT_PID}"; 
        kill HUP => $ENV{BASELINER_PARENT_PID};
    } else {
        _log _loc "Server restart requested. Using bali-web restart";
        `bali-web restart`;  # TODO this is brute force
    }
}


1;