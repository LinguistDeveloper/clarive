package Baseliner::Controller::ControllerLogDiego;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }
sub leer_log : Local {
     my ( $self, $c ) = @_;
     my $p = $c->request->parameters;
    _log ">>>>>>>>>>>>>>>>>>>>>><Controlador";
    my @rows = (1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000,16000,17000,18000,19000,20000);
    my @ev = ('add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','','');
    my @who = ('Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego');
    my @nodes = ('#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369');
    my @parent = ('Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Release','Email','Hostage','Changeset','Emergency','BD','Hostage','Email');
    $c->stash->{json} = { t=>\@rows, ev=>\@ev, who=>\@who, node=>\@nodes, parent=>\@parent};
    $c->forward('View::JSON');    
}

1;

