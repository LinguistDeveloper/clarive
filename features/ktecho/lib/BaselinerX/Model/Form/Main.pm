package BaselinerX::Model::Form::Main;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Sugar;
use Baseliner::Utils;
use BaselinerX::Ktecho::CamUtils;
use Data::Dumper;
use Switch;
use utf8;
BEGIN { extends 'Catalyst::Model' }

sub get_main_data {
  my ($self, $formobjid, $usrobjid, $username, $cam) = @_;

  # Harvest query...
  my $sql = qq{
    SELECT TRIM (statename) statename, username,
           TRIM (environmentname) environmentname, e.envobjid, hf.modifiedtime,
           hf.formname, pas_codigo, TRIM (f.paq_ciclo) AS paq_ciclo, paq_cambio,
           paq_observaciones, paq_inc, paq_pet, paq_pro, paq_comentario, paq_mant,
           paq_tipo, paq_desc, paq_usuario
      FROM harstate s,
           harpackage p,
           harassocpkg a,
           harenvironment e,
           harform hf,
           bde_paquete f,
           harallusers u
     WHERE 1 = 1
       AND f.formobjid = a.formobjid
       AND hf.formobjid = a.formobjid
       AND a.assocpkgid = p.packageobjid
       AND p.stateobjid = s.stateobjid
       AND e.envobjid = p.envobjid
       AND a.formobjid = '$formobjid'
       AND u.usrobjid = '$usrobjid'
       AND u.username = '$username'
  };

  # New HARVEST database instance...
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  # Data in array of hashes...
  my @data = $har_db->db->array_hash($sql);

  # New INF Instance...
  my $inf_db = BaselinerX::Model::InfUtil->new({cam => $cam});

  BOOLFORMAT:
  for my $ref (@data) {
    # Checks whether the package has 'ANTE'...
    $ref->{tiene_ante} = $inf_db->tiene_ante;

    # Is it public?
    $ref->{es_publica} = $inf_db->is_public_bool;

    # We should just have one row...
    last BOOLFORMAT;
  }

  \@data;
}

sub get_natures {
  my ($self, $cam, $envobjid) = @_;

  # Inits HARVEST database instance...
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  # .NET?
  my $sql = qq{
    SELECT COUNT (*)
      FROM haritems i, harview w, harrepinview r, harpathfullname p
     WHERE r.viewobjid = w.viewobjid
       AND i.repositobjid = r.repositobjid
       AND w.envobjid = '$envobjid'
       AND i.parentobjid = p.itemobjid
       AND pathfullnameupper LIKE '\\$cam\\.NET%'
       AND (   UPPER (TRIM (i.itemname)) LIKE '%.VBPROJ'
            OR UPPER (TRIM (i.itemname)) LIKE '%.CSPROJ'
           )
    };
  my $has_net_projects = ($har_db->db->value($sql) > 0) ? 1 : 0;

  # ORACLE?
  $sql = qq{
      SELECT COUNT (*)
        FROM harpathfullname
       WHERE pathfullnameupper LIKE '\\$cam\\ORACLE%'
    };
  my $has_ora_projects = ($har_db->db->value($sql) > 0) ? 1 : 0;

  # VIGNETTE?
  $sql = qq{
      SELECT COUNT (*)
        FROM harpathfullname
       WHERE pathfullnameupper LIKE '\\$cam\\VIGNETTE%'
    };
  my $has_vig_projects = ($har_db->db->value($sql) > 0) ? 1 : 0;

  # REPORTING SERVICES?
  $sql = qq{
      SELECT COUNT (*)
        FROM harpathfullname
       WHERE pathfullnameupper = '\\$cam\\RS'
    };
  my $has_rs_projects = ($har_db->db->value($sql) > 0) ? 1 : 0;

  # SISTEMAS?
  $sql = qq{
      SELECT COUNT (*)
        FROM harpathfullname
       WHERE pathfullnameupper LIKE '\\$cam\\SISTEMAS%'
    };
  my $has_sys_projects = ($har_db->db->value($sql) > 0) ? 1 : 0;

  my $inf_db = BaselinerX::Model::InfUtil->new({cam => $cam});
  my $is_cam_sistemas = $inf_db->has_sistemas;

  if ($has_sys_projects == 1 && $is_cam_sistemas == 1) {
    $has_sys_projects = 1;
  }
  else {
    $has_sys_projects = 0;
  }

  # BIZTALK?
  $sql = qq{
      SELECT COUNT (*)
        FROM haritems i, harview w, harrepinview r, harpathfullname p
       WHERE r.viewobjid = w.viewobjid
         AND i.repositobjid = r.repositobjid
         AND w.envobjid = '$envobjid'
         AND i.parentobjid = p.itemobjid
         AND pathfullnameupper LIKE '\\$cam\\BIZTALK%'
         AND (UPPER (TRIM (i.itemname)) LIKE '%.__PROJ')
  };
  my $has_biz_projects = ($har_db->db->value($sql) > 0) ? 1 : 0;

  my $data = [
    { has_net_projects => $has_net_projects,
      has_ora_projects => $has_ora_projects,
      has_vig_projects => $has_vig_projects,
      has_rs_projects  => $has_rs_projects,
      has_sys_projects => $has_sys_projects,
      has_biz_projects => $has_biz_projects,
    }
  ];

  $data;
}

sub get_combo_ciclo_vida_data {
  my ($self, $params) = @_;
  my $sistemas   = $params->{has_sys_projects};
  my $estado     = $params->{estado};
  my $es_publica = $params->{es_publica};
  my $cam        = $params->{cam};
  my $paq_ciclo  = $params->{paq_ciclo};
  my $tiene_ante = do {
  	my $inf = BaselinerX::Model::InfUtil->new(cam => $cam);
  	$inf->tiene_ante;
  };

  my $config;
  if ($estado eq 'Análisis y Diseño' || ($sistemas == 1 && $estado eq 'Desarrollo')) {
    if ($tiene_ante || $es_publica) {
      $config->{N} = "Normal (Con Preproducción)";
    }
    unless ($es_publica) {
      $config->{R} = "Rápido (Sin Preproducción)";
      $config->{E} = "Emergencia";
    }
    $config->{C} = "Correctivo";
    if ($paq_ciclo eq "Emergencia") {
      $config->{E} = "Emergencia";
    }
  }
  elsif (($estado eq 'Desarrollo' || $estado eq 'Pruebas') && !$es_publica) {
    if ($tiene_ante) {
      $config->{N} = "Normal (Con Preproducción)";
    }
    $config->{R} = "Rápido (Sin Preproducción)";
    if ($paq_ciclo eq "Emergencia") {
      $config->{E} = "Emergencia";
    }
  }

  $self->format_config($config);
}

sub get_combo_cambio_data {
  my $self = shift;
  $self->format_config(config_get('config.form.cambio'));
}

# Formats config file according to JSON structure (array of hashes
# reference)...
sub format_config {
  my ($self, $config) = @_;
  my $data;
  for my $value (keys %{$config}) {
    push @{$data}, {value => $value, show => $config->{$value}};
  }
  $data;
}

sub get_combo_tipologia_data {
  my ($self, $params) = @_;
  my $sistemas = $params->{has_sys_projects};
  my $estado   = $params->{estado};
  my $tipo     = $params->{paq_tipo};

  my $data;

  if ($sistemas == 1) {
    $data = [{value => $tipo || 'Mantenimiento Técnico'}];
  }
  elsif ($estado eq 'Análisis y Diseño') {
    my $config =
      Baseliner->model('ConfigStore')->get('config.form.tipologia');

    for my $value (keys %{$config}) {
      push @{$data}, {value => $config->{$value}};
    }
  }
  else {
    $data = [{value => $tipo}];
  }

  $data;
}

sub update_textareas {
  my ($self, $params) = @_;

  my $rs = Baseliner->model('Harvest::BdePaquete')->search({formobjid => 36});

  $rs->update($params);

  return;
}

sub load_grid_inc {
  my ($self, $cam, $username, $link_USD) = @_;
#  my $query = qq{      
#      SELECT "Id Incidencia" AS inc_codigo, "CAM" AS inc_cam,
#             "Descripción" AS inc_descripcion, "Tipo incidencia" AS inc_tipo,
#             "Activa?" AS inc_activa, "Estado" AS inc_estado, "Clase" AS inc_clase,
#             "Solicitante apellidos" AS inc_apellidos_sol,
#             "Solicitante nombre" AS inc_nombre_sol,
#             "Usr afectado apellidos" AS inc_apellidos_afe,
#             "Usr afectado nombre" AS inc_nombre_afe, "Prioridad" AS inc_prioridad,
#             "Impacto" AS inc_impacto, "Analista Asignado" AS inc_analista
#        FROM $link_USD
#       WHERE "Activa?" = 'SI' AND "Analista Asignado" = '$username'
#             AND "CAM" = '$cam'
#  };
  my $query = qq{
      SELECT "Id Incidencia" AS inc_codigo, "CAM" AS inc_cam,
             "Descripción" AS inc_descripcion, "Tipo incidencia" AS inc_tipo,
             "Activa?" AS inc_activa, "Estado" AS inc_estado, "Clase" AS inc_clase,
             "Solicitante apellidos" AS inc_apellidos_sol,
             "Solicitante nombre" AS inc_nombre_sol,
             "Usr afectado apellidos" AS inc_apellidos_afe,
             "Usr afectado nombre" AS inc_nombre_afe, "Prioridad" AS inc_prioridad,
             "Impacto" AS inc_impacto, "Analista Asignado" AS inc_analista
     FROM bde_scm_usd\@usd usd
    WHERE (   UPPER (TRIM (cam)) LIKE UPPER (TRIM ('$cam'))
           OR UPPER (TRIM (usd."Analista Asignado")) = UPPER ('$username')
          )
    AND TRIM (usd."Tipo incidencia") = 'APP'
    ORDER BY TO_NUMBER (usd."Id Incidencia") DESC, 2
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($query);

  \@data;
}

sub load_grid_hsp {
  my ($self, $tipo, $username) = @_;
  $tipo = join ',', _array($tipo);
  my $sql = qq{
      SELECT   NVL (pro_codigo, ' ') procodigo, NVL (pro_descripcion, ' ') prodesc,
               NVL (pro_unidad, ' ') prounidad, NVL (pro_responsables, ' ') proresp,
               NVL (pro_activo, '0') proactivo
          FROM intproyectos pr
         WHERE UPPER (pro_responsables) LIKE UPPER ('$username')
           AND pro_tipo IN ($tipo)
      ORDER BY 1, 3
    };

  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($sql);

  \@data;
}

1;
