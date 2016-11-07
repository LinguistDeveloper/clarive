package Baseliner::Schema::Migrations::0122_common_variables_def_value;
use Moose;

sub upgrade {
    my $self = shift;

    my $var_mids = ci->variable->find->fields( { mid => 1, var_default => 1, _id => 0 } );

    while ( my $variable = $var_mids->next() ) {

        if ( $variable->{var_default} && ref( $variable->{var_default} ) ne 'ARRAY' ) {
            my $var = ( { '*' => $variable->{var_default} } );

            mdb->master->update( { mid => $variable->{mid} }, { '$set' => { variables => $var } }, { safe => 1 } );
            mdb->master_doc->update( { mid => $variable->{mid} }, { '$set' => { variables => $var } }, { safe => 1 } );
        }
    }
}

sub downgrade {
}

1;
