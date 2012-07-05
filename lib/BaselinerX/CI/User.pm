package BaselinerX::CI::User;
use Moose;
with 'Baseliner::Role::CI::Internal';

sub collection { 'bali_user' }
sub icon { '/static/images/icons/user.gif' }

1;
