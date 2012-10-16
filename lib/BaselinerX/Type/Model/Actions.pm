package BaselinerX::Type::Model::Actions;
use Moose;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
use Carp;

sub list {
    my ($self,%p) = @_;
    my @actions = Baseliner->model('Registry')->search_for(key=>'action.');
    return @actions;
}

1;

