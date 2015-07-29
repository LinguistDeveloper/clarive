package Baseliner::Model::Projects;
use Moose;
use Baseliner::Core::Registry ':dsl';
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


sub get_all_projects {
    my ( $self, %p ) = @_;
    my $rs = mdb->master_doc->find({ collection=>'project' })->fields({name=>1, description=>1, mid=>1, _id=>0});
    $rs->sort({name=>1});
    $rs->all;
}

1;
