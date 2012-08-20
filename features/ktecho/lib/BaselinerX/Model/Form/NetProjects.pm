package BaselinerX::Model::Form::NetProjects;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Data::Dumper;
BEGIN { extends 'Catalyst::Model' }

sub net_delete_bde_paquete {
  my ($self, $args_ref) = @_;
  my $fullname     = $args_ref->{fullname};
  my $cam          = $args_ref->{cam};
  my $project_type = $args_ref->{project_type};
  my $har_db       = BaselinerX::Ktecho::Harvest::DB->new;
  $har_db->db->do(qq{
    DELETE FROM bde_paquete_proyectos_net
          WHERE prj_fullname = '$fullname'
            AND prj_env = '$cam'
            AND prj_tipo = '$project_type'
  });
  return;
}

sub net_insert_bde_paquete {
  my ($self, $args_ref) = @_;
  my $cam           = $args_ref->{cam};
  my $fullname      = $args_ref->{fullname};
  my $project_type  = $args_ref->{project_type};
  my $subaplicacion = $args_ref->{subaplicacion};
  my $item          = $args_ref->{item};
  my $har_db        = BaselinerX::Ktecho::Harvest::DB->new;
  $har_db->db->do(qq{
    INSERT INTO bde_paquete_proyectos_net
                (prj_env, prj_fullname, prj_tipo, prj_subaplicacion, prj_proyecto)
         VALUES ('$cam', '$fullname', '$project_type', '$subaplicacion', '$item')
  });
  return;
}

sub net_get_cams {
  my ($self, $fid) = @_;
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  _throw "No tengo id de formulario!" unless $fid;
  my $sql = qq{
    SELECT DISTINCT e.environmentname AS env,
                    pa.pathfullname || '\\' || i.itemname AS fullname,
                    i.itemname AS item,
                    SUBSTR (pa.pathfullname || '\\',
                            INSTR (pa.pathfullname || '\\', '\\', 1, 3) + 1,
                              INSTR (pa.pathfullname || '\\', '\\', 1, 4)
                            - INSTR (pa.pathfullname || '\\', '\\', 1, 3)
                            - 1
                           ) AS subaplicacion
               FROM harform f,
                    haritems i,
                    harpathfullname pa,
                    harpackage p,
                    harpackage pe,
                    harenvironment e,
                    harversions v,
                    harassocpkg a
              WHERE f.formobjid = a.formobjid
                AND i.parentobjid = pa.itemobjid
                AND v.itemobjid = i.itemobjid
                AND v.packageobjid = pe.packageobjid
                AND a.assocpkgid = p.packageobjid
                AND p.envobjid = e.envobjid
                AND pe.envobjid = e.envobjid
                AND i.itemtype = 1
                AND UPPER (i.itemname) LIKE '%.__PROJ'
                AND UPPER (pa.pathfullname) LIKE '%\\.NET\\%'
                AND f.formobjid = $fid 
  };
  my @ret = $har_db->db->array_hash($sql);

  # Return with new format.
  [map +{ value => "$_->{fullname}|$_->{subaplicacion}|$_->{item}"
        , show  => "$_->{subaplicacion} => $_->{item}"
        }, @ret];
}

sub net_get_cam_reserva {
  my ($self, $fid) = @_;
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my $sql = qq{
    SELECT e.environmentname AS env
      FROM harform f, harpackage p, harenvironment e, harassocpkg a
     WHERE f.formobjid = a.formobjid
       AND a.assocpkgid = p.packageobjid
       AND p.envobjid = e.envobjid
       AND TRIM (f.formname) = '$fid'
  };
  $har_db->db->value($sql);
}

sub net_get_project_env {
  my ($self, $cam) = @_;
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my $sql = qq{
    SELECT DISTINCT prj_env AS env, prj_proyecto AS proyecto,
                    prj_subaplicacion AS subaplicacion, prj_tipo AS tipo,
                    REPLACE (prj_fullname, '\\', '\\\\') AS fullname
               FROM bde_paquete_proyectos_net
           ORDER BY 1, 2, 3, 4
  };
  $har_db->db->array_hash($sql);
}

sub get_tipos_distribucion {
  [{value => 'SL', show => 'Biblioteca Servidor'},
   {value => 'SW', show => 'Servidor IIS'},
   {value => 'CO', show => 'Cliente click-once IIS'},
   {value => 'CA', show => 'Cliente click-once IBM HTTP Server'},
   {value => 'CR', show => 'Cliente R:'},
   {value => 'RS', show => 'Cliente R: Sucursales'}]
}

sub delete_bde_paquete_proyectos_net {
  my ($self, $args) = @_;
  my $rs = Baseliner->model('Harvest::BdePaqueteProyectosNet')->search($args);
  $rs->delete;
  return;
}

sub _model { Baseliner->model('Harvest::BdePaqueteProyectosNet') }

sub existsp {
  my ($self, $args) = @_;
  my @data = do {
  	my $m  = $self->_model;
  	my $rs = $m->search($args);
  	rs_hashref($rs);
  	$rs->all;
  };
  scalar @data > 0;
}

sub add_row {
  my ($self, $args) = @_;
  my $m = $self->_model;
  $m->create($args);
  return;
}

1;
