package BaselinerX::Type::Model::Actions;
use Moose;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Carp;

sub list {
    my ($self,%p) = @_;
    my @actions = Baseliner->model('Registry')->search_for(key=>'action.');
    push @actions,
        map { +{ name => $_->{action_name}, description => $_->{action_description}, key => $_->{action_id}, } }
        DB->BaliAction->search->hashref->all;
    return @actions;
}

1;

