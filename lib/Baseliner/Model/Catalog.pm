package Baseliner::Model::Catalog;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use Array::Utils qw(:all);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

# register 'menu.tools.catalog' => {
#     label    => 'Catalog',
#     title    => 'Catalog',
#     action   => 'action.catalog.view',
#     url_comp => '/catalog/init_catalog',
#     icon     => '/static/images/icons/catalog.png',
#     tab_icon => '/static/images/icons/catalog.png',
# };

register 'action.catalog.view' => {
    name => 'View catalog'
};

register 'action.catalog.request' => {
    name => 'Request catalog'
};

sub get_catalog_actions {
    my @actions = (
        'action.catalog.view',
        'action.catalog.request'
    );
}

sub get_perm_catalog {
    my ( $self, %params ) = @_;
    my $username = $params{username} // _fail "Missing username";
    my @actions = $params{actions} // $self->get_catalog_actions;
    my %perm_catalog;

    foreach my $action ( @actions ){
        $perm_catalog{$action} = Baseliner->model('Permissions')->user_has_action( action => $action, username => $username );
    }

    return \%perm_catalog;
}

1;
