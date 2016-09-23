package Baseliner::Schema::Migrations::0115_add_sort_by_labels;
use Moose;

use Baseliner::Utils qw(_array);
use List::Util qw(max);

sub upgrade {
    my @labels = mdb->label->find()->all;

    foreach my $label (@labels) {
        if ( $label->{seq} ) {
            $label->{priority} = $label->{seq};
        }
        else {
            $label->{priority} = 0;
        }
        mdb->label->update( { id => $label->{id} }, { '$unset' => { seq      => '' } } );
        mdb->label->update( { id => $label->{id} }, { '$set'   => { priority => $label->{priority} } } );
    }

    my @topics = mdb->topic->find()->all;

    foreach my $topic (@topics) {
        my @topic_labels = mdb->label->find( { id => mdb->in( _array $topic->{labels} ) } )->all;
        @topic_labels = map { $_->{seq} } @topic_labels;
        next unless @topic_labels;
        my $max_priority = max(@topic_labels) || 0;
        mdb->topic->update( { mid => $topic->{mid} }, { '$set' => { "_sort.labels_max_priority" => $max_priority } } );
    }
}

sub downgrade {
}

1;
