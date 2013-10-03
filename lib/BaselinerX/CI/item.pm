package BaselinerX::CI::item;
use Baseliner::Moose;

sub icon { '/static/images/icons/post.png' }

with 'Baseliner::Role::CI::CCMDB';
with 'Baseliner::Role::CI::Item';

has source => qw(is rw isa Str), default=>'';

1;
