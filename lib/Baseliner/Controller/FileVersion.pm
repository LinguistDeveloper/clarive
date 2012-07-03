package Baseliner::Controller::FileVersion;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

sub drop : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    $c->stash->{json} = { success=>\1, msg=>_loc('Ok') };
    $c->forward('View::JSON');
}

sub tree_file_project : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @tree;
    @tree = (
        { text=>'uno' . int(rand(99999999)), leaf=>\1 },
        { text=>'dos', leaf=>\1 },
    );
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

1;
