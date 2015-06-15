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
    my @action = ('add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','add','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','mod','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del','del');
    my @actor = ('Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego','Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego','Diego','Carlos','Pedro','Ana','Diego','Marta','Carlos','Ana','Pedro','Diego','Marta','Carlos','Pedro','Ana','Marta','Diego','Pedro','Carlos','Marta','Diego');
    my @nodes = ('#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369','#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369','#44350','#44351','#44352','#44353','#44354','#44355','#44356','#44357','#44358','#44359','#44360','#44361','#44362','#44363','#44364','#44365','#44366','#44367','#44368','#44369');
    my @parent = ('Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Email','Changeset','Emergency','Emergency','BD','Hostage','Email','Release','Emergency','Emergency','BD','Hostage','Email','Release','Emergency','Emergency','BD','Hostage','Email','Release','Email','Changeset','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Changeset','Emergency','BD','Hostage','Email','Release','Email','Changeset');
    
    my @data;
    for my $i ( 0 .. 59 ) {
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

    my $limit = $p->{limit} || 10000;
    my $where = { mid=>{'$ne'=>undef} };
	
    my $days = $p->{days} || 2592000000;
	$days = $days/86400000;

    my $date = Class::Date->now();
    my $filter_date = $date - ($days . 'D');

    my @ev = mdb->activity->find({ mid=>{'$ne'=>undef} })->sort({ ts=>1 })->limit($limit)->all;
    my @mids = map { $_->{mid}} @ev;
    my %cats = map { $_->{mid} => $_->{category_name} } mdb->topic->find({ mid => mdb->in(@mids)})->all;
    my %category_colors = map { $_->{name} => $_->{color} } mdb->category->find->fields({name=>1,color=>1})->all;

    my @data;
    for my $ev ( @ev ) {
        my $parent = $cats{$ev->{mid}};
        my $action = $ev->{event_key} =~ /(topic.change_status|topic.new)/ ? 'add' : 
            $ev->{event_key} =~ /(topic.remove)/ ? 'del' : 'mod';
        my $actor = $ev->{username} || 'clarive';
        $action = 'add';
        if ($parent){
			push @data, { parent=>$parent, node=>$ev->{mid}, ev=>$action, t=>$ev->{ts}, who=>$actor, color=> $category_colors{$parent} };
		}
    }
    # _log( \@data );
    $c->stash->{json} = { data=>\@data };
    $c->forward('View::JSON');    
}

sub grouped_activity : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    #_warn $p;
	_log "comienzoooo";
    
    my $limit = $p->{limit} || 10000;
	_log "limit => " . $limit;
    my $days = $p->{days} || 2592000000;
	
	$days = $days/86400000;

    my $where = { mid=>{'$ne'=>undef} };

    my $date = Class::Date->now();
    my $filter_date = $date - ($days . 'D');
	_log "dates... " . $days;
	_log "fecha filtrado" . $filter_date;
    my @dates = _array(
        mdb->activity->aggregate(
            [
                {'$match' => { mid=>{'$ne'=>undef}, event_key => qr/topic/, ts => { '$gte' => ''.$filter_date} }},
                
                {
                    '$group' => {
                        _id    => { '$substr' => [ '$ts',0,16] },
                        'activity' => {
                            '$push' => { ts => '$ts', event_key => '$event_key', mid => '$mid'}
                        }
                    }
                },
                {'$sort' => {_id => 1}},
				# {'$skip' => 10},
				# {'$limit' => 50}
            ]
        )
    );

    my %result_dates;
    for my $date ( @dates ) {
        my @mids = map { $_->{mid}} _array($date->{activity});
        my %cats = map { $_->{mid} => $_->{category_name} } mdb->topic->find({ mid => mdb->in(@mids)})->all;
        my @data;
        for my $ev ( _array($date->{activity} )) {
            my $parent = $cats{$ev->{mid}};
            my $action = $ev->{event_key} =~ /(topic.change_status|topic.new)/ ? 'add' : 
                $ev->{event_key} =~ /(topic.remove)/ ? 'del' : 'mod';
            my $actor = $ev->{username} || 'clarive';
            $action = 'add';
            push @data, { parent=>$parent, node=>$ev->{mid}, ev=>$action, t=>$ev->{ts}, who=>$actor } if ($parent);
        }
		_log "subo => $date->{_id} - total: " . scalar @data;
        $result_dates{$date->{_id}} = \@data;
    }
	#_log( \%result_dates); 
    $c->stash->{json} = { data=>\%result_dates };
    $c->forward('View::JSON');    
}

1;

