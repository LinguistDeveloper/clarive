package BaselinerX::Model::Form::BizProjects;
use 5.010;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Ktecho::Utils;
use Data::Dumper;
BEGIN { extends 'Catalyst::Model' }

# Loads project grid data:
sub get_grid_proyectos {
  my ($self, $cam) = @_;

  # Gets the resultset...
  my $rs = Baseliner->model('Harvest::BdePaqueteBiztalk')->search(
    {prj_env => $cam},
    {select  => [qw/ prj_proyecto      prj_registro_gac
                     prj_subaplicacion prj_tipo /],
     as      => [qw/ proyecto          gac
                     subaplicacion     tipo /]});

  # Converts to hashref...
  rs_hashref($rs);

  # Puts all the resultset into an array of hashes...
  my @data = $rs->all;

  MODIFY:    # Modifies the data to be sent...
  for my $ref (@data) {
    # Creates the column 'aplicacion' with the current CAM...
    $ref->{aplicacion} = $cam;    # Ditto...

    # Formats 'tipo' value according to the config file...
    my $biztalk_type =
      Baseliner->model('ConfigStore')->get('config.biztalk.tipo');
    $ref->{tipo} = $biztalk_type->{$ref->{tipo}};

    # Formats 'gac' from { Si : No } to { 1 : 0 }...
    $ref->{gac} = 'Si' ? 1 : 0;
  }
  \@data;
}

# Loads combo distribucion data:
sub set_combo_tipo_distribucion {
  # Loads biztalk types from config file...
  my $biz_type = Baseliner->model('ConfigStore')->get('config.biztalk.tipo');

  # Creates variable to be sent back to controller...
  my $data;

  PUSH:    # Pushes hashrefs into an array ref...
  for my $value (keys %{$biz_type}) {
    push @{$data}, {value => $value, show => $biz_type->{$value}};
  }
  $data;
}

# Loads combo almacen data:
sub set_combo_almacen {

  # Loads biztalk stores from config file...
  my $biztalk_stores =
    Baseliner->model('ConfigStore')->get('config.biztalk.store');

  # Creates variable to send back to controller...
  my $data;

  # For each element in stores...
  for (0 .. scalar(keys %{$biztalk_stores}) - 1) {

    # Sets real value and shown value...
    $data->[$_]->{value} = $_;
    $data->[$_]->{show}  = $biztalk_stores->{$_};
  }

  return $data;
}

# Loads grid recursos data:
sub get_grid_recursos {
  my ($self, $cam) = @_;

  my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 7;

  my $sql =
      $ver == 12
    ? $self->get_grid_recursos_r12()
    : $self->get_grid_recursos_r7($cam);

  # Prepares SQL query...

  # Instanciates Harvest DB Connecion...
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  # Loads data into an array of hashes...
  my @data =
      $ver == 12 ? $har_db->db->array_hash($sql, "\\$cam\\BIZTALK%\\_AC%")
    : $ver == 7  ? $har_db->db->array_hash($sql)
    :              die "Check db_version!";

  # Converts the store from numeric value to its 'real', human readable
  # value...
  my $biztalk_store =
    Baseliner->model('ConfigStore')->get('config.biztalk.store');
  for my $ref (@data) {
    $ref->{store} = $biztalk_store->{$ref->{store}};
  }

  # Return as an arrayref...
  return \@data;
}

sub get_grid_recursos_r12 {
  qq{
        -- r12
        SELECT id, 
            cam aplicacion, 
            subappl subaplicacion, 
            TYPE tipo, 
            itemjsp, 
            item proyecto, 
            Nvl(bs.prj_store, 0) store 
        FROM   bde_paquete_biztalk_store bs, 
            (SELECT v.itemobjid 
                    id, 
                    Substr(pathfullname, Instr(pathfullname, '\\', 1, 1) + 1, 
                    Instr(pathfullname, '\\', 1, 2) - Instr(pathfullname, '\\', 1, 1) 
                    - 1) 
                    cam, 
                    Substr(pathfullname, Instr(pathfullname, '\\', 1, 3) + 1, 
                    Instr(pathfullname, '\\', 1, 4) - Instr(pathfullname, '\\', 1, 3) 
                    - 1) 
                    subappl, 
                    CASE 
                        WHEN Instr(pathfullname, '\\', 1, 5) = 0 THEN 
                        Substr(pathfullname, Instr(pathfullname, '\\', 1, 4) + 1) 
                        ELSE Substr(pathfullname, Instr(pathfullname, '\\', 1, 4) + 1, 
                                    Instr(pathfullname, '\\', 1, 5) - 
                                    Instr(pathfullname, '\\', 1, 4) 
                                    - 1) 
                    END 
                    TYPE, 
                    Replace(pathfullname 
                            ||'\\' 
                            ||itemname, '\\', '\\\\') 
                    itemjsp, 
                    pathfullname 
                    ||'\\' 
                    ||itemname 
                    item 
                FROM   haritemname n, 
                    harversions v, 
                    harpathfullname pa, 
                    harversions vp 
                WHERE  1 = 1 
                    AND v.itemtype = 1 
                    AND n.nameobjid = v.itemnameid 
                    AND v.versionstatus <> 'D' 
                    AND NOT EXISTS (SELECT hv.parentversionid 
                                    FROM   harversions hv 
                                    WHERE  hv.parentversionid = v.versionobjid) 
                    AND v.pathversionid = vp.versionobjid 
                    AND vp.itemobjid = pa.itemobjid 
                    AND pathfullnameupper LIKE ? 
                    AND Substr(n.itemnameupper, Instr(n.itemnameupper, '.', -1)) = 
                        '.DLL') a 
        WHERE  a.item = bs.prj_item (+) 
        ORDER  BY 2, 
                3, 
                6  
    };
}

sub get_grid_recursos_r7 {
  my ($self, $cam) = @_;
  qq{
    -- r7
    SELECT 
    ID, CAM aplicacion, SUBAPPL subaplicacion, TYPE tipo, ITEMJSP, ITEM proyecto, NVL(bs.PRJ_STORE, 0) store
    FROM BDE_PAQUETE_BIZTALK_STORE bs, 
    ( 
    SELECT  
    i.ITEMOBJID ID, 
    SUBSTR(PATHFULLNAME,INSTR(PATHFULLNAME,'\\',1,1)+1,INSTR(PATHFULLNAME,'\\',1,2)-INSTR(PATHFULLNAME,'\\',1,1)-1) CAM,  
    SUBSTR(PATHFULLNAME,INSTR(PATHFULLNAME,'\\',1,3)+1,INSTR(PATHFULLNAME,'\\',1,4)-INSTR(PATHFULLNAME,'\\',1,3)-1) SUBAPPL, 
    CASE WHEN INSTR(PATHFULLNAME,'\\',1,5) = 0 THEN SUBSTR(PATHFULLNAME,INSTR(PATHFULLNAME,'\\',1,4)+1) ELSE SUBSTR(PATHFULLNAME,INSTR(PATHFULLNAME,'\\',1,4)+1,INSTR(PATHFULLNAME,'\\',1,5)-INSTR(PATHFULLNAME,'\\',1,4)-1) END TYPE, 
    REPLACE(PATHFULLNAME||'\\'||ITEMNAME,'\\','\\\\') ITEMJSP, 
    PATHFULLNAME||'\\'||ITEMNAME ITEM 
    FROM HARITEMS I, HARVERSIONS V, HARPATHFULLNAME P 
    WHERE 1=1 
      AND ITEMTYPE=1 
      AND I.ITEMOBJID = V.ITEMOBJID 
      AND V.VERSIONSTATUS <> 'D' 
      AND NOT EXISTS (SELECT PARENTVERSIONID FROM HARVERSIONS HV WHERE HV.PARENTVERSIONID = V.VERSIONOBJID) 
      AND I.PARENTOBJID = P.ITEMOBJID 
      AND PATHFULLNAMEUPPER LIKE '\\$cam\\BIZTALK%\\_AC%' 
      AND SUBSTR(ITEMNAMEUPPER,INSTR(ITEMNAMEUPPER,'.',-1)) = '.DLL' 
    ) a 
    WHERE a.ITEM = bs.PRJ_ITEM (+) 
    ORDER BY 2,3,6 
  };
}

# Deletes biztalk project:
sub delete_project {
  my ($self, $params) = @_;

  # Formats GAC according to database params...
  $params->{prj_registro_gac} = ($params->{prj_registro_gac} == 1) 
                                  ? 'Si'
                                  : ($params->{prj_registro_gac} eq 'true') 
                                      ? 'Si'
                                      : 'No';

  # Gets real value of biztalk type...
  $params->{prj_tipo} = _biztalk_type($params->{prj_tipo});

  # Creates resultset
  my $row = Baseliner->model('Harvest::BdePaqueteBiztalk')->search($params);

  # Then deletes...
  $row->delete;

  return;
}

sub get_combo_proyecto {
  my ($self, $cam) = @_;

  # Creates resultset...
  my $rs = Baseliner->model('Harvest::BdeBtsNet')
                        ->search({bts_env => $cam},
                                 {search  => ['BTS_USA_NET']});
  rs_hashref($rs);
  my @data = $rs->all;

  # Filters projects if there is any .NET ...
  my $net_flag = ' ';
  $net_flag = "OR UPPER(pa.pathfullname) LIKE '%\\.NET\\%'"
    if scalar @data != 0;

  my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 7;

  my $sql = $ver == 12 ? $self->get_combo_proyecto_r12($cam, $net_flag)
                       : $self->get_combo_proyecto_r7($cam, $net_flag);

  # Using harvest schema...
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  # Returns an array of hashes...
  @data = $har_db->db->array_hash($sql);

  # Formats array...
  for my $ref (@data) {
    $ref->{value} = "$ref->{subaplicacion} :: $ref->{item}";
  }

  # As a reference...
  \@data;
}

sub get_combo_proyecto_r12 {
  my ($self, $cam, $net_flag) = @_;
  qq{
        -- r12
        SELECT DISTINCT e.environmentname AS env,
                        pa.pathfullname || '\\' || n.itemname AS fullname,
                        n.itemname AS item,
                        SUBSTR (pa.pathfullname || '\\',
                                INSTR (pa.pathfullname || '\\', '\\', 1, 3) + 1,
                                INSTR (pa.pathfullname || '\\', '\\', 1, 4)
                                - INSTR (pa.pathfullname || '\\', '\\', 1, 3)
                                - 1
                            ) AS subaplicacion
                FROM haritemname n,
                        harpathfullname pa,
                        harpackage pe,
                        harenvironment e,
                        harversions v,
                        harversions vp,
                        harassocpkg a
                WHERE e.environmentname LIKE '$cam%'
                    AND v.pathversionid = vp.versionobjid
                    AND vp.itemobjid = pa.itemobjid
                    AND n.nameobjid = v.itemnameid
                    AND v.packageobjid = pe.packageobjid
                    AND a.assocpkgid = pe.packageobjid
                    AND pe.envobjid = e.envobjid
                    AND v.itemtype = 1
                    AND UPPER (n.itemname) LIKE '%.__PROJ'
                    AND (UPPER (pa.pathfullname) LIKE '%\\BIZTALK\\%' $net_flag)
                    AND NOT EXISTS (
                            SELECT prj_proyecto
                            FROM bde_paquete_biztalk
                            WHERE prj_fullname =
                                                pa.pathfullname || '\\' || n.itemname)
    };
}

sub get_combo_proyecto_r7 {
  my ($self, $cam, $net_flag) = @_;
  qq{
        -- r7
        SELECT DISTINCT e.environmentname AS ENV, pa.PATHFULLNAME || '\\' || I.ITEMNAME AS FULLNAME, i.ITEMNAME AS ITEM, SUBSTR(pa.pathfullname || '\\', INSTR(pa.pathfullname || '\\', '\\', 1, 3) + 1, INSTR(pa.pathfullname || '\\', '\\', 1, 4) - INSTR(pa.pathfullname || '\\', '\\', 1, 3) - 1) AS SUBAPLICACION 
        FROM HARFORM f, 
            HARITEMS i, 
            HARPATHFULLNAME pa, 
            HARPACKAGE p, 
            HARPACKAGE pe, 
            HARENVIRONMENT e, 
            HARVERSIONS v, 
            HARASSOCPKG a 
        WHERE f.formobjid=a.formobjid  
        AND  i.parentobjid=pa.itemobjid 
        AND   v.itemobjid = i.itemobjid 
        AND   v.PACKAGEOBJID = pe.packageobjid 
        AND   SUBSTR(f.formname, 0, 3)= '$cam'  -- \$cam
        AND   a.assocpkgid=p.packageobjid 
        AND   p.envobjid = e.envobjid 
        AND   pe.envobjid = e.envobjid 
        AND   i.itemtype=1 
        AND   UPPER(i.itemname) LIKE '%.__PROJ' 
        AND  (UPPER(pa.pathfullname) LIKE '%\\BIZTALK\\%' $net_flag) -- \$net_flag
        AND   NOT EXISTS (SELECT PRJ_PROYECTO FROM BDE_PAQUETE_BIZTALK WHERE PRJ_FULLNAME = pa.PATHFULLNAME || '\\' || i.ITEMNAME) 
    };
}

# Adds a row in BDE_PAQUETE_BIZTALK:
sub add_project {
  my ($self, $params) = @_;

  delete $params->{cam};

  # Defines 'prj_proyecto'...
  ($params->{prj_subaplicacion}, $params->{prj_proyecto}) =
    $params->{proyecto} =~ m/(.+)\s::\s(.+)/xi;

  # Composes 'prj_fullname'...
  if ($params->{prj_proyecto} =~ m/(.+)\./xi) {
    $params->{prj_fullname} =
      "$params->{prj_env}\\$params->{prj_subaplicacion}\\$1\\$params->{prj_proyecto}";
  }
  # Won't use this...
  delete $params->{proyecto};

  # Can't use DBIx::Class update_or_create method here since this table
  # doesn't have a primary key, so we have first to delete...
  my $values;
  $values->{prj_env}      = $params->{prj_env};
  $values->{prj_proyecto} = $params->{prj_proyecto};

  my $row = Baseliner->model('Harvest::BdePaqueteBiztalk')->search($values);
  $row->delete;

  # Then insert the new values...
  Baseliner->model('Harvest::BdePaqueteBiztalk')->create($params);

  return;
}

# Adds a row in BDE_BTS_NET:
sub add_project_net {
  my ($self, $cam) = @_;

  # This basically adds a new row...  there is no need to delete former data
  # entries as DBIx:Class won't create duplicates.  Apparently BTS_USA_NET
  # will always be 'S' but I may be wrong...
  Baseliner->model('Harvest::BdeBtsNet')->create({bts_env     => $cam,
                                                  bts_usa_net => 'S'});
  return;
}

# Modifies Biztalk Store:
sub mod_almacen {
  my ($self, $params) = @_;

  delete $params->{cam};  # We won't be needing this.

  # Delete all stores for a given project (Normally there shouldn't be more
  # than a single row)...
  my $row = Baseliner->model('Harvest::BdePaqueteBiztalkStore')
                         ->search({prj_item => $params->{prj_item}});
  $row->delete;

  # Create a new row if needed...
  if ($params->{prj_store} != 0) {
    Baseliner->model('Harvest::BdePaqueteBiztalkStore')->create($params);
  }
  return;
}

1;

