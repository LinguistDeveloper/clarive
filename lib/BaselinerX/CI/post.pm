package BaselinerX::CI::post;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Internal';
with 'Baseliner::Role::CI::Asset';

sub icon { '/static/images/icons/post.png' }

sub text { '' } 
sub content_type { '' } 

1;

