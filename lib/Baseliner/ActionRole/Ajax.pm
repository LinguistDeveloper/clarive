package Baseliner::ActionRole::Ajax;

use Moose::Role;
use Baseliner::Utils;

requires 'match', 'match_captures';

around [ 'match', 'match_captures' ] => sub {
    my ( $orig, $self, $c, @args ) = @_;

    if ( $c->config->{deny_non_ajax_access} ) {
        if ( $c->req->header('x-requested-with') eq 'XMLHttpRequest' ) {
            return 1;
        }
        else {
            return 0;
        }
    } else {
        return 1;
    }
};

1;