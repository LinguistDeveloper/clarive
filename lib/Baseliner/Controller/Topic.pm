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
register 'action.topics.view_graph' => { name=>'View related graph in topics' };

register 'registor.menu.topics' => {
    generator => sub {
       # action.topics.<category_name>.[create|edit|view]
       my @cats = mdb->category->find->fields({ name=>1, id=>1, color=>1 })->all;
       my $seq = 10;
       my $pad_for_tab = 'margin: 0 0 -3px 0; padding: 2px 4px 2px 4px; line-height: 12px;';
       my %menu_view = map {
           my $data = $_;
           my $name = _loc( $_->{name} );
           my $id = _name_to_id( $name );
           $data->{color} //= 'transparent';
           "menu.topic.$id" => {
                label    => qq[<div id="boot" style="background:transparent"><span class="label" style="background-color:$data->{color}">$name</span></div>],
                title    => qq[<div id="boot" style="background:transparent;height:14px;margin-bottom:0px"><span class="label" style="$pad_for_tab;background-color:$data->{color}">$name</span></div>],
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
                    comp_data => { tabTopic_force => 1 }, #force modify name and icon only for Topics Tab
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

    if( $$p{id_report} && $p->{id_report} =~ /^report\./ ) {
        my $report = Baseliner->registry->get( $p->{id_report} );
        my $config = undef; # TODO get config from custom forms
        $p->{dir} = uc($p->{dir}) eq 'DESC' ? -1 : 1;
        my $rep_data = $report->data_handler->($report,$config,$p);
        $c->stash->{json} = { data=>$rep_data->{rows}, totalCount=>$rep_data->{total}, config=>$rep_data->{config} };
    } elsif( $p->{id_report} ) {
        my $filter = $p->{filter} ? _decode_json($p->{filter}) : undef;
        my $start = $p->{start} // 0;
        

        #_log ">>>>>>>>>>>>>>>>>>>>>>>>FILTER: " . _dump $filter;
        for my $f (_array $filter){
            my @temp = split('_', $f->{field});
            #$f->{field} = join('_',@temp[0..$#temp-1]);
            $f->{category} = $temp[$#temp];
        }
        
        my ($cnt, @rows ) = ci->new( $p->{id_report} )->run( start=>$start, username=>$c->username, limit=>$p->{limit}, query=>$p->{topic_list}, filter=>$filter, query_search=>$p->{query} );
        #_log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>JSON: " . _dump  @rows;    
        $c->stash->{json} = { data=>\@rows, totalCount=>$cnt };
    } else {
        my ($cnt, @rows ) = $c->model('Topic')->topics_for_user( $p );
        $c->stash->{json} = { data=>\@rows, totalCount=>$cnt };
    }
   $c->forward('View::JSON');
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    
    $p->{username} = $c->username;
    my $return_options;   # used by event rules to return anything back to the form
    
    try  {
        my ($isValid, @field_name) = (1,());
        #my ($isValid, @field_name) = $c->model('Topic')->check_fields_required( mid => $p->{topic_mid}, username => $c->username, data => $p);

        if($isValid == 1){
            my ($msg, $topic_mid, $status, $title, $category, $modified_on);
            ($msg, $topic_mid, $status, $title, $category, $modified_on, $return_options) = $c->model('Topic')->update( $p );
            $c->stash->{json} = {
                success        => \1,
                msg            => _loc( $msg, scalar( _array( $p->{topic_mid} ) ) ),
                topic_mid      => $topic_mid,
                topic_status   => $status,
                return_options => $return_options // {},
                category       => $category,
                title          => $title,
                modified_on    => $modified_on,
            };            
        }
        else{
            $c->stash->{json} = { success => \0, fields_required=> \@field_name, return_options=>$return_options // {} };    
        }
    } catch {
        my $e = shift;
        $c->stash->{json} = { success => \0, msg=>_loc($e), return_options=>$return_options // {} };
    };
    $c->forward('View::JSON');
}

sub check_modified_on: Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $modified_before = \0;
    my $modified_rel = \0;
    my $topic_mid = $p->{topic_mid};
    
    my $duration;
    my $strDate = $p->{modified};
        
    use Class::Date;
    my $date_modified_on =  Class::Date->new( $strDate );
    
    my $doc = mdb->topic->find_one({ mid=>"$topic_mid" });
    my $date_actual_modified_on = Class::Date->new( $doc->{modified_on} );
    my $who = $doc->{modified_by};
    
    if ( $date_modified_on < $date_actual_modified_on ){
        $modified_before = $who;
        $duration = Util->to_dur( $date_actual_modified_on - $date_modified_on );
    } else {
        my $old_signature = $p->{rel_signature};
        my $new_signature = $c->model('Topic')->rel_signature($topic_mid);
        $modified_rel = \1 if $old_signature ne $new_signature;
    }
  
    $c->stash->{json} = {
        success                  => \1,
        modified_before          => $modified_before,
        modified_before_duration => $duration,
        modified_rel             => $modified_rel,
        msg                      => _loc( 'Prueba' ),
    };      
    $c->forward('View::JSON');
}

sub related : Local {
    my ($self, $c) = @_;
    my $username = $c->username;
    my $p = $c->request->parameters;

    my $where = {};

    my %filter;

    my $start = $p->{start} // 0;
    my $limit = $p->{limit} // 20;

    if ( $p->{mids} ){
        my @mids = _array $p->{mids};
        $filter{mid} = \@mids;    
    }

    if ( $p->{query} ){
        my $query = $p->{query};
        $where = $self->get_search_query_topic ( $query, $where );    
    }

    $filter{category_type} = 'release' if ($p->{show_release});

    if ($p->{filter} && $p->{filter} ne 'none'){
        delete $filter{category_type}; 
        my $filter_js = _decode_json($p->{filter});

        $filter{category_id}        =  $filter_js->{categories} if ( ref $filter_js->{categories} eq 'ARRAY' && scalar @{$filter_js->{categories}} > 0);
        $filter{category_status_id} =  $filter_js->{statuses} if ( ref $filter_js->{statuses} eq 'ARRAY' && scalar @{$filter_js->{statuses}} > 0);
        $filter{id_priority}        =  $filter_js->{priorities} if ( ref $filter_js->{priorities} eq 'ARRAY' && scalar @{$filter_js->{priorities}} > 0);
        $filter{labels}        =  $filter_js->{labels} if ( ref $filter_js->{labels} eq 'ARRAY' && scalar @{$filter_js->{labels}} > 0);

        delete $filter_js->{categories};
        delete $filter_js->{statuses};
        delete $filter_js->{priorities};
        delete $filter_js->{labels};
        delete $filter_js->{limit};
        delete $filter_js->{start};
        delete $filter_js->{typeApplication};

        for my $other_filter ( keys %$filter_js ) {
            $filter{$other_filter} = $filter_js->{$other_filter};
        }
    }

    $where = $c->model('Topic')->apply_filter( $username, $where, %filter );
    #_log _dump $where;

    my ($cnt, @result_topics) = $c->model('Topic')->get_topics_mdb( $where, $username, $start, $limit );

    my @topics = map {
        $_->{name} = _loc($_->{category}->{name}) . ' #' . $_->{mid};
        $_->{color} = $_->{category}{color};
        $_->{short_name} = $c->model('Topic')->get_short_name( name => $_->{category}->{name} ) . ' #' . $_->{mid};
        $_
    }  @result_topics;

    

    $c->stash->{json} = { totalCount => $cnt, data => \@topics };
    $c->forward('View::JSON');
}

sub get_search_query_topic {
    my ($self, $query, $where) = @_;
    _fail _loc("Missing parameter query") if ( !$query );
    $where = {} if ( !$where );

    mdb->query_build( query => $query, where => $where, fields => Baseliner->model('Topic')->get_fields_topic() );

    return $where;
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
            $field->{body} = ["$file", $cache->{body}, 0];
        } else {
            _debug "************ NOOO CACHE ( $cache->{modified_on} != $modified_on )  for $file";
            my $body = _mason( $field->{js} );
            $field_cache{ "$file" } = { modified_on=>$modified_on, body => $body };
            $field->{body} = ["$file", $body, 1 ];
        }
    }
    return $meta;
}

sub json : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
     
    my $ret = {};
    
    my $meta = $c->model('Topic')->get_meta( $topic_mid );
    my $data = $c->model('Topic')->get_data( $meta, $topic_mid, %$p );

    $meta = $self->get_meta_permissions ($c, $meta, $data);
    
    $meta = $self->get_field_bodies( $meta );
    
    $ret->{topic_meta} = $meta;
    
    if (exists $data->{ci_mid}){
        my $data_ci = _ci($data->{ci_mid})->{_ci};
        $data->{ci_parent} = $data_ci;
    }
    
    $ret->{topic_data} = $data;
    $ret->{rel_signature} = $c->model('Topic')->rel_signature($topic_mid);
    $c->stash->{json} = $ret;
    
    $c->forward('View::JSON');
}

sub get_meta_permissions : Private {
    my ($self,$c, $meta, $data, $name_category, $name_status,$username) = @_;
    my @hidden_field;
    
    $username //= $c->username;
    
    my $parse_category = $data->{name_category} ? _name_to_id($data->{name_category}) : _name_to_id($name_category);
    my $parse_status = $data->{name_status} ? _name_to_id($data->{name_status}) : _name_to_id($name_status);
    
    my $is_root = $c->model('Permissions')->is_root( $username );

    for (_array $meta){
        my $parse_id_field = _name_to_id($_->{name_field});
        
        if($_->{fieldlets}){
        	my @fields_form = _array $_->{fieldlets};
            for my $field_form ( @fields_form ){
                my $parse_field_form_id = $field_form->{id_field};
                my $write_action = 'action.topicsfield.' .  $parse_category 
                		. '.' .  $parse_id_field . '.' .  $parse_field_form_id . '.' . $parse_status . '.write';
                #my $write_action = 'action.topicsfield.write.' . $_->{name_field};
                #print ">>>>>>>>>Accion: " . $write_action . "\n";
                
                if ( $is_root ) {
                        $field_form->{readonly} = \0;
                        $field_form->{allowBlank} = 'true' unless $field_form->{id_field} eq 'title';
                } else {
                    my $has_action = $c->model('Permissions')->user_has_action( username=> $username, action => $write_action, mid => $data->{topic_mid} );
                    if ( $has_action ){
                        $field_form->{readonly} = \0;
                    }else{
                        $field_form->{readonly} = \1;
                    }
                }                    
                my $read_action = 'action.topicsfield.' .  $parse_category 
                        . '.' .  $parse_id_field . '.' .  $parse_field_form_id  . '.read';
                #my $read_action = 'action.topicsfield.read.' . $_->{name_field} if ! $write_action;
                #_error $read_action;
                #print ">>>>>>>>>Accion: " . $read_action . "\n";
        
                if ( $is_root ) {
                        $field_form->{hidden} = \0;
                } else {

                    if ($c->model('Permissions')->user_has_read_action( username=> $username, action => $read_action )){
                        $field_form->{hidden} = \1;
                        #push @hidden_field, $field_form->{id_field};
                    }
                }
            }
        }else{
            my $write_action = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.' . $parse_status . '.write';
            my $readonly = 0;
            if ( $is_root ) {
                    $_->{readonly} = \0;
                    $_->{allowBlank} = 'true' unless $_->{id_field} eq 'title';
            } else {

                my $has_action = $c->model('Permissions')->user_has_action( username=> $username, action => $write_action, mid => $data->{topic_mid} );
                # _log "Comprobando ".$write_action."= ".$has_action;
                if ( $has_action ){
                    $_->{readonly} = \0;
                }else{
                    $_->{readonly} = \1;    
                    $readonly = 1;
                }
            }
            
            my $read_action = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.read';
            my $read_action_status = 'action.topicsfield.' .  $parse_category . '.' .  $parse_id_field . '.' . $parse_status . '.read';

            if ( !$is_root ) {
                if ($c->model('Permissions')->user_has_read_action( username=> $username, action => $read_action  ) || $c->model('Permissions')->user_has_read_action( username=> $username, action => $read_action_status  ) || ($readonly && $_->{hidden_if_protected} eq 'true')){
                    push @hidden_field, $_->{id_field};
                }
            } 

        }
    }
    
    my %hidden_field = map { $_ => 1} @hidden_field;
    $meta = [grep { !($hidden_field{ $_->{id_field} }) } _array $meta];
        
    #_log _dump $meta;
    return $meta
}

sub new_topic : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    
    my $ret = try {
        my $id_category = $p->{new_category_id};
        my $name_category = $p->{new_category_name};
        my ($st) = grep { $$_{type} eq 'I' } values +{ ci->status->statuses( id_category=>"$id_category" ) };
        _fail( _loc('The topic category %1 does not have any initial status assigned. Contact your administrator.', $name_category) ) 
            unless $st;
        my $name_status = $st->{name};
        my $meta = $c->model('Topic')->get_meta( undef, $id_category, $c->username );
        $meta = $self->get_field_bodies( $meta );
        my $data = $c->model('Topic')->get_data( $meta, undef );
        map{ $data->{$_} = 'off'}  grep {$_ =~ '_done' && $data->{$_} eq 'on' } _array $data;
        $meta = $self->get_meta_permissions ($c, $meta, $data, $name_category, $name_status);
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
    ($topic_mid) = _array( $topic_mid ) if ref $topic_mid eq 'ARRAY';
    my $id_category;
    
    my $category;
    
    try {
    
        my $topic_doc;
        $c->stash->{ii} = $p->{ii};    
        $c->stash->{swEdit} =  ref($p->{swEdit}) eq 'ARRAY' ? $p->{swEdit}->[0]:$p->{swEdit} ;
        $c->stash->{permissionEdit} = 0;
        $c->stash->{permissionDelete} = 0;
        $c->stash->{permissionGraph} = $c->model("Permissions")->user_has_action( username => $c->username, action => 'action.topics.view_graph');
        $c->stash->{permissionComment} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.GDI.comment' );
        if ( $topic_mid ) {
            my $topic_ci;
            try {
                $topic_ci = ci->new( $topic_mid );
                $c->stash->{viewKanban} = $topic_ci->children( isa => 'topic' );
            } catch {
                $c->stash->{viewKanban} = 0;
            };
            $topic_doc = mdb->topic->find_one({ mid => "$topic_mid" });
        } else {
            $c->stash->{viewKanban} = 0;
        }

        if ($c->is_root){
            $c->stash->{HTMLbuttons} = 0;
        }
        else{
            $c->stash->{HTMLbuttons} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.GDI.HTMLbuttons' );
        }
        
        my %categories_edit = map { $_->{id} => 1} $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'edit', topic_mid => $topic_mid );
        my %categories_delete = map { $_->{id} => 1} $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'delete', topic_mid => $topic_mid );
        my %categories_view = map { $_->{id} => 1} $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view', topic_mid => $topic_mid );
        
        if($topic_mid || $c->stash->{topic_mid} ){
     
            # user seen
            for my $mid ( _array( $topic_mid ) ) {
                mdb->master_seen->update({ username=>$c->username, mid=>$mid },{ username=>$c->username, mid=>$mid, type=>'topic', last_seen=>mdb->ts },{ upsert=>1 });
            }
            
            $category = mdb->category->find_one({ id=>$topic_doc->{category}{id} },{ fieldlets=>0 });
            
            _fail( _loc('Category not found or topic deleted: %1', $topic_mid) ) unless $category;
            
            if ( !$categories_view{$category->{id} } ) {
                _fail( _loc("User %1 is not allowed to access topic %2 contents", $c->username, $topic_mid) );    
            }

            if ( !$c->model('Permissions')->user_can_topic_by_project( username => $c->username, mid => $topic_mid ) ) {
                _fail( _loc("User %1 is not allowed to access topic %2 contents", $c->username, $topic_mid) );    
            }

            $c->stash->{category_meta} = $category->{forms};

            # workflow category-status
            my @statuses = 
                sort { ( $a->{seq} // 0 ) <=> ( $b->{seq} // 0 ) } 
                grep { $_->{id_status} ne $topic_doc->{category_status}{id} } 
                $c->model('Topic')->next_status_for_user(
                    id_category    => $category->{id},
                    id_status_from => $topic_doc->{category_status}{id},
                    username       => $c->username,
                    topic_mid      => $topic_mid
                );            
            my %tmp;
            if ((substr $topic_doc->{category_status}{type}, 0, 1) eq "F"){
                $c->stash->{permissionEdit} = 0;
                $c->stash->{permissionDelete} = 0;
            }
            else{
                if ($c->is_root){
                    $c->stash->{permissionEdit} = 1;     
                    $c->stash->{permissionDelete} = 1;     
                }else{
                    if (exists ($categories_edit{ $category->{id} })){
                        $c->stash->{permissionEdit} = 1;
                    }
                    if (exists ($categories_delete{ $category->{id} })){
                        $c->stash->{permissionDelete} = 1;
                    }
                }
            }
                             
            $c->stash->{has_comments} = $c->model('Topic')->list_posts( mid=>$topic_mid, count_only=>1 );
     
            # jobs for release and changeset
            if ( $category->{is_changeset} || $category->{is_release} ) {
                my @jobs = ci->parents(
                    mid      => $topic_mid,
                    rel_type => 'job_' . ( $category->{is_changeset} ? 'changeset' : 'release' ),
                    no_rels  => 1,
                    order_by => { -desc => 'from_mid' }
                );
                $c->stash->{jobs} = \@jobs;
            }
            
            $c->stash->{status_items_menu} = _encode_json(\@statuses);
        } else {
            $id_category = $p->{new_category_id} // $p->{category_id};
            
            my $category = mdb->category->find_one({ id=>"$id_category" });
            $c->stash->{category_meta} = $category->{forms};

            my $first_status = ci->status->find_one({ id_status=>mdb->in( $category->{statuses} ), type=>'I' }) // _fail( _loc('No initial state found '));
            
            my @statuses =
                sort { ( $a->{seq} // 0 ) <=> ( $b->{seq} // 0 ) }
                grep { $_->{id_status} ne $first_status->{id_status} } 
                $c->model('Topic')->next_status_for_user(
                    id_category    => $id_category,
                    id_status_from => $first_status->{id_status},
                    username       => $c->username,
                    topic_mid      => $topic_mid
                );
            $c->stash->{status_items_menu} = _encode_json(\@statuses);
            $c->stash->{category_meta} = $category->{forms};
            
            $c->stash->{permissionEdit} = 1 if exists $categories_edit{$id_category};
            $c->stash->{permissionDelete} = 1 if exists $categories_delete{$id_category};
            
            $c->stash->{has_comments} = 0;
            $c->stash->{topic_mid} = '';
        }
        
        if( $p->{html} ) {
            my $meta = $c->model('Topic')->get_meta( $topic_mid, $id_category );
            my $data = $c->model('Topic')->get_data( $meta, $topic_mid, topic_child_data=>$p->{topic_child_data} );
            $meta = $self->get_meta_permissions ($c, $meta, $data);        

            my $write_action = 'action.topicsfield.' .  _name_to_id($topic_doc->{name_category}) . '.labels.' . _name_to_id($topic_doc->{name_status}) . '.write';

            $data->{admin_labels} = $c->model('Permissions')->user_has_any_action( username=> $c->username, action=>$write_action );
            
            $c->stash->{topic_meta} = $meta;
            $c->stash->{topic_data} = $data;
            
            $c->stash->{template} = '/comp/topic/topic_msg.html';
        } else {
            $c->stash->{template} = '/comp/topic/topic_main.js';
        }
    } catch {
        $c->stash->{json} = { success=>\0, msg=>_loc("Problem found opening topic %1.  Perhaps it's been removed from the system.  The error message is: %2", $topic_mid, shift()) };
        $c->forward('View::JSON');
    };
}

sub title_row : Local {
    my ($self, $c ) = @_;
    my $mid = $c->req->params->{mid};
    my $row = mdb->topic->find_one({ mid=>"$mid" },{ mid=>1, title=>1, category_name=>1, category_color=>1 });
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

            my $topic_row = mdb->topic->find_one({ mid=>"$topic_mid" });
            _fail( _loc("Topic with id %1 not found (deleted?)", $topic_mid ) ) unless $topic_row;
            
            my $topic;
            if( ! length $id_com ) {  # optional, if exists then is not add, it's an edit
                
                my $post = ci->post->new({   
                        topic        => $topic_mid,
                        content_type => $content_type,
                        created_by   => $c->username,
                        created_on   => mdb->ts,
                });
                local $Baseliner::CI::ci_record = 1;

                # notification data
                my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>"$topic_mid", rel_type=>'topic_project' });
                my @users = Baseliner->model("Topic")->get_users_friend(
                        id_category => $topic_row->{category}{id}, 
                        id_status   => $topic_row->{category_status}{id}, 
                        projects    => \@projects );
                my $subject = _loc("%1 created a post for topic [%2] %3", $c->username, $topic_row->{mid}, $topic_row->{title} );
                my $notify = { #'project', 'category', 'category_status'
                    category        => $topic_row->{category}{id},
                    category_status => $topic_row->{category_status}{id},
                    project => \@projects,
                };
                # save the post
                my $mid_post = $post->save;
                $post->put_data( $text ); 
                event_new 'event.post.create' => {
                    username        => $c->username,
                    mid             => $topic_mid,
                    data            => ci->new($topic_mid)->{_ci},
                    id_post         => $mid_post,
                    post            => $text,
                    notify_default  => \@users,
                    subject         => $subject,
                    notify=>$notify 
                };
            } else {
                my $post = ci->find( $id_com );
                _fail( _loc("This comment does not exist anymore") ) unless $post;
                $post->update( text=>$text, content_type=>$content_type );
            }

            # modified_on 
            mdb->topic->update({ mid=>"$topic_mid" },{ '$set'=>{ modified_on=>mdb->ts } });

            $c->stash->{json} = {
                msg     => _loc('Comment added'),
                id      => $id_com,
                success => \1
            };
        } catch {
            my $err = shift;
            _error( $err );
            $c->stash->{json} = { msg => _loc('Error adding Comment: %1', $err ), failure => \1 }
        };
    } elsif( $action eq 'delete' )  {
        try {
            my $id_com = $p->{id_com};
            _fail( _loc( 'Missing id' ) ) unless defined $id_com;
            my $post = ci->find( $id_com );
            _fail( _loc("This comment does not exist anymore") ) unless $post;
            my $text = $post->text;
            # find my parents to notify via events
            my @mids = map { $_->mid } $post->parents( isa=>'topic' );
            # delete the record
            $post->delete;
            # now notify my parents
            for my $mid_topic ( @mids ) {
                my $topic_row = mdb->topic->find_one({ mid=>$mid_topic });
                my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>"$mids[0]", rel_type=>'topic_project' });
                my @users = Baseliner->model("Topic")->get_users_friend(id_category => $topic_row->{category}{id}, 
                    id_status=>$topic_row->{category}{status}, projects=>\@projects);
                my $subject = _loc("%1 deleted a post from topic [%2] %3", $c->username, $topic_row->{mid}, $topic_row->{title});
                my $notify = { #'project', 'category', 'category_status'
                    category        => $topic_row->{category}{id},
                    category_status => $topic_row->{category_status}{id},
                    project => \@projects
                };

                event_new 'event.post.delete' => { username => $c->username, mid => $mid_topic, id_post=>$id_com,
                    post            => substr( $text, 0, 30 ) . ( length $text > 30 ? "..." : "" ),
                    notify_default  => \@users,
                    subject         => $subject,
                    notify          => $notify
                };
            }
            $c->stash->{json} = { msg => _loc('Delete comment ok'), failure => \0 };
        } catch {
            my $err = shift;
            _error( $err );
            $c->stash->{json} = { msg => _loc('Error deleting Comment: %1', $err ), failure => \1 }
        };
    } elsif( $action eq 'view' )  {
        try {
            my $id_com = $p->{id_com};
            my $post = ci->find($id_com);
            _fail( _loc("This comment does not exist anymore") ) unless $post;
            # check if youre the owner
            _fail _loc( "You're not the owner (%1) of the comment.", $post->created_by ) 
                if $post->created_by ne $c->username;
            $c->stash->{json} = {
                failure=>\0,
                text       => $post->text,
                created_by => $post->created_by,
                created_on => $post->created_on,
            };
        } catch {
            my $err = shift;
            _error( $err );
            $c->stash->{json} = { msg => _loc('Error viewing comment: %1', $err ), failure => \1 }
        };
    }
    $c->forward('View::JSON');
}

sub list_category : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my ($dir, $sort, $cnt) = ( @{$p}{qw/dir sort/}, 0 );
    $dir ||= 'asc';
    $sort ||= 'name';
    
    my $order = { dir=> $dir, sort=> $sort};
    my @rows;
    
    if( !$p->{categoryId} ){    
        
        my @categories;
        if( $p->{action} && $p->{action} eq 'create' ){
            @categories  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => $p->{action}, order => $order);
        } else {
            @categories  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view', order => $order);
        }
        
        if(@categories){
            foreach my $category (@categories){
                my @statuses = _array( $category->{statuses} );

                my $type = $category->{is_changeset} ? 'C' : $category->{is_release} ? 'R' : 'N';
                
                my @fieldlets =
                    map { $_->{name_field} }
                    sort { ( $a->{field_order} // 100 ) <=> ( $b->{field_order} // 100 ) }
                    map { $_->{params} }
                    _array( mdb->category->find_one({ id => ''.$category->{id} })->{fieldlets} );
                    
                my $forms = $self->form_build( $category->{forms} );
                
                push @rows, {
                    id            => $category->{id},
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
                    fields        => \@fieldlets,
                    #priorities    => \@priorities
                };
            }  
        }
        $cnt = @rows;
    }else{
        # Status list for combo and grid in workflow 
        my $cat = mdb->category->find_one({ id=>mdb->in($p->{categoryId}) },{ statuses=>1 });
        my @statuses = sort { $a->seq <=> $b->seq } ci->status->search_cis( id_status=>mdb->in($$cat{statuses}) );
        for my $status ( @statuses ) {
            push @rows, {
                            id      => $status->id_status,
                            bl      => $status->bl,
                            name    => $status->name_with_bl,
                        };
        }
        $cnt = @rows;
    }
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}


sub list_label : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($dir, $sort, $cnt) = ( @{$p}{qw/dir sort/}, 0 );
    $dir = $dir && lc $dir eq 'desc' ? -1 : 1;
    $sort ||= 'name';
    
    my @rows;
    my $rs = mdb->label->find->sort({ $sort => $dir});
    while( my $r = $rs->next ) {
        push @rows,
          {
            id          => $r->{id},
            name        => $r->{name},
            color       => $r->{color}
          };
    }  
    
    $cnt = $#rows + 1 ; 
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update_topic_labels : Local {
    my ($self,$c) = @_;
    my $p = $c->req->params;
    my $topic_mid = $p->{topic_mid};
    my @label_ids = _array( $p->{label_ids} );
    
    try{
        if( my $doc = mdb->topic->find_one({ mid=>"$topic_mid"}) ) {
            my @current_labels = _array( $doc->{labels} );
            mdb->topic->update({ mid => "$topic_mid"},{ '$set' => {labels => \@label_ids}});
        }
        $c->stash->{json} = { msg=>_loc('Labels assigned'), success=>\1 };
        cache->remove( qr/:$topic_mid:/ ) if length $topic_mid;
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error assigning Labels: %1', shift()), failure=>\1 }
    };
     
    $c->forward('View::JSON');    
}

sub delete_topic_label : Local {
    my ($self,$c, $topic_mid, $label_id)=@_;
    try{
        cache->remove( qr/:$topic_mid:/ ) if length $topic_mid;
        mdb->topic->update({ mid => "$topic_mid" },{ '$pull'=>{ labels=>$label_id } },{ multiple=>1 });
        $c->stash->{json} = { msg=>_loc('Label deleted'), success=>\1, id=> $label_id };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error deleting label: %1', shift()), failure=>\1 }
    };
    
    $c->forward('View::JSON');    
}


sub update_project : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $topic_mid = $p->{topic_mid};
    my $id_project = $p->{id_project};
    my $field;

    try{
        my $project = ci->new( $id_project );
        if( ref $project ) {
            my $meta = $c->model('Topic')->get_meta( $topic_mid );
            _fail _loc 'No metadata found for this topic (%1)', $topic_mid unless ref $meta eq 'ARRAY';
            $field = [ 
                sort { ($a->{field_order}//0) cmp ($b->{field_order}//0) } 
                grep { !defined $_->{main_field} || $_->{main_field} }  # main_field tells me this is the one to drop on 
                grep { ( !defined $_->{collection} || $_->{collection} eq 'project') && $_->{meta_type} eq 'project' } 
                @$meta 
            ]->[0];
            _fail _loc 'No project field found for this topic (%1)', $topic_mid unless $field;
            # get current data
            my $id_field = $field->{id_field};
            my $doc = mdb->topic->find_one({ mid=>"$topic_mid" },{ $id_field => 1 }); 
            _fail _loc 'Topic not found: %1', $topic_mid unless ref $doc;
            my $fdata = [ _array( $doc->{$id_field} ) ];
            push $fdata, $id_project;
            $c->model('Topic')->update({ action=>'update', topic_mid=>$topic_mid, username=>$c->username, $id_field=>$fdata }); 
        } else {
            _fail _loc 'Project not found: %1', $id_project;
        }
        $c->stash->{json} = { msg=>_loc("Project added to field '%1'", $field->{name_field}), success=>\1 };
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
    
    push @views, {
        id  => $i++,
        idfilter      => 3,
        text    => _loc('Unread'),
        filter  => '{"unread":true}',
        default    => \1,
        cls     => 'forum default',
        iconCls => 'icon-no',
        checked => \0,
        leaf    => 'true',
        uiProvider => 'Baseliner.CBTreeNodeUI_system'
    };
            
    push @views, {
        id  => $i++,
        idfilter      => 4,
        text    => _loc('Created for Me'),
        filter  => '{"created_for_me":true}',
        default    => \1,
        cls     => 'forum default',
        iconCls => 'icon-no',
        checked => \0,
        leaf    => 'true',
        uiProvider => 'Baseliner.CBTreeNodeUI_system'
    };            
    #################################################################################

    push @tree, {
        id          => 'V',
        text        => _loc('Filters'),
        cls         => 'forum-ct',
        iconCls     => 'forum-parent',
        children    => \@views
    };   
    

    # Filter: Categories ########################################################################################################
        
    my @categories;
    my $category_id = $c->req->params->{category_id};
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
    my @id_categories = map { $_->{id} } @categories_permissions;
    my @cat_statuses = mdb->category->find_values( statuses=>{ id=>mdb->in(@id_categories) } );
    my $where = { '$and'=>[{ id_status=>mdb->in(@cat_statuses)}] };
    
    # intersect statuses with a reduced set?
    my $status_id = $c->req->params->{status_id};
    if ($status_id) {
        my @status_id = _array( $status_id );
        push @{ $where->{'$and'} }, { id_status=>mdb->in(@status_id) };
    }
    my $rs_status = ci->status->find($where)->sort({ seq=>1 });
    
    my $is_root = Baseliner->model('Permissions')->is_root( $c->username );
    ##Filtramos por defecto los estados q puedo interactuar (workflow) y los que no tienen el tipo finalizado.        
    my %tmp;

    if ( !$is_root ) {
        map { $tmp{$_->{id_status_from}} = 'id' } 
                    Baseliner->model('Topic')->user_workflow( $c->username );        
    };

    if( $rs_status->count > 1 ){
        while( my $r = $rs_status->next ) {
            my $checked;

            if ( $is_root ) {
                $checked = \1;
            } else {
                $checked = exists $tmp{$r->id} && (substr ($r->type, 0 , 1) ne 'F')? \1: \0;
            }
            push @statuses,
                {
                    id  => $i++,
                    idfilter      => $r->{id_status},
                    text    => _loc($r->{name}),
                    cls     => 'forum status',
                    iconCls => 'icon-no',
                    checked => $checked,
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
    my @statuses;
    my $topic_mid = $p->{topic_mid};

    if ($p->{change_categoryId}){
        if ($p->{statusId}){
            # intersect statusId and change_categoryId
            @statuses =
                sort { $$a{seq} <=> $$b{seq} }
                values +{
                    ci->status->statuses( id_category => '' . $p->{change_categoryId}, id_status => mdb->in( $p->{statusId} ) )
                };
        }
        if( !@statuses ){
            @statuses =
                sort { $$a{seq} <=> $$b{seq} }
                values +{ ci->status->statuses( id_category => '' . $p->{change_categoryId}, type => 'I' ) };
        }
        
        for my $status ( @statuses ) {
            my $action = $c->model('Topic')->getAction($status->{type});
            push @rows, {
                            id          => $status->{id_status},
                            status      => $status->{id_status},
                            name        => _loc($status->{name}),
                            status_name => _loc($status->{name}),
                            type        => $status->{type},
                            action      => $action,
                            bl          => $status->{bl},
                            description => $status->{description}
                        };
        }

    } else {
        my @statuses = $c->model('Topic')->next_status_for_user(
            id_category    => $p->{categoryId},
            id_status_from => $p->{statusId},
            username       => $c->username,
            topic_mid     => $topic_mid
        );

        my $status_id   = $p->{statusId};
        my $current_status = ci->status->find_one({ id_status=>''.$p->{statusId} }) // _fail( _loc('Status not found: %1', $p->{statusId}) );
        my $status_name = _loc( $p->{statusName} || $current_status->{name} );
        push @rows, { 
            id          => $status_id,
            name        => $status_name,
            status      => $status_id,
            status_name => $status_name,
            action      => $c->model('Topic')->getAction($current_status->{type}),
        };
        
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
        }  sort { ( $a->{seq} // 0 ) <=> ( $b->{seq} // 0 ) } @statuses;            
        #} grep { $_->{id_status} ne $p->{statusId} } @statuses;
        
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
    
    my $f;    
    if( $c->req->body eq ''){
        my $x = $c->req->upload('qqfile');
        $f =  _file( $x->tempname );
    }else{
        $f =  _file( ''. $c->req->body );
    }
    _log "Uploading file " . $filename;
    try {
        if( length $p->{topic_mid} ) {
            my ($topic, $topic_mid, $file_mid);
            
            $topic = mdb->topic->find_one({ mid=>"$p->{topic_mid}" });
            $topic_mid = $topic->{mid};
            #my @projects = ci->children( mid=>$_->{mid}, does=>'Project' );
            my @users = Baseliner->model("Topic")->get_users_friend(
                mid         => $p->{topic_mid}, 
                id_category => $topic->{category}{id}, 
                id_status   => $topic->{category_status}{id},
                #  projects    => \@projects  # get_users_friend ignores this
            );
            
            my $versionid = 1;
            # increase file version?  if same md5 found...
            #if(mdb->grid->files->find_one({ md5=>$
            #   $versionid = $file[0] + 1;
            #}
                
            my $asset = ci->asset->new( 
                name=>$filename, 
                versionid=>$versionid, 
                extension=>$extension, 
                created_by => $c->username,
                created_on => mdb->ts,
            );
            $asset->save;
            $asset->put_data( $f->openr );
            
            if ($p->{topic_mid}){
                my $subject = _loc("Created file %1 to topic [%2] %3", $filename, $topic->{mid}, $topic->{title});                            
                event_new 'event.file.create' => {
                    username        => $c->username,
                    mid             => $topic_mid,
                    id_file         => $asset->mid,
                    filename        => $filename,
                    notify_default  => \@users,
                    subject         => $subject
                };
                
                # tie file to topic
                my $doc = { from_mid=>$topic_mid, to_mid=>$asset->mid, rel_type=>'topic_asset', rel_field=>$$p{filter} };
                mdb->master_rel->update($doc,$doc,{ upsert=>1 });
            }
                    
            $c->res->body('{"success": "true", "msg":"' . _loc( 'Uploaded file %1', $filename ) . '", "file_uploaded_mid":"' . $file_mid . '"}');
        } else {
            $c->res->body('{"success": "false", "msg":"' . _loc( 'You must save the topic before add new files' ) . '"}');
        }
    } catch {
        my $err = shift;
        _error( "Error uploading file: " . $err );
        $c->res->status( 500 );
        $c->res->body('{"success": "false", "msg":"' . $err . '"}');
    };
}

sub file : Local {
    my ( $self, $c, $action ) = @_;
    my $p      = $c->req->params;
    my $topic_mid = $p->{topic_mid};
    
    try {
        my $msg; 
        if( $action eq 'delete' ) {
            for my $mid ( _array( $p->{asset_mid} ) ) {
                my $ass = ci->find( $mid );
                ref $ass or _fail _loc("File id %1 not found", $mid );
                my $count = mdb->master_rel->find({ to_mid=>$ass->mid })->count;  # only used when assets are shared by 2+ topics
                
                my $topic = mdb->topic->find_one({ mid=> "$$p{topic_mid}" });
                my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>"$$p{topic_mid}", rel_type=>'topic_project' });
                my @users = $c->model('Topic')->get_users_friend(
                    id_category => $topic->{category}{id},
                    id_status   => $topic->{category_status}{id},
                    projects    => \@projects
                );
                
                if( $count < 2 ) {
                    _log "Deleting file " . $ass->mid;
                    my $subject = _loc("Deleted file %1", $ass->filename);
                    event_new 'event.file.remove' => {
                        username        => $c->username,
                        mid             => $topic_mid,
                        id_file         => $ass->mid,
                        filename        => $ass->filename,
                        notify_default  => \@users,
                        subject         => $subject
                    };                  
                    $ass->delete;
                    $msg = _loc( "File deleted ok" );
                } else {
                    # starting in 6.2 assets are not shared, may change back in the future
                    my $subject = _loc("Detached file %1 from topic [%2] %3", $ass->filename, $topic->mid, $topic->title,);
                    event_new 'event.topic.file_remove' => {
                        username => $c->username,
                        mid      => $topic_mid,
                        id_file  => $ass->mid,
                        filename => $ass->filename,
                        notify_default => \@users,
                        subject         => $subject
                        }
                    => sub {
                        my $rel = mdb->master_rel->find_one({ from_mid=>"$topic_mid", to_mid=>$ass->mid });
                        _log "Deleting file from topic $topic_mid ($rel) = " . $ass->mid;
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
    my ( $self, $c, $mid ) = @_;
    my $p = $c->req->params;
    my $ass = ci->find( $mid );
    if( defined $ass ) {
        my $filename = $ass->name;
        utf8::encode( $filename );
        $c->stash->{serve_filename} = $filename;
        $c->stash->{serve_body} = $ass->slurp;
        $c->forward('/serve_file');
    } else {
        $c->res->body(_loc('File %1 not found', $mid ) );
    }
}

sub file_tree : Local {
    my ( $self, $c ) = @_;
    my $p         = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
    my @files     = ();

    if ($topic_mid) {
        my @assets = mdb->master_rel->find_values( to_mid => { from_mid=>"$topic_mid", rel_type=>'topic_asset' } );
        @files = map {
            my $ass = $_;
            my ( $size, $unit ) = Util->_size_unit( $ass->filesize );
            $size = "$size $unit";
            +{ filename=>$ass->filename, versionid=>$ass->versionid, mid=>$ass->mid, _id => $ass->mid, _parent => undef, _is_leaf => \1, size => $size }
        } ci->asset->search_cis( mid => mdb->in(@assets) );
    } else {
        my @files_mid = _array( $p->{files_mid} );
        @files = map {
            my $ass = $_;
            my ( $size, $unit ) = Util->_size_unit( $ass->filesize );
            $size = "$size $unit";
            +{ filename=>$ass->filename, versionid=>$ass->versionid, mid=>$ass->mid, _id => $ass->mid, _parent => undef, _is_leaf => \1, size => $size }
        } ci->asset->search_cis( mid => mdb->in(@files_mid) );
    }
    $c->stash->{json} = { total => scalar(@files), success => \1, data => \@files };
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
        my $topic_row;
        my @topic_projects;
        if ( $p->{topic_mid}) {
            $topic_row = mdb->topic->find_one({ mid=>"$$p{topic_mid}" });
            @topic_projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>"$$p{topic_mid}", rel_type=>'topic_project' });
        }
        if($p->{roles} && $p->{roles} ne 'none'){
            my @name_roles = map {lc ($_)} split /,/, $p->{roles};
            my @id_roles;
            foreach my $role_name (@name_roles){
                push @id_roles, mdb->role->find_one({ role=>$role_name })->{id};
            }
            if (@id_roles){
                $users_friends = $c->model('Users')->get_users_from_mid_roles(roles => \@id_roles, projects => \@topic_projects); 
            }
        }else{
            $users_friends = $c->model('Users')->get_users_friends_by_username($username);    
        }
    }
    $row = ci->user->find({username => $users_friends})->sort({realname => 1}); 
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
    my $changesets = $p->{changesets} or _throw 'Missing parameter changesets';
    my $bl = $p->{bl} or _throw 'Missing parameter bl';

    $c->stash->{json} = try {
        # create job CI
        my $job;
        my $job_type = $p->{job_type} || 'static';
        my $job_data = {
            bl         => $bl,
            job_type   => $job_type,
            username   => $c->username || $p->{username} || `whoami`,
            comments   => $p->{comments},
            changesets => $changesets,
        };
        event_new 'event.job.new' => { username => $job_data->{username}, bl => $job_data->{bl}  } => sub {

            my $job = ci->job->new( $job_data );
            $job->save;  # after save, CHECK and INIT run
            $job->job_stash({   # job stash autosaves into the stash table
                status_from    => $p->{status_from},
                status_to      => $p->{status_to},
                id_status_from => $p->{id_status_from},
            }, 'merge');
            my $job_name = $job->{name};
            my $subject = _loc("The user %1 has created job %2 for %3 bl", $c->username, $job_name, $job_data->{bl});
            my @projects = map {$_->{mid} } _array($job->{projects});
            my $notify = {
                project => \@projects,
                baseline => $job_data->{bl}
            };
            { jobname => $job_name, mid=>$job->{mid}, id_job=>$job->{jobid}, subject => $subject, notify => $notify };

        };
        { success=>\1, msg=> _loc( "Job %1 created ok", $job->name ) };
    } catch {
        my $err = shift;
        $err =~ s({UNKNOWN})()g;
        $err =~ s{DBIx.*\(\):}{}g;
        $err =~ s{ at./.*line.*}{}g;
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
        my @cats = _unique( mdb->topic->find_values( id_category=>{ mid=>mdb->in($topics) }) );

        my @cat_status = mdb->category->find({ id =>mdb->in(@cats) })->fields({ statuses=>1 })->all;
        ## support multiple bls
        my %status_cis = ci->status->statuses;
        my @statuses = map {
            my $st = $_;
            my $bls = join ' ', map { $_->{moniker} } _array($st->{bl});  # XXX where are the multiple bls in ci status?
            +{ id=>$$st{id_status}, name=>$$st{name}, seq=>$$st{seq}, bl=>$bls };
        } sort { $$a{seq}<=>$$b{seq} } grep { defined } map { $status_cis{$_} } _unique map { _array($$_{statuses}) } @cat_status;

        # given a user, find my workflow status froms and tos
        my @roles = ci->user->roles( $c->username );
        my @rs2 = mdb->joins({ merge=>'flat' }, topic=>[{ mid =>mdb->in($topics) },{ fields=>{ _txt=>0 } }], 
            id_category=>id_category=>workflow=>{ id_role=>mdb->in(@roles) } );
        
        my %workflow;
        my %status_mids;
        for my $wf ( @rs2 ) {
            push @{ $workflow{ $wf->{mid} } }, $wf;
            if( $wf->{id_status_from} == $wf->{id_category_status} ) {
                push @{ $status_mids{ $wf->{id_status_from} } }, $wf->{mid};
                push @{ $status_mids{ $wf->{id_status_to} } }, $wf->{mid};
            }
        }
        { success=>\1, msg=>'', statuses=>\@statuses, workflow=>\%workflow, status_mids=>\%status_mids };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error creating job: %1", "$err" ) };
    };
    $c->forward('View::JSON');
}

sub children : Local {
    my ($self, $c) = @_;
    my $mid = $c->req->params->{mid};
    my @chi = map { $_->{to_mid} } mdb->master_rel->find({ from_mid=>"$mid", rel_type=>'topic_topic' })->all; 
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
        my @descs = mdb->topic->find({ mid=>mdb->in(@mids) })->fields({ description=>1 })->all;
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
    my $json = $p->{data_json};
    my $data = _decode_json $json;
    
    my @csv;
    my @cols;
    for( grep { length $_->{name} } _array( $data->{columns} ) ) {
        push @cols, qq{"$_->{name}"}; #"
    }
    push @csv, join ';', @cols;

    for my $row ( _array( $data->{rows} ) ) {
        my @cells;
        for my $col ( grep { length $_->{name} } _array( $data->{columns} ) ) {
            my $v = $row->{ $col->{id} };
            if( ref $v eq 'ARRAY' ) {
                $v = join ',', @$v;
            } elsif( ref $v eq 'HASH' ) {
                $v = Util->hash_flatten($v);
                $v = Util->_encode_json($v);
                $v =~ s/{|}//g;
            }
            #_debug "V=$v," . ref $v;
            $v =~ s{"}{""}g;
            # utf8::encode($v);
            # Encode::from_to($v,'utf-8','iso-8859-15');
            push @cells, qq{"$v"}; 
        }
        push @csv, join ';', @cells; 
    }
    my $body = join "\n", @csv;
    # I#6947 - chromeframe does not download csv with less than 1024: pad the file
    my $len = length $body;
    $body .= "\n" x ( 1024 - $len + 1 ) if $len < 1024;
    utf8::encode($body);
    Encode::from_to($body,'utf-8','iso-8859-15');
    $c->stash->{serve_body} = $body;
    $c->stash->{serve_filename} = length $p->{title} ? Util->_name_to_id($p->{title}).'.csv' : 'topics.csv';
    $c->forward('/serve_file');
}

sub img : Local {
    my ($self, $c, $id ) = @_;
    my $p = $c->req->params;
    my $img = mdb->grid->get( "$id" );
    $img //= do{ my $doc = mdb->grid->files->find_one({ md5=>$id }); mdb->grid->get($$doc{_id}) if $doc };
    if( $img ) {
        $c->res->content_type( $$img{content_type} || 'image/png');
        $c->res->body( $img->slurp );
    } else {
        $c->res->content_type( 'image/png');
        my $broken = $c->path_to('/root/static/images/icons/help.png')->slurp;
        $c->res->body( $broken );
    }
}

sub change_status : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        my $change_status_before;
        
        my $id_cats = mdb->topic->find_one({ mid=>"$$p{mid}" },{ category_status=>1 })->{category_status}{id};
        
        if ($p->{old_status} eq $id_cats ){
            $change_status_before = \0;
            
            my ($isValid, $field_name) = $c->model('Topic')->check_fields_required( mid => $p->{mid}, username => $c->username);
            
            if ($isValid){
                $c->model('Topic')->change_status( 
                    change => 1, username => $c->username, 
                    id_status => $p->{new_status}, id_old_status => $p->{old_status}, 
                    mid => $p->{mid} 
                );
                { success => \1, msg => _loc ('Changed status'), change_status_before => $change_status_before };
            }else{
                { success => \0, msg => _loc ('Required field %1 is empty', $field_name) };    
            }
        }
        else{
            $change_status_before = \1;
            { success => \1, msg => _loc ('Changed status'), change_status_before => $change_status_before };
        }
        
    } catch {
        my $err = shift;
        _error( $err );
        { success=>\0, msg=>$err };
    }; 
    $c->forward('View::JSON');
}

1;
