package BaselinerX::Model::CargaFTP;
use Baseliner::Plug;
use Baseliner::Utils;
use Net::FTP;
use Baseliner::Core::DBI;
use DBIx::Class::ResultSetColumn;
use Try::Tiny;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub set_fusr {
    my ( $self, $perl_temp ) = @_;

    $perl_temp = '/home/aps/scm/servidor/tmp';

    return "$perl_temp/carga$$";
}

sub set_ticket {
    my ( $self, $ftp_server, $whoami ) = @_;
    my $ret = `racxtk 01 $whoami ftp $ftp_server`;
    $ret
}

sub all_users {
    my ( $self ) = @_;

    my %args = (
        select => [ "trim(username)", "trim(usergroupname)" ],
        as     => [qw/ USR GRP /],
        join     => { harusersingroups => [ 'usrobjid', 'usrgrpobjid' ] },
        order_by => { -asc             => [ 'username', 'usergroupname' ] },
    );
    my $rs_users = Baseliner->model("Harvest::Haruser")->search( undef, \%args );

    #-----------------------------------------------------------------------------------------------
    # SELECT TRIM(username),
    #        TRIM(usergroupname)
    # FROM   haruser me
    #        LEFT JOIN harusersingroup harusersingroups
    #          ON harusersingroups.usrobjid = me.usrobjid
    #        LEFT JOIN harusergroup usrgrpobjid
    #          ON usrgrpobjid.usrgrpobjid = harusersingroups.usrgrpobjid
    # ORDER  BY username ASC,
    #           usergroupname ASC
    #-----------------------------------------------------------------------------------------------

    rs_hashref($rs_users);

    my %users = map { $_->{USR}, $_->{GRP} } $rs_users->all;

    return \%users;
}

sub set_grupos_inf_rpt {
    my ( $self ) = @_;

    my $value = qw/ '\$' /;
    my %where = (
        'wingroupname' => { '!=', undef },
        'substr( usergroupname, 1, 1 )' => { '<>' => $value }
    );
    my $rs_users = Baseliner->model("INF::InfRpt")
                       ->search( %where, { select => [ 'usergroupname', 'wingroupname' ], }, );

    #-----------------------------------------------------------------------------------------------
    #   Query original:
    #-----------------------------------------------------------------------------------------------
    #   SELECT usergroupname,
    #          wingroupname
    #   FROM   inf_rpt
    #   WHERE  Substr(usergroupname, 1, 1) <> '\$'
    #          AND wingroupname IS NOT NULL
    #-----------------------------------------------------------------------------------------------
    #   $rs_users->as_query
    #-----------------------------------------------------------------------------------------------
    #   SELECT usergroupname,
    #          wingroupname
    #   FROM   inf_rpt me
    #   WHERE  (( Substr(usergroupname, 1, 1) <> '\$'
    #          AND wingroupname IS NOT NULL ))
    #-----------------------------------------------------------------------------------------------

    rs_hashref($rs_users);

    my %users = map { $_->{usergroupname}, $_->{wingroupname} } $rs_users->all;

    return \%users;
}

sub establecer_conexion_ftp {
    my ( $self ) = @_;
    my %est_con_ftp_args = %{@_};

    my $secret                = $est_con_ftp_args{secret};
    my $ftp_server            = $est_con_ftp_args{ftp_server};
    my $whoami                = $est_con_ftp_args{whoami};
    my $ldif_remote_directory = $est_con_ftp_args{ldif_remote_directory};
    my $ldif_home_directory   = $est_con_ftp_args{ldif_home_directory};

    if ( substr( $secret, 0, 5 ) eq "Error" ) {

        #TODO ERROR
    }
    elsif ($secret) {

        #Descargo ficheros
        my $ftp = Net::FTP->new( $ftp_server, Debug => 0 );
        $ftp->login( $whoami, $secret );
        $ftp->cwd($ldif_remote_directory)
            ;    #TODO or logerr("LDIF: ERROR en CWD a $ldif_remote_directory.");
        $ftp->get( "grp_adminis.ldif",  "$ldif_home_directory/grp_adminis.ldif" );
        $ftp->get( "grp_analist.ldif",  "$ldif_home_directory/grp_analist.ldif" );
        $ftp->get( "grp_progrm.ldif",   "$ldif_home_directory/grp_progrm.ldif" );
        $ftp->get( "grp_cfuentes.ldif", "$ldif_home_directory/grp_cfuentes.ldif" );
        $ftp->get( "infra_plat.txt",    "$ldif_home_directory/infra_plat.txt" );
        $ftp->get( "grp_soporte.ldif",  "$ldif_home_directory/grp_soporte.ldif" );
        $ftp->quit;

        # OK, ARCHIVOS DESCARGADOS
    }

    return;
}

sub semUpMail {
    my ( $self ) = @_;

=begin  BlockComment  # semUpMail

    my $proceso = shift @_;
    my $waitSem = 1;
    while ($waitSem) {
        if ( $SEM{"Mail"} && $SEM{"Mail"} ne $proceso ) {
            ##sem pillado por otro pase!
            print "Envío de correos: Retenido por el proceso $SEM{Mail}\n";
     		logdebug "Envío de correos: Retenido por el proceso $SEM{Mail}\n";ºº
     		sleep $WaitTime;
     	}
     	else {
     		##es míío, míííío!
    		print "Envío de correos: Proceso $proceso semáforo UP\n";
     	$SEM{"Mail"} = $proceso;
     		$waitSem = 0;
     	}
     }

=end    BlockComment  # semUpMail

=cut

    return;
}

sub concatenar_ficheros_directorio {
    my ( $self, $ldif_home_directory ) = @_;

    my $apl        = undef;
    my $grp        = undef;
    my $group_name = undef;
    my $grpdesc    = undef;
    my $datos_log  = undef;
    my $user       = undef;
    undef my %GruposInfRpt;
    undef my %groups;
    undef my %user_group;
    undef my %user_group_2;

    #FIXME No puedo hacer cat así que me creo un fichero con todos las entradas de los ficheros ya
    #concatenados.
    #my @datos     = `cat $ldif_home_directory/*`;

    open PRUEBA, "<", "C:\\WINNT\\Profiles\\q74613x\\Escritorio\\ficheros\\pruebas_eric.ldif"
        or die $!;
    my @datos = <PRUEBA>;

    while (@datos) {
        $datos_log .= $_;

        #TODO loginfo "LDIF: ficheros de datos parseados.", $datosLog;

        # SP
        # Grupos soporte
        if (/racfid=GP(...),profiletype=GROUP/i) {
            $apl = uc $1;

            # Los grupos de soporte vienen sin el sufijo de 2 chars
            $grp        = 'SP';
            $group_name = $apl . "-" . $grp;

            # Apunto nombre y desc de grupo
            $groups{$group_name} = $group_name;
        }

        # XX o CF
        elsif (/racfid=GP(...)(..),profiletype=GROUP/i) {
            $apl = uc $1;
            $grp = $2;
            if ( $grp eq "CF" ) {
                $group_name = $apl;
            }
            else {
                $group_name = $apl . "-" . $grp;
            }

            # Apunto nombre y desc de grupo
            $groups{$group_name} = $group_name;
        }

        # RA
        elsif (/racfid=ADP(...),profiletype=GROUP/i) {
            $apl        = uc $1;
            $grp        = "RA";
            $group_name = $apl . "-" . $grp;

            # Apunto nombre y desc de grupo
            $groups{$group_name} = $group_name;
        }

        if (/racfinstallationdata: (.*)/i) {

            # Descripción de grupo
            $grpdesc = $1;
            $grpdesc =~ s/\r//g;

            # Apunto nombre y desc de grupo
            $groups{$group_name} = $grpdesc;
        }

        if (/racfid=(.*),profiletype=USER/i) {
            $user = $1;

            # Cargo usuarios
            push @{ $user_group{$user} },   "$group_name";
            push @{ $user_group_2{$user} }, "'$group_name'";

            # Si tiene el rol -XX, también necesita el CAM a secas
            if ( $group_name =~ /\-/ ) {
                my $cam = substr( $group_name, 0, 3 );

                # Apunto nombre y desc de grupo
                $groups{$cam} = $cam;
                push @{ $user_group{$user} },   "$cam";
                push @{ $user_group_2{$user} }, "'$cam'";
            }
        }
        if (/WGF-([A-Z0-9]*) ([A-Za-z0-9]*)/) {

            # infra_plat.txt
            my $wingrp = uc $1;
            $user = $2;
            foreach my $grp ( keys %GruposInfRpt ) {
                my $wgrp = @{ $GruposInfRpt{$grp} }[0];
                if ( $wgrp eq $wingrp ) {

                    # print ahora()." - LDIF: RPT $user $grp\n";
                    # Apunto nombre y desc de grupio
                    $groups{$grp} = $grp;
                    push @{ $user_group{$user} },   "$grp";
                    push @{ $user_group_2{$user} }, "'$grp'";
                }
            }
        }
    }

    #TODO loginfo "LDIF: ficheros de datos parseados.", $datosLog;

    return {
        group_name   => $group_name,
        groups       => \%groups,
        user         => $user,
        user_group   => \%user_group,
        user_group_2 => \%user_group_2
    };
}

sub create_groups {
    my ( $self, $group_name, $groups_ref ) = @_;

    my %groups = %{$groups_ref};

    # Creo grupos si hace falta
    my $grpLog = undef;

    #TODO print ahora() . " - LDIF: Creando grupos...\n";

    foreach my $group_name ( keys %groups ) {

        #-------------------------------------------------------------------------------------------
        # PRUEBA
        #-------------------------------------------------------------------------------------------

        my %where = ( 'usergroupname' => $group_name );
        my $cnt = Baseliner->model("Harvest::Harusergroup")->count( %where );

        if ($cnt == 0) {
            my $db = new Baseliner::Core::DBI( { model => 'Harvest' } );

            my @data =
                $db->array_hash("SELECT sysdate, harusergroupseq.NEXTVAL as valor FROM dual");

            my $value   = shift @data;
            my $gid     = $value->{valor};
            my $sysdate = $value->{sysdate};

            my $row = Baseliner->model("Harvest::Harusergroup")->create(
                {   usrgrpobjid   => $gid,
                    usergroupname => $group_name,
                    creationtime  => { 'to_date' => $sysdate },
                    creatorid     => 1,
                    modifiedtime  => { 'to_date' => $sysdate },
                    modifierid    => 1,
                    note          => $groups{$group_name}
                }
            );
        }
    }


#       # Gets the ID to create a new group
#        my $db = new Baseliner::Core::DBI( { model => 'Harvest' } );
#
#        my @data = $db->array_hash( "SELECT sysdate, harusergroupseq.NEXTVAL as valor FROM dual" );
#
#        my $value   = shift @data;
#        my $gid     = $value->{valor};
#        my $sysdate = $value->{sysdate};
#
#        my $cd = Baseliner->model->('Harvest::Harusergroup')->find_or_create(
#            {   usrgrpobjid   => $gid,
#                usergroupname => $group_name,
#                creationtime  => { 'to_date' => $sysdate },
#                creatorid     => 1,
#                modifiedtime  => { 'to_date' => $sysdate },
#                modifierid    => 1,
#                note          => $groups{$group_name}
#            },
#            { 'usergroupname' => $group_name }
#        );

        #-------------------------------------------------------------------------------------------


=begin  BlockComment  # BlockCommentNo_1

        # Hago un count de usergroupname
        my %where = ( 'usergroupname' => $group_name );
        my %args  = ( select          => 'usergroupname' );
        my $cnt = Baseliner->model("Harvest::Harusergroup")->count( %where, \%args );

        if ( $cnt == 0 ) {

            #TODOprint ahora() . " - LDIF: Nuevo grupo '$group_name'\n";
            $grpLog .= "$group_name\n";

            # Gets the ID to create a new group
            my $db = new Baseliner::Core::DBI( { model => 'Harvest' } );

            my @data  = $db->array_hash("SELECT harusergroupseq.NEXTVAL as id FROM dual");
            my $valor = shift @data;
            my $gid   = $valor->{id};

            @data  = $db->array_hash("SELECT sysdate from dual");
            $valor = shift @data;
            my $sysdate = $valor->{sysdate};

            # Inserts new group
            Baseliner->model('Harvest::Harusergroup')->create(
                {   usrgrpobjid   => $gid,
                    usergroupname => $group_name,
                    creationtime  => $sysdate,
                    creatorid     => 1,
                    modifiedtime  => $sysdate,
                    modifierid    => 1,
                    note          => $groups{$group_name}
                }
            );

            #---------------------------------------------------------------------------------------
            # as_query
            #---------------------------------------------------------------------------------------
            #    INSERT INTO harusergroup 
            #                (creationtime, 
            #                 creatorid, 
            #                 modifiedtime, 
            #                 modifierid, 
            #                 note, 
            #                 usergroupname, 
            #                 usrgrpobjid) 
            #    VALUES      ( "2011-02-10 12:25:35", 
            #                  1, 
            #                  "2011-02-10 12:25:35", 
            #                  1, 
            #                  'UNI-RA', 
            #                  'UNI-RA', 
            #                  "6727" )  
            #---------------------------------------------------------------------------------------
        }
        else {

            # print ahora()." - LDIF: Ya existe el grupo '$group_name'\n";
        }

=end    BlockComment  # BlockCommentNo_1

=cut


    return;
}

    #TODO loginfo( "LDIF: Nuevos grupos creados.", $grpLog ) if($grpLog);
#    return;
#}

sub create_users {
    my ( $self, $create_users_args ) = @_;

    my $fusr         = $create_users_args->{fusr};
    my $user         = $create_users_args->{user};
    my %user_group   = %{ $create_users_args->{user_group} };
    my %user_group_2 = %{ $create_users_args->{user_group_2} };

    undef my %where;
    undef my %args;

    #TODO Crear o actualizar usuarios
    # print ahora() . " - LDIF: Creando y actualizando usuarios. Espere...\n";

    # Creo fichero de nuevos usuarios
    open FUSR, ">$fusr";
    my $fusrLog = undef;

    # Creo fichero de usuarios ya existentes
    # Pongo los usuarios y sus grupos en el sitio correspondente

    foreach my $user ( keys %user_group ) {

        #-------------------------------------------------------------------------------------------
        # $cnt = oval " SELECT COUNT(*)
        #               FROM   haruser
        #               WHERE  Upper(TRIM(username)) = Upper('$user')";
        #-------------------------------------------------------------------------------------------

        my $column = 'me.username';
        %where = ( "trim(upper(\'$column\'))" => "upper(\'$user\')" );
        my $cnt = Baseliner->model("Harvest::Haruser")->count(%where);

        #-------------------------------------------------------------------------------------------
        # $cnt->as_query
        #-------------------------------------------------------------------------------------------
        # SELECT COUNT(*)
        # FROM   haruser me
        # WHERE  ( Upper(me.username) = ? )
        #-------------------------------------------------------------------------------------------

        if ( $cnt == 0 ) {

            # Creo nuevo usuario

            # print ahora()." - LDIF: NEW '$user'\n";
            # FORMATO: UserName|Password|RealName|Phone#|Ext|Fax#|Email|note|Usrgrp1|Usrgrp2|...
            #FIXME
            my $usrgrp = join '|', @{ $user_group{$user} };
            #my @temp = $user_group{$user};
            #my $usrgrp = join '|', @temp;

           #TODO print FUSR "$user||$user|0000|999|000|$user\@correo.interno|$user|$usrgrp\n";
           #TODO $fusrLog .= "$user|*****|$user|0000|999|000|$user\@correo.interno|$user|$usrgrp\n";
        }
        else {

            # Updateo usuario
            #TODO $fusrLog .= "Actualizo usuario '$user'.\n";

            #---------------------------------------------------------------------------------------
            # my $usrid = oval "  SELECT usrobjid
            #                     FROM   haruser
            #                     WHERE  Upper(TRIM(username)) = Upper('$user')  ";
            #---------------------------------------------------------------------------------------

            %where = ( "UPPER(me.username) =" => "UPPER($user)" );
            %args = ( select => 'usrobjid' );
            my $usrid = Baseliner->model("Harvest::Haruser")->search( %where, \%args );

            #---------------------------------------------------------------------------------------
            # $usrid->as_query
            #---------------------------------------------------------------------------------------
            # SELECT usrobjid
            # FROM   haruser me
            # WHERE  ( Upper(me.username) = ? )
            #---------------------------------------------------------------------------------------

            rs_hashref($usrid);

            my @list  = $usrid->all;
            my $value = shift @list;

            $usrid = $value->{usrid};

            my $usrgrp = join ',', @{ $user_group_2{$user} };

            #---------------------------------------------------------------------------------------
            # UPDATE haruser
            # SET    email = '$user\@correo.interno'
            # WHERE  Upper(TRIM(username)) = Upper('$user')
            #---------------------------------------------------------------------------------------

            %where = ( {"trim('username')"} => {"trim(\'$user\')"} );
            my $update_user =
                Baseliner->model('Harvest::Haruser')->search(%where)
                ->update( 'email' => $user . '@correo.interno' );

            # Administrador = 1

            #---------------------------------------------------------------------------------------
            # SELECT COUNT(*)
            # FROM   harusersingroup
            # WHERE  usrobjid = $usrid
            #        AND usrgrpobjid = 1
            #---------------------------------------------------------------------------------------

            %where = ( { 'usrobjid' => $usrid }, { 'usrobjid' => 1 } );
            $cnt = Baseliner->model("Harvest::Harusersingroup")->count(%where);

            if ( $cnt == 0 ) {

                # Me cargo grupos superfluos si el usuario NO es administrador

                #-----------------------------------------------------------------------------------
                # DELETE FROM harusersingroup
                # WHERE  usrobjid = $usrid
                #        AND usrgrpobjid NOT IN (SELECT usrgrpobjid
                #                                FROM   harusergroup
                #                                WHERE  usergroupname IN ( $usrgrp ))
                #-----------------------------------------------------------------------------------

                %where = ( 'usergroupname' => { -in => $usrgrp } );
                %args = ( select => 'usrgrpobjid' );
                my $sub_select =
                    Baseliner->model('Harvest::Harusergroup')->search( %where, \%args );

                %where = (
                    { 'usrobjid'    => $usrid },
                    { 'usrgrpobjid' => [ -not_in => $sub_select->as_query ] }
                );
                %args = undef;
                my $borrar_grupos =
                    Baseliner->model('Harvest::Harusersingroups')->search( %where, \%args );

                # Bye bye
                $borrar_grupos->delete;
            }
            else {

                #TODO print ahora() . " - LDIF: usrgrpobjid=1: $user ($usrid)\n";
            }
            foreach my $groupname ( @{ $user_group_2{$user} } ) {

                #-----------------------------------------------------------------------------------
                # SELECT COUNT(*)
                # FROM   harusersingroup uig,
                #        harusergroup ug
                # WHERE  uig.usrobjid = $usrid
                #        AND uig.usrgrpobjid = ug.usrgrpobjid
                #        AND ug.usergroupname = $groupname
                #-----------------------------------------------------------------------------------

                %where = (
                    { 'harusersingroups.usrobjid' => $usrid },
                    { 'usrgrpobjid.usergroupname' => $groupname }
                );
                %args = ( join => { 'harusersingroups' => 'usrgrpobjid' } );
                $cnt = Baseliner->model('Harvest::Harusergroup')->count( %where, \%args );

                if ( $cnt == 0 ) {

                    # Insert new groups

                    #-------------------------------------------------------------------------------
                    # INSERT INTO harusersingroup
                    #             (usrobjid,
                    #              usrgrpobjid)
                    # SELECT $usrid,
                    #        usrgrpobjid
                    # FROM   harusergroup
                    # WHERE  usergroupname = $groupname
                    #-------------------------------------------------------------------------------

                    my %where = ( 'usergroupname' => $groupname );
                    my %args = ( select => [ $usrid, 'usrgrpobjid' ], );
                    my $valores =
                        Baseliner->model('Harvest::Harusergroup')->search( %where, \%args );

                    #-------------------------------------------------------------------------------
                    # $valores
                    #-------------------------------------------------------------------------------
                    # SELECT $usrid,
                    #        usrgrpobjid
                    # FROM   harusergroup me
                    # WHERE  ( usergroupname = $groupname )
                    #-------------------------------------------------------------------------------

                    my $new_group =
                        Baseliner->model('Harvest::Harusersingroup')->create( \$valores->as_query );
                }
            }
        }
    }
    return;
}

sub delete_users {
    my ( $self, $delete_users_args ) = @_;

    my %user_group          = %{ $delete_users_args->{user_group} };
    my $broker              = $delete_users_args->{broker};
    my $harvest_user        = $delete_users_args->{harvest_user};
    my $harvest_password    = $delete_users_args->{harvest_password};
    my $udp_home            = $delete_users_args->{udp_home};
    my $ldif_home_directory = $delete_users_args->{ldif_home_directory};
    my $users_inicial       = $delete_users_args->{users_inicial};
    my $fusr                = $delete_users_args->{fusr};

    # Delete all users not included in LDIF

    #-----------------------------------------------------------------------------------------------
    # SELECT DISTINCT usrobjid,
    #                 TRIM(username),
    #                 TRIM(realname)
    # FROM   haruser u
    # WHERE  u.usrobjid > 1
    #        AND NOT EXISTS (SELECT *
    #                        FROM   harusersingroup ug,
    #                               harusergroup g
    #                        WHERE  u.usrobjid = ug.usrobjid
    #                               AND ug.usrgrpobjid = g.usrgrpobjid
    #                               AND TRIM(Upper(g.usergroupname)) IN (
    #                                   'SCM', 'ADMINISTRATOR', 'ADMINISTRADOR',
    #                                   'DEPARTAMENTOS_USUARIOS' ))
    #-----------------------------------------------------------------------------------------------

    my %where =
        ( "trim(upper(harusergroups.usergroupname))" =>
            { -in => [qw/ SCM ADMINISTRATOR ADMINISTRADOR DEPARTAMENTOS_USUARIOS /] } );

    my %args = ( join => { harusersingroups => [ harusergroups => 'usrgrpobjid' ] }, );

    my $sub_select = Baseliner->model('Harvest::Haruser')->search( %where, \%args );

    my %where_two = ( 'usrobjid' => { '>', 1 }, -not_exists => $sub_select->as_query );
    my %args_two = ( distinct => 1, select => [ 'usrobjid', "trim(username)", "trim(realname)" ] );

    my $harushers_rs = Baseliner->model('Harvest::Haruser')->search( %where_two, \%args_two );

    my $delete_count = 0;
    my $deltxt       = "Usuarios borrados en Harvest:\n";

    #foreach my $hid ( keys %HARUSERS ) {
    #    my ( $husr, $realname ) = @{ $HARUSERS{$hid} };
    #    if ( !( $user_group{ lc($husr) } || $user_group{ uc($husr) } ) ) {

    #        print ">>>LDIF: borro el usuario $husr ($realname) en Harvest\n";
    #        $deltxt .= "$husr ($realname)\n";

    #        %where = ( "upper(username)" => "upper(\'$husr\')" );
    #        %args = undef;
    #        my $delete_user_rs = Baseliner->model("Harvest::Haruser")->search(%where);

    #        $delete_user_rs->delete;

    #        $delete_count++;
    #    }
    #}

    while ( my $r = $harushers_rs->next ) {
        my ( $username, $realname ) = @{$harushers_rs}{qw/ username realname /};

        if ( !( $user_group{ lc($username) } || $user_group{ uc($username) } ) ) {
            $deltxt .= "$username ($realname)\n";

            #---------------------------------------------------------------------------------------
            # DELETE FROM haruser
            # WHERE  Upper(username) = Upper(haruser)
            #---------------------------------------------------------------------------------------

            %where = ( "upper(username)" => "upper(\'$username\')" );
            my $delete_user_rs = Baseliner->model("Harvest::Haruser")->search(%where);

            #Borro usuarios
            $delete_user_rs->delete;

            $delete_count++;
        }
    }

    if ( $delete_count > 0 ) {

        #TODO print ahora() . " - LDIF: $delete_count usuario(s) borrado(s) en Harvest\n";
        #TODO loginfo "LDIF: $delete_count usuario(s) borrado(s) en Harvest", $deltxt;
    }

    # Close FUSROW
    close FUSR;

    #TODO
    # Add all users to group 'Public' (id=2)

    #-----------------------------------------------------------------------------------------------
    # INSERT INTO harusersingroup
    #             (usrobjid,
    #              usrgrpobjid)
    # SELECT hu.usrobjid,
    #        2
    # FROM   haruser hu
    # WHERE  NOT EXISTS (SELECT 'x'
    #                    FROM   harusersingroup huig
    #                    WHERE  huig.usrobjid = hu.usrobjid
    #                           AND huig.usrgrpobjid = 2)
    #-----------------------------------------------------------------------------------------------

    #FIXME
    Baseliner->model('CargaLdifQueries')->insert_new_users_to_public();

    ##FIXME
    ## Gets the subselect to use in NOT EXISTS
    #my %where_one = ( 'harusersingroups.usrgrpobjid' => 2 );
    #my %args_one = ( select => 'harusersingroups.x', join => 'harusersingroups' );
    #my $sub_select_one = Baseliner->model('Harvest::Haruser')->search( %where_one, \%args_one );

    ## Gets the subselect that contains the data to insert into harusersingroups
    #%where_two = ( -not_exists => $sub_select_one->as_query );
    #%args_two = ( select => [ 'me.usrobjid', 'me.usrgrpobjid' ] );
    #my $sub_select_two = Baseliner->model('Harvest::Haruser')->search( %where_two, \%args_two );

    ##Inserts data...
    #my $new_haruser_row =
    #  Baseliner->model('Harvest::Harusersingroup')
    #  ->create( { [ 'usrobjid', 'usrgrpobjid' ] => $sub_select_two->as_query } );

    ##FIXME
    #my $sql_1 = "   SELECT hu.usrobjid,
    #                FROM   haruser hu
    #                WHERE  NOT EXISTS (SELECT 'x'
    #                                   FROM   harusersingroup huig
    #                                   WHERE  huig.usrobjid = hu.usrobjid
    #                                          AND huig.usrgrpobjid = 2) ";

    #my $sql_2 = "   SELECT  hu.usrgrpobjid
    #                FROM   haruser hu
    #                WHERE  NOT EXISTS (SELECT 'x'
    #                                   FROM   harusersingroup huig
    #                                   WHERE  huig.usrobjid = hu.usrobjid
    #                                          AND huig.usrgrpobjid = 2) ";

    #Baseliner->model('Harvest::Harusersingroup')
    #    ->create( { usrobjid => $sql_1, usrgrpobjid => $sql_2 } );

    ##... into the database
    #$new_haruser_row->insert;

    # husrmgr of new users
    if ( -s $fusr ) {

        #TODO print ahora() . " - LDIF: Creando usuarios...\n";
        #TODO loginfo "LDIF: Listado de usuarios a crear y actualizar en Harvest...", $fusrLog;

        ### CODIGO YA COMENTADO ANTERIORMENTE ###
        # x#print "husrmgr -b $broker -usr $harvest_user -pw $harvest_password -dlm '\|' -o"
        #     . "$udp_home/husrmgr.log $fusr\n";
        # @RET = "husrmgr -b $broker -usr $harvest_user -pw $harvest_password -dlm '\|' -o ";
        # @RET .= "$udp_home/husrmgr.log $fusr";

        my @RET = `husrmgr -b $broker $harvest_user $harvest_password -dlm '\|' -o `
            . `$udp_home/husrmgr.log $fusr`;

        if ( $? ne 0 ) {
            my $ret = capturaLog( "$udp_home/husrmgr.log", @RET );

            #TODO print ahora() . " - LDIF ERROR: husrmgr: " . $ret . "\n";
            #TODO loginfo "LDIF: Carga de nuevos usuarios.", $ret;
        }
        else {

            #TODO print "-----Usuarios Nuevos-----\n";
            @RET = `grep 'User Name:' $udp_home/husrmgr.log`;

            #TODO print "@RET\n";
        }
    }

    ## husrmgr de existentes
    # if ( -s $fusrow ) {
    #     #TODO print ahora()." - LDIF: Actualizando usuarios...\n";
    #     @RET = `husrmgr -b $broker -dlm '\|' -ow -o $udp_home/husrmgr.log $fusrow`;
    #     #TODO print "-----Usuarios Existentes------\n@RET\n";
    #     @RET = `cat $udp_home/husrmgr.log`;
    #     #TODO print "@RET\n";
    # }

    #TODO print ahora() . " - LDIF: Sincronizando los datos del formulario\n";
    try {
        my $dbh = Baseliner::Core::DBI->new( { model => 'Harvest' } );
        $dbh->do('begin inf_data_update; end;');
    }
    catch {

        #TODO cluck ahora()
        #   . " - LDIF: ERROR durante la sincronización de datos del formulario:\n"
        #   . shift() . "\n\n";
    };

    #TODO print ahora() . " - LDIF: Fin de la carga LDIF\n";
    #TODO loginfo "LDIF: Fin de la carga LDIF.";
    #TODO semDownMail("Ldiff");

    # Takes a picture of all users currently in the database
    #FIXME my $all_users_result = $c->model('CargaFTP')->all_users();
    #FIXME my %users_end = %{$all_users_result};

    #TODO
    # logdebug "LDIF: Listado de usuarios antes de la carga",   $users_inicial;
    # logdebug "LDIF: Listado de usuarios después de la carga", $users_final;

    # oclose();

    # CLEANUP
    my $x =
        `rm -rf $ldif_home_directory/.last; mkdir $ldif_home_directory/.last; mv -f $ldif_home_directory/* $ldif_home_directory/.last`;

    return;
}

1;
