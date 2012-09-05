package Baseliner::Controller::Rule;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

register 'menu.admin.rule' => {
    label    => 'Rules',
    title    => _loc ('Rules'),
    action   => 'action.rule.admin',
    url_comp => '/comp/rules.js',
    icon     => '/static/images/icons/rule.png',
    tab_icon => '/static/images/icons/rule.png'
};

register 'action.rule.admin' => { name=>'Admin Rules' };

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
        _debug _dump $service;
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
        $c->stash->{json} = { success=>\1, rec=>{ $row->get_columns } };
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
    my @rules = (
        { rule_name => 'Verificación del tiempo de excedido de tópico' },
        { rule_name => 'Alerta de pases erroneos' },
        { rule_name => 'Nuevo CI' }
    );
    @rules = $c->model('Baseliner::BaliRule')->search->hashref->all;
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
    my @rules = DB->BaliRule->search(undef,{ order_by=>{ -asc=>'rule_seq' } })->hashref->all;
    $c->stash->{json} = { totalCount=>scalar(@rules), data => \@rules };
    $c->forward("View::JSON");
}

sub save : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    $c->model('Baseliner::BaliRule')->create({ rule_name=>$p->{rule_name} })
        if $p->{rule_name};
    $c->stash->{json} = { success=>\1, msg=>'Creado' } ;
    $c->forward("View::JSON");
}

sub palette : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;

    my @tree;
    my $cnt = 1;
    
    my $if_icon = '/static/images/icons/if.gif';
    my @ifs = (
        { text => _loc('if var'),  leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1,  },
        { text => _loc('if user'), leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1, },
        { text => _loc('if role'), leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1, },
        { text => _loc('if project'), leaf => \1, holds_children=>\1, icon =>$if_icon, palette=>\1, },
    );
    push @tree, {
        icon     => '/static/images/icons/if.gif',
        text     => _loc('Filters'),
        draggable => \0,
        expanded => \1,
        isTarget => \0,
        leaf     => \0,
        children => \@ifs,
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
          map {
            my $service_key = $_;
            my $n = $c->registry->get( $service_key );
            +{
                isTarget => \0,
                leaf=>\1,
                key => $service_key,
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
                my $r = {
                   id_rule   => $id_rule, 
                   stmt_text => $stmt->{attributes}{text},
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
        my $build_tree;
        $build_tree = sub {
            my ($parent) = @_;
            my @tree;
            my @rows = DB->BaliRuleStatement->search( { id_rule => $id_rule, id_parent => $parent },
                { order_by=>{ -asc=>'id' } } )->hashref->all;
            for my $row ( @rows ) {
                my $n = { text=>$row->{stmt_text} };
                $n = { %$n, %{ _load( $row->{stmt_attr} ) } } if length $row->{stmt_attr};
                my @chi = $build_tree->( $row->{id} );
                if(  @chi ) {
                    $n->{children} = \@chi;
                    $n->{leaf} = \0;
                    $n->{expanded} = \1;
                } else {
                    $n->{leaf} = \1;
                }
                push @tree, $n;
            }
            return @tree;
        };
        my @tree = $build_tree->( undef );
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
        _fail _loc "Service '%1' does not have either a form or a config", $key unless $form || $config;
        my $config_data = $self->config_to_data( $config );
        $c->stash->{json} = { success=>\1, msg => 'ok', form=>$form, config=>$config_data };
    } catch {
        my $err = shift;
        _error $err;
        $c->stash->{json} = { success=>\0, msg => $err };
    };
    $c->forward("View::JSON");
}

1;
