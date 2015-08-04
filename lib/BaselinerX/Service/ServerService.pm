package BaselinerX::Service::ServerService;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Path::Class;
use File::Slurp;
use Path::Class;
use Try::Tiny;

with 'Baseliner::Role::Service';
# guardamos aqui el config que recibimos en el run
register 'service.restart_server' => { name => 'Restarts Clarive server',  icon => '/static/images/icons/daemon.gif', handler => \&run, }; 

sub run {
    my ($self,$c,$config) = @_;
 
    my $dir = $ENV{BASELINER_LOGHOME};

    my @pids = map {
        my $pid = file( $_ )->slurp;
        $pid =~ s/^([0-9]+).*$/$1/gs;
        _log "PID detected [$pid] in $_";
        $pid;
    } grep {
        $_ !~ /web.pid/;
    } glob $dir . '/cla-web*.pid';

    for my $pid ( @pids ) {
        try {
            _log _loc "Server restart requested. Using kill HUP $pid"; 
            kill HUP => $pid;
        } catch {
            _error _loc ("Error restarting $pid: "). shift;            
        };
    }
}


1;
