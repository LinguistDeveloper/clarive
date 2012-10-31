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

sub get_labels {
    my ($self, $username) = @_;
    my @labels;
    
    #user labels
    my @user_labels = Baseliner->model('Baseliner::BaliLabel')->search({username => $username}, {join => 'users'})->hashref->all;
    
    #global labels
    my @global_labels = Baseliner->model('Baseliner::BaliLabel')->search({sw_allprojects => 1})->hashref->all;
    
    #project labels
    my @project_labels = Baseliner->model('Baseliner::BaliLabel')
                    ->search({id => {-in=> Baseliner->model('Baseliner::BaliLabelProject')
                    ->search({mid_project => {-in => Baseliner->model('Permissions')->user_projects_query( username=>$username )}}, 
                             {select=>'id_label', distinct => 1})->as_query }})->hashref->all;    
    
    push @labels, map {$_} (@user_labels, @global_labels, @project_labels);
    
    return @labels;
}

1;
