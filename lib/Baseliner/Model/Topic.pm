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
    text => '%1 posted a comment: %3',
    description => 'User posted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
};

register 'event.post.delete' => {
    text => '%1 deleted a comment: %3',
    description => 'User deleted a comment',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
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
    vars => ['username', 'category', 'ts'],
    notify => {
        scope => ['project', 'category', 'category_status'],
    },
};

register 'event.topic.modify' => {
    text => '%1 modified topic',
    description => 'User modified a topic',
    vars => ['username', 'topic_name', 'ts'],
    level => 1,
};


register 'event.topic.modify_field' => {
    text => '%1 modified topic %2 from %3 to %4',
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
            my $brk = sub { [ $_[0] =~ m{(\w+)}gs ] };
            my $d =Algorithm::Diff::XS::sdiff( $brk->($vars[2]), $brk->($vars[3]), );
            my @diff;
            my @bef;
            my @aft;
            for my $ix ( 0..$#{ $d } ) {
                my ($st,$bef,$aft) = @{ $d->[$ix] };
                unless( $st eq 'u' ) {
                    push @bef, "<code>$bef</code>" if length $bef;
                    push @aft, "<code>$aft</code>" if length $aft;
                }
            }
            if( @bef || @aft ) {
                $vars[2] = @bef ? join( ' ', @bef ) : '<code>-</code>';
                $vars[3] = @aft ? join( ' ', @aft ) : '<code>-</code>';
            }
        }
        return ($txt, @vars);
    }      
};

register 'event.topic.change_status' => {
    text => '%1 changed topic status from %2 to %3',
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
            my $msg_edit = _loc('Can not edit the field');
            my $msg_view = _loc('Can not view the field');
            my $msg_in_category = _loc('in the category');
            my $msg_for_status = _loc('for the status');                
            for my $field (_array $meta){
                if ($field->{fields}) {
                	my @fields_form = _array $field->{fields};
                    
                    for my $field_form (@fields_form){
                        for my $status (@statuses){
                            my $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' 
                                    . _name_to_id($field->{name_field}) . '.' . _name_to_id($field_form->{id_field}) . '.' . _name_to_id($status->{name}) . '.write';
                            my $description = $msg_edit . ' ' . lc $field_form->{id_field} . ' ' . $msg_in_category . ' ' . lc $category->{name} . ' ' . $msg_for_status . ' ' . lc $status->{name};
                            
                            $actions_category_fields{$id_action} = { name => $id_action, description => $description };
                            
                            $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' 
                                    . _name_to_id($field->{name_field}) . '.' . _name_to_id($field_form->{id_field}) . '.' . _name_to_id($status->{name}) . '.read';
                            $description = $msg_view . ' ' . lc $field_form->{id_field} . ' ' . $msg_in_category . ' ' . lc $category->{name} . ' ' . $msg_for_status . ' ' . lc $status->{name};
                            
                            $actions_category_fields{$id_action} = { name => $id_action, description => $description };
                        }                    
                    }
                }
                else{

                    for my $status (@statuses){
                        my $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' . _name_to_id($field->{name_field}) . '.' . _name_to_id($status->{name}) . '.write';
                        my $description = $msg_edit . ' ' . lc $field->{name_field} . ' ' . $msg_in_category . ' ' . lc $category->{name} . ' ' . $msg_for_status . ' ' . lc $status->{name};
                        
                        $actions_category_fields{$id_action} = { name => $id_action, description => $description };
                        
                        $id_action = 'action.topicsfield.' . _name_to_id($category->{name}) . '.' . _name_to_id($field->{name_field}) . '.' . _name_to_id($status->{name}) . '.read';
                        $description = $msg_view . ' ' . lc $field->{name_field} . ' ' . $msg_in_category . ' ' . lc $category->{name} . ' ' . $msg_for_status . ' ' . lc $status->{name};
                        
                        $actions_category_fields{$id_action} = { name => $id_action, description => $description };
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
    
    $query and $where = query_sql_build( query=>$query, fields=>{
        map { $_ => "me.$_" } qw/
        topic_mid 
        title
        created_on
        created_by
        status
        numcomment
        category_id
        category_name
        category_status_id
        category_status_name        
        category_status_seq
        priority_id
        priority_name
        response_time_min
        expr_response_time
        deadline_min
        expr_deadline
        category_color
        label_id
        label_name
        label_color
        project_id
        project_name
        moniker
        cis_out
        cis_in
        references
        referenced_in
        file_name
        description
        text
        progress
        modified_on
        modified_by        
        /
    });

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
    
    #Filtros especificos para GDI
    if( $p->{typeApplication} && $p->{typeApplication} eq 'gdi'){
        my @usuarios_n1;
        if (!$perm->is_root( $username )){
            if(!Baseliner->model('Permissions')->user_has_action( username => $username, action => 'action.GDI.admin')){
                my $usuario_gdi = Baseliner->model('Baseliner::BaliMaster')->search({-or => [name => uc $username, name => lc $username], collection => 'UsuarioGDI'})->hashref->first;
                if( my $cached = Baseliner->cache_get( $usuario_gdi->{mid} ) ) {
                    @usuarios_n1 = @$cached;
                     
                } else {
                    #my @usuarios_n1 = map {$_->{name}} _ci( $usuario_gdi->{mid} )->parents( depth=>-1, mode=>'flat' );
                    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
                    my $sSQL;
                    $sSQL  = 'SELECT MID,  A.NAME AS DNI FROM ';
                    $sSQL .= '(SELECT ROWNUM AS FILA, LEVEL AS NIVEL, FROM_MID FROM BALI_MASTER_REL A START WITH TO_MID = ? CONNECT BY PRIOR FROM_MID = TO_MID AND FROM_MID <> TO_MID) B ';
                    $sSQL .= 'LEFT JOIN BALI_MASTER A ON A.MID = B.FROM_MID';
                    @usuarios_n1 = map {$_->{dni}} $db->array_hash( $sSQL, $usuario_gdi->{mid} );            
                    Baseliner->cache_set( $usuario_gdi->{mid}, \@usuarios_n1 );
                }
                
                push (@usuarios_n1, $username);                
                $where->{'created_by'} = \@usuarios_n1;
                #$where->{'created_by'} = $username;
            }
        }
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
        my @not_in = map { abs $_ } grep { $_ < 0 } @categories;
        my @in = @not_in ? grep { $_ > 0 } @categories : @categories;
        if (@not_in && @in){
            $where->{'category_id'} = [{'not in' => \@not_in},{'in' => \@in}];    
        }else{
            if (@not_in){
                $where->{'category_id'} = {'not in' => \@not_in};
            }else{
                $where->{'category_id'} = \@in;
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

        #$where->{'category_status_id'} = \@statuses;
        
    }else {
        if (!$p->{clear_filter}){
            ##Filtramos por defecto los estados q puedo interactuar (workflow) y los que no tienen el tipo finalizado.        
            my %tmp;
            map { $tmp{$_->{id_status_from}} = 1 && $tmp{$_->{id_status_to}} = 1 } 
                $self->user_workflow( $username );
    
            my @status_ids = keys %tmp;
            $where->{'category_status_id'} = { -in=>\@status_ids };
            
            #$where->{'category_status_type'} = {'!=', 'F'};
            #Nueva funcionalidad (todos los tipos de estado que enpiezan por F son estado finalizado)
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
    my @mid_data = grep { defined } map { Baseliner->cache_get("topic:view:$_") } @mids; 
    my $mids_in_cache = { map { $_->{topic_mid} => 1 } @mid_data };
    my @db_mids = grep { !exists $mids_in_cache->{$_} } @mids; 
    _debug( "CACHE==============================> MIDS: @mids, DBMIDS: @db_mids, MIDS_IN_CACHE: " . join',',keys %$mids_in_cache );
    my @db_mid_data = DB->TopicView->search({ topic_mid=>{ -in =>\@db_mids  } })->hashref->all if @db_mids > 0;
    Baseliner->cache_set( "topic:view:".$_->{topic_mid}, $_ ) for @db_mid_data;
    @mid_data = ( @mid_data, @db_mid_data );

    my @rows;
    my %id_label;
    my (%cis_out, %cis_in );
    my (%references, %referenced_in );
    my %projects;
    my %projects_report;
    my %assignee;
    my %mid_data;
    
    # Controlar que categorias son editables.
    my %categories_edit = map { lc $_->{name} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $username, type => 'edit' );
    
    
    for (@mid_data) {
        my $mid = $_->{topic_mid};
        $mid_data{ $mid } = $_ unless exists $mid_data{ $_->{topic_mid} };
        $mid_data{ $mid }{is_closed} = $_->{status} eq 'C' ? \1 : \0;
        $mid_data{ $mid }{sw_edit} = 1 if exists $categories_edit{ lc $_->{category_name}};
        $_->{label_id}
            ? $id_label{ $mid }{ $_->{label_id} . ";" . $_->{label_name} . ";" . $_->{label_color} } = ()
            : $id_label{ $mid } = {};
        if( $_->{project_id} ) {
            $projects{ $mid }{ $_->{project_id} . ";" . $_->{project_name} } = ();
            $projects_report{ $mid }{ $_->{project_name} } = ();
        } else {
            $projects{ $mid } = {};
            $projects_report{ $mid } = {};
        }
        if( $_->{cis_out} ) {
            $cis_out{ $mid }{ $_->{cis_out} } = ();
        }
        if( $_->{cis_in} ) {
            $cis_in{ $mid }{ $_->{cis_in} } = ();
        }
        if( $_->{references} ) {
            $references{ $mid }{ $_->{references} } = ();
        }
        if( $_->{referenced_in} ) {
            $referenced_in{ $mid }{ $_->{referenced_in} } = ();
        }
        $assignee{ $mid }{ $_->{assignee} } = () if defined $_->{assignee};
    }
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
        push @rows, {
            %$data,
            topic_name => sprintf("%s #%d", $data->{category_name}, $mid),
            labels   => [ keys %{ $id_label{$mid} || {} } ],
            projects => [ keys %{ $projects{$mid} || {} } ],
            cis_out => [ keys %{ $cis_out{$mid} || {} } ],
            cis_in => [ keys %{ $cis_in{$mid} || {} } ],
            references => [ keys %{ $references{$mid} || {} } ],
            referenced_in => [ keys %{ $referenced_in{$mid} || {} } ],
            assignee => [ keys %{ $assignee{$mid} || {} } ],
            report_data => {
                projects => join( ', ', keys %{ $projects_report{$mid} || {} } )
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
    
    given ( $action ) {
        #Casos especiales, por ejemplo la aplicacion GDI
        my $form = $p->{form};
        $p->{_cis} = _decode_json( $p->{_cis} ) if $p->{_cis};

        when ( 'add' ) {
            given ( $form ){
                when ( 'gdi' ) {
                    my $numSolicitud = Baseliner->model( 'Baseliner::BaliTopicFieldsCustom' )->search({ name => 'gdi_perfil_dni', -or => [value => lc $p->{gdi_perfil_dni}, value => uc $p->{gdi_perfil_dni}] })->count;
                    $p->{title} = $p->{gdi_perfil_dni} . '.' . ++$numSolicitud;
                }
            }
            
            event_new 'event.topic.create' => { username=>$p->{username} } => sub {
                Baseliner->model('Baseliner')->txn_do(sub{
                    my $meta = $self->get_meta ($topic_mid , $p->{category});
                    my $topic = $self->save_data ($meta, undef, $p);
                    
                    $topic_mid    = $topic->mid;
                    $status = $topic->id_category_status;
                    $return = 'Topic added';
                    $category = { $topic->categories->get_columns };
                   { mid => $topic->mid, topic => $topic->title, , category=> $category->{name} }   # to the event
                });                   
            } 
            => sub { # catch
                _throw _loc( 'Error adding Topic: %1', shift() );
            }; # event_new
        } ## end when ( 'add' )
        when ( 'update' ) {
            given ( $form ){
                when ( 'gdi' ) {
                    my $custom_data = Baseliner->model( 'Baseliner::BaliTopicFieldsCustom' )->search({ topic_mid => $p->{topic_mid} });
                    $custom_data->delete;
                }
            }            
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
                
                $row = Baseliner->model( 'Baseliner::BaliTopicFieldsCustom' )->search({ topic_mid=>$topic_mid });
                $row->delete;
                
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
    return ( $return, $topic_mid, $status, $p->{title}, $category );
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
            +select => [ 'id_status_to', 'statuses_to.name', 'statuses_to.type', 'statuses_to.bl', 'statuses_to.description', 'id_category' ],
            +as     => [ 'id_status',    'status_name', 'status_type', 'status_bl', 'status_description', 'id_category' ]
        }
    )->hashref->all;

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
                field_order_html => 1
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
                relation    => 'categories'
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
        {
            id_field => 'dates',
            params   => {
                name_field  => 'dates',
                origin      => 'default',
                relation    => 'system',
                get_method  => 'get_dates',
                html        => $pathHTML . 'field_scheduling.html',
                field_order => 9999,
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

sub get_meta {
    my ($self, $topic_mid, $id_category) = @_;

    my $cached = Baseliner->cache_get( "topic:meta:$topic_mid");
    return $cached if $cached;

    my $id_cat =  $id_category
        // DB->BaliTopic->search({ mid=>$topic_mid }, { select=>'id_category' })->as_query;
        
    my @meta =
        sort { $a->{field_order} <=> $b->{field_order} }
        map  { 
            my $d = _load $_->{params_field};
            $d->{field_order} //= 1;
            $d
        }
        #grep { my $d = _load $_->{params_field};
        #       $d->{type} ne 'form'}
        
        DB->BaliTopicFieldsCategory->search( { id_category => { -in => $id_cat } } )->hashref->all;
    
    #my @form_fields =       map  { 
    #           my $d = _load $_->{params_field};
    #           $d->{field_order} //= 1;
    #           $d->{fields}
    #       }        
    #       
    #       grep { my $d = _load $_->{params_field};
    #              $d->{type} eq 'form'}
    #       DB->BaliTopicFieldsCategory->search( { id_category => { -in => 81 } } )->hashref->all;
    #
    #push @meta, @form_fields;                
    
    @meta = sort { $a->{field_order} <=> $b->{field_order} } @meta;

    Baseliner->cache_set( "topic:meta:$topic_mid", \@meta );
    
    return \@meta;
}

sub get_data {
    my ($self, $meta, $topic_mid, %opts ) = @_;
    
    my $data;
    if ($topic_mid){
        
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

        my @rels = DB->BaliMasterRel->search({ from_mid=>$topic_mid })->hashref->all;
        for my $rel ( @rels ) {
            next unless $rel->{rel_field};
            next unless exists $rel_fields{ $rel->{rel_field} };
            push @{ $data->{ $rel->{rel_field} } },  $rel->{to_mid};
        }
        
        foreach my $key  (keys %method_fields){
            my $method_get = $method_fields{ $key };
            $data->{ $key } =  $self->$method_get( $topic_mid, $key, $meta, %opts );
        }
        
        my @custom_fields = map { $_->{id_field} } grep { $_->{origin} eq 'custom' && !$_->{relation} } _array( $meta  );
        my %custom_data = ();
        # get data from value_clob if value is not available. 
        map { $custom_data{ $_->{name} } = $_->{value} ? $_->{value} : $_->{value_clob} }
            Baseliner->model('Baseliner::BaliTopicFieldsCustom')->search( { topic_mid => $topic_mid } )->hashref->all;
        
        push @custom_fields, map { map { $_->{id_field} } _array $_->{fields}; } grep { defined $_->{type} && $_->{type} eq 'form' } _array($meta);

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
    my ($self, $topic_mid, $id_field ) = @_;
    my @projects = Baseliner->model('Baseliner::BaliTopic')->find(  $topic_mid )->projects->search( {rel_field => $id_field}, { select=>['mid','name'], order_by => { '-asc' => ['mid'] }} )->hashref->all;
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
    my ($self, $topic_mid, $id_field, $meta, %opts) = @_;
    my $rs_rel_topic = Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )->topics->search( {rel_field => $id_field}, { order_by => { '-asc' => ['categories.name', 'mid'] }, prefetch=>['categories'] } );
    rs_hashref ( $rs_rel_topic );
    my @topics = $rs_rel_topic->all;
    @topics = Baseliner->model('Topic')->append_category( @topics );
    if( $opts{topic_child_data} ) {
        @topics = map {
            #my $meta = $self->get_meta( $_->{mid} );
            my $data = $self->get_data( undef, $_->{mid} ) ;
            $_->{description} //= $data->{description};
            $_->{name_status} //= $data->{name_status};
            $_->{data} //= $data;
            $_
        } @topics;
    }
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
    my ($self, $meta, $topic_mid, $data, %opts ) = @_;

    Baseliner->cache_remove( "topic:view:$topic_mid") if length $topic_mid;
    Baseliner->cache_remove( "topic:data:$topic_mid") if length $topic_mid;
    
    my @std_fields =
        map { +{ name => $_->{id_field}, column => $_->{bd_field}, method => $_->{set_method}, relation => $_->{relation} } }
        grep { $_->{origin} eq 'system' } _array($meta);
    
    my %row;
    my %description;
    my %old_value;
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
        } grep { $_->{type} eq 'form' } _array($meta);
    
    my $topic;
    my $moniker = delete $row{moniker};
    
    if (!$topic_mid){
        my $rstopic = master_new 'topic' => { name=>$data->{title}, moniker=>$moniker } => sub {
            $topic_mid = shift;

            #Defaults
            $row{ mid } = $topic_mid;
            $row{ created_by } = $data->{username};
            $row{ modified_by } = $data->{username};
            
            $topic = DB->BaliTopic->create( \%row );

            # update images
            for( @imgs ) {
                $_->update({ topic_mid => $topic_mid });
            }

        }        
        
    }else{
        $topic = DB->BaliTopic->find( $topic_mid, { prefetch =>['categories','status','priorities'] } );

        for my $field (keys %row){
            $old_value{$field} = $topic->$field,
            my $method = $relation{ $field };
            $old_text{$field} = $method ? try { $topic->$method->name } : $topic->$field,
        }
        $topic->modified_by( $data->{username} );
        $topic->update( \%row );
        _ci( $topic_mid )->update( moniker=>$moniker, name=>$row{title} );

        for my $field (keys %row){
            next if $field eq 'response_time_min' || $field eq 'expr_response_time';
            next if $field eq 'deadline_min' || $field eq 'expr_deadline';

            my $method = $relation{ $field };

            if ($row{$field} ne $old_value{$field}){
                if($field eq 'id_category_status'){
                    
                    my @projects = $topic->projects->hashref->all;
                    event_new 'event.topic.change_status'
                        #=> { username => $data->{username}, old_status => $old_text{$field}, status => $method ? $topic->$method->name : undef }
                        => { username => $data->{username}, old_status => $old_text{$field}, status => $method ? map {$_->{name}} DB->BaliTopicStatus->search({id => $row{$field}})->hashref->first : undef }
                        => sub {
                            # check if it's a CI update
                            my $status_new = DB->BaliTopicStatus->find( $row{id_category_status} );
                            my $ci_update = $status_new->ci_update;
                            if( $ci_update && ( my $cis = $data->{_cis} ) ) {
                                _debug $cis;
                                for my $ci ( _array $cis ) {
                                    my $ci_data = $ci->{ci_data} // { map { $_ => $data->{$_} } grep { length } _array( $ci->{ci_fields} // @custom_fields ) };
                                    my $ci_master = $ci->{ci_master} // $ci_data;
                                    _debug $ci_data;
                                    given( $ci->{ci_action} ) {
                                        when( 'create' ) {
                                            my $ci_class = $ci->{ci_class};
                                            $ci_class = 'BaselinerX::CI::' . $ci_class unless $ci_class =~ /^Baseliner/;
                                            $ci->{ci_mid} = $ci_class->save( %$ci_master, data=>$ci_data );
                                            $ci->{_ci_updated} = 1;
                                        }
                                        when( 'update' ) {
                                            _debug "ci update $ci->{ci_mid}";
                                            my $ci_mid = $ci->{ci_mid} // $ci_data->{ci_mid};
                                            #_ci( $ci->{ci_mid} )->save( %$ci_master, data=>$ci_data );
                                            _ci( $ci_mid )->save( %$ci_master, data=>$ci_data );
                                            $ci->{_ci_updated} = 1;
                                        }
                                        when( 'delete' ) {
                                            my $ci_mid = $ci->{ci_mid} // $ci_data->{ci_mid};
                                            _ci( $ci_mid )->save( %$ci_master, data=>$ci_data );
                                            DB->BaliMaster->find( $ci_mid )->delete; 
                                            $ci->{_ci_updated} = 1;
                                        }
                                        default {
                                            _throw _loc "Invalid ci action '%1' for mid '%2'", $ci->{ci_action}, $ci->{ci_mid};
                                        }
                                    }
                                }
                            }

                            { mid => $topic->mid, topic => $topic->title } 
                        } 
                        => sub {
                            _throw _loc( 'Error modifying Topic: %1', shift() );
                        };                    
                }else {
                    event_new 'event.topic.modify_field' => { username   => $data->{username},
                                                        field      => _loc ($description{ $field }),
                                                        old_value  => $old_text{$field},
                                                        new_value  => $method ? $topic->$method->name : $topic->$field,
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

    
    if( my $cis = $data->{_cis} ) {
        for my $ci ( _array $cis ) {
            if( length $ci->{ci_mid} && $ci->{ci_action} eq 'update' ) {
                DB->BaliMasterRel->update_or_create({ rel_type=>'ci_request', from_mid=>$ci->{ci_mid}, to_mid=>$topic->mid });
            }
        }
    }
     
    my %rel_fields = map { $_->{id_field} => $_->{set_method} }  grep { $_->{relation} eq 'system' } _array( $meta  );
    
    foreach my $id_field  (keys %rel_fields){
        if($rel_fields{$id_field}){
            my $meth = $rel_fields{$id_field};
            $self->$meth( $topic, $data->{$id_field}, $data->{username}, $id_field, $meta );
            #eval( '$self->' . $rel_fields{$id_field} . '( $topic, $data->{$id_field}, $data->{username}, $id_field, $meta )' );    
        }
    } 
     
    for( @custom_fields ) {
        if  (exists $data->{ $_ -> {name}} && $data->{ $_ -> {name}} ne '' ){

            $data->{ $_ -> {name}} = $self->deal_with_images({topic_mid => $topic_mid, field => $data->{ $_ -> {name}}});

            my $row = Baseliner->model('Baseliner::BaliTopicFieldsCustom')->search( {topic_mid=> $topic->mid, name => $_->{column}} )->first;
            my $record = {};
            $record->{topic_mid} = $topic->mid;
            $record->{name} = $_->{column};
            if ($_->{data}){ ##Cuando el tipo de dato es CLOB
                
            	$record->{value_clob} = $data->{ $_ -> {name}};
            	$record->{value} = ''; # cleanup old data, so that we read from clob 
            }else{
            	$record->{value} = $data->{ $_ -> {name}};
            	$record->{value_clob} = ''; # cleanup old data so we read from value
            }
            
            if(!$row){
                my $field_custom = Baseliner->model('Baseliner::BaliTopicFieldsCustom')->create($record);                 
            }
            else{
                my $modified = 0;
                my $old_value;
                if ($_->{data}){ ##Cuando el tipo de dato es CLOB
                    if ($row->value ne $data->{$_->{name}}){
                        $old_value = $row->value;
                        $modified = 1;    
                    }
                    $row->value_clob($data->{$_->{name}});
                    $row->value(''); # cleanup old data in case of change data: 1
                }else{
                    if ($row->value ne $data->{$_->{name}}){
                        $modified = 1;
                        $old_value = $row->value;
                    }
                    $row->value($data->{$_->{name}});
                    $row->value_clob('');   # cleanup old data in case of change data: 1
                }
                $row->update;
                
                if ( $modified ){
                    event_new 'event.topic.modify_field' => { username   => $data->{username},
                                                        field      => _loc ($_->{column}),
                                                        old_value  => $old_value,
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

sub set_topics {
    my ($self, $rs_topic, $topics, $user, $id_field ) = @_;
    my @all_topics = ();
    
    # related topics
    my @new_topics = map { split /,/, $_ } _array( $topics ) ;
    my @old_topics = map {$_->{to_mid}} DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_type => 'topic_topic', rel_field => $id_field})->hashref->all;
    
    # check if arrays contain same members
    if ( array_diff(@new_topics, @old_topics) ) {
        if( @new_topics ) {
            if(@old_topics){
                my $rs_old_topics = DB->BaliMasterRel->search({from_mid => $rs_topic->mid, to_mid => \@old_topics});
                $rs_old_topics->delete();
            }
            
            for (@new_topics){
                DB->BaliMasterRel->update_or_create({from_mid => $rs_topic->mid, to_mid => $_, rel_type =>'topic_topic', rel_field => $id_field });
            }
            
            my $topics = join(',', @new_topics);
    
            event_new 'event.topic.modify_field' => { username   => $user,
                                                field      => _loc( 'attached topics' ),
                                                old_value      => '',
                                                new_value  => $topics,
                                                text_new      => '%1 modified topic: %2 ( %4 )',
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
                                                text_new      => '%1 deleted all attached topics of ' . $id_field ,
                                               } => sub {
                { mid => $rs_topic->mid, topic => $rs_topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };

            #$rs_topic->set_topics( undef, { rel_type=>'topic_topic', rel_field => $id_field});
            my $rs_old_topics = DB->BaliMasterRel->search({from_mid => $rs_topic->mid, to_mid => \@old_topics});
            $rs_old_topics->delete();            
        }
    }
    
}

sub set_cis {
    my ($self, $rs_topic, $cis, $user, $id_field, $meta ) = @_;

    my $field_meta = [ grep { $_->{id_field} eq $id_field } _array($meta) ]->[0];

    my $rel_type = $field_meta->{rel_type} or _fail 'Missing rel_type';

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
            DB->BaliMasterRel->search( { from_mid => $rs_topic->mid, to_mid=>\@del_cis, rel_type => $rel_type } )
                ->delete;
            $del_cis = join(',', map { Baseliner::CI->new($_)->load->{name} . '[-]' } @del_cis );
        }
        if( @add_cis ) {
            DB->BaliMasterRel->create({ from_mid => $rs_topic->mid, to_mid=>$_, rel_type => $rel_type } )
                for @add_cis;
            $add_cis = join(',', map { Baseliner::CI->new($_)->load->{name} . '[+]' } @add_cis );
        }
        event_new 'event.topic.modify_field' => {
            username  => $user,
            field     => _loc( $field_meta->{field_msg} // $field_meta->{name_field} // _loc('attached cis') ),
            old_value => $del_cis,
            new_value => join(',', grep { length } $add_cis, $del_cis ),
            text_new  => ( $field_meta->{modify_text_new} // '%1 modified topic (%2): %4 ' ),
        } => sub {
            { mid => $rs_topic->mid, topic => $rs_topic->title }    # to the event
        } => sub {
            _throw _loc( 'Error modifying Topic: %1', shift() );
        };
    }
}

sub set_revisions {
    my ($self, $rs_topic, $revisions, $user ) = @_;
    
    # related topics
    my @new_revisions = _array( $revisions ) ;
    my @old_revisions = map {$_->{to_mid}} DB->BaliMasterRel->search({from_mid => $rs_topic->mid, rel_type => 'topic_revision'})->hashref->all;    
   
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
                                                text_new      => '%1 modified topic: %2 ( %4 )',
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
        #my $rs = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => {in => $release_row->mid}, to_mid=>$topic_mid })->delete;
    }        
        
    my @new_release = _array( $release ) ;

    # check if arrays contain same members
    if ( array_diff(@new_release, @old_release) ) {
        if($release_row){
            my $rs = DB->BaliMasterRel->search({from_mid => {in => $release_row->mid}, to_mid=>$topic_mid })->delete;
        }
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
            my $rs = DB->BaliMasterRel->search({from_mid => {in => $release_row->mid}, to_mid=>$topic_mid })->delete;
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
    my ($self, $rs_topic, $projects, $user, $id_field ) = @_;
    my $topic_mid = $rs_topic->mid;
    
    my @new_projects = _array( $projects ) ;

    #my @old_projects = map {$_->{mid}} Baseliner->model('Baseliner::BaliTopic')->find(  $topic_mid )->projects->search( {rel_field => $id_field}, { order_by => { '-asc' => ['mid'] }} )->hashref->all;
    my @old_projects =  Baseliner->model('Baseliner::BaliTopic')->find( $topic_mid )->
                projects->search( {rel_field => $id_field }, { select => ['mid'], order_by => { '-asc' => ['mid'] }} )->hashref->all;

    
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
    my @old_users = map {$_->{to_mid}} DB->BaliMasterRel->search( {from_mid => $topic_mid, rel_type => 'topic_users'})->hashref->all;

    # check if arrays contain same members
    if ( array_diff(@new_users, @old_users) ) {
        my $del_users =  DB->BaliMasterRel->search( {from_mid => $topic_mid, rel_type => 'topic_users'})->delete;
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
                                                text_new      => '%1 modified topic: %2 ( %4 )',
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
    
    my $re_action;

    if ( $type eq 'view') {
        $re_action = qr/^action\.topics\.(.*?)\.(view|edit|create)$/;
    } elsif ($type eq 'edit') {
        $re_action = qr/^action\.topics\.(.*?)\.(edit|create)$/;
    } else {
        $re_action = qr/^action\.topics\.(.*?)\.(create)$/;
    }

    my @permission_categories;
    my @categories  = Baseliner->model('Baseliner::BaliTopicCategories')->search()->hashref->all;

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
            qw/category_name projects 
                assignee file_name category_status_name 
                labels modified_on modified_by created_on created_by 
                references referenced_in cis_out cis_in/;  # consider put references in separate, lower priority field
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
            title => sprintf( '%s - %s', $_->{topic_name}, $_->{title} ),
            text  => $desc,
            info  => $info,
            url   => [ $_->{topic_mid}, $_->{topic_name}, $_->{category_color} ],
            type  => 'topic',
            mid   => $r->{topic_mid},
            id    => $r->{topic_mid},
        }
    } _array( $json->{data} );
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
        ? DB->BaliTopicCategoriesAdmin->search(undef, { select=>['id_status_to', 'id_status_from'], distinct=>1 })->hashref->all
        : DB->BaliTopicCategoriesAdmin->search({username => $username}, { join=>'user_role' })->hashref->all;
    return @rows;
}

1;
