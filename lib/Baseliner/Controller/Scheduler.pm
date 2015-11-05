package Baseliner::Controller::Scheduler;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_loc);
use Baseliner::Model::Scheduler;

with 'Baseliner::Role::ControllerValidator';

register 'action.admin.scheduler' => { name => 'Admin Scheduler' };

register 'menu.admin.scheduler' => {
    label    => 'Scheduler',
    url_comp => '/scheduler/grid',
    actions  => ['action.admin.scheduler'],
    title    => 'Scheduler',
    icon     => '/static/images/icons/clock.png'
};

sub grid : Local {
    my ( $self, $c ) = @_;

    $c->stash->{template} = '/comp/scheduler_grid.js';
}

sub json : Local {
    my ( $self, $c ) = @_;

    return
      unless my $validated_params = $self->validate_params(
        $c,
        start => { isa => 'PositiveInt',   default => 0,      default_on_error => 1 },
        limit => { isa => 'PositiveInt',   default => 0,      default_on_error => 1 },
        dir   => { isa => 'SortDirection', default => 'asc',  default_on_error => 1 },
        sort  => { isa => 'Str',           default => 'name', default_on_error => 1 },
        query => { isa => 'Str',           default => '',     default_on_error => 1 }
      );

    my $result = $self->_build_scheduler->search_tasks(%$validated_params);

    $c->stash->{json} = { data => $result->{rows}, totalCount => $result->{total} };
    $c->forward('View::JSON');
}

sub last_log : Local {
    my ( $self, $c ) = @_;

    return unless my $validated_params = $self->validate_params( $c, id => { isa => 'ID' } );

    my $body = $self->_build_scheduler->task_log( taskid => $validated_params->{id} );

    if ( defined $body ) {
        $body = _loc('No log') unless length $body;
    }
    else {
        $c->res->status(404);
        $body = _loc('Error: task log not found');
    }

    $c->res->content_type('text/plain');
    $c->res->body($body);
}

sub delete_schedule : Local {
    my ( $self, $c ) = @_;

    return unless my $validated_params = $self->validate_params( $c, id => { isa => 'ID' } );

    try {
        $self->_build_scheduler->delete_task( taskid => $validated_params->{id} );

        $c->stash->{json} = { msg => 'ok', success => \1 };
    }
    catch {
        my $err = shift;

        $c->stash->{json} =
          { msg => _loc( "Error deleting schedule: %1", $err ), success => \0 };
    };

    $c->forward('View::JSON');
}

sub run_schedule : Local {
    my ( $self, $c ) = @_;

    return unless my $validated_params = $self->validate_params( $c, id => { isa => 'ID' } );

    try {
        $self->_build_scheduler->schedule_task(
            taskid => $validated_params->{id},
            when   => 'now'
        );
        $c->stash->{json} = { msg => 'ok', success => \1 };
    }
    catch {
        my $err = shift;

        $c->stash->{json} =
          { msg => _loc( "Error running schedule: %1", $err ), success => \0 };
    };

    $c->forward('View::JSON');
}

sub save_schedule : Local {
    my ( $self, $c ) = @_;

    return
      unless my $validated_params = $self->validate_params(
        $c,
        id_rule     => { isa => 'ID' },
        date        => { isa => 'DateStr' },
        time        => { isa => 'TimeStr' },
        id          => { isa => 'ID', default => undef },
        name        => { isa => 'Maybe[Str]', default => 'noname' },
        description => { isa => 'Maybe[Str]', default => undef },
        frequency   => { isa => 'Maybe[Str]', default => undef },
        workdays    => { isa => 'BoolCheckbox', default => 0 },
      );

    $validated_params->{taskid} = delete $validated_params->{id};
    $validated_params->{next_exec} =
      $c->user_ci->from_user_date( delete( $validated_params->{date} ) . " " . delete( $validated_params->{time} ) )
      . '';
    $validated_params->{workdays} = $validated_params->{workdays};

    my $scheduler = $self->_build_scheduler;

    try {
        $scheduler->save_task(%$validated_params);

        $c->stash->{json} = { msg => 'ok', success => \1 };
    }
    catch {
        my $err = shift;

        $c->stash->{json} = {
            msg     => _loc( "Error saving configuration schedule: %1", $err ),
            success => \0
        };
    };
    $c->forward('View::JSON');
}

sub toggle_activation : Local {
    my ( $self, $c ) = @_;

    return
      unless my $validated_params = $self->validate_params(
        $c,
        id     => { isa => 'ID' },
        status => { isa => 'Str' }
      );

    my $new_status;

    try {
        $new_status = $self->_build_scheduler->toggle_activation(
            taskid => $validated_params->{id},
            status => $validated_params->{status}
        );

        $c->stash->{json} = { msg => 'Task is now ' . $new_status, success => \1 };
    }
    catch {
        my $err = shift;

        $c->stash->{json} = {
            msg     => _loc( "Error changing activation: %1", $err ),
            success => \0
        };
    };

    $c->forward('View::JSON');
}

sub kill_schedule : Local {
    my ( $self, $c ) = @_;

    return
      unless my $validated_params = $self->validate_params( $c, id => { isa => 'ID' }, );

    try {
        $self->_build_scheduler->kill_schedule( taskid => $validated_params->{id} );

        $c->stash->{json} = { msg => 'Task killed', success => \1 };
    }
    catch {
        my $err = shift;

        $c->stash->{json} =
          { msg => _loc( "Error killing task: %1", $err ), success => \0 };
    };

    $c->forward('View::JSON');
}

sub _build_scheduler {
    my $self = shift;

    return Baseliner::Model::Scheduler->new;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
