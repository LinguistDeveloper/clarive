package BaselinerX::CA::Harvest::Sync7;
use Moose;
use SQL::Abstract;
use Baseliner::Core::DBI;
use Baseliner::Utils;

has 'dbh' => ( is=>'ro', isa=>'DBI::db' );
has 'db' => ( is=>'rw', isa=>'Baseliner::Core::DBI',
    default=>sub{ Baseliner::Core::DBI->new( model=>'Harvest' ) } );

sub BUILD {
    my $self = shift;
    $self->db( Baseliner::Core::DBI->new( dbi=>$self->dbh ) )
        unless ref $self->db;
}

sub elements {
    my ($self,%p)=@_;
    my @vers = $self->versions( %p );
    my @ret;
	$p{mode} or die "Missing 'mode' parameter (promote/demote/static)";
    for( @vers ) {
        my %row = %$_;
        $row{status} = $self->status( %row );
        push @ret, \%row;
    }
    @ret =
    sort {
        $a->{itemobjid} <=> $b->{itemobjid}
    }
    map {
        $_->{type} = $_->{itemtype} eq '1' ? 'file' : 'dir';
        $_->{viewpath} = join '\\', $_->{path}, $_->{itemname};
			( $_->{fullpath} = $_->{viewpath} ) =~ s{\\}{/}g;
			( $_->{extension} = $_->{itemname} ) =~ s{^.*\.(.+?)$}{$1}g;
        $_->{action} = $_->{tag} eq 'D' ? 'delete' : 'write';
        $_;
    } @ret;
    return @ret;
}

sub writeable_elements {
	my ($self,%p)=@_;
    my @ret = $self->elements( %p ); 
    return grep { $_->{status} eq 'write' } @ret; 
}

sub status {
    my ($self,%row)=@_;
    return 'new' if $row{mappedversion} == '0' ;
    return 'deletion' if $row{tag} eq 'D' ;
    return 'version';
}

sub versions {
    my $self = shift;
    my %p = @_;
	$p{mode} or die "Missing 'mode' parameter (promote/demote/static)";
    my $sa = SQL::Abstract->new( cmp => 'like' );
    my @pkgs = _array( $p{packageobjid} );
    my @envs;

    if( @pkgs == 0 ) {
		@envs = $self->db->array( $sa->select( 'harenvironment', 'envobjid', { environmentname=>$p{env} } ) ); 
        if( exists $p{package} ) {
            @pkgs = $self->db->array( $sa->select( 'harpackage', 'packageobjid', { packagename=>$p{package}, envobjid=>\@envs } ) ); 
        } elsif( exists $p{state} ) {
			@pkgs = $self->db->array( $sa->select( ['harpackage p', 'harstate s'], 'packageobjid', { -bool=>\'s.stateobjid=p.stateobjid', statename=>$p{state}, 's.envobjid'=>\@envs } ) ); 
        } else {
            die "Missing 'package' or 'state' parameters";
        }
    }
    my @views = _array( $p{viewobjid} );
    if( exists $p{view} ) {
        die "Missing 'env' parameter to find view." unless @envs > 0;
        @views = $self->db->array( $sa->select( 'harview', 'viewobjid', { viewname=>$p{view}, envobjid=>\@envs } ) ); 
	} elsif( @views == 0 ) {
		# guess view from package's own
		@views = $self->db->array( $sa->select( 'harpackage', 'viewobjid', { packageobjid=>\@pkgs } ) ); 
    }
    my $pkgs = join ',',@pkgs;
    my $views = join ',',@views;
    die "Could not determine any views from packages @pkgs" unless $views;
    my $sql = $p{mode} =~ /demote|rollback/i
        ? $self->backout_elements( $pkgs, $views)
        : $self->add_elements( $pkgs, $views);
    return $self->db->array_hash( $sql );
}

sub add_elements {
    my ($self, $pkgs, $views ) = @_;
    qq{SELECT   v.versionobjid versionid, TRIM (i.itemname) itemname,
             TRIM (p.packagename) packagename,
             UPPER (TRIM (SUBSTR (i.itemname, INSTR (i.itemname, '.') + 1))
                   ) extension,
             (CASE
                 WHEN (v.versionstatus = 'D')
                    THEN 'D'
                 WHEN (EXISTS (
                          SELECT *
                            FROM harversions vs
                           WHERE vs.itemobjid = n.itemobjid
                             AND vs.packageobjid IN ( $pkgs )
                             AND vs.versionstatus <> 'R')
                      )
                    THEN 'D'
                 ELSE 'N'
              END
             ) tag,
             TRIM (v.mappedversion) mappedversion,
             d.compressed,
             d.datasize,
             d.fileaccess,
             d.textfile,
             TO_CHAR( d.modifytime, 'YYYY-MM-DD HH24:MI') modifytime,
             0 pathid,
             i.itemtype,
             v.packageobjid,
             v.versionstatus,
             v.versiondataobjid,
             0 currversion,
             0 lastversion,
             e.environmentname,
             REPLACE (l.pathfullname, '\\', '/') PATH, i.itemobjid ,
             n.itemobjid nid, TRIM (e.environmentname) project,
             TRIM (s.statename) statename,
             TRIM (hu.username) username,
             TRIM (hu.realname) realname,
             TO_CHAR
                (  v.modifiedtime
                 + (  TO_NUMBER (SUBSTR (REPLACE (REPLACE (SESSIONTIMEZONE,
                                                           '+',
                                                           ''
                                                          ),
                                                  ':00',
                                                  ''
                                                 ),
                                         2,
                                         1
                                        )
                                )
                    / 24
                   ),
                 'YYYY-MM-DD HH24:MI'
                ) modifiedtime
        FROM harpackage p,
             harstate s,
             harallusers hu,
             harversions v,
             harenvironment e,
             haritems i,
             harpathfullname l,
             haritemrelationship n,
             harversiondata d
       WHERE p.packageobjid = v.packageobjid
         AND p.stateobjid = s.stateobjid
         AND v.modifierid = hu.usrobjid
         AND v.versionstatus <> 'R'
         AND v.versiondataobjid = d.versiondataobjid
         AND p.envobjid = e.envobjid
         AND i.itemobjid = v.itemobjid
         AND n.refitemid(+) = i.itemobjid
         AND i.parentobjid = l.itemobjid
         AND UPPER (i.itemname) NOT LIKE '%.VS_SCC'
         AND i.itemtype = 1
         AND p.packageobjid IN ( $pkgs )
         AND v.versionobjid =
                (SELECT MAX (vs.versionobjid)
                   FROM harversions vs
                  WHERE vs.itemobjid = v.itemobjid
                    AND vs.packageobjid IN ( $pkgs )
                    AND vs.versionstatus <> 'R')
    UNION
    SELECT   v2.versionobjid versionid, TRIM (ni.itemname) itemname,
             TRIM (p.packagename) packagename,
             UPPER (TRIM (SUBSTR (i.itemname, INSTR (i.itemname, '.') + 1))
                   ) extension,
             (CASE
                 WHEN (v.versionstatus = 'D')
                    THEN 'D'
                 WHEN (EXISTS (
                          SELECT *
                            FROM harversions vs
                           WHERE vs.itemobjid = n.itemobjid
                             AND vs.packageobjid IN ( $pkgs )
                             AND vs.versionstatus <> 'R')
                      )
                    THEN 'D'
                 ELSE 'N'
              END
             ) tag,
             TRIM (v.mappedversion) mappedversion,
             d.compressed,
             d.datasize,
             d.fileaccess,
             d.textfile,
             TO_CHAR( d.modifytime, 'YYYY-MM-DD HH24:MI') modifytime,
             0 pathid,
             i.itemtype,
             v.packageobjid,
             v.versionstatus,
             v.versiondataobjid,
             0 currversion,
             0 lastversion,
             e.environmentname,
             REPLACE (l.pathfullname, '\\', '/') PATH, i.itemobjid ,
             n.itemobjid nid, TRIM (e.environmentname) project,
             TRIM (s.statename) statename,
             TRIM (hu.username) username,
             TRIM (hu.realname) realname,
             TO_CHAR
                (  v.modifiedtime
                 + (  TO_NUMBER (SUBSTR (REPLACE (REPLACE (SESSIONTIMEZONE,
                                                           '+',
                                                           ''
                                                          ),
                                                  ':00',
                                                  ''
                                                 ),
                                         2,
                                         1
                                        )
                                )
                    / 24
                   ),
                 'YYYY-MM-DD HH24:MI'
                ) modifiedtime
        FROM harpackage p,
             harstate s,
             harallusers hu,
             harversions v,
             harversions v2,
             harenvironment e,
             haritems i,
             haritems ni,
             harpathfullname l,
             haritemrelationship n,
             harversiondata d
       WHERE p.packageobjid = v.packageobjid
         AND p.stateobjid = s.stateobjid
         AND v.modifierid = hu.usrobjid
         AND v.versionstatus <> 'R'
         AND v.versiondataobjid = d.versiondataobjid
         AND p.envobjid = e.envobjid
         AND i.itemobjid = v.itemobjid
         AND ni.itemobjid = n.refitemid
         AND n.itemobjid = i.itemobjid
         AND v2.itemobjid = ni.itemobjid
         AND v2.versionobjid =
                         (SELECT MAX (versionobjid)
                            FROM harversions
                           WHERE itemobjid = n.refitemid AND versionstatus <> 'R')
         AND NOT EXISTS (
                SELECT *
                  FROM harversions vs
                 WHERE vs.versionobjid = v2.versionobjid
                   AND vs.packageobjid IN ( $pkgs )
                   AND vs.versionstatus <> 'R')
         AND i.parentobjid = l.itemobjid
         AND i.itemtype = 1
         AND p.packageobjid IN ( $pkgs )
         AND v.versionobjid =
                (SELECT MAX (vs.versionobjid)
                   FROM harversions vs
                  WHERE vs.itemobjid = v.itemobjid
                    AND vs.packageobjid IN ( $pkgs )
                    AND vs.versionstatus <> 'R')
        ORDER BY 11
    };
}

sub backout_elements {
    my ($self, $pkgs, $views ) = @_;
    qq{select * 
    from(
    select   versionid,
             itemname,
             packagename,
             vstatus,
             (case when (vstatus = 'N' AND MAPPEDVERSION = '0') then 'D'
                   when (vstatus = 'N' AND
                         EXISTS (SELECT *
                                 FROM haritemrelationship r
                                 where q.VERSIONID = r.versionobjid)) THEN 'D'       
                   when (vstatus = 'D' AND 
                         EXISTS (SELECT * 
                                 FROM haritems ii, harversions vi
                                 WHERE ii.itemobjid = IID and
                                       ii.itemobjid = vi.itemobjid and 
                                       vi.packageobjid IN ( $pkgs ) and
                                       vi.versionstatus<>'R' and
                                       vi.MAPPEDVERSION = '0')) THEN 'S' 
                   when (vstatus = 'N' AND 
                         EXISTS (SELECT * 
                                 FROM haritems ii, harversions vi
                                 WHERE ii.itemobjid = IID and
                                       ii.itemobjid = vi.itemobjid and 
                                       vi.packageobjid IN ( $pkgs ) and
                                       vi.versionstatus<>'R' and
                                       vi.MAPPEDVERSION = '0')) THEN 'D' 
                   else 'N' end) AS tag,
             mappedversion,
             compressed,
             datasize,
             fileaccess,
             textfile,
             modifytime,
             pathid,
             itemtype,
             packageobjid,
             versionstatus,
             versiondataobjid,
             currversion,
             lastversion,
             environmentname,
             path,
             IID itemobjid,
             nid,
             project,
             statename,
             username,
             realname,
             modifiedtime
    from     (
    select   v.versionobjid VERSIONID,
             trim(i.itemname) itemname,
             trim(p.packagename) packagename,
             (case  when  (v.VERSIONSTATUS = 'D') then 'D'
                    when (EXISTS (select *
                        from harversions vs
                        where vs.itemobjid = n.itemobjid and
                          vs.packageobjid IN ( $pkgs ) and
                          vs.versionstatus<>'R' ) ) then 'D' 
              else 'N' end) vstatus,
             trim(v.MAPPEDVERSION) mappedversion,
             d.compressed,
             d.datasize,
             d.fileaccess,
             d.textfile,
             TO_CHAR( d.modifytime, 'YYYY-MM-DD HH24:MI') modifytime,
             0 pathid,
             i.itemtype,
             v.packageobjid,
             v.versionstatus,
             v.versiondataobjid,
             0 currversion,
             0 lastversion,
             e.environmentname,
             replace(l.pathfullname,'\\','/') PATH,
             i.itemobjid IID,
             n.itemobjid NID,
             trim(e.environmentname) PROJECT,
             trim(s.statename) STATENAME,
             trim(hu.username) username, 
             trim(hu.realname) realname, 
             to_char(v.modifiedtime+(TO_NUMBER(SUBSTR(REPLACE(REPLACE(SESSIONTIMEZONE,'+',''),':00',''),2,1))/24),'YYYY-MM-DD HH24:MI') MODIFIEDTIME
    FROM     HARPACKAGE p,
                     HARSTATE s,
                     HARALLUSERS hu,
                     HARVERSIONS v,
                     HARENVIRONMENT e,
                     HARITEMS i,
                     HARPATHFULLNAME l,
                     harversiondata d,
                     HARITEMRELATIONSHIP n
    WHERE    p.packageobjid = v.packageobjid AND
                     p.stateobjid = s.stateobjid AND
                     v.modifierid = hu.usrobjid AND
                     v.versiondataobjid = d.versiondataobjid AND
                     v.versionstatus<>'R' and
                     p.envobjid = e.envobjid AND
                     i.itemobjid = v.itemobjid AND
                     n.refitemid (+)= i.itemobjid AND
                     i.parentobjid = l.itemobjid AND
                     UPPER (i.itemname) NOT LIKE '%.VS_SCC' AND
                     i.itemtype = 1 AND
                     p.packageobjid IN ( $pkgs ) AND
                     v.versionobjid = (SELECT MAX(vs.versionobjid)
                                        FROM HARVERSIONS vs
                                        WHERE vs.itemobjid = v.itemobjid AND
                                              vs.packageobjid IN ( $pkgs ) AND
                                              vs.versionstatus<>'R' )
    UNION 
    select   v2.versionobjid VERSIONID,
             trim(ni.itemname) itemname,
             trim(p.packagename) packagename,
             (case  when  (v.VERSIONSTATUS = 'D') then 'D'
                    when (EXISTS (select *
                        from harversions vs
                        where vs.itemobjid = n.itemobjid and
                          vs.packageobjid IN ( $pkgs ) and
                          vs.versionstatus<>'R' ) ) then 'D' 
              else 'N' end) vstatus,
             trim(v.MAPPEDVERSION) mappedversion,
             d.compressed,
             d.datasize,
             d.fileaccess,
             d.textfile,
             TO_CHAR( d.modifytime, 'YYYY-MM-DD HH24:MI') modifytime,
             0 pathid,
             i.itemtype,
             v.packageobjid,
             v.versionstatus,
             v.versiondataobjid,
             0 currversion,
             0 lastversion,
             e.environmentname,
             replace(l.pathfullname,'\\','/') PATH,
             i.itemobjid IID,
             n.itemobjid NID,
             trim(e.environmentname) PROJECT,
             trim(s.statename) STATENAME,
             trim(hu.username) username, 
             trim(hu.realname) realname, 
             to_char(v.modifiedtime+(TO_NUMBER(SUBSTR(REPLACE(REPLACE(SESSIONTIMEZONE,'+',''),':00',''),2,1))/24),'YYYY-MM-DD HH24:MI') MODIFIEDTIME
    FROM     HARPACKAGE p,
                     HARSTATE s,
                     HARALLUSERS hu,
                     HARVERSIONS v,
                     HARVERSIONS v2,
                     HARENVIRONMENT e,
                     HARITEMS i,
                     HARITEMS ni,
                     HARPATHFULLNAME l,
                     harversiondata d,
                     HARITEMRELATIONSHIP n
    WHERE    p.packageobjid = v.packageobjid AND
                     p.stateobjid = s.stateobjid AND
                     v.modifierid = hu.usrobjid AND
                     v.versionstatus<>'R' and
                     v.versiondataobjid = d.versiondataobjid AND
                     p.envobjid = e.envobjid AND
                     i.itemobjid = v.itemobjid AND
                     ni.itemobjid = n.refitemid AND
                     n.itemobjid = i.itemobjid AND
                     v2.itemobjid=ni.itemobjid AND
                     v2.versionobjid = (select max(versionobjid) from harversions where itemobjid = n.refitemid) and
                     NOT EXISTS (SELECT * FROM HARVERSIONS vs
                                        WHERE vs.versionobjid = v2.versionobjid AND
                                              vs.packageobjid IN ( $pkgs ) AND
                                              vs.versionstatus<>'R' ) AND
                     i.parentobjid = l.itemobjid AND
                     UPPER (i.itemname) NOT LIKE '%.VS_SCC' AND
                     i.itemtype = 1 AND
                     p.packageobjid IN ( $pkgs ) AND
                     v.versionobjid = (SELECT MAX(vs.versionobjid)
                                        FROM HARVERSIONS vs
                                        WHERE vs.itemobjid = v.itemobjid AND
                                              vs.packageobjid IN ( $pkgs ) AND
                                              vs.versionstatus<>'R' )                          
        ) q               
    )
    where tag <> 'S'                  
    ORDER BY 11               
                          
    };
}
1;


