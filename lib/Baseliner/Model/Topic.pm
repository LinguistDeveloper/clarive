package Baseliner::Model::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use Array::Utils qw(:all);
use v5.10;


#Una prueba de commit

BEGIN { extends 'Catalyst::Model' }

my $post_filter = sub {
        my ($text, @vars ) = @_;
        $vars[2] =~ s{\n|\r|<(.+?)>}{ }gs;
        $vars[0] = "<b>$vars[0]</b>";  # bold username
        $vars[2] = "<quote>$vars[2]</quote>";  # quote post
        ($text,@vars);
    };
register 'event.post.create' => {
    text => '%1 posted a comment: %3',
    description => 'User posted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.post.delete' => {
    text => '%1 deleted a comment: %3',
    description => 'User deleted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.file.create' => {
    text => '%1 posted a file: %3',
    description => 'User uploaded a file',
    vars => ['username', 'ts', 'filename'],
};

register 'event.file.attach' => {
    text => '%1 attached %2',
    description => 'User attached a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.file.remove' => {
    text => '%1 removed %2',
    description => 'User removed a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.file_remove' => {
    text => '%1 removed %2',
    description => 'User removed a file',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.create' => {
    text => '%1 created a topic of %2',
    description => 'User created a topic',
    vars => ['username', 'category', 'ts', 'scope'],
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.topic.modify' => {
    text => '%1 modified topic',
    description => 'User modified a topic',
    vars => ['username', 'topic_name', 'ts'],
    level => 1,
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        scope => ['project', 'category', 'category_status'],
    },
    #Contemplar scope field y excluir por defecto.
};


register 'event.topic.modify_field' => {
    text => '%1 modified the field %2 from %3 to %4',
    description => 'User modified a topic',
    vars => ['username', 'field', 'old_value', 'new_value', 'text_new', 'ts',],
    filter=>sub{
        my ($txt, @vars)=@_;
       
        # TODO the idea here is to present the user with a diff in the activity log
        #require String::Diff;
        #($vars[2], $vars[3]) = String::Diff::diff(
        #    $brk->($vars[2]), $brk->($vars[3]),
        #    remove_open => '<del>',
        #    remove_close => '</del>',
        #    append_open => '<ins>',
        #    append_close => '</ins>',
        #    #escape       => sub { encode_entities($_[0]) },
        #);

        my $text_new = $vars[4];
        if( $text_new ) {
            $txt = $text_new;
        }
        else {
            #$txt = '';
            require Algorithm::Diff::XS;
            my $brk = sub { my $x=_strip_html(shift); [ $x =~ m{(\w+)}gs ] };
            my $aa = $brk->($vars[2]);
            my $bb = $brk->($vars[3]);
            my $d =Algorithm::Diff::XS::sdiff( $aa, $bb );
            my @diff;
            my @bef;
            my @aft;
            for my $ix ( 0..$#{ $d } ) {
                my ($st,$bef,$aft) = @{ $d->[$ix] };
                unless( $st eq 'u' ) {
                    push @bef, "$bef" if length $bef;
                    push @aft, "$aft" if length $aft;
                }
            }
            if( @bef || @aft ) {
                my $bef = join( ' ', @bef );
                my $aft = join( ' ', @aft );
                $bef = substr( $bef, 0, 50 ) . '...' if length $bef > 50;
                $aft = substr( $aft, 0, 50 ) . '...' if length $aft > 50;
                $vars[2] = @bef ? '<code>' . $bef . '</code>' : '<code>-</code>';
                $vars[3] = @aft ? '<code>' . $aft . '</code>' : '<code>-</code>';
            } else {
                $txt = '%1 modified the field %2';
            }
        }
        return ($txt, @vars);
    },
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        scope => ['project', 'category', 'category_status', 'field'],
    }    
};

register 'event.topic.change_status' => {
    text => '%1 changed topic status from %2 to %3',
    vars => ['username', 'old_status', 'status', 'ts'],
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        scope => ['project', 'category', 'category_status'],
    }
};

register 'action.topics.logical_change_status' => {
    name => 'Change topic status logically (no deployment)'
};

register 'registor.action.topic_category' => {
    generator => sub {
        my %type_actions_category = (
            create => _loc('Can create topic for this category'),
            view   => _loc('Can view topic for this category'),
            edit   => _loc('Can edit topic for this category'),
            delete => _loc('Can delete topic in this category')
        );

        my @categories =
            Baseliner->model('Baseliner::BaliTopicCategories')->search( undef, { order_by => 'name' } )->hashref->all;

        my %actions_category;
        foreach my $action ( keys %type_actions_category ) {
            foreach my $category (@categories) {
                my $id_action = 'action.topics.' . _name_to_id( $category->{name} ) . '.' . $action;
                $actions_category{$id_action} = { id => $id_action, name => $type_actions_category{$action} };
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
            my $msg_edit = _loc('Can edit the field');
            my $msg_view = _loc('Can not view the field');
            my $msg_in_category = _loc('in the category');
            my $msg_for_status = _loc('for the status');
            
            my $id_action;
            my $description;
            
            for my $field (_array $meta){
                if ($field->{fields}) {
                	my @fields_form = _array $field->{fields};
                    
                    for my $field_form (@fields_form){
                        $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' 
                                . _name_to_id($field->{name_field}) . '.' . _name_to_id($field_form->{id_field}) . '.read';
                        $description = $msg_view . ' ' . lc $field_form->{id_field} . ' ' . $msg_in_category . ' ' . lc $category->{name};
                        
                        $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                        
                        for my $status (@statuses){
                            $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' 
                                    . _name_to_id($field->{name_field}) . '.' . _name_to_id($field_form->{id_field}) . '.' . _name_to_id($status->{name}) . '.write';
                            $description = $msg_edit . ' ' . lc $field_form->{id_field} . ' ' . $msg_in_category . ' ' . lc $category->{name} . ' ' . $msg_for_status . ' ' . lc $status->{name};
                            
                            $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                            
                        }                    
                    }
                }
                else{

                    $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' . _name_to_id($field->{name_field}) . '.read';
                    $description = $msg_view . ' ' . lc $field->{name_field} . ' ' . $msg_in_category . ' ' . lc $category->{name};
                    
                    $actions_category_fields{$id_action} = { id => $id_action, name => $description };

                    for my $status (@statuses){
                        $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' . _name_to_id($field->{name_field}) . '.' . _name_to_id($status->{name}) . '.write';
                        $description = $msg_edit . ' ' . lc $field->{name_field} . ' ' . $msg_in_category . ' ' . lc $category->{name} . ' ' . $msg_for_status . ' ' . lc $status->{name};
                        
                        $actions_category_fields{$id_action} = { id => $id_action, name => $description };
                    }
                }
            }
        }
        return \%actions_category_fields;    
    }
};

# this is the main topic grid 

sub topics_for_user {
    my ($self, $p) = @_;
    
    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt) = ( @{$p}{qw/start limit query query_id dir sort/}, 0 );
    $dir ||= 'desc';
    $start||= 0;
    $limit ||= 100;

    $p->{page} //= to_pages( start=>$start, limit=>$limit );

    my $where = {};
    my $query_limit = 300;
    my $perm = Baseliner->model('Permissions');
    my $username = $p->{username};
    my $topic_list = $p->{topic_list};

    if( length($query) ) {
        #$query =~ s{(\w+)\*}{topic "$1"}g;  # apparently "<str>" does a partial, but needs something else, so we put the collection name "job"
        my @mids_query = map { $_->{obj}{mid} } 
            _array( mdb->topic->search( query=>$query, limit=>1000, project=>{mid=>1})->{results} );
        $where->{mid}=\@mids_query;
    }
    
    # XXX consider enabling this for quick searches on mid+title+description
    #$query and $where = query_sql_build( query=>$query, fields=>{
    #    map { $_ => "me.$_" } qw/
    #    topic_mid 
    #    title
    #    created_on
    #    created_by
    #    status
    #    numcomment
    #    category_id
    #    category_name
    #    category_status_id
    #    category_status_name        
    #    category_status_seq
    #    priority_id
    #    priority_name
    #    response_time_min
    #    expr_response_time
    #    deadline_min
    #    expr_deadline
    #    category_color
    #    label_id
    #    label_name
    #    label_color
    #    project_id
    #    project_name
    #    moniker
    #    cis_out
    #    cis_in
    #    references_out
    #    referenced_in
    #    file_name
    #    description
    #    text
    #    progress
    #    modified_on
    #    modified_by        
    #    /
    #});

    my ($select,$order_by, $as, $group_by);
    if( $sort && $sort eq 'category_status_name' ) {
        $sort = 'category_status_seq'; # status orderby sequence
        ($select, $order_by, $as, $group_by) = (
            [{ distinct=>'me.topic_mid'} , 'category_status_seq', 'category_status_name' ],
            [{ "-$dir" => 'category_status_seq'},{ "-$dir" => 'category_status_name'}, {-desc => 'me.topic_mid' }],
            ['topic_mid', 'category_status_seq', 'category_status_name' ],
            ['topic_mid', 'category_status_seq', 'category_status_name' ]
        );
    } else {
        $sort //= '';
        # sort fixups 
        $sort eq 'topic_name' and $sort = ''; # fake column, use mid instead
        $sort eq 'topic_mid' and $sort = '';
        
        ($select,$order_by, $as, $group_by) = $sort
        ? ([{ distinct=>'me.topic_mid'} ,$sort], [{ "-$dir" => $sort}, {-desc => 'me.topic_mid' }], ['topic_mid', $sort], ['topic_mid', $sort] )
        : ([{ distinct=>'me.topic_mid'},'modified_on'], [{ "-$dir" => 'modified_on' } ], ['topic_mid','modified_on'], ['topic_mid','modified_on'] );
    }

    #Filtramos por las aplicaciones a las que tenemos permisos.
    if( $username && ! $perm->is_root( $username )){
        #$where->{'project_id'} = [{-in => Baseliner->model('Permissions')->user_projects_query( username=>$username )}, { "=", undef }];
        $where->{'-or'} = [
            'exists'   =>  Baseliner->model( 'Permissions' )->user_projects_query( username=>$username, join_id=>'project_id' ),
            project_id => { '=' => undef },
        ];
    }
    
    if( $topic_list ) {
        $where->{topic_mid} = $topic_list;
    }
    
    #DEFAULT VIEWS***************************************************************************************************************
    if($p->{today}){
        my $today = DateTime->now();
        $where->{created_on} = {'between' => [ $today->ymd, $today->add(days=>1)->ymd]};
    }
    
    if ( $p->{assigned_to_me} ) {
        my $rs_user = DB->BaliUser->search( username => $username )->first;
        if ($rs_user) {
            my @topic_mids
                = map { $_->{from_mid} }
                DB->BaliMasterRel
                ->search( { to_mid => $rs_user->mid, rel_type => 'topic_users' }, { select => [qw(from_mid)] } )
                ->hashref->all;
            if (@topic_mids) {
                $where->{'me.topic_mid'} = \@topic_mids;
            } else {
                $where->{'me.topic_mid'} = -1;
            }
        } else {
            $where->{'me.topic_mid'} = -1;
        }
    }
    
    if ( $p->{unread} ){
        $where->{-bool} = \["not exists (select 1 from bali_master_prefs where username=? and last_seen >= me.modified_on and mid = me.mid)", $username];
    }
    
    if ( $p->{created_for_me} ) {
        $where->{created_by} = $username;
    }
    #*****************************************************************************************************************************
    
    #FILTERS**********************************************************************************************************************
    if($p->{labels}){
        my @labels = _array $p->{labels};
        my @not_in = map { abs $_ } grep { $_ < 0 } @labels;
        my @in = @not_in ? grep { $_ > 0 } @labels : @labels;
        if (@not_in && @in){
            $where->{'label_id'} = [{'not in' => \@not_in},{'in' => \@in}, undef];
        }else{
            if (@not_in){
                $where->{'label_id'} = [{'not in' => \@not_in}, undef];
            }else{
                $where->{'label_id'} = \@in;
            }
        }            
        #$where->{'label_id'} = \@labels;
    }
    
    if($p->{categories}){
        my @categories = _array $p->{categories};
        my @user_categories = map {
            $_->{id};
        } Baseliner->model('Topic')->get_categories_permissions( username => $username, type => 'view' );

        my @not_in = map { abs $_ } grep { $_ < 0 } @categories;
        my @in = @not_in ? grep { $_ > 0 } @categories : @categories;
        if (@not_in && @in){
            @user_categories = grep{ not $_ ~~ @not_in } @user_categories;
            $where->{'category_id'} = [{'in' => \@in},{'in' => \@user_categories}];    
        }else{
            if (@not_in){
                @in = grep{ not $_ ~~ @not_in } @user_categories;
                $where->{'category_id'} = {'in' => \@in};;
            }else{
                $where->{'category_id'} = {'in' => \@in};
            }
        }        
        #$where->{'category_id'} = \@categories;
    }else{
        # all categories, but limited by user permissions
        #   XXX consider removing this check on root and other special permissions
        my @categories  = map { $_->{id}} Baseliner::Model::Topic->get_categories_permissions( username => $username, type => 'view' );
        $where->{'category_id'} = { -in => \@categories };
    }
    
    my $default_filter;
    if($p->{statuses}){
        my @statuses = _array $p->{statuses};
        my @not_in = map { abs $_ } grep { $_ < 0 } @statuses;
        my @in = @not_in ? grep { $_ > 0 } @statuses : @statuses;
        if (@not_in && @in){
            $where->{'category_status_id'} = [{'not in' => \@not_in},{'in' => \@in}];    
        }else{
            if (@not_in){
                $where->{'category_status_id'} = {'not in' => \@not_in};
            }else{
                $where->{'category_status_id'} = \@in;
            }
        }
    }else {
        if (!$p->{clear_filter}){          
            ##Filtramos por defecto los estados q puedo interactuar (workflow) y los que no tienen el tipo finalizado.        
            my %tmp;
            map { $tmp{$_->{id_status_from}} = $_->{id_category} } 
                $self->user_workflow( $username );
            # map { $tmp{$_->{id_status_from}} = $_->{id_category} && $tmp{$_->{id_status_to} = $_->{id_category}} } 
            #             $self->user_workflow( $username );
            
            my @status_ids = keys %tmp;
            $where->{'category_status_id'} = \@status_ids if @status_ids > 0;
            #my @conditions = map { +{'-and' => [ 'category_status_id' => $_, 'category_id' => $tmp{$_} ] }} @status_ids;
            #$where->{-or} = \@conditions;
            
            #$where->{'category_status_type'} = {'!=', 'F'};
            #Nueva funcionalidad (todos los tipos de estado que empiezan por F son estado finalizado)
            $where->{'category_status_type'} = {-not_like, 'F%'}
        }
    }
      
    if( $p->{priorities}){
        my @priorities = _array $p->{priorities};
        my @not_in = map { abs $_ } grep { $_ < 0 } @priorities;
        my @in = @not_in ? grep { $_ > 0 } @priorities : @priorities;
        if (@not_in && @in){
            $where->{'priority_id'} = [{'not in' => \@not_in},{'in' => \@in}, undef];
        }else{
            if (@not_in){
                $where->{'priority_id'} = [{'not in' => \@not_in}, undef];
            }else{
                $where->{'priority_id'} = \@in;
            }
        }          
        #$where->{'priority_id'} = \@priorities;
    }

    if( $p->{from_mid} || $p->{to_mid} ){
        my $rel_where = {};
        my $dir = length $p->{from_mid} ? ['from_mid','to_mid'] : ['to_mid','from_mid'];
        $rel_where->{$dir->[0]} = $p->{$dir->[0]};
        $where->{topic_mid} = { -in => DB->BaliMasterRel->search( $rel_where,{ select=>$dir->[1]})->as_query };
    }

    #*****************************************************************************************************************************
    
    #Filtro cuando viene por la parte del Dashboard.
    if($p->{query_id}){
        $where->{topic_mid} = $p->{query_id};
    }
    
    #Filtro cuando viene por la parte del lifecycle.
    if($p->{id_project}){
        my @topics_project = map {$_->{from_mid}} DB->BaliMasterRel->search({ to_mid=>$p->{id_project}, rel_type =>'topic_project' })->hashref->all;
        $where->{topic_mid} = \@topics_project;
    }
    
    # SELECT GROUP_BY MID:
    my $args = { select=>$select, as=>$as, order_by=>$order_by, group_by=>$group_by };
    if( $limit >= 0 ) {
        $args->{page} = $p->{page};
        $args->{rows} = $limit;
    }
    
    my $rs = DB->TopicView->search(  $where, $args );                                                             
    
    if( $limit >= 0 ) {
        my $pager = $rs->pager;
        $cnt = $pager->total_entries;
    } else {
        $cnt = $rs->count;
    }
    rs_hashref( $rs );
    my @mids = map { $_->{topic_mid} } $rs->all;
    my $rs_sub = $rs->search(undef, { select=>'topic_mid' });
            # _log _dump $rs_sub->as_query;
    
    # SELECT MID DATA:
    my %mid_data = map { $_->{topic_mid} => $_ } grep { defined } map { Baseliner->cache_get("topic:view:$_:") } @mids; 
    if( my @db_mids = grep { !exists $mid_data{$_} } @mids ) {
        _debug( "CACHE==============================> MIDS: @mids, DBMIDS: @db_mids, MIDS_IN_CACHE: " . join',',keys %mid_data );
        my @db_mid_data = DB->TopicView->search({ topic_mid=>{ -in =>\@db_mids  } })->hashref->all if @db_mids > 0;
        
        # Controlar que categorias son editables.
        my %categories_edit = map { lc $_->{name} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $username, type => 'edit' );
        
        for my $row (@db_mid_data) {
            my $mid = $row->{topic_mid};
            $mid_data{ $mid } = $row unless exists $mid_data{ $row->{topic_mid} };
            $mid_data{ $mid }{is_closed} = defined $row->{status} && $row->{status} eq 'C' ? \1 : \0;
            $mid_data{ $mid }{sw_edit} = 1 if exists $categories_edit{ lc $row->{category_name}};

            # fill out hash indexes
            if( $row->{label_id} ) {
                $mid_data{$mid}{group_labels}{ $row->{label_id} . ";" . $row->{label_name} . ";" . $row->{label_color} } = ();
            }
            if( $row->{project_id} && $row->{collection} && $row->{collection} eq 'project') {
                $mid_data{$mid}{group_projects}{ $row->{project_id} . ";" . $row->{project_name} } = ();
                $mid_data{$mid}{group_projects_report}{ $row->{project_name} } = ();
            # } else {
            #     $mid_data{$mid}{group_projects} = {};
            #     $mid_data{$mid}{group_projects_report} = {};
            }
            if( $row->{cis_out} ) {
                $mid_data{$mid}{group_cis_out}{ $row->{cis_out} } = ();
            }
            if( $row->{cis_in} ) {
                $mid_data{$mid}{group_cis_in}{ $row->{cis_in} } = ();
            }
            if( $row->{references_out} ) {
                $mid_data{$mid}{group_references_out}{ $row->{references_out} } = ();
            }
            if( $row->{referenced_in} ) {
                $mid_data{$mid}{group_referenced_in}{ $row->{referenced_in} } = ();
            }
            if( $row->{directory} ) {
                $mid_data{$mid}{group_directory}{ $row->{directory} } = ();
            }
            $mid_data{$mid}{group_assignee}{ $row->{assignee} } = () if defined $row->{assignee};
        }
        for my $db_mid ( @db_mids ) {
            Baseliner->cache_set( "topic:view:$db_mid:", $mid_data{$db_mid} );
        }
    } else {
        _debug "CACHE =========> ALL TopicView data MIDS in CACHE";
    }
    
    # get user seen 
    my @mid_prefs = DB->BaliMasterPrefs->search({ mid=>{ -in => \@mids }, username=>$username })->hashref->all;
    for( @mid_prefs ) {
        my $d = $mid_data{$_->{mid}};
        #next if !defined $d->{last_seen} || !defined $d->{modified_on};
        $d->{user_seen} = !defined $_->{last_seen} || "$d->{modified_on}" gt "$_->{last_seen}" ? \0 : \1;
    }

    my @rows;
    for my $mid (@mids) {
        my $data = $mid_data{$mid};
        $data->{calevent} = {
            mid    => $mid,
            color  => $data->{category_color},
            title  => sprintf("%s #%d - %s", $data->{category_name}, $mid, $data->{title}),
            allDay => \1
        };
        $data->{category_status_name} = _loc($data->{category_status_name});
        $data->{category_name} = _loc($data->{category_name});
        map { $data->{$_} = [ keys %{ delete($data->{"group_$_"}) || {} } ] } qw/labels projects cis_out cis_in references_out referenced_in assignee directory/;
        my @projects_report = keys %{ delete $data->{projects_report} || {} };
        push @rows, {
            %$data,
            topic_name => sprintf("%s #%d", $data->{category_name}, $mid),
            report_data => {
                projects => join( ', ', @projects_report )
            }
        };
    }
    return $cnt, @rows ;
}


sub update {
    my ( $self, $p ) = @_;
    my $action = $p->{action};
    my $return;
    my $topic_mid;
    my $status;
    my $category;
    my $modified_on;
    
    given ( $action ) {
        #Casos especiales, por ejemplo la aplicacion GDI
        my $form = $p->{form};
        $p->{_cis} = _decode_json( $p->{_cis} ) if $p->{_cis};

        when ( 'add' ) {
            
            event_new 'event.topic.create' => { username=>$p->{username} } => sub {
                Baseliner->model('Baseliner')->txn_do(sub{
                    my $meta = $self->get_meta ($topic_mid , $p->{category});
                    
                    my @meta_filter;
                    push @meta_filter, $_
                       for grep { exists $p->{$_->{id_field}}} _array($meta);
                    $meta = \@meta_filter;
                    
                    my $topic = $self->save_data ($meta, undef, $p);
                    
                    $topic_mid    = $topic->mid;
                    $status = $topic->id_category_status;
                    $return = 'Topic added';
                    $category = { $topic->categories->get_columns };
                    $modified_on = $topic->modified_on->epoch;
                    my @projects = map {$_->{mid}} $topic->projects->hashref->all;
                    my $id_category = $topic->id_category;
                    my $id_category_status = $topic->id_category_status;
                    
                    my @users = $self->get_users_friend(id_category => $id_category, id_status => $id_category_status, projects => \@projects);
                    
                    my $notify = {
                        category        => $id_category,
                        category_status => $id_category_status,
                    };
                    $notify->{project} = \@projects if @projects;
                    
                    my $subject = _loc("New topic (%1): [%2] %3", $category->{name}, $topic->mid, $topic->title);
                    { mid => $topic->mid, topic => $topic->title, category => $category->{name}, notify_default => \@users, subject => $subject, notify => $notify }   # to the event
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
                    
                    my @meta_filter;
                    push @meta_filter, $_
                       for grep { exists $p->{$_->{id_field}}} _array($meta);
                    $meta = \@meta_filter;
                    
                    my $topic = $self->save_data ($meta, $topic_mid, $p);
                    
                    $topic_mid    = $topic->mid;
                    $status = $topic->id_category_status;
                    $modified_on = $topic->modified_on->epoch;
                    $category = { $topic->categories->get_columns };
                    
                    my @projects = map {$_->{mid}} $topic->projects->hashref->all;
                    my @users = $self->get_users_friend(id_category => $topic->id_category, id_status => $topic->id_category_status, projects => \@projects);
    
                    $return = 'Topic modified';
                    my $subject = _loc("Topic updated (%1): [%2] %3", $category->{name}, $topic->mid, $topic->title);
                   { mid => $topic->mid, topic => $topic->title, subject => $subject, notify_default => \@users }   # to the event
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
                
                for my $mid ( _array( $topic_mid ) ) {
                    # delete master row and bali_topic row
                    #      -- delete cascade does not clear up the cache
                    _ci( $mid )->delete;
                    mdb->topic->remove({ mid=>"$mid" });
                }

                $modified_on = Class::Date->new(_now)->epoch;
                
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
                $modified_on = $topic->modified_on->epoch;

                $topic_mid    = $topic->mid;
                $return = 'Topic closed'
            } ## end try
            catch {
                _throw _loc( 'Error closing Topic: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $topic_mid, $status, $p->{title}, $category, $modified_on);
} ## end sub update


sub append_category {
    my ($self, @topics ) =@_;
    return map {
        $_->{name} = $_->{categories}->{name} ? _loc($_->{categories}->{name}) . ' #' . $_->{mid}: _loc($_->{name}) . ' #' . $_->{mid} ;
        $_->{color} = $_->{categories}->{color} ? $_->{categories}->{color} : $_->{color};
        $_
    } @topics;
}

sub next_status_for_user {
    my ($self, %p ) = @_;
    my $user_roles;
    my $username = $p{username};
    my $where = { id_category => $p{id_category} };
    $where->{id_status_from} = $p{id_status_from} if defined $p{id_status_from};
    my $is_root = Baseliner->model('Permissions')->is_root( $username );
    my @to_status;
    
    if ( !$is_root ) {
        $user_roles = Baseliner->model('Baseliner::BaliRoleUser')->search({ username => $username },{ select=>'id_role' } )->as_query;
        $where->{id_role} = { -in => $user_roles };
        
       my @all_to_status = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
            $where,
            {   join     => [ 'roles', 'statuses_to', 'statuses_from' ],
                distinct => 1,
                +select => [ 'id_status_from', 'statuses_from.name', 'statuses_from.bl', 'id_status_to', 'statuses_to.name', 'statuses_to.type', 'statuses_to.bl', 'statuses_to.description', 'id_category', 'job_type','statuses_to.seq' ],
                +as     => [ 'id_status_from', 'status_name_from', 'status_bl_from', 'id_status',    'status_name', 'status_type', 'status_bl', 'status_description', 'id_category', 'job_type','seq' ]
            }
        )->hashref->all;
        
        my @no_deployable_status = grep {$_->{status_type} ne 'D'} @all_to_status;
        my @deployable_status = grep {$_->{status_type} eq 'D'} @all_to_status; 
        
        
        push @to_status, @no_deployable_status;
        
        foreach my $status (@deployable_status){
            if ( $status->{job_type} eq 'promote' ) {
                if(Baseliner->model('Permissions')->user_has_action( username=> $username, action => 'action.topics.logical_change_status', bl=> $status->{status_bl} )){
                    push @to_status, $status;
                }
            }else{
                if ( $status->{job_type} eq 'demote' ) {
                    if(Baseliner->model('Permissions')->user_has_action( username=> $username, action => 'action.topics.logical_change_status', bl=> $status->{status_bl_from} )){
                        push @to_status, $status;
                    }               
                }
            }
        }    
    } else {
        my @user_wf = $self->user_workflow( $username );
        @to_status = sort { ($a->{seq} // 0 ) <=> ( $b->{seq} // 0 ) } grep {
            $_->{id_category} eq $p{id_category}
                && $_->{id_status_from} eq $p{id_status_from}
                && $_->{id_status_to} ne $p{id_status_from}
        } @user_wf;
    }

    return @to_status;
}

sub get_system_fields {
    my ($self);
    my $pathHTML = '/fields/system/html/';
    my $pathJS = '/fields/system/js/';
    my @system_fields = (
        {
            id_field => 'title',
            params   => {
                name_field       => 'Title',
                bd_field         => 'title',
                origin           => 'system',
                html             => $pathHTML . 'field_title.html',
                js               => '/fields/templates/js/textfield.js',
                field_order      => -1,
                font_weigth      => 'bold',
                section          => 'head',
                field_order_html => 1,
                allowBlank       => \0,
                system_force     => \1
            }
        },
        {
            id_field => 'moniker',
            params   => {
                name_field       => 'Moniker',
                bd_field         => 'moniker',
                origin           => 'system',
                js               => '/fields/templates/js/textfield.js',
                html          => '/fields/templates/html/row_body.html',
                field_order      => -8,
                section          => 'body',
                allowBlank       => \1
            }
        },
        {
            id_field => 'category',
            params   => {
                name_field  => 'Category',
                bd_field    => 'id_category',
                origin      => 'system',
                js          => $pathJS . 'field_category.js',
                field_order => -2,
                section     => 'body',
                relation    => 'categories',
                allowBlank       => \0,
                system_force     => \1
            }
        },
        {
            id_field => 'status_new',
            params   => {
                name_field    => 'Status',
                bd_field      => 'id_category_status',
                display_field => 'name_status',
                origin        => 'system',
                html          => '/fields/templates/html/row_body.html',
                js            => $pathJS . 'field_status.js',
                field_order   => -3,
                section       => 'body',
                relation      => 'status',
                framed        => 1,
                allowBlank    => \0,
                system_force     => \1
            }
        },
        {
            id_field => 'created_by',
            params   => { name_field => 'Created By', bd_field => 'created_by', origin => 'default' }
        },
        {
            id_field => 'created_on',
            params   => { name_field => 'Created On', bd_field => 'created_on', origin => 'default' }
        },
        {
            id_field => 'modified_by',
            params   => { name_field => 'Modified By', bd_field => 'modified_by', origin => 'default' }
        },
        {
            id_field => 'modified_on',
            params   => { name_field => 'Modified On', bd_field => 'modified_on', origin => 'default' }
        },        
        {
            id_field => 'labels',
            params   => {
                name_field       => 'Labels',
                bd_field         => 'labels',
                origin           => 'default',
                relation         => 'system',
                get_method       => 'get_labels',
                field_order_html => 1
            }
        },
        {
            id_field => 'priority',
            params   => {
                name_field  => 'Priority',
                bd_field    => 'id_priority',
                set_method  => 'set_priority',
                origin      => 'system',
                html        => $pathHTML . 'field_priority.html',
                js          => $pathJS . 'field_priority.js',
                field_order => -6,
                section     => 'body',
                relation    => 'priorities'
            }
        },
        {
            id_field => 'description',
            params   => {
                name_field       => 'Description',
                bd_field         => 'description',
                origin           => 'system',
                html             => '/fields/templates/html/dbl_row_body.html',
                js               => '/fields/templates/js/html_editor.js',
                field_order      => -7,
                section          => 'head',
                field_order_html => 2
            }
        },
        {
            id_field => 'progress',
            params   => {
                name_field  => 'Progress',
                bd_field    => 'progress',
                origin      => 'system',
                html        => '/fields/templates/html/progress_bar.html',
                js          => '/fields/templates/js/progress_bar.js',
                field_order => -8,
                section     => 'body'
            }
        },
        {
            id_field => 'include_into',
            params   => {
                name_field  => 'Include into',
                bd_field    => 'include_into',
                origin      => 'default',
                html        => $pathHTML . 'field_include_into.html',
                field_order => 0,
                section     => 'details'
            }
        },
    );
    return \@system_fields
}

sub tratar{
    my $field = shift;
    my $params = _load $field->{params_field} ;
    if ($params->{origin} eq 'custom'){ 
        $_->{type} = $params->{type};
        $_->{js} = $params->{js};
        return 1;
    }
    else {
        return 0;
    }
}
    
sub get_update_system_fields {
    my ($self, $id_category) = @_;
    
    my $system_fields = $self->get_system_fields();
    my @rs_categories_fields =  Baseliner->model('Baseliner::BaliTopicFieldsCategory')->search(undef,{select=>'id_category', distinct=>1})->hashref->all;
    for my $category ( @rs_categories_fields ){
        my $id_category = $category->{id_category};
        for (_array $system_fields){
            my $field = Baseliner->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $id_category, id_field => $_->{id_field}})->first;
            if ($field){
                my $tmp_params = _load $field->params_field;
                for my $attr (keys %{ $_->{params} || {} }){
                    next unless $attr ne 'field_order';
                    $tmp_params->{$attr} = $_->{params}->{$attr};
                    $field->params_field( _dump $tmp_params );
                    $field->update();
                }
            }
        }
    }
    
    my @template_dirs;
    push @template_dirs, Baseliner->path_to( 'root/fields/templates/js' ) . "/*.js";
    push @template_dirs, Baseliner->path_to( 'root/fields/system/js' ) . "/list*.js";
    #@template_dirs = grep { -d } @template_dirs;
    
    my @tmp_templates = map {
        my @ret;
        for my $f ( map { _file($_) } grep { -f } glob "$_" ) { 
            my $d = $f->slurp;
            my $yaml = Util->_load_yaml_from_comment( $d );
           
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
    } @template_dirs;
    
    my @fields =  grep { tratar $_ } Baseliner->model('Baseliner::BaliTopicFieldsCategory')->search()->hashref->all;    
    
    for my $template (  grep {$_->{metadata}->{params}->{origin} eq 'template'} @tmp_templates ) {
        if( $template->{metadata}->{name} ){
    	    my @select_fields = grep { $_->{type} eq $template->{metadata}->{params}->{type}} @fields;
            for my $select_field (@select_fields){
                my $update_field = Baseliner->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $select_field->{id_category},
                																					id_field => $select_field->{id_field}})->first;
                if ($update_field){
                    my $tmp_params = _load $update_field->params_field;
                    for my $attr (keys %{ $template->{metadata}->{params} || {} } ){
                        next unless $attr ne 'field_order' && $attr ne 'bd_field' && $attr ne 'id_field' && $attr ne 'name_field' && $attr ne 'origin';
                        $tmp_params->{$attr} = $template->{metadata}->{params}->{$attr};

                    }   
                    $update_field->params_field( _dump $tmp_params );
                    $update_field->update();                    
                }
                
            }
	
        }
    }
    
    for my $system_listbox ( grep {!$_->{metadata}->{params}->{origin}} @tmp_templates ) {
        if( $system_listbox->{metadata}->{name} ){
    		my @select_fields = grep { $_->{js} eq $system_listbox->{metadata}->{params}->{js}} @fields;
            for my $select_field (@select_fields){
                my $update_field = Baseliner->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $select_field->{id_category},
                																					id_field => $select_field->{id_field}})->first;
                if ($update_field){
                    my $tmp_params = _load $update_field->params_field;
                    for my $attr (keys %{ $system_listbox->{metadata}->{params} || {} } ){
                        next unless $attr ne 'field_order' && $attr ne 'bd_field' && $attr ne 'id_field' 
                        && $attr ne 'name_field' && $attr ne 'origin' && $attr ne 'singleMode' && $attr ne 'filter' ;
                        $tmp_params->{$attr} = $system_listbox->{metadata}->{params}->{$attr};
                    }
                            
                    $update_field->params_field( _dump $tmp_params );
                    $update_field->update();
                }

            }
        }
    }
}

our %meta_types = (
    set_projects   => 'project',
    set_topics     => 'topic',
    set_release    => 'release',
    set_revisions  => 'revision',
    set_cal        => 'calendar',
    set_cis        => 'ci',
    set_users      => 'user',
    set_priority   => 'priority',
);

sub get_meta {
    my ($self, $topic_mid, $id_category) = @_;

    my $cached = Baseliner->cache_get( "topic:meta:$topic_mid:") if $topic_mid;
    return $cached if $cached;

    my $id_cat =  $id_category
        // DB->BaliTopic->search({ mid=>$topic_mid }, { select=>'id_category' })->as_query;
        
    my @meta =
        sort { $a->{field_order} <=> $b->{field_order} }
        map  { 
            my $d = _load $_->{params_field};
            if( length $d->{default_value} && $d->{default_value}=~/^#!perl:(.*)$/ ) {
                $d->{default_value} = eval $1;
            }
            $d->{field_order} //= 1;
            $d->{meta_type} ||= $d->{set_method} 
                ? ($meta_types{ $d->{set_method} } // _fail("Unknown set_method $d->{set_method} for field $d->{name_field}") ) 
                : '';
            $d
        }
        DB->BaliTopicFieldsCategory->search({ id_category=>{ -in => $id_cat } })->hashref->all;
    
    Baseliner->cache_set( "topic:meta:$topic_mid:", \@meta ) if length $topic_mid;
    
    return \@meta;
}

sub get_data {
    my ($self, $meta, $topic_mid, %opts ) = @_;
    
    # normalize to improve cache_hits:
    my $no_cache = delete( $opts{no_cache} ) || 0;
    my $with_meta = delete $opts{with_meta};
    $opts{topic_child_data} = !! $opts{topic_child_data};
    $opts{has_meta} = !!( $meta || $with_meta ); # normalize the cache only

    my $data;
    if ($topic_mid){
        if( !$meta && $with_meta ) {
            $meta = $self->get_meta( $topic_mid );  
        }
        my $cache_key = ["topic:data:$topic_mid:", \%opts];
        my $cached = Baseliner->cache_get( $cache_key ) unless $no_cache; 
        if( defined $cached ) {
            _debug( "CACHE HIT get_data: topic_mid = $topic_mid" );
            return $cached;
        }
        
        ##************************************************************************************************************************
        ##CAMPOS DE SISTEMA ******************************************************************************************************
        ##************************************************************************************************************************
        #my @std_fields = map { $_->{id_field} } grep { $_->{origin} eq 'system' } _array( $meta  );
        #my $rs = Baseliner->model('Baseliner::BaliTopic')->search({ mid => $topic_mid },{ select=>\@std_fields });
        
        my @select_fields = ('title', 'id_category', 'categories.name', 'categories.color',
                             'id_category_status', 'status.name', 'created_by', 'created_on', 'modified_by', 'modified_on',
                             'id_priority','priorities.name', 'deadline_min', 'description','progress', 'status.type', 'master.moniker' );
        my @as_fields = ('title', 'id_category', 'name_category', 'color_category', 'id_category_status', 'name_status',
                         'created_by', 'created_on', 'modified_by', 'modified_on', 'id_priority', 'name_priority', 'deadline_min', 'description', 'progress','type_status', 'moniker' );
        
        my $rs = Baseliner->model('Baseliner::BaliTopic')
                ->search({ 'me.mid' => $topic_mid },{ join => ['categories','status','priorities','master'], select => \@select_fields, as => \@as_fields});
        my $row = $rs->first;
        _error( "topic mid $topic_mid row not found" ) unless $row;
        
        $data = { topic_mid => $topic_mid, $row->get_columns };
        
        $data->{action_status} = $self->getAction($data->{type_status});
        $data->{created_on} = $row->created_on->dmy . ' ' . $row->created_on->hms;
        $data->{created_on_epoch} = $row->created_on->epoch;
        $data->{modified_on} = $row->modified_on->dmy . ' ' . $row->modified_on->hms;
        $data->{modified_on_epoch} = $row->modified_on->epoch;
        #$data->{deadline} = $row->deadline_min ? $row->created_on->clone->add( minutes => $row->deadline_min ):_loc('unassigned');
        $data->{deadline} = _loc('unassigned');
        
        ##*************************************************************************************************************************
        ###************************************************************************************************************************
        
        
        my %rel_fields = map { $_->{id_field} => 1  } grep { defined $_->{relation} && $_->{relation} eq 'system' } _array( $meta );
        my %method_fields = map { $_->{id_field} => $_->{get_method}  } grep { $_->{get_method} } _array( $meta );
        my %metadata = map { $_->{id_field} => $_  } _array( $meta );

        my @rels = DB->BaliMasterRel->search({ from_mid=>$topic_mid })->hashref->all;
        for my $rel ( @rels ) {
            next unless $rel->{rel_field};
            next unless exists $rel_fields{ $rel->{rel_field} };
            push @{ $data->{ $rel->{rel_field} } },  $rel->{to_mid};
        }
        
        foreach my $key  (keys %method_fields){
            my $method_get = $method_fields{ $key };
            $data->{ $key } =  $self->$method_get( $topic_mid, $key, $meta, $data, %opts );
        }
        
        my %custom_fields = map { $_->{id_field} => 1 } grep { $_->{origin} eq 'custom' && !$_->{relation} } _array( $meta  );
        my $doc = mdb->topic->find_one({ mid=>"$topic_mid" });
        for my $f ( grep { exists $custom_fields{$_} } keys %{ $doc || {} } ) {
            $data->{ $f } = $doc->{$f}; 
        }
        Baseliner->cache_set( $cache_key, $data );
    }
    
    return $data;
}

sub get_release {
    my ($self, $topic_mid, $key, $meta ) = @_;

    my @meta_local = _array($meta);
    my ($field_meta) = grep { $_->{id_field} eq $key } @meta_local;
    
    my $where = { is_release => 1, rel_type=>'topic_topic', to_mid=>$topic_mid };
    $where->{rel_field} = $field_meta->{release_field} if $field_meta->{release_field};
    
    my $release_row = Baseliner->model('Baseliner::BaliTopic')->search(
                            $where,
                            { prefetch=>['categories','children','master'] }
                            )->hashref->first; 
    return  {
                color => $release_row->{categories}{color},
                title => $release_row->{title},
                mid => $release_row->{mid},
            }
}

sub get_projects {
    my ($self, $topic_mid, $id_field, $meta, $data ) = @_;

    # for safety with legacy, reassign previous unassigned projects (normally from drag-drop
    DB->BaliMasterRel->search({ from_mid=>$topic_mid, rel_type=>'topic_project', rel_field=>undef })->update({ rel_field=>$id_field });
    
    my @projects = Baseliner->model('Baseliner::BaliTopic')->find(  $topic_mid )->projects->search( {rel_field => $id_field}, { select=>['mid','name'], order_by => { '-asc' => ['mid'] }} )->hashref->all;
    $data->{"$id_field._project_name_list"} = join ', ', map { $_->{name} } @projects;
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
    my @revisions = DB->BaliMasterRel->search( { rel_type => 'topic_revision', from_mid => $topic_mid },
        { prefetch => ['master_to'], +select => [ 'master_to.name', 'master_to.mid' ], +as => [qw/name mid/] } )
        ->hashref->all;
    return @revisions ? \@revisions : [];    
}

sub get_cis {
    my ($self, $topic_mid, $id_field, $meta ) = @_;
    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array( $meta ) ]->[0];
    my $where = { from_mid => $topic_mid };
    $where->{rel_type} = $field_meta->{rel_type} if ref $field_meta eq 'HASH' && defined $field_meta->{rel_type};
    my @cis = map { $_->{mid} } DB->BaliMasterRel->search(     
        $where,
        #{ prefetch => ['master_to'], +select => [ 'master_to.name', 'master_to.mid' ], +as => [qw/name mid/] } )
        { select =>[ 'to_mid' ], as=>[ 'mid' ] },
        )->hashref->all;
    
    return @cis ? \@cis : [];    
}

sub get_dates {
    my ($self, $topic_mid ) = @_;
    my @dates = Baseliner->model('Baseliner::BaliMasterCal')->search({ mid=> $topic_mid })->hashref->all;
    return @dates ?  \@dates : [];
}

sub get_topics{
    my ($self, $topic_mid, $id_field, $meta, $data, %opts) = @_;
    my $rs_rel_topic = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )
        ->topics->search( {rel_field => $id_field}, { order_by=>'rel_seq', prefetch=>['categories'] } );
    rs_hashref ( $rs_rel_topic );
    my @topics = $rs_rel_topic->all;
    @topics = Baseliner->model('Topic')->append_category( @topics );
    if( $opts{topic_child_data} ) {
        @topics = map {
            my $data = $self->get_data( undef, $_->{mid}, with_meta=>1 ) ;
            $_->{description} //= $data->{description};
            $_->{name_status} //= $data->{name_status};
            $_->{data} //= $data;
            $_
        } @topics;
    }
    return @topics ? \@topics : [];    
}

sub get_cal {
    my ($self, $topic_mid, $id_field, $meta, $data, %opts) = @_;
    my @cal = DB->BaliMasterCal->search({ mid=>$topic_mid, rel_field=>$id_field })
        ->hashref->all;
    return \@cal; 
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
    my ($self, $meta, $topic_mid, $data, %opts ) = @_;

    Baseliner->cache_remove( qr/:$topic_mid:/ ) if length $topic_mid;
    
    my @std_fields =
        map { +{ name => $_->{id_field}, column => $_->{bd_field}, method => $_->{set_method}, relation => $_->{relation} } }
        grep { $_->{origin} eq 'system' } _array($meta);
    
    my %row;
    my %description;
    my %old_values;
    my %old_text;
    my %relation;

    my @imgs;

    $data->{description} = $self->deal_with_images({topic_mid => $topic_mid, field => $data->{description}});

    for( @std_fields ) {
        if  (exists $data->{ $_ -> {name}}){
            $row{ $_->{column} } = $data->{ $_ -> {name}};
            $description{ $_->{column} } = $_ -> {name}; ##Contemplar otro parametro mas descriptivo
            $relation{ $_->{column} } = $_ -> {relation};
            if ($_->{method}){
                #my $extra_fields = eval( '$self->' . $_->{method} . '( $data->{ $_ -> {name}}, $data, $meta )' );
                my $method_set = $_->{method};
                my $extra_fields = $self->$method_set( $data->{ $_->{name} }, $data, $meta, %opts );
                foreach my $column (keys %{ $extra_fields || {} } ){
                     $row{ $column } = $extra_fields->{$column};
                }
            }
        }
    }

    my @custom_fields =
        map { +{ name => $_->{id_field}, column => $_->{id_field}, data => $_->{data} } }
        grep { $_->{origin} eq 'custom' && !$_->{relation} } _array($meta);

    push @custom_fields, 
        map { 
            my $cf = $_;
            map {
                +{ name => $_->{id_field}, column => $_->{id_field}, data=> $_->{data} }
            } _array $_->{fields};
        } grep { $_->{type} && $_->{type} eq 'form' } _array($meta);
    
    my $topic;
    my $moniker = delete $row{moniker};
    
    if (!$topic_mid){
        master_new 'topic' => { name=>$data->{title}, moniker=>$moniker, data=>{ %row } } => sub {
            $topic_mid = shift;

            #Defaults
            $row{ mid } = $topic_mid;
            $row{ created_by } = $data->{username};
            $row{ modified_by } = $data->{username};
            $row{ id_category_status } = $data->{id_category_status} if $data->{id_category_status};
            
            $topic = DB->BaliTopic->create( \%row );

            # update images
            for( @imgs ) {
                $_->update({ topic_mid => $topic_mid });
            }

        }        
        
    }else{
        $topic = DB->BaliTopic->find( $topic_mid, { prefetch =>['categories','status','priorities'] } );

        for my $field (keys %row){
            $old_values{$field} = $topic->$field,
            my $method = $relation{ $field };
            $old_text{$field} = $method ? try { $topic->$method->name } : $topic->$field,
        }
        $topic->modified_by( $data->{username} );
        $topic->update( \%row );
        _ci( $topic_mid )->update( name=>$row{title}, moniker=>$moniker, %row );

        for my $field (keys %row){
            next if $field eq 'response_time_min' || $field eq 'expr_response_time';
            next if $field eq 'deadline_min' || $field eq 'expr_deadline';

            my $method = $relation{ $field };
            my $new_value = $row{$field};
            my $old_value = $old_values{$field};


            if ( $new_value ne $old_value ){
                if($field eq 'id_category_status'){
                    # change status
                    my $id_status = $new_value;
                    my $cb_ci_update = sub {
                        # check if it's a CI update
                        my $status_new = DB->BaliTopicStatus->find( $id_status );
                        my $ci_update = $status_new->ci_update;
                        if( $ci_update && ( my $cis = $data->{_cis} ) ) {
                            for my $ci ( _array $cis ) {
                                my $ci_data = $ci->{ci_data} // { map { $_ => $data->{$_} } grep { length } _array( $ci->{ci_fields} // @custom_fields ) };
                                my $ci_master = $ci->{ci_master} // $ci_data;
                                given( $ci->{ci_action} ) {
                                    when( 'create' ) {
                                        my $ci_class = $ci->{ci_class};
                                        $ci_class = 'BaselinerX::CI::' . $ci_class unless $ci_class =~ /^Baseliner/;
                                        my $obj = $ci_class->new( %$ci_master, %$ci_data );
                                        $ci->{ci_mid} = $obj->save;
                                        $ci->{_ci_updated} = 1;
                                    }
                                    when( 'update' ) {
                                        _debug "ci update $ci->{ci_mid}";
                                        my $ci_mid = $ci->{ci_mid} // $ci_data->{ci_mid};
                                        my $obj = _ci( $ci_mid );
                                        $obj->update( %$ci_master, %$ci_data );
                                        $obj->save;
                                        $ci->{_ci_updated} = 1;
                                    }
                                    when( 'delete' ) {
                                        my $ci_mid = $ci->{ci_mid} // $ci_data->{ci_mid};
                                        my $obj = _ci( $ci_mid );
                                        $obj->update( %$ci_master, %$ci_data );
                                        $obj->save;
                                        $obj->delete; 
                                        $ci->{_ci_updated} = 1;
                                    }
                                    default {
                                        _throw _loc "Invalid ci action '%1' for mid '%2'", $ci->{ci_action}, $ci->{ci_mid};
                                    }
                                }
                            }
                        }
                    };
                    $self->change_status( mid=>$topic_mid, title=>$topic->{title}, username=>$data->{username},
                        old_status=>$old_text{$field}, id_old_status =>$old_value,
                        id_status=>$id_status, callback=>$cb_ci_update
                    );
                }
                else {
                    # report event
                    
                    my @projects = map {$_->{mid}} $topic->projects->hashref->all;                    
                    my $notify = {
                        category        => $topic->id_category,
                        category_status => $topic->id_category_status,
                        field           => $field
                    };                    
                    $notify->{project} = \@projects if @projects;
                    
                    event_new 'event.topic.modify_field' 
                        => { 
                             username   => $data->{username},
                             field      => _loc ($description{ $field }),
                             old_value  => $old_text{$field},
                             new_value  => $method && $topic->$method ? $topic->$method->name : $topic->$field,
                           } 
                        => sub {
                            my $subject = _loc("Topic [%1] %2: Field '%3' updated", $topic->mid, $topic->title, $description{ $field });
                            { mid => $topic->mid, topic => $topic->title, subject => $subject, notify => $notify }   # to the event
                        } 
                        => sub {
                            _throw _loc( 'Error modifying Topic: %1', shift() );
                        };

                }
            }
        }        
    }

    
    if( my $cis = $data->{_cis} ) {
        for my $ci ( _array $cis ) {
            if( length $ci->{ci_mid} && $ci->{ci_action} eq 'update' ) {
                DB->BaliMasterRel->update_or_create({ rel_type=>'ci_request', from_mid=>$ci->{ci_mid}, to_mid=>$topic->mid });
            }
        }
    }
    
    # save relationship fields
    my %rel_fields = map { $_->{id_field} => $_->{set_method} }  grep { $_->{relation} && $_->{relation} eq 'system' } _array( $meta  );
    foreach my $id_field  (keys %rel_fields){
        if($rel_fields{$id_field}){
            my $meth = $rel_fields{$id_field};
            $self->$meth( $topic, $data->{$id_field}, $data->{username}, $id_field, $meta );
        }
    } 
     
    # save to mongo
    $self->save_doc( $meta, $data, custom_fields=>\@custom_fields );

    # user seen
    my $row = DB->BaliMasterPrefs->update_or_create({ username=>$data->{username}, mid=>$topic_mid, last_seen=>_dt() });
    
    # cache clear
    $self->cache_topic_remove( $topic_mid );
    my @related_topics = ci->new($topic_mid)->related( isa => 'topic');
    for ( @related_topics ) {
        $self->cache_topic_remove( $_->{mid} );
    }

    return $topic;
}

sub save_doc {
    my ($self,$meta,$doc, %p) = @_;
    #my $doc = Util->_clone($data); # so that we don't change the original
    my $mid = ''. $doc->{topic_mid};
    _fail _loc 'save_doc failed: no mid' unless length $mid; 
    $doc->{mid} = $mid;
    my @custom_fields = @{ $p{custom_fields} };
    my %meta = map { $_->{id_field} => $_ } @$meta;
    
    # take images out
    for( @custom_fields ) {
        $doc->{ $_->{name} } = $self->deal_with_images({ topic_mid => $mid, field => $doc->{ $_->{name} } });
    }
    
    # detect modified fields
    require Hash::Diff;
    my $old_doc = mdb->topic->find_one({ mid=>$mid });
    my $diff = Hash::Diff::left_diff( $old_doc, $doc ); # hash has only changed and deleted fields
    my $projects = [ map { $_->{mid} } () ] if %$diff; # data from doc in meta_type=project fields $topic->projects->hashref->all;
    for my $changed ( keys %$diff ){
        my $old_value = $diff->{ $changed };
        my $md = $meta{ $changed };
        my $notify = {
            category        => $doc->{id_category},
            category_status => $doc->{id_category_status},
            field           => $md->{name_field},
        };
        $notify->{project} = $projects if @$projects;
        
        event_new 'event.topic.modify_field' => { 
            username   => $doc->{username},
            field      => _loc( $md->{name_field} ),
            old_value  => $old_value,
            new_value  => $doc->{ $changed },
        }, 
        sub {
            my $subject = _loc("Topic [%1] %2: Field '%3' updated", $mid, $doc->{title}, $md->{name_field} );
            { mid => $mid, topic => $doc->{title}, subject=>$subject, notify=>$notify }   # to the event
        }, 
        sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };
    }
    
    # calendar info
    _error \%meta;
    for my $field ( grep { $meta{$_}{meta_type} eq 'calendar' } keys %meta ) {
        my $arr = $doc->{$field} or next;
        $doc->{$field} = {};
        for my $cal ( _array($arr) ) {
            _fail "field $field is not a calendar?" unless ref $cal;
            my $slot = delete $cal->{slotname};
            $doc->{$field}{$slot} = $cal;
        }
    }
    
    # expanded data
    $doc->{category} = $p{category} if $p{category};
    $doc->{category_status} = $p{category_status} if $p{category_status};

    # create/update mongo doc
    mdb->topic->update({ mid=>"$doc->{mid}" }, $doc, { upsert=>1 });
}

sub deal_with_images{
    #params:  topic_mid, field
    my ($self, $params ) = @_;
    my $topic_mid = $params->{topic_mid};
    my $field = $params->{field};
    
    my @imgs;
    
    # TODO falta bucle de todos los campos HTMLEditor
    #_debug $data->{description};
    if( length $topic_mid ) {
        my @img_current_ids;
        #for my $img ( $data->{description} =~ m{"/topic/img/(.+?)"}g ) {   # /topic/img/id
        for my $img ( $field =~ m{"/topic/img/(.+?)"}g ) {   # /topic/img/id
            push @img_current_ids, $img;
        }
        if( @img_current_ids ) {
            DB->BaliTopicImage->search({ topic_mid=>$topic_mid, -not => { id_hash=>{ -in => \@img_current_ids } } })->delete;
        } else {
            DB->BaliTopicImage->search({ topic_mid=>$topic_mid })->delete;
        }
    }
    
    #_debug $field;
    ###for my $img ( $data->{description} =~ m{<img src="data:(.*?)"/?>}g ) {   # image/png;base64,xxxxxx
    for my $img ( $field =~ m{<img src="data:(.*?)"/?>}g ) {   # image/png;base64,xxxxxx
        my ($ct,$enc,$img_data) = ( $img =~ /^(\S+);(\S+),(.*)$/ );
        $img_data = from_base64( $img_data );
        _error "IMG_DATA LEN=" . length( $img_data );
        my $row = { topic_mid=>$topic_mid, img_data=>$img_data, content_type=>$ct };
        $row->{topic_mid} = $topic_mid if length $topic_mid;
        my $img_row = DB->BaliTopicImage->create( $row );
        push @imgs, $img_row; 
        my $img_id = $img_row->id;
        my $id_hash = _md5( join(',',$img_id,_nowstamp) ); 
        $img_row->update({ id_hash => $id_hash });
        #$data->{description} =~ s{<img src="data:image/png;base64,(.*?)">}{<img class="bali-topic-editor-image" src="/topic/img/$id_hash">};
        $field =~ s{<img src="data:image/png;base64,(.*?)">}{<img class="bali-topic-editor-image" src="/topic/img/$id_hash">};
    }
    
    return $field;
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

sub set_cal {
    my ($self, $rs_topic, $cal_data, $user, $id_field ) = @_;
    my $mid = $rs_topic->mid;
    DB->BaliMasterCal->search({ mid=>$mid, rel_field=>$id_field })->delete;
   
    for my $row ( _array( $cal_data ) ) {
        $row->{rel_field} = $id_field;
        for( qw/start_date end_date plan_start_date plan_end_date/ ) {
            $row->{$_} =~ s/T/ /g if defined $row->{$_}; 
        }
        $row->{mid} = $mid; 
        DB->BaliMasterCal->create( $row );
    }
}

sub set_topics {
    my ($self, $rs_topic, $topics, $user, $id_field ) = @_;
    my @all_topics = ();
    
    # related topics
    my @new_topics = map { split /,/, $_ } _array( $topics ) ;
    my @old_topics = map {$_->{to_mid}} DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_type => 'topic_topic', rel_field => $id_field})->hashref->all;
    
    # no diferences, get out
    return if !array_diff(@new_topics, @old_topics);

    my @projects = map {$_->{mid}} $rs_topic->projects->hashref->all;
    my $notify = {
        category        => $rs_topic->id_category,
        category_status => $rs_topic->id_category_status,
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;
        
    if( @new_topics ) {
        if(@old_topics){
            my $rs_old_topics = DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_field=>$id_field });
            $rs_old_topics->delete();
        }

        my $rel_seq = 1;  # oracle may resolve this with a seq, but sqlite doesn't
        for (@new_topics){
            DB->BaliMasterRel->update_or_create({from_mid => $rs_topic->mid, to_mid => $_, rel_type =>'topic_topic', rel_field => $id_field, rel_seq=>$rel_seq++ });
        }

        my $topics = join(',', @new_topics);
        
      

        event_new 'event.topic.modify_field' => { username      => $user,
                                            field               => _loc( 'attached topics' ),
                                            old_value           => '',
                                            new_value           => $topics,
                                            text_new            => '%1 modified topic: %2 ( %4 )',
                                           } => sub {
                            my $subject = _loc("Topic [%1] %2 updated", $rs_topic->mid, $rs_topic->title);

                            { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
        } ## end try
        => sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };

    } elsif( @old_topics ) {
        
        
        event_new 'event.topic.modify_field' => { username      => $user,
                                            field               => '',
                                            old_value           => '',
                                            new_value           => '',
                                            text_new            => '%1 deleted all attached topics of ' . $id_field ,
                                           } => sub {
                            my $subject = _loc("Topic [%1] %2 updated", $rs_topic->mid, $rs_topic->title);
            { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
        } ## end try
        => sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };

        #$rs_topic->set_topics( undef, { rel_type=>'topic_topic', rel_field => $id_field});
        my $rs_old_topics = DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_field => $id_field });
        $rs_old_topics->delete();
    }
}

sub set_cis {
    my ($self, $rs_topic, $cis, $user, $id_field, $meta ) = @_;

    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array($meta) ]->[0];

    my $rel_type = $field_meta->{rel_type} or _fail "Missing rel_type for field $id_field";

    # related topics
    my @new_cis = _array( $cis ) ;
    @new_cis  = split /,/, $new_cis[0] if $new_cis[0] =~ /,/ ;
    my @old_cis =
        map { $_->{to_mid} }
    DB->BaliMasterRel->search( { from_mid => $rs_topic->mid, rel_type => $rel_type } )
        ->hashref->all;

    my @del_cis = array_minus( @old_cis, @new_cis );
    my @add_cis = array_minus( @new_cis, @old_cis );

    if( @add_cis || @del_cis ) {
        my ($del_cis, $add_cis) = ( '', '' );
        if( @del_cis ) {
            DB->BaliMasterRel->search( { from_mid => $rs_topic->mid, to_mid=>\@del_cis, rel_type => $rel_type, rel_field => $id_field } )
                ->delete;
            $del_cis = join(',', map { Baseliner::CI->new($_)->name . '[-]' } @del_cis );
        }
        if( @add_cis ) {
            DB->BaliMasterRel->create({ from_mid => $rs_topic->mid, to_mid=>$_, rel_type => $rel_type, rel_field => $id_field } )
                for @add_cis;
            $add_cis = join(',', map { Baseliner::CI->new($_)->name . '[+]' } @add_cis );
        }
        
        my @projects = map {$_->{mid}} $rs_topic->projects->hashref->all;
        my $notify = {
            category        => $rs_topic->id_category,
            category_status => $rs_topic->id_category_status,
            field           => $id_field
        };
        $notify->{project} = \@projects if @projects;
        
        event_new 'event.topic.modify_field' => {
            username  => $user,
            field     => _loc( $field_meta->{field_msg} // $field_meta->{name_field} // _loc('attached cis') ),
            old_value => $del_cis,
            new_value => join(',', grep { length } $add_cis, $del_cis ),
            text_new  => ( $field_meta->{modify_text_new} // '%1 modified topic (%2): %4 ' ),
        } => sub {
            my $subject = _loc("Topic [%1] %2 updated", $rs_topic->mid, $rs_topic->title);
            { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }    # to the event
        } => sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };
    }
}

sub set_revisions {
    my ($self, $rs_topic, $revisions, $user, $id_field  ) = @_;
    
    # related topics
    my @new_revisions = _array( $revisions ) ;
    my @old_revisions = map {$_->{to_mid}} DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_type => 'topic_revision'})->hashref->all;    
   
    my @projects = map {$_->{mid}} $rs_topic->projects->hashref->all;  
    my $notify = {
        category        => $rs_topic->id_category,
        category_status => $rs_topic->id_category_status,
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;
            
    if ( array_diff(@new_revisions, @old_revisions) ) {
        if( @new_revisions ) {
            @new_revisions  = split /,/, $new_revisions[0] if $new_revisions[0] =~ /,/ ;
            my @rs_revs = Baseliner->model('Baseliner::BaliMaster')->search({mid =>\@new_revisions});
            $rs_topic->set_revisions( \@rs_revs, { rel_type=>'topic_revision', rel_field => $id_field});
            
            my $revisions = join(',', map { Baseliner::CI->new($_->mid)->load->{name}} @rs_revs);
    
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached revisions' ),
                                                old_value      => '',
                                                new_value  => $revisions,
                                                text_new      => '%1 modified topic: %2 ( %4 )',
                                               } => sub {
                                                my $subject = _loc("Topic [%1] %2 updated.  New revisions", $rs_topic->mid, $rs_topic->title);

                { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
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
                                                my $subject = _loc("Topic [%1] %2 updated.  All revisions removed", $rs_topic->mid, $rs_topic->title);
                { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
            my $rs_old_revisions = DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_type => 'topic_revision' });
            $rs_old_revisions->delete(); 
            #$rs_topic->set_revisions( undef, { rel_type=>'topic_revision'});
            #$rs_topic->revisions->delete;
        }
    }
}

sub set_release {
    my ($self, $rs_topic, $release, $user, $id_field, $meta  ) = @_;
    
    my @release_meta = grep { $_->{id_field} eq $id_field } _array $meta;

    my $release_field = $release_meta[0]->{release_field} // 'undef';

    my $topic_mid = $rs_topic->mid;
    cache_topic_remove($topic_mid);

    my $where = { is_release => 1, rel_type=>'topic_topic', to_mid=> $topic_mid };
    $where->{rel_field} = $release_field if $release_field;
    my $release_row = Baseliner->model('Baseliner::BaliTopic')->search(
                            $where,
                            { join=>['categories','children','master'], select=>['mid','title'] }
                            )->first;
    my $old_release = '';
    my $old_release_name = '';
    if($release_row) {
        $old_release = $release_row->mid;
        $old_release_name = $release_row->title;
        #my $rs = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => {in => $release_row->mid}, to_mid=>$topic_mid })->delete;
    }        
        
    my $new_release = $release;

    my @projects = map {$_->{mid}} $rs_topic->projects->hashref->all;
    my $notify = {
        category        => $rs_topic->id_category,
        category_status => $rs_topic->id_category_status,
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;

    # check if arrays contain same members
    if ( $new_release ne $old_release ) {
        if($release_row){
            my $rs = DB->BaliMasterRel->search({from_mid => $old_release, to_mid=>$topic_mid, rel_field => $release_field})->delete;
        }
        # release
        if( $new_release ) {
            
            my $row_release = Baseliner->model('Baseliner::BaliTopic')->find( $new_release );
            my $topic_row = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid );
            $row_release->add_to_topics( $topic_row, { rel_type=>'topic_topic', rel_field => $release_field} );
            
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => $id_field,
                                                old_value      => $old_release_name,
                                                new_value  => $row_release->title,
                                                text_new      => '%1 modified topic: changed release to %4',
                                               } => sub {
                                                my $subject = _loc("Topic [%1] %2 updated.  Release changed to %3", $rs_topic->mid, $rs_topic->title, $row_release->title);
                { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
            
        }else{
            my $rs = DB->BaliMasterRel->search({from_mid => $old_release, to_mid=>$topic_mid })->delete;
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => $id_field,
                                                old_value      => $old_release_name,
                                                new_value  => '',
                                                text_new      => '%1 deleted release %3',
                                               } => sub {
                                                my $subject = _loc("Topic [%1] %2 updated.  Removed from release %3", $rs_topic->mid, $rs_topic->title, $old_release_name);

                { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify}   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };  
        }
    }
}

sub set_projects {
    my ($self, $rs_topic, $projects, $user, $id_field ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my @new_projects = sort { $a <=> $b } _array( $projects ) ;

    #my @old_projects = map {$_->{mid}} Baseliner->model('Baseliner::BaliTopic')->find(  $topic_mid )->projects->search( {rel_field => $id_field}, { order_by => { '-asc' => ['mid'] }} )->hashref->all;
    
    # for safety with legacy, reassign previous unassigned projects (normally from drag-drop
    DB->BaliMasterRel->search({ from_mid=>$topic_mid, rel_type=>'topic_project', rel_field=>undef })->update({ rel_field=>$id_field });

    my @old_projects =  map { $_->{mid} } Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )->
                projects->search( {rel_field => $id_field }, { select => ['mid'], order_by => { '-asc' => ['mid'] }} )->hashref->all;

    my @projects = map {$_->{mid}} $rs_topic->projects->hashref->all;
    my $notify = {
        category        => $rs_topic->id_category,
        category_status => $rs_topic->id_category_status,
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;
    
    # check if arrays contain same members
    if ( array_diff(@new_projects, @old_projects) ) {
        my $del_projects = DB->BaliMasterRel->search({from_mid => $topic_mid, rel_type => 'topic_project', rel_field => $id_field})->delete;
        
        # projects
        if (@new_projects){
            my @name_projects;
            my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({mid =>\@new_projects});
            while( my $project = $rs_projects->next){
                push @name_projects,  $project->name;
                $rs_topic->add_to_projects( $project, { rel_type=>'topic_project', rel_field => $id_field } );
            }
            
            my $projects = join(',', @name_projects);
    
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached projects' ),
                                                old_value      => '',
                                                new_value  => $projects,
                                                text_new      => '%1 modified topic: %2 ( %4 )',
                                               } => sub {
                                                my $subject = _loc("Topic [%1] %2 updated.  Attached projects (%3)", $rs_topic->mid, $rs_topic->title, $projects);
                { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
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
                                                my $subject = _loc("Topic [%1] %2 updated.  All projects removed", $rs_topic->mid );
                { mid => $rs_topic->mid, topic => $rs_topic->title, subject => $subject, notify => $notify }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };              
        }
    }
}

sub set_users{
    my ($self, $rs_topic, $users, $user, $id_field ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my @new_users = _array( $users ) ;
    my @old_users = map {$_->{to_mid}} DB->BaliMasterRel->search( {from_mid => $topic_mid, rel_type => 'topic_users', rel_field=>$id_field })->hashref->all;

    my @projects = map {$_->{mid}} $rs_topic->projects->hashref->all;
    my $notify = {
        category        => $rs_topic->id_category,
        category_status => $rs_topic->id_category_status,
        field           => $id_field
    };
    $notify->{project} = \@projects if @projects;
    
    # check if arrays contain same members
    if ( array_diff(@new_users, @old_users) ) {
        my $del_users =  DB->BaliMasterRel->search( {from_mid => $topic_mid, rel_type => 'topic_users', rel_field=>$id_field })->delete;
        # users
        if (@new_users){
            my @name_users;
            my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({mid =>\@new_users});
            while(my $user = $rs_users->next){
                push @name_users,  $user->username;
                $rs_topic->add_to_users( $user, { rel_type=>'topic_users', rel_field=>$id_field });
            }

            my $users = join(',', @name_users);
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached users' ),
                                                old_value      => '',
                                                new_value  => $users,
                                                text_new      => '%1 modified topic: %2 ( %4 )',
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title, notify => $notify }   # to the event
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
                { mid => $rs_topic->mid, topic => $rs_topic->title, notify => $notify }   # to the event
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
    my $order = delete $param{order};
    
    my ($dir, $sort) = ( $order->{dir}, $order->{sort} );
    $dir ||= 'asc';
    $sort ||= 'name';
    
    my $re_action;

    if ( $type eq 'view') {
        $re_action = qr/^action\.topics\.(.*?)\.(view|edit|create)$/;
    } elsif ($type eq 'edit') {
        $re_action = qr/^action\.topics\.(.*?)\.(edit|create)$/;
    } elsif ($type eq 'create') {
        $re_action = qr/^action\.topics\.(.*?)\.(create)$/;
    } else {
        $re_action = qr/^action\.topics\.(.*?)\.(delete)$/;
    }

    my @permission_categories;
    my @categories  = Baseliner->model('Baseliner::BaliTopicCategories')->search(undef, { order_by => { "-$dir" => ["$sort" ] }})->hashref->all;

    if ( Baseliner->model('Permissions')->is_root( $username) ) {
        return @categories;
    }
    
    push @permission_categories, _unique map { 
        $_ =~ $re_action;
        $1;
    } Baseliner->model('Permissions')->user_actions_list( username => $username, action => $re_action);
    
    my %granted_categories = map { $_ => 1 } @permission_categories;
    @categories = grep { $granted_categories{_name_to_id( $_->{name} )}} @categories;

    return @categories;
}

# Global search

with 'Baseliner::Role::Search';

sub search_provider_name { 'Topics' };
sub search_provider_type { 'Topic' };
sub search_query {
    my ($self, %p ) = @_;
    my ($cnt, @rows ) =  $self->topics_for_user({ username=>$p{username}, limit=>$p{limit} // 1000, query=>$p{query} });
    my @mids = map { $_->{topic_mid} } @rows;
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
            qw/category_name projects 
                assignee file_name category_status_name 
                labels modified_on modified_by created_on created_by 
                references_out referenced_in cis_out cis_in/;  # consider put references in separate, lower priority field
        push @text, _loc('Release') if $r->{is_release};
        push @text, _loc('Changeset') if $r->{is_changeset};
        my $info = join(', ',@text);
        my $desc = _strip_html( sprintf "%s %s", ($r->{description} // ''), ($r->{text} // '') );
        if( length $desc ) {
            $desc = _utf8 $desc;  # strip html messes up utf8
            $desc =~ s/[^\w\s]//g; 
            #$desc =~ s/[^\x{21}-\x{7E}\s\t\n\r]//g; 
        }
        +{
            title => sprintf( '%s', $_->{title} ),
            text  => $desc,
            info  => $info,
            url   => [ $_->{topic_mid}, $_->{topic_name}, $_->{category_color} ],
            type  => 'topic',
            mid   => $r->{topic_mid},
            id    => $r->{topic_mid},
        }
    } @rows;
}

sub getAction {
    my ( $self, $type ) = @_;
    my $action;
    given ($type) {
        when ('I') { $action = 'New' }
        when ('F') { $action = 'Ok' }
        when ('FC') { $action = 'Fail' }
        when ('G') {$action = 'Processing'}
        default {$action = 'none'}
    }
    return $action
}

sub user_workflow {
    my ( $self, $username ) = @_;
    my @rows = Baseliner->model('Permissions')->is_root( $username ) 
#        ? DB->BaliTopicCategoriesAdmin->search(undef, { select=>['id_status_to', 'id_status_from', 'id_category'], distinct=>1 })->hashref->all
        ? root_workflow()
        : DB->BaliTopicCategoriesAdmin->search({username => $username}, { join=>'user_role' })->hashref->all;
    return @rows;
}

   # my @all_to_status = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
   #      $where,
   #      {   join     => [ 'roles', 'statuses_to', 'statuses_from' ],
   #          distinct => 1,
   #          +select => [ 'id_status_from', 'statuses_from.name', 'statuses_from.bl', 'id_status_to', 'statuses_to.name', 'statuses_to.type', 'statuses_to.bl', 'statuses_to.description', 'id_category', 'job_type' ],
   #          +as     => [ 'id_status_from', 'status_name_from', 'status_bl_from', 'id_status',    'status_name', 'status_type', 'status_bl', 'status_description', 'id_category', 'job_type' ]
   #      }
   #  )->hashref->all;

sub root_workflow {
    my @categories = DB->BaliTopicCategories->search()->hashref->all;
    my @wf;

    for my $cat ( @categories ) {
      my @stats = DB->BaliTopicCategoriesStatus->search( { id_category => $cat->{id} },{ join => ['status'], select => ['id_status','id_category','status.name','status.bl']} )->hashref->all;
      
      map { 
        my $from = $_->{id_status};
        my $from_name = $_->{status}->{name};
        map { 
            push @wf, { 
                id_status_from => $from, 
                status_name_from => $from_name,
                id_status => $_->{id_status},
                id_status_to => $_->{id_status},
                status_name => $_->{status}->{name},
                status_bl => $_->{status}->{bl},
                id_category => $cat->{id},
                seq => $_->{seq}
            }     
        } @stats 
      } @stats;
    };

    @wf;    
}

sub list_posts {
    my ($self, %p) = @_;
    my $mid = $p{mid};

    my $rs = DB->BaliTopic->find( $mid )
        ->posts->search( undef, { order_by => { '-desc' => 'created_on' } } );
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
    return \@rows;
}
sub find_status_name {
    my ($self, $id_status ) = @_;
    [ map {$_->{name}} DB->BaliTopicStatus->search({id =>$id_status},{select=>'name'})->hashref->first ]->[0];
}

sub cache_topic_remove {
    my ($self, $topic_mid ) = @_;
    # my own first
    Baseliner->cache_remove( qr/:$topic_mid:/ );
    # refresh cache for related stuff 
    if ($topic_mid && $topic_mid ne -1) {    
        for my $rel ( 
            map { +{mid=>$_->{mid}, type=>$_->{_edge}{rel_type} } } 
            _ci( $topic_mid )->related( depth=>1 ) ) 
        {
            my $rel_mid = $rel->{mid};
            #_debug "TOPIC CACHE REL remove :$rel_mid:";
            Baseliner->cache_remove( qr/:$rel_mid:/ );
        }
    };
}

sub change_status {
    my ($self, %p) = @_;
    my $mid = $p{mid} or _throw 'Missing parameter mid';
    $p{id_status} or _throw 'Missing parameter id_status';
    my $row = DB->BaliTopic->find( $mid );
    my $id_old_status = $p{id_old_status} || $row->id_category_status;
    my $status = $p{status} || $self->find_status_name($p{id_status});
    my $old_status = $p{old_status} || $self->find_status_name($id_old_status);
    my $callback = $p{callback};
    event_new 'event.topic.change_status'
        => { mid => $mid, username => $p{username}, old_status => $old_status, id_old_status=> $id_old_status, id_status=>$p{id_status}, status => $status }
        => sub {
            # should I change the status?
            if( $p{change} ) {
                
                _fail( _loc('Id not found: %1', $mid) ) unless $row;
                _fail _loc "Current topic status '%1' does not match the real status '%2'. Please refresh.", $row->status->name, $old_status if $row->id_category_status != $id_old_status;
                # XXX check workflow for user
                # change and cleanup
                $row->update({ id_category_status => $p{id_status} });
                $self->cache_topic_remove( $mid );
            }
            # callback, if any
            $callback->() if ref $callback eq 'CODE';
            my @projects = map {$_->{mid}} $row->projects->hashref->all;
            my @users = $self->get_users_friend(id_category => $row->id_category, id_status => $p{id_status}, projects => \@projects);
            
            ###my @roles = map { $_->{id_role} }
            ###            DB->BaliTopicCategoriesAdmin->search(   {id_category => $row->id_category, id_status_from => $p{id_status}}, 
            ###                                                    {select => 'id_role', group_by=> 'id_role'})->hashref->all;
            ###           
            ###if (@roles){
            ###    @users = Baseliner->model('Users')->get_users_from_mid_roles( roles => \@roles );
            ###}
            
            my $subject = _loc("Topic [%1] %2.  Status changed to %3", $mid, $row->title, $self->find_status_name($p{id_status}));
            +{ mid => $mid, title => $row->title, notify_default => \@users, subject => $subject } ;       
        } 
        => sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };                    
}

sub get_users_friend {
    my ($self, %p) = @_;

    my @users;
    my @projects = _array $p{projects};
    my @roles = map { $_->{id_role} }
                DB->BaliTopicCategoriesAdmin->search(   {id_category => $p{id_category}, id_status_from => $p{id_status}}, 
                                                        {select => 'id_role', group_by=> 'id_role'})->hashref->all;
    if (@roles){
        @users = Baseliner->model('Users')->get_users_from_mid_roles( roles => \@roles, projects => \@projects );
    }
    return @users
}

sub check_fields_required {
    my ($self, %p) = @_;
    my $mid = $p{mid} or _throw 'Missing parameter mid';
    my $username = $p{username} or _throw 'Missing parameter username';
    
    my $is_root = Baseliner->model('Permissions')->is_root( $username );
    my $isValid = 1;
    my @fields_required = ();
    my $field_name;
    if (!$is_root){
        if($mid != -1){
            my $meta = Baseliner->model('Topic')->get_meta( $mid );
            my %fields_required =  map { $_->{bd_field} => $_->{name_field} } grep { $_->{allowBlank} && $_->{allowBlank} eq 'false' && $_->{origin} ne 'system' } _array( $meta );
            my $data = Baseliner->model('Topic')->get_data( $meta, $mid );  
            
            for my $field ( keys %fields_required){
                next if !Baseliner->model('Permissions')->user_has_action( 
                    username => $username, 
                    action => 'action.topicsfield.'._name_to_id($data->{name_category}).'.'.$field.'.'._name_to_id($data->{name_status}).'.write'
                );
                my $v = $data->{$field};
                $isValid = (ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : defined $v && $v ne '' ) ? 1 : 0;
                if($p{data}){
                    $v = $p{data}->{$field};
                    $isValid = (ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : defined $v && $v ne '' ) ? 1 : 0;                
                }
                
                push @fields_required , $fields_required{$field} if !$isValid;
            }
        }else{
            my $data = $p{data} or _throw 'Missing parameter data';
            my $meta = Baseliner->model('Topic')->get_meta(undef, $data->{category} );
            my $category = DB->BaliTopicCategories->find($data->{category});
            my $status = DB->BaliTopicStatus->find($data->{status_new});
            
            my %fields_required =  map { $_->{bd_field} => $_->{name_field} } grep { $_->{allowBlank} && $_->{allowBlank} eq 'false' && $_->{origin} ne 'system' } _array( $meta );
            for my $field ( keys %fields_required){
                next if !Baseliner->model('Permissions')->user_has_action( 
                    username => $username, 
                    action => 'action.topicsfield.'._name_to_id($category->name).'.'.$field.'.'._name_to_id($status->name).'.write'
                );
                my $v = $data->{$field};
                $isValid = (ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : defined $v && $v ne '' ) ? 1 : 0;
                
                push @fields_required , $fields_required{$field} if !$isValid;
            }            
        }
    }
    return ($isValid, @fields_required);
}

1;


