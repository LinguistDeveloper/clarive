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
    text => '%1 created a topic of %2 on %3',
    description => 'User created a topic',
    vars => ['username', 'category', 'ts'],
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

register 'event.topic.change_status' => {
    text => '%1 changed topic status from %2 to %3 on %4',
    vars => ['username', 'old_status', 'status', 'ts'],
};

register 'registor.action.topic_category' => {
    generator => sub {
        my %type_actions_category = (
            create => _loc('Can create topic for this category'),
            view   => _loc('Can view topic for this category'),
            edit   => _loc('Can edit topic for this category'),
        );

        my @categories =
            Baseliner->model('Baseliner::BaliTopicCategories')->search( undef, { order_by => 'name' } )->hashref->all;

        my %actions_category;
        foreach my $action ( keys %type_actions_category ) {
            foreach my $category (@categories) {
                my $id_action = 'action.topics.' . _name_to_id( $category->{name} ) . '.' . $action;
                $actions_category{$id_action} = { name => $id_action, description => $type_actions_category{$action} };
            }
        }
        return \%actions_category;
    }
};

register 'registor.action.topic_category_fields' => {
    generator => sub {
        my @categories =
            Baseliner->model('Baseliner::BaliTopicCategories')->search( undef, { order_by => 'name' } )->hashref->all;        
        
        my %actions_category_fields;
        foreach my $category (@categories){
            my $meta = Baseliner::Model::Topic->get_meta( undef, $category->{id} );    
            my @statuses = Baseliner->model('Baseliner::BaliTopicCategoriesStatus')
                ->search({id_category => $category->{id}}, {join=>'status', 'select'=>'status.name', 'as'=>'name'})->hashref->all;
            for my $field (_array $meta){
                for my $status (@statuses){
                    my $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' . _name_to_id($field->{name_field}) . '.' . _name_to_id($status->{name}) . '.write';
                    my $description = _loc('Can not edit the field') . ' ' . lc $field->{name_field} . ' ' . _loc('in the category') . ' ' . lc $category->{name} . ' ' . _loc('for the status') . ' ' . lc $status->{name};
                    
                    $actions_category_fields{$id_action} = { name => $id_action, description => $description };
                    
                    $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' . _name_to_id($field->{name_field}) . '.' . _name_to_id($status->{name}) . '.read';
                    $description = _loc('Can not view the field') . ' ' . lc $field->{name_field} . ' ' . _loc('in the category') . ' ' . lc $category->{name} . ' ' . _loc('for the status') . ' ' . lc $status->{name};
                    
                    $actions_category_fields{$id_action} = { name => $id_action, description => $description };
                }
            }
        }
        return \%actions_category_fields;    
    }
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
                   { mid => $topic->mid, topic => $topic->title, , category=> $topic->categories->name }   # to the event
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
        $where->{id_role} = { -in => $user_roles };
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

sub get_system_fields {
    my ($self);
    my $pathHTML = '/fields/system/html/';
    my $pathJS = '/fields/system/js/';
    my @system_fields = (
            { id_field => 'title', params => {name_field => 'Title', bd_field => 'title', origin => 'system', html => $pathHTML . 'field_title.html', js => '/fields/templates/js/textfield.js', field_order => 2, section => 'body' }},
            { id_field => 'category', params => {name_field => 'Category', bd_field => 'id_category', origin => 'system',  js => $pathJS . 'field_category.js', field_order => 1, section => 'body', relation => 'categories' }},
            { id_field => 'status_new', params => {name_field => 'Status', bd_field => 'id_category_status', display_field => 'name_status' , origin => 'system', html => '/fields/templates/html/row_body.html', js => $pathJS . 'field_status.js', field_order => 3, section => 'body', relation => 'status' }},
            { id_field => 'created_by', params => {name_field => 'Created By', bd_field => 'created_by', origin => 'default', html => '/fields/templates/html/row_body.html', field_order => 0, section => 'body' }},
            { id_field => 'created_on', params => {name_field => 'Created On', bd_field => 'created_on', origin => 'default', html => '/fields/templates/html/row_body.html', field_order => 0, section => 'body' }},
            { id_field => 'priority', params => {name_field => 'Priority', bd_field => 'id_priority', set_method => 'set_priority', origin => 'system', html => $pathHTML . 'field_priority.html', js => $pathJS . 'field_priority.js', field_order => 6, section => 'body', relation => 'priorities' }},
            { id_field => 'description', params => {name_field => 'Description', bd_field => 'description', origin => 'system', html => '/fields/templates/html/dbl_row_body.html', js => '/fields/templates/js/html_editor.js', field_order => 7, section => 'body' }},
            { id_field => 'progress', params => {name_field => 'Progress', bd_field => 'progress', origin => 'system', html => '/fields/templates/html/progress_bar.html', js => '/fields/templates/js/progress_bar.js', field_order => 8, section => 'body' }},
            { id_field => 'include_into', params => {name_field => 'Include into', bd_field => 'include_into', origin => 'default', html => $pathHTML . 'field_include_into.html', field_order => 0, section => 'details' }},
            #{ id_field => 'dates', params => { name_field => 'dates',  origin => 'default', relation => 'system', method => 'get_dates', html => '/fields/field_scheduling.html', field_order => 9999, section => 'details' }},
    );
    return \@system_fields
}


sub get_meta {
    my ($self, $topic_mid, $id_category) = @_;

    my $id_cat =  $id_category
        // DB->BaliTopic->search({ mid=>$topic_mid }, { select=>'id_category' })->as_query;
        
    my @meta = sort { $a->{field_order} <=> $b->{field_order} } map {  _load $_->{params_field} } DB->BaliTopicFieldsCategory->search({ id_category => { -in => $id_cat }  })->hashref->all;
    #_error \@meta;
    
    #system fields
    #push @meta,
    #            { name_field => 'created_by', id_field => 'created_by', origin => 'default', html => '/fields/field_created_by.html', field_order => 4, section => 'body' },
    #            { name_field => 'created_on', id_field => 'created_on', origin => 'default', html => '/fields/field_created_on.html', field_order => 5, section => 'body' },
    #            { name_field => 'dates', id_field => 'dates', origin => 'rel', method => 'get_dates', html => '/fields/field_scheduling.html', field_order => 13, section => 'details' };
                
    
    @meta = sort { $a->{field_order} <=> $b->{field_order} } @meta;
    
    return \@meta;
}

sub get_data {
    my ($self, $meta, $topic_mid) = @_;
    
    my $data;
    if ($topic_mid){
        
        ##************************************************************************************************************************
        ##CAMPOS DE SISTEMA ******************************************************************************************************
        ##************************************************************************************************************************
        #my @std_fields = map { $_->{id_field} } grep { $_->{origin} eq 'system' } _array( $meta  );
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
        
        ##*************************************************************************************************************************
        ###************************************************************************************************************************
        
        
        my %rel_fields = map { $_->{id_field} => 1  } grep { defined $_->{relation} && $_->{relation} eq 'system' } _array( $meta );
        my %method_fields = map { $_->{id_field} => $_->{get_method}  } grep { $_->{get_method} } _array( $meta );

        my @rels = Baseliner->model('Baseliner::BaliMasterRel')->search({ from_mid=>$topic_mid })->hashref->all;
        for my $rel ( @rels ) {
            next unless $rel->{rel_field};
            next unless exists $rel_fields{ $rel->{rel_field} };
            push @{ $data->{ $rel->{rel_field} } },  $rel->{to_mid};
        }
        
        foreach my $key  (keys %method_fields){
            my $method = $method_fields{ $key };
            $data->{ $key } =  $self->$method( $topic_mid, $key );
        }
        
        my @custom_fields = map { $_->{id_field} } grep { $_->{origin} eq 'custom' && !$_->{relation} } _array( $meta  );
        my %custom_data = {};
        map { $custom_data{$_->{name}} = $_->{value} ? $_->{value} : $_->{value_clob} }  Baseliner->model('Baseliner::BaliTopicFieldsCustom')->search({topic_mid => $topic_mid})->hashref->all;
        
        for (@custom_fields){
            $data->{ $_ } = $custom_data{$_};
        }
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
    my ($self, $topic_mid, $id_field) = @_;
    my $rs_rel_topic = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )->topics->search( {rel_field => $id_field}, { order_by => { '-asc' => ['categories.name', 'mid'] }, prefetch=>['categories'] } );
    rs_hashref ( $rs_rel_topic );
    my @topics = $rs_rel_topic->all;
    @topics = Baseliner->model('Topic')->append_category( @topics );
    return @topics ? \@topics : [];    
}

sub get_files{
    my ($self, $topic_mid, $id_field) = @_;
    my @files = map { +{ $_->get_columns } } 
        Baseliner->model('Baseliner::BaliTopic')
            ->find( $topic_mid )
            ->files
            ->search( { rel_field=>$id_field }, { select=>[qw(filename filesize md5 versionid extension created_on created_by)],
        order_by => { '-asc' => 'created_on' } } )->all;
    return @files ? \@files : []; 
}

sub save_data {
    my ($self, $meta, $topic_mid, $data ) = @_;

    my @std_fields = map { +{name => $_->{id_field}, column => $_->{bd_field}, method => $_->{set_method}, relation => $_->{relation} }} grep { $_->{origin} eq 'system' } _array( $meta  );
    
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
                if($field eq 'id_category_status'){
                    my @projects = $topic->projects->hashref->all;
                    event_new 'event.topic.change_status' => { username => $data->{username}, old_status => $old_text{$field}, status => eval('$topic->' . $relation{ $field } . '->name')  } => sub {
                        { mid => $topic->mid, topic => $topic->title } 
                    } 
                    => sub {
                        _throw _loc( 'Error modifying Topic: %1', shift() );
                    };                    
                }else {
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
    }

     
    my %rel_fields = map { $_->{id_field} => $_->{set_method} }  grep { $_->{relation} eq 'system' } _array( $meta  );
    
    foreach my $key  (keys %rel_fields){
        if($rel_fields{$key}){
            eval( '$self->' . $rel_fields{$key} . '( $topic, $data->{$key}, $data->{username}, $key )' );    
        }
    } 
     
    my @custom_fields = map { +{name => $_->{name_field}, column => $_->{id_field}, data => $_->{data} } } grep { $_->{origin} eq 'custom' && !$_->{relation} } _array( $meta  );
    
    for( @custom_fields ) {
        if  (exists $data->{ $_ -> {name}}){

            my $row = Baseliner->model('Baseliner::BaliTopicFieldsCustom')->search( {topic_mid=> $topic->mid, name => $_->{column}} )->first;
            my $record = {};
            $record->{topic_mid} = $topic->mid;
            $record->{name} = $_->{column};
            if ($_->{data}){ ##Cuando el tipo de dato es CLOB
            	$record->{value_clob} = $data->{ $_ -> {name}};
            }else{
            	$record->{value} = $data->{ $_ -> {name}};
            }
            
            if(!$row){
                my $field_custom = Baseliner->model('Baseliner::BaliTopicFieldsCustom')->create($record);                 
            }
            else{
                my $modified = 0;
                
                if ($_->{data}){ ##Cuando el tipo de dato es CLOB
                    $row->value_clob ( $data->{ $_ -> {name}} );
                    if ($row->value != $data->{ $_ -> {name}}){
                        $modified = 0;    
                    }                    
                }else{
                    $row->value ( $data->{ $_ -> {name}} );
                    if ($row->value != $data->{ $_ -> {name}}){
                        $modified = 1;    
                    }
                }
                $row->update;
                
                if ( $modified ){
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
    my ($self, $rs_topic, $topics, $user, $id_field ) = @_;
    my @all_topics = ();
    
    # related topics
    my @new_topics = _array( $topics ) ;
    my @old_topics = map {$_->{to_mid}} Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $rs_topic->mid, rel_type => 'topic_topic', rel_field => $id_field})->hashref->all;
    
    # check if arrays contain same members
    if ( array_diff(@new_topics, @old_topics) ) {
        if( @new_topics ) {
            if(@old_topics){
                my $rs_old_topics = Baseliner->model('Baseliner::BaliMasterRel')->search({to_mid => \@old_topics});
                $rs_old_topics->delete();
            }
            
            for (@new_topics){
                Baseliner->model('Baseliner::BaliMasterRel')->update_or_create({from_mid => $rs_topic->mid, to_mid => $_, rel_type =>'topic_topic', rel_field => $id_field });
            }
            
            my $topics = join(',', @new_topics);
    
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
        my $rs = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => {in => $release_row->mid}, to_mid=>$topic_mid })->delete;
    }
        
    my @new_release = _array( $release ) ;

    # check if arrays contain same members
    if ( array_diff(@new_release, @old_release) ) {
        # release
        if( @new_release ) {
            my $row_release = Baseliner->model('Baseliner::BaliTopic')->find( $new_release[0] );
            my $topic_row = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid );
            $row_release->add_to_topics( $topic_row, { rel_type=>'topic_topic'} );
            
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
    my ($self, $rs_topic, $projects, $user ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my @new_projects = _array( $projects ) ;
    my @old_projects = map {$_->{to_mid}} Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $topic_mid, rel_type => 'topic_project'})->hashref->all;
    
    # check if arrays contain same members
    if ( array_diff(@new_projects, @old_projects) ) {
        my $del_projects = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $topic_mid, rel_type => 'topic_project'})->delete;
        # projects
        if (@new_projects){
            my @name_projects;
            my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({mid =>\@new_projects});
            while( my $project = $rs_projects->next){
                push @name_projects,  $project->name;
                $rs_topic->add_to_projects( $project, { rel_type=>'topic_project' } );
            }
            
            my $projects = join(',', @name_projects);
    
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached projects' ),
                                                old_value      => '',
                                                new_value  => $projects,
                                                text_new      => '%1 modified topic: %2 ( %4 ) on %6',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };            
        }
        else{
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => '',
                                                old_value      => '',
                                                new_value  => '',
                                                text_new      => '%1 deleted all projects',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };              
        }
    }
}

sub set_users{
    my ($self, $rs_topic, $users, $user ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my @new_users = _array( $users ) ;
    my @old_users = map {$_->{to_mid}} Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $topic_mid, rel_type => 'topic_users'})->hashref->all;

    # check if arrays contain same members
    if ( array_diff(@new_users, @old_users) ) {
        my $del_users =  Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $topic_mid, rel_type => 'topic_users'})->delete;
        # users
        if (@new_users){
            my @name_users;
            my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({mid =>\@new_users});
            while(my $user = $rs_users->next){
                push @name_users,  $user->username;
                $rs_topic->add_to_users( $user, { rel_type=>'topic_users' });
            }

            my $users = join(',', @name_users);
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached users' ),
                                                old_value      => '',
                                                new_value  => $users,
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
                                                text_new      => '%1 deleted all users',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };              
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
sub get_categories_permissions{
    my ($self, %param) = @_;
    
    my $username = delete $param{username};
    my $type = delete $param{type};
    
    my @permission_categories;
    my @categories  = Baseliner->model('Baseliner::BaliTopicCategories')->search()->hashref->all;
    push @permission_categories,    grep { Baseliner->model('Permissions')->user_has_action( username => $username, action => 'action.topics.' . $_ . '.' . $type) } 
                                    map { lc $_->{name} } @categories;
    
    my %permission_categories = map { $_ => 1} @permission_categories;
    @categories = grep { $permission_categories{lc $_->{name}}} @categories;
    return @categories;
}

# Global search

with 'Baseliner::Role::Search';

sub search_provider_name { 'Topics' };
sub search_provider_type { 'Topic' };
sub search_query {
    my ($self, %p ) = @_;
    my $c = $p{c};
    $c->request->params->{limit} = $p{limit} // 1000;
    $c->forward( '/topic/list');
    my $json = delete $c->stash->{json};
    my @mids = map { $_->{topic_mid} } _array( $json->{data} ); 
    #my %descs = DB->BaliTopic->search({ mid=>\@mids }, { select=>['mid', 'description'] })->hash_on('mid');
    return map {
        my $r = $_;
        #my $text = join ',', map { "$_: $r->{$_}" } grep { defined $_ && defined $r->{$_} } keys %$r;
        my @text = 
            map { "$_" }
            grep { length }
            map { _array( $_ ) }
            grep { defined }
            map { $r->{$_} }
            qw/created_on category_name projects 
                assignee file_name category_status_name created_by 
                labels /;
        push @text, _loc('Release') if $r->{is_release};
        push @text, _loc('Changeset') if $r->{is_changeset};
        my $info = join(', ',@text);
        my $desc = _strip_html( $r->{description} . ' ' . $r->{text} );
        if( length $desc ) {
            $desc = _utf8 $desc;  # strip html messes up utf8
            $desc =~ s/[^\w\s]//g; 
            #$desc =~ s/[^\x{21}-\x{7E}\s\t\n\r]//g; 
        }
        +{
            title => sprintf( '%s - %s', $_->{topic_name}, $_->{title} ),
            text  => $desc,
            info  => $info,
            url   => [ $_->{topic_mid}, $_->{topic_name}, $_->{category_color} ],
            type  => 'topic'
        }
    } _array( $json->{data} );
}

1;
