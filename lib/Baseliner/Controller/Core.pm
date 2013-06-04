package Baseliner::Controller::Core;
use Baseliner::Plug;
use Baseliner::Utils;

# otro comentario

register 'action.admin.default' =>  { name=>'Administrator' };

register 'menu.admin' => { label => 'Admin', actions=>['action.admin.%'], index=>10 };
register 'menu.reports' => { label => 'Reports', actions=>['action.reports.%'] };
register 'menu.admin.core' => { label => 'Core', actions=>['action.admin.default'] };
register 'menu.admin.core.registry' => { label => 'List Registry Data', url=>'/core/registry', title=>'Registry', actions=>['action.admin.default'] };

BEGIN { extends 'Catalyst::Controller' }
use YAML;
sub registry : Path('/core/registry') {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre>' . YAML::Dump( $c->registry->registrar ) );
}
1;


