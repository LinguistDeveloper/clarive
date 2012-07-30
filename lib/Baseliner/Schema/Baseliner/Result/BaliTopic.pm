use utf8;
package Baseliner::Schema::Baseliner::Result::BaliTopic;

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliTopic

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->load_components("+Baseliner::Schema::Master");
__PACKAGE__->table("bali_topic");

__PACKAGE__->add_columns(
  "mid",
  {
    data_type => "numeric",
    is_nullable => 0,
  },
  "title",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "description",
  { data_type => "clob", is_nullable => 0 },
  "created_on",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_by",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "status",
  { data_type => "char", default_value => "O", is_nullable => 0, size => 1 },
  "id_category",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },
  "id_category_status",
  {
    data_type => "numeric",
    is_nullable => 0,
    size => 126,
  },  
  "id_priority",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "response_time_min",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "deadline_min",
  {
    data_type => "numeric",
    is_nullable => 1,
    size => 126,
  },
  "expr_response_time",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "expr_deadline",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "progress", { data_type => "number", is_nullable => 1, default_value=>0 },  
);


__PACKAGE__->set_primary_key("mid");

__PACKAGE__->belongs_to(
  "categories",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategories",
  { "id" => "id_category" },
);

__PACKAGE__->belongs_to(
  "status",
  "Baseliner::Schema::Baseliner::Result::BaliTopicStatus",
  { "id" => "id_category_status" },
);

__PACKAGE__->belongs_to(
  "priorities",
  "Baseliner::Schema::Baseliner::Result::BaliTopicPriority",
  { id => "id_priority" },
);

__PACKAGE__->has_many(
  "workflow",
  "Baseliner::Schema::Baseliner::Result::BaliTopicCategoriesAdmin",
  { 'foreign.id_category' => 'self.id_category' },
);

__PACKAGE__->master_setup( 'posts', ['topic','mid'] => ['post', 'BaliPost','mid'] );
__PACKAGE__->master_setup( 'files', ['topic','mid'] => ['file_version', 'BaliFileVersion','mid'] );
__PACKAGE__->master_setup( 'users', ['topic','mid'] => ['users', 'BaliUser','mid'] );
__PACKAGE__->master_setup( 'projects', ['topic','mid'] => ['project', 'BaliProject','mid'] );
__PACKAGE__->master_setup( 'topics', ['topic','mid'] => ['topic', 'BaliTopic','mid'] );  # topic_topic
__PACKAGE__->master_setup( 'revisions' => ['topic','mid'] => ['revision', 'BaliMaster','mid'] );  # topic_revision

sub badge_name {
    my ($self) =@_;
    my $cat = $self->categories;
    if( $cat->is_release ) {
        my $title = $self->title;
        $title =~ s{^(\w+\s+\w+)\s+.*$}{$1};
        return $title;
    } else {
        return sprintf '%s #%s', $cat->name, $self->mid;
    }
}

sub full_name {
    my ($self) =@_;
    sprintf '[%s] %s', $self->badge_name, $self->title;
}

sub my_releases {
    my ($self) = @_;
    my $rels = Baseliner->model('Baseliner::BaliTopicCategories')->search( { is_release => 1 }, { select => ['id'] } )->as_query;
    Baseliner->model('Baseliner::BaliMasterRel')->search(
        {   rel_type                  => 'topic_topic',
            to_mid                    => $self->mid,
            'topic_topic.id_category' => { -in => $rels }
        },
        { prefetch => [ {topic_topic=>'categories'}, 'topic_topic2' ] }
    )
}

sub is_in_release {
    my ($self) = @_;
    $self->my_releases->count();
}

1;
