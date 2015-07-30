package Baseliner::Schema::Migrations::topic_admin 5;
use Moose;

sub upgrade {
    mdb->migra->topic_admin;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


