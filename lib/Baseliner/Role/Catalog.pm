package Baseliner::Role::Catalog;
use Moose::Role;

requires 'catalog_add';
requires 'catalog_del';
requires 'catalog_url';
requires 'catalog_icon';
requires 'catalog_list';
requires 'catalog_name';
requires 'catalog_description';

1;
