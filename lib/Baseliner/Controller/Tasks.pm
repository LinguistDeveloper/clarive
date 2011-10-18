package Baseliner::Controller::Tasks;
use Baseliner::Plug;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

sub grid : Local {
    my ($self, $c) = @_;
    $c->stash->{template} = '/comp/lifecycle/tasks.js';
    #$c->forward('View::JSON'); 
}

sub json : Local {
    my ($self, $c) = @_;
    my @tasks = (
        {
            name=>'cambiar pantalla de login', description=>'', assigned=>'infroox', category=>'Incidencia'
        },
        {
            name=>'modificar cuentas cliente', description=>'', assigned=>'infroox', category=>'Mejora'
        },
        {
            name=>'error apellidos erroneos', description=>'', assigned=>'infroox', category=>'Incidencia'
        },

    );

    $c->stash->{json} = {
        data=>\@tasks,
        totalCount=>scalar @tasks,
    };
    $c->forward('View::JSON'); 
}

1;
