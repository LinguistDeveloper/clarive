package Baseliner::Model::Releases;
use Moose;
extends qw/Catalyst::Model/;

use namespace::clean;
use Baseliner::Utils;
use Try::Tiny;

=head1 release_items

Returs a hash where the keys are items and the values
are lists of releases where the item belongs.

=cut
sub release_items {
	my ($self, %p ) = @_;
    my %releases;
	my $search = \%p;
    my $rs_rel = Baseliner->model('Baseliner::BaliRelease')->search($search,{ prefetch=>'bali_release_items' });
	$rs_rel->result_class('DBIx::Class::ResultClass::HashRefInflator');
	while( my $r = $rs_rel->next ) {
        try {
            for my $item ( _array $r->{bali_release_items} ) {
                my $ns = $item->{ns};
                push @{ $releases{ $ns } }, { name=>$r->{name}, id=>$r->{id} };
            }
        };
	}
	return %releases;
}

# makes sure all releases are updated
sub update_bl {
    my ($self,%p) = @_;
    my $list = Baseliner->model('Namespaces')->list( does=>'Baseliner::Role::Namespace::Release' );
    for my $rel ( _array $list->data ) {
        try {
            my $id = $rel->ns_id;
            return unless $id;
            my $row = Baseliner->model('Baseliner::BaliRelease')->find( $id ); 
			return unless ref $row;
            my $bl = $rel->bl_from_contents;
            return unless $bl;
            $row->bl( $bl );
            $row->update;
        } catch { 
            _log "Could not update bl for namespace " . $rel->ns . ": " . shift;
        };
    }
}
1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 The Authors of baseliner.org

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

