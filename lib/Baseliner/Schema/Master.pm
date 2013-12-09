package Baseliner::Schema::Master;
use strict;

=head2 master_setup

Sets up a master-rel relashionship.

From "topic" to "post":

    __PACKAGE__->master_setup( 'posts', ['topic','mid'] => ['post', 'BaliPost','mid'] );

Then you can use it like this:

    $row->posts;
    $row->children; # all children
    $row->parents; # all parents
    $row->master;  # my master row

    master_new 'post' => 'nanana' => sub { my $mid = shift;
        $row->add_to_posts({ text=>'nanana', created_by=>$c->username, mid=>$mid }, { rel_type=>'topic_post' });
    };

    my $post = $c->model('BaliPost')->find( 999 );
    $row->remove_from_posts( $post );

Equivalent to:

    Baseliner::Schema::Baseliner::Result::BaliMasterRel->belongs_to( topic =>'Baseliner::Schema::Baseliner::Result::BaliTopic', { 'foreign.mid'=>'self.from_mid' } );
    Baseliner::Schema::Baseliner::Result::BaliMasterRel->belongs_to( post =>'Baseliner::Schema::Baseliner::Result::BaliPost', { 'foreign.mid'=>'self.to_mid' });
    $self->has_many('topic_post' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel', { 'foreign.from_mid' => 'self.mid' });
    $self->many_to_many('posts' => 'topic_post', 'post');

=cut 
sub master_setup {
    my ($self, $name, $from, $to) = @_;

    my ($from_name, $from_col) = @$from;
    my ($to_name, $to_class, $to_col) = @$to;

    $from_col //= 'mid';
    $to_col //= 'mid';

    my $rel_type = $from_name .'_'. $to_name;
    my $rel_type_inverse = $to_name .'_'. $from_name;
    $rel_type_inverse = $rel_type_inverse . '2' if $rel_type eq $rel_type_inverse;

    my $foreign = "Baseliner::Schema::Baseliner::Result::$to_class";

    # especific 
    # topic_post (to get the related topic row)
    Baseliner::Schema::Baseliner::Result::BaliMasterRel->belongs_to(
        $rel_type, $self,
        { "foreign.$from_col" => 'self.from_mid' },
        { cascade_delete => 0 , on_delete=>undef, is_foreign_key_constraint=>0, },
    );
    # topic_post_to (to get the related post row)
    Baseliner::Schema::Baseliner::Result::BaliMasterRel->belongs_to(
        "${rel_type}_to", $foreign,
        { "foreign.$from_col" => 'self.to_mid' },
        { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>0, },
    );
    # post_topic (inverse relationship)
    Baseliner::Schema::Baseliner::Result::BaliMasterRel->belongs_to(
        $rel_type_inverse , $foreign,
        { "foreign.$to_col" => 'self.to_mid' },
        { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>0, },
    );
    $self->has_many(
        $rel_type,
        'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
        { 'foreign.from_mid' => "self.$from_col", },
        { where=>{'rel_type' => $rel_type}, cascade_delete=>0, on_delete=>undef, is_foreign_key_constraint=>0, }
    );
    $self->many_to_many( $name, $rel_type, $rel_type_inverse );

    # generic 
    $self->belongs_to(
      "master",
      "Baseliner::Schema::Baseliner::Result::BaliMaster",
      { "foreign.mid" => "self.mid" },
      { cascade_delete => 0, is_foreign_key_constraint=>1, },
    );

    $self->has_many(
        'children' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
        { 'foreign.from_mid' => 'self.mid' },
        { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>0, },
    );
    $self->has_many(
        'parents' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
        { 'foreign.to_mid' => 'self.mid' },
        { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>0, },
    );

    # XXX foreign - not sure this is good, maybe children-parent should be a generic thing
    eval "require $foreign";
    unless( $@ ) {
        $foreign->has_many(
            'children' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
            { 'foreign.from_mid' => 'self.mid' },
        ) unless $foreign->can('children');
        $foreign->has_many(
            'parents' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
            { 'foreign.to_mid' => 'self.mid' },
        ) unless $foreign->can('parents');
    }

}

# simple master relation, but no master_rels, used by bali_post, file_version, baselines...
sub has_master {
    my ($self, $mid_col ) = @_;
    $mid_col ||= 'mid'; 

    $self->belongs_to(
      "master",
      "Baseliner::Schema::Baseliner::Result::BaliMaster",
      { "mid" => $mid_col },
      { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>1, },
    );
    $self->has_many(
        'children' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
        { 'foreign.from_mid' => 'self.mid' },
        { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>0, },
    );
    $self->has_many(
        'parents' => 'Baseliner::Schema::Baseliner::Result::BaliMasterRel',
        { 'foreign.to_mid' => 'self.mid' },
        { cascade_delete => 0, on_delete=>undef, is_foreign_key_constraint=>0, },
    );
}

1;
