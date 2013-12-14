package Baseliner::Model::Label;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use Array::Utils qw(:all);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'action.labels.admin' => { name=>'Admin generic labels' };

sub get_labels {
    my ($self, $username, $mode) = @_;
    my @labels;
    my $perm = Baseliner->model('Permissions');
    $mode //= '';
    
    #user labels
    my @user_labels = Baseliner->model('Baseliner::BaliLabel')->search({username => $username}, {join => 'users'})->hashref->all;
    push @labels, map {$_} @user_labels;
    
    if ($perm->user_has_action( username=> $username, action => 'action.labels.admin') || $perm->is_root( $username ) || $mode ne 'admin'  ){
        #global labels
        my @global_labels = Baseliner->model('Baseliner::BaliLabel')->search({sw_allprojects => 1})->hashref->all;
        push @labels, map {$_} @global_labels;
        
        #project labels
        my @project_labels = Baseliner->model('Baseliner::BaliLabel')
                        ->search({id => {-in=> Baseliner->model('Baseliner::BaliLabelProject')
                            ->search({ 'exists'=>Baseliner->model( 'Permissions' )->user_projects_query( username=>$username, join_id=>'mid_project' ) },
                                 {select=>'id_label', distinct => 1})->as_query }})->hashref->all;
        push @labels, map {$_} @project_labels;                        
    }
    
    return @labels;
}

1;
