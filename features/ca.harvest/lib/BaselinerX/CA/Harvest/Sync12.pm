package BaselinerX::CA::Harvest::Sync12;
use Moose;
use SQL::Abstract;
use Baseliner::Core::DBI;
use Baseliner::Utils;

# Eric 12/01/2012 -- Comento esto. Lo veo innecesario y da problemas tras el cambio a R12.
#has 'dbh' => ( is=>'ro', isa=>'DBI::db' );
#has 'db' => ( is=>'rw', isa=>'Baseliner::Core::DBI' );
#
#sub BUILD {
#    my $self = shift;
#    $har_db->db( Baseliner::Core::DBI->new( dbi=>$har_db->dbh ) )
#        unless ref $har_db->db;
#}

sub elements {
    my ($self,%p)=@_;
    my @vers = $self->versions( %p );
    my @ret;
    $p{mode} or die "Missing 'mode' parameter (promote/demote/static)";
    my %moved_ren;
    for( @vers ) {
        my %row = %$_;
        if( $row{oldver} ) {
            my @old = split /\|/, $row{oldver};
            my @cols = qw/path itemname mappedversion itemtype itemobjid
                packagename packageobjid versionstatus
                versiondataobjid datasize compressed fileaccess textfile modifytime
                pathid modifiedtime currversion lastversion
                username realname environmentname statename status/;
            my %oldrow = map { shift(@cols) => $_ } @old;
            push @ret, \%oldrow;# if $oldrow{status} =~ /(renamed|moved)/i;
            $moved_ren{ $oldrow{currversion} }=undef
                if $oldrow{status} =~ /(renamed|moved)/i;
        }
        $row{status} = $self->status( %row );
        push @ret, \%row;
    }
    # finalize
    @ret =
    sort {
        $a->{itemobjid} <=> $b->{itemobjid}
    }
    map {
        # tidy and finish-up the hash
        delete $_->{oldver};
        $_->{type} = $_->{itemtype} eq '1' ? 'file' : 'dir';
        $_->{viewpath} = join '\\', $_->{path}, $_->{itemname};
            ( $_->{fullpath} = $_->{viewpath} ) =~ s{\\}{/}g;
            ( $_->{extension} = $_->{itemname} ) =~ s{^.*\.(.+?)$}{$1}g;
        # if it's been moved, mark the new item placement row as 'new'
        exists($moved_ren{ $_->{lastversion} }) and $_->{status} = 'new';
        # now work on the mode
        if( $p{mode} =~ /promote|static/ ) {
            $_->{action} = $_->{status} =~ /(renamed|moved|deletion)/i
                ? 'delete'
                : $_->{status} =~ /overwritten/ ? '' : 'write';
            # new deletions = ignore
            $_->{action} = '' if $_->{versionstatus} eq 'D' and $_->{status} eq 'new';
        }
        elsif( $p{mode} eq 'demote' ) {
            $_->{action} = $_->{status} =~ /(renamed|moved|overwritten)/i
                ? 'write'
                : $_->{status} =~ /version/
                    ? exists($moved_ren{ $_->{lastversion} }) ? 'delete' : ''
                    : $_->{status} eq 'deletion' ? '' : 'delete';
            # new deletions = ignore
            $_->{action} = '' if $_->{versionstatus} eq 'D' and $_->{status} eq 'new';
        }
        else {
                _throw _loc("Unknown job mode %1", $p{mode} );
        }
        $_
    } @ret;
    return grep { $_->{action} } @ret;
}

sub writeable_elements {
    my ($self,%p)=@_;
    my @ret = $self->elements( %p ); 
    return grep { $_->{status} eq 'write' } @ret; 
}

sub status {
    my ($self,%row)=@_;
    return 'new' if $row{lastversion} == 0 ;
    return 'deletion' if $row{versionstatus} eq 'D' ;
    return 'version';
}

sub versions {
    my $self = shift;
    my $har_db = BaselinerX::CA::Harvest::DB->new; # Eric 12/01/2012
    my %p = @_;
    my $sa = SQL::Abstract->new( cmp => 'like' );
    my @pkgs = _array( $p{packageobjid} );
    my @envs;
    if( @pkgs == 0 ) {
        @envs = $har_db->db->array( $sa->select( 'harenvironment', 'envobjid', { environmentname=>$p{env} } ) ); 
        if( exists $p{package} ) {
            @pkgs = $har_db->db->array( $sa->select( 'harpackage', 'packageobjid', { packagename=>$p{package}, envobjid=>\@envs } ) ); 
        } elsif( exists $p{state} ) {
            @pkgs = $har_db->db->array( $sa->select( ['harpackage p', 'harstate s'], 'packageobjid', { -bool=>\'s.stateobjid=p.stateobjid', statename=>$p{state}, 's.envobjid'=>\@envs } ) ); 
        } else {
            die "Missing 'package' or 'state' parameters";
        }
    }
    my @views = _array( $p{viewobjid} );
    if( exists $p{view} ) {
        die "Missing 'env' parameter to find view." unless @envs > 0;
        @views = $har_db->db->array( $sa->select( 'harview', 'viewobjid', { viewname=>$p{view}, envobjid=>\@envs } ) ); 
    } elsif( @views == 0 ) {
        # guess view from package's own
        @views = $har_db->db->array( $sa->select( 'harpackage', 'viewobjid', { packageobjid=>\@pkgs } ) ); 
    }
    my $pkgs = join ',',@pkgs;
    my $views = join ',',@views;
    die "Could not determine any views from packages @pkgs" unless $views;
    my $sql = qq{
        SELECT
           -- select previous version also, if any
           (CASE WHEN ( lastversion > 0 ) then ( 
               SELECT MAX(pa2.pathfullname
                   ||'|'||n2.itemname
                   ||'|'||v6.mappedversion
                   ||'|'||v6.itemtype
                   ||'|'||v6.itemobjid
                   ||'|'||p2.packagename
                   ||'|'||p2.packageobjid
                   ||'|'||v6.versionstatus
                   ||'|'||v6.versiondataobjid
                   ||'|'||d.datasize
                   ||'|'||d.compressed
                   ||'|'||d.fileaccess
                   ||'|'||d.textfile
                   ||'|'||d.modifytime
                   ||'|'||v6.pathversionid
                   ||'|'||to_char(v6.modifiedtime+(TO_NUMBER(SUBSTR(REPLACE(REPLACE(SESSIONTIMEZONE,'+',''),':00',''),2,1))/24),'YYYY-MM-DD HH24:MI')
                   ||'|'||v6.versionobjid
                   ||'|'||''
                   ||'|'||u6.username
                   ||'|'||u6.realname
                   ||'|'||e6.environmentname
                   ||'|'||s6.statename
                   ||'|'||
                       (CASE WHEN ( n2.nameobjid <> nid ) THEN 'renamed' ELSE 
                       (CASE WHEN ( v6.pathversionid <> pathid ) THEN 'moved' ELSE ('overwritten') END) END ) )
               FROM harpathfullname pa2, haritemname n2,harversions v6,harversiondata d,
                   harversioninview vv, harpackage p2, harallusers u6, harenvironment e6, harstate s6
               WHERE v6.versionobjid=lastversion and n2.nameobjid=v6.itemnameid 
                 and v6.pathversionid=pa2.versionobjid
                 and v6.versionobjid = vv.versionobjid
                 and p2.packageobjid = v6.packageobjid
                 and v6.versiondataobjid (+) = d.versiondataobjid
                 and u6.usrobjid = v6.modifierid
                 and e6.envobjid = p2.envobjid
                 and s6.stateobjid = p2.stateobjid
                 and vv.viewobjid IN ( $views )
            ) END ) oldver,
            main.* 
        FROM ( 
            SELECT n.itemname, v1.versionobjid currversion, v1.mappedversion,
                pa.pathfullname path, v1.itemtype, v1.versionstatus, packagename, p.packageobjid, v1.itemobjid,
                n.nameobjid nid, v1.versiondataobjid, d.datasize, d.compressed, d.fileaccess, d.textfile, d.modifytime, v1.pathversionid pathid,
                to_char(v1.modifiedtime+(TO_NUMBER(SUBSTR(REPLACE(REPLACE(SESSIONTIMEZONE,'+',''),':00',''),2,1))/24),'YYYY-MM-DD HH24:MI') modifiedtime,
                environmentname, statename, username, realname,
                (select v5.parentversionid from harversions v5
                  where v5.versionobjid=
                    (select min(v4.versionobjid) from harversions v4
                        where v4.itemobjid=v1.itemobjid AND v4.packageobjid IN ( $pkgs ) )
                ) lastversion
            FROM harversions v1, harversiondata d, harpackage p, 
              harpathfullname pa, harstate s, harallusers u,haritemname n, harenvironment e
            WHERE ( ( ( p.stateobjid = s.stateobjid 
            AND v1.modifierid = u.usrobjid AND n.nameobjid = v1.itemnameid 
            AND v1.packageobjid = p.packageobjid
            AND v1.pathversionid = pa.versionobjid
            AND p.envobjid = e.envobjid
            AND v1.versiondataobjid (+) = d.versiondataobjid
            AND v1.versionobjid = ( select max(v3.versionobjid) from harversions
            v3 where v3.itemobjid=v1.itemobjid and v3.versionstatus<>'R' and v3.packageobjid IN ( $pkgs ) ) ) AND p.packageobjid IN ( $pkgs ) ) )
        ) main
    }; 
    return $har_db->db->array_hash( $sql );
}

1;


