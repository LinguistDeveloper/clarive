package Baseliner::Controller::Permissions;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Baseliner::Utils qw(_array _error _decode_json_safe);
use Baseliner::Model::Permissions;
use Try::Tiny;

sub load_user_actions : Private {
    my ( $self, $c ) = @_;

    my $username = $c->username;

    foreach my $action ( _array $c->model('Permissions')->user_actions($username) ) {
        my $action_key = $action->{action};

        $c->stash->{user_action}->{$action_key} = 1;
    }
}

sub user_has_action : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    my $username   = $p->{username};
    my $action_key = $p->{action};
    my $options    = _decode_json_safe( $p->{options} );

    try {
        my $has_permissions
            = Baseliner::Model::Permissions->new->user_has_action( $username, $action_key, %{$options} );
        $c->stash->{json} = { success => \1, has => $has_permissions };
    }
    catch {
        my $error = shift();
        _error $error;

        $c->stash->{json} = { success => \0, has => 0 };
    };

    $c->forward('View::JSON');

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
