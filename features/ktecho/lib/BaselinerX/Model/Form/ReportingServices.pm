package BaselinerX::Model::Form::ReportingServices;
use strict;
use warnings;
use Baseliner::Utils;
use Baseliner::Plug;
use 5.010;
BEGIN { extends 'Catalyst::Controller' }

sub combo_recursos_data { # Str -> ArrayRef[HashRef]
  # Pilla los datos para rellenar el store del combobox recursos
  my ($self, $cam) = @_;
  my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 7;
  my $sql = $ver == 12 ? $self->combo_recursos_data_r12($cam)
                       : $self->combo_recursos_data_r7($cam);
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($sql);
  return \@data;
}

sub combo_recursos_data_r12 { # Str -> Str
  my ($self, $cam) = @_;
  _log "Ejecutando query R12...";
  qq{
    SELECT DISTINCT '$cam' cam, pathfullname || '\\' || itemname item
               FROM harversions v,
                    haritemname n,
                    harpathfullname pa,
                    harversions vp
              WHERE v.itemtype = 1
                AND n.nameobjid = v.itemnameid
                AND v.pathversionid = vp.versionobjid
                AND vp.itemobjid = pa.itemobjid
                AND pa.pathfullnameupper LIKE '\\' || '$cam' || '\\RS%'
           GROUP BY pathfullname || '\\' || itemname
           ORDER BY 2
  };
}

sub combo_recursos_data_r7 { # Str -> Str
  my ($self, $cam) = @_;
  _log "Ejecutando query R7...";
  qq{
    SELECT DISTINCT '$cam' cam, pathfullname || '\\' || itemname item
               FROM haritems i, harpathfullname pf
              WHERE i.itemtype = 1
                AND i.parentobjid = pf.itemobjid
                AND pf.pathfullnameupper LIKE '\\' || '$cam' || '\\RS%'
           GROUP BY pathfullname || '\\' || itemname
           ORDER BY 2
  };
}

sub _data_grid { # Str -> ArrayRef[HashRef]
  my ($self, $cam) = @_;
  my $sql = qq{
    -- Note: This query should work in both Harvest versions.
    SELECT DISTINCT rs_env AS env, REPLACE (rs_elemento, '\\', '\\\\') AS item,
                    REPLACE (rs_fullname, '\\', '\\\\') AS fullname
               FROM bde_paquete_rs
              WHERE rs_env = '$cam'
           ORDER BY 2
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($sql);

  # Formateo el array
  for my $ref (@data) {
    $ref->{item}     =~ s/\\\\/\\/g;
    $ref->{fullname} =~ s/\\\\/\\/g;
  }
  return \@data;
}

sub delete_bde_paquete_rs { # HashRef -> Undef
  my ($self, $where) = @_;
  my $rs = Baseliner->model('Harvest::BdePaqueteRs')->search($where);
  $rs->delete;
  return;
}

sub insert_bde_paquete_rs { # HashRef -> Undef
  my ($self, $args) = @_;
  my $rs = Baseliner->model('Harvest::BdePaqueteRs')->create($args);
  return;
}

1;
