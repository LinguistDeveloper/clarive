package Baseliner::Controller::TopicAdmin;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  
register 'menu.admin.topic' => {
    label    => 'Topics',
    title    => _loc ('Admin Topics'),
    action   => 'action.admin.topics',
    url_comp => '/topicadmin/grid',
    icon     => '/static/images/icons/topic.png',
    tab_icon => '/static/images/icons/topic.png'
};

register 'action.admin.topics' => { name=>'View and Admin topics' };


sub grid : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    $c->stash->{query_id} = $p->{query};
    $c->stash->{can_admin_labels} = $c->model('Permissions')->user_has_action( username=> $c->username, action=>'action.labels.admin' );    
    $c->stash->{template} = '/comp/topic/topic_admin.js';
}

sub update_category : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};
    my $idsstatus = $p->{idsstatus};
    my $type = $p->{type};
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    my $assign_type = sub {
        my ($category) = @_;
        given ($type) {
            when ('R'){
                $category->{is_release} = '1';
                $category->{is_changeset} = '0';                
                return { is_release=>'1', is_changeset=>'0' };
            }
            when ('C'){
                $category->{is_release} = '0';
                $category->{is_changeset} = '1';                
                return { is_release=>'0', is_changeset=>'1' };
            }
            when ('N'){
                $category->{is_release} = '0';
                $category->{is_changeset} = '0';                
                return { is_release=>'0', is_changeset=>'' };
            }            
        }
    };

    given ($action) {
        when ('add') {
            try{
                my $row = mdb->category->find_one({name => $p->{name}});
                if(!$row){
                    my $category = {   
                        id => mdb->seq('category'),
                        name => $p->{name},
                        color => $p->{category_color},
                        statuses => $idsstatus // [], 
                        description => $p->{description} ? $p->{description} : ''
                    };
                    my $iss = $assign_type->($category);
                    mdb->category->insert($category);
                    
                    $c->stash->{json} = { msg=>_loc('Category added'), success=>\1, category_id=>$category->{id} };
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
                my $iss = $assign_type->({});
                mdb->category->update({ id=>"$id_category" }, {
                    '$set' => {
                        name        => $p->{name},
                        color       => $p->{category_color},
                        description => $p->{description},
                        ( $idsstatus ? (statuses=>$idsstatus) : () ),
                        %$iss
                    }
                });
                $c->stash->{json} = { msg=>_loc('Category modified'), success=>\1, category_id=> $id_category };
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error modifying Category: %1', shift()), failure=>\1 };
            }
        }
        when ('delete') {
            my $ids_category = $p->{idscategory};
            try{
                mdb->category->remove({ id=>mdb->in($ids_category) });
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
    my ($dir, $sort, $cnt) = ( @{$p}{qw/dir sort/}, 0 );
    $dir = $dir =~ /desc/i ? -1 : 1;
    $sort ||= 'seq';

    my $row;
    my @rows;
    $row = ci->status->find->sort({ $sort => $dir });
    
    while( my $r = $row->next ) {
         
        push @rows,
          {
            id          => $r->{id_status},
            name        => $r->{name},
            description => $r->{description},
            bl          => $r->{bl},
            seq         => $r->{seq},
            type        => $r->{type},
            frozen      => $r->{frozen} eq '1'?\1:\0,
            readonly    => $r->{readonly} eq '1'?\1:\0,
            ci_update   => $r->{ci_update} eq '1'?\1:\0,
            bind_releases => $r->{bind_releases} eq '1'?\1:\0,
          };
    }  
    $cnt = @rows;
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub update_status : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $action = $p->{action};

    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    given ($action) {
        when ('add') {
            try{
                my $row = ci->status->find_one({name => $p->{name}});
                if(!$row){
                    my $doc = {
                        name          => $p->{name},
                        bind_releases => ($p->{bind_releases} eq 'on' ? '1' : '0'),
                        ci_update     => ($p->{ci_update} eq 'on' ? '1' : '0'),
                        readonly      => ($p->{readonly} eq 'on' ? '1' : '0'),
                        frozen        => ($p->{frozen} eq 'on' ? '1' : '0'),
                        bl            => $p->{bl},
                        description   => $p->{description},
                        type          => $p->{type},
                        seq           => $p->{seq}
                    };
                    my $status = ci->status->new( $doc );
                    $status->save;  # status ids (id_status) are now mids
                    $c->stash->{json} = { msg=>_loc('Status added'), success=>\1, status_id=>$status->mid };
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
                my $status = ci->status->search_ci( id_status=>''.$id_status );
                $status->update(
                    %$p,
                    bind_releases => $p->{bind_releases} eq 'on' ? '1' : '0',
                    ci_update     => $p->{ci_update} eq 'on'     ? '1' : '0',
                    readonly      => $p->{readonly} eq 'on'      ? '1' : '0',
                    frozen        => $p->{frozen} eq 'on'        ? '1' : '0',
                );
                
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
                  
                $$_->delete for ci->status->search_cis( id_status=>mdb->in(@ids_status) );
                
                $c->stash->{json} = { success => \1, msg=>_loc('Statuses deleted') };
            }
            catch{
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Statuses: %1', shift()) };
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
    my @projects = split ",", $p->{projects};
    my $username = $c->username;
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    given ($action) {
        when ('add') {
            try{
                my $row = mdb->label->find_one({name => $p->{label}});
                if(!$row){
                    my $label = { name => $label, color => $color, id=>mdb->seq('label') };
                    $label->{sw_allprojects} = 1;
                    mdb->label->insert($label);
                    $c->stash->{json} = { msg=>_loc('Label added'), success=>\1, label_id=>$label->{id} };
                }
                else{
                    $c->stash->{json} = { msg=>_loc('Label name already exists, introduce another label name'), failure=>\1 };
                }
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding Label: %1', shift()), failure=>\1 }
            }
        }
        when ('update') {  }
        when ('delete') {
            my $ids_label = $p->{idslabel};

            try{
                my @ids_label;
                foreach my $id_label (_array $ids_label){
                    push @ids_label, $id_label;
                }
                  
                mdb->label->remove({ id=>mdb->in(@ids_label) },{ multiple=>1 });
                
                if( @ids_label ) {
                    # errors like "cannot $pull/pullAll..." is due to labels=>N
                    mdb->topic->update({}, { '$pull'=>{ labels=>mdb->in(@ids_label) } },{ multiple=>1 }); # mongo rocks!
                }
                
                $c->stash->{json} = { success => \1, msg=>_loc('Labels deleted') };
            } catch{
                my $err = shift;
                _error( $err );
                $c->stash->{json} = { success => \0, msg=>_loc('Error deleting Labels').': '. $err };
            }
        }
    }
    
    $c->forward('View::JSON');    
}

sub update_category_admin : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_category = $p->{id};
    my $idsroles = $p->{idsroles};
    my $status_from = $p->{status_from};
    my $idsstatus_to = $p->{idsstatus_to};
    my $job_type = $p->{job_type};

    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    
    foreach my $role (_array $idsroles){
        mdb->category->update({ id=>"$id_category" },
            { '$pull'=>{ workflow=>{ id_role=>"$role", id_status_from=>"$status_from", id_status_to=>mdb->in($idsstatus_to) } } },
            { multiple=>1 }
        );
        if($idsstatus_to){
            mdb->category->update({ id=>"$id_category" },
                { '$addToSet'=>{ workflow=>{ 
                    id_role         => $role,
                    id_status_from  => $status_from,
                    job_type        => $job_type,
                    id_status_to    => $_,
            }}},{ multiple=>1 }) for _array( $idsstatus_to );
        }
    }
    $c->stash->{json} = { success => \1, msg=>_loc('Categories admin') };
    $c->forward('View::JSON');    
}

sub list_categories_admin : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $cnt;
    my @rows;

    Baseliner->cache_remove_like( qr/^topic:/ );

    my %role = mdb->role->find_hashed( id=>{},{role=>1,_id=>0});
    my %statuses = ci->status->statuses;
    
    my @cat_wkf = _array( mdb->category->find_one({ id=> "$p->{categoryId}" })->{workflow} );
    my @wkf = 
        sort { 
            # complex sort needed... look into aggregation framework for better sorting on group
            sprintf('%09d%09d%09d', $$a{id_role}, $$a{id_status_from}, $statuses{ $$a{id_status_from} }{seq} )
            <=> 
            sprintf('%09d%09d%09d', $$b{id_role}, $$b{id_status_from}, $statuses{ $$b{id_status_from} }{seq} )
        } @cat_wkf;
        
    my %stat_to;
    push @{ $stat_to{$$_{id_role}}{$$_{is_status_from}} }, $_ for @cat_wkf;

    for my $rec ( @wkf ) {
        my @sts = sort { $statuses{$$a{id_status_from}}<=>$statuses{$$b{id_status_from}} } 
            _array $stat_to{$$rec{id_role}}{$$rec{id_status_from}};
        
        # Grid for workflow configuration: right side field
        my @statuses_to;
        for my $status_to ( @sts ) {
            my $name = $statuses{ $status_to->{id_status_to} }{name};
            # show 
            my $job_type = $status_to->{job_type};
            if( $job_type && $job_type ne 'none' ) {
                $name = sprintf '%s [%s]', $name, lc( _loc($job_type) );
            }
            push @statuses_to,  $name;
        }
        
        push @rows, {
             role           => $role{ $$rec{id_role} }{name},
             status_from    => $statuses{ $$rec{id_status_from} }{name},
             id_category    => $p->{categoryId},
             id_role        => $$rec{id_role},
             id_status_from => $$rec{id_status_from},                         
             statuses_to    => \@statuses_to
         };             
    }
    $cnt = @rows;
    
    $c->stash->{json} = { data=>\@rows, totalCount=>$cnt};
    $c->forward('View::JSON');
}

sub list_tree_fields : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id_category = $p->{id_category};
    my @tree_fields;
    my @system;
    my $system_fields = Baseliner::Model::Topic->get_system_fields();
    
    my @temp_fields = _array( mdb->category->find_one({ id=>"$id_category" })->{fields} );
    my %conf_fields;
    
    for(@temp_fields){
        my $params = $_->{params};
        $conf_fields{$_->{id_field}} = 1 if !exists($params->{hidden});
    }

    my $i = (scalar keys %conf_fields) + 1;
    my @sys_fields = sort { $a->{params}->{field_order} <=> $b->{params}->{field_order} } grep { $_->{params}->{origin} eq 'system' && !exists $conf_fields{$_->{id_field}} } _array $system_fields;
    for ( @sys_fields ){
        push @system,   {
                            id          => $i++,
                            id_field    => $_->{id_field},
                            text        => _loc ($_->{params}->{name_field}),
                            params	    => $_->{params},
                            icon        => '/static/images/icons/lock_small.png',
                            leaf        => \1
                        }
    }
    
    push @tree_fields, {
        id          => 'S',
        text        => _loc('System fields'),
        expanded    => scalar @system gt 0 ? \1 : \0, 
        children    => \@system
    };       
    
    my @custom;
    my @id_fields = map { $_->{id_field} } _array $system_fields;
    
    my @custom_fields = 
        grep {!exists $conf_fields{$$_{id_field}} } 
        grep { $$_{id_field} ~~ @id_fields } 
        map { _array($$_{fields}) } mdb->category->find->all;
        
    my %unique_fields;
    for(@custom_fields){
        if (exists $unique_fields{$_->{id_field}}){
            next;
        }
        else {
            my $params = $_->{params};
            $params->{name_field} = $_->{id_field};
            push @custom,
                {
                  id        => $i++,
                  id_field  => $_->{id_field},
                  text      => $params->{name_field},
                  params	=> $params,
                  icon    => '/static/images/icons/icon_wand.gif',
                  leaf      => \1
                };        
            $unique_fields{$_->{id_field}} = '1';    
        }
    }
    
    push @tree_fields, {
        id          => 'C',
        text        => _loc('Custom fields'),
        expanded    => scalar @custom gt 0 ? \1 : \0,        
        children    => \@custom
    };
    

    my @template_dirs = map { $_->root . '/forms/*.js' } Baseliner->features->list;
    push @template_dirs, map { $_->root . '/fields/templates/js/*.js' } Baseliner->features->list;
    push @template_dirs, map { $_->root . '/fields/system/js/*.js' } Baseliner->features->list;
    
    push @template_dirs, $c->path_to( 'root/fields/templates/js' ) . "/*.js";
    push @template_dirs, $c->path_to( 'root/fields/system/js' ) . "/list*.js";
    push @template_dirs, $c->path_to( 'root/forms' ) . "/*.js";
    #@template_dirs = grep { -d } @template_dirs;
    
    my @tmp_templates = map {
        my $glob = $_;
        my @ret;
        for my $rel_file ( grep { -f } glob "$glob" ) { 
            my $f = _file( $rel_file );
            my $d = $f->slurp;
            my $yaml = Util->_load_yaml_from_comment( $d );
            my $id_form = $f->basename; 
            
            my $metadata;
            my $metadata_base = {
                name => $id_form, 
                params => {
                    origin => 'template',
                    js => $rel_file,
                    type => 'form',
                    #section => 'body',
                }
            };
            if(length $yaml ) {
                _debug( "OK metadata for $f" );
                $metadata = try { _load( $yaml ) } catch { 
                    _error( "KO load yaml metadata for $f" );
                    $metadata_base;
                };    
                if( ref $metadata ne 'HASH' ) {
                    _error( "KO load yaml metadata not HASH for $f" );
                    $metadata = $metadata_base;
                }
            } else {
                _error( "KO metadata for $f" );
                $metadata = $metadata_base;
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

    my @templates;
    for my $template (  sort { $a->{metadata}->{params}->{field_order} <=> $b->{metadata}->{params}->{field_order} }
                        grep { $_->{metadata}->{params}->{origin} eq 'template' && $_->{metadata}->{params}->{type} ne 'form'} @tmp_templates ) {
        if( $template->{metadata}->{name} ){
            $template->{metadata}->{params}->{name_field} = $template->{metadata}->{name};
            push @templates,
                {
                    id          => $i++,
                    id_field    => $template->{metadata}->{name},
                    text        => _loc ($template->{metadata}->{name}),
                    params	    => $template->{metadata}->{params},
                    leaf        => \1                  
                };		
        }
    }

    my $j = 0;
    my @meta_system_listbox;
    my @data_system_listbox;
    for my $system_listbox (  sort { $a->{metadata}->{params}->{field_order} <=> $b->{metadata}->{params}->{field_order} }
                        grep {$_->{metadata}->{params}->{type} eq 'listbox'} @tmp_templates ) {
        
        push @meta_system_listbox, [$j++, _loc $system_listbox->{metadata}->{name}];
        push @data_system_listbox, $system_listbox->{metadata}->{params};
    }
    
    push @templates,    {
                            id          => $i++,
                            id_field    => 'listbox',
                            text        => _loc ('Listbox'),
                            params	    => {origin=> 'template'},
                            meta        => \@meta_system_listbox,
                            data        => \@data_system_listbox,
                            leaf        => \1                             
                        };
    
    #push @tree_fields, {
    #    id          => 'T',
    #    text        => _loc('Templates'),
    #    children    => \@templates
    #};
    
    
    $j = 0;
    my @meta_forms;
    my @data_forms;
    for my $forms (  sort { ( $a->{metadata}{params}{field_order} // -1 ) <=> ( $b->{metadata}{params}{field_order} // -1 ) }
                        grep {$_->{metadata}->{params}->{type} eq 'form'} @tmp_templates ) {
        
        push @meta_forms, [$j++, _loc $forms->{metadata}->{name}];
        push @data_forms, $forms->{metadata}->{params};
    }
    
    push @templates,    {
                            id          => $i++,
                            id_field    => 'form',
                            text        => _loc ('Custom forms'),
                            params	    => {origin=> 'template'},
                            meta        => \@meta_forms,
                            data        => \@data_forms,
                            leaf        => \1                             
                        };
    
    push @tree_fields, {
        id          => 'T',
        text        => _loc('Templates'),
        children    => \@templates
    };      
    
    $c->stash->{json} = \@tree_fields;
    $c->forward('View::JSON');
}

sub update_fields : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_category = $p->{id_category};
    my @ids_field = _array $p->{fields};
    my @values_field = _array $p->{params};
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    
    my $order = 1;
    my $param_field;
    my %visible_system_fields;
    
    my @fields; 
    
    foreach my $field (@ids_field){
        my $params = _decode_json(shift(@values_field));
        
        $visible_system_fields{$field} = 1 if $params->{origin} eq 'system';
        
        $params->{field_order} = $order++;
        $params->{id_field} = $field;
        $params = $self->params_normalize( $params );
    
        push @fields, { id_field=>$field, params=>$params };
    }
    
    my $system_fields = Baseliner::Model::Topic->get_system_fields();
    
    for my $f ( grep { !exists $visible_system_fields{$_->{id_field}} } _array $system_fields){
        my $params = $$f{params};
        $params->{hidden}   = 1 if $params->{origin} eq 'system';
        $params->{id_field} = $$f{id_field};
        $params = $self->params_normalize( $params );
        push @fields, { id_field => $$f{id_field}, params => $params };
    }    
    
    mdb->category->update({ id=>"$id_category" },{ '$set'=>{ fields=>\@fields } });

    $c->stash->{json} = { success => \1, msg=>_loc('fields modified') };
    $c->forward('View::JSON');    
}

sub params_normalize {
    my ($self,$params)=@_;
    # now in mongo we cannot store \1 or \0
    ref $$params{$_} eq 'SCALAR' and $$params{$_}=''.${ $$params{$_} } for keys $params;
    Util->_damn( $params );
    return $params;
}

sub get_conf_fields : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id_category = $p->{id_category};
    
    #Baseliner::Model::Topic->get_update_system_fields ($id_category);
    
    my @conf_fields = 
        grep { !exists $_->{params}->{hidden} && $_->{params}->{origin} ne 'default' }
        map { +{ id_field => $_->{id_field}, params => $_->{params} } }
        _array( mdb->category->find_one({ id=>"$id_category" })->{fields} );
    my @system;
    for ( sort { $a->{params}->{field_order} <=> $b->{params}->{field_order} } @conf_fields){
        push @system,   {
                            id          => $_->{params}->{field_order},
                            id_field    => $_->{id_field},
                            name        => _loc ($_->{params}->{name_field} // $_->{id_field}),
                            params	    => $_->{params},
                            img         => $_->{params}->{origin} eq 'system' ? '/static/images/icons/lock_small.png' : '/static/images/icons/icon_wand.gif',
                            meta => {
                                bd_field    => { read_only => \0 },
                                field_order => { read_only => \0 },
                                filter      => { read_only => \0 },
                                get_method  => { read_only => \0 },
                                set_method  => { read_only => \0 },
                                html        => { read_only => \0 },
                                js          => { read_only => \0 },
                                id_field    => { read_only => \0 },
                                relation    => { read_only => \0 },
                                section     => { value     => [ 'head', 'body', 'details' ] },
                                single_mode => { value     => [ \1, \0 ] },
                                type        => { read_only => \0 },
                                origin      => { read_only => \0 }
                                },
                        }
    }

    $c->stash->{json} = { data=>\@system };
    $c->forward('View::JSON');    
}

sub workflow : Local {
    my ($self,$c, $action) = @_;
    my $p = $c->request->parameters;
    my $cnt=0;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    if( $action eq 'delete' ) {
        try {
            my $up = mdb->category->update({ id=>''.$p->{id} },
                 { '$pull'=>{ workflow=>{ 
                        id_role        => mdb->in($p->{idsroles}),
                        id_status_from => mdb->in($p->{status_from}),
                        id_status_to   => mdb->in($p->{idsstatus}),
                  } } },{ multiple=>1 });
            $cnt = $up->{n};
        } catch {
            $c->stash->{json} = { success => \0, msg=>_loc('Error deleting relationships: %1', shift() ) };
        };
    }
    $c->stash->{json} = { success => \1, msg=>_loc('Relationship deleted: %1', $cnt) };
    $c->forward('View::JSON');    
}

sub create_clone : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try {
        my ($row) = 
            grep { $$_{id_field} eq $$p{name_field} } 
            map { _array($$_{fields}) } 
            mdb->category->find->fields({ fields=>1 })->all;
        if(!$row){
            my $params = _decode_json($p->{params});
            
            $params->{origin} = 'custom';
            $params->{id_field} = $p->{name_field};
            $params->{name_field} = $p->{name_field};

            $params->{rel_field} = $p->{name_field} if exists $params->{rel_field};
            if (exists $params->{filter}) {
                $params->{filter} = $p->{filter};
                $params->{html} = '';  
            }else{
                $params->{html} = '/fields/field_generic.html';                
            }
            
            mdb->category->update({ id =>''.$p->{id_category} },
                { '$push'=>{ fields=>{ id_field=>$p->{name_field}, params=>$params } } }
            );
    
            $c->stash->{json} = { msg=>_loc('Field cloned'), success=>\1 };
        }
        else{
            $c->stash->{json} = { msg=>_loc('Field name already exists, introduce another name'), failure=>\1 };
        }
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error cloning field: %1', shift()), failure=>\1 };
    };

    $c->forward('View::JSON');    
}

sub list_filters : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my @rows;
    my @filters = $c->model('Baseliner::BaliTopicView')->search(undef, {order_by => 'name'})->hashref->all;
    for (@filters){
            push @rows, $_;
    }
    
    $c->stash->{json} = {data=>\@rows};
    $c->forward('View::JSON');
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        my $id_from = $$p{id_category};
        my $cat = mdb->category->find_one({ id=>$id_from },{ _id=>0 });
        if( $cat ){
            my %data = %$cat;
            delete $data{id};
            delete $data{description};
            
            ## category
            my $id_cat = mdb->seq('category');
            my $doc = { %data, id=>$id_cat, name=>$data{name}.'-'.$id_cat };
            mdb->category->insert($doc);
        }
        $c->stash->{json} = { success => \1, msg => _loc("Category duplicated") };  
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error duplicating category') };
    };

    $c->forward('View::JSON');  
}

sub delete_row : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_category = $p->{id_category};
    my $id_role = $p->{id_role};
    my $id_status_from = $p->{id_status_from};    
    
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        mdb->category->update({ id =>"$id_category" },
            { '$pull' => { workflow => { id_role => "$id_role", id_status_from => $id_status_from } } }, { multiple=>1 });
        $c->stash->{json} = { msg=>_loc('Row deleted'), success=>\1 };
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error deleting row: %1', shift()), failure=>\1 }
    };
    
    $c->forward('View::JSON');    
}

sub update_system : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        Baseliner::Model::Topic->get_update_system_fields;
        $c->stash->{json} = { success => \1, msg => _loc("System updated") };  
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error updating system') };
    };
    $c->forward('View::JSON');  
}

sub export : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try{
        $p->{id_category} or _fail( _loc('Missing parameter id') );
        my $export;
        my @cats; 
        my %statuses = ci->status->statuses;
        for my $id (  _array( $p->{id_category} ) ) {
            # TODO prefetch states and workflow
            my $cat = mdb->category->find_one({ id=> "$id" });
            my $statuses = delete $cat->{statuses};
            for my $st ( _array($statuses) ) {
                push @{ $cat->{statuses} }, $statuses{ $st->{id_status} }; 
            }
            _fail _loc('Category not found for id %1', $id) unless $cat;
            push @cats, $cat;
        }
        if( @cats > 1 ) {
            my $yaml = _dump( \@cats );
            utf8::decode( $yaml );
            $c->stash->{json} = { success => \1, yaml=>$yaml };  
        } else {
            my $yaml = _dump( $cats[0] );
            utf8::decode( $yaml );
            $c->stash->{json} = { success => \1, yaml=>$yaml };  
        }
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error exporting: %1', shift()) };
    };
    $c->forward('View::JSON');  
}

sub import : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my @log;
    Baseliner->cache_remove_like( qr/^topic:/ );
    $c->registry->reload_all;
    try{
        mdb->txn( sub{
            my $yaml = $p->{yaml} or _fail _loc('Missing parameter yaml');
            my $import = _load( $yaml );
            $import = [ $import ] unless ref $import eq 'ARRAY';
            for my $data ( _array( $import ) ) {
                next if !defined $data;
                my $is_new;
                my $topic_cat;
                delete $data->{id};
                delete $data->{_id};
                my $statuses = delete $data->{statuses};
                
                # category
                push @log => "----------------| Category: $data->{name} |----------------";
                $topic_cat = mdb->category->find({ name=>$data->{name} })->count;
                $is_new = !$topic_cat;
                if( $is_new ) {
                    $topic_cat = mdb->category->insert( $data );
                    push @log => _loc('Created category %1', $data->{name} );
                } else {
                    $topic_cat = mdb->category->update({ name=>$data->{name} },{ '$set'=>$data });
                    push @log => _loc('Updated category %1', $data->{name} );
                }
               
                # statuses - make sure ci exists
                my @final_statuses;
                for my $status ( _array( $statuses ) ) {
                    next if !defined $status;
                    my $srow = ci->status->find_one({ '$or'=>[ {id_status=>$$status{id_status}}, {name=>$$status{name}} ] });
                    if( !$srow ) {
                        delete $$status{id_status};
                        delete $$status{mid};
                        $srow = ci->status->new( $status );
                        push @log => _loc('Created status %1', $$srow{name} );
                        push @final_statuses, $$srow{id_status};
                    } else { 
                        push @log => _loc('Status %1 found. Statuses are not updated by this import.', $$status{name} );
                        push @log => _loc("Status '%1' included in category", $$status{name} );
                        push @final_statuses, $$status{id_status};
                    }
                }   
                mdb->category->update({ id=>$$topic_cat{id} },{ '$set'=>{ statuses=>\@final_statuses } });

                # TODO workflow ? 
                
                push @log => $is_new 
                    ? _loc('Topic category created with id %1 and name %2:', $topic_cat->id, $topic_cat->name) 
                    : _loc('Topic category %1 updated', $topic_cat->name) ;
            }
        });   # txn_do end
        
        $c->stash->{json} = { success => \1, log=>\@log, msg=>_loc('finished') };  
    }
    catch{
        $c->stash->{json} = { success => \0, log=>\@log, msg => _loc('Error importing: %1', shift()) };
    };
    $c->forward('View::JSON');  
}

1;
