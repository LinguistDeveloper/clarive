package Baseliner::Controller::Core;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;

register 'action.admin.default' =>  { name=>_locl('Administrator') };
register 'menu.admin' => { label => _locl('Admin'), actions=>['action.admin.%'], index=>10 };
register 'menu.admin.core_separator' => { separator => 1, index=>999 };
register 'menu.admin.core' => { label => _locl('Core'), actions=>['action.admin.default'], index=>1000 };
register 'menu.admin.core.registry' => { label => _locl('List Registry Data'), url=>'/core/registry', title=>_locl('Registry'), actions=>['action.admin.default'], index=>1000 };
register 'menu.reports' => { label => _locl('Reports'), actions=>['action.reports.%'] };
register 'action.reports.view' => { name=>_locl('View Reports') };
register 'action.reports.dynamics' => { name=>_locl('View dynamics fields') };
register 'config.reports' => {
    metadata => [
           { id=>'fields_dynamics', label=>_locl('Show dynamics fields'), default => 'NO' },
        ]
};

BEGIN { extends 'Catalyst::Controller' }

sub registry : Path('/core/registry') {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre>' . _dump( $c->registry->registrar ) );
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
