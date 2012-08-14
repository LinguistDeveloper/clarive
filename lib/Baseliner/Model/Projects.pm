package Baseliner::Model::Projects;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub create {
    my ($self, %p) = @_;
    $p{data} = _dump( $p{data} );
    $p{mid} //= delete $p{id};

    my $row = Baseliner->model('Baseliner::BaliProject')->search({ name=>$p{name} })->first;
    if( ref $row ) {
        _log "Updating project=" . $row->name;
        $row->set_columns(\%p);
        $row->update;
    } else {
        Baseliner->model('Baseliner::BaliProject')->create(\%p);
    }
}

sub data {
    my ($self, %p) = @_;
    $p{mid} //= delete $p{id};
    my $prj = Baseliner->model('Baseliner::BaliProject')->search(\%p)->first;

    if( ref $prj ) {
        my $data = $prj->data;
        return undef unless $data;
        # $data = _load( $p{data} );
        $data = _load( $data );
    }
}

sub add_item {
    my ($self, %p) = @_;
    $p{project} or _throw "Missing parameter 'project'";
    $p{ns} or _throw "Missing parameter 'ns'";
    my $ns = ref $p{ns} ? $p{ns} : Baseliner->model('Namespaces')->get( $p{ns} );
    return unless ref $ns;
    my $project = Baseliner->model('Baseliner::BaliProject')->search({ ns=>$p{project} })->first;
    if( ref $project ) {
        my $items = $project->bali_project_items;
        $items->find_or_create({ ns=>$ns->ns });
    }
}

sub get_project_name {
    my ( $self, %p ) = @_;
    $p{mid} //= delete $p{id};

    my $project = Baseliner->model('Baseliner::BaliProject')->search({ mid=>$p{mid} })->first->name;
}

1;
