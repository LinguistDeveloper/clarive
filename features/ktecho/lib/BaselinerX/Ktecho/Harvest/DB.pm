package BaselinerX::Ktecho::Harvest::DB;
use Moose;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Compress::Zlib;
use Try::Tiny;
BEGIN { extends 'BaselinerX::CA::Harvest::DB' }

sub get_dependencias {
    my ( $self, $args_ref ) = @_;
    my $proyecto    = $args_ref->{proyecto};
    my $paquetes_in = $args_ref->{paquetes_in};
    my $comparacion = $args_ref->{comparacion};

    return $self->db->hash(
        qq/
            SELECT p1.packageobjid 
                    || v1.itemobjid 
                    || v1.versionobjid, 
                p1.packagename, 
                pa.pathfullname 
                    || '\\' 
                    || n.itemname, 
                v1.mappedversion 
            FROM   harpackage p1, 
                harpackage p2, 
                harversions v1, 
                harversions v2, 
                harenvironment e, 
                haritemname n, 
                harversions vp, 
                harpathfullname pa 
            WHERE  TRIM(e.environmentname) LIKE '$proyecto' 
                AND TRIM(p2.packagename) IN $paquetes_in
                AND TRIM(p1.packagename) NOT IN $paquetes_in
                AND p1.stateobjid = p2.stateobjid 
                AND p2.envobjid = e.envobjid 
                AND v2.packageobjid = p2.packageobjid 
                AND v2.itemobjid = v1.itemobjid 
                AND v1.packageobjid = p1.packageobjid 
                AND p2.packageobjid <> p1.packageobjid 
                AND n.nameobjid = v1.itemnameid 
                AND v1.pathversionid = vp.versionobjid 
                AND vp.itemobjid = pa.itemobjid 
                AND v1.versionobjid $comparacion v2.versionobjid 
            ORDER  BY 1, 
                    2, 
                    4, 
                    3 
        /
    );
}

# Returns project ID for a given project name
# From: /orahar.pm
sub get_project_id {
    my ( $self, $project_name ) = @_;

    return $self->value(
        qq(
            SELECT envobjid 
            FROM   harenvironment 
            WHERE  TRIM(environmentname) = '$project_name'  
        )
    );
}

# From: /orahar.pm
sub get_package_info {
    my ( $self, $package_name ) = @_;

    return $self->db->array( "
        SELECT environmentname, 
               statename 
        FROM   harstate s, 
               harpackage pk, 
               harenvironment e 
        WHERE  s.stateobjid = pk.stateobjid 
               AND s.envobjid = e.envobjid 
               AND TRIM(pk.packagename) = TRIM('$package_name')  
        " );
}

sub get_packages_projects {
    my ( $self, $packages_ref ) = @_;
    my @packages = _array($packages_ref);
    my $list_packages = "'" . join( "','", @packages ) . "'";

    return $self->db->array( "
        SELECT e.environmentname 
        FROM   harenvironment e, 
               harpackage p 
        WHERE  e.envobjid = p.envobjid 
               AND TRIM(p.packagename) IN ( $list_packages )  
        " );
}

sub hay_emergencia {
    my ( $self, $args_ref ) = @_;
    my $env_name   = $args_ref->{env_name};
    my $state_name = $args_ref->{state_name};
    my @packages   = _array( $args_ref->{packages} );

    # Código antiguo:
    # my $EnvironmentID = getProjectID($env_name);
    # my $StateID = getStateID($EnvironmentID, $StateName);

    my $packages_list = join( "','", @packages );
    my $states_list   = "'Pruebas','Desarrollo','Emergencia','Producción Emergencia'";

    return $self->db->array( "
        SELECT p.packagename 
        FROM   harpackage p, 
               harstate s, 
               harenvironment e 
        WHERE  p.envobjid = e.envobjid 
               AND TRIM(e.environmentname) LIKE TRIM('$env_name') 
               AND p.stateobjid = s.stateobjid 
               AND TRIM(s.statename) IN ( $states_list ) 
               AND TRIM(p.packagename) LIKE '%.E-%' 
               AND TRIM(p.packagename) NOT IN ( '$packages_list' )  
        " );
}

sub get_package_id {
    my ( $self, $package_name ) = @_;

    return $self->db->value( "
        SELECT packageobjid 
        FROM   harpackage 
        WHERE  TRIM(packagename) = TRIM('$package_name')  
        " );
}

sub get_user_group_id {
    my ( $self, $group_name ) = @_;
    my %where = ( "trim('usergroupname')" => "trim($group_name)" );
    my %args  = ( select => { 'max', 'usrgrpobjid' } );

    my $group_id = Baseliner->model('Harvest::Harusergroup')->count( %where, \%args );

    return $group_id;
}

sub get_form_id {
    my ($self, $package_obj_id) = @_;

    return $self->db->value( "
                SELECT fp.formobjid 
                FROM   bde_paquete fp, 
                       harassocpkg a, 
                       harform f, 
                       harpackage p 
                WHERE  fp.formobjid = a.formobjid 
                       AND f.formobjid = fp.formobjid 
                       AND Substr(formname, 1, 12) = Substr(p.packagename, 1, 12) 
                       AND p.packageobjid = $package_obj_id 
                       AND a.assocpkgid = $package_obj_id  
                " );
}

sub get_paquete_motivo {
    my ( $self, $paquete ) = @_;
    my @retorno    = ();
    my $package_id = $self->get_package_id($paquete);
    my $form_id    = $self->get_form_id($package_id);

    my ( $tipo, $incidencia, $peticion, $proyecto, $mantenimiento ) =
        $self->db->array( "
            SELECT paq_tipo, 
                   paq_inc, 
                   paq_pet, 
                   paq_pro, 
                   paq_mant 
            FROM   bde_paquete 
            WHERE  formobjid = $form_id  
            " );

    if ( $tipo eq "Incidencia" ) {
        @retorno = ( $tipo, $incidencia );
    }
    elsif ( ( $tipo eq "Petición" ) ) {
        @retorno = ( $tipo, $peticion );
    }
    elsif ( ( $tipo eq "Proyecto" ) ) {
        @retorno = ( $tipo, $proyecto );
    }
    elsif ( ( $tipo eq "Mantenimiento técnico" ) ) {
        @retorno = ( $tipo, $mantenimiento );
    }

    return @retorno;
}

sub get_pass_packages {
    my ( $self, $pass_id ) = @_;

    return $self->db->value( "
                SELECT trim(p.packagename)
  		   		FROM DIST_PAQUETE_PASE pp, HARPACKAGE p
 		   		WHERE p.packageobjid = pp.packageobjid AND 
 		   	 		pp.pase = '$pass_id'
                " );
}

sub get_naturalezas_pase {
    my ( $self, $pass_id ) = @_;

    my $log = Catalyst::Log->new;
    $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    my $packages = "'" . join( "','", $self->get_pass_packages($pass_id) ) . "'";

    my @pkgs = $self->get_pass_packages($pass_id);

    $log->debug( "Paquetes asignados al pase $pass_id: " . join( ",", $packages ) );

    my @retorno = ();

    my @array = $self->db->array( "
        SELECT DISTINCT Substr(Substr(pa.pathfullname, 
                               Instr(pa.pathfullname, '\\', 2) + 1) 
                                || '\\', 1, Instr(Substr(pa.pathfullname, 
                                                  Instr(pa.pathfullname, '\\', 2) + 1) 
                                                   || '\\', '\\', 1) - 1) 
        FROM   harversions v, 
               harpackage p, 
               harpathfullname pa, 
               haritemname n, 
               harversions vp 
        WHERE  TRIM(packagename) IN ( $packages ) 
               AND n.nameobjid = v.itemnameid 
               AND v.pathversionid = vp.versionobjid 
               AND vp.itemobjid = pa.itemobjid 
               AND v.packageobjid = p.packageobjid  
        " );

    foreach (@array) {
        push( @retorno, $_ ) if ( /NET/i or /J2EE/i or /FICH/i or /RS/i );
        push( @retorno, "ORA" )  if (/ORACLE/i);
        push( @retorno, "BIZT" ) if (/BIZTALK/i);
    }

    return @retorno;
}

sub set_naturaleza {
    my ( $self, $pase, $naturaleza ) = @_;
    $naturaleza = substr( $naturaleza, 0, 4 );

    $self->db->do( "
        UPDATE distpase 
        SET    pas_naturaleza = TRIM(pas_naturaleza) 
                                 || ' ' 
                                 || '$naturaleza' 
        WHERE  TRIM(pas_codigo) = '$pase' 
               AND ( Instr(pas_naturaleza, '$naturaleza') IS NULL 
                      OR Instr(pas_naturaleza, '$naturaleza') = 0 )  
        " );

    #TODO ocommit();

    return;
}

sub get_pase_sub_apl {
    my ( $self, $pase, $sufijo ) = @_;
	
    my $sql = "
        SELECT DISTINCT Sub_aplicacionestr(pathfullname, Instr(TRIM(pathfullname), '\\', 
                                        Instr(TRIM(pathfullname), '\\', 2) + 1) + 1, 
                        Instr( 
                        Sub_aplicacionestr(pathfullname, Instr(TRIM(pathfullname), '\\', 
                                                               Instr(TRIM(pathfullname 
                        ), '\\', 2) + 1) + 1), '\\') - 1) 
        FROM   harenvironment e, 
               harpackage p, 
               harpathfullname pa, 
               harversions vp, 
               harversions v, 
               haritemname n, 
               dist_paquete_pase pp 
        WHERE  p.envobjid = e.envobjid 
               AND n.nameobjid = v.itemnameid 
               AND v.pathversionid = vp.versionobjid 
               AND vp.itemobjid = pa.itemobjid 
               AND p.packageobjid = pp.packageobjid 
               AND pp.pase = '$pase' 
               AND p.packageobjid = v.packageobjid 
               AND Instr(TRIM(pathfullname), '\\', Instr(TRIM(pathfullname), '\\', 
                   Instr(TRIM(pathfullname), '\\', 2)) + 1) 
                   > 0 
               AND Sub_aplicacionestr(pathfullname, Instr(TRIM(pathfullname), '\\', 
                   Instr(TRIM(pathfullname), '\\', 2) + 1) 
                                                    + 1 
                   , Instr( 
                   Sub_aplicacionestr(pathfullname, Instr(TRIM(pathfullname), '\\', 
                                                          Instr(TRIM(pathfullname 
                     ), '\\', 2) + 1) + 1), '\\') - 1) IS NOT NULL  
        ";

	if ($sufijo) {
        $sql .= "  
            AND Sub_aplicacionestr(pa.pathfullname, Instr(pa.pathfullname 
                                                                  || '\\', '\\', 1, 2) + 1, 
                           Instr(pa.pathfullname 
                                  || '\\', '\\', 1, 3) - Instr(pa.pathfullname 
                                                                || '\\', '\\', 1, 2) - 1) = 
           '$sufijo'  
        ";
	}

    # Estos son los proyectos dentro de la naturaleza
    my @proyectos = $self->db->array($sql);

	my %sub_aplicaciones=();

	## identifico la subapl según su nombre. AAA_BBB_CCC => AAA_BBB, si no, no se modifica
    foreach (@proyectos) {
        my $proy = $_;
        if (/(.*)\_...$/) {
            $proy = $1;
        }
        $sub_aplicaciones{$proy} = q//;
    }

    return keys %sub_aplicaciones;
}

# set_sub_apl: añade una subaplicacion al pase
sub set_sub_apl {
    my ( $self, $pase, $sub_apl ) = @_;

    print $self->db->do( "
                UPDATE distpase 
                SET    pas_subapl = TRIM(pas_subapl) 
                                     || ' ' 
                                     || '$sub_apl' 
                WHERE  TRIM(pas_codigo) = '$pase' 
                       AND ( Instr(pas_subapl, '$sub_apl') IS NULL 
                              OR Instr(pas_subapl, '$sub_apl') = 0 )  
                " );

    #TODO ocommit();

    return;
}

sub get_pass_projects {
    my ( $self, $pase ) = @_;

    return $self->db->array( "
        SELECT DISTINCT TRIM(environmentname) 
        FROM   harenvironment e, 
               harpackage p, 
               dist_paquete_pase pp 
        WHERE  p.envobjid = e.envobjid 
               AND p.packageobjid = pp.packageobjid 
               AND pp.pase = '$pase'  
        " );
}

sub get_owners {
    my ( $self, $packages_ref ) = @_;

    my @packages = _array($packages_ref);
    my %users    = ();

    #	my @Projects = getpackagesProjects(@packages);
    #	my @users = getProjectManagers(@Projects);

    foreach (@packages) {
        my $user = $self->db->value( "
                        SELECT TRIM(username) 
                        FROM   harallusers, 
                               harpackage 
                        WHERE  usrobjid = assigneeid 
                               AND TRIM(packagename) = '$_'  
                        " );

        $users{$user} = 1;
    }

    return keys %users;
}

sub get_ra {
    my ( $self, $env_name, $sem ) = @_;

    #TODO semUpMail("get_ra");

    my @resultado = $self->db->array( "
                        SELECT DISTINCT Upper(TRIM(username)) 
                        FROM   haruser u, 
                               harusergroup g, 
                               harusersingroup ug 
                        WHERE  TRIM(g.usergroupname) = Upper(Substr('$env_name', 0, 3) 
                                                              || '-RA') 
                               AND g.usrgrpobjid = ug.usrgrpobjid 
                               AND ug.usrobjid = u.usrobjid 
                               AND u.usrobjid > 2 
                               AND u.usrobjid NOT IN (SELECT iug.usrobjid 
                                                      FROM   harusergroup ig, 
                                                             harusersingroup iug 
                                                      WHERE  ig.usrgrpobjid = iug.usrgrpobjid 
                                                             AND Upper(TRIM(ig.usergroupname)) = 
                                                                 Upper(Substr('$env_name', 0, 3) 
                                                                        || '-JU'))  
                        " );

    #TODO semDownMail("get_ra");

	return \@resultado;
}

sub get_ra_alone {
    my ( $self, $env_name, $sem ) = @_;

    return $self->db->array( "
                SELECT DISTINCT Upper(TRIM(username)) 
                FROM   haruser u, 
                       harusergroup g, 
                       harusersingroup ug 
                WHERE  TRIM(g.usergroupname) = Upper(Substr('$env_name', 0, 3) 
                                                      || '-RA') 
                       AND g.usrgrpobjid = ug.usrgrpobjid 
                       AND ug.usrobjid = u.usrobjid 
                       AND u.usrobjid > 2 
                       AND u.usrobjid NOT IN (SELECT iug.usrobjid 
                                              FROM   harusergroup ig, 
                                                     harusersingroup iug 
                                              WHERE  ig.usrgrpobjid = iug.usrgrpobjid 
                                                     AND Upper(TRIM(ig.usergroupname)) = 
                                                         Upper(Substr('$env_name', 0, 3) 
                                                                || '-JU'))  
                ");
}

##getEmailSMTP: devuelve la direc. de correo SMTP de un grupo RPT
sub get_email_rpt {
    my ( $self, $grupo_rpt ) = @_;

    return $self->db->value( "
                SELECT Max(smtp) 
                FROM   inf_rpt 
                WHERE  TRIM(usergroupname) = '$grupo_rpt'  
                " );
}

sub get_real_name {
    my ( $self, $user_name ) = @_;

    my @user_id = $self->db->array( "
                        SELECT TRIM(realname) 
                        FROM   haruser 
                        WHERE  TRIM(Upper(username)) = '" . uc($user_name) . "'  
                        " );

    return $user_id[0];
}

sub get_package_num_items {
    my ( $self, $package_id ) = @_;

    my @num_elementos = $self->db->array( "
                            SELECT v.itemobjid 
                            FROM   harversions v 
                            WHERE  v.packageobjid = $package_id  
                            ");

	my $retorno = @num_elementos;

	return $retorno;
}

sub get_package_groups {
    my ( $self, $package_name ) = @_;
    
    return $self->db->array( "
                SELECT TRIM(pkggrpname) 
                FROM   harpackage p, 
                       harpkgsinpkggrp pp, 
                       harpackagegroup g 
                WHERE  p.packageobjid = pp.packageobjid 
                       AND pp.pkggrpobjid = g.pkggrpobjid 
                       AND TRIM(p.packagename) = TRIM('$package_name')  
                " );        
}

1;
