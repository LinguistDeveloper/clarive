package Baseliner::Controller::Rule;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use DateTime;
use Try::Tiny;
use Time::HiRes qw(time);
use v5.10;
use Baseliner::Core::Registry ':dsl';


BEGIN {  extends 'Catalyst::Controller' }
BEGIN { extends 'Catalyst::Controller::WrapCGI' }

register 'action.admin.rules' => { name=>'Admin Rules' };

register 'config.rules' => {
    metadata => [
        {   id      => 'auto_rename_vars',
            name    => 'Auto rename variables in rules',
            type    => 'text',
            default => '0',
            label   => 'CAUTION: If activated, varible names will be changed in rules when renamed in cis. USE AT YOUR OWN RISK'
        }
    ]
};

register 'menu.admin.rule' => {
    label    => 'Rules',
    title    => _loc ('Rules'),
    action   => 'action.admin.rules',
    url_comp => '/comp/rules.js',
    icon     => '/static/images/icons/rule.png',
    tab_icon => '/static/images/icons/rule.png'
};

register 'event.ws.soap_ready' => {
    text => 'SOAP WS ready to return',
    description => 'SOAP WS is ready',
    vars => [],
};

sub begin : Private {  
     my ($self,$c,$meth,$id_rule) = @_;
     if( length $id_rule ) { 
         my $rule = $self->rule_from_url( $id_rule );
         if( $rule->{authtype} eq 'none' ) {
             $c->stash->{auth_skip} = 1 
         } else {
             $c->stash->{auth_logon_type} = $meth; 
         }
     }
}

sub list : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my $qry = $p->{query};
    my %query;
    $query{rule_active} = mdb->true;
    $query{rule_type} = $p->{rule_type} if ($p->{rule_type});
    $query{rule_name} = qr/$qry/i if length $qry && !$p->{valuesqry};
    my @rows = mdb->rule->find({ %query })->sort({ rule_name=>1 })->fields({ rule_tree=>0 })->all;
    $c->stash->{json} = { data=>\@rows, totalCount=>scalar(@rows) };
    $c->forward('View::JSON');
}

sub actions : Local {
    my ($self,$c)=@_;
    my $list = $c->registry->starts_with( 'service' ) ;
    my $p = $c->req->params;
    my @tree;
    my $field = $p->{field} || 'name';
    use utf8;
    push @tree, (
        { id=>'service.email.send', text=>_loc('Envío de Notificación por Email') }
    );
    foreach my $key ( $c->registry->starts_with( 'service' ) ) {
        my $service = Baseliner::Core::Registry->get( $key );
        push @tree,
          {
            id   => $key,
            leaf => \1,
            text => ( $field eq 'key' ? $key : $service->{$field} ) || $key,
            attributes => { key => $key, name=>$service->{name}, id=>$service->{id} }
          };
    }
    $c->stash->{json} = { data => [ sort { $a->{text} cmp $b->{text} } @tree ], totalCount=>scalar @tree };
    $c->forward("View::JSON");
}

sub activate : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        my $row = mdb->rule->find_one({ id=>"$p->{id_rule}" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        my $name = $row->{rule_name};
        mdb->rule->update({ id=>"$p->{id_rule}" }, { '$set'=>{ rule_active=>"$p->{activate}" } });
        my $act = $p->{activate} ? _loc('activated') : _loc('deactivated');
        $c->stash->{json} = { success=>\1, msg=>_loc('Rule %1 %2', $name, $act) };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub export : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_rule = $p->{id_rule};
    try {
        my $doc = mdb->rule->find_one({ id=>"$id_rule" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $doc;
        #$doc->{rule_tree} = $doc->{rule_tree} ? _decode_json($doc->{rule_tree}) : [];
        delete $doc->{_id};
        my $yaml = _dump($doc);
        $c->stash->{json} = { success=>\1, yaml=>$yaml };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub export_file : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_rule = $p->{id_rule};
    try {
        my $doc = mdb->rule->find_one({ id=>"$id_rule" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $doc;
        #$doc->{rule_tree} = $doc->{rule_tree} ? _decode_json($doc->{rule_tree}) : [];
        delete $doc->{_id};
        my $yaml = _dump($doc);
        $c->stash->{serve_body} = $yaml;
        $c->stash->{serve_filename} = Util->_name_to_id( $doc->{rule_name} ) . '.yaml';
        $c->forward('/serve_file');
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
}

sub import_rule {
    my ($self,%p)=@_;
    my $data = $p{data} // _throw 'Missing rule';
    $p{type} //= 'yaml';
    my $rule = $p{type} eq 'yaml' ? _load( $data ) : {} ;
    delete $rule->{id};
    delete $rule->{rule_id};
    delete $rule->{_id};
    my $doc = mdb->rule->find_one({ rule_name=>$rule->{rule_name} });
    if( $doc ) {
        $rule->{rule_name} = sprintf '%s (%s)', $rule->{rule_name}, _now();
    }
    # rule tree should be stored as JSON to avoid import/export discrepancies while migrating it to YAML
    $rule->{rule_tree} = Util->_encode_json($rule->{rule_tree}) if ref $rule->{rule_tree}; 
    $rule->{id} = mdb->seq('rule');
    $rule->{rule_seq} = 0+ mdb->seq('rule_seq');
    $rule->{rule_active} = '1';
    mdb->rule->insert($rule);
    return $rule;
}

sub import_yaml : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $data = $p->{data};
    my $type = $p->{type};
    _fail _loc('Missing data') if !length $data;
    
    try {
        my $rule = $self->import_rule( data=>$data );
        $c->stash->{json} = { success=>\1, name=>$rule->{rule_name} };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub import_file : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;

    my $filename = $p->{qqfile};
    my $type     = $p->{type} // 'yaml';
    
    my $f = _file( $c->req->body );
    _log "Importing rule from file: " . $filename;
    try {
        my $data = ''.$f->slurp;
        _log "Rule file length: " . length $data;
        my $rule = $self->import_rule( data=>$data );
        $c->stash->{json} = { success=>\1, msg => _loc( 'Rule imported %1', $rule->{rule_name} ), name=>$rule->{rule_name} };
    } catch {
        my $err = shift;
        my $msg = "Error importing rule: " . $err;
        $c->stash->{json} = { success=>\0, msg=>$msg };
    };

    $c->forward( 'View::JSON' );
}

sub delete : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        my $row = mdb->rule->find_one({ id=>"$p->{id_rule}" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        my $name = $row->{rule_name};
        if($row->{rule_type} eq 'fieldlets'){
            #remove relationship between rule and category
            mdb->category->update({default_form=>"$p->{id_rule}"},{'$set'=>{default_form=>''}});
        }
        mdb->rule->remove({ id=>"$p->{id_rule}" },{ multiple=>1 });
        mdb->grid->remove({ id_rule=>"$p->{id_rule}" });
        # TODO delete rule_version? its capped, it can't be deleted... may be good to keep history
        $c->stash->{json} = { success=>\1, msg=>_loc('Rule %1 deleted', $name) };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub get : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        my $doc = mdb->rule->find_one({ id=>"$p->{id_rule}" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $doc;
        $doc->{pipeline_default} = $doc->{rule_type} eq 'pipeline' ? $doc->{rule_when} : '-';
        $c->stash->{json} = { success=>\1, rec=>$doc };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub event_list : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my @rows;
    foreach my $key ( $c->registry->starts_with( 'event' ) ) {
        my $ev = Baseliner::Core::Registry->get( $key );
        push @rows, {
            name        => $ev->name // $key,
            key         => $key,
            description => $ev->description,
            type        => $ev->type // 'none',
        };
    }
    $c->stash->{json} = { data => [ sort { uc $a->{name} cmp uc $b->{name} } @rows ], totalCount=>scalar @rows };
    $c->forward("View::JSON");
}

sub tree : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;

    my @tree;
    use utf8;
    my @rules = mdb->rule->find->fields({ rule_tree=>0 })->all;
    my $cnt = 1;
    for my $rule ( @rules ) {
        push @tree,
          {
            id => $cnt++,
            leaf => \0,
            icon => '/static/images/icons/rule.png',
            text => $rule->{rule_name},
          };
    }
    @tree = () if $p->{node} > 0;
    $c->stash->{json} = \@tree;
    $c->forward("View::JSON");
}

sub grid : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    $p->{destination} = 'grid';
    my @rules = Baseliner->model('Rules')->get_rules_info($p); 
    $c->stash->{json} = { totalCount=>scalar(@rules), data => \@rules };
    $c->forward("View::JSON");
}

sub compile_wsdl {
    my ($self,$wsdl)=@_;
    return try {
        require XML::Compile::SOAP11;
        require XML::Compile::SOAP::Daemon::CGI;
        require XML::Compile::WSDL11;
        require XML::Compile::SOAP::Util;
        return XML::Compile::WSDL11->new( Util->parse_vars($wsdl,{ 
                    #server_type => 'BEA',
                    WSURL=>'http://fakeurl:8080/rule/soap/fake_for_compile',
                }) );
    } catch {
        my $err = shift;
        _fail( _loc('Error compiling WSDL: <br /><pre>%1</pre>', Util->_html_escape($err)) );
    };
}

sub save : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->params;
    try {
        if( $$p{wsdl} ) {
            # soap envelope received, precompile for errors
            $self->compile_wsdl($$p{wsdl});
        }
        my $data = {
            rule_active => '1',
            rule_name  => $p->{rule_name},
            rule_when  => ( $p->{rule_type} eq 'pipeline' 
                ? $p->{pipeline_default}  
                : $p->{rule_when} ),
            rule_event => $p->{rule_event},
            rule_type  => $p->{rule_type},
            rule_compile_mode  => $p->{rule_compile_mode},
            rule_desc  => substr($p->{rule_desc},0,2000),
            subtype => $p->{subtype},
            authtype => $p->{authtype},
            wsdl => $p->{wsdl},
            ts =>  mdb->ts,
            username => $c->username
        };
        if ( length $p->{rule_id} ) {
            my $doc = mdb->rule->find_one({ id=>"$p->{rule_id}" });
            _fail _loc 'Rule %1 not found', $p->{rule_id} unless $doc;
            mdb->rule->update({ id=>"$p->{rule_id}" },{ %$doc, %$data });
        } else {
            $data->{id} = mdb->seq('rule');
            $data->{rule_seq} = 0+mdb->seq('rule_seq');
            mdb->rule->insert($data);
        }
        $c->stash->{json} = { success => \1, msg => 'Creado' };
    } catch {
        my $err = shift;
        my $msg = _loc('Error saving rule: %1', $err );
        _error( $msg );
        $c->stash->{json} = { success => \0, msg => $msg };
    };
    $c->forward("View::JSON");
}

sub palette : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;

    my $query = $p->{query};
    $query and $query = qr/$query/i;

    my @tree;
    my $cnt = 1;
    
    my $if_icon = '/static/images/icons/if.gif';
    my %types = (
        if     => { icon=>'/static/images/icons/if.gif' },
        let    => { icon=>'/static/images/icons/if.gif' },
        for    => { icon=>'/static/images/icons/if.gif' },
    );
    #my @ifs = (
    #    { text => _loc('if var'),  statement=>'if_var', leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1,  },
    #    { text => _loc('if user'), statement=>'if_user', leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1, },
    #    { text => _loc('if role'), statement=>'if_role', leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1, },
    #    { text => _loc('if project'), statement=>'if_project', leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1, },
    #);
    my @control = 
        sort { ($a->{text}//'') cmp ($b->{text}//'') } 
        grep { !$query || join(',',grep{defined}%$_) =~ $query } 
        map {
            my $key = $_;
            my $s = $c->registry->get( $key );
            my $n= { palette => 1 };
            $n->{holds_children} = defined $s->{holds_children} ? \($s->{holds_children}) : \1;
            $n->{leaf} = \1;
            $n->{key} = $key;
            $n->{text} = $s->{text} // $key;
            $n->{run_sub} = $s->{run_sub} // \1;
            $n->{on_drop} = !!$s->{on_drop};
            $n->{on_drop_js} = $s->{on_drop_js};
            $n->{nested} = $s->{nested} // 0;
            $n->{icon} = $s->icon // ( !$s->{type} 
                ? '/static/images/icons/help.png'
                : do{ 
                    my $type = $types{ $s->{type} };
                    "/static/images/icons/$s->{type}.gif";
                });
            $n;
        } 
        Baseliner->registry->starts_with( 'statement.' );
        push @tree, {
            icon     => '/static/images/icons/controller.png',
            #icon     => '/static/images/icons/control.gif',
            text     => _loc('Control'),
            draggable => \0,
            expanded => \1,
            isTarget => \0,
            leaf     => \0,
            children => \@control,
        };

    my @services = sort $c->registry->starts_with('service');
    push @tree, {
        id=>$cnt++,
        leaf=>\0,
        text=>_loc('Job Services'),
        icon => '/static/images/icons/job.png',
        draggable => \0,
        expanded => \1,
        children=> [ 
          sort { uc $a->{text} cmp uc $b->{text} }
          grep { !$query || join(',', grep{defined}values %$_) =~ $query }
          map {
            my $n = $_;
            my $service_key = $n->{key};
            +{
                isTarget => \0,
                leaf=>\1,
                key => $service_key,
                icon => $n->{icon},
                palette => \1,
                text=>$n->{name} // $service_key,
            }
        } 
        grep {
            $_->{job_service}
        }
        map { 
            $c->registry->get( $_ );
        }
        @services ]
    };

    push @tree, {
        id=>$cnt++,
        leaf=>\0,
        text=>_loc('Generic Services'),
        icon => '/static/images/icons/services_new.png',
        #icon => '/static/images/icons/job.png',
        draggable => \0,
        expanded => length $query ? \1 : \0,
        children=> [ 
          sort { uc $a->{text} cmp uc $b->{text} }
          grep { !$query || join(',', grep{defined}values %$_) =~ $query }
          map {
            my $n = $_;
            my $service_key = $n->{key};
            +{
                isTarget => \0,
                leaf=>\1,
                key => $service_key,
                icon => $n->{icon},
                palette => \1,
                text=>$n->{name} // $service_key,
            }
        } 
        grep {
            ! $_->{job_service}
        }
        map { 
            $c->registry->get( $_ );
        }
        @services ]
    };

    ############ Dashlets
    my @dashlets = sort $c->registry->starts_with('dashlet');
    push @tree, {
        id=>$cnt++,
        leaf=>\0,
        text=>_loc('Dashlets'),
        icon => '/static/images/icons/dashboard.png',
        draggable => \0,
        expanded => \1,
        children=> [ 
          sort { uc $a->{text} cmp uc $b->{text} }
          grep { !$query || join(',', grep{defined}values %$_) =~ $query }
          map {
            my $n = $_;
            +{
                isTarget  => \0,
                leaf      => \1,
                key       => $n->{key},
                icon      => $n->{icon},
                html      => $n->{html},
                palette   => \1,
                text      => $n->{name} // $n->{key},
            }
        } 
        map { 
            $c->registry->get( $_ );
        }
        @dashlets ]
    };


    my @rules = mdb->rule->find->fields({ id=>1, rule_name=>1 })->sort( mdb->ixhash( rule_seq=>1, _id=>-1) )->all; 
    push @tree, {
        id=>$cnt++,
        leaf=>\0,
        text=>_loc('Rules'),
        icon => '/static/images/icons/rule.png',
        draggable => \0,
        expanded => \1,
        children=> [ 
          sort { uc $a->{text} cmp uc $b->{text} }
          grep { !$query || join(',', values %$_) =~ $query }
          map {
            +{
                isTarget => \0,
                leaf=>\1,
                key => 'statement.include',
                icon => '/static/images/icons/rule.png',
                palette => \1,
                id_rule => $_->{id},
                data=>{ id_rule => $_->{id} },
                text=>$_->{rule_name},
            }
        } @rules ]
    };
    my @fieldlets = grep { $_ !~ /required/ } sort $c->registry->starts_with('fieldlet.');
    my $default_icon = '/static/images/icons/detail.png';
    push @tree, {
        id=>$cnt++,
        leaf=>\0,
        text=>_loc('Fieldlets'),
        icon => $default_icon,
        draggable => \0,
        expanded => \1,
        children=> [
            grep { !$query || join(',',grep{defined}%$_) =~ $query }  
            map {
                my $n = $_;
                my $service_key = $n->{key};
                +{
                    isTarget => $n->{holds_children}? \1: \0,
                    leaf=> \1,
                    holds_children=>$n->{holds_children}? \1: \0,
                    key => $service_key,
                    icon => $n->{icon} // $default_icon,
                    palette => \1,
                    text => _loc($n->{name}) // $service_key,
                }
            } 
            grep { $_->{show_in_palette} }
            map { 
                $c->registry->get( $_ );
            } @fieldlets
        ]
    };

    $c->stash->{json} = \@tree;
    $c->forward("View::JSON");
}

sub stmts_save : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    $p->{username} = $c->username;
    my $error_checking_dsl = 0;
    try {
        my ($detected_errors,$returned_ts);
        ($detected_errors,$returned_ts,$error_checking_dsl) = $self->local_stmts_save($p);
        my $old_ts = $returned_ts->{old_ts};
        my $actual_ts = $returned_ts->{actual_ts};
        my $previous_user = $returned_ts->{previous_user};
        if ($returned_ts->{old_ts} ne ''){
            my ($short_errors) = $detected_errors =~ m/^([^\n]+)/s;
            my $rule_type = mdb->rule->find_one({id=>"$p->{id_rule}"});
            if ($rule_type->{rule_type} eq 'form'){
                cache->remove_like( qr/^topic:/ );
                cache->remove_like( qr/^roles:/ );
                cache->remove({ d=>"topic:meta" });
                $c->registry->reload_all;
            }
            my $msg = $detected_errors ? _loc('Rule statements saved with errors: %1', $short_errors) : _loc('Rule statements saved ok');
            $c->stash->{json} = { success=>\1, msg =>$msg, old_ts => $old_ts, actual_ts=> $actual_ts, username=>$c->username, detected_errors=>$detected_errors };
        } else {
            $c->stash->{json} = { success=>\1, msg => _loc('Another user changed rule statements while editing'), old_ts => $old_ts, actual_ts=> $actual_ts, username=> $previous_user , detected_errors=>$detected_errors};
        }
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => "$err", error_checking_dsl=>$error_checking_dsl };
    };
    $c->forward("View::JSON");
}

sub local_stmts_save {
    my ($self,$p) = @_;
    my $returned_ts;
    my $error_checking_dsl = 0;
    my $id_rule = $p->{id_rule} or _throw 'Missing rule id';
    my $doc = mdb->rule->find_one({ id=>''.$id_rule }) // _fail _loc 'Rule id %1 missing. Deleted?', $id_rule;
    my $ignore_dsl_errors = $p->{ignore_dsl_errors} || $$doc{ignore_dsl_errors};
    # check json valid
    my $stmts = try { 
        _decode_json( $p->{stmts} );
    } catch {
        _fail _loc "Corrupt or incorrect json rule tree: %1", shift(); 
    };
    
    my $ts = mdb->ts;
    #_debug $stmts;
    # check if DSL is buildable
    my $detected_errors = try { 
        use Baseliner::Model::Rules;
        my $dsl = Baseliner::Model::Rules->dsl_build_and_test( $stmts, id_rule=>$id_rule, ts=>$ts );
        _debug "Caching rule $id_rule for further use";
        mdb->grid->remove({id_rule=> "$id_rule"});
        mdb->grid_insert( $dsl ,id_rule => $id_rule );
        return '';
    } catch {
        my $err = shift;
        _warn( $err );
        $error_checking_dsl = 1; 
        return $err if $ignore_dsl_errors;
        _fail _loc "Error testing DSL build: %1", $err;
    };
    $returned_ts = $self->save_rule( id_rule=>$id_rule, stmts_json=>$p->{stmts}, username=>$p->{username}, ts=>$ts, old_ts=>$p->{old_ts}, 
        detected_errors   => $detected_errors,  # useful in case we want to warn user before doing something with this broken rule
        ignore_dsl_errors =>( $$p{ignore_error_always} ? '1' : undef ) );
    return ($detected_errors,$returned_ts,$error_checking_dsl);
}

##################################################################################
sub get_rule_ts : Local{
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        _debug $p;
        my $ts = mdb->rule->find({id => ''.$p->{id_rule}})->next->{ts};
        $c->stash->{json} = { success=>\1, msg => 'ok', ts => $ts };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}


sub rule_test : Local{
    my ( $self, $c )=@_;
    my $option = $c->request->parameters->{option};
    if ( $option == 0 ) {
        my $id_rule = $c->request->parameters->{id_rule};
        mdb->rule->update({ id=>''.$id_rule }, { '$set'=> { ts => '2014-03-14 14:00:00', username => 'pepe' }} );
        $c->stash->{json} = { success=>\1, msg=>_loc('Simulation of modification of rule statements') };
    }
    if ( $option == -1 ) {
        my $id_rule = $c->request->parameters->{id_rule};
        mdb->rule->remove({ id=> ''.$id_rule },{ multiple=>1 });
        my $previous_seq_r = mdb->master_seq->find_one({_id => 'rule'})->{seq}-1;
        my $previous_seq_rs = mdb->master_seq->find_one({_id => 'rule_seq'})->{seq}-1;
        mdb->master_seq->update( {_id => 'rule'}, { '$set'=> { seq => $previous_seq_r } });
        mdb->master_seq->update( {_id => 'rule_seq'}, { '$set'=> { seq => $previous_seq_rs } });
        $c->stash->{json} = { success=>\1, msg=>_loc('Rule deleted') };
    }
    $c->forward( 'View::JSON' );
}
#################################################################################
# saves and versions a rule
sub save_rule {
    my ($self,%p)=@_;
    my $doc = mdb->rule->find_one({ id=>"$p{id_rule}" });
    _fail _loc 'Rule not found, id=%1', $p{id_rule} unless $doc;

    my $ts_modified = 0;
    my $old_timestamp = ''.$p{old_ts};
    my $rule = mdb->rule->find_one({ id => ''.$p{id_rule}});
    my $actual_timestamp = $p{ts} || $rule->{ts};
    my %other_options;
    defined $p{$_} and $other_options{$_}=$p{$_} for qw(detected_errors ignore_dsl_errors);
    my $previous_user = $rule->{username};
    if (!$actual_timestamp and !$previous_user){
        $actual_timestamp = $old_timestamp;
        $previous_user = $p{username};
        mdb->rule->update({ id =>''.$p{id_rule} }, { '$set'=>{ ts=>$actual_timestamp, username=>$previous_user, %other_options } } ); 
    }
    $ts_modified = (''.$old_timestamp ne ''.$actual_timestamp) ||  ($p{username} ne $previous_user);

    $old_timestamp = $p{ts} // mdb->ts;
    mdb->rule->update({ id=>''.$p{id_rule} }, { '$set'=> { ts => $old_timestamp, username => $p{username}, rule_tree=>$p{stmts_json}, %other_options } } );
    # now, version
    # check if collection exists
    # if( ! mdb->collection('system.namespaces')->find({ name=>qr/rule_version/ })->count ) {
    #     mdb->create_capped( 'rule_version' );
    # }

    delete $doc->{_id};
    mdb->rule_version->insert({ %$doc, ts=>mdb->ts, username=>$p{username}, id_rule=>$p{id_rule}, rule_tree=>$p{stmts_json}, was=>($p{was}//'') });    
    { old_ts => $old_timestamp, actual_ts => $actual_timestamp, previous_user => $previous_user };
}

sub rollback_version : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $version_id = $p->{version_id};
    my $ver = mdb->rule_version->find_one({ _id=>mdb->oid($version_id) });
    _fail _loc 'Version not found: %1', $version_id unless $ver;
    try {
        $self->save_rule( id_rule=>$ver->{id_rule}, stmts_json=>$ver->{rule_tree}, username=>$ver->{username}, was=>$ver->{ts}, old_ts=>$ver->{ts} );
        $c->stash->{json} = { success=>\1, msg => _loc('Rule rollback to %1 (%2)', $ver->{ts}, $ver->{username} ) };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
} 
    
sub stmts_load : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $load_versions = $p->{load_versions};
    try {
        my $id_rule = $p->{id_rule} or _throw 'Missing rule id';
        # recursive loading from rows to tree:
        my @tree = Baseliner->model('Rules')->build_tree( $id_rule, undef );
        # $c->stash->{json} = [{ text=>_loc('Start'), leaf=>\0, children=>\@tree }];
        if( $load_versions ) {
            my $rs = mdb->rule_version->find({ id_rule=>"$id_rule" })->sort({ ts=>-1 });
            my $current = $rs->next;
            my $text = ' was: '.$current->{was} if $current && $current->{was};
            @tree = ( 
                {   text => $current ? _loc('Current: %1 (%2)', $current->{ts}, $current->{username}).$text : _loc('Current'), 
                    leaf=>\0, 
                    icon=>'/static/images/icons/history.png',
                    is_current=>\1, children=>[ @tree ]
                }

            );
            while( my $rv = $rs->next ) {
                my $ver_tree = try { Util->_decode_json($rv->{rule_tree}) } catch { +{} }; 
                my @ver_tree = Baseliner->model('Rules')->tree_format( @$ver_tree );
                my $text = _loc('Version: %1 (%2)', $rv->{ts}, $rv->{username} );
                $text .= ' was: '.$rv->{was} if $rv->{was};
                push @tree, +{ text=>$text, 
                    icon=>'/static/images/icons/history.png',
                    is_version=>\1, version_id=>''.$rv->{_id}, leaf=>\0, children=>\@ver_tree };
            } 
        }
        $c->stash->{json} =  \@tree;
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub config_to_data {
    my ($self, $config_keys ) = @_;

    my $data = {};
    for my $config_key ( _array( $config_keys ) ) {
        $data = { %$data, %{ config_get( $config_key ) || {} } };
    }
    return $data;
}

sub edit_key : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        my $key = $p->{key} or _fail 'Missing key parameter';
        my $r = $c->registry->get( $key ); 
        _fail _loc "Key %1 not found in registry", $key unless $r;
        my $form = $r->form;
        my $config = $r->config;
        my $params = $c->registry->get_params($key); 
        delete $params->{$_} for qw(data_gen dsl handler);  ## these are code ref
        my $config_data;
        if( $r->isa( 'BaselinerX::Type::Service' ) ) {
            # service
            #_fail _loc "Service '%1' does not have either a form or a config", $key unless $form || $config;
            if( $form || $config ) {
                $config_data = $self->config_to_data( $config );
            } elsif( $r->data ) {
                $config_data = $r->data;
            } else {
                $config_data = {};
            }
        } elsif ( $r->isa( 'BaselinerX::Type::Fieldlet' )){
            $config_data = $config ? $self->config_to_data( $config ) : {};
            $config_data = { %$config_data, %{ $r->data } } ;
            $config_data->{section_allowed} = $r->registry_node->param->{section_allowed};
        } else {
            # statement
            $config_data = $config ? $self->config_to_data( $config ) : {};
            $config_data = { %$config_data, %{ $r->data } } ;
        }
        $c->stash->{json} = { success=>\1, msg => 'ok', params=>$params, form=>$form, config=>$config_data };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub dsl : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    #_debug "\n\n" . $p->{stmts} . "\n\n";;
    my $stmts = _decode_json( $p->{stmts} ) if $p->{stmts};
    try {
        my $id_rule = $p->{id_rule};
        my $doc = mdb->rule->find_one({ id=>$id_rule },{ rule_tree=>0 }) // {};
        my $rule_type = $p->{rule_type} or _throw 'Missing parameter rule_type';
        my $data;
        if( $rule_type eq 'pipeline' ) {
            $data = {
                job_step   => 'CHECK',
                elements   => [],
                changesets => [], 
            };
        } elsif( $rule_type eq 'event' ) {
            my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
            my $event = $c->registry->get( $event_key );
            my $event_data = { map { $_ => '' } _array( $event->vars ) };
            $data = $event_data;
        } else {
            # loose rule 
            $data = {};
        }
        my $dsl = $c->model('Rules')->dsl_build( $stmts, id_rule=>"temp_$id_rule", rule_name=>$$doc{rule_name} ); 
        $c->stash->{json} = { success=>\1, dsl=>$dsl, data_yaml => _dump( $data ) };
    } catch {
        my $err = shift; _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub run_rule : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_rule = $p->{id_rule} // _fail('Missing id_rule');
    my $stash = $p->{stash};
    
    my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule=>$id_rule, stash=>$stash );

    $c->stash->{json} = { stash=>$stash, ret=>$ret_rule };
    $c->forward("View::JSON");
}

sub dsl_try : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $dsl = $p->{dsl} or _throw 'Missing parameter dsl';
    my $stash = $p->{stash} ? _load( $p->{stash} ) : {};
    $c->stash->{json} = $self->dsl_run($dsl,$stash);
    $c->forward("View::JSON");
}

sub dsl_run {
    my ($self,$dsl,$stash) = @_;
    my $output;
    local $Baseliner::no_log_color = 1;
    return try {
        my $dslerr;
        require Capture::Tiny;
        _log "============================ DSL TRY START ============================";
        ($output) = Capture::Tiny::tee_merged(sub{
            try {
                $stash = Baseliner->model('Rules')->dsl_run( dsl=>$dsl, stash=>$stash );
            } catch {
               $dslerr = shift;   
            };
        });
        _log "============================ DSL TRY END   ============================";
        my $stash_yaml = _dump( $stash );
        if( $dslerr ) {
            _fail "ERROR DSL TRY: $dslerr";
        }
        #$stash = Util->_unbless( $stash );
        return { success=>\1, msg=>'ok', output=>$output, stash_yaml=>$stash_yaml };
    } catch {
        my $err = shift; _error $err;
        my $stash_yaml = _dump( $stash );
        return { success=>\0, msg=>$err, output=>$output, stash_yaml=>$stash_yaml };
    };
}

=head2 default

Soap webservices.

=cut

sub rule_from_url {
    my ($self,$id_rule)=@_;
    my $where = { rule_active => mdb->true,'$or'=>[ {id=>"$id_rule"}, {rule_name=>"$id_rule"}] };
    my $rule = mdb->rule->find_one($where,{ rule_tree=>0 }) or _fail _loc 'Rule %1 not found', $id_rule;
    return $rule;
}

sub default : Path {
    my ($self,$c,$meth,$id_rule,@args) = @_;
    my $p = $c->req->params;
    $meth //= 'json';
    my $ret = {};
    my $username = $c->username;
    $p->{username} = $username;
    my $body_file = $c->req->body ? _file($c->req->body) : undef;
    my $body = $body_file && -e $body_file ? $body_file->slurp : '';
    my $uri = $c->req->uri;
    my $wsurl = sprintf '%s://%s%s', $uri->scheme, $uri->authority, $uri->path;  # http://www.perl.com:8080/xxx/yyy, everything minus the query & fragments
    my $stash = {
        ws_body      => $body,
        ws_headers   => Util->_clone( $c->req->headers ),
        ws_params    => Util->_clone($p),
        WSURL        => $wsurl,
        ws_arguments => \@args,
    };
    my $where = { '$or'=>[ {id=>"$id_rule"}, {rule_name=>"$id_rule"}] };
    my $run_rule = sub{
        try {
            my $rule = $self->rule_from_url( $id_rule );
            _fail _loc 'Rule %1 not independent or webservice: %2',$id_rule, $rule->{rule_type} if $rule->{rule_type} !~ /independent|webservice/ ;
            my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule=>$id_rule, stash=>$stash, contained=>1 );
            _debug( _loc( 'Rule WS Elapsed: %1s', $$stash{_rule_elapsed} ) );
            $ret = defined $stash->{ws_response} 
                ? $stash->{ws_response} 
                : ref $ret_rule->{ret} ? $ret_rule->{ret} : { output=>$ret_rule->{ret}, stash=>$stash };
        } catch {
            my $err = shift;
            my $json = try { Util->_encode_json($p) } catch { '{ ... }' };
            my $msg = "Error in Rule WS call '$id_rule/$meth': $json\n$err";
            _error $msg;
            event_new 'event.ws.rule_error', { msg=>$msg };
            # $ret = { msg=>"$err", success=>\0 }; 
            $ret = +{
                Fault => { faultcode => '999', faultstring => "$err", faultactor => "$wsurl", },
                _RETURN_CODE => 404,
                _RETURN_TEXT => 'sorry, not found'
          };
        };
        return $ret;
    };
    if( $meth eq 'soap' ) {
        my $doc = $self->rule_from_url( $id_rule );
        my $wsdl_body = Util->parse_vars( $doc->{wsdl}, $stash );
        $stash->{ws_operation} = $args[0];
        
        if( !length $body ) {
            # wsdl only
            $c->res->body( $wsdl_body );
        } else {
            # soap envelope received
            my $wsdl = $self->compile_wsdl($wsdl_body);
            my $daemon = XML::Compile::SOAP::Daemon::CGI->new();
            try {
                $daemon->operationsFromWSDL(
                    $wsdl,
                    default_callback => sub {
                        my ($soap, $request_data, $cgi_request) = @_;
                        if( ref $request_data eq 'HASH' ) {
                            # if we have SOAP:Header, may break parse_vars with toString errors, 
                            #   so strip out '{xxxx}' keys used by the LibXML soap header translation
                            #   SOAP:Header could be included in the wsdl, but that's not its place:
                            #   http://stackoverflow.com/questions/5726127/adding-soap-implicit-headers-to-wsdl
                            #   the recommendation: strip header data out, so we do it:
                            my %rr = map { $_ => $$request_data{$_} } 
                                grep !/^\{/, keys %$request_data;
                            $stash->{ws_request} = \%rr;
                        } else {
                            $stash->{ws_request} = $request_data;
                        }
                        my $res = $run_rule->();  # typically ws_response
                        if( ref $res eq 'HASH' && exists $$res{Fault} ) {
                            # in case of error, add soap role, ie 'http://schemas.xmlsoap.org/soap/actor/next';
                            $$res{Fault}{faultactor} = $soap->role;
                        }
                        return $res;
                    },
                );
                # no warnings zone
                {
                    my @warns;
                    # store warnings for later
                    local $SIG{__WARN__} = sub { push @warns, @_; };
                    
                    # run the WSDL in CGI mode
                    $self->cgi_to_response($c, sub {
                        my $query = CGI->new;
                        $daemon->runCgiRequest(query => $query);
                    }); 
                
                    # call event
                    my $body = $c->res->body;
                    my $ev_data = { soap_body=>"$body" };
                    my $event_stash = event_new 'event.ws.soap_ready' => $ev_data;
                    $c->res->body( $event_stash->{soap_body} );
                    
                    # print WS warnings now
                    _warn _loc('SOAP WS warnings detected: %1', join("\n",@warns)) if @warns;
                }
            } catch {
                my $err = shift;
                if( ref $err eq 'Log::Report::Exception' ) {
                    my $msg = sprintf('%s in %s', $$err{message}{_msgid}, $$err{message}{name});
                    event_new 'event.ws.soap_error' => { msg=>$msg };
                    require XML::Simple;
                    $c->res->body( XML::Simple::XMLout({ error=>$msg, raw=>"$err", message=>$$err{message} }, RootName=>'clarive') );
                } else {
                    my $msg = _loc( 'Error setting up WSDL operations: %1', $err );
                    event_new 'event.ws.wsdl_error' => { msg=>$msg };
                    require XML::Simple;
                    $c->res->body( XML::Simple::XMLout({ error=>$msg }, RootName=>'clarive') );
                }
                $c->res->status(500);
            };
            
        }
         
    } else {
        $run_rule->();
        if( $meth eq 'json' ) {
            $c->stash->{json} = ref $ret ? $ret : {};
            $c->forward('View::JSON');
        } elsif( $meth eq 'yaml' ) {
            $c->res->body( Util->_dump($ret) );
        } elsif( $meth eq 'xml' ) {
            require XML::Simple;
            $c->res->body( XML::Simple::XMLout($ret, RootName=>'clarive') );
            $c->res->content_type("text/xml; charset=utf-8");
        } else {
            $c->res->body( $ret );
        }
    }
}

sub tree_structure : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $p->{destination} = 'tree';
    my @rules = Baseliner->model('Rules')->get_rules_info($p); 
    $c->stash->{json} = \@rules;
    $c->forward( 'View::JSON' );
}

sub add_custom_folder : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    my $folder_name = $p->{folder_name};
    $p->{username} = $c->username;
    $c->stash->{json} = try {
        my $ret = Baseliner->model('Rules')->add_custom_folder($p);
        { success=>\1, msg=>_loc('Rule folder %1 added successfully', $folder_name), data=>$ret };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error adding rule folder: %1', $err) };
    };
    $c->forward( 'View::JSON' );
}

sub rename_rule_folder : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    my $folder_name = $p->{folder_name};
    $p->{username} = $c->username;
    $c->stash->{json} = try {
        Baseliner->model('Rules')->rename_rule_folder($p);
        { success=>\1, msg=>_loc('Rule folder %1 renamed successfully', $folder_name) };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error renaming rule folder: %1', $err) };
    };
    $c->forward( 'View::JSON' );
}

sub delete_rule_folder : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $c->stash->{json} = try {
        Baseliner->model('Rules')->delete_rule_folder($p);
        { success=>\1, msg=>_loc('Rule folder %1 deleted successfully', $p->{rule_folder_id}) };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error deleting rule folder: %1', $err) };
    };
    $c->forward( 'View::JSON' );
}

sub added_rule_to_folder : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $c->stash->{json} = try {
        Baseliner->model('Rules')->added_rule_to_folder($p);
        { success=>\1, msg=>_loc('Rule %1 addeded successfully', $p->{rule_id}) };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error adding rule to folder: %1', $err) };
    };
    $c->forward( 'View::JSON' );
}

sub delete_rule_from_folder : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $c->stash->{json} = try {
        Baseliner->model('Rules')->delete_rule_from_folder($p);
        { success=>\1, msg=>_loc('Rule %1 deleted from folder %2 successfully', $p->{rule_id}, $p->{rule_folder_id}) };
    } catch {
        my $err = shift;
        { success=>\0, msg=>_loc('Error deleting rule from folder: %1', $err) };
    };
    $c->forward( 'View::JSON' );   
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
