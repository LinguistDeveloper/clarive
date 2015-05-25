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
    my @ev = (1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000,16000,17000,18000,19000,20000);
    my @action = ('add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add');
    my @actor = ('Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego');
    my @nodes = ('#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369');
    my @parent = ('Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Email','Changeset');
    
    my @data;
    for my $i ( 0 .. 19 ) {
        my $parent = $parent[$i];
        my $nodes = $nodes[$i];
		my $action = $action[$i];
        my $ev = $ev[$i];
        my $actor = $actor[$i];
        push @data, { parent => $parent, node=>$nodes, ev=>$action, t=>$ev, who=>$actor };
    }
     
    $c->stash->{json} = { data=>\@data };
    $c->forward('View::JSON');    
}

sub activity : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

my @ev = mdb->activity->find->sort({ ts=>-1 })->limit(20)->all;
my @mids = map { $_->{mid}} @ev;
my %cats = map { $_->{mid} => $_->{category_name} } mdb->topic->find({ mid => mdb->in(@mids)})->all;
    my @data;
    for my $ev ( @ev ) {
        next unless $ev->{mid};
        my $parent = $cats{$ev->{mid}};
        my $action = $ev->{event_key} =~ /(topic.change_status|topic.new)/ ? 'add' : 
            $ev->{event_key} =~ /(topic.remove)/ ? 'del' : 'mod';
        my $actor = $ev->{username} || 'clarive';
        push @data, { parent => $parent, node=>$ev->{mid}, ev=>$action, t=>$ev->{ts}, who=>$actor };
    }
     
    $c->stash->{json} = { data=>\@data };
    $c->forward('View::JSON');    
}

1;

