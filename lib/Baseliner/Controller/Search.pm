package Baseliner::Controller::Search;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

sub providers : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @provs = packages_that_do('Baseliner::Role::Search');
    $c->stash->{json} = { providers=>\@provs };
    $c->forward('View::JSON');
}

sub query : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $provider = $p->{provider} or _throw _loc('Missing provider');
    my $query = $p->{query} or _throw _loc('Missing query');
    my @results = $provider->query( query=>$query );
    $c->stash->{json} = { results=> \@results };
    $c->forward('View::JSON');
}

1;
