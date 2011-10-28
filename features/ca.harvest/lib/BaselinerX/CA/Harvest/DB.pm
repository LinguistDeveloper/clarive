package BaselinerX::CA::Harvest::DB;
use Moose;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Compress::Zlib;
use Try::Tiny;

#FIXME deprecated (now config.ca.harvest.map.states_for_job)
our %from_states = ( 
    DESA => {  promote => [ 'Desarrollo', 'Desarrollo Integrado', 'Consolidación', 'Pruebas' ], demote => 0 },
    PREP => {  promote => [ 'Desarrollo Integrado' ], demote => [ 'Pruebas Integradas', 'Pruebas de Acceptación', 'Pruebas Sistemas' ] },
    PROD => {  promote => [ 'Pruebas Sistemas', 'Preproducción' ], demote => [ 'Producción' ] },
);

# maps from current state to bl depending on job_type
sub states_for_job {
    my ($self, %p) = @_;
    my $bl = $p{bl} or _throw 'Missing parameter bl';
    my $ns = $p{ns} || '/';
    my $job_type = $p{job_type} or _throw 'Missing job_type';
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>$ns, bl=>$bl );
    if( $inf ) {
        my $states = $inf->{states_for_job}->{$job_type};
        return $states;
    }
}

sub states_for_checkin {
    my ($self, %p) = @_;
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map' );
    if( $inf ) {
        my $states = $inf->{states_for_checkin};
        return $states;
    }
}

sub view_for_bl {
    my ($self, $bl) = @_;
    my @views = $self->views_for_bl($bl);
    return $views[0];
}

sub views_for_bl {
    my ($self, $bl) = @_;
    _throw _loc("Missing parameter bl") unless $bl;
    my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>'/', bl=>$bl );
    my @ret = try {
        my @views;
        for( _array $bl ) {
            push @views, $inf->{baseline_to_view}->{$_};
        }
        return @views;
    } catch {
        return $bl;
    };
    return wantarray ? @ret : $ret[0];
}

sub viewobjids_for_bl {
    my ($self, $bls) = @_;
    my @viewobjids;
    for my $bl ( _array $bls ) {
        my $view = $self->view_for_bl( $bl );
        return wantarray ? () : []
            unless $view;
        my $rs =  Baseliner->model('Harvest::Harview')->search({ viewname=>$view }, { select=>'viewobjid' });
        rs_hashref( $rs );
        push @viewobjids, map { $_->{viewobjid} } $rs->all;
    }
    @viewobjids = _unique @viewobjids;
    return wantarray ? @viewobjids : \@viewobjids; 
}

sub views_for_packagegroup {
    my ($self, $pkggrpobjid ) = @_;

    return $self->db->array(qq{
            select distinct viewname 
            from harpackagegroup g,harpkgsinpkggrp pp,harpackage p, harview w
            where g.pkggrpobjid=pp.pkggrpobjid (+)
            and p.packageobjid (+) = pp.packageobjid 
            and p.viewobjid = w.viewobjid (+)
            and g.pkggrpobjid = $pkggrpobjid
            order by viewname
    });
}

sub packagegroup_for_bl {
    my ($self, $bl ) = @_;
    my $viewname = $self->view_for_bl( $bl );
    return $self->db->array(qq{
        SELECT DISTINCT pkggrpobjid 
        FROM HARPACKAGE p,HARPKGSINPKGGRP pp,HARVIEW w 
        WHERE p.packageobjid=pp.packageobjid 
        AND w.viewobjid=p.viewobjid AND w.viewname='$viewname' 
    });
}

sub db {
    my $self = shift;
    return Baseliner::Core::DBI->new({ model=>'Harvest' });
}

sub envs_for_user {
    my ($self, $username) = @_;
    return $self->db->array(qq{select distinct envobjid
            from harenvironmentaccess ea,harusersingroup ug,haruser u
            where u.usrobjid=ug.usrobjid and ug.usrgrpobjid=ea.usrgrpobjid
            and upper(username) = upper('$username')
            and ( updateaccess='Y' or executeaccess='Y' or viewaccess='Y' )
        });
}

sub active_projects {
    my ($self, %p) = @_;
    return $self->db->array_hash(qq{select distinct e.*
            from harenvironment e
            where e.envisactive='Y'
            and e.envobjid > 0
            and environmentname like '%'||?||'%'
            order by environmentname
        }, $p{query} );
}

sub projects_for_user {
    my ($self, %p) = @_;
    $p{username} or _throw 'Missing username';
    return $self->db->array_hash(qq{select distinct e.*
            from harenvironmentaccess ea,harusersingroup ug,haruser u,harenvironment e
            where u.usrobjid=ug.usrobjid and ug.usrgrpobjid=ea.usrgrpobjid
            and e.envobjid=ea.envobjid
            and e.envobjid > 0
            and envisactive='Y'
            and environmentname like '%'||?||'%'
            and upper(username) = upper(?)
            and ( updateaccess='Y' or executeaccess='Y' or viewaccess='Y' or secureaccess='Y' )
            order by environmentname
        }, $p{query}, $p{username});
}

sub is_superuser {
    my ($self,$username) = @_;
    return 1 if lc($username) eq 'harvest';
    my $row = Baseliner->model('Harvest::Harusersingroup')->search({ username=>$username, usrgrpobjid=>1 }, { join=>['usrobjid'] })->first;
    return ref $row;
}

sub element_from_versionobjid {
    my ($self,$vid)=@_;
    my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });
    my $sql = qq{
        SELECT p.PATHFULLNAME||'\\'||i2.itemname path, n.itemname name, v.mappedversion version,v.versionstatus status,
            u1.username creator,u2.username modifier
        FROM HARVERSIONS v, HARITEMS i, HARITEMNAME n, HARPATHFULLNAME p, HARVERSIONS v2, HARITEMS i2,
            HARALLUSERS u1,HARALLUSERS u2
        WHERE 1=1
        AND v.versionobjid = $vid
        AND v.creatorid = u1.usrobjid
        AND v.modifierid = u2.usrobjid
        AND n.NAMEOBJID = v.ITEMNAMEID
        AND v.itemobjid = i.itemobjid
        AND v.PATHVERSIONID = v2.versionobjid
        AND v2.itemobjid = i2.itemobjid
        AND i2.parentobjid = p.itemobjid
    };
    my @rows = $db->array_hash( $sql );
    my $r = $rows[0];
    #qw/name path version tag data_size package creator created_on modifier modified_file modified_on/;
    new BaselinerX::CA::Harvest::CLI::Version(
        name=>$r->{name},
        path=>$r->{path},
        version=>$r->{version},
        tag=>$r->{status}||'N',
        creator=>$r->{creator},
        modifier=>$r->{modifier},
        mask=> '/application/nature/project', #TODO from a config 'harvest.repo.mask'
    );
}

sub renamed_version_from_itempath {
    my ($self,%p)=@_;
    my $itemname = $p{itemname} or die "Missing 'itemname'";
    my $viewpath = $p{viewpath} or die "Missing 'viewpath'";
    defined $p{mappedversion} or die "Missing 'mappedversion'";
    my $mappedversion = $p{mappedversion};

    my $pkg_filter='';
    if( ref $p{packages} ) {
        my $pkgs = join',',_array($p{packages});
        $pkg_filter = "AND packageobjid IN ( $pkgs )";
    }

    my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });

    my $sql = qq{
        SELECT HV2.VERSIONOBJID LASTVERSION, HPFN2.PATHFULLNAME||'\'||HIN2.ITEMNAME BORRAR_ELTO FROM
        HARITEMNAME HIN, HARPATHFULLNAME HPFN, HARVERSIONS HV, HARVERSIONS HV2, HARITEMNAME HIN2, HARPATHFULLNAME HPFN2  
        WHERE 1=1
          AND HIN.ITEMNAME = '$itemname'
          AND HPFN.PATHFULLNAME = '$viewpath'
          AND HV.mappedversion = '$mappedversion'
          AND HIN.NAMEOBJID = HV.ITEMNAMEID
          AND HPFN.VERSIONOBJID = HV.PATHVERSIONID
          AND HV2.VERSIONOBJID = (
            SELECT MIN (VERSIONOBJID) FROM HARVERSIONS HVX 
            WHERE 1=1
              $pkg_filter 
              AND HVX.ITEMOBJID = HV.ITEMOBJID
              )
          AND ( HV.ITEMNAMEID <> HV2.ITEMNAMEID OR HV.PATHVERSIONID <> HV2.PATHVERSIONID )
          AND HV2.PATHVERSIONID = HPFN2.VERSIONOBJID
          AND HV2.ITEMNAMEID = HIN2.NAMEOBJID 
    };
    # my $sql = qq{
    # SELECT v.mappedversion, n.ITEMNAME, pathfullname, v.PATHVERSIONID, v.packageobjid, i.itemobjid,  
        # (SELECT parentversionid FROM HARVERSIONS v4 WHERE v4.versionobjid =
            # (SELECT MIN(versionobjid) FROM HARVERSIONS v3
                # WHERE v3.itemobjid = i.itemobjid $pkg_filter ) ) lastversion
        # FROM HARVERSIONS v, HARITEMS i, HARITEMNAME n, HARPATHFULLNAME p, HARVERSIONS v2, HARITEMS i2, HARITEMNAME n2
        # WHERE 1=1
        # AND n.ITEMNAME = '$itemname'
        # AND n.NAMEOBJID = v.ITEMNAMEID
        # AND v.itemobjid = i.itemobjid
        # AND v.mappedversion = '$mappedversion'
        # AND v.PATHVERSIONID = v2.versionobjid
        # AND v2.itemobjid = i2.itemobjid
        # AND i2.parentobjid = p.itemobjid
        # AND v2.itemnameid = n2.nameobjid
        # AND p.PATHFULLNAME||'\\'||n2.itemname = '$viewpath'
    # };
    _log $sql;
    my @rows = $db->array_hash( $sql );
    my $row = $rows[0];
    if( $row->{lastversion} > 0 ) { # 0 means no dice
        return $self->element_from_versionobjid( $row->{lastversion} );
    }
}

sub checkout {
    my $self = shift;
    my $p = _parameters( @_ );
    _check_parameters( $p, qw/versions path/ );

    _log "Inicio del checkout de los paquetes del pase.";
    my @versions = _array( $p->{versions} );
    my $path = $p->{path};
    my $project = $p->{project};
    my $subapp = $p->{subapp};

    my $db = Baseliner::Core::DBI->new({ model=>'Harvest' });
    
    my @DONE=();
    my @DEL=();
    foreach my $row ( @versions ) {     
        my $Blob;
        my $Compressed;

        my $itempath = $row->{path};    
        my $itemname = $row->{itemname};    
        my $versionid = $row->{versionid};  

        next if $project && $row->{project} ne $project;
        next if $subapp && ((split(/\//,$itempath))[3] ne $subapp );
        
        my $blob_file = "${path}${itempath}/$itemname";         
        if( $row->{tag} ne "D") {
            push @DONE, $blob_file.";$row->{version} ($row->{package})\n";
            my $SQL = "SELECT VERSIONDATA,COMPRESSED FROM HARVERSIONDATA VD,HARVERSIONS V WHERE VD.VERSIONDATAOBJID = V.VERSIONDATAOBJID AND V.VERSIONOBJID = $versionid";
            ($Blob,$Compressed) = $db->array( $SQL );
            if( $Compressed eq 'Y') {
                $Blob = uncompress( $Blob ) ;
            }
            _mkpath( $path, $itempath );
            open BLOB,">$blob_file" or die "Error: no he podido abrir el fichero '$blob_file' para escritura: $!";
            binmode BLOB;
            print BLOB $Blob;
            close BLOB; 
        }
        else {  ##delete
            push @DEL, $blob_file.";$row->{version} ($row->{package})\n";
            unlink($blob_file) if( -e $blob_file);
        }
    }
    #loginfo "Fin del checkout de los paquetes del pase: <b>".@DONE."</b> elemento(s) nuevo(s), ".@DEL." elemento(s) borrado(s).", "------| Elementos Nuevos |------\n\n".arrayToString(@DONE)."\n------| Elementos Borrados |------\n".arrayToString(@DEL);
    return { normal=>\@DONE, deleted=>\@DEL };
}

sub select_elements {
    my $self = shift;
    my $p = _parameters( @_ );

    my @pkgs = _array( $p->{packages} );
    my @pkgids; 
    @pkgids = _array( $p->{packageobjid} );
    my $suffix = $p->{suffix};
    my $pkgids = '(' . join(',',@pkgids) . ')';

    my $sql = qq{
        select   v.versionobjid versionid,
                 trim(i.itemname) itemname,
                 UPPER(nvl(substr(i.itemname,1,instr(i.itemname,'.') - 1),i.itemname)) itemname_short,
                 trim(p.packagename) package,
                 substr(l.pathfullname,instr(l.pathfullname, '\\', 1, 3) + 1) AS library,
                 UPPER(TRIM(substr(i.itemname, instr(i.itemname,'.') + 1))) extension,
                 (case  when  (v.VERSIONSTATUS = 'D') then 'D'
                        when (EXISTS (select *
                            from harversions vs
                            where vs.itemobjid = n.itemobjid and
                              vs.packageobjid IN $pkgids and
                              vs.versionstatus<>'R' ) )
                  then 'D' 
                  else 'N' end) tag,
                 trim(v.MAPPEDVERSION) version,
                 replace(l.pathfullname,'\\','/') path,
                 i.itemobjid iid,
                 n.itemobjid nid,
                 trim(e.environmentname) project,
                 trim(s.statename) statename,
                 trim(hu.username)||' ('||trim(hu.realname)||')' username,
                 to_char(v.modifiedtime+(TO_NUMBER(SUBSTR(REPLACE(REPLACE(SESSIONTIMEZONE,'+',''),':00',''),2,1))/24),'YYYY-MM-DD HH24:MI') modifiedtime
        FROM     HARPACKAGE p,
                         HARSTATE s,
                         HARALLUSERS hu,
                         HARVERSIONS v,
                         HARENVIRONMENT e,
                         HARITEMS i,
                         HARPATHFULLNAME l,
                         HARITEMRELATIONSHIP n
        WHERE    p.packageobjid = v.packageobjid AND
                         p.stateobjid = s.stateobjid AND
                         v.modifierid = hu.usrobjid AND
                         v.versionstatus<>'R' and
                         p.envobjid = e.envobjid AND
                         i.itemobjid = v.itemobjid AND
                         n.refitemid (+)= i.itemobjid AND
                         i.parentobjid = l.itemobjid AND
                         SUBSTR(l.pathfullname, INSTR(l.pathfullname||'\\', '\\', 1, 2) + 1, INSTR(l.pathfullname||'\\', '\\', 1, 3) - INSTR(l.pathfullname||'\\', '\\', 1, 2) - 1) = '$suffix' AND            
                         UPPER (i.itemname) NOT LIKE '%.VS_SCC' AND
                         i.itemtype = 1 AND
                         p.packageobjid IN $pkgids AND
                         v.versionobjid = (SELECT MAX(vs.versionobjid)
                                            FROM HARVERSIONS vs
                                            WHERE vs.itemobjid = v.itemobjid AND
                                                  vs.packageobjid IN $pkgids AND
                                                  vs.versionstatus<>'R' )
        UNION 
        select   v2.versionobjid versionid,
                 trim(ni.itemname) itemname,
                 UPPER(nvl(substr(i.itemname,1,instr(i.itemname,'.') - 1),i.itemname)) itemname_short,
                 trim(p.packagename) package,
                 substr(l.pathfullname,instr(l.pathfullname, '\\', 1, 3) + 1) AS library,
                 UPPER(TRIM(substr(i.itemname, instr(i.itemname,'.') + 1))) extension,
                 (case  when  (v.VERSIONSTATUS = 'D') then 'D'
                        when (EXISTS (select *
                            from harversions vs
                            where vs.itemobjid = n.itemobjid and
                              vs.packageobjid IN $pkgids and
                              vs.versionstatus<>'R' ) )
                  then 'D' 
                  else 'N' end) tag,
                 trim(v.MAPPEDVERSION) version,
                 replace(l.pathfullname,'\\','/') path,
                 i.itemobjid iid,
                 n.itemobjid nid,
                 trim(e.environmentname) project,
                 trim(s.statename) statename,
                 trim(hu.username)||' ('||trim(hu.realname)||')' username,
                 to_char(v.modifiedtime+(TO_NUMBER(SUBSTR(REPLACE(REPLACE(SESSIONTIMEZONE,'+',''),':00',''),2,1))/24),'YYYY-MM-DD HH24:MI') modifiedtime
        FROM     HARPACKAGE p,
                         HARSTATE s,
                         HARALLUSERS hu,
                         HARVERSIONS v,
                         HARVERSIONS v2,
                         HARENVIRONMENT e,
                         HARITEMS i,
                         HARITEMS ni,
                         HARPATHFULLNAME l,
                         HARITEMRELATIONSHIP n
        WHERE    p.packageobjid = v.packageobjid AND
                         p.stateobjid = s.stateobjid AND
                         v.modifierid = hu.usrobjid AND
                         v.versionstatus<>'R' AND
                         p.envobjid = e.envobjid AND
                         i.itemobjid = v.itemobjid AND
                         ni.itemobjid = n.refitemid AND
                         n.itemobjid = i.itemobjid AND
                         v2.itemobjid=ni.itemobjid AND
                         v2.versionobjid = (select max(versionobjid) from harversions where itemobjid = n.refitemid and versionstatus<>'R') and
                         NOT EXISTS (SELECT * FROM HARVERSIONS vs
                                            WHERE vs.versionobjid = v2.versionobjid AND
                                                  vs.packageobjid IN $pkgids AND
                                                  vs.versionstatus<>'R' ) AND
                         i.parentobjid = l.itemobjid AND
                         SUBSTR(l.pathfullname, INSTR(l.pathfullname||'\\', '\\', 1, 2) + 1, INSTR(l.pathfullname||'\\', '\\', 1, 3) - INSTR(l.pathfullname||'\\', '\\', 1, 2) - 1) = '$suffix' AND            
                         i.itemtype = 1 AND
                         p.packageobjid IN $pkgids AND
                         v.versionobjid = (SELECT MAX(vs.versionobjid)
                                            FROM HARVERSIONS vs
                                            WHERE vs.itemobjid = v.itemobjid AND
                                                  vs.packageobjid IN $pkgids AND
                                                  vs.versionstatus<>'R' )                          
        ORDER BY 11
        };

}

sub viewpath_exists {
    my ($self,$vp) = @_;
    $vp =~s{\/}{\\}g;
    $vp =~ s{\\$}{};
    $vp = "\\$vp" unless $vp =~ /^\\/;
    return $self->db->value(q{select count(*) from harpathfullname pa, harversions v where pa.pathfullname like ?
        and v.pathversionid = pa.versionobjid}, $vp);
}

sub viewpaths_for_env {
    my ($self,$envobjid, $query) = @_;
    $query ||= '%';
    _throw 'Missing envobjid' unless defined $envobjid;
    my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 12;
    if( $ver == 12 ) {
        return $self->db->array(q{select distinct pathfullname
               from harpathfullname pa, harversions v, harversioninview vv, harview w
               where v.pathversionid = pa.versionobjid
                and vv.versionobjid=v.versionobjid
                and w.viewobjid=vv.viewobjid
                and w.envobjid = ? and lower(pathfullname) like lower(?) order by pathfullname}, $envobjid, $query);
    } else {
        return $self->db->array(q{select distinct pathfullname
               from harpathfullname pa, harversions v, haritems i, harversioninview vv, harview w
               where v.itemobjid = i.itemobjid
                and i.parentobjid = pa.itemobjid
                and i.itemtype = 0
                and vv.versionobjid=v.versionobjid
                and w.viewobjid=vv.viewobjid
                and w.envobjid = ? and lower(pathfullname) like lower(?) order by pathfullname}, $envobjid, $query);
    }
}

sub viewpaths_query {
    my ($self, $query) = @_;
    $query or _throw "Missing query";
    $query =~ s{\/}{\\}g;
    $query =~ s/\*/%/g;
    $query =~ s/\?/_/g;
    #$query = $query ? '%' . $query . '%' : '%';
    my $ver = Baseliner->config->{'Model::Harvest'}->{db_version} || 12;
    if( $ver == 12 ) {
        return $self->db->array(q{select distinct pathfullname
               from harpathfullname pa, haritems i
               where i.parentobjid = pa.itemobjid
               and i.itemtype = 0
               and lower(pathfullname) like lower(?) order by pathfullname}, $query);
    } else {
        return $self->db->array(q{select distinct pathfullname
               from harpathfullname pa, haritems i
               where i.parentobjid = pa.itemobjid
               and i.itemtype = 0
               and lower(pathfullname) like lower(?) order by pathfullname}, $query);
    }
}

sub viewpaths_query_nofiles {
  # Same query but without checking whether it has files or not.
  my ($self, $query) = @_;
  $query or _throw "Missing query";
  $query =~ s{\/}{\\}g;
  $query =~ s/\*/%/g;
  $query =~ s/\?/_/g;
  my $sql = qq{
      SELECT DISTINCT pathfullname
        FROM harpathfullname pa
       WHERE LOWER (pathfullname) LIKE LOWER (?)
    ORDER BY pathfullname
  };
  $self->db->array($sql, $query);
}

sub packagename_pathfullname {
    my ($self, $packagename) = @_;
    my $query = qq{
        SELECT DISTINCT pathfullname
          FROM harenvironment e,
               harpackage p,
               harpathfullname pa,
               harversions v,
               haritems i
         WHERE p.envobjid = e.envobjid
           AND p.packagename = ?
           AND p.packageobjid = v.packageobjid
           AND i.itemobjid = v.itemobjid
           AND i.parentobjid = pa.itemobjid
    };
    $self->db->array($query, $packagename);
}

sub packages_for_packagegroup {
    my ($self, %p) = @_;
    my $errmsg = "Please select a valid argument (pkggrpobjid / pkggrpname)";
    my $query = qq{
        SELECT hp.packagename
          FROM harpackage hp, harpackagegroup hpg, harpkgsinpkggrp hppg
         WHERE hppg.pkggrpobjid = hpg.pkggrpobjid
           AND hp.packageobjid IN hppg.packageobjid };
    $query .= exists $p{id}   ? " AND hpg.pkggrpobjid = $p{id}"
            : exists $p{name} ? " AND TRIM (hpg.pkggrpname) = '$p{name}'"
            :                   _throw $errmsg;
    my @data = $self->db->array($query);
    wantarray ? @data : \@data;
}

sub package_inc_id {
    my ($self, %p) = @_;
    my $errmsg = "Please select a valid argument (pkggrpobjid / pkggrpname)";
    my $query = qq{
        SELECT bde.paq_inc
          FROM harpackage hp, harassocpkg ha, bde_paquete bde
         WHERE bde.paq_tipo = 'Incidencia'
           AND bde.formobjid = ha.formobjid
           AND ha.assocpkgid = hp.packageobjid
           AND paq_inc IS NOT NULL };
    $query .= exists $p{id}   ? " AND hp.packageobjid = $p{id}"
            : exists $p{name} ? " AND hp.packagename  = '$p{name}'"
            :                   _throw $errmsg;
    $self->db->value($query);
}

sub packagegroup_inc_id {
    my ($self, %p) = @_;
    my $errmsg = "Please select a valid argument (pkggrpobjid / pkggrpname)";
    my $query = qq{
         SELECT DISTINCT hp.packageobjid, bde.paq_inc
           FROM harpackage hp,
                harpackagegroup hpg,
                harassocpkg ha,
                bde_paquete bde,
                harpkgsinpkggrp hppg
          WHERE bde.paq_tipo = 'Incidencia'
            AND bde.formobjid = ha.formobjid
            AND ha.assocpkgid = hp.packageobjid
            AND paq_inc IS NOT NULL
            AND hp.packageobjid = hppg.packageobjid };
    $query .= exists $p{id}   ? " AND hpg.pkggrpobjid = $p{id}"
            : exists $p{name} ? " AND hpg.pkggrpname  = '$p{name}'"
            :                   _throw $errmsg;
    my @data = $self->db->array_hash($query);
    my %hash = map +($_->{packageobjid} => $_->{paq_inc}), @data;
    \%hash;
}

sub pkggrpname_packagename {
    my ($self, $packagename) = @_;
    my $query = qq{
        SELECT TRIM (pkggrpname)
          FROM harpackage p, harpkgsinpkggrp pp, harpackagegroup g
         WHERE p.packageobjid = pp.packageobjid
           AND pp.pkggrpobjid = g.pkggrpobjid
           AND TRIM (p.packagename) = TRIM ( ? )
    };
    my @data = $self->db->array($query, $packagename);
    wantarray ? @data : \@data;
}

sub set_subapl {
    my ($self, $job, $sub_apl) = @_;
    my $query = qq{
        UPDATE distpase
           SET pas_subapl = TRIM (pas_subapl) || ' ' || '$sub_apl'
         WHERE TRIM (pas_codigo) = '$job'
           AND (   INSTR (pas_subapl, '$sub_apl') IS NULL
                OR INSTR (pas_subapl, '$sub_apl') = 0
               )
    };
    $self->db->do($query);
}

sub dist_entornos_write {
    my ($self, %dist) = @_;
    my $sql = qq{
      INSERT INTO distentornos
                  (cam, entorno, environmentname,
                   ciclo, vista_co, nivel
                  )
           VALUES ('$dist{cam}', '$dist{entorno}', '$dist{envname}',
                   '$dist{ciclo}', '$dist{vista_co}', '$dist{nivel}'
                  )        
    };
    $self->db->do($sql);
    return;
}

1;
