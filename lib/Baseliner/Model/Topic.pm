package Baseliner::Model::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use Array::Utils qw(:all);
use v5.10;

BEGIN { extends 'Catalyst::Model' }


my $post_filter = sub {
        my ($text, @vars ) = @_;
        $vars[2] =~ s{\n|\r|<(.+?)>}{ }gs;
        $vars[0] = "<b>$vars[0]</b>";  # bold username
        $vars[2] = "<quote>$vars[2]</quote>";  # quote post
        ($text,@vars);
    };
register 'event.post.create' => {
    text => '%1 posted a comment on %2: %3',
    description => 'User posted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
};

register 'event.post.delete' => {
    text => '%1 deleted a comment on %2: %3',
    description => 'User deleted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
};

register 'event.file.create' => {
    text => '%1 posted a file on %2: %3',
    description => 'User uploaded a file',
    vars => ['username', 'ts', 'filename'],
};

register 'event.file.attach' => {
    text => '%1 attached %2 on %3',
    description => 'User attached a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.file.remove' => {
    text => '%1 removed %2 on %3',
    description => 'User removed a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.file_remove' => {
    text => '%1 removed %2 on %3',
    description => 'User removed a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.create' => {
    text => '%1 created topic on %2',
    description => 'User created a topic',
    vars => ['username', 'ts'],
};

register 'event.topic.modify' => {
    text => '%1 modified topic on %2',
    description => 'User modified a topic',
    vars => ['username', 'ts'],
};


register 'event.topic.modify_field' => {
    text => '%1 modified topic %2 from %3 to %4 on %6',
    description => 'User modified a topic',
    vars => ['username', 'field', 'old_value', 'new_value', 'text_new', 'ts',],
    filter=>sub{
        my ($txt, @vars)=@_;
        my $text_new = $vars[4];
        if( $text_new ) {
            $txt = $text_new;
        }
        return ($txt, @vars);
    }      
};

#register 'event.topic.modify_field' => {
#    text => '%1 modified topic %2 to %3 on %4',
#    description => 'User modified a topic',
#    vars => ['username', 'field', 'text_new', 'ts'],
#    filter=>sub{
#        my ($txt, @vars)=@_;
#        my $text_new = $vars[2];
#        if( $text_new ) {
#            $txt = $text_new;
#        }
#        return ($txt, @vars);
#    }    
#};

register 'event.topic.change_status' => {
    text => '%1 changed topic status to %2 on %3',
    vars => ['username', 'status', 'ts'],
};

sub update {
    my ( $self, $p ) = @_;
    my $action = $p->{action};
    my $return;
    my $topic_mid;
    my $status;

    given ( $action ) {
        when ( 'add' ) {
            event_new 'event.topic.create' => { username=>$p->{username} } => sub {
                Baseliner->model('Baseliner')->txn_do(sub{
                    my $meta = $self->get_meta ($topic_mid , $p->{category});
                    my $topic = $self->save_data ($meta, undef, $p);
                    
                    $topic_mid    = $topic->mid;
                    $status = $topic->id_category_status;
                    $return = 'Topic added';
                   { mid => $topic->mid, topic => $topic->title }   # to the event
                });                   
            } 
            => sub { # catch
                _throw _loc( 'Error adding Topic: %1', shift() );
            }; # event_new
        } ## end when ( 'add' )
        when ( 'update' ) {
            event_new 'event.topic.modify' => { username=>$p->{username},  } => sub {
                Baseliner->model('Baseliner')->txn_do(sub{
                    my @field;
                    $topic_mid = $p->{topic_mid};
                    
                    my $meta = $self->get_meta ($topic_mid, $p->{category});
                    my $topic = $self->save_data ($meta, $topic_mid, $p);
                    
                    $topic_mid    = $topic->mid;
                    $status = $topic->id_category_status;
    
                    #_log ">>>>>>>>>>>>>>Datos modificados con dirty en el topico: " . _dump $topic->get_dirty_columns;                
                    #_log ">>>>>>>>>>>>>>Datos modificados en el topico: " . _dump @field;
    
                  
                    # event_new 'event.topic.modify' => {
                    #     username => $p->{username},
                    #     mid      => $topic_mid,
                    #     field  => @field ? 'topic' : '',
                        
                    # };                   
                    
                    $return = 'Topic modified';
                   { mid => $topic->mid, topic => $topic->title }   # to the event
                });
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
        } ## end when ( 'update' )
        when ( 'delete' ) {
            $topic_mid = $p->{topic_mid};
            try {
                my $row = ref $topic_mid eq 'ARRAY'
                    ? Baseliner->model( 'Baseliner::BaliTopic' )->search({ mid=>$topic_mid })
                    : Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                _fail _loc('Topic not found') unless ref $row;
                #my $row2 = Baseliner->model( 'Baseliner::BaliMaster' )->find( $row->mid );
                $row->delete;
                $topic_mid    = $topic_mid;
                
                $return = '%1 topic(s) deleted';
            } ## end try
            catch {
                _throw _loc( 'Error deleting topic: %1', shift() );
            }
        } ## end when ( 'delete' )
        when ( 'close' ) {
            try {
                my $topic_mid = $p->{topic_mid};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                $topic->status( 'C' );
                $topic->update();

                $topic_mid    = $topic->mid;
                $return = 'Topic closed'
            } ## end try
            catch {
                _throw _loc( 'Error closing Topic: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $topic_mid, $status );
} ## end sub update

sub append_category {
    my ($self, @topics ) =@_;
    return map {
        $_->{name} = $_->{categories}->{name} ? $_->{categories}->{name} . ' #' . $_->{mid}: $_->{name} . ' #' . $_->{mid} ;
        $_->{color} = $_->{categories}->{color} ? $_->{categories}->{color} : $_->{color};
        $_
    } @topics;
}

sub next_status_for_user {
    my ($self, %p ) = @_;
    my $user_roles;
    my $where = { id_category => $p{id_category} };
    $where->{id_status_from} = $p{id_status_from} if defined $p{id_status_from};
    if( $p{username} ) {
        $user_roles = Baseliner->model('Baseliner::BaliRoleUser')->search({ username => $p{username} },{ select=>'id_role' } )->as_query;
        $where->{role} = { -in => $user_roles };
    }
    my @to_status = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        $where,
        {   join     => [ 'roles', 'statuses_to' ],
            distinct => 1,
            +select => [ 'id_status_to', 'statuses_to.name', 'id_category' ],
            +as     => [ 'id_status',    'status_name',             'id_category' ]
        }
    )->hashref->all;

    return @to_status;
}

sub get_meta {
    my ($self, $topic_mid, $id_category) = @_;

    my $id_cat =  $id_category
        // DB->BaliTopic->search({ mid=>$topic_mid }, { select=>'id_category' })->as_query;
        
    my @meta = sort { $a->{field_order} <=> $b->{field_order} } map {  _load $_->{params_field} } DB->BaliTopicFieldsCategory->search({ id_category => { -in => $id_cat }  })->hashref->all;
    
    push @meta, { name_field => 'created_by', id_field => 'created_by', origin => 'default', html => '/fields/field_created_by.html', field_order => 4, section => 'body' },
                { name_field => 'created_on', id_field => 'created_on', origin => 'default', html => '/fields/field_created_on.html', field_order => 5, section => 'body' },
                { name_field => 'dates', id_field => 'dates', origin => 'rel', method => 'get_dates', html => '/fields/field_scheduling.html', field_order => 13, section => 'details' };
    
    sort { $a->{field_order} <=> $b->{field_order} } @meta;
    
    #my @meta = (
    #     { name_field => 'title', id_field => 'title', origin => 'system', html => '/fields/field_title.html', js => '/fields/field_title.js', field_order => 2, section => 'body' },
    #     { name_field => 'category', id_field => 'id_category', origin => 'system', html => '/fields/field_category.html', js => '/fields/field_category.js', field_order => 1, section => 'body' },
    #     { name_field => 'status_new', id_field => 'id_category_status', origin => 'system', html => '/fields/field_status.html', js => '/fields/field_status.js', field_order => 3, section => 'body' },
    #     { name_field => 'created_by', id_field => 'created_by', origin => 'default', html => '/fields/field_created_by.html', field_order => 4, section => 'body' },
    #     { name_field => 'created_on', id_field => 'created_on', origin => 'default', html => '/fields/field_created_on.html', field_order => 5, section => 'body' },
    #     { name_field => 'priority', id_field => 'id_priority', set_method => 'set_priority', origin => 'system', html => '/fields/field_priority.html', js => '/fields/field_priority.js', field_order => 6, section => 'body' },
    #     { name_field => 'description', id_field => 'description', origin => 'system', html => '/fields/field_description.html', js => '/fields/field_description.js', field_order => 15, section => 'body' },
    #     { name_field => 'release', id_field => 'release', origin => 'rel', set_method => 'set_release', rel_field => 'release', method => 'get_release', html => '/fields/field_release.html', js => '/fields/field_release.js', field_order => 7, section => 'body' },
    #     { name_field => 'progress', id_field => 'progress', origin => 'system', html => '/fields/field_progress.html', js => '/fields/field_progress.js', field_order => 8, section => 'body' },
    #     { name_field => 'projects', id_field => 'projects', origin => 'rel', set_method => 'set_projects', rel_field => 'projects', method => 'get_projects', html => '/fields/field_projects.html', js => '/fields/field_projects.js', field_order => 9, section => 'details' },
    #     { name_field => 'users', id_field => 'users', origin => 'rel', set_method => 'set_users', rel_field => 'users', method => 'get_users', html => '/fields/field_assign_to.html', js => '/fields/field_assign_to.js', field_order => 10, section => 'details' },
    #     { name_field => 'labels', id_field => 'labels', origin => 'rel', set_method => 'set_labels', method => 'get_labels', html => '/fields/field_labels.html', js => '/fields/field_labels.js', field_order => 11, section => 'head' },
    #     { name_field => 'revisions', id_field => 'revisions', origin => 'rel', set_method => 'set_revisions', rel_field => 'revisions', method => 'get_revisions', html => '/fields/field_revisions.html', js => '/fields/field_revisions.js', field_order => 12, section => 'details' },
    #     { name_field => 'dates', id_field => 'dates', origin => 'rel', method => 'get_dates', html => '/fields/field_scheduling.html', field_order => 13, section => 'details' },
    #     { name_field => 'topics', id_field => 'topics', origin => 'rel', set_method => 'set_topics', method => 'get_topics', html => '/fields/field_topics.html', js => '/fields/field_topics.js', field_order => 14, section => 'details' },
    #     { name_field => 'files', id_field => 'files', origin => 'rel', method => 'get_files', html => '/fields/field_files.html', js => '/fields/field_files.js', field_order => 15, section => 'details' },
    #     #{ id_field =>'comentario', origin =>'custom' },
    #     #{ id_field =>'docs', origin =>'rel', rel_type =>'topic_file' },
    #);
    return \@meta;
}

sub get_data {
    my ($self, $meta, $topic_mid) = @_;
    
    my $data;
    if ($topic_mid){
        my @std_fields = map { $_->{id_field} } grep { $_->{origin} eq 'standard' } _array( $meta  );
        my %rel_fields = map { $_->{id_field} => 1  } grep { $_->{origin} eq 'rel' } _array( $meta );
        my %method_fields = map { $_->{id_field} => $_->{method}  } grep { $_->{method} } _array( $meta );
        
        #my $rs = Baseliner->model('Baseliner::BaliTopic')->search({ mid => $topic_mid },{ select=>\@std_fields });
        my @select_fields = ('title', 'id_category', 'categories.name', 'categories.color',
                             'id_category_status', 'status.name', 'created_by', 'created_on',
                             'id_priority','priorities.name', 'deadline_min', 'description','progress');
        my @as_fields = ('title', 'id_category', 'name_category', 'color_category', 'id_category_status', 'name_status',
                         'created_by', 'created_on', 'id_priority', 'name_priority', 'deadline_min', 'description', 'progress');
        
        my $rs = Baseliner->model('Baseliner::BaliTopic')
                ->search({ mid => $topic_mid },{ join => ['categories','status','priorities'], select => \@select_fields, as => \@as_fields});
       
        
        my $row = $rs->first;
        
        
        $data = { topic_mid => $topic_mid, $row->get_columns };
        
        $data->{created_on} = $row->created_on->dmy . ' ' . $row->created_on->hms;
        #$data->{deadline} = $row->deadline_min ? $row->created_on->clone->add( minutes => $row->deadline_min ):_loc('unassigned');
        $data->{deadline} = _loc('unassigned');
        
        
        my @rels = Baseliner->model('Baseliner::BaliMasterRel')->search({ from_mid=>$topic_mid })->hashref->all;
        for my $rel ( @rels ) {
            next unless $rel->{rel_field};
            next unless exists $rel_fields{ $rel->{rel_field} };
            push @{ $data->{ $rel->{rel_field} } },  $rel->{to_mid};
        }
        
        foreach my $key  (keys %method_fields){
            $data->{ $key } =  eval( '$self->' . $method_fields{$key} . '( $topic_mid )' );
        }
        
        my @custom_fields = map { $_->{id_field} } grep { $_->{origin} eq 'custom' } _array( $meta  );
        my %custom_data = {};
        map { $custom_data{$_->{name}} = $_->{value} }  Baseliner->model('Baseliner::BaliTopicFieldsCustom')->search({topic_mid => $topic_mid})->hashref->all;
        
        for (@custom_fields){
            $data->{ $_ } = $custom_data{$_};
        }
        
    }else{
        _log ">>>>>>>>>>>>>>>topic_mid: " . $topic_mid;
    }
    return $data;
}

sub get_release {
    my ($self, $topic_mid ) = @_;
    my $release_row = Baseliner->model('Baseliner::BaliTopic')->search(
                            { is_release => 1, rel_type=>'topic_topic', to_mid=>$topic_mid },
                            { prefetch=>['categories','children','master'] }
                            )->hashref->first; 
    return  {
                color => $release_row->{categories}{color},
                title => $release_row->{title},
                mid => $release_row->{mid},
            }
}

sub get_projects {
    my ($self, $topic_mid ) = @_;
    my $topic = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid );
    my @projects = $topic->projects->search(undef,{select=>['mid','name']})->hashref->all;

    return @projects ? \@projects : [];
}

sub get_users {
    my ($self, $topic_mid ) = @_;
    my $topic = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid );
    my @users = $topic->users->search(undef,{select=>['mid','username','realname']})->hashref->all;

    return @users ? \@users : [];
}

sub get_labels {
    my ($self, $topic_mid ) = @_;
    my @labels = Baseliner->model('Baseliner::BaliTopicLabel')->search( { id_topic => $topic_mid },
                                                                        {prefetch =>['label']})->hashref->all;
    @labels = map {$_->{label}} @labels;
    return @labels ? \@labels : [];
}

sub get_revisions {
    my ($self, $topic_mid ) = @_;
    my @revisions = Baseliner->model('Baseliner::BaliMasterRel')->search( { rel_type => 'topic_revision', from_mid => $topic_mid },
        { prefetch => ['master_to'], +select => [ 'master_to.name', 'master_to.mid' ], +as => [qw/name mid/] } )
        ->hashref->all;
    return @revisions ? \@revisions : [];    
}

sub get_dates {
    my ($self, $topic_mid ) = @_;
    my @dates = Baseliner->model('Baseliner::BaliMasterCal')->search({ mid=> $topic_mid })->hashref->all;
    return @dates ?  \@dates : [];
}

sub get_topics{
    my ($self, $topic_mid) = @_;
    my $rs_rel_topic = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )->topics->search( undef, { order_by => { '-asc' => ['categories.name', 'mid'] }, prefetch=>['categories'] } );
    rs_hashref ( $rs_rel_topic );
    my @topics = $rs_rel_topic->all;
    @topics = Baseliner->model('Topic')->append_category( @topics );
    return @topics ? \@topics : [];    
}

sub get_files{
    my ($self, $topic_mid) = @_;
    my @files = map { +{ $_->get_columns } } 
        Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )->files->search( undef, { select=>[qw(filename filesize md5 versionid extension created_on created_by)],
        order_by => { '-asc' => 'created_on' } } )->all;
    return @files ? \@files : []; 
}

sub save_data {
    my ($self, $meta, $topic_mid, $data ) = @_;
   
    # $data = { title=>'xxx' , id_category=>66, docs=>"1,2,3" }
    my @std_fields = map { +{name => $_->{name_field}, column => $_->{id_field}, method => $_->{set_method}, relation => $_->{relation} }} grep { $_->{origin} eq 'system' } _array( $meta  );
    
    my %row;
    my %description;
    my %old_value;
    my %old_text;
    my %relation;
    
    for( @std_fields ) {
        if  (exists $data->{ $_ -> {name}}){
            $row{ $_->{column} } = $data->{ $_ -> {name}};
            $description{ $_->{column} } = $_ -> {name}; ##Contemplar otro parametro mas descriptivo
            $relation{ $_->{column} } = $_ -> {relation};
            if ($_->{method}){
                my $extra_fields = eval( '$self->' . $_->{method} . '( $data->{ $_ -> {name}}, $data )' );
                foreach my $column (keys $extra_fields ){
                     $row{ $column } = $extra_fields->{$column};
                }
            }
        }
    }
    
    my $topic;
    
    if (!$topic_mid){
        $topic = master_new 'topic' => $data->{title} => sub {
            $topic_mid = shift;
            #Defaults
            $row{ mid } = $topic_mid;
            $row{ created_by } = $data->{username};
            DB->BaliTopic->create( \%row );
        }        
        
    }else{
        #$topic = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
        $topic = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid, {prefetch=>['categories','status','priorities']} );
        
        for my $field (keys %row){
            $old_value{$field} = eval($topic->$field),
            $old_text{$field} = $relation{ $field } ? eval('$topic->' . $relation{ $field } . '->name') :eval($topic->$field),
        }
        
        $topic->update( \%row );
        
        for my $field (keys %row){
            next if $field eq 'response_time_min' || $field eq 'expr_response_time';
            next if $field eq 'deadline_min' || $field eq 'expr_deadline';
            
            $topic = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid, {prefetch=>['categories','status','priorities']} );
            if ($row{$field} != eval($old_value{$field})){
                
                event_new 'event.topic.modify_field' => { username   => $data->{username},
                                                    field      => _loc ($description{ $field }),
                                                    old_value  => $old_text{$field},
                                                    new_value  => $relation{ $field } ? eval('$topic->' . $relation{ $field } . '->name') :eval($topic->$field),
                                                   } => sub {
                    { mid => $topic->mid, topic => $topic->title }   # to the event
                } ## end try
                => sub {
                    _throw _loc( 'Error modifying Topic: %1', shift() );
                };
            }
        }        
    }

     
    my %rel_fields = map { $_->{id_field} => $_->{set_method} }  grep { $_->{origin} eq 'rel' } _array( $meta  );
    
    foreach my $key  (keys %rel_fields){
        if($rel_fields{$key}){
            eval( '$self->' . $rel_fields{$key} . '( $topic, $data->{$key}, $data->{username} )' );    
        }
    } 
    
    
     
    #$topic->update( \%row );
    
                 
    
    my @custom_fields = map { +{name => $_->{name_field}, column => $_->{id_field}} } grep { $_->{origin} eq 'custom' } _array( $meta  );
    
    for( @custom_fields ) {
        if  (exists $data->{ $_ -> {name}}){

            my $row = Baseliner->model('Baseliner::BaliTopicFieldsCustom')->search( {topic_mid=> $topic->mid, name => $_->{column}} )->first;
            if(!$row){
                my $field_custom = Baseliner->model('Baseliner::BaliTopicFieldsCustom')->create({
                                                                                            topic_mid  => $topic->mid,
                                                                                            name       => $_->{column},
                                                                                            value   => $data->{ $_ -> {name}},
                });            
            }
            else{
                if ($row->value != $data->{ $_ -> {name}}){
                    
                    event_new 'event.topic.modify_field' => { username   => $data->{username},
                                                        field      => _loc ($_->{column}),
                                                        old_value  => $row->value,
                                                        new_value  => $data->{ $_ -> {name}},
                                                       } => sub {
                        { mid => $topic->mid, topic => $topic->title }   # to the event
                    } ## end try
                    => sub {
                        _throw _loc( 'Error modifying Topic: %1', shift() );
                    };
                }                
                $row->value ( $data->{ $_ -> {name}} );
                $row->update;
            }
            
            
            
            
        }
    }    
    
    return $topic;
}

sub set_priority {
    my ($self, $value, $data ) = @_;
    my @rsptime = ();
    my @deadline = ();
    
    if( length $value ) {
        @rsptime = split('#', $data->{txt_rsptime_expr_min});
        @deadline = split('#', $data->{txt_deadline_expr_min});
    }
 
    return {
            response_time_min  => $rsptime[1],
            expr_response_time => $rsptime[0],
            deadline_min       => $deadline[1],
            expr_deadline      => $deadline[0]         
           } 
}

sub set_topics {
    my ($self, $rs_topic, $topics, $user ) = @_;
    my @all_topics = ();
    
    # related topics
    my @new_topics = _array( $topics ) ;
    my @old_topics = map {$_->{to_mid}} Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $rs_topic->mid, rel_type => 'topic_topic'})->hashref->all;    
    

    # check if arrays contain same members
    if ( array_diff(@new_topics, @old_topics) ) {
        if( @new_topics ) {
            @all_topics = Baseliner->model('Baseliner::BaliTopic')->search({mid =>\@new_topics});
            $rs_topic->set_topics( \@all_topics, { rel_type=>'topic_topic'});
            
            
            
            my $topics = join(',', map {$_->mid} @all_topics);
    
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached topics' ),
                                                old_value      => '',
                                                new_value  => $topics,
                                                text_new      => '%1 modified topic: %2 ( %4 ) on %6',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };        
            
        }else{
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => '',
                                                old_value      => '',
                                                new_value  => '',
                                                text_new      => '%1 deleted all attached topics',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };             
            $rs_topic->set_topics( undef, { rel_type=>'topic_topic'});
        }
    }
    
}

sub set_revisions {
    my ($self, $rs_topic, $revisions, $user ) = @_;
    
    # related topics
    my @new_revisions = _array( $revisions ) ;
    my @old_revisions = map {$_->{to_mid}} Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $rs_topic->mid, rel_type => 'topic_revision'})->hashref->all;    
   
    if ( array_diff(@new_revisions, @old_revisions) ) {
        if( @new_revisions ) {
            @new_revisions  = split /,/, $new_revisions[0] if $new_revisions[0] =~ /,/ ;
            my @rs_revs = Baseliner->model('Baseliner::BaliMaster')->search({mid =>\@new_revisions});
            $rs_topic->set_revisions( \@rs_revs, { rel_type=>'topic_revision'});
            
            my $revisions = join(',', map { Baseliner::CI->new($_->mid)->load->{name}} @rs_revs);
    
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached revisions' ),
                                                old_value      => '',
                                                new_value  => $revisions,
                                                text_new      => '%1 modified topic: %2 ( %4 ) on %6',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };             
            
        } else {
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => '',
                                                old_value      => '',
                                                new_value  => '',
                                                text_new      => '%1 deleted all revisions',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
            $rs_topic->set_revisions( undef, { rel_type=>'topic_revision'});
            #$rs_topic->revisions->delete;
        }
    }
}

sub set_release {
    my ($self, $rs_topic, $release, $user ) = @_;
    my $topic_mid = $rs_topic->mid;
    my $release_row = Baseliner->model('Baseliner::BaliTopic')->search(
                            { is_release => 1, rel_type=>'topic_topic', to_mid=> $topic_mid },
                            { join=>['categories','children','master'], select=>'mid' }
                            )->first;
    my @old_release =();
    if($release_row){
        @old_release = $release_row->mid;
        my $rs = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => {in => $release_row->mid}})->delete;
    }
        
    my @new_release = _array( $release ) ;

    # check if arrays contain same members
    if ( array_diff(@new_release, @old_release) ) {
        # release
        if( @new_release ) {
            my $row_release = Baseliner->model('Baseliner::BaliTopic')->find( $new_release[0] );
            my @topics = Baseliner->model('Baseliner::BaliTopic')->search( {mid => $topic_mid} );
            $row_release->set_topics( \@topics, { rel_type=>'topic_topic'});
            
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => '',
                                                old_value      => '',
                                                new_value  => $row_release->title,
                                                text_new      => '%1 modified topic: changed release to %4',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
            
        }else{
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => '',
                                                old_value      => $release_row->title,
                                                new_value  => '',
                                                text_new      => '%1 deleted release %3',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };  
        }
    }
}

sub set_projects {
    my ($self, $rs_topic, $projects ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my $del_projects = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $topic_mid, rel_type => 'topic_project'})->delete;
    
    # projects
    my @projects = _array( $projects );
    if (@projects){
        my $project;
        my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({mid =>\@projects});
        while($project = $rs_projects->next){
            $rs_topic->add_to_projects( $project, { rel_type=>'topic_project' } );
        }
    }    
}

sub set_users{
    my ($self, $rs_topic, $users ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my $del_users =  Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $topic_mid, rel_type => 'topic_users'})->delete;
    
    # users
    my @users = _array( $users );
    if (@users){
        my $user;
        my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({mid =>\@users});
        while($user = $rs_users->next){
            $rs_topic->add_to_users( $user, { rel_type=>'topic_users' });
        }                    
    }
}

sub set_labels{
    my ($self, $rs_topic, $labels ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    # labels
    Baseliner->model("Baseliner::BaliTopicLabel")->search( {id_topic => $topic_mid} )->delete;
    
    foreach my $label_id (_array  $labels){
        Baseliner->model('Baseliner::BaliTopicLabel')->create( {    id_topic    => $topic_mid,
                                                                    id_label    => $label_id,
                                                        });     
    }     
}


1;
