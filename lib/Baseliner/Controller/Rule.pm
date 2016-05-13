package Baseliner::Controller::Rule;
use Moose;
BEGIN {  extends 'Catalyst::Controller::WrapCGI' }

use Capture::Tiny ();
use Try::Tiny;
use Time::HiRes qw(time);
use v5.10;
use BaselinerX::CI::variable;
use Baseliner::RuleRunner;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Model::Rules;
use Baseliner::Utils;
use Baseliner::Sugar;

with 'Baseliner::Role::ControllerValidator';

my %RULE_ICONS = (
    dashboard  => Util->icon_path('dashboard.svg'),
    form       => Util->icon_path('form.svg'),
    event      => Util->icon_path('event.svg'),
    report     => Util->icon_path('report.svg'),
    pipeline   => Util->icon_path('job.svg'),
    workflow   => Util->icon_path('workflow.svg'),
    webservice => Util->icon_path('webservice.svg'),
);

register 'action.admin.rules' => {
    name   => _locl('Admin Rules'),
    bounds => [
        {
            key     => 'id_rule',
            name    => _locl('Rule'),
            handler => 'Baseliner::Model::Rules=list_rules'
        }
    ]
};

register 'config.rules' => {
    metadata => [
        {   id      => 'auto_rename_vars',
            name    => _locl('Auto rename variables in rules'),
            type    => 'text',
            default => '0',
            label   => _locl('CAUTION: If activated, variable names will be changed in rules when renamed in CIs. USE AT YOUR OWN RISK')
        }
    ]
};

register 'menu.admin.rule' => {
    label    => 'Rule Designer',
    title    => _locl('Rule Designer'),
    actions  => [ { action => 'action.admin.rules', bounds => '*' } ],
    url_comp => '/comp/rules.js',
    icon     => '/static/images/icons/rule.svg',
    tab_icon => '/static/images/icons/rule.svg'
};

register 'event.ws.soap_ready' => {
    text => _locl('SOAP WS ready to return'),
    description => _locl('SOAP WS is ready'),
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
             $c->stash->{api_key_authentication} = 1;
         }
     }
}

sub list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $qry = $p->{query};
    my %query;

    $query{rule_active} = mdb->true;
    $query{rule_type}   = mdb->in( $p->{rule_type} ) if ( $p->{rule_type} );
    $query{rule_name}   = qr/$qry/i if length $qry && !$p->{valuesqry};

    my @rows = mdb->rule->find( {%query} )->sort( { rule_name => 1 } )->fields( { rule_tree => 0 } )->all;

    @rows = map {
        $_->{icon} = $RULE_ICONS{ $_->{rule_type} } // Util->icon_path('rule.svg');
        $_;
    } @rows;

    $c->stash->{json} = { data => \@rows, totalCount => scalar(@rows) };
    $c->forward('View::JSON');
}


sub actions : Local {
    my ($self,$c)=@_;
    my $list = Baseliner::Core::Registry->starts_with( 'service' ) ;
    my $p = $c->req->params;
    my @tree;
    my $field = $p->{field} || 'name';
    push @tree, (
        { id=>'service.email.send', text=>_loc('Send notification by email') }
    );
    foreach my $key ( Baseliner::Core::Registry->starts_with( 'service' ) ) {
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
        my $name = Baseliner->model('Rules')->delete_rule( username => $c->username, id_rule => $p->{id_rule} );
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
    foreach my $key ( Baseliner::Core::Registry->starts_with( 'event' ) ) {
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
    my @rules = mdb->rule->find->fields({ rule_tree=>0 })->all;
    my $cnt = 1;
    for my $rule ( @rules ) {
        push @tree,
          {
            id => $cnt++,
            leaf => \0,
            icon => '/static/images/icons/rule.svg',
            text => $rule->{rule_name},
          };
    }
    @tree = () if $p->{node} > 0;
    $c->stash->{json} = \@tree;
    $c->forward("View::JSON");
}

sub grid : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    $p->{destination} = 'grid';
    $p->{username} = $c->username;

    my @rules = Baseliner::Model::Rules->new->get_rules_info($p);

    @rules = map {
        $_->{icon} = $RULE_ICONS{ $_->{rule_type} } // Util->icon_path('rule.svg');
        $_;
    } @rules;

    $c->stash->{json} = { totalCount => scalar(@rules), data => \@rules };
    $c->forward("View::JSON");
}

sub save : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->params;
    try {
        my $res = Baseliner::Model::Rules->new->save_rule( %$p, username => $c->username );
        $c->stash->{json} = { success => \1, msg => _loc('Rule %1 saved', $res->{rule_name}) };
    } catch {
        my $err = shift;
        my $msg = _loc('Error saving rule: %1', $err );
        _error( $msg );
        $c->stash->{json} = { success => \0, msg => $msg };
    };
    $c->forward("View::JSON");
}

sub palette : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $query = $p->{query};

    my @tree;
    my $cnt = 1;

    my $if_icon = '/static/images/icons/if.svg';
    my %types   = (
        if  => { icon => $if_icon },
        let => { icon => $if_icon },
        for => { icon => $if_icon },
    );

    my @statements = Baseliner::Core::Registry->starts_with('statement.');
    my @dashlets   = Baseliner::Core::Registry->starts_with('dashlet.');
    my @services   = Baseliner::Core::Registry->starts_with('service.');
    my @fieldlets  = grep { $_ !~ /required/ } Baseliner::Core::Registry->starts_with('fieldlet.');
    my @rules      = mdb->rule->find->fields( { id => 1, rule_name => 1 } )->all;

    my @ops;
    for my $key ( @statements, @dashlets, @services, @fieldlets ) {

        my $reg = Baseliner::Core::Registry->get($key);
        next unless $reg->show_in_palette;

        ( my $name = $key ) =~ s{\.}{-}g;

        my $op = {
            key            => $key,
            text           => $reg->{name} // $reg->{text} // $key,
            isTarget       => \( $reg->{holds_children} ),
            holds_children => \( $reg->{holds_children} ),
            leaf           => \1,
            icon           => $reg->{icon},
            html           => $reg->{html},
            palette        => \1,
            palette_area   => ( $reg->{job_service} ? 'job' : $reg->palette_area ),
            cls            => "ui-comp-palette-$name",
        };

        if ( $key =~ /^statement\./ ) {
            $op->{run_sub}    = $reg->{run_sub} // \1;
            $op->{on_drop}    = !!$reg->{on_drop};
            $op->{on_drop_js} = $reg->{on_drop_js};
            $op->{nested}     = $reg->{nested} // 0;
            $op->{icon}       = $reg->icon // (
                !$reg->{type}
                ? '/static/images/icons/help.svg'
                : do {
                    my $type = $types{ $reg->{type} };
                    "/static/images/icons/$reg->{type}.svg";
                  }
            );
        }
        push @ops, $op;
    }

    # add rules from database directly as nodes
    push @ops, map {
        +{
            key            => 'statement.call',
            icon           => '/static/images/icons/rule.svg',
            text           => $_->{rule_name},
            isTarget       => \0,
            holds_children => \0,
            leaf           => \1,
            palette_area   => 'rule',
            id_rule        => $_->{id},
            data           => { id_rule => $_->{id} },
          }
    } @rules;

    # sorting and querying
    @ops = sort { uc $a->{text} cmp uc $b->{text} } (
        $query
        ? Util->query_grep( query => $query, all_fields => 1, rows => \@ops )
        : @ops
    );

    # now build the tree groups
    push @tree,
      {
        text      => _loc('Control'),
        icon      => '/static/images/icons/controller.svg',
        draggable => \0,
        expanded  => \1,
        isTarget  => \0,
        leaf      => \0,
        children  => [ grep { $_->{palette_area} eq 'control' } @ops ],
      };

    push @tree,
      {
        text      => _loc('Workflow'),
        leaf      => \0,
        icon      => '/static/images/icons/workflow.svg',
        draggable => \0,
        expanded  => \1,
        children  => [ grep { $_->{palette_area} eq 'workflow' } @ops ],
      };

    push @tree,
      {
        text      => _loc('Generic'),
        leaf      => \0,
        icon      => '/static/images/icons/wrench.svg',
        draggable => \0,
        expanded  => length $query ? \1 : \0,
        children => [ grep { $_->{palette_area} eq 'generic' } @ops ],
      };

    push @tree,
      {
        text      => _loc('Job'),
        leaf      => \0,
        icon      => '/static/images/icons/job.svg',
        draggable => \0,
        expanded  => \1,
        children  => [ grep { $_->{palette_area} eq 'job' } @ops ],
      };

    push @tree,
      {
        text      => _loc('Dashlets'),
        leaf      => \0,
        icon      => '/static/images/icons/dashboard.svg',
        draggable => \0,
        expanded  => \1,
        children  => [ grep { $_->{palette_area} eq 'dashlet' } @ops ],
      };

    my $fieldlet_icon = '/static/images/icons/detail.svg';
    push @tree, {
        text      => _loc('Fieldlets'),
        id        => $cnt++,
        leaf      => \0,
        icon      => $fieldlet_icon,
        draggable => \0,
        expanded  => \1,
        children  => [
            map {
                my $n = $_;
                $n->{icon} //= $fieldlet_icon;
                $n->{active} = \1;
                $n
              }
              grep { $_->{palette_area} eq 'fieldlet' } @ops
        ]
    };

    push @tree,
      {
        text      => _loc('Rules'),
        leaf      => \0,
        icon      => '/static/images/icons/rule.svg',
        draggable => \0,
        expanded  => \1,
        children  => [ grep { $_->{palette_area} eq 'rule' } @ops ],
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
                Baseliner::Core::Registry->reload_all;
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
    my $doc = mdb->rule->find_one({ id=>''.$id_rule }) // _fail _loc('Rule id %1 missing. Deleted?', $id_rule);
    my $ignore_dsl_errors = $p->{ignore_dsl_errors} || $$doc{ignore_dsl_errors};
    # check json valid
    my $stmts = try {
        _decode_json( $p->{stmts} );
    } catch {
        _fail _loc("Corrupt or incorrect json rule tree: %1", shift());
    };

    my $ts = mdb->ts;
    #_debug $stmts;
    # check if DSL is buildable
    my $rule_runner = Baseliner::RuleRunner->new;
    my $detected_errors = try {
        my $dsl = $rule_runner->dsl_build_and_test( $stmts, id_rule=>$id_rule, ts=>$ts );
        _debug "Caching rule $id_rule for further use";
        mdb->grid->remove({id_rule=> "$id_rule"});
        mdb->grid_insert( $dsl ,id_rule => $id_rule );
        return '';
    } catch {
        my $err = shift;
        _warn( $err );
        $error_checking_dsl = 1;
        return $err if $ignore_dsl_errors;
        _fail _loc("Error testing DSL build: %1", $err);
    };
    $returned_ts = Baseliner::Model::Rules->new->write_rule( id_rule=>$id_rule, stmts_json=>$p->{stmts}, username=>$p->{username}, ts=>$ts, old_ts=>$p->{old_ts},
        detected_errors   => $detected_errors,  # useful in case we want to warn user before doing something with this broken rule
        ignore_dsl_errors =>( $$p{ignore_error_always} ? '1' : undef ) );
    return ($detected_errors,$returned_ts,$error_checking_dsl);
}

##################################################################################
sub get_rule_ts : Local{
    my ($self,$c)=@_;
    my $p = $c->req->params;
    my $id_rule = $p->{id_rule} or _fail _loc('id_rule is not passed');
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

sub rollback_version : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    my $version_id = $p->{version_id};

    my $ver = mdb->rule_version->find_one( { _id => mdb->oid($version_id) } );
    _fail _loc('Version not found: %1', $version_id) unless $ver;

    try {
        Baseliner::Model::Rules->new->write_rule(
            id_rule    => $ver->{id_rule},
            stmts_json => $ver->{rule_tree},
            username   => $ver->{username},
            was        => $ver->{ts},
            old_ts     => $ver->{ts}
        );
        $c->stash->{json} = { success => \1, msg => _loc( 'Rule rollback to %1 (%2)', $ver->{ts}, $ver->{username} ) };
    }
    catch {
        my $err = shift;

        _error $err;
        chomp($err);

        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub tag_version : Local {
    my ( $self, $c ) = @_;

    return
      unless my $p = $self->validate_params(
        $c,
        version_id => { isa => 'Str' },
        tag        => { isa => 'Str' }
      );

    my $version_id = $p->{version_id};
    my $tag        = $p->{tag};

    my $rules = Baseliner::Model::Rules->new;

    try {
        $rules->tag_version(version_id => $version_id, version_tag => $tag);

        $c->stash->{json} = { success => \1, msg => _loc('Rule version tagged') };
    } catch {
        my $error = shift;

        $c->stash->{json} = { success => \0, msg => 'Validation failed', errors => { tag => $error } };
        $c->forward("View::JSON");
    };

    $c->forward("View::JSON");
}

sub untag_version : Local {
    my ( $self, $c ) = @_;

    return
      unless my $p = $self->validate_params( $c, version_id => { isa => 'Str' } );

    my $version_id = $p->{version_id};

    my $rules = Baseliner::Model::Rules->new;

    $rules->untag_version(version_id => $version_id);

    $c->stash->{json} = { success => \1, msg => _loc('Rule version untagged') };
    $c->forward("View::JSON");
}

sub stmts_load : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    my $id_rule       = $p->{id_rule};
    my $load_versions = $p->{load_versions};

    try {
        _throw 'Missing rule id' unless $id_rule;

        my @tree = Baseliner::Model::Rules->new->build_tree( $id_rule, undef );

        if ($load_versions) {
            my $rs      = mdb->rule_version->find( { id_rule => "$id_rule" } )->sort( { ts => -1 } );
            my $current = $rs->next;
            my $text = '';
            $text = ' was: ' . $current->{was} if $current && $current->{was};
            @tree = (
                {
                    text => $current
                    ? _loc( 'Current: %1 (%2)', $current->{ts}, $current->{username} ) . $text
                    : _loc('Current'),
                    leaf       => \0,
                    icon       => '/static/images/icons/slot.svg',
                    is_current => \1,
                    children   => [@tree]
                }

            );

            while ( my $rv = $rs->next ) {
                my @ver_tree = Baseliner::Model::Rules->new->load_tree( rule => $rv );

                my $text = _loc( 'Version: %1 (%2)', $rv->{ts}, $rv->{username} );
                $text .= " [ $rv->{version_tag} ]" if $rv->{version_tag};
                $text .= ' was: ' . $rv->{was} if $rv->{was};
                push @tree,
                  +{
                    text        => $text,
                    icon        => '/static/images/icons/slot.svg',
                    is_version  => \1,
                    version_id  => '' . $rv->{_id},
                    version_tag => $rv->{version_tag} // '',
                    leaf        => \0,
                    children    => \@ver_tree
                  };
            }
        }

        $c->stash->{json} = \@tree;
    }
    catch {
        my $err = shift;

        _error $err;

        chomp $err;

        $c->stash->{json} = { success => \0, msg => $err };
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
        my $r = Baseliner::Core::Registry->get( $key );
        _fail _loc("Key %1 not found in registry", $key) unless $r;
        my $form = $r->form;
        my $config = $r->config;
        my $params = Baseliner::Core::Registry->get_params($key);
        delete $params->{$_} for qw(data_gen dsl handler);  ## these are code ref
        my $config_data;
        if( $r->isa( 'BaselinerX::Type::Service' ) ) {
            # service
            #_fail _loc("Service '%1' does not have either a form or a config", $key) unless $form || $config;
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
    my ($self, $c)=@_;

    my $p = $c->req->params;

    my $id_rule   = $p->{id_rule};
    my $rule_type = $p->{rule_type} or _throw 'Missing parameter rule_type';
    my $stmts     = $p->{stmts};

    $stmts = _decode_json( $stmts ) if $stmts;

    try {
        my $doc = mdb->rule->find_one({ id=>$id_rule },{ rule_tree=>0 }) // {};
        my $data;
        if( $rule_type eq 'pipeline' ) {
            $data = {
                job_step   => 'CHECK',
                elements   => [],
                changesets => [],
            };
        } elsif( $rule_type eq 'event' ) {
            my $event_key = $p->{event_key} or _throw 'Missing parameter event_key';
            my $event = Baseliner::Core::Registry->get( $event_key );
            my $event_data = { map { $_ => '' } _array( $event->vars ) };
            $data = $event_data;
        } else {
            # loose rule
            $data = {};
        }
        my $dsl = Baseliner::Model::Rules->new->dsl_build( $stmts, id_rule=>"temp_$id_rule", rule_name=>$$doc{rule_name} );
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

    my $rule_runner = Baseliner::RuleRunner->new;
    my $ret_rule = $rule_runner->find_and_run_rule( id_rule=>$id_rule, stash=>$stash );

    $c->stash->{json} = { stash=>$stash, ret=>$ret_rule };
    $c->forward("View::JSON");
}

sub dsl_try : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    my $dsl = $p->{dsl} or _throw 'Missing parameter dsl';
    my $stash = $p->{stash} ? _load( $p->{stash} ) : {};

    my $success = \1;
    my $msg     = 'ok';

    local $Baseliner::no_log_color = 1;

    my $rule_runner = Baseliner::RuleRunner->new;

    my $ret_rule = try {
        $rule_runner->run_dsl( dsl => $dsl, stash => $stash );
    }
    catch {
        my $error = $_;

        $success = \0;
        $msg = $error;

        return;
    };

    my $output = $ret_rule ? $ret_rule->{output} : '';

    my $stash_yaml = _dump( $stash );

    $c->stash->{json} = {
        success    => $success,
        msg        => $msg,
        output     => $output,
        stash_yaml => $stash_yaml
    };
    $c->forward("View::JSON");
}

=head2 default

Soap webservices.

=cut

sub rule_from_url {
    my ($self,$id_rule)=@_;
    my $where = { rule_active => mdb->true,'$or'=>[ {id=>"$id_rule"}, {rule_name=>"$id_rule"}] };
    my $rule = mdb->rule->find_one($where,{ rule_tree=>0 }) or _fail _loc('Rule %1 not found', $id_rule);
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
        ws_uploads   => Util->_clone($c->req->uploads),
        WSURL        => $wsurl,
        ws_arguments => \@args,
    };
    my $where = { '$or'=>[ {id=>"$id_rule"}, {rule_name=>"$id_rule"}] };
    my $run_rule = sub{
        my $rule = $self->rule_from_url( $id_rule );
        _fail _loc('Rule %1 not independent or webservice: %2',$id_rule, $rule->{rule_type}) if $rule->{rule_type} !~ /independent|webservice/ ;

        my $rule_runner = Baseliner::RuleRunner->new;
        event_new 'event.rule.ws', {
            username  => $username,
            rule_id   => $rule->{id},
            rule_name => $rule->{rule_name},
            rule_type => $rule->{rule_type},
            ws_params => $stash->{ws_params},
            ws_body => $stash->{ws_body},
            _steps      => ['PRE','RUN']
            } => sub {
                my $ret_rule = $rule_runner->find_and_run_rule( id_rule=>$id_rule, stash=>$stash);
                _debug( _loc( 'Rule WS Elapsed: %1s', $$stash{_rule_elapsed} ) );
                $ret = defined $stash->{ws_response}
                    ? $stash->{ws_response}
                    : ref $ret_rule->{ret} ? $ret_rule->{ret} : { output=>$ret_rule->{ret}, stash=>$stash };
            }, sub {
                my ($err) = @_;
                my $json = try { Util->_encode_json($p) } catch { '{ ... }' };
                my $msg = "Error in Rule WS call '$id_rule/$meth': $json\n$err";
                _error $msg;
                event_new 'event.ws.rule_error', { msg=>$msg };
                $ret = +{
                    Fault => { faultcode => '999', faultstring => "$err", faultactor => "$wsurl" },
                    _RETURN_CODE => 404,
                    _RETURN_TEXT => 'sorry, not found'
                };
            };
        event_new 'event.rule.ws', {
            username  => $username,
            rule_id   => $rule->{id},
            rule_name => $rule->{rule_name},
            rule_type => $rule->{rule_type},
            ws_params => $stash->{ws_params},
            ws_body => $stash->{ws_body},
            ws_response => $ret,
            _steps      => ['POST']
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
            my $wsdl = Baseliner::Model::Rules->new->compile_wsdl($wsdl_body);
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

    if( ref $stash->{ws_response_methods} eq 'HASH' ) {
        for my $meth ( qw(body cookies status redirect location write content_type headers header) ) {
            $c->res->$meth( $stash->{ws_response_methods}{$meth} )
                if exists $stash->{ws_response_methods}{$meth};
        }
    }
}

sub tree_structure : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;
    $p->{destination} = 'tree';
    $p->{username} = $c->username;
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

sub flowchart : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->parameters;

    my $id_rule = $p->{id_rule};
    my $json    = $p->{json};

    $c->stash->{json} = try {
        my @nodes = ( { "key" => -1, "category" => "Start", "loc" => "15 0", "text" => _loc("Start") }, );

        my @links;

        my @tree =
          length $json
          ? Baseliner::Model::Rules->new->tree_format( _array( Util->_decode_json($json) ) )
          : Baseliner::Model::Rules->new->build_tree( $id_rule, undef );

        my $dig;
        $dig = sub {
            my ( $parent, @ops ) = @_;

            for ( my $i = 0 ; $i < @ops ; $i++ ) {
                my $op = $ops[$i];

                #my $key = $op->{text};
                my $key = $op->{id_op} // $op->{key} . Util->_md5();
                my @children = _array( $op->{children} );
                my ( $from, $to );

                my $reg  = Baseliner::Core::Registry->get( $op->{key} );
                my $node = {
                    key          => $key,
                    text         => $op->{text},
                    color        => '#f0f0f0',
                    has_children => !!scalar(@children),
                    is_last_node => ( $i == $#ops )
                };
                if ( $reg->{type} eq 'if' ) {
                    $node->{category} = 'if';
                }
                else {
                    $node->{category} = '';
                }

                push @nodes, $node;

                if ( @nodes > 1 && $parent ) {
                    ( $from, $to ) =
                      ( $parent->{has_children} && !$parent->{is_last_node} && $i == 0 )
                      ? qw(R T)
                      : qw(B T);
                    push @links,
                      {
                        from     => $parent->{key},
                        to       => $key,
                        fromPort => $from,
                        toPort   => $to
                      };
                }

                $parent = $node;

                if (@children) {
                    $dig->( $node, @children );
                }
            }
        };

        $dig->( $nodes[0], @tree );

        { success => \1, nodes => \@nodes, links => \@links };
    }
    catch {
        my $err = shift;
        my $msg = _loc( 'Error building diagram: %1', $err );
        _error($msg);
        { success => \0, msg => $msg };
    };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
