package Baseliner::Model::Projects;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub data {
    my ($self, %p) = @_;
    $p{mid} //= delete $p{id};
    my $prj = mdb->master_doc->find(\%p)->next;

    if( ref $prj ) {
        my $data = $prj->data;
        return undef unless $data;
        # $data = _load( $p{data} );
        $data = _load( $data );
    }
}

sub get_project_name {
    my ( $self, %p ) = @_;
    $p{mid} //= delete $p{id};

    my $project = mdb->master_doc->find({ mid=>$p{mid} })->next->{name};
}

1;
