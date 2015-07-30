package Baseliner::Schema::Migrations::topic_rels;
use Moose;

sub upgrade {
    # 6.1:
    mdb->migra->topic_rels;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


