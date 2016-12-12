package BaselinerX::Workflow;
use Moose;
use Try::Tiny;
use Array::Utils qw(intersect);

use Baseliner::Sugar;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(:logging _locl _any _array _dump _warn);

use v5.10;

register 'service.workflow.transition' => {
    name         => _locl('Change Topic Status'),
    form         => '/forms/workflow_transition.js',
    icon         => '/static/images/icons/service-workflow-transition.svg',
    palette_area => 'workflow',
    handler      => \&workflow_transition,
};

register 'service.workflow.transition_match' => {
    name         => _locl('Change Topic Status If Matches'),
    form         => '/forms/workflow_transition_match.js',
    icon         => '/static/images/icons/service-workflow-match.svg',
    palette_area => 'workflow',
    handler      => \&workflow_transition_match,
};

sub workflow_transition {
    my $self = shift;
    my ( $c, $config ) = @_;

    my $statuses_to = $config->{statuses_to}
      // _fail( _loc("Missing 'statuses_to' configuration for workflow transition") );
    my $job_type = $config->{job_type} // '';

    my $stash = $c->stash;
    my $user_roles = $stash->{user_roles} // {};

    $stash->{workflow} //= [];

    for my $id_role ( keys %$user_roles ) {
        for my $status_to ( _array($statuses_to) ) {

            my @statuses =
              defined $stash->{id_status_from}
              ? ( $stash->{id_status_from} )
              : _array( $stash->{category}{statuses} );

            if ( $job_type && $stash->{_statuses_from} ) {
                my @statuses_from_job = _array $stash->{_statuses_from};
                @statuses = intersect @statuses, @statuses_from_job;
            }

            for my $status_from (@statuses) {
                push @{ $stash->{workflow} },
                  {
                    id_role        => $id_role,
                    id_status_from => $status_from,
                    id_status_to   => $status_to,
                    job_type       => $job_type,
                  };
            }
        }
    }
}

sub workflow_transition_match {
    my $self = shift;
    my ( $c, $config ) = @_;

    my $stash       = $c->stash;
    my $user_roles  = $stash->{user_roles} // {};
    my $id_category = $stash->{id_category} // '';

    my $statuses_to = $config->{statuses_to}
      // _fail( _loc("Missing 'statuses_to' configuration for workflow transition") );
    my $statuses_from  = $config->{statuses_from} || $stash->{category}->{statuses};
    my $id_status_from = $stash->{id_status_from} || $statuses_from;
    my $roles          = $config->{roles}         || $user_roles;
    my $categories = $config->{categories} // [];
    my $job_type   = $config->{job_type}   // '';

    my @user_roles_id = keys %$user_roles;
    my @common_roles;
    if ( $stash->{_complete_workflow} ) {
        @common_roles = @$roles ? @$roles : @user_roles_id;
    }
    else {
        @common_roles = @$roles ? intersect @user_roles_id, @$roles : @user_roles_id;
    }

    $stash->{workflow} //= [];

    if ( $stash->{_complete_workflow} || !_array($categories) || _any { $_ eq $id_category } _array($categories) ) {
        for my $id_role (@common_roles) {
            for my $status_from ( _array($statuses_from) ) {
                next
                  if !$stash->{_complete_workflow}
                  && !_any { $status_from eq $_ } _array($id_status_from);
                next
                  if $job_type
                  && $stash->{_statuses_from}
                  && !( _any { $status_from eq $_ } _array( $stash->{_statuses_from} ) );
                for my $status_to ( _array($statuses_to) ) {
                    next
                      if !$stash->{_complete_workflow}
                      && defined $stash->{status_to}
                      && !_any { $status_to eq $_ } _array( $stash->{status_to} );
                    push @{ $stash->{workflow} },
                      {
                        id_role        => $id_role,
                        id_status_to   => $status_to,
                        id_status_from => $status_from,
                        job_type       => $job_type,
                      };
                }
            }
        }
    }
}

register 'statement.workflow.if_status_from' => {
    text         => _locl('IF From Status IS'),
    type         => 'if',
    form         => '/forms/workflow_if_status.js',
    data         => { statuses_from => '' },
    palette_area => 'workflow',
    dsl          => sub {
        my ( $self, $n, %p ) = @_;

        local $Data::Dumper::Terse = 1;
        sprintf(
            q{
            $stash->{_statuses_from} = %s;
            if( $stash->{_complete_workflow}
                || ( length $stash->{id_status_from}
                     && _any { $stash->{id_status_from} eq $_ } grep { defined } _array($stash->{_statuses_from}) ) ) {
                    %s
            }

        }, Data::Dumper::Dumper( $n->{statuses_from} ), $self->dsl_build( $n->{children}, %p )
        );
    }
};

register 'statement.workflow.if_role' => {
    text         => _locl('IF Role IS'),
    type         => 'if',
    form         => '/forms/workflow_if_role.js',
    data         => { roles => '' },
    palette_area => 'workflow',
    dsl          => sub {
        my ( $self, $n, %p ) = @_;

        sprintf(
            q{
            if( $stash->{_complete_workflow}
                || ( ref $stash->{user_roles} eq 'HASH'
                     && _any { $stash->{user_roles}->{$_} } grep { defined } _array(%s) )) {
                    %s
            }

        }, Data::Dumper::Dumper( $n->{roles} || [] ), $self->dsl_build( $n->{children}, %p )
        );
    }
};

register 'statement.workflow.if_project' => {
    text         => _locl('IF Project IS'),
    type         => 'if',
    form         => '/forms/workflow_if_project.js',
    data         => { roles => '' },
    palette_area => 'workflow',
    dsl          => sub {
        my ( $self, $n, %p ) = @_;

        local $Data::Dumper::Terse = 1;
        sprintf(
            q{
            if( $stash->{_complete_workflow}
                || ( ref $stash->{projects} eq 'ARRAY'
                     && _any { my $first = $_; _any { $first eq $_ } _array( $stash->{projects} ) } _array( %s ) )) {
                    %s
            }

        }, Data::Dumper::Dumper( $n->{projects} || [] ), $self->dsl_build( $n->{children}, %p )
        );
    }
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
