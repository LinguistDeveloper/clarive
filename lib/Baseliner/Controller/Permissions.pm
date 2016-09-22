package Baseliner::Controller::Permissions;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Baseliner::Utils qw(_array);

sub load_user_actions : Private {
    my ( $self, $c ) = @_;

    my $username = $c->username;

    foreach my $action ( _array $c->model('Permissions')->user_actions( $username ) ) {
        my $action_key = $action->{action};

        $c->stash->{user_action}->{$action_key} = 1;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
