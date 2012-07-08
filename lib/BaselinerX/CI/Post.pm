package BaselinerX::CI::post;
use Moose;
with 'Baseliner::Role::CI::Internal';

sub collection { 'bali_post' }
sub icon { '/static/images/icons/post.png' }

1;

