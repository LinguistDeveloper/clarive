package Baseliner::Controller::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  
register 'menu.tools.topic' => {
    label    => 'Topics',
    title    => _loc ('Topics'),
    action   => 'action.topics.view',
    url_comp => '/topic/grid',
    icon     => '/static/images/icons/topic.png',
    tab_icon => '/static/images/icons/topic.png'
};

register 'action.topics.view' => { name=>'View and Admin topics' };

sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $c->stash->{query_id} = $p->{query};    
    $c->stash->{template} = '/comp/topic/topic_grid.js';
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt) = ( @{$p}{qw/start limit query query_id dir sort/}, 0 );
    $sort ||= 'id';
    $dir ||= 'asc';
    $start||= 0;
    $limit ||= 100;

    my @labels = ();
    my $labels;
    my @categories = ();
    my @statuses = ();
    my @priorities = ();
    my @datas;
    
    my @projects = $c->model( 'Permissions' )->user_projects_with_action(username => $c->username,
                                                                            action => 'action.job.viewall',
                                                                            level => 1);
    
    
    @datas = Baseliner::Model::Topic->GetTopics({orderby => "$sort $dir"});
    #@datas = Baseliner::Model::Topic->GetTopics({orderby => "$sort $dir"}, \@labels, \@categories, \@projects, \@statuses, \@priorities);
    #my @datas = Baseliner::Model::Topic->GetTopics({orderby => "$sort $dir", labels => @labels});
    
    #Viene por la parte de dashboard, y realiza el filtrado por ids.
    if($query_id){ 
        @datas = grep { ($_->{id}) =~ $query_id } @datas if $query_id;
    #Comportamiento normal.
    }else{
        my @temp =();
        my %seen   = ();
        #Filtramos por el estado de las topics, abiertas 'O' o cerradas 'C'.
        #@datas = grep { uc($_->{status}) =~ $filter } @datas;
        #Filtramos por lo que han introducido en el campo de búsqueda.
        @datas = grep { lc($_->{title}) =~ $query } @datas if $query;
        
        if($p->{labels}){
            foreach my $label (_array $p->{labels}){
                push @labels, $label;
            }
            
            $labels = $c->model('Baseliner::BaliTopicLabel')->search({id_label => \@labels});
            while( my $label = $labels->next ) {
                push @temp, grep { $_->{id} =~ $label->id_topic && ! $seen{ $_->{id} }++ } @datas if $label;    
            }
            @datas = @temp;
        }
        
        @temp =();
        %seen   = ();
        
        if($p->{categories}){
            foreach my $category (_array $p->{categories}){
                #push @categories, $category;
                push @temp, grep { $_->{category} =~ $category && ! $seen{ $_->{id} }++ } @datas if $category;    
            }
            @datas = @temp;
        }
        
        @temp =();
        %seen   = ();
        
        if($p->{statuses}){
            foreach my $status (_array $p->{statuses}){
                #push @statuses, $status;
                push @temp, grep { $_->{id_category_status} =~ $status && ! $seen{ $_->{id} }++ } @datas if $status;    
            }
            @datas = @temp;
        }        

        @temp =();
        %seen   = ();
        
        if($p->{priorities}){
            foreach my $priority (_array $p->{priorities}){
                #push @priorities, $priority;
                _log ">>>>>>>>>>>>>>>>asas: " . $priority;
                push @temp, grep { $_->{id_priority} =~ $priority && ! $seen{ $_->{id} }++ } @datas if $priority;
            }
            @datas = @temp;            
        }
        
    }
    my @rows;
          
    #Creamos el json para la carga del grid de topics.


    foreach my $data (@datas){
        my @labels;
        my $topiclabels = $c->model('Baseliner::BaliTopicLabel')->search({id_topic => $data->{id}});
        while( my $topiclabel = $topiclabels->next ) {
            my $str = { label => $topiclabel->id_label,  color => $topiclabel->label->color, name => $topiclabel->label->name  };
            push @labels, $str
        }
        
        my @projects;
        my $topicprojects = $c->model('Baseliner::BaliTopicProject')->search({id_topic => $data->{id}});
        while( my $topicproject = $topicprojects->next ) {
            my $str = { project => $topicproject->project->name,  id_project => $topicproject->id_project };
            push @projects, $str
        }
        
        push @rows, {
            id      => $data->{id},
            title   => $data->{title},
            description => $data->{description},
            created_on  => $data->{created_on},
            created_by  => $data->{created_by},
            numcomment  => $data->{numcomment},
            category    => $data->{category} ? [$data->{category}] : '',
            category_color => $data->{category_color},
            namecategory    => $data->{namecategory} ? [$data->{namecategory}] : '',
            labels      => \@labels,
            projects    => \@projects,
            status      => $data->{id_category_status},
            priority    => $data->{id_priority},
            response_time_min   => $data->{response_time_min},
            expr_response_time  => $data->{expr_response_time},
            deadline_min    => $data->{deadline_min},
            expr_deadline   => $data->{expr_deadline}
        };
    }   


    $cnt = scalar @datas ;
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    $p->{username} = $c->username;
    
    try  {    
        my ($msg, $id) = Baseliner::Model::Topic->update( $p );
        $c->stash->{json} = { success => \1, msg=>_loc($msg), topic_id => $id };
    } catch {
        my $e = shift;
        $c->stash->{json} = { success => \0, msg=>_loc($e) };
    };
    $c->forward('View::JSON');
}

sub json : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $id_topic = $p->{id};
    my $topic = $c->model('Baseliner::BaliTopic')->find( $id_topic );
    my $ret = {
        title       => $topic->title,
        description => $topic->description,
        category    => $topic->categories->first->name,
        id          => $id_topic,
    };
    $c->stash->{json} = $ret;
    $c->forward('View::JSON');
}

sub view : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $id_topic = $p->{id} || $p->{action};
    
    my $topic = $c->model('Baseliner::BaliTopic')->find( $id_topic );
    $c->stash->{title} = $topic->title;
    $c->stash->{created_on} = $topic->created_on;
    $c->stash->{created_by} = $topic->created_by;
    $c->stash->{deadline} = $topic->created_on;  # TODO
    $c->stash->{status} = try { $topic->status->name } catch { _loc('unassigned') };
    $c->stash->{description} = $topic->description;
    my $category = $topic->categories->first;
    $c->stash->{category} = $category->name;
    $c->stash->{category_color} = try { $category->color} catch { '#444' };
    $c->stash->{forms} = [
        map { "/forms/$_" } split /,/,$category->forms
    ];
    $c->stash->{id} = $id_topic;
    $self->list_comments( $c );  # get comments into stash
    if( $p->{html} ) {
        $c->stash->{template} = '/comp/topic/topic_msg.html';
    } else {
        $c->stash->{template} = '/comp/topic/topic_main.js';
    }
}

sub comment : Local {
    my ($self, $c, $action) = @_;
    my $p = $c->request->parameters;
    if( $action eq 'add' ) {
        try{
            my $id_topic = $p->{id_topic};
            my $id_com = $p->{id_com};
            my $content_type = $p->{content_type};
            _throw( _loc( 'Missing id' ) ) unless defined $id_topic;
            my $text = $p->{text};
            _log $text;
            
            my $topic;
            if( ! length $id_com ) {  # optional, if exists then is not add, it's an edit
                $topic = $c->model('Baseliner::BaliPost')->create(
                    {   id_topic   => $id_topic,
                        text       => $text,
                        content_type => $content_type,
                        created_by => $c->username,
                        created_on => DateTime->now,
                    }
                );
                #$c->model('Event')->create({
                #    type => 'event.topic.new_comment',
                #    ids  => [ $id_topic ],
                #    username => $c->username,
                #    data => {
                #        text=>$p->{text}
                #    }
                #});
            } else {
                my $topic = $c->model('Baseliner::BaliPost')->find( $id_com );
                $topic->text( $text );
                $topic->content_type( $content_type );
                # TODO modified_on ?
                $topic->update;
            }
            $c->stash->{json} = {
                msg     => _loc('Comment added'),
                success => \1
            };
        }
        catch{
            $c->stash->{json} = { msg => _loc('Error adding Comment: %1', shift()), failure => \1 }
        };
    } elsif( $action eq 'delete' )  {
        try {
            my $id_com = $p->{id_com};
            _throw( _loc( 'Missing id' ) ) unless defined $id_com;
            $c->model('Baseliner::BaliPost')->find( $id_com )->delete;
            $c->stash->{json} = { msg => _loc('Delete comment ok'), failure => \0 };
        } catch {
            $c->stash->{json} = { msg => _loc('Error deleting Comment: %1', shift() ), failure => \1 }
        };
    } elsif( $action eq 'view' )  {
        try {
            my $id_com = $p->{id_com};
            my $topic = $c->model('Baseliner::BaliPost')->find($id_com);
            # check if youre the owner
            _fail _loc( "You're not the owner (%1) of the comment.", $topic->created_by ) 
                if $topic->created_by ne $c->username;
            $c->stash->{json} = {
                failure=>\0,
                text       => $topic->text,
                created_by => $topic->created_by,
                created_on => $topic->created_on->dmy . ' ' . $topic->created_on->hms
            };
        } catch {
            $c->stash->{json} = { msg => _loc('Error viewing comment: %1', shift() ), failure => \1 }
        };
    }
    $c->forward('View::JSON');
}

sub list_comments : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $id_topic = $p->{id};

    my $rs = $c->model('Baseliner::BaliPost')->search( { id_topic => $id_topic }, { order_by => 'created_on desc' } );
    my @rows;
    while( my $r = $rs->next ) {
        push @rows,
            {
            created_on   => $r->created_on,
            created_by   => $r->created_by,
            text         => $r->text,
            content_type => $r->content_type,
            id           => $r->id,
            };
    }
    $c->stash->{comments} = \@rows;
}

sub list_category : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my @rows;

    if( !$p->{categoryId} ){    
        my $row = $c->model('Baseliner::BaliTopicCategories')->search();
        
        if($row){
            while( my $r = $row->next ) {
                my @statuses;
                my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $r->id});
                while( my $status = $statuses->next ) {
                    push @statuses, $status->id_status;
                }
                
                push @rows,
                  {
                    id          => $r->id,
                    name        => $r->name,
                    description => $r->description,
                    statuses    => \@statuses
                  };
            }  
        }
        $cnt = $#rows + 1 ; 
    }else{
        my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $p->{categoryId}});
        if($statuses){
            while( my $status = $statuses->next ) {
                push @rows, {
                                id      => $status->status->id,
                                name    => $status->status->name
                            };
            }
        }
        $cnt = $#rows + 1 ;
    }
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update_category : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my $idsstatus = $p->{idsstatus};

    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliTopicCategories')->search({name => $p->{name}})->first;
                if(!$row){
                    my $category = $c->model('Baseliner::BaliTopicCategories')->create({name  => $p->{name}, description=> $p->{description}});
                    
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
                $category->description( $p->{description} );
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
    $row = $c->model('Baseliner::BaliTopicStatus')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @rows,
              {
                id          => $r->id,
                name        => $r->name,
                description => $r->description,
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
                    my $status = $c->model('Baseliner::BaliTopicStatus')->create({name  => $p->{name}, description=> $p->{description}});
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

sub list_priority : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my $row;
    my @rows;
    $row = $c->model('Baseliner::BaliTopicPriority')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @rows,
              {
                id          => $r->id,
                name        => $r->name,
                response_time_min   => $r->response_time_min,
                expr_response_time => $r->expr_response_time,
                deadline_min => $r->deadline_min,
                expr_deadline => $r->expr_deadline
              };
        }  
    }
    $cnt = $#rows + 1 ; 
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
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
        when ('update') {
            #try{

            #}
            #catch{

            #}
        }
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

sub list_label : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my $row;
    my @rows;
    $row = $c->model('Baseliner::BaliLabel')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @rows,
              {
                id          => $r->id,
                name        => $r->name,
                color       => $r->color
              };
        }  
    }
    $cnt = $#rows + 1 ; 
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update_topiclabels : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $idtopic = $p->{idtopic};
    my $idslabel = $p->{idslabel};
    my $topiclabels;
    
    try{
        my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
        my $dbh = $db->dbh;
        my $sth = $dbh->prepare('DELETE FROM BALI_TOPIC_LABEL WHERE ID_TOPIC = ?');
        $sth->bind_param( 1, $idtopic );
        $sth->execute();        
        
        foreach my $id_label (_array $idslabel){
            $topiclabels = $c->model('Baseliner::BaliTopicLabel')->create(
                                                                            {
                                                                                id_topic    => $idtopic,
                                                                                id_label    => $id_label,
                                                                            });     
        }
        $c->stash->{json} = { msg=>_loc('Labels assigned'), success=>\1 };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error assigning Labels: %1', shift()), failure=>\1 }
    };
     
    $c->forward('View::JSON');    
}

sub update_project : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_topic = $p->{id_topic};
    my $id_project = $p->{id_project};

    try{
        my $project = $c->model('Baseliner::BaliTopicProject')->create({id_topic => $id_topic, id_project => $id_project});
        $c->stash->{json} = { msg=>_loc('Project added'), success=>\1 };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error adding project: %1', shift()), failure=>\1 }
    };
     
    $c->forward('View::JSON');    
}

sub unassign_projects : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $idtopic = $p->{idtopic};
    my $idsproject = $p->{idsproject};
    my $topicprojects;
    
    try{
        my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
        my $dbh = $db->dbh;
        my $sth = $dbh->prepare('DELETE FROM BALI_TOPIC_PROJECT WHERE ID_TOPIC = ?');
        $sth->bind_param( 1, $idtopic );
        $sth->execute();        
        
        foreach my $id_project (_array $idsproject){
            $topicprojects = $c->model('Baseliner::BaliTopicProject')->create(
                                                                            {
                                                                                id_topic    => $idtopic,
                                                                                id_project  => $id_project
                                                                            });     
        }
        $c->stash->{json} = { msg=>_loc('Projects unassigned'), success=>\1 };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error unassigning Projects: %1', shift()), failure=>\1 }
    };
     
    $c->forward('View::JSON');    
}

sub filters_list : Local {
    my ($self,$c) = @_;
    my $id = $c->req->params->{node};
    #my $project = $c->req->params->{project} ;
    #my $id_project = $c->req->params->{id_project} ;
    #my $parent_checked = $c->req->params->{parent_checked} || 0 ;
    
    
    
    my @tree;
    my @labels; 
    my $row;
    $row = $c->model('Baseliner::BaliLabel')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @labels, {
                id      => $r->id,
                text    => $r->name,
                cls     => 'forum',
                iconCls => 'icon-forum',
                checked => \0,
                leaf    => 'true'
            };	
        }  
    }
    
    push @tree, {
        id          => 'L',
        text        => 'labels',
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        children    => \@labels
    };
    
    my @statuses;
    $row = $c->model('Baseliner::BaliTopicStatus')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @statuses,
                {
                    id      => $r->id,
                    text    => $r->name,
                    cls     => 'forum',
                    iconCls => 'icon-forum',
                    checked => \0,
                    leaf    => 'true'
                };
        }  
    }
    
    push @tree, {
        id          => 'S',
        text        => 'statuses',
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        expanded    => 'true',
        children    => \@statuses
    };
    
    
    my @categories;
    my $row = $c->model('Baseliner::BaliTopicCategories')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @categories,
                {
                    id      => $r->id,
                    text    => $r->name,
                    cls     => 'forum',
                    iconCls => 'icon-forum',
                    checked => \0,
                    leaf    => 'true'
                };
        }  
    }

    push @tree, {
        id          => 'C',
        text        => 'categories',
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        expanded    => 'true',
        children    => \@categories
    };
        
    
    my @priorities;
    $row = $c->model('Baseliner::BaliTopicPriority')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @priorities,
            {
                id      => $r->id,
                text    => $r->name,
                cls     => 'forum',
                iconCls => 'icon-forum',
                checked => \0,
                leaf    => 'true'
            };
        }  
    }       
       
    push @tree, {
        id          => 'P',
        text        => 'priorities',
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        expanded    => 'true',
        children    => \@priorities
    };
       
        
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub view_filter : Local {
    my ($self,$c, $action) = @_;
    my $name = $c->req->params->{name};
    my $filter = $c->req->params->{filter};
    try {
        if( $action eq 'new' ) {
        }
        $c->stash->{json} = { success=>\1, msg=>_loc("Created view %1", $name) };
    } catch {
        $c->stash->{json} = { success=>\0, msg=>_loc("Error view %1", shift() ) };
    };
    $c->forward('View::JSON');

}

1;
