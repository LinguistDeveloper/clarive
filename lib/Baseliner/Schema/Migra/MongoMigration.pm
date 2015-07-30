package Baseliner::Schema::Migra::MongoMigration;
use Moose;
use Baseliner::Utils;
use v5.10;
use Try::Tiny;

sub roles {
    my ($self, $p) = @_;
    my $name_format = $p->{name_format};
    my @roles = sort { $a->{name} cmp $b->{name} } list_roles(name_format=>$name_format );
    return _encode_json { data=>\@roles, totalCount=>scalar(@roles) };
}


sub list_roles {
    my (%p) = @_;
    $p{name_format} //= 'lc';
    my $name_transform = sub {
        my $name = shift;
        return $name if $p{name_format} eq 'full';
        ($name) = $name =~ /^.*::CI::(.*)$/;
        return length($name) ? $name : 'CI' if $p{name_format} eq 'short';
        $name =~ s{::}{}g if $name;
        $name =~ s{([a-z])([A-Z])}{$1_$2}g if $name;
        my $return = $name || 'ci';
        return lc $return;
    };
    my %cl=Class::MOP::get_all_metaclasses;
    map {
        my $role = $_;
        +{
            role => $role,
            name => $name_transform->( $role ),
        }
    } grep /^Baseliner::Role::CI/, keys %cl;
}

sub topic_categories_to_rules {
    mdb->rule->remove({rule_type=>mdb->in('form','fieldlets') });
    my @topic_category = mdb->category->find->all;
    foreach my $topic_category (@topic_category){
        my @fieldlets = _array $topic_category->{fieldlets};
        map {$_->{params}{field_order} = $_->{params}{field_order} // -999999999999} @fieldlets;
        @fieldlets = sort { 0+$a->{params}{field_order} <=> 0+$b->{params}{field_order} } @fieldlets;
        #map { _log "===>". $_->{params}{field_order} } @fieldlets;
        my @fields;
        my $registers = map_registors();
        #_log $registers;
        foreach my $fieldlet (@fieldlets){
            my $f;
            my $attributes;
            my $data;
            next if $fieldlet->{params}->{id_field} eq 'created_on' || $fieldlet->{params}->{id_field} eq 'created_by' || 
                    $fieldlet->{params}->{id_field} eq 'modified_on' || $fieldlet->{params}->{id_field} eq 'modified_by' ||
                    $fieldlet->{params}->{id_field} eq 'category' || $fieldlet->{params}->{id_field} eq 'labels' ||
                    $fieldlet->{params}->{id_field} eq 'include_into' || $fieldlet->{params}->{id_field} eq 'progress' || 
                    $fieldlet->{params}->{id_field} eq 'moniker';
            foreach my $key (keys $fieldlet->{params}){
                if($key eq '_html'){
                    $data->{html} = $fieldlet->{params}->{$key};
                    $fieldlet->{params}->{html} = $fieldlet->{params}->{$key};
                }elsif($key eq 'name_field'){
                    $fieldlet->{params}->{$key} =~ s/\n//;
                    $data->{$key} = $fieldlet->{params}->{$key}; 
                }else{
                    $data->{$key} = $fieldlet->{params}->{$key} unless $key eq 'data' or $key eq 'readonly' or $key eq 'origin';
                }
            }
            #_log $fieldlet;
            my $reg_key;
            if($fieldlet->{params}->{html} && $fieldlet->{params}->{js}){
                $reg_key = $fieldlet->{params}->{html}.$fieldlet->{params}->{js};
            }elsif($fieldlet->{params}->{html} && !$fieldlet->{params}->{js}){
                $reg_key = $fieldlet->{params}->{html};
            }elsif(!$fieldlet->{params}->{html} && $fieldlet->{params}->{js}){
                $reg_key = $fieldlet->{params}->{js};
            }else{
                  _log ">>>>>>>>>>>>>>>>>>>> WARNING MIGRATING FIELD: html and js empty ==> ". _dump $fieldlet ; 
                  next;
            }
            #_log _dump $fieldlet;
            my $icon = Baseliner->model('Registry')->get($registers->{$reg_key})->{icon};

            $data->{allowBlank} = '0' if not $fieldlet->{allowBlank};
            $data->{editable} = '1' if not $fieldlet->{editable};
            $data->{hidden} = '0' if not $fieldlet->{hidden};
            
         
            $attributes->{active} = '1';
            $attributes->{disabled} = \0;
            $attributes->{expanded} = \0;
            $attributes->{icon} = $icon; #;// '/static/images/icons/lock_small.png';
            if($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/row_body.html' and $fieldlet->{params}->{js} eq '/fields/templates/js/textfield.js'){
                if($fieldlet->{params}->{bd_field} eq 'moniker'){
                    $attributes->{key} = 'fieldlet.system.moniker';    
                    $data->{editable} = '1';
                    $data->{hidden} = '0';
                }else{
                    $attributes->{key} = 'fieldlet.text';    
                } 
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/grid_editor.html' && $fieldlet->{params}->{js} eq '/fields/templates/js/milestones.js'){
                $attributes->{key} = 'fieldlet.milestones';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/row_body.html' && $fieldlet->{params}->{js} eq '/fields/templates/js/html_editor.js'){
                $attributes->{key} = 'fieldlet.html_editor';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{bd_field} && $fieldlet->{params}->{html} eq '/fields/templates/html/grid_editor.html' && $fieldlet->{params}->{bd_field} eq 'hitos'){
                $attributes->{key} = 'fieldlet.milestones';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/progress_bar.html' and $fieldlet->{params}->{js} eq '/fields/templates/js/progress_bar.js'){
                if($fieldlet->{params}->{bd_field} eq 'progress'){
                    $attributes->{key} = 'fieldlet.system.progress';    
                }else{
                    $attributes->{key} = 'fieldlet.progressbar';    
                }        
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/templates/html/row_body.html' && !$fieldlet->{params}->{js}){
                if($fieldlet->{params}->{type} eq 'numberfield'){
                    $attributes->{key} = 'fieldlet.number';
                }elsif($fieldlet->{params}->{type} eq 'datefield'){
                    $attributes->{key} = 'fieldlet.datetime';
                }elsif($fieldlet->{params}->{type} eq 'combo'){
                    $attributes->{key} = 'fieldlet.combo';
                }elsif($fieldlet->{params}->{type} eq 'textfield'){
                    $attributes->{key} = 'fieldlet.text';
                }elsif($fieldlet->{params}->{type} eq 'timefield'){
                    $attributes->{key} = 'fieldlet.time';
                }
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/list_topics.html' && !$fieldlet->{params}->{js}){
              $attributes->{key} = 'fieldlet.system.list_topics';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/field_cis.html' && !$fieldlet->{params}->{js}){
                $attributes->{key} = 'fieldlet.system.cis';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/field_topics.html' && !$fieldlet->{params}->{js}){
                $attributes->{key} = 'fieldlet.system.topics';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/field_users.html' && !$fieldlet->{params}->{js}){
                $attributes->{key} = 'fieldlet.system.users';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/field_projects.html' && !$fieldlet->{params}->{js}){
                $attributes->{key} = 'fieldlet.system.projects';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/field_release.html' && !$fieldlet->{params}->{js}){
                $attributes->{key} = 'fieldlet.system.release';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{html} eq '/fields/system/html/field_revisions.html' && !$fieldlet->{params}->{js}){
                $attributes->{key} = 'fieldlet.system.revisions';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/dbl_row_body.html' && $fieldlet->{params}->{js} eq '/fields/templates/js/html_editor.js'){
                if($fieldlet->{params}->{bd_field} eq 'description'){
                    $attributes->{key} = 'fieldlet.system.description';
                }else{
                    $attributes->{key} = 'fieldlet.html_editor';
                }
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/dbl_row_body.html' and $fieldlet->{params}->{js} eq '/fields/templates/js/textfield.js'){
              $attributes->{key} = 'fieldlet.text';
            }elsif($fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{html} eq '/fields/templates/html/ci_grid.html' && $fieldlet->{params}->{js} eq '/fields/system/js/list_ci.js'){
                $attributes->{key} = 'fieldlet.ci_grid';
            }elsif(!$fieldlet->{params}->{html} && $fieldlet->{params}->{js} && $fieldlet->{params}->{js} eq '/fields/system/js/list_topics.js'){
                $attributes->{key} = 'fieldlet.system.topics';
            }else{
                $attributes->{key} = $registers->{$reg_key};
            }
            if($attributes->{key} eq 'fieldlet.ci_grid' or $attributes->{key} eq 'fieldlet.system.cis'){
                if ($data->{ci_class}){
                    $data->{ci_role} = 'Baseliner::Role::CI';
                    my @ar = split (',', $data->{ci_class});
                    $data->{ci_class_box} = \@ar;
                }
                if($data->{ci_role}){
                    my @elems = split ',', $data->{ci_role};
                    my @ret;
                    my $b = _decode_json(roles(''))->{data};
                    for my $name (@elems){
                        map{ push @ret, $_->{name} if $_->{role} =~ /Baseliner::Role::.*::$name/} _array $b;
                    }
                    $data->{var_ci_role} = \@ret;
                }          
            }
            
            $data->{default_value} = 'off' if not $fieldlet->{default_value} and $attributes->{key} eq 'fieldlet.checkbox';
            $data->{default_value} = $fieldlet->{params}->{default_value} if not $fieldlet->{params}->{default_value} and $attributes->{key} eq 'fieldlet.system.projects';
            $data->{fieldletType} = $attributes->{key};
            
            if ($data->{fieldletType} eq '1') { _warn ">>>>>>>>>>>>>>>>>>>> WARNING MIGRATING FIELD ==> $data->{name_field} WITH CATEGORY $topic_category->{name} "; _log $data }
            
            $attributes->{data} = $data;
            
            $attributes->{leaf} = \1;
            $attributes->{name} = $fieldlet->{params}->{name_field};
            $attributes->{palette} = \0;
            $attributes->{text} = $fieldlet->{params}->{name_field};
            $attributes->{ts} = mdb->ts;
            $attributes->{who} = 'root';
              $f->{attributes} = $attributes;
            $f->{children} = [];
            push @fields, $f;    
        }
        my $rule;
        $rule->{id} = mdb->seq('rule');
        $rule->{detected_errors} = '';
        $rule->{authtype} = 'required';
        $rule->{rule_active} = '1';
        $rule->{rule_desc} = '';
        $rule->{rule_event} = '';
        $rule->{rule_name} = $topic_category->{name};
        $rule->{rule_sec} = mdb->seq('rule_seq');
        $rule->{rule_tree} = _encode_json(\@fields);
        $rule->{rule_type} = 'form';
        $rule->{rule_when} = 'post-offline';
        $rule->{subtype} = '-';
        $rule->{ts} = mdb->ts;
        $rule->{username} = 'root';
        $rule->{wsdl} = '';
        #map{_log _dump $_->{attributes}->{key}}_array _decode_json($rule->{rule_tree});
        #_decode_json($rule->{rule_tree});
        #_log "LA REGLA "._dump $rule;
        mdb->rule->insert($rule);
        mdb->category->update({ id=>"$topic_category->{id}" },{ '$set' => { default_field=>"$rule->{id}"} });
        _warn "GENERANDO DSL DE CATEGORIA: ".$topic_category->{name}; 
        generate_dsl($rule);
    }
}

sub generate_dsl {
    my ($rule) = @_;
    my ( $detected_errors, $returned_ts, $error_checking_dsl ) =
      Baseliner::Controller::Rule->local_stmts_save(
        {
            username => 'root',
            id_rule  => $rule->{id},
            stmts    => $rule->{rule_tree},
            old_ts   => $rule->{ts}
        }
      );
    my $old_ts        = $returned_ts->{old_ts};
    my $actual_ts     = $returned_ts->{actual_ts};
    my $previous_user = $returned_ts->{previous_user};
    my $msg;
    if ( $returned_ts->{old_ts} ne '' ) {
        my ($short_errors) = $detected_errors =~ m/^([^\n]+)/s;
        my $rule_type = mdb->rule->find_one( { id => "$rule->{id}" } );
        if ( $rule_type->{rule_type} eq 'form' ) {
            cache->remove_like(qr/^topic:/);
            cache->remove_like(qr/^roles:/);
            cache->remove( { d => "topic:meta" } );
            Baseliner->registry->reload_all;
        }
        $msg =
          $detected_errors
          ? _loc( 'Rule statements saved with errors: %1', $short_errors )
          : _loc('Rule statements saved ok');
    }
    return $msg;
}
    
sub map_registors {
    my @categories  = mdb->category->find->all;
    my $find_directos;
    my $find_propios;
    map {
        my $cat = $_;
        map {
            if ($_->{params}->{html} and $_->{params}->{js}){
                $find_propios->{ $_->{params}->{html} . $_->{params}->{js} } = '1';
                if($_->{params}->{html} eq '/fields/templates/html/ucm_files.html' and $_->{params}->{js} eq '/fields/templates/js/ucm_files.js'){
                    #_log "LA CATEGORIA ES "._dump $cat;
                }
            }elsif($_->{params}->{html} and not $_->{params}->{js}){
                $find_propios->{ $_->{params}->{html}} = '1';
                if($_->{params}->{html} eq '/fields/templates/html/row_body.html' ){
                    #_log "LA CATEGORIA ES "._dump $cat;
                }
            }elsif(not $_->{params}->{html} and $_->{params}->{js}){
                $find_propios->{ $_->{params}->{js} } = '1';
                if($_->{params}->{js} eq '/fields/system/js/field_category.js'){
                    #_log "LA CATEGORIA ES "._dump $cat;
                }
            }      
          } _array $_->{fieldlets}
    } @categories;
    
    my @reg_fieldlets = Baseliner->registry->starts_with('fieldlet');
    map {
        my $reg = Baseliner->model('registry')->get($_);
        
        #if ( $reg->{registry_node}->{key} =~ /.*required.*/ ) {
            
        #}else {
            my $unique_key;
           # _log "==>".$reg->{registry_node}->{param}->{html}."===>".$reg->{registry_node}->{param}->{js};
            if($reg->{registry_node}->{param}->{html} and $reg->{registry_node}->{param}->{js}){
                if($reg->{registry_node}->{param}->{html} eq '/fields/templates/html/status_chart_pie.html' 
                    and $find_propios->{'/fields/templates/html/status_chart_pie.html'} ){     
                    $unique_key = '/fields/templates/html/status_chart_pie.html';
                }else{
                    $unique_key = $reg->{registry_node}->{param}->{html} . $reg->{registry_node}->{param}->{js};
                }
            }elsif($reg->{registry_node}->{param}->{html} && !$reg->{registry_node}->{param}->{js}){
                $unique_key = $reg->{registry_node}->{param}->{html};
            }elsif(not $reg->{registry_node}->{param}->{html} and $reg->{registry_node}->{param}->{js}){
                $unique_key = $reg->{registry_node}->{param}->{js};
            }
            $unique_key = $unique_key // '';
            if($unique_key && $find_propios->{$unique_key}){
                $find_propios->{$unique_key} = $reg->{registry_node}->{key};
            }
       # }
    } @reg_fieldlets;
    return $find_propios;
}

sub activity_to_status_changes {
    use Array::Utils qw(:all);

    my $rs = mdb->activity->find({ event_key => 'event.topic.create'})->sort({ ts => 1 });
    my $total = $rs->count;
    my $cont = 1;
    my %st = ();
    my %initials = map {$_->{id_status} => _name_to_id($_->{name})} ci->status->find({ type => 'I'})->all;
    my @initial_ids = sort keys %initials;

    my %cat_initial = map {
        my @statuses = _array($_->{statuses});
        my @commons = intersect(@initial_ids,@statuses);
        $_->{name} =>  $commons[0] || $initial_ids[0];
    } mdb->category->find->fields({statuses => 1, name => 1})->all;

    my %category_names = map { $_->{id} => $_->{name}} mdb->category->find({})->all;

    while ( my $act = $rs->next() ) {
      my $status_changes = {};
      my $doc = mdb->topic->find_one({ mid => "$act->{mid}"});
      _debug "Doc $act->{mid} skipped. Probably deleted" if !$doc;
      next if !$doc;
      my $category_name = $category_names{$doc->{category}->{id}};
      next if !$category_name;
      #_log $initials{$cat_initial{$category_name}};
      my $new_status = $initials{$cat_initial{$category_name}};
      $new_status = $initials{$initial_ids[0]} if !$new_status;
      $st{$act->{mid}} = $initials{$cat_initial{$category_name}};
      $status_changes->{$initials{$cat_initial{$category_name}}}->{count} = 1;
      $status_changes->{$initials{$cat_initial{$category_name}}}->{total_time} = 0;
      $status_changes->{transitions} = [{ from => '', to => $cat_initial{$category_name}, ts => $act->{ts} }];
      $status_changes->{last_transition} = { from => '', to => $cat_initial{$category_name}, ts => $act->{ts} };
      mdb->topic->update({ mid => "$act->{mid}"},{ '$set' => { '_status_changes' => $status_changes} });
      if ( ($cont % 100) == 0 ) {
        _log "Creation: Updated $cont/$total";
      }
      $cont++;
    }  
    _log "Creation: Updated $cont/$total";  

    $rs = mdb->activity->find({ event_key => 'event.topic.change_status'})->sort({ ts => 1 });
    $total = $rs->count;
    $cont = 1;

    while ( my $act = $rs->next() ) {
      my $doc = mdb->topic->find_one({ mid => "$act->{mid}"});
      my $status_changes = $doc->{_status_changes} // {};
      _debug "Doc $act->{mid} skipped. Probably deleted" if !$doc;
      next if !$doc;

      if ( $status_changes->{$st{$act->{mid}}} ) {
        my $last = Class::Date->new($status_changes->{last_transition}->{ts});
        my $ts = Class::Date->new($act->{ts});
        my $rel =  $ts - $last;
        $status_changes->{$st{$act->{mid}}}->{total_time} = $status_changes->{$st{$act->{mid}}}->{total_time} + $rel->second;
      }

      if ( $status_changes->{_name_to_id($act->{vars}->{status})} ) {
        $status_changes->{_name_to_id($act->{vars}->{status})}->{count} = $status_changes->{_name_to_id($act->{vars}->{status})}->{count} + 1;
      } else {
        $status_changes->{_name_to_id($act->{vars}->{status})}->{count} = 1;
        $status_changes->{_name_to_id($act->{vars}->{status})}->{total_time} = 0;
      }
      my @transitions = _array($status_changes->{transitions});
      push @transitions, { to => _name_to_id($act->{vars}->{status}), from => $st{$act->{mid}}, ts => $act->{ts} };
      $status_changes->{transitions} = \@transitions;
      $status_changes->{last_transition} = { to => _name_to_id($act->{vars}->{status}), from => $st{$act->{mid}}, ts => $act->{ts} };

      mdb->topic->update({ mid => "$act->{mid}"},{ '$set' => { '_status_changes' => $status_changes} });
      $st{$act->{mid}} = _name_to_id($act->{vars}->{status});
      if ( ($cont % 100) == 0 ) {
        _log "Status changes: Updated $cont/$total";
      }
      $cont++;  
    }
    _log "Status changes: Updated $cont/$total";
}

sub closed_date {
    my @close_status = map { $_->{name} } ci->status->find({ type => qr/^F/ })->all;
    my $act = mdb->activity->find({ event_key => 'event.topic.change_status', 'vars.status' => mdb->in(@close_status)})->sort({ts => 1});
    my $tot = $act->count;
    my $cont = 0;

    while ( my $event = $act->next() ) {
        mdb->topic->update({mid=>$event->{mid}},{'$set'=>{ closed_on => $event->{ts}}});
        if ( $cont%100 == 0 ) {
            _log "Updated $cont/$tot";
        }
        $cont++;
    }
    _log "Updated $cont/$tot";
}

sub drop_all {
    say "Dropping Grid data for this DB...";
    mdb->grid->drop;
    say "Dropping DB...";
    mdb->db->drop;
}

sub cleanup {
    my ($self,%p) = @_;
    # bad inserts probably
    mdb->master->remove({ mid=>undef }); 
}

sub current {
    my ($self,%p) = @_;
    $self->run( tables=>[qw(bali_master)], no_assets=>1 );
    Baseliner->model('Topic')->migrate_docs();
}

sub run {
    my ($self,%p) = @_;
    $p{drop} //= 0;  # indicate if we should drop before inserting
    $self->drop_all if $p{drop_all};
    require Tie::IxHash;
    tie( my %ff, 'Tie::IxHash',
        bali_master       => 'master',
        bali_master_cal   => 'master_cal',
        # bali_master_kv    => 'master_kv',  # needed?
        bali_master_prefs => 'master_prefs',
        bali_master_rel   => 'master_rel',

        bali_topic_status              => 'status',
        bali_topic_categories          => 'category',
        bali_topic_categories_status   => 'category_status',
        bali_topic_categories_admin    => 'workflow',
        bali_topic_categories_priority => 'category_priority',
        bali_topic_fields_category     => 'field',
        bali_topic_priority            => 'priority',
        bali_topic_view                => 'view',

        bali_calendar        => 'calendar',
        bali_calendar_window => 'calendar_window',
        bali_config          => 'config',
        bali_daemon          => 'daemon',
        bali_dashboard       => 'dashboard',
        bali_dashboard_role  => 'dashboard_role',
        bali_event           => { coll=>'event', seq=>1 },
        bali_event_rules     => { coll=>'event_log', seq=>1, capped=>1, size=>(1024*1024*50), max=>1000 },
        bali_job             => 'job',
        bali_log             => 'job_log',
        # bali_job_items       => 'job_items',
        bali_label           => 'label',
        bali_label_project   => 'label_project',

        bali_message                   => 'message',
        bali_message_queue             => { coll=>'message_queue', capped=>1, size=>(1024*1024*50), max=>( 1024*1024 ) },
        bali_notification              => 'notification',
        bali_post                      => 'post',
        bali_project                   => 'project',
        bali_project_directories       => 'project_directories',
        bali_project_directories_files => 'project_directories_files',

        bali_request        => 'request',
        bali_role           => 'role',
        bali_roleaction     => 'role_action',
        bali_roleuser       => 'role_user',
        bali_rule           => 'rule',
        #  bali_rule_statement => 'rule_statement', deprecated
        bali_scheduler      => 'scheduler',
        bali_sem            => 'sem',
        bali_sem_queue      => 'sem_queue',
        bali_sysoutdds      => 'sysoutdds',
        bali_user           => 'user',
        
        #  bali_topic_image               => 'image',              # convert to asset
        # bali_file_version    => 'file_version',                  # asset
        # bali_job_stash       => 'job_stash',                     # asset
        # bali_log             => 'log',                           # asset
        # bali_log_data        => 'log_data',                      # asset
        # bali_repo           => 'repo',                           # not migrated
        # bali_topic_fields_custom       => 'custom_fields',       # not needed, incorporated into topic
        # bali_repokeys       => 'repokeys',                       # what?
    );
    my ($ok,$nok)=(0,0);
    say "Database name: " . mdb->db->name;
    # migrate tables
    my $db = Util->_dbis;
    my %tables = map { $_=>1 } _array($p{tables}) ;
    my @tables_processed;
    for my $table ( grep { $p{tables} ? exists $tables{$_} : 1 } keys %ff ) {
       my $collname = $ff{$table};
       if( ref $collname ) {
           my $coll = $collname->{coll};
           mdb->collection( $coll )->drop if $p{drop};  # drop before creating capped collection
           mdb->db->run_command([ create=> $collname, capped=>boolean::true, size=>$collname->{size}, max=>$collname->{max} ])
                if( $collname->{capped} );
           # seq initialize to table or to mdb if exists. In drop mode, use DB top value
           if( $collname->{seq} ) {
               my $db_curr = $db->query(sprintf q{select max(id) from %s}, $table)->array->[0] + 1;
               my $mdb_curr = mdb->seq( $coll );
               my $seq_value = ($db_curr > $mdb_curr) || $p{drop} ? $db_curr : $mdb_curr;
               mdb->seq( $coll, "$seq_value" );
               say "SEQ $coll created with value=$seq_value";
           }
           $collname = $coll;
       } else {
           mdb->collection($collname)->drop;
       }
       push @tables_processed, $table;
       print sprintf "Dumping table %32s --> %-27s", $table,$collname;
       my $coll = mdb->collection( $collname );
       my $sch_ok = $ok;
       my $sch_nok = $nok;
       $self->each( $table, sub{
           my $r = shift;
           try { $coll->insert( $r ); $ok++ }
           catch { warn "\nERROR: $table: ".shift(); $nok++ }
       });
       say sprintf 'OK: %6s, NOK: %6s' , ( $ok - $sch_ok ) , ( $nok - $sch_nok );
    }
    say "OK=$ok - NOK=$nok";
    $self->assets( %tables ) unless $p{no_assets};
    $self->convert_schemas( %tables ) unless $p{no_convert};  
    mdb->index_all;
}

sub convert_schemas {
    my ($self,%tables) = @_;
    
    say "Converting schemas for tables: " . join keys %tables;

    if( !%tables || exists $tables{bali_user} ) {
        say "Converting schema user...";
        my %users = map { $_->{mid}=>$_ } mdb->user->find->all;
    }

    # label
    if( !%tables || exists $tables{bali_label} ) {
        say "Converting schema label...";
        # mdb->label->find->each(sub{
        #     my $lab = $_;
        #     my $uid = delete $lab->{mid_user};
        #     $lab->{
    }
    
    # master_rel dups
    my $rs = mdb->master_rel->find;
    my %rel_index;
    my $dup=0;
    print "Removing duplicates from master_rel...";
    while( my $r = $rs->next ) {
        my $key = join'|', @{$r}{qw(from_mid to_mid rel_field rel_type)};
        if( exists $rel_index{ $key } ) {
            say "Removing duplicate master_rel: " . $key;
            mdb->master_rel->remove( $r );
            $dup++;
        }
        $rel_index{ $key } = 1;
    }
    say "duplicates found: $dup";
    
    # master_doc
    if( !%tables || exists $tables{bali_master} ) {
        say "Converting master yaml to docs in master_doc...";
        mdb->master_doc->drop;
        $self->each('bali_master', sub{
            my $r = shift;
            #my $doc = Util->_load( delete $r->{yaml} ) // {};
            my $doc = try { ci->new( $r->{mid} ) } catch { undef };
            return unless $doc;
            $doc = { %$doc, %$r }; # merge yaml with master row, so that doc has all attributes for searching
            Util->_unbless( $doc );
            delete $doc->{yaml};
            $doc->{mid} = "$r->{mid}";
            mdb->clean_doc( $doc );
            mdb->master_doc->insert( $doc );
        });
    }
    
    # sequences
    if( !%tables || exists $tables{bali_master_seq} ) {
        mdb->master_seq->drop; 
        my $db = Util->_dbis;
        my $max_mid = $db->query('select max(mid) from bali_master')->array->[0];
        require List::Util;
        my $max_mid_mdb = List::Util::max(map { $_->{mid} } mdb->master_doc->find->fields({ mid=>1 })->all );
        mdb->seq('mid', ($max_mid_mdb > $max_mid ? $max_mid_mdb : $max_mid)+1 );
    }
    
    # topic
    if( !%tables || exists $tables{bali_topic} ) {
        print "Migrating bali_topic...";
        my $k = 0;
        mdb->topic->drop;
        my $coll = mdb->topic;
        $self->each('bali_topic', sub{
           my $r = shift;
           $self->topic( coll=>$coll, row=>$r );
           $k++;
        });
        say "$k rows migrated.";
    }
    
    # repository 
    #   migrate Repository saved.repl into mdb->repl
    #   migrate mvs.queue? no, not needed
    if( !%tables || exists $tables{bali_repo} ) {
        mdb->repl->drop;
        $self->each('bali_repo', sub{
           my $r = shift;
           return unless $r->{ns} =~ /repl/;
           my $t = $r->{ns};
           $t =~ s{^.*/(.*)$}{$1}g;
           #say $t;
           #say _dump $r;
           my $d = Util->_load($r->{data});
           #say _dump $d;
           my $doc = { %$d, text=>$t };
           mdb->repl->insert( $doc );
        });
        mdb->repo->drop; # in case it exists
    }
    
    say 'Done converting.';
}

sub assets {
    my ($self,%tables) = @_;
    
    say "Migrating assets for tables " . join ',', keys %tables;

    # log
    if( !%tables || exists $tables{bali_log} ) {
        my $k=0;
        print "Migrating log assets..."; 
        mdb->log->drop;
        mdb->grid->remove({ parent_collection=>'log' });
        my %not_found;
        $self->each('bali_log', sub{
            my $r = shift;
            my $d = delete $r->{data};
            my $job = mdb->job->find_one({ id=>$r->{id_job} });
            if( !$job ) {
                $not_found{ $r->{id_job} } ++;
                #warn "ERROR: job $r->{id_job} not found for log id $r->{id}. Row ignored.";
                return;
            }
            my $mid = $job->{mid};
            my $ass = mdb->asset( $d, filename=>$r->{data_name}//'', parent_collection=>'log', parent_mid=>$mid );
            $ass->insert;
            $r->{data} = $ass->id;
            mdb->job_log->insert( $r );
            $k++;
            print "$k..." if ! $k % 1000;
        });
        say "$k rows migrated.";
        say "id_job not found: " . join ', ', map { "$_ (" . $not_found{$_} . ")" } keys %not_found if %not_found;
    }
    
    # log_data
    if( !%tables || exists $tables{bali_log_data} ) {
        my $k=0;
        print "Migrating log_data assets..."; 
        mdb->log_data->drop;
        mdb->grid->remove({ parent_collection=>'log_data' });
        $self->each('bali_log_data', sub{
            my $r = shift;
            my $d = delete $r->{data};
            my $job = mdb->job->find_one({ id=>$r->{id_job} });
            if( !$job ) {
                warn "ERROR: job $r->{id_job} not found for log_data id $r->{id}. Row ignored.";
                return;
            }
            my $mid = $job->{mid};
            my $ass = mdb->asset( $d, filename=>$r->{name}//'', parent_collection=>'log_data', parent_mid=>$mid );
            $ass->insert;
            $r->{data} = $ass->id;
            mdb->log_data->insert( $r );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    # job_stash
    if( !%tables || exists $tables{bali_job_stash} ) {
        my $k = 0;
        print "Migrating job_stash assets..."; 
        mdb->job_stash->drop;
        mdb->grid->remove({ parent_collection=>'job' });
        $self->each('bali_job_stash', sub{
            my $r = shift;
            my $d = delete $r->{stash};
            my $job = mdb->job->find_one({ id=>$r->{id_job} });
            if( !$job ) {
                warn "ERROR: job $r->{id_job} not found for stash id $r->{id}. Row ignored.";
                return;
            }
            my $ass = mdb->asset( $d, parent_collection=>'job', parent_mid=>$job->{mid}  );
            $ass->insert;
            $job->{stash} = $ass->id;
            mdb->job->save( $job );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    # file_version 
    if( !%tables || exists $tables{bali_file_version} ) {
        my $k=0;
        print "Migrating file_version assets...";
        mdb->file_version->drop;
        mdb->grid->remove({ parent_collection=>'file_version' });
        $self->each('bali_file_version', sub{
            my $r = shift;
            my $d = delete $r->{filedata};
            my $ass = mdb->asset( $d, filename=>$r->{filename}, parent_collection=>'file_version', parent_mid=>$r->{mid} );
            $ass->insert;
            $r->{filedata} = $ass->id;
            mdb->file_version->insert( $r );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    # topic_image
    if( !%tables || exists $tables{bali_topic_image} ) {
        my $k=0;
        print "Migrating topic_image assets...";
        mdb->topic_image->drop;
        $self->each('bali_topic_image', sub{
            my $r = shift;
            my $d = delete $r->{img_data};
            $r->{mid} //= $r->{topic_mid};
            my $ass = mdb->asset( $d, parent_collection=>'topic_image', parent_mid=>$r->{topic_mid} );
            $ass->insert;
            $r->{img_data} = $ass->id;
            mdb->topic_image->insert( $r );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    say 'Done migrating assets.';
}

sub each {
    my ($self, $table, $code) = @_;
    my $db = Util->_dbis;
    my $rs = $db->query( sprintf 'SELECT * FROM %s', $table );
    while( my $row = $rs->hash ) {
        $code->( $row ); 
    }
}

sub topic_security {
    my ( $self, %p ) = @_;
    for my $doc ( mdb->topic->find->all ) {
        my $meta = Baseliner->model('Topic')->get_meta( $doc->{mid} );
        die "Meta not found for $doc->{mid}" unless $meta;
        warn "Updating topic security for $doc->{mid}\n";
        my $sec = Baseliner->model('Topic')->update_project_security($meta,$doc,$doc);
        warn _dump($sec);
        mdb->topic->save( $doc );
    }
}

sub topic_labels {
    my ( $self, %p ) = @_;
    
    my $db = Util->_dbis();
    
    # bali_topic_label
    my %tlabels;
    map { push @{ $tlabels{$_->{id_topic}} }, $_->{id_label} } $db->query('select * from bali_topic_label')->hashes;
    
    for my $mid ( keys %tlabels ) {
        mdb->topic->update({ mid=>"$mid" },{ '$set'=>{ labels=>$tlabels{$mid} } });
    }
    
    # bali_label
    mdb->label->drop;
    mdb->label->insert($_) for $db->query('select * from bali_label')->hashes;
}

sub topic_status {
    my ( $self, %p ) = @_;
    for my $row ( DB->BaliTopic->search->hashref->all ) {
        warn "Updating status for topic #" . $row->{mid} . "\n";
        Baseliner->model('Topic')->update_category( $row->{mid}, $row->{id_category} ); 
        Baseliner->model('Topic')->update_category_status( $row->{mid}, $row->{id_category_status} );
    }
}

sub job_status_fix {
    # fix CIs that do not have its job_status correct due to old changes directed to BaliJob, now everything goes through CI
    DB->BaliJob->search->each(sub{
       my $r = shift;
       my $ci = ci->new( ns=>'job/' . $r->id );
       if( $ci ) {
           $ci->status( $r->status );
           $ci->step( $r->step );
           $ci->save;
       }
    });
}
    
sub topic_numify {
    my ( $self, %p ) = @_;
    for my $doc ( mdb->topic->find->all ) {
    }
}

sub rules {
    my ($self)=@_;
    my $db = Util->_dbis();
    

    # MASTER
    my @rules = $db->query('select * from bali_rule order by id')->hashes;
    mdb->rule->drop;
    my ($maxseq,$maxid) = (0,0);
    for my $rule ( @rules ) {
        my $id = $rule->{id};
        $rule->{rule_active} .= '';
        $rule->{rule_seq} = 0+ $rule->{rule_seq};
        $maxseq = $rule->{rule_seq} if $rule->{rule_seq} > $maxseq;
        $maxid = $rule->{id} if $rule->{id} > $maxid;
        $rule->{id} .='';
        mdb->rule->insert($rule);        
        if( !length $rule->{rule_tree} ) {
            _warn( "RULE TREE missing for $id, Open them in Rule editor, then save again." );
            # no json rule_tree, look for legacy data
            my $build_tree;
            $build_tree = sub {
                my( $id_rule, $parent )=@_;
                my @tree;
                my $par = length $parent ? ' and id_parent=? ' : ' and id_parent is null';
                my @rows = $db->query('select * from bali_rule_statement where id_rule=? '.$par.' order by id', $id_rule, ($parent // () ))->hashes;
                for my $row ( @rows ) {
                              
                    my $n = { text=>$row->{stmt_text} };
                    $row->{stmt_attr} = _load( $row->{stmt_attr} );
                    $n = { active=>1, %$n, %{ $row->{stmt_attr} } } if length $row->{stmt_attr};
                    delete $n->{disabled};
                    delete $n->{id};
                    $n->{active} //= 1;
                    $n->{disabled} = $n->{active} ? \0 : \1;
                    my @chi = $build_tree->( $id_rule, $row->{id} );
                    if(  @chi ) {
                        $n->{children} = \@chi;
                        $n->{leaf} = \0;
                        $n->{expanded} = $n->{expanded} eq 'false' ? \0 : \1;
                    } elsif( ! ${$n->{leaf} // \1} ) {  # may be a folder with no children
                        $n->{children} = []; 
                        $n->{expanded} = $n->{expanded} eq 'false' ? \0 : \1;
                    }
                    delete $n->{loader};  
                    delete $n->{isTarget};  # otherwise you cannot drag-drop around a node
                    #_log $n;
                    push @tree, $n;
                }
                return @tree;
            };
            my @tree = $build_tree->($rule->{id},undef);
            mdb->rule->update({ id=>$rule->{id} }, { '$set'=>{ rule_tree=>Util->_encode_json(\@tree) } });
        }
    }
    
    mdb->seq('rule',$maxid+1);
    mdb->seq('rule_seq',$maxseq+1);
}

sub message_queue {
    mdb->message->drop;
    for my $msg ( DB->BaliMessage->all ) {
       my @q = map { delete $_->{id_message}; delete $_->{id}; $_ }  
              $msg->bali_message_queues->hashref->all;
       my $doc = +{ $msg->get_columns };
       delete $doc->{id};
       $doc->{queue} = \@q;
       
       mdb->message->insert( $doc );   
    }
}

sub scheduler {
    my @sch = _dbis->query('select * from bali_scheduler')->hashes;
    mdb->scheduler->drop;
    mdb->scheduler->insert($_) for map { delete $_->{id}; $_ } @sch;
}

sub posts {
    my $db = _dbis;
    my %post = map { $_->{mid} => $_ } $db->query('select * from bali_post')->hashes;
    my %rels = map { $$_{to_mid} => $$_{from_mid} }    # post => parent topic
        _dbis->query('select * from bali_master_rel where rel_type=?', 'topic_post')->hashes;
    my $rs = $db->query('select * from bali_post');
    while( my $post = $rs->hash ) {
        # if we find a post for this mid, delete it and create it again
        if( ci->post->find({ mid=>"$$post{mid}" })->count ) {
            say "Post replace existing MID== $$post{mid} " ;
            ci->delete( $$post{mid} );
        }
        my $ci = ci->post->new({
                mid          => $$post{mid},
                content_type => $$post{content_type},
                created_on   => $$post{created_on},
                created_by   => $$post{created_by},
                modified_on  => $$post{created_on},
                ts           => $$post{created_on},
        });
        $ci->topic( ci->new($rels{$$post{mid}}) ) if length $rels{$$post{mid}};
        $ci->put_data( $$post{text} );
        $ci->save;
        say "Saved Post $$post{mid}";
    }
}

sub config {
    my @config = _dbis->query('select * from bali_config')->hashes;
    for my $doc ( @config ) {
        delete $doc->{id};
        mdb->config->insert($doc);
    }
}

sub notifications {
    my @notifs = _dbis->query('select * from bali_notification')->hashes;
    require Baseliner::Model::Notification;
    for my $doc ( @notifs ) {
        delete $doc->{id};
        $doc->{data} = Baseliner::Model::Notification->decode_data( $doc->{data});
        mdb->notification->insert($doc);
    }
}

sub dashboards {
    my @dashes = _dbis->query('select * from bali_dashboard')->hashes;
    for my $dash ( @dashes ) {
        my @roles_in_mongo;
        my @roles_in_oracle = _dbis->query('select * from bali_dashboard_role')->hashes;
        foreach my $role (@roles_in_oracle){
            if($role->{id_dashboard} eq $dash->{id}){
                push @roles_in_mongo, $role->{id_role};
            }
        }
        delete $dash->{id};
        $dash->{role} = \@roles_in_mongo;
        my @dashlets = _array _load $dash->{dashlets};
        $dash->{dashlets} = \@dashlets;      
        if($dash->{system_params}){
            $dash->{system_params} = _load $dash->{system_params};
        } 
        mdb->dashboard->insert( $dash );   
    }
    mdb->dashboard->remove({'$or'=>[dashlets => qr/^---.*/i, system_params => qr/^---.*/i]});
}

sub role_id_fix {
    my @tmp = map { $_->{_id} } mdb->role->find()->all;
    for my $id (@tmp) {
        my $idrole = mdb->role->find( { _id => $id } )->next->{id} . '';

        mdb->role->update(
            { _id => $id },
            {
                '$set' => {
                    id => $idrole,
                }
            }
        );
    }
}

sub daemons {
    my @daemons = _dbis->query('select * from bali_daemon')->hashes;
    for my $daemon ( @daemons ) {
        delete $daemon->{id};   
        mdb->daemon->insert( $daemon );   
    }
}

sub repository_repl {
    my ($self) = @_;
    
    # repository 
    #   migrate Repository saved.repl into mdb->repl
    #   migrate mvs.queue? no, not needed
    mdb->repl->clone if mdb->repl->count;
    mdb->repl->drop;
    $self->each('bali_repo', sub{
       my $r = shift;
       return unless $r->{ns} =~ /repl/;
       my $t = $r->{ns};
       $t =~ s{^.*/(.*)$}{$1}g;
       my $d = Util->_load($r->{data});
       my $doc = { %$d, text=>$t, _id=>$t };
       mdb->repl->insert( $doc );
    });
    mdb->repo->drop; # in case it exists
}

# add _txt to topic collection
sub topic_rels {
    require Baseliner::Model::Topic;
    _debug('Updating all relationship doc fields for all topics, may take quite a while, be patient...');
    my @alltopics = map{ $$_{mid} } mdb->topic->find->fields({mid=>1})->all;
    my ($k,$tot)=(0,scalar(@alltopics));
    my @group;
    for my $mid ( @alltopics ) {
        if( @group >= 150 ) {
            _debug "Updating... $k/$tot";
            Baseliner::Model::Topic->update_rels( @group );
            _debug "OK. Updated $k/$tot";
            @group = ();
        }
        push @group, $mid; 
        $k++;
    }
    if( @group ){
        Baseliner::Model::Topic->update_rels( @group );
        $k+=@group;
        _debug "Updated $k/$tot";
    }
}

sub role {
    mdb->role->drop;
    my @roles = _dbis->query('select * from bali_role')->hashes;
    my $highest_id = 0;
    for my $role (@roles){
        my @actions_in_oracle = _dbis->query('select * from bali_roleaction')->hashes;
        my @actions_in_mongo;
        if ($role->{id}+0 > $highest_id){
            $highest_id = $role->{id}+0;
        }
        $role->{id} = "$role->{id}";
        foreach my $action (@actions_in_oracle){
            if($role->{id} eq $action->{id_role}){
                push @actions_in_mongo, {action => $action->{action}, bl => $action->{bl}};
            }
        }
        $role->{actions} = \@actions_in_mongo;
        mdb->role->update({ id=>"$$role{id}" },$role,{ upsert=>1 }); 
    }
    mdb->master_seq->remove({ _id => 'role'});
    mdb->master_seq->insert({ _id => 'role', seq => $highest_id });
}

sub topic_admin {
    # category:
    #     { statuses=>[], fields=>[], workflow=>[] }
    require YAML::Syck;
    my $trans=sub{ ref $_[0] eq 'SCALAR' ? $_[0] = ${ $_[0] } : $_[0] };
    my $max_cat=0;
    for my $tc ( _dbis->query('select * from bali_topic_categories')->hashes ) {
        my @st = _dbis->query('select * from bali_topic_categories_status where id_category=?', $$tc{id} )->hashes;
        $$tc{statuses} = [ _unique map { $$_{id_status} } @st ];
        my @fi = _dbis->query('select id_field,params_field from bali_topic_fields_category where id_category=?', $$tc{id} )->hashes;
        $$tc{fieldlets} = [ map { 
            my $pf = delete $$_{params_field};
        	$$_{params} = Util->_load($pf);
            $trans->( $$_{params}{allowBlank} );
            $trans->( $$_{params}{hidden} );
            $trans->( $$_{params}{system_force} );
            $$_{params}{field_order} += 0;
            $$_{params}{field_order_html} += 0;
            $$_{params}{single_mode} = $$_{params}{single_mode} ? 'true':'false' if exists $$_{params}{single_mode};
            $_ } @fi ];
        my @wf = _dbis->query('select id_role,id_status_from,id_status_to,job_type from bali_topic_categories_admin where id_category=?', $$tc{id} )->hashes;
        $$tc{workflow} = [ @wf ];
        #_log( $tc ) ; 
        $max_cat = $$tc{id} if $$tc{id} > $max_cat;
        $$tc{id} .= '';
        mdb->category->update({ id=>"$$tc{id}" }, $tc,{ upsert=>1 });
    }
    # get rid of priority fields in forms
    mdb->category->update({},
     { '$pull'=>{ fieldlets=>{ id_field=>'priority' } } },{ multiple=>1 });
    
    mdb->seq('category', $max_cat ) if $max_cat;
}

sub mids {
    my $max_mid = _dbis->query('select max(mid) from bali_master')->array->[0];
    require List::Util;
    my $max_mid_mdb = List::Util::max(
        map { $_->{mid} } 
        mdb->master->find->fields({ mid=>1 })->all,
        mdb->master_doc->find->fields({ mid=>1 })->all 
     );
     mdb->seq('mid', ($max_mid_mdb > $max_mid ? $max_mid_mdb : $max_mid)+1 );
}

sub statuses {
    my @st = _dbis->query('select * from bali_topic_status')->hashes;
    
    for my $s ( @st )  {
        my $ci = ci->status->search_ci( id_status=>$$s{id} );
        next unless $ci;
        $ci->type( $$s{type} );
        $ci->save;
        say "Updated CI status data for $$s{id} mid=$$ci{mid}";
    }
    
}

# make sure all statuses in DB are migrated to mongo
sub statuses_from_db {
    my @st = _dbis->query('select * from bali_topic_status')->hashes;
    
    for my $s ( @st )  {
        my $ci = ci->status->search_ci( id_status=>$$s{id} );
        next if $ci;
        $$s{id_status} = delete $$s{id};
        $$s{bls} = [ map { my $bl=ci->bl->search_ci(name=>$_); $bl ? $$bl{mid} : () } _array($$s{bl}) ];
        $ci = ci->status->new($s);
        $ci->save;
        say "Created missing CI status for $$s{id_status} mid=$$ci{mid}";
    }
}

sub topic_images {
    my $db = _dbis(); # otherwise we get nasty DESTROY errors
    my $rs = $db->query('select * from bali_topic_image');
    while( my $img = $rs->hash ) {
        say "Checking if image $$img{id_hash} is already in mongo...";
        next if mdb->grid->files->find_one({ md5=>$$img{id_hash} });
        say "Migrating image $$img{id_hash}";
        mdb->grid_insert( $$img{img_data}, content_type=>$$img{content_type}, md5=>$$img{id_hash}, parent_mid=>$$img{topic_mid} );
    }
    say "Done migrating images";
}

sub topic_fields {
    for my $t ( _dbis->query('select * from bali_topic')->hashes ) {
       my %d = map { $_=>$$t{$_} } qw(description modified_on modified_by);
       mdb->topic->update({ mid=>$$t{mid} },{ '$set'=>\%d });
    }
    
    # fix some old broken fields
    for my $t ( mdb->topic->find->all ) {
       my %d = ();
       $d{modified_by} = $$t{created_by} if length $$t{created_by};
       mdb->topic->update({ mid=>$$t{mid} },{ '$set'=>\%d }) if %d;
    }
    
}

sub topic_assets {
    my $db = _dbis;
    my @deleteables;
    for my $rel ( mdb->master_rel->find({ rel_type=>'topic_file_version' })->all ) {    
        
        # get file data
        my $r = $db->query(q{select mid,filename,extension,created_on,created_by,filedata 
           from bali_file_version where mid=?}, $$rel{to_mid})->hash;
       
        if( !$r ) {
            # deleted file, invalid master_rel
            _warn "Not found file mid=$$rel{to_mid}, skipped";
            mdb->master_rel->remove({ _id=>$$rel{_id} });
            next;
        }

        # CREATE asset ci
        my $asset = ci->asset->new({
            name       => $$r{filename},
            created_by => $$r{created_by},
            created_on => $$r{created_on},
            ts         => $$r{created_on},
        });
        $asset->save;
        $asset->put_data( $$r{filedata} );
        
        # RELATE to topic ci
        say "Migrating topic file from=$$rel{from_mid} to=$$rel{to_mid} field=$$rel{rel_field}, mid=$$asset{mid} ($$r{filename})";
        #my $topic = ci->new( $$rel{from_mid} );
        #my @ass = grep { defined } ( _array( $topic->assets ), $asset );
        #$topic->assets( \@ass );
        #$topic->save;
        
        # UPDATE old relation to new asset mid
        mdb->master_rel->update({ _id=>$$rel{_id} },{ '$set'=>{ to_mid=>$$asset{mid}, rel_type=>'topic_asset' } });    
        
        # DELETE old file CI
        push @deleteables, $$rel{to_mid};
        
        # DELETE old relationship
        #mdb->master_rel->remove({ _id=>$$rel{_id} });    
    }
    ci->delete( $_ ) for @deleteables;
}

sub master_cal {
    for my $cal ( _dbis->query('select * from bali_master_cal')->hashes ) {
        mdb->master_cal->update({ id=>$$cal{id} }, $cal,{ upsert=>1 });
    }
}

sub master_doc_clean {
    # delete yaml attribute
    mdb->master_doc->update({},{ '$unset'=>{ 'yaml'=>'' } },{ multiple=>1 });
}

sub job_last_error {
    # clean last_error monstruosities
    my @mids = ci->job->find->fields({mid=>1})->all; 
    my ($k,$tot)=(0,scalar(@mids));
    for my $j ( @mids ) {
       my $job = ci->new( $$j{mid} );
       $job->last_error( substr($job->last_error,0,1024) );
       $job->save;
       $k++;
       _debug "Updated job_last_error $k/$tot" if !($k % 10) || $tot < 10;
    }
}

####################################
#
# Integrity fixes
#

# insert (no update) 
sub master_insert {
    my $db = Util->_dbis();

    my @misses;
    # MASTER
    my $rs = $db->query('select * from bali_master');
    while ( my $r = $rs->hash ) {
        my $mid = "$$r{mid}"; 
        next if mdb->master->find({ mid=>$mid })->count;
        _warn("MISSING master mid=$mid. Inserting.");
        # inserts master
        mdb->master->update({ mid=>$mid }, $r, { upsert=>1 });
        push @misses, $mid;
    }
    
    # inserts master_doc record after we have all masters
    for my $mid (@misses) {
        try { ci->new( $mid )->save } 
        catch { warn "Could not write MASTER_DOC for $mid: " . shift() };  
    }
}

sub master_and_rel {
    my ($self) = @_;
    my $db = Util->_dbis();

    # MASTER
    my @master = $db->query('select * from bali_master')->hashes;
    for my $r ( @master ) {
        mdb->master->update({ mid=>''.$r->{mid} }, $r, { upsert=>1 });
    }
    
    # NOT IN MASTER
    my %in_master = map  {  $_->{mid} => $_ } @master;
    for my $m ( mdb->master->find->fields({ mid=>1 })->all ) {
        if( ! exists $in_master{ $m->{mid} } ) {
            warn "MASTER-MASTER not in DB: $m->{mid}";
            mdb->master->remove({ mid=>''.$m->{mid} },{ multiple=>1 }) 
        }
    }
    
    # FIX master_rel safely
    $self->master_rel_fix;
}

# MASTER_DOC created from CI->save. MASTER_DOC deleted if not in MASTER
sub master_doc {
    my ($self) = @_;
    
    # MASTER_DOC 
    for my $mid ( map {$_->{mid}} mdb->master->find->fields({ mid=>1 })->all ) {
        try { ci->new( $mid )->save } catch { warn "Could not write MASTER_DOC for $mid: " . shift() };  # creates/updates master_doc record
    }
    # master_doc integrity 
    for my $mid ( map {$_->{mid}} mdb->master_doc->find->fields({ mid=>1 })->all ) {
        next if mdb->master->find_one({ mid=>$mid });
        warn "master_doc mid not found=$mid";
        mdb->master_doc->remove({ mid=>$mid });
    }
}

# topic docs that do not have a master row?
sub master_topic {
    my ($self) = @_;
    
    my $db = Util->_dbis();
    my %in_master = map  {  $_->{mid} => $_ } $db->query('select * from bali_master')->hashes;
    
    # TOPIC is in MASTER?
    for my $t ( mdb->topic->find->fields({ mid=>1 })->all ) {
        my $x = mdb->master->find_one({ mid=>$t->{mid} });
        next if $x and exists $in_master{ $t->{mid} };
        warn "TOPIC not in MASTER: $$t{mid}";
        mdb->topic->remove({'$or'=>[{mid=>$$t{mid}},{mid=>0+$$t{mid}}] },{ multiple=>1 });
    }
}

# safely add MASTER_REL from Database to MDB (no deletes)
sub master_rel_add {
    my ($self,@mids)=@_;
    my $db = Util->_dbis();
    @mids = keys +{ map{$_->{mid}=>1} (mdb->master->find->all,$db->query('select * from bali_master')->hashes) }
        unless @mids > 0;
    
    my $k = 0;
    _debug "safely adding master_rel from DB (no deletes)...";
    for my $mid ( @mids ) {
        next if $mid !~ /^\d+$/;   # we want only numeric mids from mongo, otherwise db query breaks
        my %db = map { join(',',@{$_}{qw(from_mid to_mid rel_type rel_field)}) => $_ } 
            $db->query("select * from bali_master_rel where from_mid=? or to_mid=?", $mid, $mid)->hashes;
        my %mdb = map { join(',',@{$_}{qw(from_mid to_mid rel_type rel_field)}) => $_ } 
            mdb->master_rel->find({ '$or'=>[{from_mid=>"$mid"},{to_mid=>"$mid"}] })->all;
        for ( keys %db ) {
            next if exists $mdb{$_};
            $k++;
            mdb->master_rel->insert( $db{$_} );
        }
    }
    _debug "INSERTed REL into MDB: $k times";
}
    
# safely add and delete MASTER_REL from Database
sub master_rel_fix {
    my ($self,@mids)=@_;
    my $db = Util->_dbis();
    @mids = keys +{ map{$_->{mid}=>1} (mdb->master->find->all,$db->query('select * from bali_master')->hashes) }
        unless @mids > 0;
    
    for my $mid ( @mids ) {
        my %db = map { join(',',@{$_}{qw(from_mid to_mid rel_type rel_field)}) => $_ } 
            $db->query("select * from bali_master_rel where from_mid=? or to_mid=?", $mid, $mid)->hashes;
        my %mdb = map { join(',',@{$_}{qw(from_mid to_mid rel_type rel_field)}) => $_ } 
            mdb->master_rel->find({ '$or'=>[{from_mid=>"$mid"},{to_mid=>"$mid"}] })->all;
        for ( keys %mdb ) {
            next if exists $db{$_};
            _warn "REMOVE REL from MDB: $_";
            mdb->master_rel->remove({ _id=>$mdb{$_}{_id} },{ multiple=>1 });
        }
        for ( keys %db ) {
            next if exists $mdb{$_};
            _warn "INSERT REL into MDB: $_";
            mdb->master_rel->insert( $db{$_} );
        }
    }
}
    
# DROPS!!! master_rel and reloads from Database
sub master_rel_rebuild {
    my $db = Util->_dbis();
    # MASTER_REL
    my @master_rel = $db->query('select * from bali_master_rel')->hashes;
    mdb->master_rel->drop;  # cleaner just to insert
    mdb->index_all('master_rel');  # so we have the master_rel uniques
    for my $r ( @master_rel ) {
        next if mdb->master_rel->find_one($r); # bali_master_rel may have tons of junk
        # rgo: salen todas... warn "Missing Rel: $$r{from_mid} => $$r{to_mid} ( $$r{rel_field}, $$r{rel_type} )";
        mdb->master_rel->insert( $r );
    }
}

sub user_cis {
    for my $u ( ci->user->search_cis ) {
       DB->BaliUser->find($u->{mid}) or do {
            warn "NO USER=$u->{mid}, $$u{username}";
            ci->delete( $u->{mid} );
       }
    }
}

sub topic {
    my ( $self, %p ) = @_;
    
    my $db = Util->_dbis;
    my $coll = $p{coll} // mdb->topic;
    my $r = $p{row} // $db->query('select * from bali_topic where mid=?', $p{mid} )->hash;
    my $mid = ''. ( $p{mid} // $r->{mid} );
    if( $mid && $p{replace} ) {
        $coll->remove({ mid=>$mid });
    }

    my $rs = $db->query( $self->topic_view, $r->{mid} );
    my $row = $rs->hash;
    return if !$row;
    my $doc = { %$row, %$r };
    $doc->{category} = mdb->category->find_one( { id => $r->{id_category} } );
    $doc->{category_status} = ci->status->find_one( { id => $r->{id_category_status} } );
    $doc->{calevent} = '';

    #$doc->{created_on} = Class::Date->new( $doc->{created_on_epoch} ).""; # not needed, dates are correct comming out of oraclej
    #$doc->{modified_on} = Class::Date->new( $doc->{modified_on_epoch} )."";
    delete $doc->{$_} for grep /\./, keys $doc;
    my @fields = $db->query( 'select * from bali_topic_fields_custom where topic_mid=?', $r->{mid} )->hashes;
    my @rels = $db->query(
        'select r.rel_field, m.collection, m.name from bali_master_rel r,bali_master m where (m.mid=r.to_mid) and r.from_mid=?',
        $r->{mid}
    )->hashes;
    my @rels2 = $db->query(
        'select r.rel_field, m.collection, m.name from bali_master_rel r,bali_master m where (m.mid=r.from_mid) and r.to_mid=?',
        $r->{mid}
    )->hashes;
    my %cals = map {
        my $slot = Util->_name_to_id( $_->{slotname} );
        $_->{rel_field} => {
            $slot => {
                start_date      => $_->{start_date},
                end_date        => $_->{end_date},
                plan_start_date => $_->{plan_start_date},
                plan_end_date   => $_->{plan_end_date}
            }
            }
    } $db->query( 'select * from bali_master_cal c where c.mid=?', $r->{mid} )->hashes;

    #_debug \@rels;
    say "found custom fields for $r->{mid}: " . join ',', map { $_->{name} } @fields if @fields;

    my %fieldlets = map( {
            my $v = $_->{value_clob} || $_->{value};
                $v = try { _load($v) } catch { $v } if $v;
                ( $_->{name} => $v )
    } @fields );
    my %relations = map( {
            my $v = $_->{name};
                ( $_->{rel_field} => $v )
        } @rels,
        @rels2 );
    $doc = { %$doc, %cals, %fieldlets, %relations };
    delete $doc->{$_} for qw(sw_edit last_seen label_color label_name label_id);
    $coll->insert($doc);
}

sub clean_master_topic {
   for ( _dbis->query(q{select name,mid from bali_master m where m.collection='topic' and not exists 
    (select 1 from bali_topic t where t.mid=m.mid)})->hashes ){
        warn "Deleting master mid $_->{mid} not found in topic...";
        my $x = DB->BaliMaster->find($_->{mid});
        next unless $x;
        $x->delete
    } 
}

sub add_master_doc_sort{
    _log "adding sorting properties to master_doc\n";
    my @cis = mdb->master_doc->find->all;

    foreach  (@cis){
        my $new_name = $_->{name} ? lc $_->{name} : $_->{collection}.':'.$_->{mid};
        mdb->master_doc->update({mid => $_->{mid}},{'$set'=>{_sort => {name => $new_name}}}); 
    }
}

sub update_topic_rels{
    _log "updating topics rels\n";
    my @topics = map{$_->{mid}}mdb->topic->find->fields({mid=>1,_id=>0})->all;
    Baseliner->model('Topic')->update_rels(@topics);
}

sub activity{
    _log "creating activity log for topics from events collection\n";
    my $ultra_tot = 0;
    my $tot = 0;
    my $inc = 1000;
    my $total_events = 0;
    my @ev_errors;
    while ($total_events <= $inc){  
        my $limit = $tot+$inc;
        my @events = mdb->event->find({event_key=>{'$not'=>qr/^event\.(rule|repository)/i}})->skip($tot)->limit($inc)->all;
        $total_events = @events;
        $tot += $inc;
        if($total_events == 0){
           last; 
        }
        $ultra_tot += $total_events;
        _log "$ultra_tot events converted to activity" if $ultra_tot % 500 == 0;
        foreach my $event (@events) {
            try{
                my $key = $event->{event_key};
                my $ev = Baseliner->model('Registry')->get($key);
                if( _array( $ev->{vars} ) > 0 ) {
                    
                    my $ed_reduced={};
                    my $ed = _load $event->{event_data};
                    Util->_unbless( $ed );
                    foreach (_array $ev->{vars}){             
                        $ed_reduced->{$_} = $ed->{$_};
                    }
                    $ed_reduced->{ts} = $event->{ts};
                    mdb->activity->insert({
                        vars            => $ed_reduced,
                        event_key       => $key,
                        event_id        => $event->{id},
                        mid             => $event->{mid},
                        module          => $event->{module},
                        ts              => $event->{ts},
                        username        => $event->{username},
                        text            => $ev->{text},
                        ev_level        => $ev->{ev_level},
                        level           => $ev->{level}
                    });
                }    
            } catch{
                push @ev_errors, $event;
            }        
        }
    }
    _log "numero total de eventos erroneos ". scalar @ev_errors ;
    _log _dump map{$_->{mid} => $_->{event_key}; } @ev_errors;
}

sub topic_view {
    qq{
    SELECT  T.MID TOPIC_MID,
            T.MID,
            T.TITLE,
            T.CREATED_ON,
            T.CREATED_BY,
            T.MODIFIED_ON,
            T.MODIFIED_BY,
            T.DESCRIPTION,
            T.STATUS, 
            NUMCOMMENT,
            C.ID CATEGORY_ID,
            C.NAME CATEGORY_NAME,
            T.PROGRESS,
            T.ID_CATEGORY_STATUS CATEGORY_STATUS_ID,
            S.NAME CATEGORY_STATUS_NAME,
            S.SEQ CATEGORY_STATUS_SEQ,
            S.TYPE CATEGORY_STATUS_TYPE,
            T.ID_PRIORITY AS PRIORITY_ID,
            TP.NAME PRIORITY_NAME,
            TP.RESPONSE_TIME_MIN,
            TP.EXPR_RESPONSE_TIME,
            TP.DEADLINE_MIN,
            TP.EXPR_DEADLINE,
            C.COLOR CATEGORY_COLOR,
            C.IS_CHANGESET,
            C.IS_RELEASE,
            L.ID LABEL_ID,
            L.NAME LABEL_NAME,
            L.COLOR LABEL_COLOR,
            P.MID AS PROJECT_ID,
            P.NAME AS PROJECT_NAME,
            MP.COLLECTION AS COLLECTION,
            F.FILENAME AS FILE_NAME,
            PS.TEXT AS TEXT,
            NUM_FILE,
            U.USERNAME ASSIGNEE,
            MA.MONIKER,
            cis_out.NAME CIS_OUT,
            cis_in.NAME CIS_IN,
            topics_in.TITLE REFERENCED_IN,
            topics_out.TITLE REFERENCES_OUT,
            DS.NAME directory
            FROM  BALI_TOPIC T
                    JOIN BALI_MASTER MA ON T.MID = MA.MID
                    LEFT JOIN BALI_TOPIC_CATEGORIES C ON T.ID_CATEGORY = C.ID
                    LEFT JOIN BALI_TOPIC_LABEL TL ON TL.ID_TOPIC = T.MID
                    LEFT JOIN BALI_LABEL L ON L.ID = TL.ID_LABEL
                    LEFT JOIN BALI_TOPIC_PRIORITY TP ON T.ID_PRIORITY = TP.ID
                    LEFT JOIN (SELECT COUNT(*) AS NUMCOMMENT, A.MID 
                                        FROM BALI_TOPIC A, BALI_MASTER_REL REL, BALI_POST B
                                        WHERE A.MID = REL.FROM_MID
                                        AND REL.TO_MID = B.MID
                                        AND REL.REL_TYPE = 'topic_post'
                                        GROUP BY A.MID) D ON T.MID = D.MID
                    LEFT JOIN (SELECT COUNT(*) AS NUM_FILE, E.MID 
                                        FROM BALI_TOPIC E, BALI_MASTER_REL REL1, BALI_FILE_VERSION G
                                        WHERE E.MID = REL1.FROM_MID
                                        AND REL1.TO_MID = G.MID
                                        AND REL1.REL_TYPE = 'topic_file_version'
                                        GROUP BY E.MID) H ON T.MID = H.MID                                         
                    LEFT JOIN BALI_TOPIC_STATUS S ON T.ID_CATEGORY_STATUS = S.ID
                    LEFT JOIN BALI_MASTER_REL REL_PR ON REL_PR.FROM_MID = T.MID AND REL_PR.REL_TYPE = 'topic_project'
                    LEFT JOIN BALI_PROJECT P ON P.MID = REL_PR.TO_MID
                    LEFT JOIN BALI_MASTER MP ON REL_PR.TO_MID = MP.MID AND MP.COLLECTION = 'project'
                    LEFT JOIN BALI_MASTER_REL REL_F ON REL_F.FROM_MID = T.MID AND REL_F.REL_TYPE = 'topic_file_version'
                    LEFT JOIN BALI_FILE_VERSION F ON F.MID = REL_F.TO_MID
                    LEFT JOIN BALI_MASTER_REL REL_PS ON REL_PS.FROM_MID = T.MID AND REL_PS.REL_TYPE = 'topic_post'
                    LEFT JOIN BALI_POST PS ON PS.MID = REL_PS.TO_MID
                    LEFT JOIN BALI_MASTER_REL REL_USER ON REL_USER.FROM_MID = T.MID AND REL_USER.REL_TYPE = 'topic_users'
                    LEFT JOIN BALI_USER U ON U.MID = REL_USER.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_topics_out ON rel_topics_out.FROM_MID = T.MID AND rel_topics_out.REL_TYPE = 'topic_topic'
                    LEFT JOIN BALI_TOPIC topics_out ON topics_out.MID = rel_topics_out.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_topics_in ON rel_topics_in.TO_MID = T.MID AND rel_topics_in.REL_TYPE = 'topic_topic'
                    LEFT JOIN BALI_TOPIC topics_in ON topics_in.MID = rel_topics_in.FROM_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_cis_out ON rel_cis_out.FROM_MID = T.MID AND rel_cis_out.REL_TYPE NOT IN( 
                        'topic_post','topic_file_version','topic_project','topic_users','topic_topic' )
                    LEFT JOIN BALI_MASTER cis_out ON cis_out.MID = rel_cis_out.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_cis_in ON rel_cis_in.TO_MID = T.MID AND rel_cis_in.REL_TYPE NOT IN( 
                        'topic_post','topic_file_version','topic_project','topic_users','topic_topic' )
                    LEFT JOIN BALI_MASTER cis_in ON cis_in.MID = rel_cis_in.FROM_MID
                    
                    LEFT JOIN BALI_PROJECT_DIRECTORIES_FILES DF ON DF.ID_FILE = T.MID
                    LEFT JOIN BALI_PROJECT_DIRECTORIES DS ON DF.ID_DIRECTORY = DS.ID
            WHERE T.ACTIVE = 1
            AND T.MID = ?
    };
}

package Baseliner::Schema::Migra::MongoMigration::Wrap {
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my $name = $AUTOLOAD;
        my ($meth) = reverse( split(/::/, $name));
        {
            local $Baseliner::Utils::caller_level = 1;
            Util->_log( "MDB -> migra START: $meth" );
        }
        Baseliner::Schema::Migra::MongoMigration->$meth(@_);
        {
            local $Baseliner::Utils::caller_level = 1;
            Util->_log( "MDB -> migra END: $meth" );
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__


---
- BaliProjectTree
- TopicView
- bali_calendar
- bali_calendar_window
- bali_config
- bali_daemon
- bali_dashboard
- bali_dashboard_role
- bali_event
- bali_event_rules
- bali_file_version
- bali_job
- bali_job_items
- bali_job_stash
- bali_label
- bali_label_project
- bali_log
- bali_log_data
- bali_master
- bali_master_cal
- bali_master_kv
- bali_master_prefs
- bali_master_rel
- bali_message
- bali_message_queue
- bali_notification
- bali_post
- bali_project
- bali_project_directories
- bali_project_directories_files
- bali_repo
- bali_repokeys
- bali_request
- bali_role
- bali_roleaction
- bali_roleuser
- bali_rule
- bali_rule_statement
- bali_scheduler
- bali_sem
- bali_sem_queue
- bali_sysoutdds
- bali_topic
- bali_topic_categories
- bali_topic_categories_admin
- bali_topic_categories_priority
- bali_topic_categories_status
- bali_topic_fields_category
- bali_topic_fields_custom
- bali_topic_image
- bali_topic_label
- bali_topic_priority
- bali_topic_status
- bali_topic_view
- bali_user

