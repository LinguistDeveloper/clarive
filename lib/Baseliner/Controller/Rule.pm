package Baseliner::Controller::Rule;
use Baseliner::Plug;
use Baseliner::Utils qw(:basic _decode_json _strip_html);
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use Time::HiRes qw(time);
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }
BEGIN { extends 'Catalyst::Controller::WrapCGI' }

register 'action.admin.rules' => { name=>'Admin Rules' };

register 'menu.admin.rule' => {
    label    => 'Rules',
    title    => _loc ('Rules'),
    action   => 'action.admin.rules',
    url_comp => '/comp/rules.js',
    icon     => '/static/images/icons/rule.png',
    tab_icon => '/static/images/icons/rule.png'
};


sub list : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    my @rows = mdb->rule->find({ rule_active=>'1' })->sort({ rule_name=>1 })->fields({ rule_tree=>0 })->all;
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
        my $row = mdb->rule->find_one({ id=>"$id_rule" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        $row->{rule_tree} = $row->{rule_tree} ? _decode_json($row->{rule_tree}) : [];
        my $yaml = _dump($row);
        $c->stash->{json} = { success=>\1, yaml=>$yaml };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub import : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $data = $p->{data};
    my $type = $p->{type};
    _fail _loc('Missing data') if !length $data;
    
    try {
        my $rule = $type eq 'yaml' ? _load( $data ) : {} ;
        delete $rule->{id};
        delete $rule->{rule_id};
        my $doc = mdb->rule->find_one({ rule_name=>$rule->{rule_name} });
        if( $doc ) {
            $rule->{rule_name} = sprintf '%s (%s)', $rule->{rule_name}, _now();
        }
        $rule->{rule_tree} = Util->_encode_json($rule->{rule_tree});
        $rule->{id} = mdb->seq('rule');
        $rule->{rule_seq} = 0+ mdb->seq('rule_seq');
        $rule->{rule_active} = '1';
        mdb->rule->insert($rule);
        $c->stash->{json} = { success=>\1, name=>$rule->{rule_name} };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub delete : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        my $row = mdb->rule->find_one({ id=>"$p->{id_rule}" });
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        my $name = $row->{rule_name};
        mdb->rule->remove({ id=>"$p->{id_rule}" },{ multiple=>1 });
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
        $doc->{chain_default} = $doc->{rule_type} eq 'chain' ? $doc->{rule_when} : '-';
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
    $c->stash->{json} = { data => [ sort { uc $a->{ev_name} cmp uc $b->{ev_name} } @rows ], totalCount=>scalar @rows };
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
    my @rules = mdb->rule->find->fields({ rule_tree=>0 })->sort( mdb->ixhash( rule_seq=>-1, _id=>-1 ) )->all;
    @rules = map {
        $_->{event_name} = $c->registry->get( $_->{rule_event} )->name if $_->{rule_event};
        $_
    } @rules;
    @rules = grep { join(',',values %$_) =~ qr/$p->{query}/i } @rules if length $p->{query}; 
    $c->stash->{json} = { totalCount=>scalar(@rules), data => \@rules };
    $c->forward("View::JSON");
}

sub save : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->params;
    my $data = {
        rule_active => '1',
        rule_name  => $p->{rule_name},
        rule_when  => ( $p->{rule_type} eq 'chain' 
            ? $p->{chain_default}  
            : $p->{rule_when} ),
        rule_event => $p->{rule_event},
        rule_type  => $p->{rule_type},
        rule_desc  => substr($p->{rule_desc},0,2000),
        subtype => $p->{subtype},
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
    my @control = sort { $a->{text} cmp $b->{text} } 
        grep { !$query || join(',',%$_) =~ $query } 
        map {
        my $key = $_;
        my $s = $c->registry->get( $key );
        my $n= { palette => 1 };
        my $type = $types{ $s->{type} };
        my $parse_path = "/static/images/icons/$s->{type}.gif";
        $n->{holds_children} = defined $s->{holds_children} ? \($s->{holds_children}) : \1;
        $n->{leaf} = \1;
        $n->{key} = $key;
        $n->{text} = $s->{text} // $key;
        $n->{nested} = $s->{nested} // 0;
        $n->{icon} = $s->icon // $parse_path;
        $n;
    } 
    Baseliner->registry->starts_with( 'statement.' );
    push @tree, {
        icon     => '/static/images/icons/control.gif',
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
          grep { !$query || join(',', values %$_) =~ $query }
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
        icon => '/static/images/icons/service.png',
        draggable => \0,
        expanded => length $query ? \1 : \0,
        children=> [ 
          sort { uc $a->{text} cmp uc $b->{text} }
          grep { !$query || join(',', values %$_) =~ $query }
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

    my @rules = mdb->rule->find->sort( mdb->ixhash( rule_seq=>1, _id=>-1) )->all; 
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
    $c->stash->{json} = \@tree;
    $c->forward("View::JSON");
}

sub stmts_save : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $returned_ts;
    my $error_checking_dsl = 0;
    try {
        my $id_rule = $p->{id_rule} or _throw 'Missing rule id';
        # check json valid
        my $stmts = try { 
            _decode_json( $p->{stmts} );
        } catch {
            _fail _loc "Corrupt or incorrect json rule tree: %1", shift(); 
        };
        # check if DSL is buildable
        try { 
            $c->model('Rules')->dsl_build_and_test( $stmts ); 
        } catch {
            $error_checking_dsl = 1; 
            return if $p->{ignore_dsl_errors};
            _fail _loc "Error testing DSL build: %1", shift(); 
        };
        $returned_ts = $self->save_rule( id_rule=>$id_rule, stmts_json=>$p->{stmts}, username=>$c->username, old_ts => $p->{old_ts} );
        my $old_ts = $returned_ts->{old_ts};
        my $actual_ts = $returned_ts->{actual_ts};
        my $previous_user = $returned_ts->{previous_user};
        if ($returned_ts->{old_ts} ne ''){
            $c->stash->{json} = { success=>\1, msg => _loc('Rule statements saved ok'), old_ts => $old_ts, actual_ts=> $actual_ts, username=>$c->username };
        } else {
            $c->stash->{json} = { success=>\1, msg => _loc('An other user changed rule statements during edition process!'), old_ts => $old_ts, actual_ts=> $actual_ts, username=> $previous_user };
        }
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => "$err", error_checking_dsl=>$error_checking_dsl };
    };
    $c->forward("View::JSON");
}

##################################################################################
sub get_rule_ts : Local{
    my ($self,$c)=@_;
    my $p = $c->req->params;
    try {
        _log _dump $p;
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
    my $actual_timestamp = mdb->rule->find({ id => ''.$p{id_rule}})->next->{ts};
    my $previous_user = mdb->rule->find({ id => ''.$p{id_rule}})->next->{username};
    if (!$actual_timestamp and !$previous_user){
        $actual_timestamp = $old_timestamp;
        $previous_user = $p{username};
        mdb->rule->update({ id =>''.$p{id_rule} }, { '$set'=> { ts => $actual_timestamp, username => $previous_user } } ); 
    }
    $ts_modified = ''.$old_timestamp ne ''.$actual_timestamp || $p{username} ne $previous_user;
    if ( $ts_modified ){
        $old_timestamp = '';
    }else{
        $old_timestamp = mdb->ts;
        mdb->rule->update({ id=>''.$p{id_rule} }, { '$set'=> { ts => $old_timestamp, username => $p{username}, rule_tree=>$p{stmts_json} } } );
        # now, version
        # check if collection exists
        if( ! mdb->collection('system.namespaces')->find({ name=>qr/rule_version/ })->count ) {
            mdb->create_capped( 'rule_version' );
        }
        delete $doc->{_id};
        mdb->rule_version->insert({ %$doc, ts=>mdb->ts, username=>$p{username}, id_rule=>$p{id_rule}, rule_tree=>$p{stmts_json}, was=>($p{was}//'') });    
    }
    { old_ts => $old_timestamp, actual_ts => $actual_timestamp, previous_user => $previous_user };
}

sub rollback_version : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $version_id = $p->{version_id};
    my $ver = mdb->rule_version->find_one({ _id=>mdb->oid($version_id) });
    _fail _loc 'Version not found: %1', $version_id unless $ver;
    try {
        $self->save_rule( id_rule=>$ver->{id_rule}, stmts_json=>$ver->{rule_tree}, username=>$ver->{username}, was=>$ver->{ts} );
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
                my $ver_tree = Util->_decode_json($rv->{rule_tree}); 
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
        } else {
            # statement
            $config_data = $config ? $self->config_to_data( $config ) : {};
            $config_data = { %$config_data, %{ $r->data } } ;
        }
        $c->stash->{json} = { success=>\1, msg => 'ok', form=>$form, config=>$config_data };
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
        my $rule_type = $p->{rule_type} or _throw 'Missing parameter rule_type';
        my $data;
        if( $rule_type eq 'chain' ) {
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
        my $dsl = $c->model('Rules')->dsl_build( $stmts ); 
        $c->stash->{json} = { success=>\1, dsl=>$dsl, data_yaml => _dump( $data ) };
    } catch {
        my $err = shift; _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
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

sub default : Path Args(2) {
    my ($self,$c,$id_rule,$meth) = @_;
    my $p = $c->req->params;
    $meth //= 'json';
    my $ret = {};
    my $body_file = $c->req->body ? _file($c->req->body) : undef;
    my $body = $body_file && -e $body_file ? $body_file->slurp : '';
    my $stash = { ws_body=>$body, ws_headers=>Util->_clone($c->req->headers), ws_params=>Util->_clone($p), };
    my $where = { '$or'=>[ {id=>"$id_rule"}, {rule_name=>"$id_rule"}] };
    my $run_rule = sub{
        try {
            my $rule = mdb->rule->find_one($where,{ rule_type=>1 }) or _fail _loc 'Rule %1 not found', $id_rule;
            _fail _loc 'Rule %1 not independent: %2',$id_rule, $rule->{rule_type} if $rule->{rule_type} ne 'independent' ;
            my $ret_rule = Baseliner->model('Rules')->run_single_rule( id_rule=>$id_rule, stash=>$stash );
            $ret = defined $stash->{ws_return} 
                ? $stash->{ws_return} 
                : ref $ret_rule->{ret} ? $ret_rule->{ret} : { output=>$ret_rule->{ret}, stash=>$stash };
        } catch {
            my $err = shift;
            my $json = try { Util->_encode_json($p) } catch { '{ ... }' };
            _error "Error in Rule WS call '$id_rule/$meth': $json\n$err";
            $ret = { msg=>"$err", success=>\0 }; 
        };
        return $ret;
    };
    if( $meth eq 'soap' ) {
        my $doc = mdb->rule->find_one($where); 
        my $wsdl_body = $doc->{wsdl};
        if( !length $body ) {
            # wsdl only
            $c->res->body( $wsdl_body );
        } else {
            # soap envelope received
            require XML::Compile::SOAP11;
            require XML::Compile::SOAP::Daemon::CGI;
            require XML::Compile::WSDL11;
            require XML::Compile::SOAP::Util;
            my $wsdl = XML::Compile::WSDL11->new($wsdl_body);
            my $daemon = XML::Compile::SOAP::Daemon::CGI->new();
            $daemon->operationsFromWSDL(
                $wsdl,
                default_callback => sub {
                    my ($soap, $data_in, $request) = @_;
                    $stash->{ws_request} = $request;
                    $stash->{ws_data}    = $data_in;
                    return $run_rule->();
                },
            );
            $self->cgi_to_response($c, sub {
                my $query = CGI->new;
                $daemon->runCgiRequest(query => $query);
            }); 
             
        }
         
    } else {
        $run_rule->();
        if( $meth eq 'json' ) {
            $c->stash->{json} = $ret;
            $c->forward('View::JSON');
        } elsif( $meth eq 'yaml' ) {
            $c->res->body( Util->_dump($ret) );
        } elsif( $meth eq 'xml' ) {
            require XML::Simple;
            $c->res->body( XML::Simple::XMLout($ret) );
            $c->res->content_type("text/xml; charset=utf-8");
        } else {
            $c->res->body( $ret );
        }
    }
}

1;
