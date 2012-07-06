use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesStatus;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("bali_topic_categories_status");
__PACKAGE__->add_columns(
  "id_category",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },
  "id_status",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },

);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut



# Created by DBIx::Class::Schema::Loader v0.07012 @ 2012-01-17 18:19:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kPypxdTqp7bcXeLkSRdC7A

__PACKAGE__->belongs_to(
  "status",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { id => "id_status" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
