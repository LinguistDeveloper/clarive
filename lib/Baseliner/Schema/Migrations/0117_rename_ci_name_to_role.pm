package Baseliner::Schema::Migrations::0117_rename_ci_name_to_role;
use Moose;

use Baseliner::Utils qw(_encode_json _decode_json);

sub upgrade {
    my $self = shift;

    my $rs = mdb->rule->find( { rule_type => 'form' } );

    while ( my $r = $rs->next ) {
        my $rule_tree = eval { _decode_json( $r->{rule_tree} ) } or do {
            warn "Cannot decode rule ($r->{id}): $@! Skipped";
            next;
        };

        foreach my $attribute (@$rule_tree) {
            next unless my $role = $attribute->{attributes}->{data}->{var_ci_role};

            if ( ref $role ne 'ARRAY' ) {
                $role = [$role];
            }

            next unless grep { lc( $role->[0] ) eq $_ } ( '', 'ci', 'all', 'todos' );

            $role->[0] = 'Baseliner::Role::CI';

            $attribute->{attributes}->{data}->{var_ci_role} = $role;
        }

        $rule_tree = _encode_json($rule_tree);

        mdb->rule->update( { id => $r->{id} }, { '$set' => { rule_tree => $rule_tree } } );
    }
}

sub downgrade {
}

1;
