package Baseliner::Model::Label;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Try::Tiny;
use Baseliner::Utils qw(_locl);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

register 'action.labels.attach_labels' => { name=> _locl('Attach labels to a topic') };
register 'action.labels.remove_labels' => { name=> _locl('Remove labels from a topic') };

sub get_labels {
    my ($self, $username, $mode) = @_;
    my @labels;
    $mode //= '';

    @labels = mdb->label->find->all;

    return @labels;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
