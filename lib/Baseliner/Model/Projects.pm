package Baseliner::Model::Projects;
use Moose;
BEGIN { extends 'Catalyst::Model' }

use Baseliner::Utils qw(_check_parameters);

sub get_all_projects {
    my ( $self, %p ) = @_;

    my @projects =
      mdb->master_doc->find( { collection => 'project' } )
      ->fields( { name => 1, description => 1, mid => 1, _id => 0, bls => 1, moniker => 1 } )->sort( { name => 1 } )
      ->all;

    for my $project (@projects) {
        my @bls = ci->bl->find( { mid => mdb->in( $project->{bls} ) } )->fields( { name => 1, _id => 0 } )->all;

        $project->{bl} = join ',', map { $_->{name} } @bls;
        $project->{icon} = BaselinerX::CI::project->icon;
    }

    return @projects;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
