#!/usr/bin/perl
package BaselinerX::Model::Form::Vignette;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub get_entornos {
    return [ { env => 'TEST' }, { env => 'ANTE' }, { env => 'PROD' } ];
}

sub get_servers {
    my ( $self, $cam ) = @_;
    my $sql = qq{
        SELECT vig_maq server
        FROM   bde_paquete_vignette 
        WHERE  vig_cam = Substr('$cam', 1, 3) 
        ORDER  BY Decode(vig_env, 'TEST', 1, 
                                'ANTE', 2, 
                                'PROD', 3), 
                vig_orden
    };

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my @data = $har_db->db->array_hash($sql);

    return \@data;
}

sub get_usuario_funcional {
    my ( $self, $cam, $env ) = @_;
    my $user
        = 'v'
        . lc( substr( $env, 0, 1 ) )
        . lc($cam) . ':g'
        . lc( substr( $env, 0, 1 ) )
        . lc($cam);

    return [ { user => $user } ];
}

sub get_grid {
    my ( $self, $cam, $env ) = @_;

    my $sql = qq{
        SELECT vig_usu, 
            vig_grupo, 
            vig_maq, 
            vig_accion code, 
            vig_pausa  pausa, 
            vig_activo active 
        FROM   bde_paquete_vignette 
        WHERE  vig_cam = Substr('SCT', 1, 3) 
            AND vig_env = '$env' 
        ORDER  BY vig_orden  
    };

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my @data   = $har_db->db->array_hash($sql);

    for my $ref (@data) {
        $ref->{usu}    = "$ref->{vig_usu}:$ref->{vig_grupo}\@$ref->{vig_maq}";
        $ref->{pausa}  = ( $ref->{pausa} eq 'S' ) ? 'true' : 'false';
        $ref->{active} = ( $ref->{active} eq 'S' ) ? 'true' : 'false';
    }

    return \@data;
}

sub add_row {
    my ( $self, $p ) = @_;

    ( $p->{vig_usu}, $p->{vig_grupo} ) = split( /:/, $p->{c_user} );
    $p->{vig_pausa} = ( $p->{vig_pausa} eq 'true' ) ? 'S' : 'N';
    $p->{vig_orden} = $self->get_max_order( $p->{vig_cam}, $p->{vig_env} ) || 1;
    delete $p->{c_user};

    open my $file, '>', 'C:\test2.txt';
    print $file Data::Dumper::Dumper $p;

    my $insert = Baseliner->model('Harvest::BdePaqueteVignette')->create($p);

    return;
}

sub compose_usu_values {
    my ( $self, $usu ) = @_;

    my ( $vig_usu, $vig_grupo, $vig_maq ) = $usu =~ m/(.+):(.+)@(.+)/xi;

    return $vig_usu, $vig_grupo, $vig_maq;
}

sub get_max_order {
    my ( $self, $cam, $env ) = @_;
    my $query = qq{
        SELECT MAX(vig_orden) + 1 vig_orden 
        FROM   bde_paquete_vignette 
        WHERE  vig_env = '$env' 
            AND vig_cam = '$cam'  
    };

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    return $har_db->db->value($query);
}

sub delete_row {
    my ( $self, $cam, $p ) = @_;

    ( $p->{vig_usu}, $p->{vig_grupo}, $p->{vig_maq} )
        = $self->compose_usu_values( $p->{usu} );
    $p->{vig_pausa}  = ( $p->{vig_pausa}  eq 'true' ) ? 'S' : 'N';
    $p->{vig_activo} = ( $p->{vig_activo} eq 'true' ) ? 'S' : 'N';
    delete $p->{usu};

    open my $filename, '>', 'C:\test.txt';
    print $filename Data::Dumper::Dumper $p;

    my $rs = Baseliner->model('Harvest::BdePaqueteVignette')->search($p);
    $rs->delete;

    return;
}

sub raise_order {
    my ( $self, $cam, $p ) = @_;

    ( $p->{vig_usu}, $p->{vig_grupo}, $p->{vig_maq} )
        = $self->compose_usu_values( $p->{usu} );
    $p->{vig_pausa}  = ( $p->{vig_pausa}  eq 'true' ) ? 'S' : 'N';
    $p->{vig_activo} = ( $p->{vig_activo} eq 'true' ) ? 'S' : 'N';
    delete $p->{usu};

    my $rs = Baseliner->model('Harvest::BdePaqueteVignette')
        ->search( $p, { columns => 'vig_orden' } );
    rs_hashref($rs);
    my $orden = int( $rs->next->{vig_orden} );

    my $update_row = Baseliner->model('Harvest::BdePaqueteVignette')
        ->search( { vig_orden => $orden - 1 } );
    rs_hashref($update_row);
    $update_row->update( { vig_orden => $orden } );

    $rs->update( { vig_orden => $orden - 1 } );

    return;
}

sub update_row {
    my ( $self, $cam, $p ) = @_;

    ( $p->{vig_usu}, $p->{vig_grupo}, $p->{vig_maq} )
        = $self->compose_usu_values( $p->{usu} );

    open my $filename, '>', 'C:\prueba.txt';
    print $filename Data::Dumper::Dumper $p;

#    $p->{vig_pausa}  = ( $p->{vig_pausa}  eq 'true' ) ? 'N' : 'S';
#    $p->{vig_activo} = ( $p->{vig_activo} eq 'true' ) ? 'N' : 'S';
#
#    open my $filename, '>', 'C:\prueba.txt';
#    print $filename Data::Dumper::Dumper $p;
#
#    delete $p->{usu};
#
#    $p->{vig_pausa}  = ( $p->{vig_pausa}  eq 'S' ) ? 'N' : 'S';
#    $p->{vig_activo} = ( $p->{vig_activo} eq 'S' ) ? 'N' : 'S';
#
#    my $rs = Baseliner->model('Harvest::BdePaqueteVignette')->search($p);
#    $rs->update(
#        {   vig_pausa  => $p->{vig_pausa},
#            vig_activo => $p->{vig_activo}
#        }
#    );

    return;
}

1;
