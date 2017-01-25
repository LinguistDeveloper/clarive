package Baseliner::Role::CI::ProjectSecurity;
use Moose::Role;
with 'Baseliner::Role::CI::Internal';

use Baseliner::Utils qw(_array _unique);

sub roles_projects {
    my $self = shift;

    my @rows;
    foreach my $id_role ( keys %{ $self->project_security } ) {
        next unless my $role = mdb->role->find_one( { id => $id_role } );

        my @projects;
        foreach my $dimension ( keys %{ $self->project_security->{$id_role} } ) {
            my @cis = ci->search_cis( mid => mdb->in( $self->project_security->{$id_role}->{$dimension} ) );

            foreach my $ci (@cis) {
                next unless $ci->active;

                push @projects, $ci;
            }
        }

        push @rows,
          {
            role     => $role,
            projects => \@projects
          };
    }

    return \@rows;
}

sub toggle_roles_projects {
    my $self = shift;
    my (%params) = @_;

    my $action   = $params{action};
    my @roles    = _array $params{roles};
    my @projects = _array $params{projects};

    my @dimensions = map { Util->to_base_class($_) } Util->packages_that_do('Baseliner::Role::CI::Project');

    my $projects_by_dimensions = {};
    foreach my $project (@projects) {
        my $ci = eval { ci->new($project) };
        next unless $ci && $ci->DOES('Baseliner::Role::CI::Project');

        my $dimension = Util->to_base_class( ref $ci );
        next unless grep { $dimension eq $_ } @dimensions;

        push @{ $projects_by_dimensions->{$dimension} }, $project;
    }

    my $project_security = $self->project_security;

    foreach my $id_role (@roles) {
        next unless mdb->role->find_one( { id => $id_role }, { _id => 1 } );

        foreach my $dimension ( keys %$projects_by_dimensions ) {
            if ( $action eq 'assign' ) {
                $project_security->{$id_role}->{$dimension} = [
                    _unique _array( $project_security->{$id_role}->{$dimension} ),
                    _array( $projects_by_dimensions->{$dimension} )
                ];
            }
            elsif ( $action eq 'unassign' ) {
                my %to_remove = map { $_ => 1 } _array( $projects_by_dimensions->{$dimension} );

                $project_security->{$id_role}->{$dimension} =
                  [ grep { !$to_remove{$_} } _array $project_security->{$id_role}->{$dimension} ];
                delete $project_security->{$id_role}->{$dimension}
                  unless _array $project_security->{$id_role}->{$dimension};
            }
        }

        delete $project_security->{$id_role} unless %{ $project_security->{$id_role} };
    }

    $self->update( project_security => $project_security );

    return $self;
}

sub delete_roles {
    my $self = shift;
    my (%params) = @_;

    my @roles = _array $params{roles};

    my $project_security = $self->project_security;

    foreach my $id_role (@roles) {
        next unless mdb->role->find_one( { id => $id_role }, { _id => 1 } );

        delete $project_security->{$id_role};
    }

    $self->update( project_security => $project_security );

    return $self;
}

1;
