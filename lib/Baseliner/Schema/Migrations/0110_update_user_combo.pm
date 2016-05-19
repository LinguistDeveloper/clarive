package Baseliner::Schema::Migrations::0110_update_user_combo;
use Moose;

use Baseliner::Utils qw(_decode_json _encode_json _array_or_commas);

sub upgrade {
    my @rules = mdb->rule->find( { rule_type => 'form' } )->all;
    foreach my $rule (@rules) {
        my $json = eval { _decode_json( $rule->{rule_tree} ) } or do {
            warn "Cannot decode $rule->{id} rule_tree: $!. Skipped";
            next;
        };

        foreach my $el (@$json) {
            my $attributes = $el->{attributes};
            my $data       = $attributes->{data};

            if ( $attributes->{key} eq "fieldlet.system.users" ) {
                my @filters = _array_or_commas delete $data->{filter};

                my @role_ids;
                foreach my $filter (@filters) {
                    if ( !defined($filter) || $filter eq 'none' ) {
                        next;
                    }

                    my $role = mdb->role->find_one({ role => $filter });

                    push @role_ids, $role->{id} if $role;
                }

                $data->{roles_filter} = join ',', @role_ids;
            }
        }

        my $new_tree_rule = _encode_json($json);
        mdb->rule->update( { id => $rule->{id} }, { '$set' => { rule_tree => $new_tree_rule } } );
    }
}

sub downgrade {

}

1;
