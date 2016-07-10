package Baseliner::ActionRole::ACL;
use Moose::Role;

requires 'match', 'match_captures';

use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_error _array);

around [ 'match', 'match_captures' ] => sub {
    my ( $orig, $self, $c, @args ) = @_;

    my @acl = _array $self->attributes->{ACL};

    my $permissions = $self->_build_permissions();

    foreach my $acl (@acl) {
        if (!$c->username || !$permissions->user_has_action($c->username, $acl)) {
            _error 'Unauthorized';

            $c->res->status(403);

            return 0;
        }
    }

    return 1;
};

sub _build_permissions {
    my $self = shift;

    return Baseliner::Model::Permissions->new;
}

1;
