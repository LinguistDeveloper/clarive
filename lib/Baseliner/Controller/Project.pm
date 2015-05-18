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
    my $roles = $p->{roles};

    my @rows = Baseliner->model('Users')->get_projectnames_and_descriptions_from_user($username, $collection, $query, $roles);

    if ($query) {
        my @projects = split (' ', $query);
        my %projects;

        foreach my $project (@projects){
            my $ci_project = ci->new($project);
            $projects{$project} = { mid => $project, name => $ci_project->{name}};
        }

        if ( !@rows ){
            foreach my $mid ( keys %projects ){
                push @rows, $projects{$mid};
            }
        }else{
            foreach my $row ( @rows ) {
                if (exists $projects{$row->{mid}}){
                    delete $projects{$row->{mid}};
                }
            }

            map { 
                push @rows, $projects{$_};
            } keys %projects;

        }
    }

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
