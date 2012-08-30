package BaselinerX::Model::Form::Sistemas;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
BEGIN { extends 'Catalyst::Model' }


### get_main_data : Self Str -> ArrayRef[HashRef]
sub get_main_data {
  my ($self, $cam) = @_;
  my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 7;
  my $sql;

  if ($ver == 12) {
    $sql = qq{
        SELECT  pathfullname, itemname, v.itemobjid, v.versionobjid, v.mappedversion,
                s.versionobjid vid_sis, sis_owner, sis_permisos, sis_path,
                UPPER (v.versionstatus) estado
           FROM harversions v,
                haritemname n,
                harversions vp,
                harpathfullname pa,
                harassocpkg a,
                harform f,
                bde_paquete_sistemas s
          WHERE 1 = 1
            AND v.itemtype = 1
            AND n.nameobjid = v.itemnameid
            AND v.pathversionid = vp.versionobjid
            AND vp.itemobjid = pa.itemobjid
            AND v.inbranch = 0
            AND v.versionstatus IN ('N', 'D')
            AND s.versionobjid(+) = v.versionobjid
            AND v.packageobjid = a.assocpkgid
            AND a.formobjid = f.formobjid
            AND pathfullname LIKE "\\${cam}%"             -- FIX ME
            AND ROWNUM < 10                               -- DELETE ME
        ORDER BY pathfullname, itemname, v.versionobjid
      };
  }
  elsif ($ver == 7) {
    $sql = qq{
      SELECT pathfullname, itemname, i.itemobjid, v.versionobjid, v.mappedversion,
             p.packagename, versionstatus, sis_path, sis_owner, sis_permisos,
             sis_status, TO_CHAR (s.ts, 'YYYY-MM-DD HH24:MI') modificado
        FROM harversions v,
             haritems i,
             harpathfullname pa,
             harassocpkg a,
             harform f,
             bde_paquete_sistemas s,
             harpackage p
       WHERE v.itemobjid = i.itemobjid
         AND i.parentobjid = pa.itemobjid
         AND i.itemtype = 1
         AND v.inbranch = 0
         AND p.packageobjid = a.assocpkgid
         AND s.versionobjid = v.versionobjid
         AND v.packageobjid = a.assocpkgid
         AND a.formobjid = f.formobjid        
    };
  }
  # Instantiates Harvest schema...
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

  # Retrieves an array-hash...
  my @data = $har_db->db->array_hash($sql);

  FORMAT:
  for my $ref (@data) {
    # Builds elemento...
    $ref->{elemento} = "$ref->{pathfullname}\\$ref->{itemname}";
  }
  \@data;
}

### check_is_catalogued : Self Int -> ArrayRef
sub check_is_catalogued {
  my ($self, $versionobjid) = @_;
  my $sql = qq{
    SELECT COUNT (*)
      FROM bde_paquete_sistemas
    WHERE versionobjid = ?
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my $value  = $har_db->db->value($sql, $versionobjid);
  [{value => $value}];
}

### get_owners : Self Int -> ArrayRef[HashRef]
sub get_owners {
  my ($self, $cam) = @_;

  # Gets resultset...
  my $rs = Baseliner->model('Inf::InfSistemasAcl')
             ->search({cam => $cam}, 
                      {select => ['acl'], as => ['owner']});

  # Converts resultset to a hash-ref...
  rs_hashref($rs);

  # Builds data as an array of hashes...
  my @data = $rs->all;

  # Captures the first hash...
  my $hashref = shift @data;

  # Splits and converts data into an array...
  my @owners = split ', ', $hashref->{owner};

  # Format into an array of hash-refs...
  @data = map +{owner => $_}, @owners;
  \@data;
}

### update_or_create : Self HashRef Str -> Undef
sub update_or_create {
  my ($self, $params, $username) = @_;

  # Gets last usrobjid for the given user...
  my $rs = Baseliner->model('Harvest::Haruser')
                        ->search({username => $username},
                                 {select => ['max(usrobjid)'], 
                                  as     => ['usrobjid']});
  rs_hashref($rs);
  $params->{usrobjid} = $rs->next->{usrobjid};    # Adds usrobjid

  open my $filehandler, '>', 'C:\open-me.txt';
  print $filehandler Data::Dumper::Dumper $params;

  # Updates or creates in BDE_PAQUETE_SISTEMAS with constraint
  # 'versionobjid'...
  my $row =
    Baseliner->model('Harvest::BdePaqueteSistemas')
    ->update_or_create($params, {key => 'cons'});
  return;
}

### get_grid_data : Self -> ArrayRef[HashRef]
sub get_grid_data {
  my $self = shift;
  my $version = Baseliner->config->{'Model::Harvest'}->{db_version} || 7;
  $version == 12 ? $self->get_grid_data_r12() : $self->get_grid_data_r7();
}

### Note: I don't know wheter this sub works, let's test later.
### get_grid_data_r7 : Self -> ArrayRef[HashRef]
sub get_grid_data_r7 {
  my $self  = shift;
  my $query = q{
    SELECT pathfullname, itemname, i.itemobjid, v.versionobjid, v.mappedversion,
           p.packagename, versionstatus, sis_path, sis_owner, sis_permisos,
           sis_status, TO_CHAR (s.ts, 'YYYY-MM-DD HH24:MI') modificado
      FROM harversions v,
           haritems i,
           harpathfullname pa,
           harassocpkg a,
           harform f,
           bde_paquete_sistemas s,
           harpackage p
     WHERE v.itemobjid = i.itemobjid
       AND i.parentobjid = pa.itemobjid
       AND i.itemtype = 1
       AND v.inbranch = 0
       AND p.packageobjid = a.assocpkgid
       AND s.versionobjid = v.versionobjid
       AND v.packageobjid = a.assocpkgid
       AND a.formobjid = f.formobjid
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($query);
  for my $ref (@data) {
    $ref->{elemento} =~ m/(.+);/xi;
    $ref->{elemento_full} = $1;
    $ref->{elemento} =~ m/(.+)\\(.+);/xi;
    $ref->{elemento} = $2;
  }
  \@data;
}

### get_grid_data_r12 : Self -> ArrayRef[HashRef]
sub get_grid_data_r12 {
  my $self = shift;
  # Nota: Hay que filtrar el SQL, de forma que cuando solo se quieran ver los
  # campos del formulario se filtre por f_id, y si se quieren ver todos, se
  # filtra por CAM.
  my $sql = qq{
    SELECT   *
        FROM (SELECT ROWNUM,
                        TRIM (pathfullname)
                     || TRIM (itemname)
                     || ';'
                     || TRIM (v.mappedversion) elemento,
                     TRIM (statename) statename, TRIM (u.username) username,
                     TRIM (pathfullname) pathfullname, TRIM (itemname) itemname,
                     v.itemobjid, v.versionobjid,
                     TRIM (v.mappedversion) mappedversion, p.packagename,
                     v.versionstatus, sis_path, sis_owner, sis_permisos,
                     sis_status, TO_CHAR (s.ts, 'YYYY-MM-DD HH24:MI') modificado,
                     s.ID id_bde_paquete
                FROM harversions v,
                     haritemname n,
                     harversions vp,
                     harpathfullname pa,
                     harassocpkg a,
                     harform f,
                     bde_paquete_sistemas s,
                     harpackage p,
                     harstate st,
                     harallusers u
               WHERE 1 = 1
                 AND n.nameobjid = v.itemnameid
                 AND v.pathversionid = vp.versionobjid
                 AND vp.itemobjid = pa.itemobjid
                 AND v.itemtype = 1
                 AND v.inbranch = 0
                 AND p.packageobjid = a.assocpkgid
                 AND p.stateobjid = st.stateobjid
                 AND s.usrobjid = u.usrobjid
                 AND s.versionobjid = v.versionobjid
                 AND v.packageobjid = a.assocpkgid
                 AND a.formobjid = f.formobjid)
    ORDER BY pathfullname, itemname, versionobjid
  };
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($sql);

  for my $ref (@data) {
    $ref->{elemento} =~ m/(.+);/xi;
    $ref->{elemento_full} = $1;
    $ref->{elemento} =~ m/(.+)\\(.+);/xi;
    $ref->{elemento} = $2;
  }
  \@data;
}

### get_package_data : Self Int -> ArrayRef[HashRef]
sub get_package_data {
  my ($self, $versionobjid) = @_;
  my $rs = Baseliner->model('Harvest::BdePaqueteSistemas')
             ->search({versionobjid => $versionobjid});
  rs_hashref($rs);
  my @data = $rs->all;
  \@data;
}

### delete_row : Self Int -> Undef
sub delete_row {
  my ($self, $versionobjid) = @_;
  my $rs = Baseliner->model('Harvest::BdePaqueteSistemas')
             ->search({versionobjid => $versionobjid});
  $rs->delete;
  return;
}

1;
