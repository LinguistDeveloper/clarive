package BaselinerX::CI::service;
use Baseliner::Moose;

with 'Baseliner::Role::CI';
with 'Baseliner::Role::CI::CatalogService';


sub icon { '/static/images/icons/catalog-light.png' }

1;
