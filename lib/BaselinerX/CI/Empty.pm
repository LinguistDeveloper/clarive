# Empty CI to represent missing relationships
package BaselinerX::CI::Empty;
use Baseliner::Moose;
with 'Baseliner::Role::CI';

sub icon {
    '/static/images/icons/empty.png'
}

1;
