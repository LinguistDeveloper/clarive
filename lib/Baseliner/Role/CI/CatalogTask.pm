package Baseliner::Role::CI::CatalogTask;
use Moose::Role;
use Baseliner::Utils;
with 'Baseliner::Role::CI';

before new_ci => sub {
    my ($self) = @_;
    $self->remove_task_cache;
};

before save => sub {
    my ($self, $master_row, $data ) = @_;
    $self->remove_task_cache;
};

before delete => sub {
    my ($self, $master_row, $data ) = @_;
    $self->remove_task_cache;
};

sub remove_task_cache {
    my ( $self ) = @_;
    cache->remove( qr/catalog_folder/ );
}


1;
