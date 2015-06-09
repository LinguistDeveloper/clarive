package Baseliner::Controller::Topic;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use DateTime;
use Try::Tiny;
use Text::Unaccent::PurePerl;
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
                index    => $seq++,
                actions  => ["action.topics.$id.create"],
                url_comp => '/topic/view?swEdit=1',
                comp_data => { new_category_name=>$name, new_category_id=>$data->{id} },
                #icon     => '/static/images/icons/topic.png',
                tab_icon => '/static/images/icons/topic.png'
           }
       } sort { lc $a->{name} cmp lc $b->{name} } @cats;

       my %menu_statuses = map {
           my $data = $_;
           my $name = _loc( $_->{name} );
           my $id = _name_to_id( $name );
           $data->{color} //= 'transparent';
           "menu.topic.status.$id" => {
                label    => qq[<span style="white-space: nowrap; text-transform: uppercase; font-weight: bold; padding-bottom: 1px; font-size: 10px; font-family: Helvetica, Verdana, Helvetica, Arial, sans-serif;">$name</span>],
                title    => qq[<span style="white-space: nowrap; text-transform: uppercase; padding-bottom: 1px; font-size: 10px; font-family: \"Helvetica Neue\", Helvetica, Verdana, Helvetica, Arial, sans-serif; ">$name</span>],
                index    => $seq++,
                hideOnClick => 0,
                #actions  => ["action.topics.$id.create"],
                url_comp => '/topic/grid?status_id=' . $data->{id_status},
                #comp_data => { new_category_name=>$name, new_category_id=>$data->{id} },
                icon     => $data->{status_icon}||'/static/images/icons/state.gif',
                tab_icon => $data->{status_icon}||'/static/images/icons/state.gif',
           }
       } sort { lc $a->{name} cmp lc $b->{name} } 
           ci->status->find->fields({ id_status=>1, name=>1, color=>1, seq=>1, status_icon=>1 })->all;

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
            %menu_statuses,
            %menu_view,
       };
       $menus->{'menu.topic.status'} = {
                    label    => _loc('Status'),
                    icon     => '/static/images/icons/state.gif',
                    index => 2,
                    #actions  => ['action.topics.%.create'],
             } if %menu_statuses;
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
    if ($p->{category_id}){
        
        if (exists $c->stash->{category_id} && $c->stash->{category_id} ne $p->{category_id}) {
            $c->stash->{category_id} = $p->{category_id};
        }

        my $cat = mdb->category->find_one({ id=>''.$p->{category_id} });
        if ($cat->{default_grid}){
            my $report = ci->new($cat->{default_grid});
            my $selected_fields = $report->selected_fields({username => $c->username});
            my $report_data = {
                id_report   => $report->{mid},
                report_name => $report->{name},
                report_rows => $report->{rows},
                fields      => $selected_fields
            };

            $c->stash->{report_data} = Util->_encode_json($report_data);
        }

        # wip rgo: get report fields
        # my $cat = mdb->category->find_one({ id=>''.$p->{category_id} }) // _fail _loc 'Category with id %1 not found', $p->{category_id};
        # if( my $id_report = $cat->{default_grid} ) {
        #     my $rep = ci->new( $id_report );
        #     my $fields = $rep->selected_fields({ username=>$c->username });
        #     _debug( $fields );
        #     $c->stash->{default_grid} = $id_report;
        # }
    }


    $c->stash->{template} = '/comp/topic/topic_grid.js';
}

sub list : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    $p->{username} = $c->username;

    my $data = $self->get_items($p);

    if( $$p{id_report} && $p->{id_report} =~ /^report\./ ) {
        $c->stash->{json} = { data=>$data->{data}, totalCount=>$data->{totalCount}, config=>$data->{config} };
    } elsif( $p->{id_report} ) {
        $c->stash->{json} = { data=>$data->{data}, totalCount=>$data->{totalCount} };
    } elsif( my $id = $p->{id_report_rule} ) {
        $c->stash->{json} = { data=>$data->{data}, totalCount=>$data->{totalCount}};
    } else {
        $c->stash->{json} = { data=>$data->{data}, totalCount=>$data->{totalCount}, last_query=>$data->{last_query} };
    }
   $c->forward('View::JSON');
}

sub get_items {

    my ($self, $p ) = @_;
    my $data;

    if( $$p{id_report} && $p->{id_report} =~ /^report\./ ) {
        my $report = Baseliner->registry->get( $p->{id_report} );
        my $config = undef; # TODO get config from custom forms
        my $sort = $p->{sort};
        $p->{dir} = uc($p->{dir}) eq 'DESC' ? -1 : 1;
        $p->{sort} = { $sort => $p->{dir} } if ($p->{sort});
        my $rep_data = $report->data_handler->($report,$config,$p);
        $data = {
            data=>$rep_data->{rows},
            totalCount=>$rep_data->{total},
            config=>$rep_data->{config}
        };
        _log "total "._dump $rep_data->{total};
    } elsif( $p->{id_report} ) {
        my $filter = $p->{filter} ? _decode_json($p->{filter}) : undef;
        my $start = $p->{start} // 0;
        for my $f (_array $filter){
            my @temp = split('_', $f->{field});
            #$f->{field} = join('_',@temp[0..$#temp-1]);
            $f->{category} = $temp[$#temp];
        }
        my $dir = $p->{dir} && uc($p->{dir}) eq 'DESC' ? -1 : 1;        
        my ($cnt, @rows ) = ci->new( $p->{id_report} )->run( start=>$start, username=>$p->{username}, limit=>$p->{limit}, query=>$p->{topic_list}, filter=>$filter, query_search=>$p->{query}, sort=>$p->{sort}, sortdir=>$dir );
        $data = {
            data=>\@rows,
            totalCount=>$cnt 
        }  

    } elsif( my $id = $p->{id_report_rule} ) {
        my $cr = Baseliner::CompiledRule->new( _id=>$p->{id_report_rule} );
        my $stash = { 
            report_data => { data=>[], count=>0 },
            report_params => {
                %$p,
                step        => 'data',
                filter      => $p->{filter} ? _decode_json($p->{filter}) : undef,
                start       => $p->{start} // 0,
                dir         => uc($p->{dir}) eq 'DESC' ? -1 : 1,
            }
        };
        $cr->compile;
        $cr->run( stash=>$stash ); 
        my $report_data = ref $$stash{report_data} eq 'CODE' ? $$stash{report_data}->(%$p) : $$stash{report_data};
        _fail _loc 'Invalid report data for report %1',$id unless ref $report_data->{data} eq 'ARRAY';
        $data = {
            data=>$report_data->{data},
            totalCount=>$report_data->{cnt} || []
        }
       
    } else {
        my ($info, @rows ) = Baseliner->model('Topic')->topics_for_user( $p );

        $data = {
            data=>\@rows, 
            totalCount=>$$info{count}, 
            last_query=>$$info{last_query} 
        };
        #_log "data  "._dump $data;

    }

    return $data;
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $p->{status_new} = $p->{status_new}[0] if (ref $p->{status_new} eq 'ARRAY');     # Only for IE8 
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

    $where = $c->model('Topic')->apply_filter( $where, %filter );
    # _debug $where;

    my ($cnt, @result_topics) = $c->model('Topic')->get_topics_mdb( where=>$where, username=>$username, start=>$start, limit=>$limit,
            fields=>{ _txt=>0 });
            # fields=>{ category=>1, mid=>1, title=>1, });
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
            _debug $cache ? "***** NO CACHE ( $cache->{modified_on} != $modified_on )  for $file"
                : "***** NO CACHE for $file";
          my $body = _mason( $field->{js} );
          # $field_cache{ "$file" } = { modified_on=>$modified_on, body => $body };
          $field->{body} = ["$file", $body, 1 ];
        }
    }
    return $meta;
}

sub json : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
     
    try {
        my $ret = {};
        mdb->topic->find({ mid=>"$topic_mid" })->count or _fail(_loc('Topic #%1 not found. Deleted?', $topic_mid)); 
        my $meta = $c->model('Topic')->get_meta( $topic_mid );
        my $data = $c->model('Topic')->get_data( $meta, $topic_mid, %$p );


        $meta = model->Topic->get_meta_permissions( username=>$c->username, meta=>$meta, data=>$data );
        $meta = $self->get_field_bodies( $meta );
        
        
        $ret->{topic_meta} = $meta;
        
        if (exists $data->{ci_mid}){
            my $data_ci = _ci($data->{ci_mid})->{_ci};
            $data->{ci_parent} = $data_ci;
        }
        
        $ret->{topic_data} = $data;
        $ret->{rel_signature} = $c->model('Topic')->rel_signature($topic_mid);
        $c->stash->{json} = $ret;
    } catch {
        my $err = shift;   
        $c->stash->{json} = { success=>\0, msg=>$err };
    };
    
    $c->forward('View::JSON');
}

sub new_topic : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    
    my $ret = try {
        my $id_category = $p->{new_category_id};
        my $name_category = $p->{new_category_name} || mdb->category->find_one({id=>"$p->{new_category_id}"})->{name};
        my ($st) = grep { $$_{type} eq 'I' } values +{ ci->status->statuses( id_category=>"$id_category" ) };
        _fail( _loc('The topic category %1 does not have any initial status assigned. Contact your administrator.', $name_category) ) 
            unless $st;
        my $name_status = $st->{name};
        my $meta = $c->model('Topic')->get_meta( undef, $id_category, $c->username );
        $meta = $self->get_field_bodies( $meta );
        my $data = $c->model('Topic')->get_data( $meta, undef );
        map{ $data->{$_} = 'off'}  grep {$_ =~ '_done' && $data->{$_} eq 'on' } _array $data;
        $meta = model->Topic->get_meta_permissions( username=>$c->username, meta=>$meta, data=>$data, id_category=>$id_category, id_status=>$st->{id_status}, name_category=>$name_category, name_status=>$name_status);
        +{
            success             => \1,
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

        $c->stash->{user_security} = ci->user->find_one({ name => $c->username })->{project_security};
        $c->stash->{ii} = $p->{ii};    
        $c->stash->{swEdit} =  ref($p->{swEdit}) eq 'ARRAY' ? $p->{swEdit}->[0]:$p->{swEdit} ;
        $c->stash->{permissionEdit} = 0;
        $c->stash->{permissionDelete} = 0;
        $c->stash->{permissionGraph} = $c->model("Permissions")->user_has_action( username => $c->username, action => 'action.topics.view_graph');
        $c->stash->{permissionComment} = 0;
        my $topic_ci;
        if ( $topic_mid ) {
            try {
                $topic_ci = ci->new( $topic_mid );
                $c->stash->{viewKanban} = $topic_ci->children( where=>{collection => 'topic'}, mids_only => 1 );
                my $is_root = Baseliner->model('Permissions')->is_root($c->username);
                $c->stash->{viewDocs} = $c->stash->{viewKanban} && ( $is_root || Baseliner->model('Permissions')->user_has_action( username=> $c->username, action=>'action.home.generate_docs' ));  
                $topic_doc = $topic_ci->get_doc;

            } catch {
                my $err = shift;
                $c->stash->{viewKanban} = 0;
                $c->stash->{viewDocs} = 0;
                _fail $err;
            };
        } else {
            $c->stash->{viewKanban} = 0;
            $c->stash->{viewDocs} = 0;
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
        my %categories_comment = map { $_->{id} => 1} $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'comment', topic_mid => $topic_mid );
        
        if($topic_mid || $c->stash->{topic_mid} ){
     
            # user seen
            for my $mid ( _array( $topic_mid ) ) {
                mdb->master_seen->update({ username=>$c->username, mid=>$mid },{ username=>$c->username, mid=>$mid, type=>'topic', last_seen=>mdb->ts },{ upsert=>1 });
            }
            
            $category = mdb->category->find_one({ id=>$topic_doc->{category}{id} },{ fieldlets=>0 });
            
            if ( $category->{is_changeset} ) {
                if ( !$topic_doc->{category_status}->{bind_releases} ) {
                    my ($id_project) = map {$_->{mid}} $topic_ci->projects;
                    my ( $deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d ) = BaselinerX::LcController->promotes_and_demotes(
                        topic      => $topic_doc,
                        username   => $c->username,
                        id_project => $id_project
                    );
                    my $menu = { deployable => $deployable, promotable => $promotable, demotable => $demotable, menu => [_array $menu_s, _array $menu_p, _array $menu_d]};
                    $c->stash->{menu_deploy} = _encode_json($menu);
                } else {
                    my $menu = { deployable => {}, promotable => {}, demotable => {}, menu => []};
                    $c->stash->{menu_deploy} = _encode_json($menu);
                }
            }
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
                sort { ( $a->{status_name} ) cmp ( $b->{status_name} ) }
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
            if (exists ($categories_comment{ $category->{id} })){
                $c->stash->{permissionComment} = 1;
                $c->stash->{has_comments} = $c->model('Topic')->list_posts( mid=>$topic_mid, count_only=>1 );
            } else {
                $c->stash->{permissionComment} = 0;
                $c->stash->{has_comments} = 0;
            }
                             
     
            # jobs for release and changeset
            if( $category->{is_changeset} || $category->{is_release} ) {
                my $has_permission = Baseliner->model('Permissions')->user_has_action( username=> $c->username, action=>'action.job.monitor' );

                $c->stash->{jobs} = $has_permission ? 1 : 0;
            } else {
                $c->stash->{jobs} = -1;
            }
            
            # used by the Change State menu in the topic
            $c->stash->{status_items_menu} = _encode_json(\@statuses);
        } else {
            $id_category = $p->{new_category_id} // $p->{category_id};
            
            my $category = mdb->category->find_one({ id=>"$id_category" });
            $c->stash->{category_meta} = $category->{forms};
            $c->stash->{category_name} = $category->{name};
            $c->stash->{category_color} = $category->{color};

            my $first_status = ci->status->find_one({ id_status=>mdb->in( $category->{statuses} ), type=>'I' }) // _fail( _loc('No initial state found '));

            my @statuses =
                sort { ( $a->{status_name} ) cmp ( $b->{status_name} ) }
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
            $c->stash->{permissionComment} = 1 if exists $categories_comment{$id_category};
            
            $c->stash->{has_comments} = 0;
            $c->stash->{topic_mid} = '';
        }
        
        if( $p->{html} ) {
            my $meta = $c->model('Topic')->get_meta( $topic_mid, $id_category );
            my $data = $c->model('Topic')->get_data( $meta, $topic_mid, topic_child_data=>$p->{topic_child_data} );
            $meta = $self->get_field_bodies( $meta );
            $meta = model->Topic->get_meta_permissions( username=>$c->username, meta=>$meta, data=>$data );

            my $write_action = 'action.topicsfield.' .  _name_to_id($topic_doc->{name_category}) . '.labels.' . _name_to_id($topic_doc->{name_status}) . '.write';

            $data->{admin_labels} = $c->model('Permissions')->user_has_any_action( username=> $c->username, action=>$write_action );
            
            $c->stash->{topic_meta} = $meta;
            $c->stash->{topic_data} = $data;
            
            $c->stash->{template} = '/comp/topic/topic_msg.html';
        } else {
            $c->stash->{template} = '/comp/topic/topic_main.js';
        }
    } catch {
        $c->stash->{json} = { success=>\0, msg=>_loc("Problem found opening topic %1. The error message is: %2", $topic_mid, shift()) };
        $c->forward('View::JSON');
    };
}

sub title_row : Local {
    my ($self, $c ) = @_;
    my $mid = $c->req->params->{mid};
    my $row = mdb->topic->find_one({ mid=>"$mid" },{ mid=>1, title=>1, category_name=>1, category_color=>1 });
    if ($row){
        $c->stash->{json} = { success=>$row ? \1 : \0, row => $row };
        $c->forward('View::JSON');
    }else {
        _fail(_loc("Problem found opening topic %1. The error message is: %2", $mid, _loc('Topic not found')));
    }
    
}

sub data_user_event : Local {
    my ($self, $c, $action) = @_;
    my $username = $c->request->parameters->{username};
    if( $action eq 'get' ) {
        try {
            my $user_mid = ( ci->user->find_one({username=>$username}) // _fail(_loc('User not found: %1', $username)) )->{mid};
            my $user = ci->new($user_mid);
            my $name = $user->{realname};
            my $email = $user->{email};
            my $phone = $user->{phone};
            my $data = '';
            if ($name ne ''){
                $data .= "<b>Nombre</b>: " . $name . "<br><br>";
            }
            if ($email ne ''){
                $data .= "<b>E-mail</b>: " . $email . "<br><br>";
            }
            if ($phone ne ''){
                $data .= "<b>Phone Number</b>: " . $phone . "<br><br>";
            }
            if ($data eq ''){
                $data .= "No se tienen datos del usuario <b>" . $username . "</b>.<br>";
            }else{
                $data = "<b>Nombre de usuario</b>: " . $username . "<br><br>" . $data;
            }
            $c->stash->{json} = { msg => $data, failure => \0 };
        } catch {
            my $err = shift;
            _error( $err );
            $c->stash->{json} = { msg => _loc('It seems that the user %1 does not already exist in Clarive', $username ), failure => \1 };
        };
    }
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
            my $msg = _loc('Comment added');
            my $topic_row = mdb->topic->find_one({ mid=>"$topic_mid" });
            _fail( _loc("Topic #%1 not found. Deleted?", $topic_mid ) ) unless $topic_row;

            # notification data
            my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>"$topic_mid", rel_type=>'topic_project' });
            my @users = Baseliner->model("Topic")->get_users_friend(
                    id_category => $topic_row->{category}{id}, 
                    id_status   => $topic_row->{category_status}{id}, 
                    projects    => \@projects );
            my $subject = _loc("@%1 created a post for #%2 %3", $c->username, $topic_row->{mid}, $topic_row->{title} );
            my $notify = { #'project', 'category', 'category_status'
                category        => $topic_row->{category}{id},
                category_status => $topic_row->{category_status}{id},
                project => \@projects,
            };

            my @name_projects = map { ci->project->find_one({mid=>$_})->{name} } _array(mdb->topic->find_one({mid=>"$topic_mid"})->{_project_security}->{project});

            if( ! length $id_com ) {  # optional, if exists then is not add, it's an edit
                
                my $post = ci->post->new({   
                        topic        => $topic_mid,
                        content_type => $content_type,
                        created_by   => $c->username,
                        created_on   => mdb->ts,
                });
                local $Baseliner::CI::ci_record = 1;

                
                # save the post
                my $mid_post = $post->save;
                $post->put_data( $text ); 
                event_new 'event.post.create' => {
                    username        => $c->username,
                    mid             => $topic_mid,
                    data            => _ci($topic_mid)->{_ci},
                    id_post         => $mid_post,
                    post            => $text,
                    notify_default  => \@users,
                    subject         => $subject,
                    project        => \@name_projects,
                    notify=>$notify 
                };
                # mentioned people? event this...
                while( $text =~ /\@([^\s\W\n]+)/gm ) {
                    my $mentioned = $1;
                    if( ci->user->find_one({ username=>$mentioned }) ) {
                        event_new 'event.post.mention' => {
                            username        => $c->username,
                            mentioned       => $mentioned,
                            mid             => $topic_mid,
                            data            => _ci($topic_mid)->{_ci},
                            id_post         => $mid_post,
                            post            => $text,
                            notify_default  => [ $mentioned ],
                            notify=>$notify 
                        };
                    }
                }
            } else {
                #my $post = ci->find( $id_com );
                my $post = ci->new( $id_com );
                #$post->update(modified_by => $c->username);
                $post->update(ts => mdb->ts);
                $post->save;
                $post->put_data( $text );
                event_new 'event.post.edit' => {
                    username        => $c->username,
                    mid             => $topic_mid,
                    data            => ci->new($topic_mid)->{_ci},
                    id_post         => $id_com,
                    post            => $text,
                    notify_default  => \@users,
                    subject         => $subject,
                    project        => \@name_projects,
                    notify=>$notify 
                };
                _fail( _loc("This comment does not exist anymore") ) unless $post;
                $msg = _loc("Comment modified");
                #$post->update(content_type=>$content_type );
            }

            # modified_on 
            mdb->topic->update({ mid=>"$topic_mid" },{ '$set'=>{ modified_on=>mdb->ts, modified_by=>$c->username } });
            cache->remove({ mid=>"$topic_mid" }) if length $topic_mid;  # qr/:$topic_mid:/ )
            $c->stash->{json} = {
                msg     => $msg,
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
            my @mids = map { $_->{mid} } $post->parents( where => {collection=>'topic'}, mids_only => 1 );
            # delete the record
            $post->delete;
            # now notify my parents
            for my $mid_topic ( @mids ) {
                my $topic_row = mdb->topic->find_one({ mid=>$mid_topic });
                my @projects = mdb->master_rel->find_values( to_mid=>{ from_mid=>"$mids[0]", rel_type=>'topic_project' });
                my @users = Baseliner->model("Topic")->get_users_friend(id_category => $topic_row->{category}{id}, 
                    id_status=>$topic_row->{category}{status}, projects=>\@projects);
                my $subject = _loc("@%1 deleted a post from #%2 %3", $c->username, $topic_row->{mid}, $topic_row->{title});
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
                mdb->topic->update({ mid=>"$mid_topic" },{ '$set'=>{ modified_on=>mdb->ts, modified_by=>$c->username } });
                cache->remove({ mid=>"$mid_topic" }) if length $mid_topic; # qr/:$mid_topic:/ ) 
            }
            $c->stash->{json} = {
                msg     => _loc('Delete comment ok'),
                id      => $id_com,
                failure => \0
            };
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

sub category_list : Local { #this is for ComboCategories
    my ($self, $c) = @_;
    my @cats = mdb->category->find()->fields({ id => 1, name => 1, _id => 0 })->all;

    my $return = {
        data => [
            map { +{ id => $_->{id}, name => $_->{name} } } 
            sort { lc $a->{name} cmp lc $b->{name} }
            @cats
        ],
        totalCount=>scalar @cats
    };
    $c->stash->{json} = $return;
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
            @categories  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => $p->{action}, order => $order, all_fields=>1);
        } else {
            @categories  = $c->model('Topic')->get_categories_permissions( username => $c->username, type => 'view', order => $order, all_fields=>1);
        }
        
        if(@categories){
            foreach my $category (@categories){
                my @statuses = _array( $category->{statuses} );

                my $type = $category->{is_changeset} ? 'C' : $category->{is_release} ? 'R' : 'N';
                my @fieldlets;

                my $forms = $self->form_build( $category->{forms} );
                
                push @rows, {
                    id            => $category->{id},
                    category      => $category->{id},
                    name          => $p->{swnotranslate} ? $category->{name}: _loc($category->{name}),
                    acronym       => $category->{acronym},
                    color         => $category->{color},
                    type          => $type,
                    forms         => $forms,
                    category_name => _loc($category->{name}),
                    is_release    => $category->{is_release},
                    is_changeset  => $category->{is_changeset},
                    description   => $category->{description},
                    default_grid  => $category->{default_grid},
                    default_field => $category->{default_field},
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
            for my $bl_status ( _array( $status->bls ) ) {
                push @rows, {
                                id      => $status->id_status,
                                bl      => $bl_status,
                                name    => $status->name_with_bl( no_common=>1 ),
                            };
            }
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
        cache->remove({ mid=>"$topic_mid" }) if length $topic_mid; # qr/:$topic_mid:/ ) 
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error assigning Labels: %1', shift()), failure=>\1 }
    };
     
    $c->forward('View::JSON');    
}

sub delete_topic_label : Local {
    my ($self,$c, $topic_mid, $label_id)=@_;
    try{
        cache->remove({ mid=>"$topic_mid" }) if length $topic_mid; # qr/:$topic_mid:/ 
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
        text    => _loc('Modified Today'),
        filter  => '{"modified_today":true}',
        default    => \1,
        cls     => 'forum default',
        iconCls => 'icon-no',
        checked => \0,
        leaf    => 'true',
        uiProvider => 'Baseliner.CBTreeNodeUI_system'
    };
    
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
    my @categories_permissions  = $c->model('Topic')->get_categories_permissions( id=>$category_id, username=>$c->username, type=>'view', all_fields=>1 );

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
#_debug \@cat_statuses;
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
        my %p;
        $p{categories} = \@id_categories;
        map { $tmp{$_->{id_status_from}} = $_->{id_category} } 
                    Baseliner->model('Topic')->user_workflow( $c->username, %p );        
    };

    my %id_categories_hash = map { $_ => '1' } @id_categories;

    if( $rs_status->count > 1 ){
        while( my $r = $rs_status->next ) {
            my $checked;

            if ( $is_root ) {
                #Si no es un estado final, lo sacamos marcado
                if(($r->{type} ne 'F') and ($r->{type} ne 'FC')){
                    $checked = \1;
                }else{
                    $checked = \0;
                }
            } else {
                # $checked = exists $tmp{$r->{id_status}} && (substr ($r->{type}, 0 , 1) ne 'F')? \1: \0;
                $checked = exists $tmp{$r->{id_status}} && $id_categories_hash{$tmp{$r->{id_status}}} && (substr ($r->{type}, 0 , 1) ne 'F')? \1: \0;


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
        @statuses = sort { uc($a->{text}) cmp uc($b->{text}) } @statuses;
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
    my %response = Baseliner->model("Topic")->upload(
                f           => $f, 
                p           => $p, 
                username    => $c->username,
            );
    if ($response{status} ne '200') {
        $c->res->status($response{status});
    }
    my $body = '{"success": "' . $response{success}. '", "msg": "' . $response{msg} .'"}';
    $c->res->body($body);
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
                    my $subject = _loc("Detached file %1 from #%2 %3", $ass->filename, $topic->{mid}, $topic->{title});
                    event_new 'event.topic.file_remove' => {
                        username => $c->username,
                        mid      => $topic_mid,
                        id_file  => $ass->mid,
                        filename => $ass->filename,
                        notify_default => \@users,
                        subject         => $subject
                        }
                    => sub {
                        _log _loc("Deleting file %1 from topic %2",$ass->name,$topic_mid);
                        my $rel = mdb->master_rel->remove({ from_mid=>"$topic_mid", to_mid=>$ass->mid });
                        _fail _loc "File not attached to topic" if $rel ne '1';
                        $msg = _loc( "Relationship deleted ok" );
                    };
                }
            }
        }
        cache->remove({mid=>"$topic_mid"});
        $c->stash->{ json } = { success => \1, msg => $msg };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success => \0, msg => $err };
    };
    $c->forward( 'View::JSON' );
}

sub download_file : Local {
    my ( $self, $c, $mid, $fn ) = @_;
    my $p = $c->req->params;
    my $ass = ci->find( $mid );
    try {
        if( defined $ass ) {
            if( $ass->does('Baseliner::Role::CI::Topic') ) {
                # it's a topic! find an asset that matches the filename
                my @res = $ass->related( isa=>'asset', where=>{ name=>$fn } );
                $ass = @res > 1 ? _fail( _loc 'More than one asset found for topic %1 matching name `%2`',$mid,$fn)
                    : @res == 0 ? _fail( _loc 'No asset found for topic %1 matching name `%2`',$mid,$fn)
                    : $res[0];
            }
            my $filename = $ass->name;
            utf8::encode( $filename );
            $c->stash->{serve_filename} = $filename;
            $c->stash->{serve_body} = $ass->slurp;
            $c->forward('/serve_file');
        } else {
            $c->res->body(_loc('File %1 not found', $mid ) );
        }
    } catch {
        my $err = shift;
        _error( $err );
        $c->res->body( $err );
    };
}

sub file_tree : Local {
    my ( $self, $c ) = @_;
    my $p         = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
    my $rel_field = $p->{filter};
    my @files     = ();
    if ($topic_mid) {
        my @assets = mdb->master_rel->find_values( to_mid => { from_mid=>"$topic_mid", rel_field=>"$rel_field", rel_type=>'topic_asset' } );
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
                push @id_roles, mdb->role->find_one({ role=> qr/$role_name/i })->{id};
            }
            if (@id_roles){
                $users_friends = $c->model('Users')->get_users_from_mid_roles(roles => \@id_roles, projects => \@topic_projects); 
            }
        }else{
            $users_friends = $c->model('Users')->get_users_friends_by_username($username);    
        }
    }
    my $row = ci->user->find({username => mdb->in($users_friends)})->sort({realname => 1});
    if($row){
        while( my $r = $row->next ) {
            push @rows,
              {
                id 		=> $r->{mid},
                username	=> $r->{username},
                realname	=> $r->{realname}
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

            $job = ci->job->new( $job_data );
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
        $err =~ s{ at./.*line.*}{}g;
        my $msg = _loc( "Error creating job: %1", "$err" );
        _error( $msg );
        { success=>\0, msg=>$msg };
    };
    $c->forward('View::JSON');
}

sub kanban_status : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $topic_list = $p->{topics};
    my $data = {};
    my @columns;
    $c->stash->{json} = try {
        my @topics = mdb->topic->find({ mid=>mdb->in($topic_list) })->fields({ id_category=>1, mid=>1, id_category_status=>1, _id=>0 })->all;
        _fail( _loc('No topics available') ) unless @topics;
        my %cats; push @{ $cats{ $$_{id_category} } }, $_ for @topics;
        _fail( _loc('No categories found for topics') ) unless %cats;
        my @cat_status = _unique map { _array($$_{statuses}) } mdb->category->find({ id =>mdb->in(keys %cats) })->fields({ statuses=>1 })->all;
        _fail( _loc('No category status found for topics') ) unless @cat_status;
        
        ## support multiple bls
        my %status_cis = map { $_->id_status => $_ } ci->status->search_cis;
        
        my @statuses = map {
            my $st = $_;
            my $bls = join ' ', map { $_->{moniker} } _array( $st->bls ); 
            +{ id=>$$st{id_status}, name=>$$st{name}, seq=>$$st{seq}, bl=>$bls };
        } sort { $$a{seq}<=>$$b{seq} } grep { defined } map { $status_cis{$_} } @cat_status;

        # given a user, find my workflow status froms and tos
        my @transitions = model->Topic->non_root_workflow( $c->username, categories=>[keys %cats] );
        
        my %workflow;
        my %status_mids;
        my %visible_status;  # list with destination to statuses to reduce cruft on top of kanban
        # for each workflow transition for this user:
        for my $wf ( @transitions ) {
            next if $$wf{id_status_from} == $$wf{id_status_to}; # don't need static promotions in Kanban
            # for each mid in this category
            for my $t ( _array $cats{ $$wf{id_category} } ) {
                my $mid = $$t{mid};
                push @{ $workflow{ $mid } }, {
                    from_name          => $$wf{status_name_from},
                    from_seq           => $$wf{seq_from},
                    id_category_status => $$wf{id_status_from},
                    id_status_from     => $$wf{id_status_from},
                    id_status_to       => $$wf{id_status_to},
                    mid                => $mid,
                    to_name            => $$wf{status_name},
                    to_seq             => $$wf{seq_to},
                    id_category        => $$wf{id_category},
                };
                push @{ $status_mids{ $wf->{id_status_from} } }, $mid;
                push @{ $status_mids{ $wf->{id_status_to} } }, $mid;
                # visible status: only the ones that match topics current status + destination status
                if( $$t{id_category_status} == $$wf{id_status_from} ) {
                    $visible_status{ $$wf{id_status_from} } = 1;
                    $visible_status{ $$wf{id_status_to} } = 1;
                }
            }
        }

        { success=>\1, msg=>'', statuses=>\@statuses, visible_status=>\%visible_status, workflow=>\%workflow, status_mids=>\%status_mids };
    } catch {
        my $err = shift;
        { success=>\0, msg=> _loc( "Error rendering kanban: %1", "$err" ) };
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
    my $params = _decode_json $p->{params};
    $params->{username} = $c->username;
    $params->{categories} ='' if !scalar @{$params->{categories}};
    $params->{limit} = $p->{total_rows};

   my $rows = $self->get_items($params);
   
    my @csv;
    my @cols;

    my $charset = "iso-8859-1";
    # Topics are related to categories, remove accents from category name to check for mongo fields and extract data.    
    my @cats = map { +{ id => $_->{id}, name => lc(unac_string($_->{name}) )} } mdb->category->find()->fields({ id => 1, name => 1, _id => 0 })->all;
    push my @names_category, map {$_->{name}} @cats;
    # _log "categories "._dump @cats;

    # Columns are taken from user grid.
    for( grep { length $_->{name} } _array( $data->{columns} ) ) { 
        push @cols, qq{"$_->{name}"}; #"
    }
    for(@cols){s/Comentarios/Mas info/g};
    
    push @csv, join ';', @cols;

    for my $row (_array $rows->{data}){      
        my $main_category = $row->{category}->{name}|| $row->{category_name} ; 
        my @cells;
        for my $col ( grep { length $_->{name} } _array( $data->{columns} ) ) {
            my ($col_id, $field1, $tail);
            if ( $params->{id_report} || $params->{id_report_rule}) {

                # Remove _<related Category> to the column id in reports
                ( $field1, $tail) = ($col->{id} =~ m/^(.*[^_])_(.*)$/);
                $col_id = ($tail && grep /^$tail$/i, @names_category )? $field1 : $col->{id};
            } else { 
                $col_id = $col->{id}
            }
            my $v = $row->{ $col_id };
            if( ref $v eq 'ARRAY' ) {
                if ($col->{id} eq 'projects') {
                    my @projects;
                    for (@{$v}){
                        push @projects, ( split';', $_)[1];
                    }
                    @$v = @projects;
                }
                (my $du) = _array $v;
                if( ref $du eq 'HASH' && exists $du->{mid}) {
                        $v = $du->{mid};
                } else {        
                    $v = join ',', @$v;
                }
            } elsif( ref $v eq 'HASH' ) {
                $v = $v->{mid};
                #$v = Util->hash_flatten($v);
                #$v = Util->_encode_json($v);
                #$v =~ s/{|}//g;
            };
            if ( $v &&  $v !~ /^\s?$/ && $col_id ) { # Look for related category for prepending 
                my $rel_category; 

                if (ref $row->{$col_id} eq 'HASH' ){            
                     $rel_category = $row->{$col_id}->{category}->{name};
                     $v = $rel_category.' #'.$v ;
                    
                } elsif ( ref $row->{$col_id} eq 'ARRAY' ){
                    (my $du) = _array $row->{$col_id};
                    if( ref $du eq 'HASH' && exists $du->{category}) {
                        $rel_category = $du->{category}->{name};
                        $v = $rel_category.' #'.$v ; 
                    }
                } else {
                    ($tail) = ($col->{name} =~ m/^.*[^:]:\s(.*)$/);
                    $tail = lc(unac_string($tail) ) if ($tail);
                    if ($tail && grep /^$tail$/i, @names_category) {
                        (my $id) = map { $_->{id}} grep { $_->{name} eq $tail } @cats;                
                        $rel_category = mdb->category->find_one({id => $id})->{name};
                        $v = $rel_category.' #'.$v ;
                    }
                }
            }
            $v = $main_category.' #'.$v if ($col_id eq'topic_mid' && $col->{name} ne 'MID');
            $v = _strip_html ($v); # HTML Code 
            #_debug "V=$v," . ref $v;
            $v =~ s/\t//g if $v;
            $v =~ s{"}{""}g if $v;
            # utf8::encode($v);
            # Encode::from_to($v,'utf-8','iso-8859-15');
            if ($v || ($v eq '0' &&  $params->{id_report} && $params->{id_report} =~ /\.statistics\./)) {
                 push @cells, qq{"$v"};
            } else { push @cells, qq{""} }; 
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
    $img //= do {
        my $doc = mdb->grid->files->find_one({ '$or'=>[{ _id=>mdb->oid($id) },{ md5=>$id }] });
        mdb->grid->get( $$doc{_id} ) if $doc;
    };
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
        
        my $id_cats = ( 
            mdb->topic->find_one({ mid=>"$$p{mid}" },{ category_status=>1 }) 
            // _fail(_loc("Topic #%1 not found. Deleted?", $$p{mid}))  
        )->{category_status}{id};
        
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

sub xget_files : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $ucmserver = 'moniker:ucm';
    my $name = $p->{name};
    my $topic_mid = $p->{id_release};
    my @topics = mdb->master_rel->find( { from_mid => $topic_mid } )->all;
    my @mids = map { $_->{to_mid} } @topics;
    @topics = mdb->topic->find( { mid=>{'$in'=>\@mids} } )->all;
    my @result = grep { $_->{category_name} eq 'Petición' } @topics;
    my $download_path = Baseliner->model( 'ConfigStore' )->get( 'config.specifications' )->{download_specification_directory};
    my $agrupador_path;
    mkdir $download_path unless -d $download_path;
    foreach my $peticion (@result) {
        my $ucm = ci->new($ucmserver) or _fail _loc 'UCM server not found';
        $agrupador_path = $download_path.'/'.$peticion->{agrupador};
        mkdir $agrupador_path unless -d $agrupador_path;
        my $peticion_path = $agrupador_path.'/Peticion_'.$peticion->{mid};
        mkdir $peticion_path if (!-d $peticion_path and $peticion->{especificaciones}[0] );
        foreach my $specification ( @{ $peticion->{especificaciones} } ) {
           my ( $file_name, $body ) =
             $ucm->getfile( params => { docid => $specification->{id} } );
           open my $temp_file, ">>:raw", $peticion_path.'/'.$file_name;
           print $temp_file $body;
           close $temp_file;
        }
    }
    my $file_path = $agrupador_path.'.zip';
    Baseliner::Utils->zip_dir(source_dir=>$agrupador_path,zipfile=>$file_path);
    File::Path::rmtree $agrupador_path;
    $c->stash->{serve_file} = $file_path;
    $c->stash->{serve_filename} = $name.'_specifications.zip';
    $c->forward('/serve_file');
}

sub grid_count : Local {
    my ($self,$c)=@_;
    if( my $lq = $c->req->params->{lq} ) {
        my $cnt = mdb->topic->find($lq)->fields({_id=>1})->count;
        my @rows = mdb->topic->find($lq)->all;
        $c->stash->{json} = { data =>\@rows, count=>$cnt };

    } else {
        $c->stash->{json} = { count=>9999999 };
    }
    $c->forward('View::JSON');
}

sub get_files : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;

    my $username = $p->{username} || $c->username;
    my $fields = $p->{field} // 'ALL';
    my $mid = $p->{mid} || _throw _loc('Missing mid');

    my $topic = ci->new($mid);
    my @doc_fields = split /,/, $fields;
    my ($info, @user_topics) = Baseliner->model('Topic')->topics_for_user({ username => $username, query=>$mid, clear_filter => 1});
    my $where = { mid => mdb->in(map {$_->{mid}} @user_topics), collection => 'topic'};

    my @topics = $topic->children( where => $where, depth => -1 );

    my $download_path = _tmp_dir."/downloads/";
    #my $topic_path = $download_path._nowstamp."_".$mid;
    my $topic_path = _mktmp( prefix => 'downloads');
    _mkpath($topic_path);

    for my $related ( @topics ) {
        my $cat_meta;
        my $cat_fields;
        
        if ( !$cat_meta->{$related->{name_category}} ) {
            $cat_meta->{$related->{name_category}} = $related->get_meta;
            $cat_fields->{$related->{name_category}} = [
                map { 
                    { id_field => $_->{id_field}, name_field => $_->{name_field} } 
                }
                grep { 
                    'ALL' ~~ @doc_fields || $_->{id_field} ~~ @doc_fields
                }
                _array $cat_meta->{ $related->{name_category} }
            ];
        }
        my $rel_data = ci->new($related->{mid})->get_data;
        my $user_security = ci->user->find_one( {name => $username}, { project_security => 1, _id => 0} )->{project_security};
        my $user_actions = model->Permissions->user_actions_by_topic( username=> $username, user_security => $user_security );
        my @user_actions_for_topic = $user_actions->{positive};
        my @user_read_actions_for_topic = $user_actions->{negative};

        for my $field ( _array $cat_fields->{$related->{name_category}} ) {
            if ( _array($rel_data->{$field->{id_field}}) ) {

                my $read_action = 'action.topicsfield.'._name_to_id($related->{name_category}).'.'.$field->{id_field}.'.read';
                if ( !( $read_action ~~ @user_read_actions_for_topic) ) {
                    ###### TODO: get all file types not just ucm
                    my ($field_meta) = grep {$_->{id_field} eq $field->{id_field}} _array($cat_meta->{ $related->{name_category} });
                    if ( $field_meta->{ucmserver} ) {                    
                        my $ucm = ci->new( $field_meta->{ucmserver} );
                        my $related_path = $topic_path.'/'.$related->{name_category}.'_'.$related->{mid};
                        _mkpath($related_path) if (!-d $related_path );
                        foreach my $file ( _array($rel_data->{$field->{id_field}}) ) {
                            my ( $file_name, $body, $status ) =
                                $ucm->getfile( params => { docid => $file->{id} } );
                            if(0+$status < 0){
                                $file_name =  "ID_FILE_".$file->{id}."_NOT_PRESENT";
                                $body = '';
                            }
                            open my $temp_file, ">>:raw", $related_path.'/'.$file_name;
                            print $temp_file $body;
                            close $temp_file;
                        }
                    }
                }
            }
        }
    }

    my $file_path = $topic_path.'.zip';
    Baseliner::Utils->zip_dir(source_dir=>$topic_path,zipfile=>$file_path);
    _rmpath $topic_path;

    $c->stash->{serve_file} = $file_path;
    $c->stash->{serve_filename} = $mid.'_'.$fields.'.zip';
    $c->forward('/serve_file');
}

=pod

---
node1:
  topic_mid: '131290'
node2:
  click:
    icon: /static/images/icons/topic.png
    title: 'Paquete #103132'
    type: comp
    url: /topic/view?topic_mid=103132
  on_drop:
    url: /lifecycle/release_drop
  topic_mid: '103132'

=cut

sub topic_drop : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $n1 = delete $p->{node1};
    my $n2 = delete $p->{node2};
    my $mid1 = $n1->{topic_mid};
    my $mid2 = $n2->{topic_mid};
    my ($from_mid,$to_mid);
    my $kmatches = 0;
    my @targets;
    
    if ( $mid1 && $mid2 ) {
        try {
            PAIR: for my $pair ( [$mid1,$mid2],[$mid2,$mid1] ) {
                ($from_mid,$to_mid) = @$pair;
                my $meta = model->Topic->get_meta($to_mid);
                my @ids = map { $_=>1 } grep { defined } map { $$_{id_field} } @$meta;
                my $data = mdb->topic->find_one({ mid => $to_mid },{ category=>1, category_status=>1, id_status=>1, @ids });
                $meta = model->Topic->get_meta_permissions( username => $c->username, meta => $meta, data=>$data );
                my @mids;

                META: for my $fm (@$meta) {
                    my $dt = $fm->{drop_target};
                    next META unless !length($dt) || $dt;# if not defined, it's a drop target; if defined then it depends
                    next META if $$fm{meta_type} !~ /(topic|release)/;
                    $kmatches++;
                    next META if !$$fm{editable};
                    # if filter, test if filter matches and avoid later errors
                    next META if !model->Topic->test_field_match( field_meta=>$fm, mids=>$from_mid );

                    my $id_field = $$fm{id_field};
                    if ( ref $$fm{readonly} eq 'SCALAR' && ${ $$fm{readonly} } ) {
                        $c->stash->{json} = { success => \0, msg=> _loc( 'User %1 does not have permission to drop into field %2', $c->username, _loc( $$fm{name_field} )) };
                        last META;
                    }
                    if ( !$fm->{single_mode} ) {
                        push @mids, _array( $$data{$id_field} );
                    }
                    push @mids, $from_mid;
                    # save operation for later
                    push @targets, { id_field=>$id_field, mid=>$to_mid, fm=>$fm, oper=>sub{ 
                        model->Topic->update({ action=>'update', topic_mid=>$to_mid, $id_field=>\@mids, username=>$c->username });
                        $c->stash->{json} = { success => \1, msg => _loc( 'Topic #%1 added to #%2 in field `%3`', $from_mid, $to_mid, _loc( $$fm{name_field} ) ) };
                    } };
                }
            }
            if( !@targets ) {
                my $msg = $kmatches ? _loc('No editable or matching fields found in topics #%1 and #%2', $mid1, $mid2)
                    :  _loc( 'No drop fields available in topics %1 or %2', $mid1, $mid2 );
                $c->stash->{json} //= { success => \0, msg =>$msg };
            }
            elsif( @targets > 1 ) {
                # more than one possible field? 
                if( $p->{selected_id_field} ) {
                    # user told me which one
                    map { $$_{oper}->() } grep { $$_{id_field} eq $p->{selected_id_field} && $$_{mid} eq $p->{selected_mid} } @targets; 
                } else {
                    # ask user
                    $c->stash->{json} = { success =>\1, targets=>[ map { my $r=$$_{fm}; $$r{mid}=$$_{mid}; $r } @targets ] };
                }
            }
            else {
                (shift @targets)->{oper}->();  # only 1 operation, run it
            }
        } catch {
            my $err = shift;
            my $msg = _loc('Error adding topic #%1 to #%2: %3', $from_mid, $to_mid, $err);
            _error( $msg );
            $c->stash->{json} = { success => \0, msg=>$msg };
        };
    } else {
        $c->stash->{json} = { success => \0, msg => _loc('Missing mid') };
    }
    $c->forward('View::JSON');
}
sub leer_log : Local {
     my ( $self, $c ) = @_;
     my $p = $c->request->parameters;
    _log ">>>>>>>>>>>>>>>>>>>>>><Controlador";
    my @rows = (1,2,3);
    $c->stash->{json} = { data=>\@rows};
    $c->forward('View::JSON');    
}

1;
