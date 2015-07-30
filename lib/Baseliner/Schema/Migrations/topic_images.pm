package Baseliner::Schema::Migrations::topic_images 6;
use Moose;

sub upgrade {
    mdb->migra->topic_images;
}

sub downgrade {
}

1;
