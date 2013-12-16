package Baseliner::Schema::Baseliner::Result::BaliProject;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->load_components("+Baseliner::Schema::Master");

=head1 NAME

Baseliner::Schema::Baseliner::Result::BaliProject

=cut

__PACKAGE__->table("bali_project");
__PACKAGE__->add_columns(
  "mid", {
    data_type => "NUMBER",
    is_nullable => 0,
    is_auto_increment => 1,
  },     
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "data",
  { data_type => "clob", is_nullable => 1 },
  "ns",
  {
    data_type => "varchar2",
    default_value => "/",
    is_nullable => 1,
    size => 1024,
  },
  "bl",
  {
    data_type => "varchar2",
    default_value => "*",
    is_nullable => 1,
    size => 1024,
  },
  "ts",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "domain", { data_type => "varchar2", is_nullable => 1, size => 1 },
  "description", { data_type => "clob", is_nullable => 1 },
  "id_parent",
  {
    data_type => "number",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "nature", { data_type => "varchar2", is_nullable => 1, size => 1024 },
  "active", { data_type => "char", is_nullable => 1, size => 1, default => '1' },
);
__PACKAGE__->set_primary_key("mid");

# __PACKAGE__->has_many(
#   "bali_project_items",
#   "Baseliner::Schema::Baseliner::Result::BaliProjectItems",
#   { "foreign.id_project" => "self.mid" },
#   {},
# );

__PACKAGE__->belongs_to(
  "parent",
  "Baseliner::Schema::Baseliner::Result::BaliProject",
  { mid => "id_parent" },
);

__PACKAGE__->belongs_to(
  "roleuser",
  "Baseliner::Schema::Baseliner::Result::BaliRoleuser",
  { id_project => "mid" },
);

__PACKAGE__->master_setup( 'files', ['project','mid'] => ['file_version', 'BaliFileVersion','mid'] );
__PACKAGE__->master_setup( 'repositories', ['project','mid'] => ['repository','BaliMaster', 'mid'] => );

sub id { $_[0]->mid; }   # for backwards compatibility

# used in LcController to generate the tree
sub releases {
    my ($self ) = @_;

    my $rel_chi = DB->BaliTopic->search({
       'categories.is_release' => 1,
    },{ 
       join=>['categories'], select=>['me.mid'],
    })->as_query;

    DB->BaliTopic->search(
            { 'me.mid'=>{-in=>$rel_chi }, 'to_children.to_mid' => $self->mid },
            { join=>[{ 'master' => { 'children' => 'to_children' } }] }
    );
}

1;
