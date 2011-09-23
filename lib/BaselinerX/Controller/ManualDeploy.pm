package BaselinerX::Controller::ManualDeploy;
use Baseliner::Plug;
BEGIN {  extends 'Catalyst::Controller' }
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

sub save : Local {
	my ($self,$c)=@_;
    my $p = $c->request->params;
    try {
        $p->{name} or _throw(_loc("Missing parameter %1", 'name' ));
        $p->{action} or _throw(_loc("Missing parameter %1", 'action' ));
        $p->{paths} or _throw(_loc("Missing parameter %1", 'paths' ));
        my $ns = delete $p->{ns} || delete $p->{id}; 
        _log "MD NS=$ns";
        kv->set(
            $ns ?  (ns=>$ns) : (provider=>'manual_deploy'),
            data=>$p
        );
        $c->stash->{json} = { success => \1 };
    } catch {
        $c->stash->{json} = { success => \0, msg=>shift };
    };
    $c->forward('View::JSON');
}

1;
