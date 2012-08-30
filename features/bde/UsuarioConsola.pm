package BaselinerX::Ktecho::UsuarioConsola;
use Moose;
use Switch;
use 5.010;

extends 'BaselinerX::Ktecho::Usuario';

#package com.ca.hardist.consola;
#import com.ca.hardist.util.Usuario;

has 'env_test' => ( is => 'rw', isa => 'Int', default => 1, required => 1 );
has 'env_ante' => ( is => 'rw', isa => 'Int', default => 2, required => 1 );
has 'env_prod' => ( is => 'rw', isa => 'Int', default => 3, required => 1 );
has 'usuario_potente' => (
    is      => 'rw',
    isa     => 'Bool',
    default => undef,
    builder => '_usuario_potente',
    lazy    => 1
);

sub start_stop {
    my ( $self, $cam_uc, $env ) = @_;

    switch ( $self->get_env($env) ) {
        case 'ENV_TEST' {

            #do nothing
        }
        case 'ENV_ANTE' {
            return
                   $self->usuario_potente
                or return $self->is_user_in_group( $cam_uc . "-RA" )
                or return $self->is_user_in_group( $cam_uc . "-AN" );
            case 'ENV_PROD' {

                # No se permite rearrancar en PROD, pero, por si acaso, sólo se lo
                # permitimos al RA
                return $self->usuario_potente
                    or return $self->is_user_in_group( $cam_uc . "-RA" );
            }
            else { return undef; }
        }

    }
}

sub view_config {
    my ($self, $cam_uc, $env ) = @_;

    # Por  ahora visualizar configuración y  logs está  asignado a  los mismos
    # perfiles
    return $self->view_logs( $cam_uc, $env );
}

sub view_logs {
    switch ( $self->get_env($env) ) {
        case 'ENV_TEST' {
            # Los programadores pueden ver logs de test
            return $self->usuario_potente
                or return $self->is_user_in_group( $cam_uc . "-RA" )
                or return $self->is_user_in_group( $cam_uc . "-AN" )
                or return $self->is_user_in_group( $cam_uc . "-SP" )
                or return $self->is_user_in_group( $cam_uc . "-PR" );
        }
        case 'ENV_ANTE' {
            return $self->usuario_potente
                or return $self->is_user_in_group( $cam_uc . "-RA" )
                or return $self->is_user_in_group( $cam_uc . "-AN" )
                or return $self->is_user_in_group( $cam_uc . "-SP" );
        }
        case 'ENV_PROD' {
            return $self->usuario_potente
                or return $self->is_user_in_group( $cam_uc . "-RA" )
                or return $self->is_user_in_group( $cam_uc . "-SP" );
        }
        else { return undef; }
    }
}

sub _usuario_potente {
    my $self = shift;

    return $self->is_user_in_group("SCM")
        or return $self->is_user_in_group("RPT-SCM")
        or return $self->is_user_in_group("RPT-WAS")
        or return $self->is_user_in_group("RPT-AIX");
}

sub get_env {
    my ( $self, $env ) = @_;

    return 'ENV_TEST' if ( $env =~ /TEST/i );
    return 'ENV_ANTE' if ( $env =~ /ANTE/i );
    return 'ENV_PROD' if ( $env =~ /PROD/i );
    return;
}

1;
