package Baseliner::Controller::Project;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

sub user_projects : Local {
    my ($self, $c) = @_;
    my $username = $c->username;
    my $p = $c->request->parameters;
    my $collection = $p->{collection} // 'project';
    my $query = $p->{query} // '';

    my @rows = Baseliner->model('Users')->get_projectnames_and_descriptions_from_user($username, $collection, $query);
    $c->stash->{json} = { data=>\@rows, totalCount=>scalar(@rows)};	
    $c->forward('View::JSON');
}

sub all_projects : Local {
    my ($self, $c) = @_;
	my @rows = Baseliner->model('Projects')->get_all_projects();
	$c->stash->{json} = { data=>\@rows, totalCount=>scalar(@rows)};		
	$c->forward('View::JSON');	
}

1;
