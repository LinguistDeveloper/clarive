package Baseliner::Schema::Migrations::mid;
use Moose;

sub upgrade {
    mdb->migra->mids;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

