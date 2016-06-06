package Baseliner::Schema::Migrations::0112_unify_list_topic_selector;
use Moose;

use Baseliner::Utils qw(_decode_json _encode_json);

sub upgrade {
    my $self = shift;

    my @rules = mdb->rule->find( { rule_type => 'form' } )->all;
    foreach my $rule (@rules) {
        my $json = eval { _decode_json( $rule->{rule_tree} ) } or do {
            warn "Cannot decode $rule->{id} rule_tree: $!. Skipped";
            next;
        };
        foreach my $el (@$json) {
            my $attributes = $el->{attributes};
            my $data       = $attributes->{data};

            if ( $attributes->{key} eq "fieldlet.system.list_topics" ) {
                $data->{fieldletType} = "fieldlet.system.list_topics";
                $data->{filter_data}  = '';
                $data->{filter_field} = '';
            }

            if ( $attributes->{key} eq "fieldlet.system.list_topics_selector" ) {
                $attributes->{key}  = "fieldlet.system.list_topics";
                $attributes->{name} = "Topic Selector";

                $data->{fieldletType} = "fieldlet.system.list_topics";
            }
        }

        my $new_tree_rule = _encode_json($json);
        mdb->rule->update( { id => $rule->{id} }, { '$set' => { rule_tree => $new_tree_rule } } );
    }
}

sub downgrade {
}

1;
