package Baseliner::Role::Search;
use Moose::Role;

requires 'search_query';
requires 'search_provider_name';
requires 'search_provider_type';

package SearchResult;
use Moose;
has icon => qw/is ro/;

1;
