package Baseliner::Controller::Topic;
use Moose;
BEGIN {  extends 'Catalyst::Controller' }

use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Model::PromotesAndDemotes;
use Baseliner::Model::Permissions;
use Baseliner::Model::Topic;
use Baseliner::Model::Label;
use Baseliner::Model::Users;
use Baseliner::DataView::Topic;
use Baseliner::RuleRunner;
use DateTime;
use Try::Tiny;
use Text::Unaccent::PurePerl;
use v5.10;
use experimental 'smartmatch', 'autoderef', 'switch';

with 'Baseliner::Role::ControllerValidator';

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';

register 'action.admin.topics' => { name=>_locl('Admin topics') };
register 'action.topics.view_graph' => { name=>_locl('View related graph in topics') };

register 'registor.menu.topics' => {
    generator => sub { __PACKAGE__->generate_menus() }
};

sub generate_menus {
    my $class = shift;

    my @cats        = mdb->category->find->fields( { name => 1, id => 1, color => 1 } )->all;
    my $seq         = 10;
    my $pad_for_tab = 'margin: 0 0 -3px 0; padding: 2px 4px 2px 4px; line-height: 12px;';

    my %menu_view = map {
        my $data = $_;
        my $name = _loc( $_->{name} );
        my $id   = _name_to_id($name);
        $data->{color} //= 'transparent';
        "menu.topic.$id" => {
            label =>
qq[<span id="boot" style="background:transparent"><span class="label" style="background-color:$data->{color}">$name</span></span>],
            title =>
qq[<span id="boot" style="background:transparent;height:14px;margin-bottom:0px"><span class="label" style="$pad_for_tab;background-color:$data->{color}">$name</span></span>],
            index    => $seq++,
            actions  => [ { action => "action.topics.view", bounds => { id_category => $data->{id} } }, ],
            url_comp => "/topic/grid?category_id=" . $data->{id},
            tab_icon => '/static/images/icons/topic.svg'
          }
    } sort { lc $a->{name} cmp lc $b->{name} } @cats;

    my %menu_create = map {
        my $data = $_;
        my $name = _loc( $_->{name} );
        my $id   = _name_to_id($name);
        $data->{color} //= 'transparent';
        "menu.topic.create.$id" => {
            label =>
qq[<div id="boot" style="background:transparent"><span class="label" style="background-color:$data->{color}">$name</span></div>],
            index    => $seq++,
            actions  => [ { action => "action.topics.create", bounds => { id_category => $data->{id} } } ],
            url_comp => '/topic/view',
            comp_data => { new_category_name => $name, new_category_id => $data->{id}, swEdit=>'1' },
            tab_icon  => '/static/images/icons/topic.svg'
          }
    } sort { lc $a->{name} cmp lc $b->{name} } @cats;

    my %menu_statuses = map {
        my $data = $_;
        my $name = _loc( $_->{name} );
        my $id   = _name_to_id($name);
        $data->{color} //= 'transparent';
        "menu.topic.status.$id" => {
            label =>
qq[<span style="white-space: nowrap; text-transform: uppercase; font-weight: bold; padding-bottom: 1px; font-size: 10px;">$name</span>],
            title =>
qq[<span style="white-space: nowrap; text-transform: uppercase; padding-bottom: 1px; font-size: 10px;">$name</span>],
            index       => $seq++,
            hideOnClick => 0,

            #actions  => ["action.topics.$id.create"],
            url_comp => '/topic/grid?status_id=' . $data->{id_status},
            icon     => $data->{status_icon} || '/static/images/icons/state.svg',
            tab_icon => $data->{status_icon} || '/static/images/icons/state.svg',
          }
      } sort { lc $a->{name} cmp lc $b->{name} }
      ci->status->find->fields( { id_status => 1, name => 1, color => 1, seq => 1, status_icon => 1 } )->all;

    my $menus = {
        'menu.topic' => {
            label   => _locl('Topics'),
            title   => _locl('Topics'),
            actions => ['action.topics.%'],
        },
        'menu.topic.topics' => {
            index     => 1,
            label     => _locl('All'),
            title     => _locl('Topics'),
            actions   => ['action.topics.%'],
            url_comp  => '/topic/grid',
            comp_data => { tabTopic_force => 1 },
            icon      => '/static/images/icons/topic.svg',
            tab_icon  => '/static/images/icons/topic.svg'
        },
        'menu.topic._sep_' => { index => 3, separator => 1 },
        %menu_create,
        %menu_statuses,
        %menu_view,
    };

    $menus->{'menu.topic.status'} = {
        label => _locl('Status'),
        icon  => '/static/images/icons/state.svg',
        index => 2,
    } if %menu_statuses;

    $menus->{'menu.topic.create'} = {
        label   => _locl('Create'),
        icon    => '/static/images/icons/add.svg',
        index   => 2,
        actions => [ { action => 'action.topics.create', bounds => '*' } ],
      }
      if %menu_create;

    return $menus;
}

sub grid : Local {
    my ( $self, $c, $typeApplication ) = @_;

    my $p = $c->req->params;

    # Special parameter for Cetelem (maybe not needed in > 6.0)
    $c->stash->{typeApplication} = $typeApplication;

    $c->stash->{id_project} = $p->{id_project};
    $c->stash->{project}    = $p->{project};
    $c->stash->{query_id}   = $p->{query};
    if ( $p->{category_id} ) {
        $c->stash->{category_id} = $p->{category_id};

        my $category = mdb->category->find_one( { id => $p->{category_id} } );
        if ( $category->{default_grid} ) {
            try {
                my $report = ci->new( $category->{default_grid} );

                if ($report) {
                    my $selected_fields = $report->selected_fields( { username => $c->username } );
                    my $data_fields = { fields => $selected_fields };
                    $c->stash->{id_report}   = $category->{default_grid};
                    $c->stash->{data_fields} = Util->_encode_json($data_fields);
                }
            }
            catch {
                $c->stash->{id_report}   = '';
                $c->stash->{no_report_category} = 1;
            }

        }else {
            $c->stash->{id_report}   = '';
            $c->stash->{no_report_category}   = 1;
        }
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
        $c->stash->{json} = {
            data       => $data->{data},
            totalCount => $data->{totalCount},
            last_query => $data->{last_query},
            query      => $p->{query},
            username   => $p->{username},
            id_project => $data->{id_project}
        };
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
    } elsif( $p->{id_report} ) {
        my $filter = $p->{filter} ? _decode_json($p->{filter}) : undef;
        my $start = $p->{start} // 0;
        for my $f (_array $filter){
            my @temp = split('_', $f->{field});
            $f->{category} = $temp[$#temp];
        }
        my $dir = $p->{dir} && uc($p->{dir}) eq 'DESC' ? -1 : 1;

        my %report_params = (
            start        => $start,
            username     => $p->{username},
            limit        => $p->{limit},
            query        => $p->{topic_list},
            filter       => $filter,
            query_search => $p->{query},
            sort         => $p->{sort},
            sortdir      => $dir
        );

        if ( ref $p->{id_category_report} eq 'ARRAY' ) {
            $report_params{id_category_report} = $p->{id_category_report}
                if scalar @{ $p->{id_category_report} };
        }
        else {
            $report_params{id_category_report} = $p->{id_category_report}
                if $p->{id_category_report} ne '';
        }

        my ( $cnt, @rows ) = ci->new( $p->{id_report} )->run(%report_params);

        $data = {
            data=>\@rows,
            totalCount=>$cnt
        }

    } elsif( my $id = $p->{id_report_rule} ) {
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

        my $rule_runner = Baseliner::RuleRunner->new;
        $rule_runner->find_and_run_rule( id_rule => $p->{id_report_rule}, stash => $stash );

        my $report_data = ref $$stash{report_data} eq 'CODE' ? $$stash{report_data}->(%$p) : $$stash{report_data};
        _fail _loc('Invalid report data for report %1',$id) unless ref $report_data->{data} eq 'ARRAY';
        $data = {
            data=>$report_data->{data},
            totalCount=>$report_data->{cnt} || []
        }

    } else  {
        my ($info, @rows ) = Baseliner->model('Topic')->topics_for_user( $p );

        $data = {
            data=>\@rows,
            totalCount=>$$info{count},
            last_query=>$$info{last_query},
            id_project=>$$info{id_project}
        };
    }

    return $data;
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    $p->{status_new} = $p->{status_new}[0] if (ref $p->{status_new} eq 'ARRAY');     # Only for IE8
    $p->{username} = $c->username;
    my $return_options;   # used by event rules to return anything back to the form

    my $action = $p->{action};

    try  {
        my $validated_params;
        if ( $action eq 'add' || $action eq 'update' ) {
            $validated_params = Baseliner::Model::Topic->new->filter_valid_update_params($p);
        }
        else {
            %$validated_params = %$p;
        }

        my ($isValid, @field_name) = (1,());
        #my ($isValid, @field_name) = $c->model('Topic')->check_fields_required( mid => $p->{topic_mid}, username => $c->username, data => $p);

        if($isValid == 1){
            my ($msg, $topic_mid, $status, $title, $category, $modified_on);
            ( $msg, $topic_mid, $status, $title, $category, $modified_on, $return_options ) =
              $c->model('Topic')->update( { %$validated_params, action => $p->{action} } );
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

    my $ci = ci->topic->find_one({ mid=>"$topic_mid" });
    my $date_actual_modified_on = Class::Date->new( $ci->{ts} );
    my $who = $ci->{modified_by};
    if ( $date_modified_on < $date_actual_modified_on ){
        $modified_before = $who;
        $duration = Util->to_dur( $date_actual_modified_on - $date_modified_on );
    } else {
        my $old_signature = $p->{rel_signature};
        my $new_signature = Baseliner::Model::Topic->new->rel_signature($topic_mid);
        $modified_rel = \1 if $old_signature ne $new_signature;
    }

    $c->stash->{json} = {
        success                  => \1,
        modified_before          => $modified_before,
        modified_before_duration => $duration,
        modified_rel             => $modified_rel,
        msg                      => _loc( 'Test' ),
    };
    $c->forward('View::JSON');
}

sub related : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    my $categories    = $p->{categories};
    my $statuses      = $p->{statuses};
    my $not_in_status = $p->{not_in_status};
    my $show_release  = $p->{show_release};
    my $logic         = $p->{logic};

    my $where;
    my $valuesqry = $p->{valuesqry};
    if ( $valuesqry && $valuesqry eq 'true' ) {
        $where = { mid => mdb->in( split /\s+/, join ' ', _array( delete $p->{query} ) ) };
    }
    my $search_query =  $p->{query};

    my $filter = $p->{filter};

    if ($filter) {
        my $filter_json = _decode_json($filter);
        for my $key_filter ( keys %$filter_json ) {
            my @values = _array_or_commas( $filter_json->{$key_filter} );
            if ( scalar @values > 1 ) {
                my $operator = $logic eq 'AND' ? '$all' : '$in';
                $filter_json->{$key_filter} = { $operator => [@values] };
                $filter = _encode_json($filter_json);
            }
        }
    }
    my $start = $p->{start} //= 0;
    my $limit = $p->{limit} //= 20;
    my $sort  = $p->{sort_field};
    my $dir   = $p->{dir};

    my $view = $self->_build_data_view;

    my $rs = $view->find(
        username      => $c->username,
        categories    => $categories,
        statuses      => $statuses,
        not_in_status => $not_in_status && $not_in_status eq 'on',
        search_query  => $search_query,
        valuesqry     => $valuesqry,
        where         => $where,
        filter        => $filter,
        start         => $start,
        limit         => $limit,
        sort          => $sort,
        dir           => $dir,
        $show_release ? ( category_type => 'release' ) : (),
    );
    $rs->fields( { _txt => 0 } );

    my @topics = $rs->all;

    @topics = map {
        $_->{name}  = _loc( $_->{category}->{name} ) . ' #' . $_->{mid};
        $_->{color} = $_->{category}{color};
        $_->{short_name} =
          Baseliner::Model::Topic->new->get_short_name( name => $_->{category}->{name} ) . ' #' . $_->{mid}
          if $_->{mid};
        $_
    } @topics;

    $c->stash->{json} = { totalCount => $rs->count, data => \@topics };
    $c->forward('View::JSON');
}

our %field_cache;

sub get_field_bodies {
    my ($self, $meta ) = @_;
    # load comp body for each field
    for my $field ( _array( $meta ) ) {
        next unless length $field->{js};
        my $file = Clarive->path_to( 'root', $field->{js} );
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

sub get_menu_deploy : Private {
    my ( $self, $p ) = @_;

    my $topic_mid = $p->{topic_mid};
    my $username  = $p->{username};

    my $topic_ci  = ci->new($topic_mid);
    my $topic_doc = $topic_ci->get_doc;

    my $menu_deploy;

    my $category = mdb->category->find_one( { id => $topic_doc->{id_category} } );
    my $status = ci->status->find_one( { id_status => $topic_doc->{id_category_status} } );

    if ( $category->{is_release} || !$status->{bind_releases} ) {
        my ($id_project) = map { $_->{mid} } $topic_ci->projects;
        my ( $deployable, $promotable, $demotable, $menu_s, $menu_p, $menu_d) =
          Baseliner::Model::PromotesAndDemotes->new->promotes_and_demotes_menu(
            topic      => $topic_doc,
            username   => $username,
            id_project => $id_project
          );
        $menu_deploy = {
            deployable => $deployable,
            promotable => $promotable,
            demotable  => $demotable,
            menu       => [ _array $menu_s, _array $menu_p, _array $menu_d ]
        };
    }
    else {
        $menu_deploy = { deployable => {}, promotable => {}, demotable => {}, menu => [] };
    }

    return $menu_deploy;
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
    my $id_category = $p->{new_category_id} // $p->{category_id};

    my $category;

    my $permissions = Baseliner::Model::Permissions->new;
    my $is_root = $permissions->new->is_root($c->username);

    try {
        my $topic_doc;

        $c->stash->{user_security} = $c->user_ci->{project_security};
        $c->stash->{ii} = $p->{ii};
        $c->stash->{swEdit} =  ref($p->{swEdit}) eq 'ARRAY' ? $p->{swEdit}->[0]:$p->{swEdit} ;
        $c->stash->{permissionEdit} = 0;
        $c->stash->{permissionDelete} = 0;
        my $topic_ci = ci->new($topic_mid) if $topic_mid;
        $c->stash->{permissionGraph} = $topic_mid
          && Baseliner::Model::Permissions->user_has_action( $c->username, 'action.topics.view_graph' )
          && $topic_ci->related( depth => 1, mids_only => 1 );
        $c->stash->{permissionComment} = 0;
        $c->stash->{permissionActivity} = 0;
        $c->stash->{permissionJobs} = 0;
        $c->stash->{permissionJobsLink} = 0;

        if ( $topic_mid ) {
            try {
                $c->stash->{viewKanban} = $topic_ci->children( where=>{collection => 'topic'}, mids_only => 1 );
                $c->stash->{viewDocs} = $c->stash->{viewKanban} && ( $is_root || Baseliner::Model::Permissions->user_has_action(  $c->username, 'action.home.generate_docs' ));
                $topic_doc = $topic_ci->get_doc;

                $id_category = $topic_doc->{category}->{id};
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

        #if ($is_root){
            #$c->stash->{HTMLbuttons} = 0;
        #}
        #else{
            #$c->stash->{HTMLbuttons} = Baseliner::Model::Permissions->user_has_action( $c->username, 'action.GDI.HTMLbuttons' );
        #}

        my %categories_edit = map { $_->{id} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'edit', id => $id_category );
        my %categories_delete = map { $_->{id} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'delete', id => $id_category );
        my %categories_view = map { $_->{id} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'view', id => $id_category );
        my %categories_comment = map { $_->{id} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'comment', id => $id_category );
        my %categories_activity = map { $_->{id} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'activity', id => $id_category );
        my %categories_jobs = map { $_->{id} => 1} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'jobs', id => $id_category );

        if($topic_mid || $c->stash->{topic_mid} ){

            $c->stash->{category_id} = $topic_doc->{category}{id};
            # user seen
            for my $mid ( _array( $topic_mid ) ) {
                mdb->master_seen->update({ username=>$c->username, mid=>$mid },{ username=>$c->username, mid=>$mid, type=>'topic', last_seen=>mdb->ts },{ upsert=>1 });
            }

            $category = mdb->category->find_one({ id=>$topic_doc->{category}{id} },{ fieldlets=>0 });
            _fail( _loc('Category not found or topic deleted: %1', $topic_mid) ) unless $category;

            $c->stash->{category_name} = $category->{name};
            $c->stash->{category_color} = $category->{color};

            $c->stash->{dashboard} = $category->{dashboard};
            if ( $category->{is_changeset} || $category->{is_release} ) {
                my $menu = $self->get_menu_deploy( { topic_mid => $topic_mid, username => $c->username } );
                $c->stash->{menu_deploy} = _encode_json($menu);
            }

            my $action = $permissions->user_action( $c->username, 'action.topics.view',
                bounds => { id_category => $category->{id} } );

            _fail( _loc( "User %1 is not allowed to access topic %2 contents", $c->username, $topic_mid ) )
              unless $action && Baseliner::Model::Permissions->user_has_security(
                $c->username,
                $topic_doc->{_project_security},
                roles => $action->{roles}
              );

            $c->stash->{category_meta} = $category->{forms};

            # workflow category-status
            my @statuses =
                sort { ( $a->{status_name} ) cmp ( $b->{status_name} ) }
                grep { $_->{id_status} ne $topic_doc->{category_status}{id} }
                Baseliner::Model::Topic->next_status_for_user(
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
                if ($is_root){
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
                $c->stash->{has_comments} = Baseliner::Model::Topic->list_posts( mid=>$topic_mid, count_only=>1 );
            } else {
                $c->stash->{permissionComment} = 0;
                $c->stash->{has_comments} = 0;
            }
            if (exists ($categories_activity{ $category->{id} })){
                $c->stash->{permissionActivity} = 1;
            } else {
                $c->stash->{permissionActivity} = 0;
            }

            if($c->stash->{permissionActivity} || $is_root ){
                $c->stash->{viewTimeline} = 1;
            } else {
                $c->stash->{viewTimeline} = 0;
            }
            # jobs for release and changeset
            if( $category->{is_changeset} || $category->{is_release} ) {
                my $has_permission;
                my $has_permission_link = Baseliner::Model::Permissions->new->user_has_action( $c->username, 'action.job.view_monitor' );
                if (exists ($categories_jobs{ $category->{id} })){
                    $c->stash->{permissionJobs} = 1;
                    $c->stash->{permissionJobsLink} = 1 if $has_permission_link;
                } else {
                    $c->stash->{permissionJobs} = 0;
                    $c->stash->{permissionJobsLink} = 0;
                }
            } else {
                $c->stash->{permissionJobs} = -1;
                $c->stash->{permissionJobsLink} = -1;
            }

            # used by the Change State menu in the topic
            $c->stash->{status_items_menu} = _encode_json(\@statuses);
        } else {
            $c->stash->{category_id} //= $id_category;

            my $category = mdb->category->find_one({ id=>"$id_category" });
            $c->stash->{category_meta} = $category->{forms};
            $c->stash->{category_name} = $category->{name};
            $c->stash->{category_color} = $category->{color};
            $c->stash->{dashboard} = $category->{dashboard};

            my $first_status = ci->status->find_one({ id_status=>mdb->in( $category->{statuses} ), type=>'I' }) // _fail( _loc('No initial state found'));

            my @statuses =
                sort { ( $a->{status_name} ) cmp ( $b->{status_name} ) }
                grep { $_->{id_status} ne $first_status->{id_status} }
                Baseliner::Model::Topic->next_status_for_user(
                    id_category    => $id_category,
                    id_status_from => $first_status->{id_status},
                    username       => $c->username,
                    topic_mid      => $topic_mid
                );
            $c->stash->{status_items_menu} = _encode_json(\@statuses);

            $c->stash->{permissionEdit} = 1 if exists $categories_edit{$id_category};
            $c->stash->{permissionDelete} = 1 if exists $categories_delete{$id_category};
            $c->stash->{permissionComment} = 1 if exists $categories_comment{$id_category};
            $c->stash->{permissionActivity} = 1 if exists $categories_activity{$id_category};
            $c->stash->{viewTimeline} = $c->stash->{permissionActivity};
            $c->stash->{permissionJobs} = 1 if exists $categories_jobs{$id_category};
            my $has_permission_link = Baseliner::Model::Permissions->new->user_has_action(  $c->username, 'action.job.view_monitor' );
            $c->stash->{permissionJobsLink} = 1 if exists $categories_jobs{$id_category} && $has_permission_link;
            $c->stash->{has_comments} = 0;
            $c->stash->{topic_mid} = '';
        }

        if( $p->{html} ) {
            my $meta = Baseliner::Model::Topic->get_meta( $topic_mid, $id_category );
            my $data = Baseliner::Model::Topic->get_data( $meta, $topic_mid, topic_child_data=>$p->{topic_child_data} );
            $meta = $self->get_field_bodies( $meta );
            $meta = model->Topic->get_meta_permissions( username=>$c->username, meta=>$meta, data=>$data );

            foreach my $field (@$meta) {
                next
                  unless $field->{key}
                  && ( $field->{key} eq 'fieldlet.html_editor'
                    || $field->{key} eq 'fieldlet.system.description' );

                my $name  = $field->{id_field};
                my $value = $data->{$name};

                $data->{$name} = _strip_html_editor($value);
            }

            #my $write_action = 'action.topicsfield.' .  _name_to_id($topic_doc->{name_category}) . '.labels.' . _name_to_id($topic_doc->{name_status}) . '.write';
            #$data->{admin_labels} = Baseliner::Model::Permissions->user_has_any_action( username=> $c->username, action=>$write_action );

            $data->{remove_labels} = Baseliner::Model::Permissions->user_has_action( $c->username, 'action.labels.remove_labels' );
            $c->stash->{topic_meta} = $meta;
            $c->stash->{topic_data} = $data;
            $c->stash->{template} = '/comp/topic/topic_msg.html';
        } else {
            $c->stash->{template} = '/comp/topic/topic_main.js';
        }
    } catch {
        my $error = shift;

        $c->stash->{json} = { success=>\0, msg=>_loc("Problem found opening topic %1. The error message is: %2", $topic_mid, $error) };
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
                $data .= "<b>" . _loc('Name') . "</b>: " . $name . "<br><br>";
            }
            if ($email ne ''){
                $data .= "<b>" . _loc('E-mail') . "</b>: " . $email . "<br><br>";
            }
            if ($phone ne ''){
                $data .= "<b>" . _loc('Phone Number') . "</b>: " . $phone . "<br><br>";
            }
            if ($data eq ''){
                $data .= _loc("No user details available") . " <b>" . $username . "</b>.<br>";
            }else{
                $data = "<b>" . _loc('Username') . "</b>: " . $username . "<br><br>" . $data;
            }
            $c->stash->{json} = { msg => $data, failure => \0 };
        } catch {
            my $err = shift;
            _error( $err );
            $c->stash->{json} = { msg => _loc('The user %1 does not exist in Clarive', $username ), failure => \1 };
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
                    mid         => $topic_mid,
                    id_category => $topic_row->{category}{id},
                    id_status   => $topic_row->{category_status}{id},
                    projects    => \@projects );
            my $subject = _loc("@%1 created a post for #%2 %3", $c->username, $topic_row->{mid}, $topic_row->{title} );
            my $notify = { #'project', 'category', 'category_status'
                mid             => $topic_row->{mid},
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

                #old posts..
                my @mids_only = map { $_->{to_mid} } mdb->master_rel->find({from_mid=>"$topic_mid", rel_type=>"topic_post"})->fields({to_mid=>1})->all;
                my @old_post;
                for my $old_post (@mids_only){
                    my $post = ci->new($old_post);
                    my $text;
                    $text->{username} = $post->{created_by};
                    $text->{created_on} = $post->{created_on};
                    $text->{text} = $post->text;
                    push @old_post, $text if($text);
                }
                @old_post = sort { $b->{created_on} cmp $a->{created_on} } @old_post;

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
                    old_post        => \@old_post,
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
                my @users = Baseliner->model("Topic")->get_users_friend(
                    mid         => $mid_topic,
                    id_category => $topic_row->{category}{id},
                    id_status   => $topic_row->{category_status}{id},
                    projects    => \@projects );
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

sub category_list : Local {    #this is for ComboCategories
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $query             = $p->{query} // '';
    my $query_as_values   = $p->{valuesqry};
    my $with_extra_values = $p->{with_extra_values};
    my $is_release        = $p->{is_release} ? '1' : '0';

    my @categories = Baseliner::Model::Topic->get_categories_permissions(
        username   => $c->username,
        is_release => $is_release,
        type       => 'view'
    );

    @categories = map { +{ id => $_->{id}, color => $_->{color}, name => $_->{name} } }
      sort { lc $a->{name} cmp lc $b->{name} } @categories;

    if ($query) {
        my $query_re = $query_as_values ? join( '|', map { quotemeta $_ } split /\|/, $query ) : quotemeta($query);
        $query_re = qr/$query_re/i;

        my $query_key = $query_as_values ? 'id' : 'name';
        @categories = grep { $_->{$query_key} =~ $query_re } @categories;
    }

    if ( $with_extra_values && $query_as_values && !@categories ) {
        @categories = ( { id => $query, name => $query } );
    }

    $c->stash->{json} = {
        data       => [@categories],
        totalCount => scalar @categories
    };

    $c->forward('View::JSON');
}

sub list_category : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my ( $dir, $sort, $cnt ) = ( @{$p}{qw/dir sort/}, 0 );
    $dir  ||= 'asc';
    $sort ||= 'name';

    my $order = { dir => $dir, sort => $sort };
    my @rows;

    if ( !$p->{categoryId} ) {
        my $action = $p->{action} && $p->{action} eq 'create' ? 'create' : 'view';
        my @categories = Baseliner::Model::Topic->get_categories_permissions(
            username   => $c->username,
            type       => $action,
            order      => $order,
            all_fields => 1
        );

        if ( $p->{categories_filter} || $p->{categories_id_filter} ) {
            my %allowed_categories_map = map { $_->{id} => 1 } @categories;

            my @filtered_categories = $self->_filter_categories_permissions(
                username             => $c->username,
                categories_id_filter => $p->{categories_id_filter},
                categories_filter    => $p->{categories_filter}
            );

            @categories = ();
            foreach my $category (@filtered_categories) {
                if ($allowed_categories_map{$category->{id}}) {
                    push @categories, $category;
                }
            }
        }

        if (@categories) {
            foreach my $category (@categories) {
                my @statuses = _array( $category->{statuses} );

                my $type = $category->{is_changeset} ? 'C' : $category->{is_release} ? 'R' : 'N';
                my @fieldlets;

                my $forms = $self->form_build( $category->{forms} );

                push @rows, {
                    id            => $category->{id},
                    category      => $category->{id},
                    name          => $p->{swnotranslate} ? $category->{name} : _loc( $category->{name} ),
                    acronym       => $category->{acronym},
                    color         => $category->{color},
                    type          => $type,
                    forms         => $forms,
                    category_name => _loc( $category->{name} ),
                    is_release    => $category->{is_release},
                    is_changeset  => $category->{is_changeset},
                    description   => $category->{description},
                    default_grid  => $category->{default_grid},
                    default_form  => $category->{default_form}
                      // $category->{default_field},    ## FIXME default_field is legacy
                    default_workflow => $category->{default_workflow},
                    dashboard        => $category->{dashboard},
                    statuses         => \@statuses,
                    fields           => \@fieldlets,
                };

            }
        }
        $cnt = @rows;
    }
    else {
        # Status list for combo and grid in workflow
        my $cat = mdb->category->find_one( { id => mdb->in( $p->{categoryId} ) }, { statuses => 1 } );
        my @statuses = sort { $a->seq <=> $b->seq } ci->status->search_cis( id_status => mdb->in( $$cat{statuses} ) );
        for my $status (@statuses) {
            for my $bl_status ( _array( $status->bls ) ) {
                push @rows,
                  {
                    id   => $status->id_status,
                    bl   => $bl_status,
                    name => $status->name_with_bl( no_common => 1 ),
                  };
            }
        }
        $cnt = @rows;
    }

    $c->stash->{json} = { data => \@rows, totalCount => $cnt };
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
            _fail _loc('No metadata found for this topic (%1)', $topic_mid) unless ref $meta eq 'ARRAY';
            $field = [
                sort { ($a->{field_order}//0) cmp ($b->{field_order}//0) }
                grep { !defined $_->{main_field} || $_->{main_field} }  # main_field tells me this is the one to drop on
                grep { ( !defined $_->{collection} || $_->{collection} eq 'project') && $_->{meta_type} eq 'project' }
                @$meta
            ]->[0];
            _fail _loc('No project field found for this topic (%1)', $topic_mid) unless $field;
            # get current data
            my $id_field = $field->{id_field};
            my $doc = mdb->topic->find_one({ mid=>"$topic_mid" },{ $id_field => 1 });
            _fail _loc('Topic not found: %1', $topic_mid) unless ref $doc;
            my $fdata = [ _array( $doc->{$id_field} ) ];
            push $fdata, $id_project;
            $c->model('Topic')->update({ action=>'update', topic_mid=>$topic_mid, username=>$c->username, $id_field=>$fdata });
        } else {
            _fail _loc('Project not found: %1', $id_project);
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
        text    => _loc('Created by Me'),
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
    my @categories_permissions  = Baseliner::Model::Topic->get_categories_permissions( id=>$category_id, username=>$c->username, type=>'view', all_fields=>1 );

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
                    priority    => $_->{priority} // 0,
                    cls         => 'forum label',
                    iconCls     => 'icon-no',
                    checked     => \0,
                    leaf        => 'true',
                    uiProvider => 'Baseliner.CBTreeNodeUI'
                };
            }

            @labels = sort { $b->{priority} <=> $a->{priority} } @labels;

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
    my $is_root = Baseliner::Model::Permissions->is_root( $c->username );
    ##Filtramos por defecto los estados q puedo interactuar (workflow) y los que no tienen el tipo finalizado.
    my %tmp;

    if ( !$is_root ) {
        my %p;
        $p{categories} = \@id_categories;
        map { $tmp{$_->{id_status_from}} = $_->{id_category} }
                    Baseliner::Model::Topic->user_workflow( $c->username, %p );
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
    my $topic_mid = $p->{topic_mid} // '';

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
        my ($id_category,$id_status);
        if( my $doc = mdb->topic->find_one({ mid=>"$topic_mid" },{ category_status=>1, name_status=>1, category=>1 }) ) {
            $id_category = $doc->{category}{id} ;
            $id_status   = $doc->{category_status}{id};
        } else {
            $id_category  = $p->{categoryId};
            $id_status    = $p->{statusId};
        }

        my @statuses = model->Topic->next_status_for_user(
            id_category    => $id_category,
            id_status_from => $id_status,
            username       => $c->username,
            topic_mid      => $topic_mid,
        );

        my $current_status = ci->status->find_one({ id_status=>"$id_status" }) or _fail( _loc('Status not found: %1', $id_status ) );
        my $status_name = _loc( $current_status->{name} );
        push @rows, {
            id          => $id_status,
            name        => $status_name,
            status      => $id_status,
            status_name => $status_name,
            action      => Baseliner::Model::Topic->getAction($current_status->{type}),
        };

        push @rows , map {
            my $action = model->Topic->getAction($_->{status_type});
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

sub next_status_for_topics : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $topic_mids = $p->{topics};

    my %all_status;
    my @ids;
    my @uniq;
    my @topics = mdb->topic->find({ mid=>mdb->in($topic_mids) })->fields({ mid=>1, category=>1, category_status=>1 })->all;
    for my $topic ( @topics ) {
        my @statuses = model->Topic->next_status_for_user(
            username       => $c->username,
            id_category    => $topic->{category}{id},
            id_status_from => $topic->{category_status}{id},
            topic_mid      => $topic->{mid},
        );
        for my $st ( @statuses ) {
            $all_status{ $st->{id_status_to} }= $st;
        }
        push @ids, [ map{ $_->{id_status_to} } @statuses ];
        push @uniq, map{ $_->{id_status_to} } @statuses;
    }
    # now intersect all statuses to get common ones
    for( @ids ) {
        my %hh = map{ $_=>1 } @uniq;
        @uniq = grep($hh{$_},@$_);
    }
    #$c->stash->{json} = { data=>[ sort { $a->{seq_to} <=> $b->{seq_to} or $a->{status_name} cmp $b->{status_name} } map{ $all_status{$_} } @uniq ]};
    $c->stash->{json} = { data=>[ sort { $a->{status_name} cmp $b->{status_name} } map{ $all_status{$_} } @uniq ]};
    $c->forward('View::JSON');
}

sub is_valid_extension {
    my ( $self, %params ) = @_;
    return 1 if ( !$params{filter} );

    my $filter = lc( $params{filter} );
    my $filename = $params{filename};

    my $extension = Util->_get_extension_file($filename);
    $extension =  lc($extension) if ($extension);

    my @filters = split /,|\s+/, $filter;
    @filters = grep { $_ ne '' } @filters;
    @filters = map { $_ =~ s/^\.//; $_ } @filters;

    my $exist = grep { $_ eq $extension} @filters;

    return $exist ? 1 : 0;
}

sub upload : Local {
    my ( $self, $c ) = @_;

    return
        unless my $params = $self->validate_params(
        $c,
        qqfile    => { isa => 'Str' },
        extension => { isa => 'Str', default => '' },
        filter    => { isa => 'Str' },
        fullpath  => { isa => 'Str', default => '' },
        topic_mid => { isa => 'Str' },
        );

    try {
        my $filename         = $params->{qqfile};
        my $extension_filter = $params->{extension};
        my $id_field         = $params->{filter};
        my $fullpath         = $params->{fullpath} // '';
        my $topic_mid        = $params->{topic_mid};
        my $username         = $c->username;

        _fail _loc('qqfile is not a file')
            if $c->req->body eq '' && !$c->req->upload('qqfile');

        my $file;
        if ( $c->req->body eq '' ) {
            my $x = $c->req->upload('qqfile');
            $file = _file( $x->tempname );
        }
        else {
            $file = _file( '' . $c->req->body );
        }

        if ( $file->basename eq '0' ) {
            my $tempdir  = Util->_tmp_dir();
            my $fullpath = "$tempdir/$filename";
            open my $fh, '>', $fullpath or die $!;
            close $fh;
            $file = _file $fullpath;
        }

        if ($self->is_valid_extension(
                filter   => $extension_filter,
                filename => $filename
            )
            )
        {
            my $model_topic = Baseliner::Model::Topic->new;
            my %result      = $model_topic->upload(
                file      => $file,
                topic_mid => $topic_mid,
                filename  => $filename,
                filter    => $id_field,
                fullpath  => $fullpath,
                username  => $username
            );

            my $msg = _loc(
                'Uploaded file %1, file_uploaded_mid: %2',
                $result{upload_file}->{name},
                $result{upload_file}->{mid}
            );

            $c->stash->{json} = { success => 1, msg => $msg, %result };

        }
        else {
            _throw _loc( "This type of file is not allowed, only (%1)",
                $extension_filter );
        }
    }
    catch {
        my $err = shift;
        _error $err;
        chomp($err);

        $c->stash->{json} = { success => 0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub upload_complete: Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $p->{username} = $c->username;

    try {
        Baseliner::Model::Topic->new->upload_complete(%$p);

        $c->stash->{json} = { success => 1, msg => 'Upload completed' };
    }
    catch {
        my $err = shift;
        _error $err;
        chomp($err);

        $c->stash->{json} = { success => 0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub remove_file : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $topic_mid = $p->{topic_mid} or _fail _loc('topic mid required');
    my $asset_mid = $p->{asset_mid};
    my $username  = $c->username;
    my $fields    = $p->{fields};

    try {
        Baseliner::Model::Topic->new->remove_file(
            topic_mid => $topic_mid,
            asset_mid => $asset_mid,
            username  => $username,
            fields    => $fields
        );
        $c->stash->{json} = { success => \1, msg => _loc( 'Deleted files from topic %1', $topic_mid ) };
    }
    catch {
        my $err = shift;
        _error $err;
        chomp($err);

        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
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
                $ass = @res > 1 ? _fail( _loc('More than one asset found for topic %1 matching name `%2`',$mid,$fn))
                    : @res == 0 ? _fail( _loc('No asset found for topic %1 matching name `%2`',$mid,$fn))
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
    my @files;
    my @directory_nodes;
    my %id_path_node;

    my @asset_mid;

    try {
        if ($topic_mid) {
            _fail _loc('filter param is required') if !$rel_field;
            @asset_mid = mdb->master_rel->find_values(
                to_mid => {
                    from_mid  => "$topic_mid",
                    rel_field => "$rel_field",
                    rel_type  => 'topic_asset'
                }
            );
        }else{
            @asset_mid = _array( $p->{files_mid} );
        }

        my @asset = ci->asset->search_cis( mid => mdb->in( @asset_mid ));

        foreach my $asset ( @asset ){
            my ( $size, $unit ) = Util->_size_unit( $asset->filesize );
            $size = "$size $unit";

            my $path;
            if ($asset->{fullpath}){
                my $file = _file($asset->{fullpath});
                $path = $file->dir->stringify;
                my @directories = _array $file->dir->{dirs};
                unshift @directories, '';
                while ( my $relative_path = join( '/', @directories ) ) {
                    my $dir_name = pop @directories;
                    if ( !$id_path_node{$relative_path} ) {
                        $id_path_node{$relative_path} = $relative_path . '_' . _nowstamp;
                        push @directory_nodes,
                            {
                            filename  => $dir_name,
                            versionid => undef,
                            mid       => undef,
                            _id       => $id_path_node{$relative_path},
                            _parent   => undef,
                            _is_leaf  => \0,
                            size      => undef,
                            path      => join( '/', @directories )
                            };
                    }
                }
            }

            push @files,
                {
                filename  => $asset->filename,
                versionid => $asset->versionid,
                mid       => $asset->mid,
                _id       => $asset->mid,
                _parent   => undef,
                _is_leaf  => \1,
                size      => $size,
                path      => $path || '/'
                }
        }

        my @nodes;
        foreach my $file (@files){
            $file->{_parent} = $id_path_node{ $file->{path} } if ( $id_path_node{$file->{path}} );
            push @nodes, $file;
        }

        foreach my $directory (@directory_nodes){
            $directory->{_parent} = $id_path_node{ $directory->{path} } if ( $id_path_node{$directory->{path}} );
            push @nodes, $directory;
        }

        $c->stash->{json} = { total => scalar(@files), success => \1, data => \@nodes };
    }
    catch {
        my $err = shift;
        _error $err;
        chomp($err);

        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub list_users : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my $projects  = $p->{projects};
    my $topic_mid = $p->{topic_mid};
    my $roles     = $p->{roles};
    my $start     = $p->{start};
    my $limit     = $p->{limit};
    my $query     = $p->{query};

    my $username = $c->username;

    my $users_friends;
    if ($projects) {
        my @projects = _array $projects;
        $users_friends = Baseliner::Model::Users->new->get_users_friends_by_projects( \@projects );
    }
    else {
        my @topic_projects;
        if ($topic_mid) {
            @topic_projects = ci->new($topic_mid)->projects;
        }

        if ( $roles && $roles ne 'none' ) {
            my @roles = _array_or_commas $roles;

            if (@roles) {
                $users_friends = Baseliner::Model::Users->new->get_users_from_mid_roles(
                    roles    => \@roles,
                    projects => \@topic_projects
                );
            }
        }
        else {
            $users_friends = Baseliner::Model::Users->new->get_users_friends_by_username($username);
        }
    }

    if ($query) {
        $users_friends = [ grep { m/\Q$query\E/i } _array $users_friends];
    }

    my $users_cursor = ci->user->find( { username => mdb->in($users_friends) } );
    $users_cursor->sort( { realname => 1 } );
    $users_cursor->skip($start)  if $start;
    $users_cursor->limit($limit) if $limit;

    my @rows;
    while ( my $user = $users_cursor->next ) {
        push @rows,
          {
            id       => $user->{mid},
            username => $user->{username},
            realname => $user->{realname}
          };
    }

    $c->stash->{json} = { totalCount => scalar(@rows), data => \@rows };
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

sub kanban_status : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    my $topic_list = $p->{topics};
    my $mid = $p->{mid};
    my $data = {};
    my @columns;
    my $config = {};
    if( length $mid ) {
        my $doc = mdb->topic->find_one({ mid=>"$mid" },{ _kanban=>1 });
        $config = $doc->{_kanban};
    }
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
        my @transitions = model->Topic->user_workflow( $c->username, categories=>[keys %cats] );

        my %workflow;
        my %status_mids;
        my %visible_status;  # list with destination to statuses to reduce cruft on top of kanban
        # for each workflow transition for this user:
        for my $wf ( @transitions ) {
            next if $$wf{id_status_from} == $$wf{id_status_to}; # don't need static promotions in Kanban
            # for each mid in this category
            for my $topic ( _array $cats{ $$wf{id_category} } ) {
                my $mid = $$topic{mid};
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
                if( $$topic{id_category_status} == $$wf{id_status_from} ) {
                    $visible_status{ $$wf{id_status_from} } = 0+( $config->{statuses}{$$wf{id_status_from}} // 1 );
                    $visible_status{ $$wf{id_status_to} } = 0+ ( $config->{statuses}{$$wf{id_status_to}} // 1 );
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

sub kanban_config : Local {
    my ($self, $c) = @_;
    my $mid = $c->req->params->{mid};
    if( my $statuses = $c->req->params->{statuses} ) {
        mdb->topic->update({ mid=>"$mid" },{ '$set'=>{ '_kanban.statuses'=>$statuses } });
        $c->stash->{json} = { success=>\1 };
    } elsif( length $mid )  {
        my $doc = mdb->topic->find_one({ mid=>"$mid" },{ _kanban=>1 });
        $c->stash->{json} = { success=>\1, config=>$doc->{_kanban} };
    } else {
        $c->stash->{json} = { success=>\1, config=>{} };
    }
    $c->forward('View::JSON');
}

sub children : Local {
    my ($self, $c) = @_;
    my $mid = $c->req->params->{mid};
    my @chi = map { $_->{to_mid} } mdb->master_rel->find({ from_mid=>"$mid", rel_type=>'topic_topic' })->all;
    $c->stash->{json} = { success=>\1, msg=>'', children=>\@chi };
    $c->forward('View::JSON');
}

sub get_category_default_workflow : Local {
    my ( $self, $c ) = @_;

    my $id_category = $c->req->params->{id_category};
    _fail _loc("Missing category_id") unless $id_category;

    try {
        my $id_rule = Baseliner::Model::Topic->new->get_category_default_workflow($id_category);
        $c->stash->{json} =
          { success => \1, data => $id_rule, msg => _loc( 'Default workflow rule for category %1', $id_category ) };
    }
    catch {
        $c->stash->{json} =
          { success => \0, msg => _loc( 'Default workflow rule for category %1 not found', $id_category ) };
    };

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
    my ( $self, $c ) = @_;

    $c->res->content_type('text/html; charset=utf-8');
    return $self->_export($c, 'html');
}

sub report_yaml : Local {
    my ($self, $c ) = @_;

    $c->res->content_type('text/plain; charset=utf-8');
    return $self->_export($c, 'yaml');
}

sub report_csv : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $json = _decode_json $p->{data_json};
    my $data = $json->{rows};

    if ( $p->{params} ) {
        my $params = _decode_json $p->{params};
        $params->{username}   = $c->username;
        $params->{categories} = '' if ( $$params{categories} && !scalar @{ $params->{categories} } );
        $params->{limit}      = $p->{total_rows};

        my $rows = $self->get_items($params);
        $data = $rows->{data};
    }

    my $exporter = Baseliner::Model::TopicExporter->new;
    foreach my $node (@$data) {
        if ( $node->{labels} ) {
            $node->{labels} = join ';',
              grep { defined $_ && length $_ } map { $_ =~ m/\;(.*)\;/; $1 } _array $node->{labels};
        }
    }
    my $body     = $exporter->export(
        'csv', $data,
        username   => $c->username,
        title      => $p->{title},
        params     => $p->{params},
        columns    => $json->{columns},
        rows       => $p->{rows},
        total_rows => $p->{total_rows},
    );
    $c->stash->{serve_body}     = $body;
    $c->stash->{serve_filename} = length $p->{title} ? Util->_name_to_id( $p->{title} ) . '.csv' : 'topics.csv';
    $c->stash->{content_type}   = 'application/csv';
    $c->forward('/serve_file');
}

sub _filter_categories_permissions : Local {
    my $self = shift;
    my (%params) = @_;

    my $filter = _decode_json_safe( $params{categories_filter} );
    my $where = $self->_build_category_filter( categories_id_filter => $params{categories_id_filter}, filter => $filter );

    return mdb->category->find($where)->all;
}

sub _build_category_filter {
    my $self = shift;
    my (%params) = @_;

    my $where;
    my $id_category = join( ",",
        _array $params{categories_id_filter},
        _array $params{filter}->{id_category},
        _array $params{filter}->{category_id},
        _array $params{filter}->{categories} );

    my $name_category = join( ",", _array $params{filter}->{category_name}, _array $params{filter}->{name_category} );

    $where->{id} = mdb->in( split( ",", $id_category ) ) if ($id_category);

    $where->{name} = mdb->in( split( ",", $name_category ) ) if ($name_category);

    return $where;
}

sub _export {
    my $self = shift;
    my ($c, $format) = @_;

    my $p = $c->req->params;

    my $exporter = Baseliner::Model::TopicExporter->new(
        renderer => sub {
            my (%params) = @_;

            my $content = $c->forward( $c->view('Mason'), 'render', [ '/reports/basic.html', \%params ] );
            return $content;
        }
    );

    try {
        my $content = $exporter->export(
            $format, $p->{data_json},
            username   => $c->username,
            title      => $p->{title},
            params     => $p->{params},
            rows       => $p->{rows},
            total_rows => $p->{total_rows},
        );

        if (!Encode::is_utf8($content)) {
            $content = Encode::decode('UTF-8', $content);
        }

        $c->res->body($content);
    } catch {
        my $error = $_;

        $c->res->status(500);
        $c->res->body("Error: $error");
    };
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
        my $broken = $c->path_to('/root/static/images/icons/help.svg')->slurp;
        $c->res->body( $broken );
    }
}

sub change_status : Local {
    my ($self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        my $change_status_before;
        my @results;
        my @statuses = _array( $p->{old_status} );

        for my $mid ( _array( $p->{mid} ) ) {
            my $old_status = shift @statuses;
            my $id_cats = (
                mdb->topic->find_one({ mid=>"$mid" },{ category_status=>1 })
                        or _fail(_loc("Topic #%1 not found. Deleted?", $mid))
            )->{category_status}{id};

            if ($old_status eq $id_cats ){
                $change_status_before = \0;

                my ($isValid, $field_name) = $c->model('Topic')->check_fields_required( mid => $mid, username => $c->username);

                if ($isValid){
                    model->Topic->change_status(
                        change => 1, username => $c->username,
                        id_status => $p->{new_status}, id_old_status => $old_status,
                        mid => $mid,
                    );
                    push @results, { success=>\1, mid=>$mid, msg => _loc('Changed status'), change_status_before=>$change_status_before };
                }else{
                    push @results, { success=>\0, mid=>$mid, msg => _loc('Required field %1 is empty', $field_name) };
                }
            }
            else{
                $change_status_before = \1;
                push @results, { success=>\1, mid=>$mid, msg=>_loc('Changed status'), change_status_before=>$change_status_before };
            }
        }
        @results==1 ? $results[0] : { success=>\1, results=>\@results };
    } catch {
        my $err = shift;
        _error( $err );
        { success=>\0, msg=>$err };
    };
    $c->forward('View::JSON');
}

sub grid_count : Local {
    my ($self,$c)=@_;

    my $p = $c->req->params;

    if( my $lq = $p->{lq} ) {
        if($lq->{'$and'}){
            my $where = Baseliner->model('Topic')->build_where_clause_with_reg_exp($p->{query}, $p->{username}, $p->{id_project});
            $lq->{'$and'} = $where->{'$and'};
        }
        my $cnt = mdb->topic->find($lq)->fields({_id=>1})->count;
        $c->stash->{json} = { count=>$cnt };
    } else {
        $c->stash->{json} = { count=>9999999 };
    }
    $c->forward('View::JSON');
}

sub get_projects_from_release : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $release = ci->new( $p->{mid} );
    my @projects = map { { id => $_->{mid}, name => $_->{name} } }
      $release->related( where => { collection => 'project' }, depth => 2, docs_only => 1 );

    $c->stash->{json} = { projects => \@projects };
    $c->forward('View::JSON');
    return;
}

sub get_files : Local {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;

    my $username = $p->{username} || $c->username;
    my $fields = $p->{field} // 'ALL';
    my $depth = $p->{depth} // 4;
    my $mid = $p->{mid} || _throw _loc('Missing mid');

    my $topic = ci->new($mid);
    my @doc_fields = split /,/, $fields;
    my ($info, @user_topics) = Baseliner->model('Topic')->topics_for_user({ username => $username, query=>$mid, clear_filter => 1});
    my $where = { mid => mdb->in(map {$_->{mid}} @user_topics), collection => 'topic'};

    my @topics = $topic->children( where => $where, depth => $depth );

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
        my $rel_data = $related->get_data;

        for my $field ( _array $cat_fields->{$related->{name_category}} ) {
            if ( _array($rel_data->{$field->{id_field}}) ) {
                my $can_read_field = Baseliner::Model::Permissions->new->user_has_action(
                    $username,
                    'action.topicsfield.read',
                    bounds =>
                      { id_category => $related->{id_category}, id_status => '*', id_field => $field->{id_field} }
                );
                next unless $can_read_field;

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

    my $file_path = $topic_path.'.zip';
    Baseliner::Utils->zip_dir(source_dir=>$topic_path,zipfile=>$file_path);
    _rmpath $topic_path;

    $c->stash->{serve_file} = $file_path;
    $c->stash->{serve_filename} = $mid.'_'.$fields.'.zip';
    $c->forward('/serve_file');
}

sub topic_fieldlet_nodes : Local {
    my ( $self, $c ) = @_;
    my $p            = $c->request->parameters;
    my $id_category  = $p->{id_category};
    my $query        = $p->{query};
    my $default_form = $p->{id_rule};
    my @nodes;

    if ( !$id_category && $default_form ) {
        @nodes = Baseliner::Model::Topic->new->get_fieldlets_from_default_form($default_form);
    }
    else {
        my @fieldlet_nodes = Baseliner::Model::Topic->new->get_fieldlet_nodes($id_category);
        foreach my $fieldlet (@fieldlet_nodes) {
            my $id = $fieldlet->{id_field} || $fieldlet->{id};
            $fieldlet->{fieldlet_name}
                = _array($id_category) == 1
                ? "$fieldlet->{name_field} [$id]"
                : "$fieldlet->{category_name} : $fieldlet->{name_field} [$id]";
            $fieldlet->{id_uniq} = Util->_md5();
            push @nodes, $fieldlet;
        }
        @nodes = Util->query_grep(
            query  => $query,
            fields => [ 'id_field', 'name_field', 'category_name' ],
            rows   => \@nodes
        ) if length $query;
    }

    @nodes = grep { $$_{key} !~ /^fieldlet\.separator/ } @nodes;
    my $total = scalar @nodes;

    $c->stash->{json} = { data => \@nodes, totalCount => $total };
    $c->forward('View::JSON');
}

sub topic_drop : Local {
    my ($self, $c) = @_;

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

                META: for my $fm (@$meta) {
                    my $dt = $fm->{drop_target};
                    next META unless !length($dt) || $dt;# if not defined, it's a drop target; if defined then it depends
                    next META if $$fm{meta_type} !~ /(release)/;
                    next META if !$$fm{editable};
                    # if filter, test if filter matches and avoid later errors
                    next META if !model->Topic->test_field_match( field_meta=>$fm, mids=>$from_mid );

                    $kmatches++;

                    my $id_field = $$fm{id_field};
                    if ( ref $$fm{readonly} eq 'SCALAR' && ${ $$fm{readonly} } ) {
                        $c->stash->{json} = { success => \0, msg=> _loc( 'User %1 does not have permission to drop into field %2', $c->username, _loc( $$fm{name_field} || $$fm{id_field} )) };
                        last META;
                    }

                    my @mids;
                    # single_mode is for backwards compatibility
                    if ( !$fm->{single_mode} && (!$fm->{value_type} || $fm->{value_type} ne 'single')) {
                        push @mids, _array( $$data{$id_field} );
                    }
                    push @mids, $from_mid;

                    # save operation for later
                    push @targets, { id_field=>$id_field, mid=>$to_mid, fm=>$fm, oper=>sub{
                        Baseliner::Model::Topic->new->update(
                            {
                                action    => 'update',
                                topic_mid => $to_mid,
                                $id_field => [@mids],
                                username  => $c->username
                            }
                        );
                        $c->stash->{json} = {
                            success => \1,
                            msg     => _loc(
                                'Topic #%1 added to #%2 in field `%3`', $from_mid,
                                $to_mid, _loc( $fm->{name_field} || $fm->{id_field} )
                            )
                        };
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

sub list_status_changes : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my @status_changes = Baseliner::Model::Topic->new->status_changes( $p->{mid} );

    $c->stash->{json} = { data => \@status_changes };
    $c->forward('View::JSON');
}

sub _build_data_view {
    return Baseliner::DataView::Topic->new;
}

sub timeline_list_status_changes : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;

    my @events = Baseliner::Model::Topic->new->timeline_status_changes( $p->{mid} );

    $c->stash->{json} = { data => \@events };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
