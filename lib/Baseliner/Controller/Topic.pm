package Baseliner::Controller::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  
register 'action.admin.topics' => { name=>'Admin topics' };

register 'registor.menu.topics' => {
    generator => sub {
       # action.topics.<category_name>.[create|edit|view]
       my @cats = DB->BaliTopicCategories->search(undef,{ select=>[qw/name id color/] })->hashref->all;
       my $seq = 10;
       my %menu_view = map {
           my $data = $_;
           my $name = _loc( $_->{name} );
           my $id = _name_to_id( $name );
           $data->{color} //= 'transparent';
           "menu.topic.$id" => {
                label    => qq[<div id="boot" style="background:transparent"><span class="label" style="background-color:$data->{color}">$name</span></div>],
                title    => qq[<div id="boot" style="background:transparent;height:14px"><span class="label" style="background-color:$data->{color}">$name</span></div>],
                index    => $seq++,
                actions  => ["action.topics.$id.view"],
                url_comp => "/topic/grid?category_id=" . $data->{id},
                #icon     => '/static/images/icons/topic.png',
                tab_icon => '/static/images/icons/topic.png'
           }
       } sort { lc $a->{name} cmp lc $b->{name} } @cats;

       my %menu_create = map {
           my $data = $_;
           my $name = _loc( $_->{name} );
           my $id = _name_to_id( $name );
           $data->{color} //= 'transparent';
           "menu.topic.create.$id" => {
                label    => qq[<div id="boot" style="background:transparent"><span class="label" style="background-color:$data->{color}">$name</span></div>],
                title    => _loc ('New: %1', $name),
                index    => $seq++,
                actions  => ["action.topics.$id.create"],
                url_comp => '/topic/view?swEdit=1',
                comp_data => { new_category_name=>$name, new_category_id=>$data->{id} },
                #icon     => '/static/images/icons/topic.png',
                tab_icon => '/static/images/icons/topic.png'
           }
       } sort { lc $a->{name} cmp lc $b->{name} } @cats;

       my $menus = {
            'menu.topic' => {
                    label => _loc('Topics'),
                    title    => _loc('Topics'),
                    actions  => ['action.topics.%'],
            },
            'menu.topic.topics' => {
                    index => 1,
                    label => _loc('All'),
                    title    => _loc ('Topics'),
                    actions  => ['action.topics.%.view'],
                    url_comp => '/topic/grid',
                    icon     => '/static/images/icons/topic.png',
                    tab_icon => '/static/images/icons/topic.png'
            },
            'menu.topic._sep_' => { index=>3, separator=>1 },
            %menu_create,
            %menu_view,
       };
       $menus->{'menu.topic.create'} = {
                    label    => _loc('Create'),
                    icon     => '/static/images/icons/add.gif',
                    index => 2,
                    actions  => ['action.topics.%.create'],
             } if %menu_create;
       return $menus;
    }
};

sub grid : Local {
    my ($self, $c, $typeApplication) = @_;
    my $p = $c->req->params;
    
    #Parametro para casos especiales como la aplicacion GDI
    $c->stash->{typeApplication} = $typeApplication;
    $c->stash->{id_project} = $p->{id_project};
    $c->stash->{project} = $p->{project}; 
    $c->stash->{query_id} = $p->{query};
    if ($p->{category_id} && $c->stash->{category_id} != $p->{category_id}) {
        $c->stash->{category_id} = $p->{category_id};
    }
    $c->stash->{template} = '/comp/topic/topic_grid.js';
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    $p->{username} = $c->username;

    my ($cnt, @rows ) = $c->model('Topic')->topics_for_user( $p );

    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt };
    $c->forward('View::JSON');
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    
    $p->{username} = $c->username;
    
    try  {    
        my ($msg, $topic_mid, $status, $title) = $c->model('Topic')->update( $p );
        $c->stash->{json} = {
            success      => \1,
            msg          => _loc( $msg, scalar( _array( $p->{topic_mid} ) ) ),
            topic_mid    => $topic_mid,
            topic_status => $status,
            title        => $title
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
    my $query = $p->{query};
    length($query) and $where = query_sql_build( query=>$query, fields=>{
        map { $_ => "me.$_" } qw/
        mid 
        title
        created_on
        created_by
        modified_on
        modified_by        
        /
    });

    if ($p->{mids}){
         my @mids = _array $p->{mids};
         $where->{mid} = \@mids;
    }
    $where->{mid} = { '<>' => $mid } if length $mid;
    $where->{'categories.is_release'} = $show_release;
    
    if($p->{filter} && $p->{filter} ne 'none'){
        ##Tratamos todos los tópicos, independientemente si son releases o no.
        delete $where->{'categories.is_release'}; 
        my $p = _decode_json($p->{filter});
        
        if($p->{categories}){
            my @categories = _array $p->{categories};
            if(@categories){
                my @not_in = map { abs $_ } grep { $_ < 0 } @categories;
                my @in = @not_in ? grep { $_ > 0 } @categories : @categories;
                if (@not_in && @in){
                    $where->{'id_category'} = [{'not in' => \@not_in},{'in' => \@in}];    
                }else{
                    if (@not_in){
                        $where->{'id_category'} = {'not in' => \@not_in};
                    }else{
                        $where->{'id_category'} = \@in;
                    }
                }                   
                
                #$where->{'id_category'} = \@categories;
            }
        }
        
        if($p->{statuses}){
            my @statuses = _array $p->{statuses};
            if(@statuses){
                my @not_in = map { abs $_ } grep { $_ < 0 } @statuses;
                my @in = @not_in ? grep { $_ > 0 } @statuses : @statuses;
                if (@not_in && @in){
                    $where->{'id_category_status'} = [{'not in' => \@not_in},{'in' => \@in}];    
                }else{
                    if (@not_in){
                        $where->{'id_category_status'} = {'not in' => \@not_in};
                    }else{
                        $where->{'id_category_status'} = \@in;
                    }
                }                
                #$where->{'id_category_status'} = \@statuses;
            }
        }
          
        if($p->{priorities}){
            my @priorities = _array $p->{priorities};
            if(@priorities){
                my @not_in = map { abs $_ } grep { $_ < 0 } @priorities;
                my @in = @not_in ? grep { $_ > 0 } @priorities : @priorities;
                if (@not_in && @in){
                    $where->{'id_priority'} = [{'not in' => \@not_in},{'in' => \@in}, undef];
                }else{
                    if (@not_in){
                        $where->{'id_priority'} = [{'not in' => \@not_in}, undef];
                    }else{
                        $where->{'id_priority'} = \@in;
                    }
                }                
                #$where->{'id_priority'} = \@priorities;            
            }
        
        }        
    }
    my $rs_topic = DB->BaliTopic->search($where, { order_by=>['categories.name', 'mid' ], prefetch=>['categories'] })->hashref;
    my @topics = map {
        if( $p->{topic_child_data} ) {
            #my $meta = $c->model('Topic')->get_meta( $_->{mid} );
            $_->{data} = $c->model('Topic')->get_data( undef, $_->{mid} );
            $_->{description} //= $_->{data}{description};
            $_->{name_status} ||= $_->{data}{name_status};
        }

        $_->{name} = $_->{categories}{is_release} eq '1' 
            ?  $_->{title}
            :  _loc($_->{categories}->{name}) . ' #' . $_->{mid};
        $_->{color} = $_->{categories}->{color};
        $_
    } $rs_topic->all;
    $c->stash->{json} = { totalCount=>scalar(@topics), data=>\@topics };
    $c->forward('View::JSON');
}

our %field_cache;

sub get_field_bodies {
    my ($self, $meta ) = @_;
    # load comp body for each field
    for my $field ( _array( $meta ) ) {
        next unless defined $field->{js};
        my $file = Baseliner->path_to( 'root', $field->{js} );
        _debug "field file: $file";
        if( !ref $file || $file->is_dir ) {
            _error "********ERROR: field file is not valid: $file ($field->{js})";
            next; 
        }
        _fail _loc("Template not found: %1 (%2)", $field->{js}, $file ) unless -e $file;
        # CACHE check - consider using Mason -- has its own cache
        my $modified_on = $file->stat->mtime;
        my $cache = $field_cache{ "$file" };
        if( defined $cache && $cache->{modified_on} == $modified_on ) {
            _debug "************ HIT CACHE ( $cache->{modified_on} == $modified_on ) for $file";
            $field->{body} = $cache->{body};
        } else {
            _debug "************ NOOO CACHE ( $cache->{modified_on} != $modified_on )  for $file";
            my $body = _mason( $field->{js} );
            $field_cache{ "$file" } = { modified_on=>$modified_on, body => $body };
            $field->{body} = $body;
        }
    }
    return $meta;
}

sub json : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
    
    ######################################################################################### 
    #my $id_category = $topic->id_category;    

    #my $row_category = $c->model('Baseliner::BaliTopicCategories')->find( $id_category );
    #my $forms;
    #if( ref $row_category ) {
    #    $forms = $self->form_build( $row_category->forms );
    #}

    ##########################################################################################
        
    my $ret = {};
    
    my $meta = $c->model('Topic')->get_meta( $topic_mid );
    my $data = $c->model('Topic')->get_data( $meta, $topic_mid, %$p );

    $meta = get_meta_permissions ($c, $meta, $data);
    
    $meta = $self->get_field_bodies( $meta );
    
    $ret->{topic_meta} = $meta;
    
    if (exists $data->{ci_mid}){
        my $data_ci = _ci($data->{ci_mid})->{_ci};
        $data->{ci_parent} = $data_ci;
    }
    
    $ret->{topic_data} = $data;
    $c->stash->{json} = $ret;
    
    $c->forward('View::JSON');
}

sub get_meta_permissions : Local {
    my ($c, $meta, $data, $name_category, $name_status) = @_;
    my @hidden_field;
    
    my $parse_category = $data->{name_category} ? _name_to_id($data->{name_category}) : _name_to_id($name_category);
    my $parse_status = $data->{name_status} ? _name_to_id($data->{name_status}) : _name_to_id($name_status);
    
    my $is_root = $c->model('Permissions')->is_root( $c->username );

    if (!$is_root) {
        for (_array $meta){
            my $parse_id_field = _name_to_id($_->{id_field});
            
            if($_->{fields}){
            	my @fields_form = _array $_->{fields};
                for my $field_form ( @fields_form ){
                    my $parse_field_form_id = $field_form->{id_field};
                    my $write_action = 'action.topicsfield.' .  $parse_category 
                    		. '.' .  $parse_id_field . '.' .  $parse_field_form_id . '.' . $parse_status . '.write';
                    #my $write_action = 'action.topicsfield.write.' . $_->{name_field};
                    #print ">>>>>>>>>Accion: " . $write_action . "\n";
                    
                    if ($c->model('Permissions')->user_has_action( username=> $c->username, action => $write_action )){
                        $field_form->{readonly} = \1;
                    }
                    
                    my $read_action = 'action.topicsfield.' .  $parse_category 
                    		. '.' .  $parse_id_field . '.' .  $parse_field_form_id  . '.' . $parse_status . '.read';
                    #my $read_action = 'action.topicsfield.read.' . $_->{name_field} if ! $write_action;
                    #_error $read_action;
                    #print ">>>>>>>>>Accion: " . $read_action . "\n";
            
                    if ($c->model('Permissions')->user_has_action( username=> $c->username, action => $read_action )){
                    	$field_form->{hidden} = \1;
                        #push @hidden_field, $field_form->{id_field};
                    }
                }
            }else{
                my $write_action = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.' . $parse_status . '.write';
                #my $write_action = 'action.topicsfield.' .  lc $data->{name_category} . '.' .  lc $_->{id_field} . '.' . lc $data->{name_status} . '.write';
                #my $write_action = 'action.topicsfield.write.' . $_->{name_field};
                
                
                if ($c->model('Permissions')->user_has_action( username=> $c->username, action => $write_action )){
                    $_->{readonly} = \1;
                }
                
                my $read_action = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.' . $parse_status . '.read';
                #my $read_action = 'action.topicsfield.' .  lc $data->{name_category} . '.' .  lc $_->{id_field} . '.' . lc $data->{name_status} . '.read';
                #my $read_action = 'action.topicsfield.read.' . $_->{name_field} if ! $write_action;
                #_error $read_action;
        
                if ($c->model('Permissions')->user_has_action( username=> $c->username, action => $read_action )){
                    push @hidden_field, $_->{id_field};
                }
            }
        }
        
        my %hidden_field = map { $_ => 1} @hidden_field;
        $meta = [grep { !($hidden_field{ $_->{id_field} }) } _array $meta];
        
    }
    _log _dump $meta;
    return $meta
}

sub new_topic : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    
    my $ret = try {
        my $id_category = $p->{new_category_id};
        my $name_category = $p->{new_category_name};
        my $rs_status = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $id_category, type => 'I'},
                                                                                            {
                                                                                            prefetch=>['status'],
                                                                                            }                                                                                 
                                                                                         )->first; 
        _fail( _loc('The topic category %1 does not have any initial status assigned. Contact your administrator.', $name_category) ) 
            unless $rs_status;
        my $name_status = $rs_status->status->name;
        my $meta = $c->model('Topic')->get_meta( undef, $id_category );
        $meta = $self->get_field_bodies( $meta );
        
        my $data;
        
        if ($p->{ci}){
            $data = _ci($p->{ci})->{_ci};
            $data->{title} = $data->{gdi_perfil_dni};
            if ($p->{clonar} && $p->{clonar} == -1){
                $data = $self->init_values_topic($data);
                if ($p->{dni}){
                    $data->{gdi_perfil_dni} = $p->{dni};
                }
                my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $id_category, type => 'I'},
                                                                                        {
                                                                                        prefetch=>['status'],
                                                                                        }                                                                                 
                                                                                     )->first;
                
                my $action = $c->model('Topic')->getAction($statuses->status->type);
                $data->{id_category_status} = $statuses->status->id;
                $data->{name_status} = $statuses->status->name;
                $data->{type_status} = $statuses->status->type;
                $data->{action_status} = $action;
            }
        }else{
            $data = $c->model('Topic')->get_data( $meta, undef );
            #Cetelem
            if($p->{dni}){
                if ($p->{clonar}){
                    $data = $c->model('Topic')->get_data( $meta, $p->{clonar} );
                    $data = $self->init_values_topic($data);
                    my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $data->{id_category}, type => 'I'},
                                                                                            {
                                                                                            prefetch=>['status'],
                                                                                            }                                                                                 
                                                                                         )->first;
                    
                    
                    my $action = $c->model('Topic')->getAction($statuses->status->type);
                    $data->{id_category_status} = $statuses->status->id;
                    $data->{name_status} = $statuses->status->name;
                    $data->{type_status} = $statuses->status->type;
                    $data->{action_status} = $action;                    
                }
                $data->{gdi_perfil_dni} = $p->{dni};
                $data->{title} = $data->{gdi_perfil_dni};
            }
        }
        
        map{ $data->{$_} = 'off'}  grep {$_ =~ '_done' && $data->{$_} eq 'on' } _array $data;
        
        $meta = get_meta_permissions ($c, $meta, $data, $name_category, $name_status);
        
        {
            success => \1,
            new_category_id     => $id_category,
            new_category_name   => $name_category,
            topic_meta          => $meta,
            topic_data          => $data,
        };
    } catch {
        { success=>\0, msg=>"".shift() } 
    };
    
    $c->stash->{json} = $ret;
    $c->forward('View::JSON');
}

sub init_values_topic : Private {
    my ($self, $data) = @_;

    $data->{topic_mid} = '';
    $data->{id_category_status} = '';
    $data->{name_status} = '';
    $data->{type_status} = '';
    $data->{action_status} = '';
    $data->{created_by} = '';
    $data->{created_on} = '';
    $data->{gdi_perfil_usuario_nombre} = '';
    $data->{gdi_perfil_usuario_apellidos} = '';
    
    return $data;
}

sub view : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid} || $p->{action};
    my $id_category;
    
    my $category;
    
    try {
    
    $c->stash->{ii} = $p->{ii};    
    $c->stash->{swEdit} =  ref($p->{swEdit}) eq 'ARRAY' ? $p->{swEdit}->[0]:$p->{swEdit} ;
    $c->stash->{permissionEdit} = 0;
    $c->stash->{permissionComment} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.GDI.comment' );
    if ($c->is_root){
        $c->stash->{HTMLbuttons} = 0;
    }
    else{
        $c->stash->{HTMLbuttons} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.GDI.HTMLbuttons' );
    }
    
    my %categories_edit = map { $_->{id} => 1} $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'edit' );
    
    if($topic_mid || $c->stash->{topic_mid} ){
 
        $category = DB->BaliTopicCategories->search({ mid=>$topic_mid }, { prefetch=>{'topics' => 'status'} })->first;
        _fail( _loc('Category not found or topic deleted: %1', $topic_mid) ) unless $category;
        
        $c->stash->{category_meta} = $category->forms;
        
        my %tmp;
        if ((substr $category->topics->status->type, 0, 1) eq "F"){
            $c->stash->{permissionEdit} = 0;
        }
        else{
            if ($c->is_root){
                $c->stash->{permissionEdit} = 1;     
            }else{
                if (exists ($categories_edit{ $category->id })){
                    $c->stash->{permissionEdit} = 1;
                }
            }
        }
                         
        # comments
        $self->list_posts( $c );  # get comments into stash        
        $c->stash->{events} = events_by_mid( $topic_mid, min_level => 2 );
        
        #$c->stash->{forms} = [
        #    map { "/forms/$_" } split /,/,$topic->categories->forms
        #];
 
        # jobs for release and changeset
        if( $category->is_changeset || $category->is_release ) {
            my @jobs = DB->BaliJob->search({ item=>{ -like => '%/' . $topic_mid } }, 
            { prefetch=>'bali_job_items', page=>0, rows=>20, order_by=>{ -desc=>'me.id' } })->hashref->all;
            $c->stash->{jobs} = \@jobs;
        }
    }else{
        $id_category = $p->{new_category_id};
        my $category = DB->BaliTopicCategories->find( $id_category );
        $c->stash->{category_meta} = $category->forms;
        $c->stash->{permissionEdit} = 1 if exists $categories_edit{$id_category};
        
        $c->stash->{topic_mid} = '';
        $c->stash->{events} = '';
        $c->stash->{comments} = '';
    }
    
    if( $p->{html} ) {
        my $meta = $c->model('Topic')->get_meta( $topic_mid, $id_category );
        my $data = $c->model('Topic')->get_data( $meta, $topic_mid, %$p );
        $meta = get_meta_permissions ($c, $meta, $data);        

        $c->stash->{topic_meta} = $meta;
        $c->stash->{topic_data} = $data;

        $c->stash->{template} = '/comp/topic/topic_msg.html';
    } else {
        $c->stash->{template} = '/comp/topic/topic_main.js';
    }
    } catch {
        $c->stash->{json} = { success=>\0, msg=>"". shift() };
        $c->forward('View::JSON');
    };
}

sub title_row : Local {
    my ($self, $c ) = @_;
    my $mid = $c->req->params->{mid};
    my $row = DB->BaliTopic->search(
        { mid => $mid }, { join=>'categories', 
        select=>[qw/mid title categories.name categories.color/], 
        as=>[qw/mid title category_name category_color/] } );
    $row = $row->hashref->first;
    $c->stash->{json} = { success=>$row ? \1 : \0, row => $row };
    $c->forward('View::JSON');
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
                    _fail( _loc("Topic with id %1 not found (deleted?)", $topic_mid ) ) unless $topic;
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
                _fail( _loc("This comment does not exist anymore") ) unless $post;
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
            _fail( _loc("This comment does not exist anymore") ) unless $post;
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
            my $post = $c->model('Baseliner::BaliPost')->find($id_com);
            _fail( _loc("This comment does not exist anymore") ) unless $post;
            # check if youre the owner
            _fail _loc( "You're not the owner (%1) of the comment.", $post->created_by ) 
                if $post->created_by ne $c->username;
            $c->stash->{json} = {
                failure=>\0,
                text       => $post->text,
                created_by => $post->created_by,
                created_on => $post->created_on->dmy . ' ' . $post->created_on->hms
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
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my @rows;
    
    if( !$p->{categoryId} ){    
        
        my @categories;
        if( $p->{action} && $p->{action} eq 'create' ){
            @categories  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => $p->{action} );
        } else {
            @categories  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view' );
        }
        
        if(@categories){
  
            foreach my $category (@categories){
                my @statuses;
                my $statuses = $c->model('Baseliner::BaliTopicCategoriesStatus')->search({id_category => $category->{id}});
                while( my $status = $statuses->next ) {
                    push @statuses, $status->id_status;
                }

                my $type = $category->{is_changeset} ? 'C' : $category->{is_release} ? 'R' : 'N';
                
                my @fields =
                    map { $_->{name_field} }
                    sort { ( $a->{field_order} // 100 ) <=> ( $b->{field_order} // 100 ) }
                    map { _load $_->{params_field} }
                    DB->BaliTopicFieldsCategory->search( { id_category => $category->{id} } )->hashref->all;
                    
                my @priorities = map { $_->id_priority } 
                    $c->model('Baseliner::BaliTopicCategoriesPriority')->search( {id_category => $category->{id}, is_active => 1}, {order_by=> {'-asc'=> 'id_priority'}} )->all;

                my $forms = $self->form_build( $category->{forms} );
                
                push @rows,
                {   id            => $category->{id},
                    category      => $category->{id},
                    name          => $p->{swnotranslate} ? $category->{name}: _loc($category->{name}),
                    color         => $category->{color},
                    type          => $type,
                    forms         => $forms,
                    category_name => _loc($category->{name}),
                    is_release    => $category->{is_release},
                    is_changeset  => $category->{is_changeset},
                    description   => $category->{description},
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
    
    #$row = $c->model('Baseliner::BaliLabel')->search();
    #
    #if($row){
    #    while( my $r = $row->next ) {
    #        push @rows,
    #          {
    #            id          => $r->id,
    #            name        => $r->name,
    #            color       => $r->color
    #          };
    #    }  
    #}
    
    @rows = Baseliner::Model::Label->get_labels( $c->username, 'admin' );
    
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
    my ($self, $c, $typeApplication) = @_;
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
        leaf    => 'true',
        uiProvider => 'Baseliner.CBTreeNodeUI_system'
        
    };
    
    if(!$typeApplication){
        push @views, {
            id  => $i++,
            idfilter      => 2,
            text    => _loc('Assigned To Me'),
            filter  => '{"assigned_to_me":true}',
            default    => \1,
            cls     => 'forum default',
            iconCls => 'icon-no',
            checked => \0,
            leaf    => 'true',
            uiProvider => 'Baseliner.CBTreeNodeUI_system'
        };
    }
    #################################################################################

    $row = $c->model('Baseliner::BaliTopicView')->search();
    
    if($row){
        while( my $r = $row->next ) {
            push @views, {
                id  => $i++,
                idfilter      => $r->id,
                text    => _loc($r->name),
                filter  => $r->filter_json,
                default    => \0,
                cls     => 'forum',
                iconCls => 'icon-no',
                checked => \0,
                leaf    => 'true',
                uiProvider => 'Baseliner.CBTreeNodeUI_system'
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
    

    # Filter: Categories ########################################################################################################
        
    my @categories;
    my $category_id = $c->req->params->{category_id};
    #$row = $c->model('Baseliner::BaliTopicCategories')->search();
    my @categories_permissions  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view' );
    if($category_id){
        @categories_permissions = grep { $_->{id} == $category_id } @categories_permissions;
    }

    
    if(@categories_permissions && scalar @categories_permissions gt 1){
        for( @categories_permissions ) {
            push @categories,
                {
                    id  => $i++,
                    idfilter      => $_->{id},
                    text    => _loc($_->{name}),
                    color   => $_->{color},
                    cls     => 'forum',
                    iconCls => 'icon-no',
                    #checked => \0,
                    checked => ( $category_id && $category_id eq $_->{id} ) ? \1: \0,
                    leaf    => 'true',
                    uiProvider => 'Baseliner.CBTreeNodeUI'
                };
        }
        
        push @tree, {
            id          => 'C',
            text        => _loc('Categories'),
            cls         => 'forum-ct',
            iconCls     => 'forum-parent',
            expanded    => 'true',
            children    => \@categories
        };
    }
    
    # Filter: Labels ##############################################################################################################
    if(!$typeApplication){
        my @labels; 
    
        #$row = $c->model('Baseliner::BaliLabel')->search();
        my @row = Baseliner::Model::Label->get_labels( $c->username );
        
        #if($row->count() gt 0){
        if(@row){
            foreach ( @row ) {
                push @labels, {
                    id          => $i++,
                    idfilter    => $_->{id},
                    text        => _loc($_->{name}),
                    color       => $_->{color},
                    cls         => 'forum label',
                    iconCls     => 'icon-no',
                    checked     => \0,
                    leaf        => 'true',
                    uiProvider => 'Baseliner.CBTreeNodeUI'                
                };	
            }          
            
            push @tree, {
                id          => 'L',
                text        => _loc('Labels'),
                cls         => 'forum-ct',
                iconCls     => 'forum-parent',
                children    => \@labels
            };
        }
    }
    
    
    # Filter: Status #############################################################################################################
    my @statuses;
    
    my $where = undef;
    my $arg = {order_by=>'seq'};
    
    if($category_id){
        $arg->{join} = ['categories_status'];
        $where->{'categories_status.id_category'} = $category_id;
    }
    $row = $c->model('Baseliner::BaliTopicStatus')->search($where,$arg);
    
    #$row = $c->model('Baseliner::BaliTopicStatus')->search(undef, { order_by=>'seq' });
    
    ##Filtramos por defecto los estados q puedo interactuar (workflow) y los que no tienen el tipo finalizado.        
    my %tmp;
    map { $tmp{$_->{id_status_from}} = 'id'; $tmp{$_->{id_status_to}} = 'id' } 
                Baseliner->model('Topic')->user_workflow( $c->username );

    if($row->count() gt 0){
        while( my $r = $row->next ) {
            push @statuses,
                {
                    id  => $i++,
                    idfilter      => $r->id,
                    text    => _loc($r->name),
                    cls     => 'forum status',
                    iconCls => 'icon-no',
                    checked => exists $tmp{$r->id} && (substr ($r->type, 0 , 1) ne 'F')? \1: \0,
                    leaf    => 'true',
                    uiProvider => 'Baseliner.CBTreeNodeUI'                    
                };
        }  

        push @tree, {
            id          => 'S',
            text        => _loc('Statuses'),
            cls         => 'forum-ct',
            iconCls     => 'forum-parent',
            expanded    => 'true',
            children    => \@statuses
        };
    }
    
    
    #Filter: Priority ########################################################################################################
    if(!$typeApplication){    
        my @priorities;
        $row = $c->model('Baseliner::BaliTopicPriority')->search();
        
        if($row->count() gt 0){
            while( my $r = $row->next ) {
                push @priorities,
                {
                    id  => $i++,
                    idfilter      => $r->id,
                    text    => _loc($r->name),
                    cls     => 'forum',
                    iconCls => 'icon-no',
                    checked => \0,
                    leaf    => 'true',
                    uiProvider => 'Baseliner.CBTreeNodeUI'                
                };
            }
            
            push @tree, {
                id          => 'P',
                text        => _loc('Priorities'),
                cls         => 'forum-ct',
                iconCls     => 'forum-parent',
                expanded    => 'true',
                children    => \@priorities
            };
            
        }
    }
        
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
                my $action = $c->model('Topic')->getAction($status->status->type);
                push @rows, {
                                id          => $status->status->id,
                                status      => $status->status->id,
                                name        => _loc($status->status->name),
                                status_name => _loc($status->status->name),
                                type        => $status->status->type,
                                action      => $action,
                                bl          => $status->status->bl,
                                description => $status->status->description
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


        my $rs_current_status = $c->model('Baseliner::BaliTopicStatus')->find({id => $p->{statusId}});
        
        push @rows, { id => $p->{statusId},
                     name => _loc($p->{statusName}),
                     status => $p->{statusId},
                     status_name => _loc($p->{statusName}),
                     action => $c->model('Topic')->getAction($rs_current_status->type)};
        
        push @rows , map {
            my $action = $c->model('Topic')->getAction($_->{status_type});
            +{
                id          => $_->{id_status},
                status      => $_->{id_status},
                name        => _loc($_->{status_name}),
                status_name => _loc($_->{status_name}),
                type        => $_->{status_type},
                action      => $action,
                bl          => $_->{status_bl},
                description => $_->{status_description},
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
        if($p->{topic_mid} && $p->{topic_mid} > 0){
            my $config = config_get( 'config.uploader' );
            my ($topic, $topic_mid, $file_mid);
            #if($p->{topic_mid}){
                $topic = $c->model('Baseliner::BaliTopic')->find( $p->{topic_mid} );
                $topic_mid = $topic->mid;
            #}
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
                    $topic->add_to_files( $existing, { rel_type=>'topic_file_version', rel_field=> $p->{filter} });
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
                            $topic->add_to_files( $file, { rel_type=>'topic_file_version', rel_field=> $p->{filter} });
                        }
                    };                        
                }
                    
                #$file_mid = $existing->mid;
            }
            $c->stash->{ json } = { success => \1, msg => _loc( 'Uploaded file %1', $filename ), file_uploaded_mid => $p->{topic_mid}? '': $file_mid, };            
        }
        else{
            $c->stash->{ json } = { success => \0, msg => _loc( 'You must save the topic before add new files' )};
        }
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
                    event_new 'event.file.remove' => {
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
           {'rel_field'=> $p->{filter}},
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
    return $form_str
        ? [ map {
                my $form_name = $_;
                +{
                    form_name => $_,
                    form_path => "/forms/$form_name.js",
                }
            } split /,/, $form_str ]
        : [];
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
        $job->stash_key( id_status_from => $p->{id_status_from});
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
          { +select=>['status.id', 'status.name', 'status.seq'], +as=>[qw/id name seq/], 
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

sub children : Local {
    my ($self, $c) = @_;
    my $mid = $c->req->params->{mid};
    my @chi = map { $_->{to_mid} } DB->BaliMasterRel->search({ from_mid => $mid, rel_type=>'topic_topic' })->hashref->all; 
    $c->stash->{json} = { success=>\1, msg=>'', children=>\@chi };
    $c->forward('View::JSON');
}

sub report_data_replace {
    my ($self, $data, $show_desc ) = @_;
    my @mids;
    for( _array( $data->{rows} ) ) {
        push @mids, $_->{topic_mid};
        # find and replace report_data columns 
        for my $col ( keys %{ $_->{report_data} || {} } ) {
            $_->{ $col } = $_->{report_data}->{ $col };
        }
    }
    if( $show_desc ) {
        my @descs = DB->BaliTopic->search({ mid=>\@mids }, { select=>'description' })->hashref->all;
        map {
            $_->{description} = ( shift @descs )->{description};
        } _array( $data->{rows} );
        push @{ $data->{columns} }, { name=>'Description', id=>'description' };
    }
    return $data;
}

sub report_html : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $data = $p->{data_json};
    $data = _decode_json $data;
    $data = $self->report_data_replace( $data, $p->{show_desc} );
    $c->stash->{data} = $data;
    $c->stash->{template} = '/reports/basic.html';
}

sub report_yaml : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $data_json = $p->{data_json};
    my $data = _decode_json $data_json;
    my $yaml = _dump( $data );
    $yaml = _utf8( $yaml );
    $c->res->body( qq{<!DOCTYPE html>\n<html>\n<head>\n<meta charset="utf-8">\n</head>\n<body>\n<pre>${yaml}</pre></body></html>} );
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

sub img : Local {
    my ($self, $c, $id ) = @_;
    my $p = $c->req->params;
    my $img = DB->BaliTopicImage->search({ id_hash=>$id })->first;
    if( $img ) {
        $c->res->content_type( $img->content_type || 'image/png');
        $c->res->body( $img->img_data );
    } else {
        $c->res->content_type( 'image/png');
        my $broken = $c->path_to('/root/static/images/icons/help.png')->slurp;
        $c->res->body( $broken );
    }
}

1;
