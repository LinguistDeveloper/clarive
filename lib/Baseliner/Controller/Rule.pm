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

sub save : Local {
    my ($self,$c)=@_;
    my $p = $c->req->params;
    $c->model('Baseliner::BaliRule')->create({ rule_name=>$p->{rule_name} })
        if $p->{rule_name};
    $c->stash->{json} = { success=>\1, msg=>'Creado' } ;
    $c->forward("View::JSON");
}

1;
