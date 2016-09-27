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

        foreach my $atribute (@$rule_tree) {
            $atribute->{attributes}->{data}->{var_ci_role}[0] = 'Baseliner::Role::CI'
              if (
                ( exists $atribute->{attributes}->{data}->{var_ci_role} )
                && (   ( $atribute->{attributes}->{data}->{var_ci_role}[0] eq "" )
                    || ( $atribute->{attributes}->{data}->{var_ci_role}[0] eq "CI" )
                    || ( $atribute->{attributes}->{data}->{var_ci_role}[0] eq "All" )
                    || ( $atribute->{attributes}->{data}->{var_ci_role}[0] eq "Todos" ) )
              );
        }

        $rule_tree = _encode_json($rule_tree);

        mdb->rule->update( { id => $r->{id} }, { '$set' => { rule_tree => $rule_tree } } );
    }
}

sub downgrade {
}

1;
