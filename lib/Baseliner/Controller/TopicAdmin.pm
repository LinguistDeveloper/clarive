package Baseliner::Controller::TopicAdmin;
use Baseliner::PlugMouse;
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


sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $c->stash->{query_id} = $p->{query};
    $c->stash->{can_admin_labels} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.labels.admin' );    
    $c->stash->{template} = '/comp/topic/topic_admin.js';
}

sub update_category : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my $idsstatus = $p->{idsstatus};
    my $type = $p->{type};
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
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
                
                my $rs = Baseliner->model('Baseliner::BaliTopicCategoriesStatus')->search({ id_category => $id_category, id_status => { 'not in' => $idsstatus} });
                $rs->delete;
                if($idsstatus){
                    foreach my $id_status (_array $idsstatus){
                        $rs = $c->model('Baseliner::BaliTopicCategoriesStatus')->update_or_create(
                                                                                        {
                                                                                            id_category    =>  $category->id,
                                                                                            id_status   => $id_status,
                                                                                        });     
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
    my ($dir, $sort, $cnt) = ( @{$p}{qw/dir sort/}, 0 );
    $dir ||= 'asc';
    $sort ||= 'seq';

    my $row;
    my @rows;
    $row = $c->model('Baseliner::BaliTopicStatus')->search(undef, { order_by => { "-$dir" => ["$sort" ] }});
    
    if($row){
        while( my $r = $row->next ) {
             
            push @rows,
              {
                id          => $r->id,
                name        => $r->name,
                description => $r->description,
                bl          => $r->bl,
                seq         => $r->seq,
                type        => $r->type,
                frozen      => $r->frozen eq '1'?\1:\0,
                readonly    => $r->readonly eq '1'?\1:\0,
                ci_update   => $r->ci_update eq '1'?\1:\0,
                bind_releases => $r->bind_releases eq '1'?\1:\0,
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

    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliTopicStatus')->search({name => $p->{name}})->first;
                if(!$row){
                    my $status = $c->model('Baseliner::BaliTopicStatus')
                        ->create(
                        {
                            name          => $p->{name},
                            bind_releases => ($p->{bind_releases} eq 'on' ? '1' : '0'),
                            ci_update     => ($p->{ci_update} eq 'on' ? '1' : '0'),
                            readonly      => ($p->{readonly} eq 'on' ? '1' : '0'),
                            frozen        => ($p->{frozen} eq 'on' ? '1' : '0'),
                            bl            => $p->{bl},
                            description   => $p->{description},
                            type          => $p->{type},
                            seq           => $p->{seq}
                        } );
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
                $status->bind_releases($p->{bind_releases} eq 'on'?'1':'0');
                $status->ci_update($p->{ci_update} eq 'on'?'1':'0');
                $status->readonly($p->{readonly} eq 'on'?'1':'0');
                $status->frozen($p->{frozen} eq 'on'?'1':'0');
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
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Statuses: %1', shift()) };
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
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
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
                    
                    $c->stash->{json} = { msg => _loc('Priority added'), success => \1, priority_id => $priority->id };
                }
                else{
                    $c->stash->{json} = { msg => _loc('Priority name already exists, introduce another priority name'), failure => \1 };
                }
            }
            catch{
                $c->stash->{json} = { msg => _loc('Error adding Priority: %1', shift()), failure => \1 }
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
    my @projects = split ",", $p->{projects};
    my $username = $c->username;
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliLabel')->search({name => $p->{label}})->first;
                if(!$row){
                    my $rslabel;
                    my $label = { name => $label, color => $color};
                    #if (!@projects){
                    #    if ($username eq 'root'){
                            $label->{sw_allprojects} = 1;
                    #    }else{
                    #        my $rs_user = $c->model('Baseliner::BaliUser')->search({username => $username}, {select => 'mid'})->hashref->first;
                    #        $label->{mid_user} = $rs_user->{mid};
                    #    }
                        $rslabel = $c->model('Baseliner::BaliLabel')->create($label);
                        
                    #}else{
                    #    if ($projects[0] eq 'todos'){
                    #        $label->{sw_allprojects} = 1;
                    #    }
                    #    $rslabel = $c->model('Baseliner::BaliLabel')->create($label);
                    #    foreach my $project (@projects){
                    #        next if $project eq 'todos';
                    #        $c->model('Baseliner::BaliLabelProject')->create({id_label => $rslabel->id, mid_project => $project});
                    #    }                        
                    #}
                    $c->stash->{json} = { msg=>_loc('Label added'), success=>\1, label_id=> $rslabel->id };
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
                
                $rs = Baseliner->model('Baseliner::BaliLabelProject')->search({ id_label => \@ids_label });
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
    my $mod = $c->model('Baseliner::BaliTopicCategoriesAdmin');

    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    foreach my $role (_array $idsroles){
        my $rs = $mod->search({ 
            id_category => $idcategory, id_role => $role, id_status_from => $status_from, id_status_to=>$idsstatus_to
        });
        if($rs->first){
            $rs->delete;
            if($idsstatus_to){
                foreach my $idstatus_to (_array $idsstatus_to){
                    my $category = $mod->update_or_create({
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
                    my $category = $mod->update_or_create({
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

    Baseliner->cache_remove_like( qr/^topic:/ );
    my $rows = $c->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        { id_category => $p->{categoryId} },
        {   
            select   => [qw/id_role id_status_from statuses_from.name/],
            group_by => [qw/id_role id_status_from statuses_from.name/],
            distinct => 1,
            join     => ['statuses_from','roles'],
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
                    #distinct=>1,
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
                         role           => $rec->roles->name,
                         status_from    => $rec->statuses_from->name,
                         id_category    => $p->{categoryId},
                         id_role        =>  $rec->id_role,
                         id_status_from => $rec->id_status_from,                         
                         statuses_to    => \@statuses_to
                     };             
        }
    }
    $cnt = $#rows + 1 ;
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub list_tree_fields : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id_category = $p->{id_category};
    my @tree_fields;
    my @system;
    my $system_fields = Baseliner::Model::Topic->get_system_fields();
    
    my @temp_fields =  $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $id_category})->hashref->all;
    my %conf_fields;
    
    for(@temp_fields){
        my $params = _load $_->{params_field};
        $conf_fields{$_->{id_field}} = 1 if ! exists ($params->{hidden});
    }

    my $i = (scalar keys %conf_fields) + 1;
    for ( sort { $a->{params}->{field_order} <=> $b->{params}->{field_order} } grep { $_->{params}->{origin} eq 'system' && !exists $conf_fields{$_->{id_field}} } _array $system_fields){
        push @system,   {
                            id          => $i++,
                            id_field    => $_->{id_field},
                            text        => _loc ($_->{params}->{name_field}),
                            params	    => $_->{params},
                            icon        => '/static/images/icons/lock_small.png',
                            leaf        => \1
                        }
    }
    
    push @tree_fields, {
        id          => 'S',
        text        => _loc('System fields'),
        expanded    => scalar @system gt 0 ? \1 : \0, 
        children    => \@system
    };       
    
    my @custom;
    my @id_fields = map { $_->{id_field} } _array $system_fields;
    my @custom_fields = grep {!exists $conf_fields{$_->{id_field}} } $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_field => { 'not in' => \@id_fields}})->hashref->all;
    my %unique_fields;
    for(@custom_fields){
        if (exists $unique_fields{$_->{id_field}}){
            next;
        }
        else {
            my $params = _load  $_->{params_field};
            $params->{name_field} = $_->{id_field};
            push @custom,
                {
                  id        => $i++,
                  id_field  => $_->{id_field},
                  text      => $params->{name_field},
                  params	=> $params,
                  icon    => '/static/images/icons/icon_wand.gif',
                  leaf      => \1
                };        
            $unique_fields{$_->{id_field}} = '1';    
        }
    }
    
    push @tree_fields, {
        id          => 'C',
        text        => _loc('Custom fields'),
        expanded    => scalar @custom gt 0 ? \1 : \0,        
        children    => \@custom
    };
    

    my @template_dirs = map { $_->root . '/forms/*.js' } Baseliner->features->list;
    push @template_dirs, map { $_->root . '/fields/templates/js/*.js' } Baseliner->features->list;
    push @template_dirs, map { $_->root . '/fields/system/js/*.js' } Baseliner->features->list;
    
    push @template_dirs, $c->path_to( 'root/fields/templates/js' ) . "/*.js";
    push @template_dirs, $c->path_to( 'root/fields/system/js' ) . "/list*.js";
    push @template_dirs, $c->path_to( 'root/forms' ) . "/*.js";
    #@template_dirs = grep { -d } @template_dirs;
    
    my @tmp_templates = map {
        my $glob = $_;
        my @ret;
        for my $rel_file ( grep { -f } glob "$glob" ) { 
            my $f = _file( $rel_file );
            my $d = $f->slurp;
            my $yaml = Util->_load_yaml_from_comment( $d );
            my $id_form = $f->basename; 
            
            my $metadata;
            my $metadata_base = {
                name => $id_form, 
                params => {
                    origin => 'template',
                    js => $rel_file,
                    type => 'form',
                    #section => 'body',
                }
            };
            if(length $yaml ) {
                _debug( "OK metadata for $f" );
                $metadata = try { _load( $yaml ) } catch { 
                    _error( "KO load yaml metadata for $f" );
                    $metadata_base;
                };    
                if( ref $metadata ne 'HASH' ) {
                    _error( "KO load yaml metadata not HASH for $f" );
                    $metadata = $metadata_base;
                }
            } else {
                _error( "KO metadata for $f" );
                $metadata = $metadata_base;
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
    } @template_dirs;

    my @templates;
    for my $template (  sort { $a->{metadata}->{params}->{field_order} <=> $b->{metadata}->{params}->{field_order} }
                        grep { $_->{metadata}->{params}->{origin} eq 'template' && $_->{metadata}->{params}->{type} ne 'form'} @tmp_templates ) {
        if( $template->{metadata}->{name} ){
            $template->{metadata}->{params}->{name_field} = $template->{metadata}->{name};
            push @templates,
                {
                    id          => $i++,
                    id_field    => $template->{metadata}->{name},
                    text        => _loc ($template->{metadata}->{name}),
                    params	    => $template->{metadata}->{params},
                    leaf        => \1                  
                };		
        }
    }

    my $j = 0;
    my @meta_system_listbox;
    my @data_system_listbox;
    for my $system_listbox (  sort { $a->{metadata}->{params}->{field_order} <=> $b->{metadata}->{params}->{field_order} }
                        grep {$_->{metadata}->{params}->{type} eq 'listbox'} @tmp_templates ) {
        
        push @meta_system_listbox, [$j++, _loc $system_listbox->{metadata}->{name}];
        push @data_system_listbox, $system_listbox->{metadata}->{params};
    }
    
    push @templates,    {
                            id          => $i++,
                            id_field    => 'listbox',
                            text        => _loc ('Listbox'),
                            params	    => {origin=> 'template'},
                            meta        => \@meta_system_listbox,
                            data        => \@data_system_listbox,
                            leaf        => \1                             
                        };
    
    #push @tree_fields, {
    #    id          => 'T',
    #    text        => _loc('Templates'),
    #    children    => \@templates
    #};
    
    
    $j = 0;
    my @meta_forms;
    my @data_forms;
    for my $forms (  sort { ( $a->{metadata}{params}{field_order} // -1 ) <=> ( $b->{metadata}{params}{field_order} // -1 ) }
                        grep {$_->{metadata}->{params}->{type} eq 'form'} @tmp_templates ) {
        
        push @meta_forms, [$j++, _loc $forms->{metadata}->{name}];
        push @data_forms, $forms->{metadata}->{params};
    }
    
    push @templates,    {
                            id          => $i++,
                            id_field    => 'form',
                            text        => _loc ('Custom forms'),
                            params	    => {origin=> 'template'},
                            meta        => \@meta_forms,
                            data        => \@data_forms,
                            leaf        => \1                             
                        };
    
    push @tree_fields, {
        id          => 'T',
        text        => _loc('Templates'),
        children    => \@templates
    };      
    
    $c->stash->{json} = \@tree_fields;
    $c->forward('View::JSON');
}

sub update_fields : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_category = $p->{id_category};
    my @ids_field = _array $p->{fields};
    my @values_field = _array $p->{params};
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    my $category = $c->model('Baseliner::BaliTopicFieldsCategory')->search( {id_category => $id_category} );
    if($category->count > 0){
        $category->delete;
    }
    my $order = 1;
    my $param_field;
    my %visible_system_fields;
    
    foreach my $field (@ids_field){
        my $params = _decode_json(shift(@values_field));
        
        $visible_system_fields{$field} = 1 if $params->{origin} eq 'system';
        
        $params->{field_order} = $order++;
        $params->{id_field} = $field;
    
        my $fields_category = $c->model('Baseliner::BaliTopicFieldsCategory')->create({
                                                                                id_category         => $id_category,
                                                                                id_field            => $field,
                                                                                params_field          => _dump $params,
        });                                                                                
    }
    
    my $system_fields = Baseliner::Model::Topic->get_system_fields();
    
    for ( grep { !exists $visible_system_fields{$_->{id_field}} } _array $system_fields){
        $_->{params}->{hidden}= \1 if $_->{params}->{origin} eq 'system';
        $_->{params}->{id_field}= $_->{id_field};
        my $fields_category = $c->model('Baseliner::BaliTopicFieldsCategory')->create({
                                                                                id_category         => $id_category,
                                                                                id_field            => $_->{id_field},
                                                                                params_field          => _dump $_->{params},
        }); 
    }    
    
    $c->stash->{json} = { success => \1, msg=>_loc('fields modified') };
    $c->forward('View::JSON');    
}

sub get_conf_fields : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id_category = $p->{id_category};
    
    #Baseliner::Model::Topic->get_update_system_fields ($id_category);
    
    my @conf_fields = grep { !exists $_->{params}->{hidden} && $_->{params}->{origin} ne 'default' }
                      map { +{id_field=> $_->{id_field}, params=> _load $_->{params_field}} } $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $id_category})->hashref->all;
    my @system;
    for ( sort { $a->{params}->{field_order} <=> $b->{params}->{field_order} } @conf_fields){
        push @system,   {
                            id          => $_->{params}->{field_order},
                            id_field    => $_->{id_field},
                            name        => _loc ($_->{params}->{name_field} // $_->{id_field}),
                            params	    => $_->{params},
                            img         => $_->{params}->{origin} eq 'system' ? '/static/images/icons/lock_small.png' : '/static/images/icons/icon_wand.gif',
                            meta => {
                                bd_field    => { read_only => \0 },
                                field_order => { read_only => \0 },
                                filter      => { read_only => \0 },
                                get_method  => { read_only => \0 },
                                set_method  => { read_only => \0 },
                                html        => { read_only => \0 },
                                js          => { read_only => \0 },
                                id_field    => { read_only => \0 },
                                relation    => { read_only => \0 },
                                section     => { value     => [ 'head', 'body', 'details' ] },
                                single_mode => { value     => [ \1, \0 ] },
                                type        => { read_only => \0 },
                                origin      => { read_only => \0 }
                                },
                        }
    }

    $c->stash->{json} = { data=>\@system };
    $c->forward('View::JSON');    
}

sub workflow : Local {
    my ($self,$c, $action) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
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
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
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

sub create_clone : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        my $row = $c->model('Baseliner::BaliTopicFieldsCategory')->search({id_field => $p->{name_field}})->first;
        if(!$row){
            my $params = _decode_json($p->{params});
            
            $params->{origin} = 'custom';
            $params->{id_field} = $p->{name_field};
            $params->{name_field} = $p->{name_field};

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

sub list_filters : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my @rows;
    my @filters = $c->model('Baseliner::BaliTopicView')->search(undef, {order_by => 'name'})->hashref->all;
    for (@filters){
            push @rows, $_;
    }
    
    $c->stash->{json} = {data=>\@rows};
    $c->forward('View::JSON');
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        my $rs_category = $c->model('Baseliner::BaliTopicCategories')->find({ id => $p->{id_category} });
        if( $rs_category ){
            my $new_category;
            my %data = $rs_category->get_columns; 
            delete $data{id};
            delete $data{description};
            
            ##BaliTopicCategories
            $new_category = Baseliner->model('Baseliner::BaliTopicCategories')->create({%data});
            $new_category->name( $new_category->name . '-' . $new_category->id );
            $new_category->update();

            ##BaliTopicCategoriesStatus
            my @rs_categories_status =  $c->model('Baseliner::BaliTopicCategoriesStatus')->search({ id_category => $rs_category->id })->hashref->all;
            for (@rs_categories_status){
                $c->model('Baseliner::BaliTopicCategoriesStatus')->create(
                    {
                        id_category => $new_category->id,
                        id_status   => $_->{id_status},
                    }    
                );
            }
            ##BaliTopicCategoriesPriority
            my @rs_categories_priority =  $c->model('Baseliner::BaliTopicCategoriesPriority')->search({ id_category => $rs_category->id })->hashref->all;
            for (@rs_categories_priority){
                $_->{id_category} = $new_category->id;
                $c->model('Baseliner::BaliTopicCategoriesPriority')->create($_);
            }
            ##BaliTopicCategoriesAdmin
            my @rs_categories_admin =  $c->model('Baseliner::BaliTopicCategoriesAdmin')->search({ id_category => $rs_category->id })->hashref->all;
            for (@rs_categories_admin){
                delete $_->{id};
                $_->{id_category} = $new_category->id;
                $c->model('Baseliner::BaliTopicCategoriesAdmin')->create($_);
            }            
            ##BaliTopicFieldsCategory
            my @rs_categories_fields =  $c->model('Baseliner::BaliTopicFieldsCategory')->search({ id_category => $rs_category->id })->hashref->all;
            for (@rs_categories_fields){
                $_->{id_category} = $new_category->id;
                $c->model('Baseliner::BaliTopicFieldsCategory')->create($_);
            }            
        }
        $c->stash->{json} = { success => \1, msg => _loc("Category duplicated") };  
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error duplicating category') };
    };

    $c->forward('View::JSON');  
}

sub delete_row : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_category = $p->{id_category};
    my $id_role = $p->{id_role};
    my $id_status_from = $p->{id_status_from};    
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        my $category_admin = $c->model('Baseliner::BaliTopicCategoriesAdmin')->search({id_category => $id_category, id_role => $id_role, id_status_from => $id_status_from});
        $category_admin->delete();
        $c->stash->{json} = { msg=>_loc('Row deleted'), success=>\1 };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error deleting row: %1', shift()), failure=>\1 }
    };
    
    $c->forward('View::JSON');    
}

sub update_system : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        Baseliner::Model::Topic->get_update_system_fields;
        $c->stash->{json} = { success => \1, msg => _loc("System updated") };  
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error updating system') };
    };
    $c->forward('View::JSON');  
}

sub export : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try{
        $p->{id_category} or _fail( _loc('Missing parameter id') );
        my $export;
        my @cats; 
        for my $id (  _array( $p->{id_category} ) ) {
            # TODO prefetch states and workflow
            my $status = DB->BaliTopicStatus->search()->hashref->hash_unique_on('id');
            my $topic = DB->BaliTopicCategories->search({ id=> $id }, { prefetch=>['fields', 'statuses'] })->hashref->first;
            my $ss = delete $topic->{statuses};
            for my $st ( @$ss ) {
                push @{ $topic->{statuses} }, $status->{$st->{id_status} }; #{ name=>'rrr' };
            }
            _fail _loc('Category not found for id %1', $id) unless $topic;
            push @cats, $topic;
        }
        if( @cats > 1 ) {
            my $yaml = _dump( \@cats );
            utf8::decode( $yaml );
            $c->stash->{json} = { success => \1, yaml=>$yaml };  
        } else {
            my $yaml = _dump( $cats[0] );
            utf8::decode( $yaml );
            $c->stash->{json} = { success => \1, yaml=>$yaml };  
        }
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error exporting: %1', shift()) };
    };
    $c->forward('View::JSON');  
}

sub import : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my @log;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        Baseliner->model('Baseliner')->txn_do( sub {
            my $yaml = $p->{yaml} or _fail _loc('Missing parameter yaml');
            my $import = _load( $yaml );
            $import = [ $import ] unless ref $import eq 'ARRAY';
            for my $data ( _array( $import ) ) {
                next if !defined $data;
                my $is_new;
                my $topic_cat;
                delete $data->{id};
                my $fields = delete $data->{fields};
                my $statuses = delete $data->{statuses};
                push @log => "----------------| Category: $data->{name} |----------------";
                $topic_cat = DB->BaliTopicCategories->search({ name=>$data->{name} })->first;
                $is_new = !$topic_cat;
                if( $is_new ) {
                    $topic_cat = DB->BaliTopicCategories->create( $data );
                    push @log => _loc('Created category %1', $data->{name} );
                } else {
                    $topic_cat->update( $data );
                    push @log => _loc('Updated category %1', $data->{name} );
                }
               
                # fields
                for my $field ( _array( $fields ) ) {
                    next if !defined $field;
                    delete $field->{id_category};
                    my $params_field = _load( $field->{params_field} );
                    my $frow = $topic_cat->fields->search({ id_field=>$field->{id_field} })->first;
                    if( $frow ) {
                        $frow->update( $field );
                        push @log => _loc('Updated field %1 (%2)', $field->{id_field}, $params_field->{name_field} );
                    } else {
                        $topic_cat->fields->create( $field );
                        push @log => _loc('Created field %1 (%2)', $field->{id_field}, $params_field->{name_field} );
                    }
                }
                
                # statuses
                for my $status ( _array( $statuses ) ) {
                    next if !defined $status;
                    delete $status->{id};
                    my $srow = DB->BaliTopicStatus->search({ name=>$status->{name} })->first;
                    if( !$srow ) {
                        $srow = DB->BaliTopicStatus->create( $status );
                        $topic_cat->statuses->create({ id_status=>$srow->id });
                        push @log => _loc('Created status %1', $status->{name} );
                    } else { 
                        push @log => _loc('Status %1 found. Statuses are not updated by this import.', $status->{name} );
                        my $srel = $topic_cat->statuses->search({ id_status=>$srow->id })->first;
                        if( !$srel ) {
                            $topic_cat->statuses->create({ id_status=>$srow->id });
                            push @log => _loc("Status '%1' included in category", $status->{name} );
                        } else {
                            push @log => _loc("Status '%1' was already included.", $status->{name} );
                        }
                    }
                }
                # TODO workflow ? 
                push @log => $is_new 
                    ? _loc('Topic category created with id %1 and name %2:', $topic_cat->id, $topic_cat->name) 
                    : _loc('Topic category %1 updated', $topic_cat->name) ;
            }
        });   # txn_do end
        
        $c->stash->{json} = { success => \1, log=>\@log, msg=>_loc('finished') };  
    }
    catch{
        $c->stash->{json} = { success => \0, log=>\@log, msg => _loc('Error importing: %1', shift()) };
    };
    $c->forward('View::JSON');  
}

sub delete_topic_label : Local {
    my ($self,$c, $topic_mid, $label_id)=@_;
    try{
        Baseliner->cache_remove( qr/:$topic_mid:/ ) if length $topic_mid;
        
        Baseliner->model("Baseliner::BaliTopicLabel")->search( {id_topic => $topic_mid, id_label => $label_id } )->delete;
        $c->stash->{json} = { msg=>_loc('Label deleted'), success=>\1, id=> $label_id };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error deleting label: %1', shift()), failure=>\1 }
    };
    
    $c->forward('View::JSON');    
}

1;
