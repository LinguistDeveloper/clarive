#!/usr/bin/perl
package BaselinerX::Model::Form::Vignette;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Data::Dumper;
BEGIN { extends 'Catalyst::Model' }

sub get_entornos {
  return [{env => 'TEST'}, {env => 'ANTE'}, {env => 'PROD'}];
}

sub get_servers {
  my ($self, $cam) = @_;
  my $sql = qq{
    SELECT   vig_maq server
        FROM bde_paquete_vignette
       WHERE vig_cam = SUBSTR ('$cam', 1, 3)
    ORDER BY DECODE (vig_env, 'TEST', 1, 'ANTE', 2, 'PROD', 3), vig_orden
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data = $har_db->db->array_hash($sql);
  \@data;
}

sub get_usuario_funcional {
  my ($self, $cam, $env) = @_;
  my $user = 'v'
    . lc(substr($env, 0, 1))
    . lc($cam) . ':g'
    . lc(substr($env, 0, 1))
    . lc($cam);
  return [{user => $user}];
}

sub get_grid {
  my ($self, $cam, $env) = @_;
  my $sql = qq{
    SELECT   vig_usu, vig_grupo, vig_maq, vig_accion code, vig_pausa pausa,
             vig_activo active
        FROM bde_paquete_vignette
       WHERE vig_cam = SUBSTR ('SCT', 1, 3) AND vig_env = '$env'
    ORDER BY vig_orden
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($sql);
  for my $ref (@data) {
    $ref->{usu}    = "$ref->{vig_usu}:$ref->{vig_grupo}\@$ref->{vig_maq}";
    $ref->{pausa}  = ($ref->{pausa} eq 'S') ? 'true' : 'false';
    $ref->{active} = ($ref->{active} eq 'S') ? 'true' : 'false';
  }
  \@data;
}

sub add_row {
  my ($self, $p) = @_;
  ($p->{vig_usu}, $p->{vig_grupo}) = split(/:/, $p->{c_user});
  $p->{vig_pausa} = ($p->{vig_pausa} eq 'true') ? 'S' : 'N';
  $p->{vig_orden} = $self->get_max_order($p->{vig_cam}, $p->{vig_env}) || 1;
  delete $p->{c_user};

  # Check if there is already one entry with the same params.
  my $vig_orden_bkp = $p->{vig_orden};
  delete $p->{vig_orden};  # Got to delete this or we won't find anything.
  my $rs = Baseliner->model('Harvest::BdePaqueteVignette')->search($p);
  rs_hashref($rs);
  my @data = $rs->all;

  $p->{vig_orden} = $vig_orden_bkp;  # Restore it!
  Baseliner->model('Harvest::BdePaqueteVignette')->create($p)
    unless scalar @data;  # Avoid duplicates.

  return;
}

sub compose_usu_values {
  my ($self, $usu) = @_;
  my ($vig_usu, $vig_grupo, $vig_maq) = $usu =~ m/(.+):(.+)@(.+)/xi;
  return $vig_usu, $vig_grupo, $vig_maq;
}

sub get_max_order {
  my ($self, $cam, $env) = @_;
  my $query = qq{
    SELECT MAX (vig_orden) + 1 vig_orden
      FROM bde_paquete_vignette
     WHERE vig_env = '$env' AND vig_cam = '$cam'
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  $har_db->db->value($query);
}

sub delete_row {
  my ($self, $cam, $p) = @_;
  ($p->{vig_usu}, $p->{vig_grupo}, $p->{vig_maq}) =
    $self->compose_usu_values($p->{usu});
  $p->{vig_pausa}  = ($p->{vig_pausa}  eq 'true') ? 'S' : 'N';
  $p->{vig_activo} = ($p->{vig_activo} eq 'true') ? 'S' : 'N';
  delete $p->{usu};
  my $rs = Baseliner->model('Harvest::BdePaqueteVignette')->search($p);
  $rs->delete;
  return;
}

sub raise_order {
  my ($self, $cam, $p) = @_;

  ($p->{vig_usu}, $p->{vig_grupo}, $p->{vig_maq}) =
    $self->compose_usu_values($p->{usu});
  $p->{vig_pausa}  = ($p->{vig_pausa}  eq 'true') ? 'S' : 'N';
  $p->{vig_activo} = ($p->{vig_activo} eq 'true') ? 'S' : 'N';
  delete $p->{usu};

  my $rs =
    Baseliner->model('Harvest::BdePaqueteVignette')
    ->search($p, {columns => 'vig_orden'});
  rs_hashref($rs);
  my $orden = int($rs->next->{vig_orden});

  my $update_row =
    Baseliner->model('Harvest::BdePaqueteVignette')
    ->search({vig_orden => $orden - 1});
  rs_hashref($update_row);
  $update_row->update({vig_orden => $orden});

  $rs->update({vig_orden => $orden - 1});
  return;
}

sub update_row {
  my ($self, $cam, $p) = @_;

  ($p->{vig_usu}, $p->{vig_grupo}, $p->{vig_maq}) =
    $self->compose_usu_values($p->{usu});

#    $p->{vig_pausa}  = ( $p->{vig_pausa}  eq 'true' ) ? 'N' : 'S';
#    $p->{vig_activo} = ( $p->{vig_activo} eq 'true' ) ? 'N' : 'S';
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
