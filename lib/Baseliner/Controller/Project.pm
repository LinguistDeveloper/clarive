package Baseliner::Controller::Project;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

sub user_projects : Local {
    my ($self, $c) = @_;
    my $username = $c->username;
    my @rows = Baseliner->model('Users')->get_projectnames_and_descriptions_from_user($username);
    $c->stash->{json} = { data=>\@rows};		
    $c->forward('View::JSON');
}

1;