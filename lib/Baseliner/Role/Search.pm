=head1 Baseliner::Role::Search

This role is used by the CI, Topic and Job libs
to register as search providers.

=cut
package Baseliner::Role::Search;
use Moose::Role;

requires 'search_query';
requires 'search_provider_name';
requires 'search_provider_type';
requires 'user_can_search';

package SearchResult;
use Moose;
has icon => qw/is ro/;

no Moose;
__PACKAGE__->meta->make_immutable;

1;
