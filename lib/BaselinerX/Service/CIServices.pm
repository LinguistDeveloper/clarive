package BaselinerX::Service::CIServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.ci.invoke' => {
    name => 'Invoke CI methods',
    form => '/forms/ci_invoke.js',
    icon => '/static/images/ci/class.gif',
    job_service  => 1,
    handler => \&ci_invoke,
};

sub ci_invoke {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    my $named = $config->{named} || {};
    my $positional = $config->{positional} || [];
    my $ci_class =  Util->to_ci_class( $config->{ci_class} );
    my $ci_method = $config->{ci_method};
    my $ci_mid = $config->{ci_mid};
    
    my $ci = length $ci_mid ? ci->new($ci_mid) : $ci_class;
    my @args;
    if( @$positional ) {
        push @args, map { $_->{value} } @$positional;          
    } 
    if( %$named ) {
        push @args, map { substr($_,1) => $named->{$_} } keys %$named;   # need to strip the '$' or '@' from the front
    }
    my @ret = $ci->$ci_method( @args ); 
    
    return @ret==0 ? undef : @ret==1 ? $ret[0] : \@ret;
    
    # sort map { _loc(Util->to_base_class($_)) } packages_that_do('Baseliner::Role::CI');
    # my $cl = 'BaselinerX::CI::job';
    # sort grep !/^(_|TO_JSON)/, $cl->meta->get_method_list;
    # Function::Parameters::info( $cl.'::'.'write_to_logfile' );
}

register 'service.ci.change_task' => {
    name => 'Change status task to final',
    form => '/forms/ci_invoke.js',
    icon => '/static/images/ci/class.gif',
    job_service  => 1,
    handler => \&change_task,
};


sub change_task {
    my ($self, $c, $p ) = @_;

    my $stash = $c->stash;
    my $topic_mid =  $stash->{task_current}->{attributes}->{topic_mid};
    my $id_category = $stash->{category_mid_topic_created_task};
    my $final_status_mid = Baseliner->model('Topic')->get_final_status_from_category({id_category => $id_category});
    my $id_status = mdb->topic->find_one({mid => $topic_mid })->{category_status}->{id};
    my $initial_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category});


    my $mid_status_wait = ci->status->find_one( {name => qr/dependencia/i } )->{mid};
    my $mid_status_pendiente = ci->status->find_one( {name => qr/pendiente revision/i } )->{mid};
    my $mid_status_revisada = ci->status->find_one( {name => qr/revisada/i } )->{mid};

    my $config = Baseliner->model('ConfigStore')->get('config.catalog.settings');
    my $time = $config->{time_change_status_task};



    if($id_status ne $final_status_mid && $id_status ne  $initial_status && $id_status ne $mid_status_pendiente && $id_status ne $mid_status_revisada){

        while ($id_status ne  $final_status_mid ) {
            sleep($time);
            if ($id_status ne $mid_status_wait){
                #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>SE EJECUTA, ESTADO: " . $id_status;

                
                my $topic_data = {};
                $topic_data->{topic_mid} = $topic_mid;
                $topic_data->{status_new} = $final_status_mid;
                $topic_data->{username} = $stash->{username};   
                my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );            
                $id_status = $final_status_mid;
                #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>MODIFICA: " . _dump $topic_data;
            }else{
                my $parent_task = $stash->{task_current}->{parent};
                
                my $service_selected = $stash->{service_selected};
                my $tasks = $service_selected->{tasks};
                my $bl_dependency = 0;
                foreach my $task ( _array $tasks ){
                    if ($task->{id} eq $parent_task){
                        $bl_dependency = 1;
                        $parent_task = $task;
                        last;
                    }
                } 
                
                #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>PARENT: " . $parent_task->{attributes}->{topic_mid};

                my $parent_id_status = mdb->topic->find_one({mid => $parent_task->{attributes}->{topic_mid} })->{category_status}->{id};
                if ($parent_id_status eq  $final_status_mid){
                    my $topic_data = {};
                    $topic_data->{topic_mid} = $topic_mid;
                    $topic_data->{status_new} = $final_status_mid;
                    $topic_data->{username} = $stash->{username};   
                    my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );            
                    $id_status = $final_status_mid;
                }
            }
        }
    }
    #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>Service selected: " . _dump $stash->{service_selected};
    #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>Selected Task: " . _dump $selected_task;

    return 0;
}

register 'service.ci.lineabase' => {
    name => 'Asociar a linea base',
    form => '/forms/ci_invoke.js',
    icon => '/static/images/ci/class.gif',
    job_service  => 1,
    handler => \&lineabase,
};

sub lineabase {
    my ($self, $c, $config ) = @_;
    _log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>><ASOCIAR A LINEA BASE: ";


    return 0;
}
1;
