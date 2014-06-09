package Baseliner::Model::Label;
use Baseliner::Plug;
use Try::Tiny;
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'action.labels.admin' => { name=>'Admin generic labels' };

sub get_labels {
    my ($self, $username, $mode) = @_;
    my @labels;
    $mode //= '';
    
    @labels = mdb->label->find->all;
    
    #user labels
    # my $perm = Baseliner->model('Permissions');
    # my @user_labels = mdb->label_user->find({username => $username})->all;
    # if ($perm->user_has_action( username=> $username, action => 'action.labels.admin') || $perm->is_root( $username ) || $mode ne 'admin'  ){
    # }
    
    return @labels;
}

1;
