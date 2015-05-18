package Baseliner::Controller::Catalog;
use Baseliner::Plug;
use Baseliner::Utils;

BEGIN { extends 'Catalyst::Controller' }


sub init_catalog : Local {
    my ( $self, $c ) = @_;
    
    $c->stash->{perm_catalog} =  Util->_encode_json(Baseliner->model('Catalog')->get_perm_catalog( username => $c->username ));
    $c->stash->{template} = '/comp/catalog.js';
}

sub next_panel : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};
    my $stash = $p->{stash} // {};

    delete $stash->{task_current};

    $stash->{realm} = 'project';

    my $service_selected = $stash->{service_selected};
    delete $service_selected->{forms};  
    foreach my $task (_array $service_selected->{tasks}){
        delete $task->{forms};
    }
    $stash->{is_first_form} = 0;
    $stash->{is_last_form} = 0;

    if ($stash->{show_request} != 1){
        $stash->{show_request} = 0;    
    }

    $stash->{catalog_filter} = 1;
    my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule => $p->{id_rule}, stash => $stash, no_merge_variables => 1 );
    my @forms = _array $stash->{service_selected}->{forms};

    my $index = 0;
    foreach my $form (@forms){
        last if ($form->{id_task} eq $stash->{current_form}->{id_task} );
        $index ++;
    }

    if ($stash->{catalog_step}  eq 'NEXT') {
        $index += 1 if ($index < scalar @forms - 1);
    }else{
        $index -= 1 if ($index > 0);    
    } 

    if ($stash->{current_form} ) {
        if ($stash->{current_form}{task}{name} eq $forms[$index]->{task}{name}){
            $stash->{show_request} = 1; 
            $stash->{is_last_form} = 1;
        }else{
            $stash->{is_last_form} = 0;           
        }
    }
    $stash->{current_form} = $forms[$index];
    $stash->{is_first_form} = 1 if ($index == 0);
    $c->stash->{json} = { success => \1, stash => $stash };

    $c->forward('View::JSON');
}

sub clone_request : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};
    my @bls = split /,/,$p->{bls} // [];
    my $mid = $p->{mid} // undef;

    my $topic = mdb->topic->find_one({ mid => $mid });
    my $catalog = _load $topic->{_catalog_stash};
    my $username = $c->username;
    my $variables = BaselinerX::CI::variable->default_hash; 
    my $service_task_relation;

    my $project = ci->new( $catalog->{service_selected}->{project}->{mid} );

    my @requests;
    for my $bl (@bls){

        my $stash = { wizard_data => {}, catalog_step => 'DRAFT', catalog_filter => 0, username => $username };
        $stash->{realm} = 'project';
        $stash->{variables} = $variables;     
        $self->init_var_catalog( $stash );
        $service_task_relation = $stash->{field_service_task_relation};
        $stash->{bl_mid} = ci->bl->find_one({bl => $bl})->{mid};    

        $stash->{bl} = $bl; 
        $stash->{id_rule} = $catalog->{id_rule};
        $stash->{service_selected} = exists $catalog->{selection_catalog} ? Util->_clone($catalog->{selection_catalog}) : Util->_clone($catalog->{service_selected});
       
        if ($project->{variables}->{$stash->{bl}}) {
            %{$stash->{variables}} = ( %{$stash->{variables}}, %{$project->{variables}->{$stash->{bl}}});        
        }     

        delete $stash->{service_selected}->{mid_topic_created_service};
        delete $stash->{service_selected}->{mids_topic_created_task};
        delete $stash->{service_selected}->{run_service_step};
        $stash->{service_selected}->{forms} = $catalog->{service_selected}->{forms};
        $stash->{service_selected}->{tasks} = Util->_clone($catalog->{service_selected}->{tasks});

        for my $task ( _array $stash->{service_selected}->{tasks}){
            delete $task->{attributes}->{topic_mid};
            delete $task->{run_task_step};
        }

        my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule => $catalog->{id_rule} , stash => $stash, no_merge_variables => 1 );

        push @requests, $stash->{service_selected}->{mid_topic_created_service};
        
    }

    my @topics = mdb->topic->find({mid=> { '$in' => \@requests }})->sort({ created_on => -1 })->all;
    my @tree;

    foreach my $topic (@topics){
        my $id = mdb->oid->{value};
        my $catalog = _load $topic->{_catalog_stash};
        my $attributes = {
            ts => $topic->{created_on},
            topic_mid => $topic->{mid},
            catgory_name => $topic->{category}{name},
            category_color => $topic->{category}{color},
            baseline => $catalog->{bl},
        };

        my $tree_chi = {
            _is_leaf    => \1,
            icon        => '/static/images/icons/topic.png',
            attributes  => $attributes,
            tasks       => $topic->{$service_task_relation},
            name        => $topic->{title},
            mid         => $topic->{mid},
            type        => 'draft',
            project     => $project->{mid},
        };
        push @tree, $tree_chi;        
    }

    $c->stash->{json} = { success => \1, request => \@tree };
    $c->forward('View::JSON');
}


sub wizard_start : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};
    my $stash = $p->{stash} // {};
    my $mid = $p->{mid} // undef;

    delete $stash->{current_form};
    $stash->{catalog_step}  = 'WIZARD';


    if ($mid) {
        my $topic = mdb->topic->find_one({ mid => $mid });
        $stash = _load ($topic->{_catalog_stash});  
        $stash->{catalog_step}  = 'DRAFT';
        $stash->{service_selected}->{mid_topic_created_service} = $mid;
    }
    
    $stash->{catalog_filter} = 1;
    $stash->{realm} = 'project';
    $stash->{show_request} = 0; 
    $stash->{is_first_form} = 1;


    my $first_sel = $stash->{service_selected};
    my $id_rule;


    my $project = ci->new($stash->{service_selected}->{project}->{mid});
    if ($project->{variables}->{$stash->{bl}}) {
        %{$stash->{variables}} = ( %{$stash->{variables}}, %{$project->{variables}->{$stash->{bl}}});        
    }


    if ( $first_sel->{type} eq '_service' ){
        $id_rule = $stash->{id_rule};
        $stash->{service_selected}->{id_rule} = $id_rule;
    }else{
        $id_rule = $first_sel->{id_rule};  
    }

    my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule => $id_rule, stash => $stash, no_merge_variables => 1  ) if length $id_rule;

    $stash->{current_form} = $stash->{service_selected}->{forms}->[0] if (exists $stash->{service_selected}->{forms} && ref $stash->{service_selected}->{forms} eq 'ARRAY');
    $c->stash->{json} = { stash => $stash };
    $c->forward('View::JSON');
}

sub save : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};
    my $stash = $p->{stash} // {};
    $stash->{realm} = 'project';
    $stash->{catalog_step}  = 'DRAFT';

    my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule => $p->{id_rule}, stash => $stash, no_merge_variables => 1 );

    $c->stash->{json} = { stash => $stash, success => \1 }; 
    $c->forward('View::JSON');
}


sub request : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};
    my $stash = $p->{stash} // {};
    $stash->{realm} = 'project';
    $stash->{catalog_step}  = 'RUN';
    $stash->{catalog_filter} = 1;
    my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule => $p->{id_rule}, stash => $stash, no_merge_variables => 1 );
    $stash->{wizard_data} = {};
    $stash->{catalog_step} = 'MENU';
    delete $stash->{services_selected};
    delete $stash->{service_selected};
    delete $stash->{task_selected};
    delete $stash->{tasks_status};
    
    $c->stash->{json} = { stash => $stash, success => \1 }; 
    $c->forward('View::JSON');
}

sub add_request_history { 
    my ($self, $parentid, $stash, $mid_project) = @_;
    my @tree;

    my $id_category = $stash->{category_mid_topic_created_service};
    my $id_status = $stash->{category_initial_status_service};
    my $id_project = $stash->{category_id_field_project_service};
    my $service_task_relation = $stash->{field_service_task_relation};
    my $query;


    my @status_ids = _unique map{_array $_->{statuses}}mdb->category->find({id=>$id_category})->all;
    @status_ids = map{$_->{id_status}}ci->status->find({id_status=>mdb->in(@status_ids)})->all;

    $query->{'category.id'} = $id_category;
    $query->{'category_status.id'} = mdb->in(@status_ids);
    $query->{$id_project} = $mid_project;

    my @topics = mdb->topic->find($query)->sort({ created_on => -1 })->all;

    foreach my $topic (@topics){
        my $id = mdb->oid->{value};
        my $catalog = _load $topic->{_catalog_stash};
        my $attributes = {
            ts => $topic->{created_on},
            topic_mid => $topic->{mid},
            catgory_name => $topic->{category}{name},
            category_color => $topic->{category}{color},
            baseline => $catalog->{bl},
            status => $topic->{category_status}{name},
            status_color => $topic->{category_status}{color},
        };

        my $tree_chi = {
            _id         => $id,
            _parent     => $parentid,
            _is_leaf    => \1,
            icon        => '/static/images/icons/topic.png',
            attributes  => $attributes,
            tasks       => $topic->{$service_task_relation},
            name        => $topic->{title},
            mid         => $topic->{mid},
            type        => 'history',
            project     => $mid_project,
        };
        push @tree, $tree_chi;        
    }
    return @tree;
}

sub expanded_folder { 
    my ($self, $parentid, $stash, $service_project) = @_;
    my @tree;
    my %cis;

    my %project;
    my %service_project;
    my %parent_exclude;

    my $key_mid_id_service;

    
    #################################################################################################
    ##### my @mids = map { $_->{mid} } grep { $_->{mid} } _array $stash->{services};
    ##### _log ">>>>>>>>>>>>>>>>>>>>>><MIDS: " . _dump @mids;
    #################################################################################################



    for my $service ( _array( $stash->{services} ) ) {
        next if ($service->{type} eq 'folder');
        my $desc = $service->{description};
        # push a service into the catalog tree

        if ($service->{mid}){
            $key_mid_id_service = $service->{id_service} ? $service->{mid} . '_' . $service->{id_service} : $service->{mid};
            if(!exists $cis{$key_mid_id_service}){
                my $query = {mid => $service->{mid}};
                if ( $service->{type} eq 'task' ) {
                    #$query->{bl} = { '$in' => ['*', $stash->{bl}]};
                    $query->{bl} = { '$regex' => qr/$stash->{bl}|\*/ };  #TODO: change bl to be an array or improve regex it does not match some cases
                }

                my $ci_data = mdb->master_doc->find_one($query, {yaml => 0});  ## TODO: get only one query
                next if (!$ci_data);


                my $attributes = $service->{attributes};
                my %attributes_merge = (%$ci_data, %$attributes);  
                $cis{$key_mid_id_service} = \%attributes_merge;

                if ( $service->{type} eq 'service' ) {
                    $parent_exclude{$service->{id}} = 1;

                    my $ci_service = ci->new($service->{mid});
                    my $hide_service = $ci_service->hide_service($stash->{bl}, $service_project);
                    next if ($hide_service);
                    map { $service_project{$service->{mid}} = $_->{mid}} _array $ci_service->{project};
                }  

                if ( $service->{type} eq 'task' ) {
                    if ($service->{id_service} && $service->{id_service} ne 'task_group'){
                        next if (!exists $service_project{$service->{id_service}});
                    }else{
                        $parent_exclude{$service->{id}} = 1;
                    }

                    if ( $service_project->{type} ne  $attributes_merge{type} ){
                        next if (!exists $parent_exclude{$service->{parent}});
                    } 
                }
            }
        }else{
            $parent_exclude{$service->{id}} = 1;    
        }

        my $tree_chi = {
            _id         => $parentid ?  mdb->oid->{value} : $service->{id},
            _parent     => $parentid // $service->{parent},
            _is_leaf    => $service->{_is_leaf},
            icon        => $service->{icon},
            id_rule     => $service->{id_rule},
            id_service  => $service->{id_service},
            name        => $service->{name},
            mid         => $service->{mid},
            description => ( length $desc ? Util->_markdown($desc) : '' ),
            attributes  => $service->{mid} &&  $key_mid_id_service ? $cis{$key_mid_id_service} : undef,
            id_task     => $service->{id_task},
            tasks       => $service->{tasks},
            project     => $service_project,
            bl          => {
                name => $stash->{bl},
                mid  => $stash->{bl_mid}
            },
            type        => $service->{type},
            forms       => $service->{forms},
        };
        push @tree, $tree_chi;
    }
    return @tree;
}

# processor for rule results
sub add_services { 
    my ($self, $stash, $service_project) = @_;
    my @tree;
    my %cis;

    my %project;
    my $key_mid_id_service;

    for my $service ( _array( $stash->{services} ) ) {
        my $desc = $service->{description};

        my $tree_chi = {
            _id         => $service->{id},
            _parent     => $service->{parent},
            _is_leaf    => $service->{_is_leaf},
            icon        => $service->{icon},
            id_rule     => $service->{id_rule},
            id_service  => $service->{id_service},
            name        => $service->{name},
            mid         => $service->{mid},
            description => ( length $desc ? Util->_markdown($desc) : '' ),
            attributes  => $service->{mid} && $key_mid_id_service ? $cis{$key_mid_id_service} : undef,
            id_task      => $service->{id_task},
            tasks       => $service->{tasks},
            project     => $service_project,
            bl          => {
                name => $stash->{bl},
                mid  => $stash->{bl_mid}
            },
            type        => $service->{type},
            forms       => $service->{forms},
        };
        push @tree, $tree_chi;
    }

    return @tree;
}

# processor for rule results
sub add_drafts { 
    my ($self, $stash, $service_project) = @_;
    my @tree;

    my $id_category = $stash->{category_mid_topic_created_service};
    my $id_status = $stash->{status_draft};
    my $id_project = $stash->{category_id_field_project_service};
    my $service_task_relation = $stash->{field_service_task_relation};
    my $query;

    $query->{'category.id'} = $id_category;
    $query->{'category_status.id'} = $id_status;
    
    $query->{$id_project} = $service_project->{mid} if $id_project;

    
    #######################################################################
    # CONTROLAR SEGURIDAD TOPICOS
    #######################################################################
    my @topics = mdb->topic->find($query)->sort({ created_on => -1 })->all;

    foreach my $topic (@topics){
        my $id = mdb->oid->{value};
        my $catalog = _load $topic->{_catalog_stash};
        my $attributes = {
            ts => $topic->{created_on},
            topic_mid => $topic->{mid},
            catgory_name => $topic->{category}{name},
            category_color => $topic->{category}{color},
            baseline => $catalog->{bl},
            status => $topic->{category_status}{name},
            status_color => $topic->{category_status}{color},
        };

        my $tree_chi = {
            _id         => $id,
            _parent     => $stash->{catalog_parent},
            _is_leaf    => \1,
            icon        => '/static/images/icons/topic.png',
            attributes  => $attributes,
            tasks       => $topic->{$service_task_relation},
            name        => $topic->{title},
            mid         => $topic->{mid},
            type        => 'draft',
            project     => $service_project->{mid},
        };
        push @tree, $tree_chi;        
    }
    return @tree;
}

sub add_history { 
    my ($self, $stash, $service_project) = @_;
    my @tree;

    my $id_category = $stash->{category_mid_topic_created_service};
    my $id_status = $stash->{category_initial_status_service};
    my $id_project = $stash->{category_id_field_project_service};
    my $service_task_relation = $stash->{field_service_task_relation};

    my $id = mdb->oid->{value};
    my $tree_chi = {
        _id         => $id,
        _parent     => $stash->{catalog_parent},
        _is_leaf    => \0,
        icon        => '/static/images/icons/catalog-folder.png',
        attributes  => '',
        tasks       => '',
        name        => _loc('History'),
        mid         => "history:$service_project->{mid}",
        type        => '_history_folder',
        project     => $service_project,
    };
    push @tree, $tree_chi;        
    return @tree;
}


# project tasks
sub list_projects {
    my ( $self,$parentid, $parent_project, $username ) = @_;
    my @tree;
    my $k=0;

    my $where;
    if ($parent_project){
        $where = {parent_project => {'$in'=>[$parent_project]}};    
    }else{
        my @ids_project = Baseliner->model( 'Permissions' )->user_projects_ids( username => $username );
        $where = {mid => {'$in'=> \@ids_project }, parent_project => undef};
    }
    $where->{active} = '1';

    for my $project ( ci->project->find($where)->sort({ name=>1 })->all ) {
        my $id = mdb->oid->{value};
        push @tree, {
            _id         => "$id",
            _parent     => $parentid,
            _is_leaf    => \0,
            name        => $project->{name},
            mid         => $project->{mid},
            type        => $parent_project ? 'subproject' : 'project',
            icon        => '/static/images/icons/project.png'
        };
    }  

    return @tree;
}

sub catalog_rules {
    my ( $self ) = @_;
    my @rules;
    # grab all catalog rules
    for my $rule ( mdb->rule->find({ rule_type => 'catalog', rule_active => mdb->true })->all ){
        # prepare each rule
        push @rules, { id_rule => $rule->{id} };
        #my $ret = Baseliner->model('Rules')->run_single_rule( id_rule=>$rule->{id}, stash=>$stash );
    }
    return @rules;
}

sub init_var_catalog {
    my ( $self, $stash) = @_;

    my $username = $stash->{username};
    my $config = Baseliner->model('ConfigStore')->get('config.catalog.settings');
    my $mid_category = mdb->category->find_one({name => $config->{service}})->{id};
    my $mid_task = mdb->category->find_one({name => $config->{task}})->{id}; 
    my $mid_initial_status = Baseliner->model('Topic')->get_initial_status_from_category({id_category => $mid_category}); 
    my $mid_status_draft = ci->status->find_one({name => $config->{status_draft}})->{id_status};
    my $meta_service = Baseliner->model('Topic')->get_meta( undef, $mid_category, $username );
    my $meta_task = Baseliner->model('Topic')->get_meta( undef, $mid_task, $username );
    my @fields_project_service = grep { $_->{meta_type} && $_->{meta_type} eq 'project' && $_->{collection} eq 'project'} _array $meta_service;
    my @fields_bl_service = grep {$_->{ci_class} && $_->{ci_class} eq 'bl'} _array $meta_service;
    my @fields_project_task = grep {$_->{meta_type} && $_->{meta_type} eq 'project' && $_->{collection} eq 'project'} _array $meta_task;
    my @fields_area_task = grep {$_->{meta_type} && $_->{meta_type} eq 'project' && $_->{collection} eq 'area'} _array $meta_task;
    my @fields_bl_task = grep {$_->{ci_class} && $_->{ci_class} eq 'bl'} _array $meta_task;
    my @fields_subproject_task = grep {$_->{meta_type} && $_->{meta_type} eq 'subproject'} _array $meta_task;
    #my @fields_subproject_task = grep {$_->{meta_type} && $_->{meta_type} eq 'project'} _array $meta_task;

    $stash->{job} = BaselinerX::Type::Service::Container::Job->new( job_stash=>$stash );
    $stash->{category_topic_created_service} = $config->{service};
    $stash->{category_mid_topic_created_service} = $mid_category;
    $stash->{category_initial_status_service} = $mid_initial_status;
    $stash->{category_id_field_project_service} = scalar @fields_project_service gt 0 ? $fields_project_service[0]->{id_field} : undef;
    $stash->{category_id_field_bl_service} = scalar @fields_bl_service gt 0 ? $fields_bl_service[0]->{id_field} : undef;
    $stash->{category_id_field_project_task} = scalar @fields_project_task gt 0 ? $fields_project_task[0]->{id_field} : undef;
    $stash->{category_id_field_area_task} = scalar @fields_area_task gt 0 ? $fields_area_task[0]->{id_field} : undef;
    $stash->{category_id_field_bl_task} = scalar @fields_bl_task gt 0 ? $fields_bl_task[0]->{id_field} : undef;
    $stash->{category_id_field_subproject_task} = scalar @fields_subproject_task gt 0 ? $fields_subproject_task[0]->{id_field} : undef;
    $stash->{category_topic_created_task} = $config->{task};
    $stash->{category_mid_topic_created_task} = $mid_task;
    $stash->{field_service_task_relation} = $config->{service_task_relation};
    $stash->{status_draft} = $mid_status_draft;

    $stash->{show_request} = 0;

}


sub generate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};

    my @tree;
    my $username = $c->username;

    my $stash = { wizard_data => {}, catalog_step => 'MENU', catalog_filter => 0, username => $username };

    $self->init_var_catalog( $stash );
    $stash->{bl} = $p->{bl}; 

    $stash->{bl_mid} = ci->bl->find_one({bl => $p->{bl}})->{mid};

    if( my $mid = $p->{mid} ) {
        if ( $mid =~ /^history/ ){
            my @history_mid_project = split /:/, $mid;
            my $mid_project = $history_mid_project[1];
            push @tree, $self->add_request_history( $p->{anode}, $stash, $mid_project );
        }elsif ( $mid =~ /^folder/ ){
            my @folder_name = split /:/, $mid;
            my $name_folder = $folder_name[1];
            my $mid_project = $folder_name[2];
            my $type_folder = $folder_name[3];

            my $project = ci->new( $mid_project );
            my $id = $p->{anode}; # $mid
            local $stash->{realm} = exists $project->{parent_project}  ? 'subproject' : 'project';
            local $stash->{catalog_parent} = $id;
            local $stash->{services} = [];
            local $stash->{service_mid_project_click} = $mid_project;  

            my $service_project = {
                mid     => $project->{mid},
                name    => $project->{name},
                type    => exists $project->{parent_project}  ? 'S' : 'P',
                parent_mid => $project->{parent_project}->{mid_project},
            };            

            my $tasks_list;
            if ( $type_folder eq '_catalog_folder'){

                $tasks_list = cache->get('catalog_folder:'.$stash->{bl});
            }

            if ( !$tasks_list) {
                my @rules = $self->catalog_rules;
                local $stash->{name_folder} = $name_folder;
                local $stash->{id_folder} = $p->{anode};
                for my $rule ( @rules ) {
                    $stash->{id_rule} = $rule->{id_rule};
                    Baseliner->model('Rules')->dsl_run( id_rule=> $rule->{id_rule}, stash => $stash, no_merge_variables => 1 );
                }
                delete $$stash{job};
                if ( $type_folder eq '_catalog_folder'){
                    cache->set( 'catalog_folder:' . $stash->{bl}, $stash->{services} );
                }
                push @tree, $self->expanded_folder( undef, $stash, $service_project  );
            }else{
                $stash->{services} = $tasks_list;
                push @tree, $self->expanded_folder( $p->{anode}, $stash, $service_project  );
            }

        }else{
            my $project = ci->new( $mid );
            my $id = $p->{anode}; # $mid
            local $stash->{realm} = exists $project->{parent_project}  ? 'subproject' : 'project';
            local $stash->{catalog_parent} = $id;
            local $stash->{services} = [];
            local $stash->{service_mid_project_click} = $mid;

            # ---> run each rule for this project
            #local $stash->{name_folder} = "no_children";

            my @rules = $self->catalog_rules;
            for my $rule ( @rules ) {
                $stash->{id_rule} = $rule->{id_rule};
                Baseliner->model('Rules')->dsl_run( id_rule=> $rule->{id_rule}, stash => $stash, no_merge_variables => 1 );
            }
            delete $$stash{job};
            
            my $service_project = {
                mid     => $project->{mid},
                name    => $project->{name},
                type    => exists $project->{parent_project}  ? 'S' : 'P',
                parent_mid => $project->{parent_project}->{mid},
            };

            push @tree, $self->add_drafts( $stash, $service_project );
            push @tree, $self->add_history(  $stash, $service_project ) if $service_project->{type} eq 'P';
            push @tree, $self->add_services( $stash, $service_project );
            push @tree, $self->list_projects( $id, $project->{mid}, $username );
        }
    } else {
        $stash->{variables} = BaselinerX::CI::variable->default_hash;

        # my @rules = $self->catalog_rules;

        # # non project tasks
        # {
        #     local $stash->{catalog} = [];
        #     local $stash->{realm} = 'global';
        #     for my $rule ( @rules ) {
        #         $stash->{id_rule} = $rule->{id_rule};
        #         Baseliner->model('Rules')->dsl_run( id_rule => $rule->{id_rule}, stash => $stash, no_merge_variables => 1 );
        #     }
        #     push @tree, $self->add_services($stash);
        # }
        push @tree, $self->list_projects( undef, undef, $username);
    }

    $c->stash->{json} = { data => \@tree, success => \1, totalCount => scalar(@tree), stash => $stash };
    $c->forward('View::JSON');
}


sub get_status_topic_service : Local {
    my ( $self, $c ) = @_;
    my @rows;
    my $cnt;
    my $config = Baseliner->model('ConfigStore')->get('config.catalog.settings');
    my $mid_category = mdb->category->find_one({name => $config->{service}})->{id};    

    my $cat = mdb->category->find_one({ id=>mdb->in($mid_category) },{ statuses=>1 });
    my @statuses = sort { $a->seq <=> $b->seq } ci->status->search_cis( id_status=>mdb->in($$cat{statuses}) );
    for my $status ( @statuses ) {
        for my $bl_status ( _array( $status->bls ) ) {
            push @rows, {
                            id      => $status->id_status,
                            bl      => $bl_status,
                            name    => $status->name_with_bl( no_common => 1 ),
                        };
        }
    }
    $cnt = @rows;
    
    $c->stash->{json} = { data => \@rows, totalCount => $cnt};    
    $c->forward('View::JSON');
}

sub check_task_requested : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params // {};
    my $username = $c->username;
    my $task_mid = $p->{task_mid};
    my $task_project = $p->{task_project};
    my $bl = $p->{bl};

    my $config = Baseliner->model('ConfigStore')->get('config.catalog.settings');
    my $mid_category_task = mdb->category->find_one({name => $config->{task}})->{id};     
    my $meta_task = Baseliner->model('Topic')->get_meta( undef, $mid_category_task, $username );
    my @fields_project_task = grep {$_->{meta_type} && $_->{meta_type} eq 'project'} _array $meta_task; 
    my @fields_subproject_task = grep {$_->{meta_type} && $_->{meta_type} eq 'subproject'} _array $meta_task;

    my $name_task_project = $task_project->{type} eq 'S' ? $fields_subproject_task[0]->{id_field} : $fields_project_task[0]->{id_field};
    my @topics = _unique map {$_->{ci_task_mid}} mdb->topic->find({$name_task_project => $task_project->{mid}, ci_task_mid => { '$in' => $task_mid}, bl => $bl })->fields({ ci_task_mid => 1, _id => 0 })->all;

    $c->stash->{json} = { success => \1, task_requested => \@topics }; 
    $c->forward('View::JSON');
}

1;
