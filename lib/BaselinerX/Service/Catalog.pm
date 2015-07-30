package BaselinerX::Service::Catalog;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Path::Class;
use Try::Tiny;
use v5.10;
use experimental 'autoderef', 'switch';

no warnings q{uninitialized};

with 'Baseliner::Role::Service';

register 'config.catalog.settings' => {
    metadata => [
           { id =>'service', label =>'Name of category created', default => _utf8 'Petición' },
           { id =>'task', label =>'Name of category created', default => 'Tarea' },
           { id =>'service_task_relation', label =>'Name of field for service-task relation', default => 'tareas' },
           { id =>'project_filter', label =>'Limit Catalog to these project names', default => '' },
           { id =>'status_draft', label =>'Draft status for wizard', default => 'Borrador' },
        ]
};

####################### STATEMENTS

register 'statement.catalog.if.var' => {
    text => 'Catalogue - IF var THEN',
    type => 'if',
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/if.gif',
    form => '/forms/variable_value.js',
    data => { variable=>'', value=>'' },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            my @name = grep /%s/, keys $stash->{wizard_data};
            my $id_field = $name[0];
            # $stash->{catalog_filter} = 0;
            if( $stash->{wizard_data}{$id_field} eq '%s' ) {
                %s
                # $stash->{catalog_filter} = 1;
            }
            
        }, $n->{variable}, $n->{value} , $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.catalog.folder' => {
    text => 'Folder',
    data => { },
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/catalog-folder.png',
    holds_children => 1,
    form => '/forms/catalog_folder.js',
    filter => 1,
    dsl => sub { 
        my ($self, $n , %p) = @_;

        my @children_mids;
        my @children_service = grep { $_->{key} eq 'statement.catalog.service' } _array $n->{children};

        my $project;
        if (scalar @children_service > 0){
            foreach my $service (@children_service){
                push @children_mids, @{$service->{data}->{service}};   
            }
        }

        my @children_task = grep { $_->{key} eq 'statement.catalog.task'  } _array $n->{children};
        if (scalar @children_task > 0){
            foreach my $task (@children_task){
                push @children_mids, @{$task->{data}->{task}};   
            }            
        }

        my @children_task_group = grep { $_->{key} eq 'statement.catalog.task_group'  } _array $n->{children};
        if (scalar @children_task_group > 0){
            foreach my $task_group (@children_task_group){
                foreach my $task ( _array $task_group->{children}){
                    push @children_mids, @{$task->{data}->{task}};   
                }                 
            }            
        }        

        my $children_mids = \@children_mids;

        sprintf(q{
            my $realm = '%s';
            my $children_mids = %s;
            my $name = q{%s};
            my $description = q{%s};
            my $collapse = q{%s};
            my $system = q{%s};

            _log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>FOLDER: " . $name;

            if( $stash->{realm} eq $realm || $realm eq 'both' && $stash->{realm} ne 'global' || $stash->{catalog_step} ne 'MENU') {
                my $has_children = 1;
                if ( scalar @{$children_mids} ){
                    my $type;
                    $type = $stash->{realm} eq 'project' ? 'P' : $stash->{realm} eq 'subproject' ? 'S' : undef;
                    my $query = { mid => { '$in' => $children_mids }, active => '1'};
                    if ($stash->{catalog_step} eq 'MENU'){
                        $query->{'$or'} = [ {type => $type}, {type=> { '$exists' => 0 }, project => $stash->{service_mid_project_click}}] if ($type);    
                    }

                    my @rows = mdb->master_doc->find( $query )->all;

                    my @show_rows;
                    foreach my $row (@rows){
                        my $mid = $row->{mid};
                        my $ci = ci->new($mid);
                        if (scalar grep {$_->name =~ /Baseliner::Role::CI::CatalogService/} _array($ci->meta->roles)){
                            my $hide_service = $ci->hide_service($stash->{bl});
                            next if ($hide_service); 
                            push @show_rows, $mid;
                            last;                           
                        }else{
                            push @show_rows, $mid;
                            last;
                        }
                    }

                    if( scalar @show_rows > 0){
                        $has_children = 1;
                    }
                }

                _log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>CHILDREN: " . _dump $children_mids;

                if (!$stash->{name_folder} || $stash->{name_folder} eq $name ){
                    if ($has_children eq '1' ){
                        my $id = mdb->oid->{value};
                        my $folder = { 
                            id          => $id,
                            parent      => $stash->{catalog_parent}, 
                            name        => $name, 
                            mid         => 'folder:' . $name . ':' . ($stash->{service_mid_project_click} // '') . ':' . $system,
                            type        => 'folder', 
                            description => $description,  
                            collapse    => $collapse,
                            system      => $system,
                            id_task      => $stash->{id_task},
                            _is_leaf    => \0,
                        };     

                        if( $stash->{catalog_step} eq 'MENU' ) {
                            push @{ $stash->{services} } => $folder;
                        }
                        local $stash->{catalog_parent} = $stash->{id_folder} // $id;
                        local $stash->{folder_current} = $folder;

                        if ($stash->{name_folder} && $stash->{name_folder} eq $name || $stash->{catalog_step} ne 'MENU'){
                            %s;
                        }                    
                    }
                }

            }
        }, ( $n->{realm} // 'global'), Data::Dumper::Dumper($children_mids), $n->{text}, $n->{note}, $n->{collapse}, $n->{name}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.catalog.service' => {
    text => 'Service',
    data => { },
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/catalog-light.png',
    holds_children => 1,
    form => '/forms/catalog_service.js',
    filter => 1,
    dsl => sub { 
        my ($self, $n , %p) = @_;
        
        sprintf(q{
            {
                local $stash->{catalog_filter} = 0;
                my $name = q{%s};
                _log ">>>>>>>>>>>>>>>>>>>>>>><SERVICE: " . $name;
                launch( 'service.catalog.service', 'Catalog Service', $stash, 
                   { key => $name, mid => q{%s}, description => q{%s}, attributes => %s, chi => sub{ %s } }, '' );
                
            }
        }, $n->{text}, $n->{data}{service}[0], $n->{note}, Data::Dumper::Dumper($n->{data}), $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.catalog.task_group' => {
    text => 'Task Group',
    data => { },
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/task_group.png',
    holds_children => 1,
    filter => 0,
    dsl => sub { 
        my ($self, $n , %p) = @_;

        my @mids_task;
        foreach my $task (_array $n->{children}){
            if($task->{data}->{task}){
                push @mids_task, @{$task->{data}->{task}};                
            }
               
        }            

        sprintf(q{
            {
                my $name = q{%s};
                my $mids_task = %s;
                my @mids_task = map {$_.''} _array $mids_task;

                my $type;
                $type = $stash->{realm} eq 'project' ? 'P' : $stash->{realm} eq 'subproject' ? 'S' : undef;                
                my $query = { mid => { '$in' => \@mids_task }, active => '1'};
                if ($stash->{catalog_step} eq 'MENU'){
                    $query->{'$or'} = [ {type => $type}, {type=> { '$exists' => 0 }, project => $stash->{service_mid_project_click}}] if ($type);    
                }

                my @rows = mdb->master_doc->find( $query )->all;
                my $is_leaf = scalar @rows ? 0 : 1;

                launch( 'service.catalog.task_group', 'Catalog Task Group', $stash, { key => $name, description => q{%s}, chi => sub{ %s }, is_leaf => $is_leaf }, '' );                    
            }
        }, $n->{text}, Data::Dumper::Dumper(\@mids_task), $n->{note}, $self->dsl_build( $n->{children}, %p ) );        
    },
};


register 'statement.catalog.task' => {
    text => 'Task',
    data => { },
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/catalog-target.png',
    holds_children => 1,
    form => '/forms/catalog_task.js',
    filter => 1,
    dsl => sub { 
        my ($self, $n , %p) = @_;
        my $tasks = grep { $_->{key} eq 'statement.catalog.task' } _array $n->{children};

        sprintf(q{
            {
                local $stash->{catalog_filter} = 0;
                my $name = q{%s};
                launch( 'service.catalog.task', 'Catalog Task', $stash, 
                   { key => $name, mid => q{%s}, description => q{%s}, attributes => %s, is_leaf => q{%s} , chi => sub{ %s } }, '' );
                
            }
        }, $n->{text}, $n->{data}{task}[0], $n->{note}, Data::Dumper::Dumper($n->{data}), $tasks, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.catalog.step' => {
    text => 'CATALOG STEP',
    description=> 'a task step section: MENU,WIZZARD,RUN...',
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/job.png',
    dsl=>sub{
        my ($self, $n, %p ) = @_;
        sprintf(q{
            if( $stash->{catalog_step} eq q{%s} ) {
                %s
            }
        }, $n->{text}, $self->dsl_build( $n->{children}, %p ) );
    }
};

# register 'statement.catalog.run_task_services' => {
#     text => 'RUN TASK SERVICES',
#     description=> 'RUN TASK SERVICES...',
#     icon => '/static/images/icons/job.png',
#     dsl=>sub{
#         my ($self, $n, %p ) = @_;
#         sprintf(q{
#             my $service_selected = $stash->{service_selected};

#             my $sel_task_current = BaselinerX::Service::Catalog::set_sel_task_current( $service_selected->{tasks} ); 
#             if( $stash->{catalog_step} eq 'RUN' ) {
#                 if ( !$sel_task_current->{attributes}->{sw_dependency} ) {
#                     if ( !$sel_task_current->{attributes}->{sw_services_task_done} ) {
#                         try{
#                             %s
#                             $sel_task_current->{attributes}->{sw_services_task_done} = 1;
#                         } catch {
#                             $sel_task_current->{attributes}->{sw_services_task_done} = 0;
#                         }
#                     }                    
#                 }
#             }
#         }, $self->dsl_build( $n->{children}, %p ) );
#     }
# };

####################### SERVICES

register 'service.catalog.service' => {
    handler=>sub{
        my ( $self, $c, $config ) = @_;

        my $stash = $c->stash;
        my $key = $config->{key};
        my $mid = $config->{mid};
        my $description = $config->{description};
        my $chi = $config->{chi};
        my $id = mdb->oid->{value};
        my $attributes = $config->{attributes};
        my $id_task = $stash->{id_task};

        my $service = { 
            id          => $id,
            id_rule     => $stash->{id_rule},
            mid         => $mid,
            name        => $key, 
            description => $description,  
            attributes  => $attributes,
            type        => 'service', 
            id_task     => $id_task,
            parent      => $stash->{catalog_parent}, 
            icon        => '/static/images/icons/catalogue.png',
            #icon        => '/static/images/icons/catalog-light.png',
            _is_leaf    => $attributes->{split_task} ? \0 : \1,     
        };

        local $stash->{catalog_parent} = $id;
        local $stash->{service_current} = $service;   

        if ($stash->{catalog_step} eq 'MENU') {
            push @{ $stash->{services} } => $service;
            $chi->();
        } 

        my $service_selected = $stash->{service_selected};

        if ($service_selected && $service_selected->{mid} eq $stash->{service_current}->{mid}){

            my $relation_field = $stash->{field_service_task_relation};
            my $id_category = $stash->{category_mid_topic_created_service};        

            given ($stash->{catalog_step}) {
                when ('DRAFT') {
                    $self->create_or_update_service( $relation_field, $service_selected, $id_category, $stash );
                }
                when ('RUN') {
                    if ( !$service_selected->{run_service_step} ){
                        $self->create_or_update_service( $relation_field, $service_selected, $id_category, $stash ); 
                    }
                    if ( $service_selected->{run_service_step} ne 'DONE') { 
                        my $id_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category});
                        $self->set_service_status($service_selected, $id_category, $id_status, $stash );
                        $service_selected->{status_service} = mdb->topic->find_one({ mid => $service_selected->{mid_topic_created_service} })->{category_status}{id};
                    }
                }
            } 

            $chi->();

            given ($stash->{catalog_step}) {
                when ('DRAFT') { 
                    my $topic_data = $self->set_service_data( $relation_field, $service_selected, $id_category, $stash );  
                    $topic_data->{topic_mid} = $service_selected->{mid_topic_created_service};
                    my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );
                }
                when ('RUN') { 
                    $self->set_service_selected($stash);
                    $self->set_task_selected($stash);
                }                            
            }                        
        }
    },
    icon        => '/static/images/icons/catalogue.png'  #new icons for clarive 6.3
};


register 'service.catalog.task' => {
    parse_vars=>0,
    icon        => '/static/images/icons/catalogue.png' , #new icons for clarive 6.3
    handler=>sub{
        my ( $self, $c, $config ) = @_;

        my $key = $config->{key};
        my $mid = $config->{mid};
        my $description = $config->{description};
        my $attributes = $config->{attributes};
        my $chi = $config->{chi};
        my $id = mdb->oid->{value};
        my $is_leaf = $config->{is_leaf} eq '0' ? \1: \0;
        my $stash = $c->stash;
        my $service_selected = $stash->{service_selected};
        my $id_task = $stash->{id_task};

        local $stash->{task_parent_name};
        local $stash->{project_parent};

        if (exists $stash->{task_current} ) {
            $stash->{task_parent_name} = $stash->{task_current}->{name};
        } 
        #if( ( $stash->{catalog_step} eq 'MENU') || $service_selected->{mid} eq $stash->{service_current}->{mid} || !$stash->{service_current}->{mid} ){
            my $task = { 
                id          => $id,
                id_rule     => $stash->{id_rule},
                id_service  => $stash->{service_current}->{mid} || $stash->{task_group_current}->{type} || undef,
                mid         => $mid,
                attributes  => $attributes,
                name        => $key, 
                description => $description,
                type        => 'task', 
                id_task      => $id_task,
                parent      => $stash->{catalog_parent},
                icon        => '/static/images/icons/catalogue.png',
                #icon        => '/static/images/icons/catalog-target.png',
                _is_leaf    =>  $is_leaf,
            };

            local $stash->{catalog_parent} = $id;
            local $stash->{task_current} = $task; 
            
            if ($stash->{catalog_step} eq 'MENU') {
                if ($stash->{service_current}->{attributes}->{split_task} eq '1' || $stash->{task_group_current} || $stash->{folder_current}->{system} eq '_catalog_folder') {
                    push @{ $stash->{services} } => $task;                    
                }
                $chi->();
            } 

            delete $stash->{task_selected};

            if ($stash->{catalog_step} eq 'WIZARD') {
                push @{$stash->{'init_tasks'}} => $key;
            }

            foreach my $task_sel (_array $service_selected->{tasks}){
                if ( $task_sel->{mid} eq $mid) {
                        push @{$stash->{task_selected}} =>  $task_sel;
                }
                my $key_task_mid_project = $task_sel->{mid} . '_' . $task_sel->{project}->{mid};
                if (!exists $stash->{tasks_status}->{$key_task_mid_project}){
                    $stash->{tasks_status}->{$key_task_mid_project} = 0;            
                }
                if ($stash->{task_parent_name} eq $task_sel->{name}) {
                    $stash->{project_parent} = $task_sel->{project};
                }
            }

            # if ($service_selected->{name} && $stash->{service_current}->{attributes}->{split_task} eq '0'){
            #     push @{$service_selected->{tasks}} => $task;
            #     $stash->{task_selected} = $task;
            # }    

            if ($stash->{catalog_step} eq 'NEXT' || $stash->{catalog_step} eq 'PREV') {
                my $is_new;
                foreach my $task ( _array $stash->{init_tasks} ){
                    if ( $task eq $key) {
                        $is_new = 0;
                        last;
                    }else{
                        $is_new = 1;
                    }
                }

                if ($is_new) {
                    $stash->{task_current}->{project} = $stash->{project_parent};
                    push @{$service_selected->{tasks}}  =>  $stash->{task_current};
                    push @{$stash->{task_selected}}     =>  $stash->{task_current};
                    push @{$stash->{init_tasks}}        =>  $key;
                }
            }

            foreach my $task_selected ( _array $stash->{task_selected} ){
                local $stash->{task_selected} = $task_selected;

                if ($task_selected && $stash->{task_current}->{id_service} eq $task_selected->{id_service}){
                    my $id_category = $stash->{category_mid_topic_created_task};

                    given ($stash->{catalog_step}) {
                       
                        when ('DRAFT') {
                            $self->create_or_update_task( $service_selected, $task_selected, $id_category, $stash  );
                            if (!$stash->{task_group_current}->{name} && $task_selected->{id_service} eq '' ){
                                $self->set_service_selected($stash);
                                $self->set_task_selected($stash);                                 
                            }                        
                        }
                        when ('RUN') {
                            if ( !$task_selected->{run_task_step} ){
                                $self->create_or_update_task( $service_selected, $task_selected, $id_category, $stash );
                                if (!$stash->{task_group_current}->{name} && $task_selected->{id_service} eq '' ){
                                    $self->set_service_selected($stash);
                                    $self->set_task_selected($stash);                                 
                                }
                            }

                            my $id_status = mdb->topic->find_one({ mid => $task_selected->{attributes}->{topic_mid} })->{category_status}{id};
                            my ($bl_dependency, $parent_task) = $self->has_dependency( $service_selected, $stash );

                            if(!$task_selected->{attributes}->{init_run_status}) {
                                if($bl_dependency && $parent_task->{attributes} && $parent_task->{attributes}->{init_run_status}){
                                    $task_selected->{attributes}->{init_run_status} = $parent_task->{attributes}->{init_run_status};
                                }else{
                                    $task_selected->{attributes}->{init_run_status} = '';
                                }
                            }
                            my $params = {
                                username        => $stash->{username},
                                topic_mid       => $task_selected->{attributes}->{topic_mid},
                                id_category     => $id_category,
                                id_status_from  => $id_status,
                                surrogate       => 'clarive'
                            };                            
                            if ( $task_selected->{run_task_step} ne 'DONE' && 
                                $service_selected->{status_service} eq $task_selected->{attributes}->{init_run_status} || 
                                ($task_selected->{attributes}->{init_run_status} eq '' && $task_selected->{run_task_step} ne 'DONE')) {
                                    my $id_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category}); ##resolverlo a nivel global
                                    $self->set_task_status($task_selected, $id_category, $id_status, $stash );
                                    my $id_category_service = $stash->{category_mid_topic_created_service};
                                    $id_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category_service});
                                    my $id_status_before = mdb->topic->find_one({ mid => $service_selected->{mid_topic_created_service} })->{category_status}{id};
                                    if ($id_status ne $id_status_before){
                                        $self->set_service_status($service_selected, $id_category_service, $id_status, $stash );
                                    }
                                    $task_selected->{run_task_step} = 'DONE'; 
                            }

                            if ( $task_selected->{run_task_step} eq 'DONE' ){
                                if ( !$task_selected->{attributes}->{sw_task_done} ){
                                    if ( $bl_dependency ) {
                                        if ( !$parent_task->{attributes}->{sw_task_done}){
                                                my $id_status_dependency = Baseliner->model('Topic')->get_dependency_status_from_category({id_category => $id_category}); ##resolverlo a nivel global
                                                $self->set_task_status( $task_selected, $id_category, $id_status_dependency, $stash );
                                                $task_selected->{attributes}->{sw_dependency} = 1;
                                        }else{
                                            my $id_status_dependency = Baseliner->model('Topic')->get_dependency_status_from_category({id_category => $id_category});

                                            ##Contemplar caso automático
                                            if ( $id_status eq $id_status_dependency) { 
                                                my @status = Baseliner->model('Topic')->next_status_for_user(%$params);

                                                if ( @status ){
                                                    $self->set_task_status( $task_selected, $id_category, $status[0]->{id_status_to}, $stash );
                                                }
                                            }
                                        }
                                    }
                                    else{
                                        if ($task_selected->{attributes}->{prerequisite} || $task_selected->{attributes}->{ancestor}) {
                                            my $has_dependency = 0;
                                            my $key_task_mid_project;
                                            foreach my $prerequisite ( _array $task_selected->{attributes}->{prerequisite} ){
                                                $key_task_mid_project = $prerequisite . '_' . $task_selected->{project}->{mid};
                                                if ( exists $stash->{tasks_status}->{$key_task_mid_project} && $stash->{tasks_status}->{$key_task_mid_project} eq '0'){
                                                    $has_dependency = 1;
                                                    last;
                                                }
                                            }

                                            #if ($has_dependency){
                                                foreach my $ancestor ( _array $task_selected->{attributes}->{ancestor} ){
                                                    $key_task_mid_project = $ancestor . '_' . $task_selected->{project}->{mid};
                                                    if ( exists $stash->{tasks_status}->{$key_task_mid_project} && $stash->{tasks_status}->{$key_task_mid_project} eq '0'){
                                                        $has_dependency = 1;
                                                        last;
                                                    }
                                                }
                                            #}

                                            if ($has_dependency){
                                                my $id_status_dependency = Baseliner->model('Topic')->get_dependency_status_from_category({id_category => $id_category});
                                                if ( $task_selected->{attributes}->{status_mid} ne $id_status_dependency ) {
                                                    $self->set_task_status( $task_selected, $id_category, $id_status_dependency, $stash );                                                
                                                }                                               
                                            }
                                            else{
                                                if( $task_selected->{attributes}->{automatic} ){
                                                    my $id_status_final = Baseliner->model('Topic')->get_final_status_from_category({id_category => $id_category});
                                                    $self->set_task_status( $task_selected, $id_category, $id_status_final, $stash );
                                                    $task_selected->{attributes}->{sw_task_done} = 1;
                                                    $stash->{tasks_status}->{$task_selected->{mid} . '_' . $task_selected->{project}->{mid}} = 1;
                                                }else{
                                                    my $id_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category});
                                                    $self->set_task_status($task_selected, $id_category, $id_status, $stash );                                                    
                                                }                                                  
                                            }
                                        }else{ # No dependencies
                                            if( $task_selected->{attributes}->{automatic} ){
                                                my $id_status_final = Baseliner->model('Topic')->get_final_status_from_category({id_category => $id_category});
                                                $self->set_task_status( $task_selected, $id_category, $id_status_final, $stash );
                                                $task_selected->{attributes}->{sw_task_done} = 1;
                                                $stash->{tasks_status}->{$task_selected->{mid} . '_' . $task_selected->{project}->{mid}} = 1;
                                            }                                            
                                        }
                                    }                                
                                }
                            }
                        }                    
                    }

                    $chi->();

                    if ($stash->{catalog_step} eq 'RUN'){
                        if ( $task_selected->{attributes}->{sw_services_task_done} && $task_selected->{attributes}->{sw_services_task_done} == 0 ){
                            $task_selected->{attributes}->{sw_task_done} = 0; 
                        }
                        $stash->{from_catalog_event_topic} = 0;
                        mdb->topic->update({ mid => $task_selected->{attributes}->{topic_mid}},{ '$set' => { '_catalog_stash' => _dump $stash }});

                        if($service_selected->{type} eq '_service'){
                            $self->set_service_selected($stash);
                            $self->set_task_selected($stash);                            
                        }
                    }  
                }
            }
            #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>END TASK: " . $key;

        #}
    }
};

register 'service.catalog.task_group' => {
    parse_vars => 0,
    icon        => '/static/images/icons/catalogue.png',  #new icons for clarive 6.3
    handler=>sub{
        my ( $self, $c, $config ) = @_;


        my $id = mdb->oid->{value};
        my $key = $config->{key};
        my $description = $config->{description};
        my $is_leaf = $config->{is_leaf};
        my $attributes;
        $attributes->{split_task} = 1;
        my $chi = $config->{chi};
        my $stash = $c->stash;
        my $id_task = $stash->{id_task};

        if (!$is_leaf){
            my $task_group = { 
                id          => $id,
                id_rule     => $stash->{id_rule},
                mid         => '',
                name        => $key, 
                description => $description,  
                attributes  => $attributes,
                type        => 'task_group', 
                id_task     => $id_task,
                parent      => $stash->{catalog_parent}, 
                icon        => '/static/images/icons/catalogue.png',
                #icon        => '/static/images/icons/task_group.png',
                _is_leaf    => $is_leaf,     
            };


            local $stash->{catalog_parent} = $id;
            local $stash->{task_group_current} = $task_group;   

            if ($stash->{catalog_step} eq 'MENU') {
                push @{ $stash->{services} } => $task_group;
            }

            $chi->(); 

            my $service_selected = $stash->{service_selected};

            if (exists $service_selected->{mid_topic_created_service} && $service_selected->{mid_topic_created_service} ne ''){
                if ($stash->{catalog_step} eq 'DRAFT' || $stash->{catalog_step} eq 'RUN'){
                    $self->set_service_selected($stash);
                    $self->set_task_selected($stash);                 
                }
            }            
        }

    },
};

register 'service.catalog.form' => {
    name => 'Form',
    icon => '/static/images/icons/catalogue.png',
    #icon => '/static/images/icons/catalog-form.png',
    form => '/forms/catalog_form.js', 
    parse_vars => 0,
    handler => sub{
        my ( $self, $c, $config ) = @_;
        my $stash = $c->stash;
        my $key;
        my $form;

        if ($stash->{catalog_step} eq 'WIZARD' || $stash->{catalog_step} eq 'NEXT' || $stash->{catalog_step} eq 'PREV'){
            my @fieldlets = _array $config->{fields};

            my $service_selected = $stash->{service_selected};

            if ($config->{type_form} eq 'global'){

                $key = "form_global";

                $form = { 
                    id_rule     => $stash->{id_rule},
                    name        => $key, 
                    fieldlets   => \@fieldlets,
                    type        => 'form',
                    subtype     => $config->{type_form},
                    project     => {
                        mid     => $service_selected->{project}->{mid},
                        name    => $service_selected->{project}->{name}
                    }
                };

                push @{ $service_selected->{forms} } => $form;  
            }else{
                if ($stash->{task_current}) {

                    map {
                        $_->{params}->{from} = $stash->{task_current}->{name};
                    } @fieldlets;

                    my $task_selected =  $stash->{task_selected};
                    my $id_task = $stash->{id_task};

                    $key = "form_$task_selected->{name}_$stash->{catalog_parent}";

                    my %task_cleaned = map { 
                        if ($_ !~ /^_/) {
                            ($_, $task_selected->{$_});
                        }else{
                            ();
                        }
                    } keys $task_selected;

                    $form = { 
                        id_rule     => $stash->{id_rule},
                        name        => $key, 
                        fieldlets   => \@fieldlets,
                        type        => 'form', 
                        subtype     => $config->{type_form},
                        parent      => $stash->{catalog_parent},
                        task        => Util->_clone(\%task_cleaned),
                        id_task     => $id_task,
                        project     => {
                            mid     => $task_selected->{project}->{mid},
                            name    => $task_selected->{project}->{name}
                        }
                    };                
                    
                    if ( $service_selected->{tasks} ){
                        push @{$task_selected->{forms}} => $form;
                        push @{ $service_selected->{forms} } => $form if ($config->{type_form} eq 'wizard');
                    }else{
                        push @{ $service_selected->{forms} } => $form if ($config->{type_form} eq 'wizard');    
                    }                    
                }else{
                    $key = "form_service";

                    $form = { 
                        id_rule     => $stash->{id_rule},
                        name        => $key, 
                        fieldlets   => \@fieldlets,
                        type        => 'form', 
                        project     => {
                            mid     => $service_selected->{project}->{mid},
                            name    => $service_selected->{project}->{name}
                        }
                    };

                    push @{ $service_selected->{forms} } => $form;                      
                }
            }
        }
    },
};

# register 'service.catalog.wizard_panel' => {
#     name => 'Wizard Panel',
#     icon => '/static/images/icons/catalog-wizard.png',
#     form => '/forms/wizard_panel.js', 
#     handler => sub{
#         my ( $self, $c, $config ) = @_;
#         my $stash = $c->stash;
#         my $service = $stash->{service};

#         my $path = $config->{path};
#         my $title = $config->{title} || $config->{node_attributes}{text};
#         my $note = $config->{note} || $config->{node_attributes}{note};
        
#         #push @{ $stash->{wizard_js_forms} }, $path;
#         push @{ $service->{forms} }, { title=>$title, path=>$path, note=>$note };
#     },
# };


sub set_service_data {
    my ( $self, $relation_field, $service_data, $id_category, $stash ) = @_;
    my $topic_data;

    my $date = '' . Class::Date->now;
    $date =~ s/\W//g;
    $topic_data->{title}              = $date . '_' . uc $stash->{category_topic_created_service} . '_' . $stash->{bl};
    $topic_data->{category}           = $id_category;     
    $topic_data->{id_category_status} = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category}); 
    $topic_data->{description}        = $service_data->{description};
    $topic_data->{username}           = $stash->{username};
    $topic_data->{bl}                 = $stash->{bl};
    $topic_data->{$stash->{category_id_field_bl_service}} = $stash->{bl_mid};
    $topic_data->{$relation_field}    = $service_data->{mids_topic_created_task} if $service_data->{mids_topic_created_task};
    $topic_data->{$stash->{category_id_field_project_service}} = $service_data->{project}->{mid};


    
    # if( $service_data->{forms} ){
    #     my @forms = grep { $_->{parent} eq $service_data->{mid} } _array $stash->{wizard_forms};
    #     my $index = 0;
    #     for my $form (@forms) {
    #         $index += 1000;
    #         for my $fieldlet (@{$form->{fieldlets}}){
    #             $fieldlet->{params}->{field_order} += $index;
    #         }
    #         push @all_fields, @{$form->{fieldlets}};
    #     }
    # }

    my @all_fields;
    my $index = 99000;
    for my $form (_array $stash->{service_selected}->{forms}) {
        
        if( !$form->{id_task} ){
            for my $fieldlet (@{$form->{fieldlets}}){
                $index += 1;

                if ($fieldlet->{params}->{type} eq 'variable') {
                    my $ci_variable = ci->variable->find_one( { name => $fieldlet->{id_field} } );
                    my $var_type = $ci_variable->{var_type};
                    my $var_columns = $ci_variable->{var_columns};
                    if ($var_type eq 'grid editor') {
                        $fieldlet->{params}->{html} = '/fields/templates/html/grid_editor.html'; 
                        $fieldlet->{params}->{columns} = $var_columns; 
                        $fieldlet->{params}->{section} = 'head';    
                    }
                }
                $fieldlet->{params}->{field_order} = $index;
                $fieldlet->{params}->{field_order_html} = $index;
                $fieldlet->{params}->{field_type_form} = $form->{subtype};
            }            
            push @all_fields, @{$form->{fieldlets}};            
        }
    }
    $topic_data->{_catalog_fieldlets}= \@all_fields;

    for my $field ( @all_fields ){
        my $from_data = '';
        $from_data = '_' . $field->{params}->{from} if (exists $field->{params}->{from});
        $topic_data->{$field->{id_field}} = $stash->{wizard_data}->{ $service_data->{project}->{mid} . '_' . $field->{id_field} . $from_data } if ( exists $stash->{wizard_data}->{ $service_data->{project}->{mid} . '_' . $field->{id_field} . $from_data });
    }                         

    return $topic_data;
}

sub create_or_update_service {
    my ( $self, $relation_field, $service_selected, $id_category, $stash_data ) = @_;

    my $action; #'add';
    my $topic_data = $self->set_service_data( $relation_field, $service_selected, $id_category, $stash_data );
    if ($service_selected->{mid_topic_created_service}){
        $action = 'update';
        delete $topic_data->{title};
        $topic_data->{topic_mid} = $service_selected->{mid_topic_created_service};
    }else{
        $action = 'add';
        $topic_data->{id_category_status} = $stash_data->{status_draft};
    };
    
    $topic_data->{_catalog_stash} = _dump $stash_data;

    my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => $action, %$topic_data } );
    $stash_data->{mid_topic_created_catalog} = $topic_mid;
    $service_selected->{mid_topic_created_service} = $topic_mid;
    $service_selected->{run_service_step} = 'CHECK';

}

sub set_task_data {
    my ($self, $task_selected, $id_category, $stash ) = @_;
    my $topic_data;

    $topic_data->{title}              = $task_selected->{name};
    $topic_data->{category}           = $id_category;               
    $topic_data->{id_category_status} = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category});
    $topic_data->{description}        = $task_selected->{description};
    $topic_data->{username}           = $stash->{username};
    $topic_data->{origin}             = $task_selected->{attributes}->{origin};
    $topic_data->{ci_task_mid}        = $task_selected->{mid}; 
    $topic_data->{ci_task_variables_output} = $task_selected->{attributes}->{variables_output}; 
    $topic_data->{bl}                 = $stash->{bl};  
    $topic_data->{peticion}           = [$stash->{service_selected}->{mid_topic_created_service}];
    $topic_data->{$stash->{category_id_field_bl_task}}          = $stash->{bl_mid};
    $topic_data->{$stash->{category_id_field_project_task}}     = $stash->{service_selected}->{project}->{mid} if ($stash->{service_selected}->{project}->{mid});
    $topic_data->{$stash->{category_id_field_area_task}}        = $task_selected->{attributes}->{area};
    $topic_data->{$stash->{category_id_field_subproject_task}}  = $stash->{task_selected}->{project}->{mid} if ($stash->{task_selected}->{project}->{mid} && $stash->{task_selected}->{project}->{type} eq 'S');


    my @all_fields;
    my $index = 99000;
    if ( $task_selected->{forms} ){
        for my $form (_array $task_selected->{forms}) {
            for my $fieldlet (@{$form->{fieldlets}}){
                $index += 1;
                if ($fieldlet->{params}->{type} eq 'variable') {
                    my $ci_variable = ci->variable->find_one( { name => $fieldlet->{id_field} } );
                    my $var_type = $ci_variable->{var_type};
                    my $var_columns = $ci_variable->{var_columns};
                    if ($var_type eq 'grid editor') {
                        $fieldlet->{params}->{html} = '/fields/templates/html/grid_editor.html'; 
                        $fieldlet->{params}->{columns} = $var_columns; 
                        $fieldlet->{params}->{section} = 'head';   
                    }
                }
                $fieldlet->{params}->{field_order} = $index;
                $fieldlet->{params}->{field_order_html} = $index;
                $fieldlet->{params}->{field_type_form} = $form->{subtype};
            }            
            push @all_fields, @{$form->{fieldlets}};
        }
    }

    
    if ( $task_selected->{attributes}->{help} ) {
        $index += 1;
        my $fieldlet_help = {
            id => '999999999999',
            id_field => 'ayuda',
            name => _loc('Help'),
            params => {
                bd_field => 'ayuda',
                data => 'clob',
                editable => 1,
                field_order => $index,
                field_order_html => $index,
                field_type_form => 'topic',
                html => '/fields/templates/html/help_task.html',
                id_field => 'ayuda',
                js => '/fields/templates/js/help_task.js',
                meta_type => 'content',
                name_field => _loc('Help'),
                origin  => 'custom',
                section => 'head',
                type => 'html/editor',
            }
        };

        push @all_fields, $fieldlet_help;
    }

    $topic_data->{_catalog_fieldlets}   = \@all_fields;

    for my $field ( @all_fields ){
        my $from_data = '';
        $from_data = '_' . $field->{params}->{from} if (exists $field->{params}->{from});        
        $topic_data->{$field->{id_field}} = $stash->{wizard_data}->{ $task_selected->{project}->{mid} . '_' . $field->{id_field} . $from_data} if ( exists $stash->{wizard_data}->{ $task_selected->{project}->{mid} . '_' . $field->{id_field} . $from_data});
    }   

    if ($task_selected->{attributes}->{output}){
        my $output_attributes = $task_selected->{attributes}->{output};
        foreach my $output ( _array $output_attributes ){
            try{
                my $output_ci = ci->new($output);
                $stash->{output_data}->{ $task_selected->{project}->{mid} . '_' . $output_ci->{name}} = $topic_data->{$output_ci->{name}};
            };
        }
    }

    return $topic_data;
}

 
sub create_or_update_task {
    my ($self, $service_selected, $task_selected, $id_category, $stash  ) = @_;

    if ( $service_selected->{tasks} ){ 
        if ($service_selected->{type} eq '_service'){
            my $relation_field = $stash->{field_service_task_relation};
            my $id_category_service = $stash->{category_mid_topic_created_service};        

            if ( !$service_selected->{run_service_step} ){
                $self->create_or_update_service( $relation_field, $service_selected, $id_category_service, $stash );
            }

            if ( $service_selected->{run_service_step} ne 'DONE') { 
                if ( $stash->{catalog_step} eq 'RUN' ){
                    my $id_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $id_category_service});
                    $self->set_service_status($service_selected, $id_category_service, $id_status, $stash );
                    $service_selected->{status_service} = $id_status;
                }
            }            
        }

        my $action;
        my $topic_data = $self->set_task_data( $task_selected, $id_category, $stash );

        if ($task_selected->{attributes}->{topic_mid}){
            $action = 'update';
            delete $topic_data->{title};
            $topic_data->{topic_mid} = $task_selected->{attributes}->{topic_mid};
        }else{
            $action = 'add';
            $topic_data->{id_category_status} = $stash->{status_draft};    
        }

        $task_selected->{run_task_step} = 'CHECK';
        $topic_data->{_catalog_stash} = _dump $stash;
        my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => $action, %$topic_data,  } );
        
        $task_selected->{attributes}->{topic_mid} = $topic_mid;

        if( $action eq 'add'){
            push @{ $service_selected->{mids_topic_created_task} }, $topic_mid;     
        } 

        if ($service_selected->{type} eq '_service'){
            $self->set_service_selected($stash);
            $self->set_task_selected($stash);
        }
    } 
}

sub has_dependency {   
    my ($self, $service_selected, $stash_data) = @_;
    my $parent_task = $stash_data->{task_current}->{parent};
    my $tasks = $service_selected->{tasks};
    my $bl_dependency = 0;
    foreach my $task ( _array $tasks ){
        if ($task->{mid} eq $parent_task){
            $bl_dependency = 1;
            $parent_task = $task;
            last;
        }
    }         
    
    return $bl_dependency, $parent_task; 
}


sub build_catalog_folder {
    my ($self, $p) = @_;
    my @children;


    my $task_children = $p->{task_children};
    my $id_rule = $p->{id_rule};

    my @roles;
    my $role = 'CatalogTask';
    for my $r ( _array $role ) {
        if( $r !~ /^Baseliner/ ) {
            $r = uc($r) eq 'CI' ? "Baseliner::Role::CI" : "Baseliner::Role::CI::$r" ;
        }
        push @roles, $r;
    }
    my $classes = [ packages_that_do( @roles ) ];
    my $collection = { 
        '$in'=>[ map { 
                    my $coll= $_->can('collection') ? $_->collection : Util->to_base_class($_);
                    $coll 
                } @$classes 
        ] 
    };

    my @task_cis = mdb->master_doc->find({collection => $collection, active => '1'} )->sort({ name => 1 })->all;

    foreach my $ci_task (@task_cis){
        my $task = {
            children => $task_children->{$ci_task->{mid}} ? $task_children->{$ci_task->{mid}}->{children} : [],
            active  => 1,
            data        => $task_children->{$ci_task->{mid}} ? $task_children->{$ci_task->{mid}}->{data} : {task => [$ci_task->{mid}]}, 
            id_rule     => $id_rule,
            icon        => '/static/images/icons/catalogue.png',
            #icon        => '/static/images/icons/catalog-target.png',
            key         => 'statement.catalog.task',
            leaf        => \0,
            name        => '_task',
            text        => $ci_task->{name},    
            disabled    => \0,    
            expanded    => \1,
            holds_children => \1,
            nested      => '0',
            on_drop     => '',
            on_drop_js  => undef,
            palette     => \0,
            run_sub     => \0,        
        };

        push @children, $task;
    };

    my $folder;
    if ( $p->{_catalog_folder} ){
        delete $p->{_catalog_folder}->{children};
        $p->{_catalog_folder}->{children} = \@children;
        $folder = $p->{_catalog_folder};
    }else{
        $folder = {
            children => \@children,
            data => {},
            icon => '/static/images/icons/catalogue.png',
            #icon => '/static/images/icons/catalog-folder.png',
            key => 'statement.catalog.folder',
            leaf => \0,
            name=> '_catalog_folder',
            text => _loc('Tasks list'),
            disabled => \0,
            expanded    => \1,
            holds_children => \1,
            nested      => 0,
            on_drop     => '',
            on_drop_js  => undef,
            palette     => \0,
            run_sub     => \1,           
        };
    }
    return $folder;
}

sub set_service_selected {
    my ($self, $stash) = @_;

    my $service_selected = $stash->{service_selected};
    my $relation_field = $stash->{field_service_task_relation}; 
    my $id_category = $stash->{category_mid_topic_created_service};

    my $topic_data = $self->set_service_data( $relation_field, $service_selected, $id_category, $stash );  
    $topic_data->{topic_mid} = $service_selected->{mid_topic_created_service};
    #$service_selected->{run_service_step} = 'DONE';
    $stash->{from_catalog_event_topic} = 0;                                     
    $topic_data->{_catalog_stash} = _dump $stash;
    delete $topic_data->{title};
    my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );
}


sub set_task_selected {
    my ($self, $stash) = @_;
    my $service_selected = $stash->{service_selected};
    my $id_category = $stash->{category_mid_topic_created_service};

    if ($service_selected->{mids_topic_created_task}){
        mdb->topic->update({ mid => { '$in' => $service_selected->{mids_topic_created_task} }},{ '$set' => { '_catalog_stash' => _dump $stash }},{ multiple=>1 });
        my $id_task_category = $stash->{category_mid_topic_created_task};
        my $mid_status_final = Baseliner->model('Topic')->get_final_status_from_category({id_category => $id_task_category});  
        #my $tot_tasks = scalar @{$service_selected->{mids_topic_created_task}};
        my $tot_tasks = scalar @{$service_selected->{tasks}};
        my $tot_tasks_done = mdb->topic->find({ mid => { '$in' => $service_selected->{mids_topic_created_task}}, 'category_status.id' => $mid_status_final})->all;

        if($tot_tasks eq $tot_tasks_done){
            my $status_mid = Baseliner->model('Topic')->get_final_status_from_category({id_category => $id_category});

            my $topic_data = {};
            $topic_data->{topic_mid} = $service_selected->{mid_topic_created_service};
            $topic_data->{status_new} = $status_mid;
            $topic_data->{username} = 'clarive'; #$stash->{username};   
            $stash->{from_catalog_event_topic} = 1;
            $topic_data->{_catalog_stash} = _dump $stash;
            delete $topic_data->{title};
            my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );
        }
    }
}

sub set_task_status {
    my ($self, $task_selected, $id_category, $id_status, $stash) = @_;

    my $username = $stash->{username};
    my @roles = Baseliner->model('Permissions')->user_roles_for_topic( username => $username, mid => $task_selected->{attributes}->{topic_mid} );
    if (!@roles){
        $username = 'clarive' if ($username ne 'root');
    }

    my $topic_data = {};
    #$topic_data->{title} = $task_selected->{name};
    $topic_data->{topic_mid} = $task_selected->{attributes}->{topic_mid};
    $topic_data->{category} = $id_category;
    $topic_data->{status_new} = $id_status ;
    $topic_data->{username} = $username;   
    $stash->{from_catalog_event_topic} = 1;
    $topic_data->{_catalog_stash}       = _dump $stash;
    
    my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );            
    
}

sub set_service_status {
    my ($self, $service_selected, $id_category, $id_status, $stash) = @_;

    my $username = $stash->{username};
    my @roles = Baseliner->model('Permissions')->user_roles_for_topic( username => $username, mid => $service_selected->{mid_topic_created_service}  );
    if (!@roles){
        $username = 'clarive' if ($username ne 'root');
    }

    my $topic_data = {};
    #$topic_data->{title} = $service_selected->{name};
    $topic_data->{topic_mid} = $service_selected->{mid_topic_created_service};
    $topic_data->{category} = $id_category;
    $topic_data->{status_new} = $id_status;
    $topic_data->{username} = $username;
    $stash->{from_catalog_event_topic} = 1;
    $topic_data->{_catalog_stash} = _dump $stash;

    my ( $msg, $topic_mid ) = Baseliner->model('Topic')->update( { action => 'update', %$topic_data } );
    $service_selected->{run_service_step} = 'DONE';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
