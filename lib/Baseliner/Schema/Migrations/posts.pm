package Baseliner::Schema::Migrations::posts 3;
use Moose;

sub upgrade {
    mdb->migra->posts;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;



