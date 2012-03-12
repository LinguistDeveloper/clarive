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
    # name=>'cambiar pantalla de login', description=>'', assigned=>'infroox', category=>'Incidencia'

    my $rs = $c->model('Baseliner::BaliIssue')->search( status => 'O');
    my @tasks;
    while ( my $row = $rs->next ) {
        push @tasks, { id => $row->id, name => $row->title, description => $row->description, assigned => $row->created_by, category => 'Incidencia'}
    }

    $c->stash->{json} = {
        data=>\@tasks,
        totalCount=>scalar @tasks,
    };
    $c->forward('View::JSON'); 
}

1;
