# Empty CI to represent missing relationships
package BaselinerX::CI::Empty;
use Moose;
with 'Baseliner::Role::CI';

sub icon {
    '/static/images/icons/empty.png'
}

1;
