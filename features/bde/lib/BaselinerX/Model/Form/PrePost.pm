package BaselinerX::Model::Form::PrePost;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub combo_entornos_data {
    return [
        { value => 'TEST', show => 'TEST' },
        { value => 'ANTE', show => 'ANTE' },
        { value => 'PROD', show => 'PROD' }
    ];
}

sub combo_naturaleza_data {
    return [
        { nat => 'J2EE'     },
        { nat => 'FICHEROS' },
        { nat => '.NET'     },
        { nat => 'PUBLICO'  },
        { nat => 'ECLIPSE'  },
        { nat => 'VIGNETTE' },
        { nat => 'BIZTALK'  }
    ];
}

sub combo_block_data {
    return [ 
        { value => 'S', show => 'Si' },
        { value => 'N', show => 'No' }
    ];
}

sub combo_os_data {
    return [ { os => 'WIN' }, { os => 'UNIX' } ];
}

sub combo_prepost_data {
    return [ 
        { value => 'PRE' }, 
        { value => 'POST' } 
    ];
}

sub combo_server_data {
    my ( $self, $args ) = @_;

    my $rs = Baseliner->model('Harvest::BdePaquetePrepost')->search(
        {   pp_cam => $args->{cam},
            pp_env => $args->{env}
        },
        { columns => [qw{ pp_maq }], distinct => 1 }
    );
    rs_hashref($rs);
    my @data = $rs->all;

    return \@data;
}

sub _where {
    my ( $self, $p ) = @_;

    my $where;
    $where->{pp_env}        = $p->{env_name} if $p->{env_name};
    $where->{pp_prepost}    = $p->{prepost}  if $p->{prepost};
    $where->{pp_naturaleza} = $p->{nature}   if $p->{nature};
    $where->{pp_maq}        = $p->{server}   if $p->{server};
    $where->{pp_usu}        = $p->{user}     if $p->{user};

    return $where;
}

sub get_bde_paquete_prepost {
    my ( $self, $where ) = @_;

    my $rs = Baseliner->model('Harvest::BdePaquetePrepost')->search($where);
    rs_hashref($rs);
    my @data = $rs->all;

    return \@data;
}

sub grid_data {
    my ( $self, $env ) = @_;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $cam    = 'SCT';

    my $sql = qq{
        SELECT * 
        FROM   bde_paquete_prepost 
        WHERE  pp_cam = '$cam'
          AND  pp_env = '$env'
        ORDER  BY Decode(pp_env, 'TEST', 1, 
                                'ANTE', 2, 
                                'PROD', 3), 
                Decode(Trim(pp_naturaleza), 'ECLIPSE', 1, 
                                            'J2EE', 2, 
                                            '.NET', 3, 
                                            'FICHEROS', 4, 
                                            'DOCS', 5, 
                                            'PUBLICO', 6, 
                                            'VIGNETTE', 7, 
                                            8), 
                Decode(Trim(pp_prepost), 'PRE', 1, 
                                        'POST', 2), 
                pp_orden  
    };

    my @data = $har_db->db->array_hash($sql);

    for my $ref (@data) {

        # Concateno usuario y server...
        $ref->{pp_usumaq} = $ref->{pp_usu} . '@' . $ref->{pp_maq};

        # pp_activo a true/false para el Checkbox en ExtJS...
        $ref->{pp_activo} = ( $ref->{pp_activo} =~ m/S/ix ) ? 'true' : 'false';

        # Cambio "bloquea" por sí/no en lugar de s/N
        $ref->{pp_block} = ( $ref->{pp_block} =~ m/S/ix ) ? 'Si' : 'No';
    }

    return \@data;
}

sub delete_bde_prepost {
    my ( $self, $args ) = @_;

    my $rs = Baseliner->model('Harvest::BdePaquetePrepost')->search(
        {   pp_cam        => $args->{cam},
            pp_env        => $args->{entorno},
            pp_exec       => $args->{exec},
            pp_naturaleza => $args->{naturaleza},
            pp_usu        => $args->{user},
            pp_maq        => $args->{maq},
            pp_prepost    => $args->{prepost}
        }
    );
    $rs->delete;

    return;
}

sub create_bde_prepost {
  my ( $self, $args ) = @_;
  my $rs = Baseliner->model('Harvest::BdePaquetePrepost')->search($args);
  rs_hashref($rs);
  my @data = $rs->all;
  Baseliner->model('Harvest::BdePaquetePrepost')->create($args) unless @data;
  return;
}

1;
