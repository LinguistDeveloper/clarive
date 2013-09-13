package Baseliner::Controller::Rule;
use Baseliner::Plug;
use Baseliner::Utils qw(:basic _decode_json _strip_html);
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

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
    my @rows;
    $c->stash->{json} = \@rows;
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
        my $row = DB->BaliRule->find( $p->{id_rule} );
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        my $name = $row->rule_name;
        $row->update({ rule_active=> $p->{activate} });
        my $act = $p->{activate} ? _loc('activated') : _loc('deactivated');
        $c->stash->{json} = { success=>\1, msg=>_loc('Rule %1 %2', $name, $act) };
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
        my $row = DB->BaliRule->find( $p->{id_rule} );
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        my $name = $row->rule_name;
        $row->delete;
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
        my $row = DB->BaliRule->find( $p->{id_rule} );
        _fail _loc('Row with id %1 not found', $p->{id_rule} ) unless $row;
        my $rec = { $row->get_columns };
        $rec->{rule_when} = \1 if $rec->{rule_type} eq 'chain' && $rec->{rule_when} eq 'on';
        $c->stash->{json} = { success=>\1, rec=>$rec };
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
    my @rules = $c->model('Baseliner::BaliRule')->search->hashref->all;
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
    my @rules = DB->BaliRule->search(undef,{ order_by=>[ { -asc=>'rule_seq' }, { -desc=>'id' }] })->hashref->all;
    @rules = map {
        $_->{event_name} = $c->registry->get( $_->{rule_event} )->name if $_->{rule_event};
        $_
    } @rules;
    $c->stash->{json} = { totalCount=>scalar(@rules), data => \@rules };
    $c->forward("View::JSON");
}

sub save : Local {
    my ( $self, $c ) = @_;
    my $p    = $c->req->params;
    my $data = {
        rule_name  => $p->{rule_name},
        rule_when  => $p->{rule_type} eq 'chain' ? $p->{chain_default} : $p->{rule_when},
        rule_event => $p->{rule_event},
        rule_type  => $p->{rule_type},
        rule_desc  => substr($p->{rule_desc},0,2000),
    };
    if ( length $p->{rule_id} ) {
        my $row = $c->model('Baseliner::BaliRule')->find( $p->{rule_id} );
        _fail _loc 'Rule %1 not found', $p->{rule_id} unless $row;
        $row->update($data);
    } else {
        $c->model('Baseliner::BaliRule')->create($data);
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
        $n->{holds_children} = defined $s->{holds_children} ? \($s->{holds_children}) : \1;
        $n->{leaf} = \1;
        $n->{key} = $key;
        $n->{text} = $s->{text} // $key;
        $n->{icon} = $s->icon // "/static/images/icons/$s->{type}.gif";
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
        text=>_loc('Services'),
        draggable => \0,
        expanded => \1,
        children=> [ 
          sort { uc $a->{text} cmp uc $b->{text} }
          grep { !$query || join(',', values %$_) =~ $query }
          map {
            my $service_key = $_;
            my $n = $c->registry->get( $service_key );
            +{
                isTarget => \0,
                leaf=>\1,
                key => $service_key,
                icon => $n->{icon},
                palette => \1,
                text=>$n->{name} // $service_key,
            }
        } @services ]
    };
    $c->stash->{json} = \@tree;
    $c->forward("View::JSON");
}

sub stmts_save : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;

    try {
        my $id_rule = $p->{id_rule} or _throw 'Missing rule id';
        my $flatten_tree;
        $flatten_tree = sub {
            my ($parent, $stmts) = @_;
            for my $stmt ( _array $stmts ) {
                delete $stmt->{attributes}{loader}; # treenode cruft
                my $r = {
                   id_rule   => $id_rule, 
                   stmt_text => _strip_html( $stmt->{attributes}{text} ),
                   stmt_attr => _dump( $stmt->{attributes} ),
                };
                $r->{id_parent} = $parent if defined $parent;
                my $row = DB->BaliRuleStatement->create( $r );
                my $chi = delete $stmt->{children};
                $flatten_tree->( $row->id, $chi ) if _array( $chi );
            }
        };
        my $stmts = _decode_json( $p->{stmts} );
        DB->BaliRuleStatement->search({ id_rule=> $id_rule })->delete;
        $stmts = $flatten_tree->( undef, $stmts );
        $c->stash->{json} = { success=>\1, msg => _loc('Rule statements saved ok') };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

sub stmts_load : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;

    try {
        my $id_rule = $p->{id_rule} or _throw 'Missing rule id';
        # recursive loading from rows to tree:
        my @tree = Baseliner->model('Rules')->build_tree( $id_rule, undef );
        # $c->stash->{json} = [{ text=>_loc('Start'), leaf=>\0, children=>\@tree }];
        $c->stash->{json} = \@tree;
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
            #my @rows = DB->BaliRuleS
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
    my $output;
    my $dslerr;
    try {
        require Capture::Tiny;
        _log "============================ DSL TRY START ============================";
        ($output) = Capture::Tiny::tee_merged(sub{
            try {
                $stash = $c->model('Rules')->dsl_run( dsl=>$dsl, stash=>$stash );
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
        $c->stash->{json} = { success=>\1, msg=>'ok', output=>$output, stash_yaml=>$stash_yaml };
    } catch {
        my $err = shift; _error $err;
        my $stash_yaml = _dump( $stash );
        $c->stash->{json} = { success=>\0, msg=>$err, output=>$output, stash_yaml=>$stash_yaml };
    };
    $c->forward("View::JSON");
}

1;
