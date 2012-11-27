package Baseliner::Controller::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

my $post_filter = sub {
        my ($text, @vars ) = @_;
        $vars[2] =~ s{\n|\r|<(.+?)>}{ }gs;
        $vars[0] = "<b>$vars[0]</b>";  # bold username
        $vars[2] = "<quote>$vars[2]</quote>";  # quote post
        ($text,@vars);
    };
register 'event.post.create' => {
    text => '%1 posted a comment on %2: %3',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
};

register 'event.post.delete' => {
    text => '%1 deleted a comment on %2: %3',
    vars => ['username', 'ts', 'post'],
    filter => $post_filter,
};

register 'event.file.create' => {
    text => '%1 posted a file on %2: %3',
    vars => ['username', 'ts', 'filename'],
};

register 'event.file.attach' => {
    text => '%1 attached %2 on %3',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.file_remove' => {
    text => '%1 removed %2 on %3',
    vars => ['username', 'filename', 'ts'],
};

register 'event.topic.create' => {
    text => '%1 created topic on %2',
    vars => ['username', 'ts'],
};

register 'event.topic.modify' => {
    text => '%1 modified topic on %3',
    vars => ['username', 'field', 'ts'],
};

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  
register 'menu.tools.topic' => {
    label    => 'Topics',
    title    => _loc ('Topics'),
    action   => 'action.topics.view',
    url_comp => '/topic/grid',
    icon     => '/static/images/icons/topic.png',
    tab_icon => '/static/images/icons/topic.png'
};

register 'action.topics.admin' => { name=>'Admin topics' };

# XXX
map {
    register "action.topics.view." . lc($_) => { name=>"Ver $_" };
    register "action.topics.edit." . lc($_) => { name=>"Editar $_" };
} (qw/Cambio Tarea Release Peticion Incidencia/, 'Caso de Prueba', 'Plan de Pruebas', 'Funcionalidad');

sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $c->stash->{id_project} = $p->{id_project}; 
    $c->stash->{query_id} = $p->{query};
    $c->stash->{category_id} = $p->{category_id};
    $c->stash->{template} = '/comp/topic/topic_grid.js';
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $username = $c->username;
    my $perm = $c->model('Permissions');
    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt) = ( @{$p}{qw/start limit query query_id dir sort/}, 0 );
    $dir ||= 'desc';
    $start||= 0;
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    my $where = {};
    my $query_limit = 300;
    
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
        file_name
        text
        progress
        /
    });

    my ($select,$order_by, $as, $group_by);
    if( $sort eq 'category_status_name' ) {
        $sort = 'category_status_seq'; # status orderby sequence
        ($select, $order_by, $as, $group_by) = (
            [{ distinct=>'me.topic_mid'} , 'category_status_seq', 'category_status_name' ],
            [{ "-$dir" => 'category_status_seq'},{ "-$dir" => 'category_status_name'}, {-desc => 'me.topic_mid' }],
            ['topic_mid', 'category_status_seq', 'category_status_name' ],
            ['topic_mid', 'category_status_seq', 'category_status_name' ]
        );
    } else {
        # sort fixups 
        $sort eq 'topic_name' and $sort = ''; # fake column, use mid instead
        $sort eq 'topic_mid' and $sort = '';
        
        ($select,$order_by, $as, $group_by) = $sort
        ? ([{ distinct=>'me.topic_mid'} ,$sort], [{ "-$dir" => $sort}, {-desc => 'me.topic_mid' }], ['topic_mid', $sort], ['topic_mid', $sort] )
        : ([{ distinct=>'me.topic_mid'}], [{ "-$dir" => 'me.topic_mid' }, { "-$dir" => "me.topic_mid" } ], ['topic_mid'], ['topic_mid'] );
    }

    #Filtramos por las aplicaciones a las que tenemos permisos.
    if( $username && ! $perm->is_root( $username )){
        my @user_apps = $perm->user_projects_ids( $username );

        unless ( scalar grep /^\/$/, @user_apps ) {  ## Si no tiene visibilidad sobre todos los proyectos.
            push @user_apps, undef; #Insertamos valor null para los topicos que no llevan proyectos
            $where->{'me.project'} =  \@user_apps;
        }
    }

    #DEFAULT VIEWS***************************************************************************************************************
    if($p->{today}){
        my $today = DateTime->now();
        $where->{created_on} = {'between' => [ $today->ymd, $today->add(days=>1)->ymd]};
    }
    
    if ( $p->{assigned_to_me} ) {
        my $rs_user = $c->model('Baseliner::BaliUser')->search( username => $username )->first;
        if ($rs_user) {
            my @topic_mids
                = map { $_->{from_mid} }
                Baseliner->model('Baseliner::BaliMasterRel')
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
        $where->{'label_id'} = \@labels;
    }
    
    if($p->{categories}){
        my @categories = _array $p->{categories};
        $where->{'category_id'} = \@categories;
    }
    
    if($p->{statuses}){
        my @statuses = _array $p->{statuses};
        $where->{'category_status_id'} = \@statuses;
    }
      
    if($p->{priorities}){
        my @priorities = _array $p->{priorities};
        $where->{'priority_id'} = \@priorities;
    }

    #*****************************************************************************************************************************
    
    #Filtro cuando viene por la parte del Dashboard.
    if($p->{query_id}){
        $where->{topic_mid} = $p->{query_id};
    }
    
    #Filtro cuando viene por la parte del lifecycle.
    if($p->{id_project}){
        my @topics_project = map {$_->{from_mid}} $c->model('Baseliner::BaliMasterRel')->search({ to_mid=>$p->{id_project}, collection =>'bali_topic' }, {join => ['master_from']})->hashref->all;
        $where->{topic_mid} = \@topics_project;
    }    
    
    # SELECT GROUP_BY MID:
    my $args = { select=>$select, as=>$as, order_by=>$order_by, group_by=>$group_by };
    if( $limit >= 0 ) {
        $args->{page} = $page;
        $args->{rows} = $limit;
    }
    my $rs = $c->model('Baseliner::TopicView')->search(  $where, $args );                                                             
    
    if( $limit >= 0 ) {
        my $pager = $rs->pager;
        $cnt = $pager->total_entries;
    } else {
        $cnt = $rs->count;
    }
    rs_hashref( $rs );
    my @mids = map { $_->{topic_mid} } $rs->all;
    my $rs_sub = $rs->search(undef, { select=>'topic_mid', distinct=>1});
            # _log _dump $rs_sub->as_query;
    
    # SELECT MID DATA:
    my @mid_data = $c->model('Baseliner::TopicView')->search({ topic_mid=>{ -in =>$rs_sub->as_query  } })->hashref->all;
    my @rows;
    my %id_label;
    my %projects;
    my %projects_report;
    my %assignee;
    my %mid_data;
    for (@mid_data) {
        my $mid = $_->{topic_mid};
        $mid_data{ $mid } = $_ unless exists $mid_data{ $_->{topic_mid} };
        $mid_data{ $mid }{is_closed} = $_->{status} eq 'C' ? \1 : \0;
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
        push @rows, {
            %$data,
            topic_name => sprintf("%s #%d", $data->{category_name}, $mid),
            labels   => [ keys %{ $id_label{$mid} || {} } ],
            projects => [ keys %{ $projects{$mid} || {} } ],
            assignee => [ keys %{ $assignee{$mid} || {} } ],
            report_data => {
                projects => join( ', ', keys %{ $projects_report{$mid} || {} } )
            },
        };
    }

    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}


sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    $p->{username} = $c->username;
    
    try  {    
        my ($msg, $topic_mid, $status) = Baseliner::Model::Topic->update( $p );
        $c->stash->{json} = {
            success      => \1,
            msg          => _loc( $msg, scalar( _array( $p->{topic_mid} ) ) ),
            topic_mid    => $topic_mid,
            topic_status => $status
        };
    } catch {
        my $e = shift;
        $c->stash->{json} = { success => \0, msg=>_loc($e) };
    };
    $c->forward('View::JSON');
}

sub related : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $mid = $p->{mid};
    my $show_release = $p->{show_release} // '0';
    my $where = {};
    $where->{mid} = { '<>' => $mid } if length $mid;
    $where->{'categories.is_release'} = $show_release;
    my $rs_topic = $c->model('Baseliner::BaliTopic')->search($where, { order_by=>['categories.name', 'mid' ], prefetch=>['categories'] });
    rs_hashref( $rs_topic );
    my @topics = map {
        $_->{name} = $_->{categories}{is_release} eq '1' 
            ?  $_->{title}
            :  $_->{categories}->{name} . ' #' . $_->{mid};
        $_->{color} = $_->{categories}->{color};
        $_
    } $rs_topic->all;
    $c->stash->{json} = { totalCount=>scalar(@topics), data=>\@topics };
    $c->forward('View::JSON');
}

sub json : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
    my $topic = $c->model('Baseliner::BaliTopic')->find( $topic_mid );

    my @projects;
    my $topicprojects = $topic->projects->search();
    while( my $topicproject = $topicprojects->next ) {
        my $str = $topicproject->id;
        push @projects, $str
    }
    
    my @users = map { $_->id } 
        $topic->users->search( undef, { select=>[qw(mid)],
        order_by => { '-asc' => 'username' } } )->all;
        
    my @labels = map { $_->id_label } 
        $c->model('Baseliner::BaliTopicLabel')->search( id_topic => $topic_mid , { select=>[qw(id_label)] } )->all;        
        
    my @topics = map { $_->mid } 
        $topic->topics->search( undef, { select=>[qw(mid)],
        order_by => { '-asc' => 'mid' } } )->all;
    
    my @revisions = map { $_->{id} = $_->{mid}; $_ } 
        $topic->revisions->search( undef, { select=>[qw(name mid)],
        order_by => { '-asc' => 'mid' } } )->hashref->all;
    
    ######################################################################################### 
    #Preguntar por el formulario de configuracion;
    my $id_category = $topic->id_category;    
    my $field_hash = $self->field_configuration( $id_category );
    my $row_category = $c->model('Baseliner::BaliTopicCategories')->find( $id_category );
    my $forms;
    if( ref $row_category ) {
        $forms = $self->form_build( $row_category->forms );
    }

    ##########################################################################################
        
    my $ret = {
        title              => $topic->title,
        description        => $topic->description,
        progress           => $topic->progress,
        category           => $topic->id_category,
        topic_mid          => $topic_mid,
        status             => $topic->id_category_status,
        labels             => \@labels,
        projects           => \@projects,
        users              => \@users,
        topics             => \@topics,
        revisions          => \@revisions,
        priority           => $topic->id_priority,
        response_time_min  => $topic->response_time_min,
        expr_response_time => $topic->expr_response_time,
        deadline_min       => $topic->deadline_min,
        expr_deadline      => $topic->expr_deadline,
        fields_form        => $field_hash,
        forms              => $forms,
    };
    $ret->{category_name} = try { $topic->categories->name } catch {''};
    $ret->{status_name} = try { $topic->status->name } catch {''};
    $ret->{priority_name} = try { $topic->priorities->name } catch { ''};
    
    $c->stash->{json} = $ret;
    
    $c->forward('View::JSON');
}

sub new_topic : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    
    ######################################################################################### 
    #Preguntar por el formulario de configuracion;
    # my $id_category = $p->{new_category_id};
    
    my $id_category = $p->{new_category_id};
    my $field_hash = $self->field_configuration( $id_category );
    
    ##########################################################################################

    
        
    my $ret = {
        new_category_id    => $p->{new_category_id},
        new_category_name  => $p->{new_category_name},
        fields_form        => $field_hash
    };
    
    $c->stash->{json} = $ret;
    $c->forward('View::JSON');
}

sub view : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid} || $p->{action};
    my $id_category;
    
    if($topic_mid || $c->stash->{topic_mid} ){
        my $topic = $c->model('Baseliner::BaliTopic')->find( $topic_mid );
        $id_category = $topic->id_category;
        $c->stash->{title} = $topic->title;
        $c->stash->{topic_mid} = $topic->mid;
        $c->stash->{created_on} = $topic->created_on;
        $c->stash->{created_by} = $topic->created_by;
        $c->stash->{priority} = try { $topic->priorities->name } catch { _loc('unassigned') };
        my $deadline = $topic->deadline_min ? $topic->created_on->clone->add( minutes => $topic->deadline_min ):'';
        $c->stash->{deadline} = $deadline;
        $c->stash->{status} = try { $topic->status->name } catch { _loc('unassigned') };
        $c->stash->{description} = $topic->description;
        $c->stash->{progress} = $topic->progress;
        $c->stash->{category} = $topic->categories->name;
        $c->stash->{is_release} = $topic->categories->is_release;
        $c->stash->{is_changeset} = $topic->categories->is_changeset;
        $c->stash->{category_color} = try { $topic->categories->color} catch { '#444' };
        $c->stash->{forms} = [
            map { "/forms/$_" } split /,/,$topic->categories->forms
        ];
        $c->stash->{ii} = $p->{ii};
        $c->stash->{events} = events_by_mid( $topic_mid );
        $c->stash->{swEdit} = $p->{swEdit};
        # users
        my @users = $topic->users->search()->hashref->all;
        $c->stash->{users} = @users ? \@users : []; 
        # projects
        my @projects = $topic->projects->search()->hashref->all;
        $c->stash->{projects} = @projects ? \@projects : [];
        # labels
        my @labels = Baseliner->model('Baseliner::BaliTopicLabel')->search({ id_topic => $topic_mid },
                                                                         {prefetch =>['label']})->hashref->all;
        @labels = map {$_->{label}} @labels;
        $c->stash->{labels} = @labels ? \@labels : []; 
        # comments
        $self->list_posts( $c );  # get comments into stash
        # related topics
        my $rs_rel_topic = $topic->topics->search( undef, { order_by => { '-asc' => ['categories.name', 'mid'] }, prefetch=>['categories'] } );
        rs_hashref ( $rs_rel_topic );
        my @topics = $rs_rel_topic->all;
        @topics = $c->model('Topic')->append_category( @topics );
        $c->stash->{topics} = @topics ? \@topics : []; 

        #topics_parents
        my @parents_topics = $c->model('Baseliner::BaliTopic')->search(
                                { rel_type=>'topic_topic', to_mid=>$topic_mid },
                                { join=>['categories','children','master'], select=>['mid','title', 'progress', 'categories.name', 'categories.color'], as=>['mid','title','progress','name','color'] }
                                )->hashref->all;
        @parents_topics = $c->model('Topic')->append_category( @parents_topics );
        $c->stash->{parents_topics} = @parents_topics ? \@parents_topics : []; 

        # dates
        my @dates = $c->model('Baseliner::BaliMasterCal')->search({ mid=> $topic_mid })->hashref->all;
        $c->stash->{dates} = \@dates;

        # revisions
        my @revisions =
            $c->model('Baseliner::BaliMasterRel')->search( { rel_type => 'topic_revision', from_mid => $topic_mid },
            { prefetch => ['master_to'], +select => [ 'master_to.name', 'master_to.mid' ], +as => [qw/name mid/] } )
            ->hashref->all;
        $c->stash->{revisions} = \@revisions;

        # release
        #my $release_row = $topic->topics->search({ is_release=>'1' })->first;
        my $release_row = $c->model('Baseliner::BaliTopic')->search(
                                { is_release => 1, rel_type=>'topic_topic', to_mid=>$topic_mid },
                                { prefetch=>['categories','children','master'] }
                                )->hashref->first;
        $c->stash->{release} = ref $release_row ? $release_row->{title} : '';
        $c->stash->{release_row} = $release_row;
        # files
        my @files = map { +{ $_->get_columns } } 
            $topic->files->search( undef, { select=>[qw(filename filesize md5 versionid extension created_on created_by)],
            order_by => { '-asc' => 'created_on' } } )->all;
        $c->stash->{files} = @files ? \@files : []; 
    }else{
        $id_category = $p->{categoryId};
        $c->stash->{title} = '';
        $c->stash->{created_on} = '';
        $c->stash->{created_by} = '';
        $c->stash->{deadline} = '';  # TODO
        $c->stash->{status} = '';
        $c->stash->{description} = '';        
        $c->stash->{category} = $id_category;
        $c->stash->{category_color} = '#444';
        $c->stash->{priority} = '';
        $c->stash->{dates} = [];
        $c->stash->{progress} = 0;
        $c->stash->{revisions} = [];
        $c->stash->{forms} = '';
        $c->stash->{topic_mid} = '';
        $c->stash->{swEdit} = $p->{swEdit};
        $c->stash->{events} = '';
        $c->stash->{comments} = '';
        $c->stash->{ii} = $p->{ii};
        $c->stash->{files} = []; 
        $c->stash->{topics} = [];
        $c->stash->{projects} = [];
        $c->stash->{labels} = [];
        $c->stash->{users} = [];
    }

    if( $p->{html} ) {
        my $field_hash = $self->field_configuration( $id_category );
        map { $c->stash->{ $_ } = \1 } keys %$field_hash;
        
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
            my $topic_mid = $p->{topic_mid};
            my $id_com = $p->{id_com};
            my $content_type = $p->{content_type};
            _throw( _loc( 'Missing id' ) ) unless defined $topic_mid;
            my $text = $p->{text};
            _log $text;
            
            my $topic;
            if( ! length $id_com ) {  # optional, if exists then is not add, it's an edit
                $topic = master_new 'post' => substr($text,0,10) => sub { 
                    my $mid = shift;
                    my $post = $c->model('Baseliner::BaliPost')->create(
                        {   mid   => $mid,
                            text       => $text,
                            content_type => $content_type,
                            created_by => $c->username,
                            created_on => DateTime->now,
                        }
                    );
                    event_new 'event.post.create' => {
                        username => $c->username,
                        mid      => $topic_mid,
                        id_post  => $mid,
                        post     => substr( $text, 0, 30 ) . ( length $text > 30 ? "..." : "" )
                    };
                    my $topic = $c->model('Baseliner::BaliTopic')->find( $topic_mid );
                    $topic->add_to_posts( $post, { rel_type=>'topic_post' });
                    #master_rel->create({ rel_type=>'topic_post', from_mid=>$id_topic, to_mid=>$mid });
                };
                #$c->model('Event')->create({
                #    type => 'event.topic.new_comment',
                #    ids  => [ $id_topic ],
                #    username => $c->username,
                #    data => {
                #        text=>$p->{text}
                #    }
                #});
            } else {
                my $post = $c->model('Baseliner::BaliPost')->find( $id_com );
                $post->text( $text );
                $post->content_type( $content_type );
                # TODO modified_on ?
                $post->update;
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
            my $post = $c->model('Baseliner::BaliPost')->find( $id_com );
            my $text = $post->text;
            # find my parents to notify via events
            my @mids = map { $_->from_mid } $post->parents->all; 
            # delete the record
            $post->delete;
            # now notify my parents
            event_new 'event.post.delete' => { username => $c->username, mid => $_, id_post=>$id_com,
                post     => substr( $text, 0, 30 ) . ( length $text > 30 ? "..." : "" )
            } for @mids;
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

sub list_posts : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};

    my $rs = $c->model('Baseliner::BaliTopic')->find( $topic_mid )
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
    $c->stash->{comments} = \@rows;
}

sub list_category : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my @rows;

    if( !$p->{categoryId} ){    
        my $rs = $c->model('Baseliner::BaliTopicCategories')->search();
        
        if($rs){
            while( my $r = $rs->next ) {
                my @statuses;
                my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $r->id});
                while( my $status = $statuses->next ) {
                    push @statuses, $status->id_status;
                }

                my $type = $r->is_changeset ? 'C' : $r->is_release ? 'R' : 'N';
                
                my @fields = map { $_->id_field } 
                    $c->model('Baseliner::BaliTopicFieldsCategory')->search( {id_category => $r->id}, {order_by=> {'-asc'=> 'id_field'}} )->all;
                    
                my @priorities = map { $_->id_priority } 
                    $c->model('Baseliner::BaliTopicCategoriesPriority')->search( {id_category => $r->id, is_active=>1}, {order_by=> {'-asc'=> 'id_priority'}} )->all;

                my $forms = $self->form_build( $r->forms );
                
                push @rows,
                {   id            => $r->id,
                    category      => $r->id,
                    name          => $r->name,
                    color         => $r->color,
                    type          => $type,
                    forms         => $forms,
                    category_name => $r->name,
                    is_release    => $r->is_release,
                    is_changeset  => $r->is_changeset,
                    description   => $r->description,
                    statuses      => \@statuses,
                    fields        => \@fields,
                    priorities    => \@priorities
                };
            }  
        }
        $cnt = $#rows + 1 ; 
    }else{
        # Status list for combo and grid in workflow 
        my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $p->{categoryId}},
                                                                            {
                                                                                join => ['status'],
                                                                                '+select' => ['status.name','status.id','status.bl'],
                                                                                order_by => { -asc => ['status.seq'] },
                                                                            });            
        if($statuses){
            while( my $status = $statuses->next ) {
                push @rows, {
                                id      => $status->status->id,
                                bl      => $status->status->bl,
                                name    => $status->status->name_with_bl,
                            };
            }
        }
        $cnt = $#rows + 1 ;
    }
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
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

sub update_topic_labels : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $topic_mid = $p->{topic_mid};
    my $label_ids = $p->{label_ids};
    
    try{
        $c->model("Baseliner::BaliTopicLabel")->search( {id_topic => $topic_mid} )->delete;
        
        foreach my $label_id (_array $label_ids){
            $c->model('Baseliner::BaliTopicLabel')->create( {   id_topic    => $topic_mid,
                                                                id_label    => $label_id,
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
    my $topic_mid = $p->{topic_mid};
    my $id_project = $p->{id_project};

    try{
        my $project = $c->model('Baseliner::BaliProject')->find($id_project);
        my $mid;
        if( ref $project ) {
            if($project && $project->mid){
                $mid = $project->mid
            }
            else{
                my $project_mid = master_new 'project' => $project->name => sub {
                    my $mid = shift;
                    $project->mid($mid);
                    $project->update();
                }
            }
            my $topic = $c->model('Baseliner::BaliTopic')->find( $topic_mid );
            $topic->add_to_projects( $project, { rel_type=>'topic_project' } );
        } # TODO invalid
        
        $c->stash->{json} = { msg=>_loc('Project added'), success=>\1 };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error adding project: %1', shift()), failure=>\1 }
    };
     
    $c->forward('View::JSON');    
}

sub filters_list : Local {
    my ($self,$c) = @_;
    my $id = $c->req->params->{node};
    
    my @tree;
    my $row;
    my $i=1;
 
    my @views;
    
    ####Defaults views################################################################
    push @views, {
        id  => $i++,
        idfilter      => 1,
        text    => _loc('Created Today'),
        filter  => '{"today":true}',
        default    => \1,
        cls     => 'forum default',
        iconCls => 'icon-no',
        checked => \0,
        leaf    => 'true'
    };
    
    push @views, {
        id  => $i++,
        idfilter      => 2,
        text    => _loc('Assigned To Me'),
        filter  => '{"assigned_to_me":true}',
        default    => \1,
        cls     => 'forum default',
        iconCls => 'icon-no',
        checked => \0,
        leaf    => 'true'
    };
    
    ##################################################################################

    $row = $c->model('Baseliner::BaliTopicView')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @views, {
                id  => $i++,
                idfilter      => $r->id,
                text    => $r->name,
                filter  => $r->filter_json,
                default    => \0,
                cls     => 'forum',
                iconCls => 'icon-no',
                checked => \0,
                leaf    => 'true'
            };	
        }  
    }   
    
    push @tree, {
        id          => 'V',
        text        => _loc('Views'),
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        children    => \@views
    };   
    
    # Filter: Categories
    my @categories;
    $row = $c->model('Baseliner::BaliTopicCategories')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @categories,
                {
                    id  => $i++,
                    idfilter      => $r->id,
                    text    => $r->name,
                    color   => $r->color,
                    cls     => 'forum',
                    iconCls => 'icon-no',
                    checked => \0,
                    leaf    => 'true'
                };
        }  
    }

    push @tree, {
        id          => 'C',
        text        => _loc('Categories'),
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        expanded    => 'true',
        children    => \@categories
    };
        
    
    # Filter: Labels
    my @labels; 

    $row = $c->model('Baseliner::BaliLabel')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @labels, {
                id  => $i++,
                idfilter      => $r->id,
                text    => $r->name,
                color   => $r->color,
                cls     => 'forum label',
                iconCls => 'icon-no',
                checked => \0,
                leaf    => 'true'
            };	
        }  
    }
    
    push @tree, {
        id          => 'L',
        text        => _loc('Labels'),
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        children    => \@labels
    };
    
    # Filter: Status
    my @statuses;
    $row = $c->model('Baseliner::BaliTopicStatus')->search(undef, { order_by=>'seq' });
    
    if($row){
        while( my $r = $row->next ) {
            push @statuses,
                {
                    id  => $i++,
                    idfilter      => $r->id,
                    text    => $r->name,
                    cls     => 'forum status',
                    iconCls => 'icon-no',
                    checked => \0,
                    leaf    => 'true'
                };
        }  
    }
    
    push @tree, {
        id          => 'S',
        text        => _loc('Statuses'),
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        expanded    => 'true',
        children    => \@statuses
    };
    
    
    my @priorities;
    $row = $c->model('Baseliner::BaliTopicPriority')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @priorities,
            {
                id  => $i++,
                idfilter      => $r->id,
                text    => $r->name,
                cls     => 'forum',
                iconCls => 'icon-no',
                checked => \0,
                leaf    => 'true'
            };
        }  
    }       
       
    push @tree, {
        id          => 'P',
        text        => _loc('Priorities'),
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        expanded    => 'true',
        children    => \@priorities
    };
       
        
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub view_filter : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my $name = $p->{name};
    my $filter = $p->{filter};
  
    given ($action) {
        when ('add') {
            try{
                my $row = $c->model('Baseliner::BaliTopicView')->search({name => $name})->first;
                if(!$row){
                    my $view = $c->model('Baseliner::BaliTopicView')->create({name => $name, filter_json => $filter});
                    $c->stash->{json} = { msg=>_loc('View added'), success=>\1, data=>{id=>9999999999, idfilter=>$view->id}};
                }
                else{
                    $c->stash->{json} = { msg=>_loc('View name already exists, introduce another view name'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding View: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {

        }
        when ('delete') {
            my $ids_view = $p->{ids_view};
            try{
                my @ids_view;
                foreach my $id_view (_array $ids_view){
                    push @ids_view, $id_view;
                }
                  
                my $rs = Baseliner->model('Baseliner::BaliTopicView')->search({ id => \@ids_view });
                $rs->delete;
                
                $c->stash->{json} = { success => \1, msg=>_loc('Views deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting views') };
            }            
        }
    }
    
    $c->forward('View::JSON');    
}

=head2 list_admin_category

Lists the destination statuses for a given topic.

=cut
sub list_admin_category : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my @rows;
    my $statuses;
    my $swStatus = 0;


    if ($p->{change_categoryId}){
        if ($p->{statusId}){
            $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $p->{change_categoryId}, id_status => $p->{statusId}},
                                                                                        {
                                                                                        prefetch=>['status'],
                                                                                        }                                                                                 
                                                                                     );
            if($statuses->count){
                $swStatus = 1;
            }
            
        }
        if(!$swStatus){
            $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $p->{change_categoryId}, type => 'I'},
                                                                                        {
                                                                                        prefetch=>['status'],
                                                                                        }                                                                                 
                                                                                     );        
        }
        
        if($statuses->count){
            while( my $status = $statuses->next ) {
                push @rows, {
                                id      => $status->status->id,
                                status      => $status->status->id,
                                name    => $status->status->name,
                                status_name    => $status->status->name,
                            };
            }
        }        

    }else{
        my $username = $c->is_root ? '' : $c->username;
        my @statuses = $c->model('Topic')->next_status_for_user(
            id_category    => $p->{categoryId},
            id_status_from => $p->{statusId},
            username       => $username,
        );
        push @rows, { id => $p->{statusId}, name => $p->{statusName}, status => $p->{statusId}, status_name => $p->{statusName}  };
        @rows = map {
            +{
                id          => $_->{id_status},
                status      => $_->{id_status},
                name        => $_->{status_name},
                status_name => $_->{status_name},
            }
        } @statuses;
        
    }
        
    $c->stash->{json} = { data=>\@rows};
    $c->forward('View::JSON');
}

sub upload : Local {
    my ( $self, $c ) = @_;
    my $p      = $c->req->params;
    my $filename = $p->{qqfile};
    my ($extension) =  $filename =~ /\.(\S+)$/;
    $extension //= '';
    my $f =  _file( $c->req->body );
    _log "Uploading file " . $filename;
    try {
        my $config = config_get( 'config.uploader' );
        my ($topic, $topic_mid, $file_mid);
        if($p->{topic_mid}){
            $topic = $c->model('Baseliner::BaliTopic')->find( $p->{topic_mid} );
            $topic_mid = $topic->mid;
        }
        my $body = scalar $f->slurp;
        my $md5 = _md5( $body );
        my $existing = Baseliner->model('Baseliner::BaliFileVersion')->search({ md5=>$md5 })->first;
        if( $existing && $p->{topic_mid}) {
            # file already exists
            if( $topic->files->search({ md5=>$md5 })->count > 0 ) {
                _fail _loc "File already attached to topic";
            } else {
                event_new 'event.file.attach' => {
                    username => $c->username,
                    mid      => $topic_mid,
                    id_file  => $existing->mid,
                    filename     => $filename,
                };                
                $topic->add_to_files( $existing, { rel_type=>'topic_file_version' });
            }
        } else {
            # create file version master and bali_file_version rows
            if (!$existing){
                my $versionid = 1;
                my @file = map {$_->{versionid}}  Baseliner->model('Baseliner::BaliFileVersion')->search({ filename =>$filename },{order_by => {'-desc' => 'versionid'}})->hashref->first;
                if(@file){
                    $versionid = $file[0] + 1;
                }else{
                }
                
                master_new 'file', $filename, sub {
                    my $mid = shift;
                    my $file = $c->model('Baseliner::BaliFileVersion')->create(
                        {   mid   => $mid,
                            filedata   => $body,
                            filename => $filename,
                            extension => $extension,
                            versionid => $versionid,
                            md5 => $md5, 
                            filesize => length( $body ), 
                            created_by => $c->username,
                            created_on => DateTime->now,
                        }
                    );
                    $file_mid = $mid;
                    if ($p->{topic_mid}){
                        event_new 'event.file.create' => {
                            username => $c->username,
                            mid      => $topic_mid,
                            id_file  => $mid,
                            filename     => $filename,
                        };
                        # tie file to topic
                        $topic->add_to_files( $file, { rel_type=>'topic_file_version' });
                    }
                };                        
            }
                
            #$file_mid = $existing->mid;
        }
        $c->stash->{ json } = { success => \1, msg => _loc( 'Uploaded file %1', $filename ), file_uploaded_mid => $p->{topic_mid}? '': $file_mid, };
    }
    catch {
        my $err = shift;
        _log "Error uploading file: " . $err;
        $c->stash->{ json } = { success => \0, msg => $err };
    };
    #$c->res->body('{success: true}');
    $c->forward( 'View::JSON' );
    #$c->res->content_type( 'text/html' );    # fileupload: true forms need this
}

sub file : Local {
    my ( $self, $c, $action ) = @_;
    my $p      = $c->req->params;
    my $topic_mid = $p->{topic_mid};
    try {
        my $msg; 
        if( $action eq 'delete' ) {
            for my $md5 ( _array( $p->{md5} ) ) {
                my $file = Baseliner->model('Baseliner::BaliFileVersion')->search({ md5=>$md5 })->first;
                ref $file or _fail _loc("File id %1 not found", $md5 );
                my $count = Baseliner->model('Baseliner::BaliMasterRel')->search({ to_mid => $file->mid })->count;
                if( $count < 2 ) {
                    _log "Deleting file " . $file->mid;
                    event_new 'event.file_remove' => {
                        username => $c->username,
                        mid      => $topic_mid,
                        id_file  => $file->mid,
                        filename => $file->filename,
                    };                  
                    $file->delete;
                    $msg = _loc( "File deleted ok" );
                } else {
                    event_new 'event.topic.file_remove' => {
                        username => $c->username,
                        mid      => $topic_mid,
                        id_file  => $file->mid,
                        filename => $file->filename,
                        }
                    => sub {
                        my $rel = Baseliner->model('Baseliner::BaliMasterRel')->search({ from_mid=>$topic_mid, to_mid => $file->mid })->first;
                        _log "Deleting file from topic $topic_mid ($rel) = " . $file->mid;
                        ref $rel or _fail _loc "File not attached to topic";
                        $rel -> delete;
                        $msg = _loc( "Relationship deleted ok" );
                    };
                }
            }
        }
        $c->stash->{ json } = { success => \1, msg => $msg };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success => \0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub download_file : Local {
    my ( $self, $c, $md5 ) = @_;
    my $p      = $c->req->params;
    my $file = $c->model('Baseliner::BaliFileVersion')->search({ md5=>$md5 })->first;
    if( defined $file ) {
        $c->stash->{serve_filename} = $file->filename;
        $c->stash->{serve_body} = $file->filedata;
        $c->forward('/serve_file');
    } else {
        $c->res->body(_loc('File %1 not found', $md5 ) );
    }
}

sub file_tree : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
    my @files = ();
    if($topic_mid){
        @files = map {
           my ( $size, $unit ) = _size_unit( $_->filesize );
           $size = "$size $unit";
           +{ $_->get_columns, _id => $_->mid, _parent => undef, _is_leaf => \1, size => $size }
           } 
           $c->model('Baseliner::BaliTopic')->search( { mid => $topic_mid } )->first->files->search(
           undef,
           {   select   => [qw(mid filename filesize md5 versionid extension created_on created_by)],
               order_by => { '-asc' => 'created_on' }
           }
           )->all;       
    }else{
        my @files_mid = _array $p->{files_mid};
        @files = map {
           my ( $size, $unit ) = _size_unit( $_->filesize );
           $size = "$size $unit";
           +{ $_->get_columns, _id => $_->mid, _parent => undef, _is_leaf => \1, size => $size }
           } 
           $c->model('Baseliner::BaliFileVersion')->search( { mid => \@files_mid } )->all;           
        
    }

    $c->stash->{json} = { total=>scalar( @files ), success=>\1, data=>\@files };
    $c->forward('View::JSON');
}

sub list_users : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $row;
    my (@rows, $users_friends);
    my $username = $c->username;
    if($p->{projects}){
        my @projects = _array $p->{projects};
        $users_friends = $c->model('Users')->get_users_friends_by_projects(\@projects);
    }else{
        $users_friends = $c->model('Users')->get_users_friends_by_username($username);
        
    }
    $row = $c->model('Baseliner::BaliUser')->search({username => $users_friends},{order_by => 'realname asc'});    
    if($row){
        while( my $r = $row->next ) {
            push @rows,
              {
                id 		=> $r->id,
                username	=> $r->username,
                realname	=> $r->realname
              };
        }  
    }
    
    $c->stash->{json} = { data=>\@rows };
    $c->forward('View::JSON');
}
sub form_build {
    my ($self, $form_str ) = @_;
    [ map {
        my $form_name = $_;
        +{
            form_name => $_,
            form_path => "/forms/$form_name.js",
        }
    } split /,/, $form_str ];
}

sub newjob : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $ns = $p->{ns} or _throw 'Missing parameter ns';
    my $bl = $p->{bl} or _throw 'Missing parameter bl';

    $c->stash->{json} = try {
        my @contents = map {
            _log _loc "Adding namespace %1 to job", $_;
            my $item = Baseliner->model('Namespaces')->get( $_ );
            _throw _loc 'Could not find changeset "%1"', $_ unless ref $item;
            $item;
        } ($ns);

        _log _dump \@contents;

        my $job_type = $p->{job_type} || 'static';

        my $job = $c->model('Jobs')->create(
            bl       => $bl,
            type     => $job_type,
            username => $c->username || $p->{username} || `whoami`,
            runner   => $p->{runner} || 'service.job.chain.simple',
            comments => $p->{comments},
            items    => [ @contents ]
        );
        $job->stash_key( status_from => $p->{status_from} );
        $job->stash_key( status_to => $p->{status_to} );
        $job->update;
        { success=>\1, msg=> _loc( "Job %1 created ok", $job->name ) };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error creating job: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}

sub kanban_status : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $topics = $p->{topics};
    my $data = {};
    my @columns;
    $c->stash->{json} = try {
        my $rs1 = $c->model('Baseliner::BaliTopic')->search({ 
          mid=>$topics }, { select=>'id_category', distinct=>1 }); 

        my $rs = $c->model('Baseliner::BaliTopicCategoriesStatus')->search(
          { id_category=>{ -in => $rs1->as_query } },
          { +select=>['status.id', 'status.name'], +as=>[qw/id name/], 
            join=>['status'], order_by=>'status.seq', distinct=>1 }
        );
        my @statuses = $rs->hashref->all;

        my $where = { mid => $topics };
        $where->{'user_role.username'} = $c->username unless $c->is_root;
        my @rs2 = $c->model('Baseliner::BaliTopic')->search(
            $where,
            {   join => { 'workflow' => [ 'user_role', 'statuses_to', 'statuses_from' ] },
                +select  => [qw/mid workflow.id_status_from workflow.id_status_to statuses_to.name statuses_to.seq statuses_from.name statuses_from.seq/],
                +as      => [qw/mid id_status_from id_status_to to_name to_seq from_name from_seq/],
                distinct => 1,
            }
        )->hashref->all;
        my %workflow;
        for( @rs2 ) {
            push @{ $workflow{ $_->{mid} } }, $_;
        }
        #my %statuses = map { $_->{id_status_to} => { name=>$_->{to_name}, id=>$_->{id_status_to}, seq=>$_->{to_seq} } } @rs2;
        #{ success=>\1, msg=>'', statuses=>[ sort { $a->{seq} <=> $b->{seq} } values %statuses ] };
        { success=>\1, msg=>'', statuses=>\@statuses, workflow=>\%workflow };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error creating job: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}

sub report_data_replace {
    my ($self, $data ) = @_;
    for( _array( $data->{rows} ) ) {
        # find and replace report_data columns 
        for my $col ( keys %{ $_->{report_data} || {} } ) {
            $_->{ $col } = $_->{report_data}->{ $col };
        }
    }
    return $data;
}

sub report_html : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $data = _decode_json $p->{data_json};
    $data = $self->report_data_replace( $data );
    $c->stash->{data} = $data;
    $c->stash->{template} = '/reports/basic.html';
}

sub report_yaml : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $data_json = $p->{data_json};
    my $data = _decode_json $data_json;
    my $yaml = YAML::XS::Dump( $data );
    #utf8::encode( $yaml );
    $c->res->body( qq{<!DOCTYPE html>\n<html>\n<head>\n<meta charset="utf-8">\n</head>\n<body>\n<pre>${yaml}</pre></body></html>} );
    #$c->res->headers->header( 'content-type', 'plain/text' );
    #$c->res->body( $yaml );
}

sub report_csv : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $data = _decode_json $p->{data_json};
    $data = $self->report_data_replace( $data );
    
    my @csv;
    my @cols;
    for( _array( $data->{columns} ) ) {
        push @cols, qq{"$_->{name}"}; #"
    }
    push @csv, join ',', @cols;

    for my $row ( _array( $data->{rows} ) ) {
        my @cells;
        for my $col ( _array( $data->{columns} ) ) {
            my $v = $row->{ $col->{id} };
            $v =~ s{"}{""}g;
            push @cells, qq{"$v"}; 
        }
        push @csv, join ',', @cells; 
    }
    my $body = join "\n", @csv;
    #$c->res->body( $body );
    $c->stash->{serve_body} = $body;
    $c->stash->{serve_filename} = 'topics.csv';
    $c->forward('/serve_file');
}

sub field_configuration {
    my ($self, $id_category ) = @_;
    defined $id_category or _throw _loc 'Missing parameter';
    my $field_hash = {};
    my @fields = Baseliner->model('Baseliner::BaliTopicFieldsCategory')->search({id_category => $id_category}, {prefetch => ['fields']})->hashref->all;
    if( @fields > 0 ) {
        map { $field_hash->{'show_' . $_->{fields}->{name}} = \1 } @fields;
    } else {
        map { $field_hash->{"show_$_"} = \1 } qw/
            assign_to
            category
            description
            files
            labels
            priority
            progress
            projects
            properties
            release
            revisions
            status
            title
            topics
        /;
    }
    return $field_hash;
}

1;
