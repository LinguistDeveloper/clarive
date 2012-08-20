package Baseliner::Schema::Harvest::ResultSet::Haritems;

use strict;
use warnings;

use base 'Baseliner::Schema::Harvest::Base::ResultSet';

sub items_with_paths {
    my $self = shift;
    return $self->search(
        {
            itemtype => 1,
        },
        {
            join => ["path"],
            prefetch=>["path"],
        }
    );
}


1;
