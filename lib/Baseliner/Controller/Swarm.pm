package Baseliner::Controller::Swarm;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

register 'dashlet.swarm' => {
    form    => '/dashlets/swarm_config.js',
    name    => 'Swarm', 
    icon    => '/static/images/icons/swarm.png',
    js_file => '/dashlets/swarm_dash.js'
};

sub leer_log : Local {
     my ( $self, $c ) = @_;
     my $p = $c->request->parameters;
    _log ">>>>>>>>>>>>>>>>>>>>>><Controlador";
    my @action = ('add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del');
    my @actor = ('Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego','Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego');
    my @nodes = ('#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369','#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369');
    my @parent = ('Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Email','Changeset','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Email','Changeset');
    
    my @data;
    for my $i ( 0 .. 39 ) {
        my $parent = $parent[$i];
        my $nodes = $nodes[$i];
		my $action = $action[$i];
        my $actor = $actor[$i];
        my $t = ($i+1) * 1000;
        push @data, { parent => $parent, node=>$nodes, ev=>$action, t=>$t, who=>$actor };
    }
     
    $c->stash->{json} = { data=>\@data };
    $c->forward('View::JSON');    
}

sub activity : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    
    my $limit = $p->{limit} || 100;
    my $where = { mid=>{'$ne'=>undef} };

    if($p->{project_id}){
        my @mids_in = ();
        my @topics_project = map { $$_{from_mid} } 
            mdb->master_rel->find({ to_mid=>"$$p{project_id}", rel_type=>'topic_project' })->all;
        push @mids_in, grep { length } @topics_project;
        $where->{mid} = mdb->in(@mids_in) if @mids_in;
    }

    my $rs = mdb->activity->find($where)->sort({ ts=>-1 })->limit($limit);
    my $total = $ts->count;
    my @ev = $rs->all;
    my @mids = map { $_->{mid}} @ev;
    my %cats = map { $_->{mid} => $_->{category_name} } mdb->topic->find({ mid => mdb->in(@mids)})->all;
    my @data;
    for my $ev ( @ev ) {
        my $parent = $cats{$ev->{mid}};
        my $action = $ev->{event_key} =~ /(topic.change_status|topic.new)/ ? 'add' : 
            $ev->{event_key} =~ /(topic.remove)/ ? 'del' : 'mod';
        my $actor = $ev->{username} || 'clarive';
        $action = 'add';
        push @data, { parent=>$parent, node=>$ev->{mid}, ev=>$action, t=>$ev->{ts}, who=>$actor };
    }
    $c->stash->{json} = { data=>\@data, total=>$total };
    $c->forward('View::JSON');    
}

1;

