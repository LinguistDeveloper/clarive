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
                
                my $rs = Baseliner->model('Baseliner::BaliTopicLabel')->search({ id_label => \@ids_label });
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
    my $cnt;
    my @rows;

    my $rows = $c->model('Baseliner::BaliFieldsCategory')->search(undef, {orderby => ['id ASC']});

                                                                        
    if($rows){
        while( my $rec = $rows->next ) {
            push @rows, {
                         id      => $rec->id,
                         name    => $rec->name
                     };             

        }
    }
    $cnt = $#rows + 1 ;
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
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

    my $category = $c->model('Baseliner::BaliTopicFieldsCategory')->search( {id_category => $id_category} );
    if($category->count > 0){
        $category->delete;
    }
    
    foreach my $id_field (@ids_field){
        my $fields_category = $c->model('Baseliner::BaliTopicFieldsCategory')->create({
                                                                                id_category => $id_category,
                                                                                id_field    => $id_field
        });
    }    

    if( $p->{forms} ) {
        my $forms = join ',', _array $p->{forms};
        my $row = $c->model('Baseliner::BaliTopicCategories')->find( $id_category );
        $row->update({ forms=>$forms }) if ref $row;
    }

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

1;
