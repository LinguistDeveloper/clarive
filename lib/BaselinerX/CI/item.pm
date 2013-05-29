package BaselinerX::CI::item;
use Baseliner::Moose;

sub icon { '/static/images/icons/post.png' }

with 'Baseliner::Role::CI::CCMDB';
with 'Baseliner::Role::CI::Item';

has name   => qw(is rw isa Maybe[Str]);
has is_dir => qw(is rw isa Maybe[Bool]);

1;
