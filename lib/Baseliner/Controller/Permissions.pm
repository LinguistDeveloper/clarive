package Baseliner::Controller::Permissions;
use Moose;
use Baseliner::Utils;
BEGIN {  extends 'Catalyst::Controller' }

sub load_user_actions : Private {
    my ($self,$c)=@_;
    my $username = $c->username;
    foreach my $action ( $c->model('Permissions')->list( username=>$username ) ) {
        $c->stash->{user_action}->{ $action } = 1;
    }
}

1;
