package Baseliner::Controller::TopicAdmin;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  
register 'menu.admin.topic' => {
    label    => 'Topics',
    title    => _loc ('Admin Topics'),
    action   => 'action.admin.topics',
    url_comp => '/topicadmin/grid',
    icon     => '/static/images/icons/topic.png',
    tab_icon => '/static/images/icons/topic.png'
};

register 'action.admin.topics' => { name=>'View and Admin topics' };

register 'config.field.general' => {
    metadata => [
        { id => 'status', label => '', default => 'visible', values => ['visible','hidden','readonly'] },
    ]
};

register 'config.field.title' => {
    metadata => [
        { id => 'status', label => '', default => 'visible', values => ['visible','hidden','readonly'] },
    ]
};


sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $c->stash->{query_id} = $p->{query};    
    $c->stash->{template} = '/comp/topic/topic_admin.js';
}

sub update_category : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my $idsstatus = $p->{idsstatus};
    my $type = $p->{type};
    
    my $assign_type = sub {
        my ($category) = @_;
        given ($type) {
            when ('R'){
                $category->is_release('1');
                $category->is_changeset('0');                
            }
            when ('C'){
                $category->is_release('0');
                $category->is_changeset('1');                
            }
            when ('N'){
                $category->is_release('0');
                $category->is_changeset('0');                
            }            
        }
    };

    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliTopicCategories')->search({name => $p->{name}})->first;
                if(!$row){
                    my $category = $c->model('Baseliner::BaliTopicCategories')->create(
                        {   name           => $p->{name},
                            color => $p->{category_color},
                            description    => $p->{description} ? $p->{description} : ''
                        }
                    );
                    $assign_type->($category);
                    $category->update;
                    
                    if($idsstatus){
                        foreach my $id_status (_array $idsstatus){
                            $row = $c->model('Baseliner::BaliTopicCategoriesStatus')->create(
                                                                                            {
                                                                                                id_category    =>  $category->id,
                                                                                                id_status   => $id_status,
                                                                                            });     
                        }
                    }
                    
                    my $name = $p->{name};
                    my %acciones_by_category = (    create  => 'Puede crear tópicos de la categoría ',
                                                    view    => 'Puede ver tópicos de la categoría ',
                                                    edit    => 'Puede editar tópicos de la categoría ');
                                                 
                    foreach my $action (keys %acciones_by_category){
                       
                        my $id_action = 'action.topics.' . lc $name . '.' . $action  ;
                        my $name = $acciones_by_category{$action} . $name ;
                                 
                        my $actions = $c->model('Baseliner::BaliAction')->update_or_create({ action_id => $id_action,
                                                                                             action_name => $name,
                                                                                             action_description => $name
                                                                                            });                                
                    }                 

                    $c->stash->{json} = { msg=>_loc('Category added'), success=>\1, category_id=> $category->id };
                }
                else{
                    $c->stash->{json} = { msg=>_loc('Category name already exists, introduce another category name'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Category: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {
            try{
                my $id_category = $p->{id};
                my $category = $c->model('Baseliner::BaliTopicCategories')->find( $id_category );
                my $old_category = $category->name;
                $category->name( $p->{name} );
                $category->color( $p->{category_color} );
                $category->description( $p->{description} );
                $assign_type ->( $category );
                $category->update();
                
                my $rs = Baseliner->model('Baseliner::BaliTopicCategoriesStatus')->search({ id_category => $id_category });
                $rs->delete;
                if($idsstatus){
                    foreach my $id_status (_array $idsstatus){
                        $rs = $c->model('Baseliner::BaliTopicCategoriesStatus')->create(
                                                                                        {
                                                                                            id_category    =>  $category->id,
                                                                                            id_status   => $id_status,
                                                                                        });     
                    }
                }
                
                foreach ( '%action.topics.' . lc $old_category . '%', '%action.topicsfield.' . lc $old_category . '%'){
                    my $rs_action = Baseliner->model('Baseliner::BaliAction')->search({ action_id => {'like', $_  }});
                    while (my $row = $rs_action->next){
                        my @split_action = split /\./, $row->action_id;
                        $split_action[2] = lc $p->{name};
                        my $new_action = join('.',@split_action);
                        $row->action_id($new_action);
                        $row->update;
                    }
                }                
                
                
                
                $c->stash->{json} = { msg=>_loc('Category modified'), success=>\1, category_id=> $id_category };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Category: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            my $ids_category = $p->{idscategory};
            try{
                my @ids_category;
                foreach my $id_category (_array $ids_category){
                    push @ids_category, $id_category;
                }
                  
                my $rs = Baseliner->model('Baseliner::BaliTopicCategories')->search({ id => \@ids_category });
                
                while (my $row = $rs->next){
                    foreach ( '%action.topics.' . lc $row->name . '%', '%action.topicsfield.' . lc $row->name . '%'){
                        my $rs_action = Baseliner->model('Baseliner::BaliAction')->search({ action_id => {'like', $_  }});
                        $rs_action->delete;
                    }
                }
                
                $rs->delete;
                
                $c->stash->{json} = { success => \1, msg=>_loc('Categories deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Categories') };
            }
        }
    }
    
    $c->forward('View::JSON');    
}


sub list_status : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my $row;
    my @rows;
    $row = $c->model('Baseliner::BaliTopicStatus')->search(undef, { order_by=>{ -asc => ['seq' ] } });
    
    if($row){
        while( my $r = $row->next ) {
             
            push @rows,
              {
                id          => $r->id,
                name        => $r->name,
                description => $r->description,
                bl          => $r->bl,
                seq         => $r->seq,
                type        => $r->type
              };
        }  
    }
    $cnt = $#rows + 1 ; 
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update_status : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};

    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliTopicStatus')->search({name => $p->{name}})->first;
                if(!$row){
                    my $status = $c->model('Baseliner::BaliTopicStatus')
                        ->create(
                        { name => $p->{name}, bl => $p->{bl}, description => $p->{description}, type => $p->{type}, seq => $p->{seq} } );
                    $c->stash->{json} = { msg=>_loc('Status added'), success=>\1, status_id=> $status->id };
                }
                else{
                    $c->stash->{json} = { msg=>_loc('Status name already exists, introduce another status name'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Status: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {
            try{
                my $id_status = $p->{id};
                my $status = $c->model('Baseliner::BaliTopicStatus')->find( $id_status );
                $status->name( $p->{name} );
                $status->description( $p->{description} );
                $status->bl( $p->{bl} );
                $status->type( $p->{type} );
                $status->seq( $p->{seq} );
                $status->update();
                
                $c->stash->{json} = { msg=>_loc('Status modified'), success=>\1, status_id=> $id_status };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Status: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            my $ids_status = $p->{idsstatus};
            try{
                my @ids_status;
                foreach my $id_status (_array $ids_status){
                    push @ids_status, $id_status;
                }
                  
                my $rs = Baseliner->model('Baseliner::BaliTopicStatus')->search({ id => \@ids_status });
                $rs->delete;
                
                $c->stash->{json} = { success => \1, msg=>_loc('Statuses deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Statuses') };
            }
        }
    }
    
    $c->forward('View::JSON');    
}

sub update_priority : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my @rsptime = _array $p->{rsptime};
    my @deadline = _array $p->{deadline};
    
    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliTopicPriority')->search({name => $p->{name}})->first;
                if(!$row){
                    my $priority = $c->model('Baseliner::BaliTopicPriority')->create({
                                                                                    name => $p->{name},
                                                                                    response_time_min => $rsptime[1],
                                                                                    expr_response_time => $rsptime[0],
                                                                                    deadline_min => $deadline[1],
                                                                                    expr_deadline => $deadline[0]
                                                                                    });
                    
                    $c->stash->{json} = { msg=>_loc('Priority added'), success=>\1, status_id=> $priority->id };
                }
                else{
                    $c->stash->{json} = { msg=>_loc('Priority name already exists, introduce another priority name'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Priority: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {
            try{
                my $id_priority = $p->{id};
                my $priority = $c->model('Baseliner::BaliTopicPriority')->find( $id_priority );
                $priority->name( $p->{name} );
                $priority->response_time_min( $rsptime[1] );
                $priority->expr_response_time( $rsptime[0] );
                $priority->deadline_min( $deadline[1] );
                $priority->expr_deadline( $deadline[0] );
                $priority->update();
                
                $c->stash->{json} = { msg=>_loc('Priority modified'), success=>\1, priority_id=> $id_priority };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Priority: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            my $ids_priority = $p->{idspriority};
            try{
                my @ids_priority;
                foreach my $id_priority (_array $ids_priority){
                    push @ids_priority, $id_priority;
                }
                  
                my $rs = Baseliner->model('Baseliner::BaliTopicPriority')->search({ id => \@ids_priority });
                $rs->delete;
                
                $c->stash->{json} = { success => \1, msg=>_loc('Priorities deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Priorities') };
            }
        }
    }
    
    $c->forward('View::JSON');    
}

sub update_label : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    
    my $action = $p->{action};
    my $label = $p->{label};
    my $color = $p->{color};
    
    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliLabel')->search({name => $p->{label}})->first;
                if(!$row){
                    my $label = $c->model('Baseliner::BaliLabel')->create({name => $label, color => $color});
                    $c->stash->{json} = { msg=>_loc('Label added'), success=>\1, label_id=> $label->id };
                }
                else{
                    $c->stash->{json} = { msg=>_loc('Label name already exists, introduce another label name'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Label: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {  }
        when ('delete') {
            my $ids_label = $p->{idslabel};

            try{
                my @ids_label;
                foreach my $id_label (_array $ids_label){
                    push @ids_label, $id_label;
                }
                  
                my $rs = Baseliner->model('Baseliner::BaliLabel')->search({ id => \@ids_label });
                $rs->delete;
                
                $rs = Baseliner->model('Baseliner::BaliTopicLabel')->search({ id_label => \@ids_label });
                $rs->delete;                
                
                $c->stash->{json} = { success => \1, msg=>_loc('Labels deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Labels') };
            }
        }
    }
    
    $c->forward('View::JSON');    
}

sub update_category_admin : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $idcategory = $p->{id};
    my $idsroles = $p->{idsroles};
    my $status_from = $p->{status_from};
    my $idsstatus_to = $p->{idsstatus_to};
    my $job_type = $p->{job_type};

    foreach my $role (_array $idsroles){
        my $rs = $c->model('Baseliner::BaliTopicCategoriesAdmin')
            ->search( { id_category => $idcategory, id_role => $role, id_status_from => $status_from, id_status_to=>$idsstatus_to} );
        if($rs->first){
            $rs->delete;
            if($idsstatus_to){
                foreach my $idstatus_to (_array $idsstatus_to){
                    my $category = $c->model('Baseliner::BaliTopicCategoriesAdmin')->create({
                                                                                            id_category => $idcategory,
                                                                                            id_role      => $role,
                                                                                            id_status_from  => $status_from,
                                                                                            job_type  => $job_type,
                                                                                            id_status_to => $idstatus_to
                    });
        
                }
            }

        }
        else{
            if($idsstatus_to){
                foreach my $idstatus_to (_array $idsstatus_to){
                    my $category = $c->model('Baseliner::BaliTopicCategoriesAdmin')->create({
                                                                                            id_category => $idcategory,
                                                                                            id_role      => $role,
                                                                                            id_status_from  => $status_from,
                                                                                            job_type  => $job_type,
                                                                                            id_status_to => $idstatus_to
                    });
        
                }
            }
        }        
    }
    $c->stash->{json} = { success => \1, msg=>_loc('Categories admin') };
    $c->forward('View::JSON');    
}

sub list_categories_admin : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my @rows;

    my $rows = $c->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        { id_category => $p->{categoryId} },
        {   
            select   => [qw/id_role id_status_from /],
            group_by => [qw/id_role id_status_from /],
            distinct => 1,
            join     => ['statuses_from'],
            orderby  => { -asc => [ 'id_role', 'id_status_from', 'statuses_from.seq' ] }
        }
    );
                                                                        
    if($rows){
        while( my $rec = $rows->next ) {
            
            my @statuses_to;
            my $statuses_to = $c->model('Baseliner::BaliTopicCategoriesAdmin')->search(
                {   id_category    => $p->{categoryId},
                    id_role        => $rec->id_role,
                    id_status_from => $rec->id_status_from,
                },
                {
                    join=>['statuses_from'],
                    distinct=>1,
                    order_by => { -asc => ['statuses_from.seq'] },
                }
            );
            
            # Grid for workflow configuration: right side field
            while( my $status_to = $statuses_to->next ) {
                my $name = $status_to->statuses_to->name;
                # show 
                my $job_type = $status_to->job_type;
                if( $job_type && $job_type ne 'none' ) {
                    $name = sprintf '%s [%s]', $name, lc( _loc($job_type) );
                }
                push @statuses_to,  $name;
            }
           _log _dump \@statuses_to; 
            push @rows, {
                         role      => $rec->roles->name,
                         status_from    => $rec->statuses_from->name,
                         statuses_to    => \@statuses_to
                     };             

        }
    }
    $cnt = $#rows + 1 ;
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub list_fields : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my @field_dirs;
    push @field_dirs, $c->path_to( 'root/fields' ) . "";
    @field_dirs = grep { -d } @field_dirs;
    
    my @fieldlets = map {
        my @ret;
        #for my $f ( grep { -f } _dir( $_ . '/*.html')->children ) {
        for my $f ( map { _file($_) } grep { -f } glob "$_/*.js" ) { 
            my $d = $f->slurp;
            my ( $yaml ) = $d =~ /^\/\*(.*)\n---.?\n(.*)$/gs;
           
            my $metadata;
            if(length $yaml ) {
                $metadata =  _load( $yaml );    
            } else {
                $metadata = {};
            }
            my @rows = map {
                +{  field=>$_, value => $metadata->{$_} } 
            } keys %{ $metadata || {} };
            
            push @ret, {
                file => "$f",
                yaml => $yaml,
                metadata => $metadata,
                rows => \@rows,
            };
        }
       @ret;
    } @field_dirs;
    
    
    my @rows;
    my $i = 1;
    for my $field ( sort { $a->{metadata}->{params}->{field_order} <=> $b->{metadata}->{params}->{field_order} } @fieldlets ) {
        if( $field->{metadata}->{name} ){
            $field->{metadata}->{params}->{name_field} = $field->{metadata}->{name};
            push @rows,
                {
                  #id		=> $field->{metadata}->{name} . '#' . $field->{metadata}->{path} ,
                  id        => $field->{metadata}->{name},
                  params	=> $field->{metadata}->{params},
                  #order     => $field->{metadata}->{order},
                  #value     => $field->{metadata}->{value},
                };		
        }
    }
    my @id_fields = map { $_->{metadata}->{name} } @fieldlets;
    my @custom_fields = $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_field => { 'not in' => \@id_fields}})->hashref->all;
    for(@custom_fields){
    	my $params = _load  $_->{params_field};
        $params->{name_field} = $_->{id_field};
        push @rows,
            {
              id        => $_->{id_field},
              params	=> $params,
            };        
    }
    
    
    
    $c->stash->{json} = {data=>\@rows};
    $c->forward('View::JSON');
}

sub list_forms : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @rows;

    my $dir = _dir( $c->path_to('root/forms') );
    if( $dir ) {
        for my $f ( $dir->children ) {
            my $name = $f->basename;
            ($name) = $name =~ m{^(.*)(\..*?)$};
            push @rows, {
                form_name => $name,
                form_path => "$f",
            };
        }
    }
    
    $c->stash->{json} = { data=>\@rows, totalCount=>scalar(@rows)};
    $c->forward('View::JSON');
}

sub update_fields : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_category = $p->{id};
    my @ids_field = _array $p->{fields};
    my @values_field = _array $p->{values};

    my $category = $c->model('Baseliner::BaliTopicFieldsCategory')->search( {id_category => $id_category} );
    if($category->count > 0){
        $category->delete;
    }
    
    my $param_field;
    foreach my $field (@ids_field){
        my $params = _decode_json(shift(@values_field));

        my $fields_category = $c->model('Baseliner::BaliTopicFieldsCategory')->create({
                                                                                id_category         => $id_category,
                                                                                id_field            => $field,
                                                                                params_field          => _dump $params,
        });                                                                                
    }
    
    #my $i = 1;
    #foreach my $id_field (@ids_field){
    #    
    #    my @id_path = split /#/, $id_field;
    #    my $fields_category = $c->model('Baseliner::BaliTopicFieldsCategory')->create({
    #                                                                            id_category         => $id_category,
    #                                                                            id_field            => $id_path[0],
    #                                                                            path_field          => $id_path[1],
    #                                                                            column_json_field   => shift(@values_field),
    #                                                                            #params_field => shift(@params_field),
    #                                                                            order_field => $i++,
    #    });
    #}    
    #
    #if( $p->{forms} ) {
    #    my $forms = join ',', _array $p->{forms};
    #    my $row = $c->model('Baseliner::BaliTopicCategories')->find( $id_category );
    #    $row->update({ forms=>$forms }) if ref $row;
    #}

    $c->stash->{json} = { success => \1, msg=>_loc('fields modified') };
    $c->forward('View::JSON');    
}

sub workflow : Local {
    my ($self,$c, $action) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    if( $action eq 'delete' ) {
        try {
            my $rs = $c->model('Baseliner::BaliTopicCategoriesAdmin')->search(
                {   id_category    => $p->{id},
                    id_role        => $p->{idsroles},
                    id_status_from => $p->{status_from},
                    id_status_to   => $p->{idsstatus}
                }
            );
            $cnt = $rs->count;
            $rs->delete;
        } catch {
            $c->stash->{json} = { success => \0, msg=>_loc('Error deleting relationships: %1', shift() ) };
        };
    }
    $c->stash->{json} = { success => \1, msg=>_loc('Relationship deleted: %1', $cnt) };
    $c->forward('View::JSON');    
}

sub get_config_priority : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $priority_id = $p->{id};
    my $category_id = $p->{category_id};
    
    my @category_priority;
    
    if($p->{active}){
        @category_priority = $c->model('Baseliner::BaliTopicCategoriesPriority')->search(
                                    {id_category=> $category_id, is_active=>1},
                                    {join=>['priority'], 
                                    select=>[qw/id_category id_priority priority.name response_time_min expr_response_time deadline_min deadline_min expr_deadline is_active/], 
                                    as=>[qw/id_category id name response_time_min expr_response_time deadline_min deadline_min expr_deadline is_active/]})->hashref->all;
    }else{
        if($category_id){
            @category_priority = $c->model('Baseliner::BaliTopicCategoriesPriority')->search(
                                        {id_category=> $category_id, id_priority=> $priority_id},
                                        {join=>['priority'], 
                                        select=>[qw/id_category id_priority priority.name response_time_min expr_response_time deadline_min deadline_min expr_deadline is_active/], 
                                        as=>[qw/id_category id name response_time_min expr_response_time deadline_min deadline_min expr_deadline is_active/]})->hashref->all;
            if(!@category_priority){
                my @priority_default = $c->model('Baseliner::BaliTopicPriority')->search({id=> $priority_id})->hashref->all;
                foreach my $field (@priority_default){
                    push @category_priority, { name => $field->{name},
                                      id_category => $category_id,
                                      id => $field->{id},
                                      response_time_min => $field->{response_time_min},
                                      expr_response_time => $field->{expr_response_time},
                                      deadline_min => $field->{deadline_min},
                                      expr_deadline => $field->{expr_deadline},
                                      is_active => 0,
                                      }
                }
            }
        }
    }
    $c->stash->{json} = { data=>\@category_priority};
    $c->forward('View::JSON');    
}

sub update_category_priority : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my @rsptime = _array $p->{rsptime};
    my @deadline = _array $p->{deadline};
    my $priority_id = $p->{id};
    my $category_id = $p->{id_category};    
    
    given ($action) {
        when ('add') {

        }
        when ('update') {
            try{
                my $category_priority = $c->model('Baseliner::BaliTopicCategoriesPriority')->search({id_category=> $category_id, id_priority=> $priority_id})->first;
                if($category_priority){
                    $category_priority->delete();
                }
                my $priority = $c->model('Baseliner::BaliTopicCategoriesPriority')->create({
                                                                                id_category => $category_id,
                                                                                id_priority => $priority_id,
                                                                                response_time_min => $rsptime[1],
                                                                                expr_response_time => $rsptime[0],
                                                                                deadline_min => $deadline[1],
                                                                                expr_deadline => $deadline[0],
                                                                                is_active => $p->{priority_active_check} ? 1:0,
                                                                                });
                    
                $c->stash->{json} = { msg=>_loc('Priority added'), success=>\1 };

            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Priority: %1', shift()), failure=>\1 }
            }            
        }
        when ('delete') {
        }
    }
    
    $c->forward('View::JSON');    
}

sub get_config_field : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @rows;
    
    #if($p->{config}){
    #    try{
    #        my $default_config = $c->model('Registry')->get( 'config.field.' . $p->{config} )->metadata;
    #        my %dashlet_config;
    #        my %key_description;
    #        foreach my $field (_array $default_config){
    #            $dashlet_config{$field->{id}} = $field->{default};
    #            $key_description{$field->{id}} = $field->{label};
    #        }		
    #        
    #        foreach my $key (keys %dashlet_config){
    #            push @rows,
    #                {
    #                    id 			=> $key,
    #                    description	=> $key_description{$key},
    #                    value 		=> $dashlet_config{$key}
    #                };		
    #        }
    #    }
    #    catch{
    #        $c->stash->{json} = { data => undef};  
    #    };
    #}
    
    if($p->{config}){
        try{
            my @settings = $c->model('Registry')->get('config.field.general')->metadata;
            #my @settings = $c->model('Registry')->get( 'config.field.' . $p->{config} )->metadata;
            $c->stash-> {json} = {data => @settings};
        }
        catch{
            $c->stash-> {json} = {data => undef};  
        };
    }    
    $c->forward('View::JSON');    
}

sub create_clone : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    
    try{
        #my $row = $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $p->{id_category}})->first;
        my $row = $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_field => $p->{name_field}})->first;
        if(!$row){
            my $params = _decode_json($p->{params});
            
            $params->{origin} = 'custom';
            $params->{id_field} = $p->{name_field};
            $params->{name_field} = $p->{name_field};
            #$params->{field_order} += 20;

            $params->{rel_field} = $p->{name_field} if exists $params->{rel_field};
            if (exists $params->{filter}) {
                $params->{filter} = $p->{filter};
                $params->{html} = '';  
            }else{
                $params->{html} = '/fields/field_generic.html';                
            }
            
            
    
            my $clone_field = $c->model('Baseliner::BaliTopicFieldsCategory')->create({
                                                                                    id_category    => $p->{id_category},
                                                                                    id_field       => $p->{name_field},
                                                                                    params_field   => _dump $params,
            });            
    
            $c->stash->{json} = { msg=>_loc('Field cloned'), success=>\1 };
        }
        else{
            $c->stash->{json} = { msg=>_loc('Field name already exists, introduce another name'), failure=>\1 };
        }
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error cloning field: %1', shift()), failure=>\1 };
    };

    $c->forward('View::JSON');    
}

sub list_clone_fields : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my @field_dirs;
    push @field_dirs, $c->path_to( 'root/fields' ) . "";
    @field_dirs = grep { -d } @field_dirs;
    
    my @fieldlets = map {
        my @ret;
        #for my $f ( grep { -f } _dir( $_ . '/*.html')->children ) {
        for my $f ( map { _file($_) } grep { -f } glob "$_/*.js" ) { 
            my $d = $f->slurp;
            my ( $yaml ) = $d =~ /^\/\*(.*)\n---.?\n(.*)$/gs;
           
            my $metadata;
            if(length $yaml ) {
                $metadata =  _load( $yaml );    
            } else {
                $metadata = {};
            }
            my @rows = map {
                +{  field=>$_, value => $metadata->{$_} } 
            } keys %{ $metadata || {} };
            
            push @ret, {
                file => "$f",
                yaml => $yaml,
                metadata => $metadata,
                rows => \@rows,
            };
        }
       @ret;
    } @field_dirs;
    
    my @rows;
    my $i = 1;
    for my $field ( sort { $a->{metadata}->{params}->{field_order} <=> $b->{metadata}->{params}->{field_order} } grep { $_->{metadata}->{params}->{is_clone} eq 1} @fieldlets ) {
        if( $field->{metadata}->{name} ){
            $field->{metadata}->{params}->{name_field} = $field->{metadata}->{name};
            push @rows,
                {
                  #id		=> $field->{metadata}->{name} . '#' . $field->{metadata}->{path} ,
                  id        => $field->{metadata}->{name},
                  params	=> $field->{metadata}->{params},
                  name      => _loc $field->{metadata}->{name},
                  #value     => $field->{metadata}->{value},
                };		
        }
    }	    
    
    $c->stash->{json} = {data=>\@rows};
    $c->forward('View::JSON');
}

sub list_filters : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my @rows;
    my @filters = $c->model('Baseliner::BaliTopicView')->search(undef, {order_by => 'name'})->hashref->all;
    for(@filters){
        push @rows,
                {
                  name        => $_->{name},
                  filter_json	=> $_->{filter_json}
                };	
    }
    
    $c->stash->{json} = {data=>\@rows};
    $c->forward('View::JSON');
}

1;
