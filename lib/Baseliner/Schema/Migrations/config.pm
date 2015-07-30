package Baseliner::Schema::Migrations::config;
use Moose;

sub upgrade {
    mdb->migra->config;
}

sub downgrade {
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

