package Baseliner::Role::CI::VariableStash;
use Moose::Role;
use Baseliner::Utils qw(_md5);
with 'Baseliner::Role::CI';

has variables => qw(is rw isa HashRef), default=>sub{ +{} };

after load_data => sub {
    my $self = shift;
    my ( $mid, $data ) = @_;

    my $allvars = $data->{variables};

    if( ref $allvars eq 'HASH' ) {
        if ( $self->does('Baseliner::Role::CI::Variable') ) {
            if ( defined $data->{var_type} && $data->{var_type} eq 'password' ) {
                for my $bl ( keys %$allvars ) {
                    $data->{variables}{$bl} = $self->_decrypt_variable( $data->{variables}{$bl} );
                }
            }
        }
        else {
            for my $bl ( keys %$allvars ) {

                my $vars = $allvars->{$bl} || {};

                for my $var ( keys %$vars ) {
                    if ( my $meta = ci->variable->search_ci( name => $var ) ) {
                        if ( defined $meta->var_type && $meta->var_type eq 'password' ) {
                            $data->{variables}{$bl}{$var} = $self->_decrypt_variable( $data->{variables}{$bl}{$var} );
                        }
                    }
                }
            }
        }
    }
};

around save_data => sub {
    my $orig = shift;
    my $self = shift;
    my ( $master_row, $data, $opts, $old ) = @_;

    my $allvars = $self->variables || {};

    if ( $self->does('Baseliner::Role::CI::Variable') ) {
        if ( defined $self->var_type && $self->var_type eq 'password' ) {
            for my $bl ( keys %$allvars ) {
                if( $self->variables->{$bl} eq $Baseliner::CI::password_hide_str ) {
                    $self->variables->{$bl} = $old->{variables}{$bl};
                }
                else {
                    $self->variables->{$bl} =  $self->_encrypt_variable( $self->variables->{$bl} );
                }
            }
        }
    }
    else {
        for my $bl ( keys %$allvars ) {
            my $vars = $allvars->{$bl};
            for my $var ( keys %$vars ) {
                if ( my $meta = ci->variable->search_ci( name => $var ) ) {
                    if ( defined $meta->var_type && $meta->var_type eq 'password' ) {
                        if( $self->variables->{$bl}{$var} eq $Baseliner::CI::password_hide_str ) {
                            $self->variables->{$bl}{$var} = $old->{variables}{$bl}{$var};
                        }
                        else {
                            $self->variables->{$bl}{$var} = $self->_encrypt_variable( $self->variables->{$bl}{$var} );
                        }
                    }
                }
            }
        }
    }

    $self->$orig(@_);
};

sub cloak_password_variables {
    my $self = shift;

    my $allvars = $self->variables;

    if ( $self->does('Baseliner::Role::CI::Variable') ) {
        if ( defined $self->var_type && $self->var_type eq 'password' ) {
            for my $bl ( keys %$allvars ) {
                $allvars->{$bl} = $Baseliner::CI::password_hide_str;
            }
        }
    }
    else {
        for my $bl ( keys %$allvars ) {
            my $vars = $allvars->{$bl};
            for my $var ( keys %$vars ) {
                if ( my $meta = ci->variable->search_ci( name => $var ) ) {
                    if ( defined $meta->var_type && $meta->var_type eq 'password' ) {
                        $allvars->{$bl}{$var} = $Baseliner::CI::password_hide_str;
                    }
                }
            }
        }
    }

    return $allvars;
}

sub _encrypt_variable {
    my $self = shift;
    my ( $value ) = @_;

    my $key = Baseliner->decrypt_key;
    return Baseliner->encrypt(
        substr( _md5(), 0, 10 ) . $value . substr( _md5(), 0, 10 ),
        $key
    );
}

sub _decrypt_variable {
    my $self = shift;
    my ( $value ) = @_;

    my $key = Baseliner->decrypt_key;
    return substr Baseliner->decrypt( $value, $key ), 10, -10;
}

1;
