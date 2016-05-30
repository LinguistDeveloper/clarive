package Baseliner::Schema::Migrations::0111_update_fieldlet_active;
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
            my $data       = $el->{attributes}->{data};
            if ( !defined( $attributes->{active} ) ) {
                $attributes->{active} = \1;
            }
            if ( !defined( $data->{active} ) ) {
                $data->{active} = \1;
            }
        }

        my $new_tree_rule = _encode_json($json);
        mdb->rule->update( { id => $rule->{id} }, { '$set' => { rule_tree => $new_tree_rule } } );
    }
}

sub downgrade {

}

1;
