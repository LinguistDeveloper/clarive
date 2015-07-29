package Baseliner::Controller::Core;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;

register 'action.admin.default' =>  { name=>'Administrator' };
register 'menu.admin' => { label => 'Admin', actions=>['action.admin.%'], index=>10 };
register 'menu.admin.core_separator' => { separator => 1, index=>999 };
register 'menu.admin.core' => { label => 'Core', actions=>['action.admin.default'], index=>1000 };
register 'menu.admin.core.registry' => { label => 'List Registry Data', url=>'/core/registry', title=>'Registry', actions=>['action.admin.default'], index=>1000 };
register 'menu.reports' => { label => 'Reports', actions=>['action.reports.%'] };
register 'action.reports.view' => { name=>'View Reports' };
register 'action.reports.dynamics' => { name=>'View dynamics fields' };
register 'config.reports' => {
    metadata => [
           { id=>'fields_dynamics', label=>'Show dynamics fields', default => 'NO' },
        ]
};

BEGIN { extends 'Catalyst::Controller' }

sub registry : Path('/core/registry') {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre>' . _dump( $c->registry->registrar ) );
}
1;


