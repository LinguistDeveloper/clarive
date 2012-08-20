package BaselinerX::Model::LoadApplication;
use Baseliner::Plug;
use Baseliner::Utils;
use Catalyst::Log;
use 5.010;
use strict;
use warnings;
use Try::Tiny;
BEGIN { extends 'Catalyst::Model' }

sub process_name {
    # cambia el nombre de proceso para los "ps" de unix
    my ( $self, $proc ) = @_;

    $0 = "perl $0 ($proc)";

    # Nota: Puede que esto no funcione
}

sub set_is_public {
    my ( $self, $is_public_string ) = @_;

    return $is_public_string =~ /^S/ ? 1 : 0; 
}

sub set_is_sistemas {
    my ( $self, $sistemas ) = @_;

    return $sistemas =~ /^S/ ? 1 : 0;
}

sub exist_environment {
    my ( $self, $env ) = @_;

    my %where = ( "trim(environmentname)" => $env );
    my $count = Baseliner->model('Harvest::Harenvironment')->count(%where);

    return $count;
}

sub exist_repository {
    my ( $self, $repository ) = @_;

    my %where = ( 'trim(repositname)' => $repository );
    my $count = Baseliner->model('Harvest::Harrepository')->count(%where);

    return $count;
}

sub _scm_apl_many {
    my ( $self, $args_ref ) = @_;

    my $column_name = $args_ref->{column_name};
    my $inf_data    = $args_ref->{inf_data};
    my $cam         = $args_ref->{cam};

    my $inf_db = BaselinerX::Ktecho::INF::DB->new;

    return $inf_db->db->value( qq/
        SELECT DISTINCT id.valor 
        FROM   $inf_data id 
        WHERE  id.idform = (SELECT MAX (IF.idform) 
                            FROM   inf_form IF 
                            WHERE  id.cam = IF.cam) 
            AND id.column_name = '$column_name'  
            AND cam = '$cam'
        / );        
}

#sub get_query_applications {
#    my ( $self, $inf_data ) = @_;
#
#    my $inf_db = BaselinerX::Ktecho::INF::DB->new;
#
#    my %envs = $inf_db->db->hash( "
#        SELECT DISTINCT Upper(cam)                    one, 
#                        Nvl(d.scm_apl_publica, 'No')  two, 
#                        d.scm_apl_crear               three, 
#                        Nvl(d.scm_apl_sistemas, 'No') four 
#        FROM   $inf_data d 
#        WHERE  d.id = (SELECT MAX(d2.id) 
#                    FROM   $inf_data d2 
#                    WHERE  d2.cam = d.cam)  
#        " );
#
#    return \%envs;
#}

# Nota: Está modificada para que sólo me saque los cams, luego ya voy iterando
# el  cam y llamando  a _scm_apl_many para  sacar los valores,  que  ahora con
# inf_data F2 esto ya no vale.
sub get_query_applications {
    my ( $self, $inf_data ) = @_;

    my $inf_db = BaselinerX::Ktecho::INF::DB->new;

    return $inf_db->db->array(
        qq/
                SELECT DISTINCT id.cam 
                FROM   $inf_data id 
                WHERE  id.idform = (SELECT MAX(IF.idform) 
                                    FROM   inf_form IF 
                                    WHERE  id.cam = IF.cam)  
         /
    );
}

sub get_query_already_exists {
    my ( $self, $cam, $is_public ) = @_;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $sql = " 
        SELECT environmentname 
        FROM   harenvironment e 
        WHERE  e.envobjid > 0 
               AND e.envisactive <> 'T' ";
    $sql .= (
        $is_public
        ? " AND upper(SUBSTR(environmentname,0,3))=upper('$cam') "
        : " AND upper(environmentname) like upper('$cam (%)') "
    );

    my @already_exists = $har_db->db->array_hash($sql);

    return \@already_exists;
}

sub create_repository {
    my ( $self, $args_ref ) = @_;

    my $cam                  = $args_ref->{cam};
    my $repository_sufix     = $args_ref->{repository_sufix};
    my $repository_directory = $args_ref->{repository_directory};
    my $loghome              = $args_ref->{loghome};
    my $broker               = $args_ref->{broker};
    my $harvest_user         = $args_ref->{harvest_user};
    my $harvest_password     = $args_ref->{harvest_password};
    my $templates            = $args_ref->{templates};

    my ( $logfile, $c_ret, @ret );
    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

	try {
        if ( Baseliner->model('LoadApplication')->exist_repository( "$cam$repository_sufix" ) )
        {
            #logwarn "AltaAplicación $cam: repositorio '$cam$repository_sufix' ya existe.";
            $log->debug( "AltaAplicación $cam: repositorio '$cam$repository_sufix' ya existe.");

            return 1;
        }

		## Creación del repositorio $cam $repository_sufix
		my $repname = "$cam$repository_sufix";
		my $tplname = '_BDE';

        #loginfo "AltaAplicación $cam: Creando el repositorio '$repname' desde la plantilla . 
        #"'$tplname'...\n";
        $log->info(
            "LoadApplication $cam: Creating repository '$repname' from template '$tplname'...\n" );
		
		# Creamos el repositorio desde la plantilla
        $logfile = "$loghome/hlr$$.log";
        my @ret = `hrepmngr -b $broker $harvest_user $harvest_password -dup -srn '$tplname' -drn `
            . `'$repname' -o '$logfile'`;
        if ( $? ne "0" ) {
            #TODO die "$cam: ERROR creando el repositorio '$repname' de la plantilla '$tplname': "
            #TODO    . capturaLog( $logfile, @ret ) . "\n";
        }

        #TODO die "\n\t El repositorio $cam$repository_sufix ya existe. Borrelo o utilice otro nombre "
        #TODO    . "para la aplicación"
        #TODO    if $DBI::err;
		
        print ahora() . "AltaAplicación $cam: Asociando la vista al repositorio\n";
		
		## Cargamos la estructura inicial del repositorio
		$logfile = "$loghome/hlr$$.log";		
        @ret = `hlr -b $broker $harvest_user $harvest_password -cp `
            . `"$templates/repositorios/$repository_directory" -rp "/$cam$repository_sufix/" `
            . `-r -cep -f "*" -o '$logfile'`;
        if ( $? ne "0" ) {
            #TODO die "$cam: ERROR cargando la estructura inicial del repositorio: "
            #TODO    . capturaLog( $logfile, @ret ) . "\n";
        }

        $log->info("AltaAplicación $cam: repositorio '$cam$repository_sufix' creado.\n");
	} catch {
        #TODO orollback();
        die "Error durante la creación del repositorio $cam$repository_sufix:".shift()."\n";
	};
	return 0;
}

sub create_application {
    my ( $self, $args_ref ) = @_;

	#   (el env_sufix puede ser "(Red Interna)" o "(Internet)" o "" )
    my $cam              = $args_ref->{cam};
    my $env_sufix        = $args_ref->{env_sufix};
    my $env_template     = $args_ref->{env_template};
    my $loghome          = $args_ref->{loghome};
    my $broker           = $args_ref->{broker};
    my $harvest_user     = $args_ref->{harvest_user};
    my $harvest_password = $args_ref->{harvest_password};
    my $sufix_repo       = q//;                            #en BDE, el repositorio siempre es $cam

    print ahora() . "AltaAplicación $cam: Creando aplicación $cam$env_sufix...\n";

    my ( $logfile, $c_ret, @ret );

    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );
    
	try {						
        if ( Baseliner->model('LoadApplication')->exist_environment("$cam$env_sufix") ) {
            #logwarn "AltaAplicación $cam: ya existe la aplicación '$cam$env_sufix'. Creación
            #ignorada. " . "No se ha cambiado la asociación de la aplicación al repositorio.";
            $log->debug( "LoadApplication: $cam: The application '$cam$env_sufix' already "
                    . "exists. Creation ignored. Change of the association of the application for"
                    . " its repository did not take place." );

            return 1;
        }

		# SCM_APL_SISTEMAS

		# Copia un nuevo projecto desde la plantilla Ciclo de Vida _BDE.
        $logfile = "$loghome/hcpj$$.log";
        #loginfo "AltaAplicación $cam: Copiando plantilla $env_template a '$cam$env_sufix'...";
        $log->info(
            "AltaAplicación $cam: Copiando plantilla $env_template a '$cam$env_sufix'..." );

        @ret = `hcpj -b $broker $harvest_user $harvest_password -cpj "$env_template" -npj `
            . `"$cam$env_sufix" -act -o '$logfile'`;

        if ( $? ne "0" ) {
            #TODO die "$cam: ERROR copiando aplicación $cam$env_sufix desde la plantilla: "
            #TODO    . capturaLog( $logfile, @ret ) . "\n";
        }

		# Activamos la protección sobre los nombres de paquete.

=begin  BlockComment  # Con DBIx::Class

        my %vals  = ( 'disablenamechange' => 'Y' );
        my %where = ( 'processname' => { 'like', '%PAQUETE:%Crear%' } );

        #FIXME La clase Harcrpkgproc no está creada en el esquema de BD de Harvest
        my $insert_row = Baseliner->model('Harvest::Harcrpkgproc')->search(%where);
        $insert_row->update( \%vals );

=end    BlockComment

=cut

        my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
        $c_ret = $har_db->db->do( "
                    UPDATE harcrpkgproc 
                    SET    disablenamechange = 'Y' 
                    WHERE  processname LIKE '%PAQUETE:%Crear%'  
                    " );

        #TODO ocommit();

        #loginfo
        #    "AltaAplicación $cam: Aplicación '$cam$env_sufix' (repositorio=$cam$sufix_repo) creada con éxito.";

        $log->info( "LoadApplication $cam: Creation of application '$cam$env_sufix' "
                . "(repositorio=$cam$sufix_repo) successful." );
	} catch {
        #TODO orollback();

        #TODO die "Error durante la creación de la aplicación $cam:".shift()."\n";
	};

	return 0;
}	

sub associate_apl_repository {
    my ( $self, $args_ref ) = @_;
    my $env              = $args_ref->{cam};
    my $repo             = $args_ref->{cam};
    my $loghome          = $args_ref->{loghome};
    my $broker           = $args_ref->{broker};
    my $harvest_user     = $args_ref->{harvest_user};
    my $harvest_password = $args_ref->{harvest_password};
    my $logfile          = undef;
    my @ret              = undef;

    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

	try {
		# Configuramos la BaseLine del proyecto.
        $logfile = "$loghome/hcbl$$.log";
        @ret = `hcbl -b $broker $harvest_user $harvest_password -en "$env" -rp "$repo" -add -rw -o `
            . `'$logfile'`;

        if ( $? ne "0" ) {
            #TODO die "$env: ERROR copiando baseline para $env desde la plantilla:"
            #TODO    . capturaLog( $logfile, @ret ) . "\n";
        }
        else {
            #loginfo "AltaAplicación $env asociado a $repo con éxito.";
            $log->info("Succesful association of LoadApplication $env to $repo");
        }
	} catch {
        #orollback();
        #TODO die "Error durante la asociación del repositorio $env a $repo:".shift()."\n";
	};

	return 0;
}


# Cambia los permisos de acceso a aplicaciones de [project][-XX] a cam_uc[-XX]
sub chg_permissions_application {
    my ( $self, $udpverbose ) = @_;
    my $har_db  = BaselinerX::Ktecho::Harvest::DB->new;
    my $log_txt = q//;
    my %group_id;
    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    try {
        my %envs = $$har_db->db->hash( "
            SELECT e.envobjid 
                    || '-' 
                    || ug.usrgrpobjid, 
                   e.envobjid, 
                   TRIM(environmentname), 
                   ug.usrgrpobjid, 
                   TRIM(ug.usergroupname), 
                   TRIM(ug.usergroupname) 
            FROM   harenvironment e, 
                   harenvironmentaccess ea, 
                   harusergroup ug 
            WHERE  e.envobjid = ea.envobjid 
                   AND ug.usrgrpobjid = ea.usrgrpobjid 
                   AND TRIM(envisactive)<>'T' 
                   AND ug.usergroupname LIKE '%[project]%' 
            ORDER  BY 2 " );

        foreach my $key ( keys %envs ) {
            my ( $env_id, $env_name, $group_process_id_old, $group_name, $group_name_old ) =
                @{ $envs{$key} };
            my ( $cam, $cam_uc ) = Baseliner->model('LoadApplication')->getcam_uc($env_name);

            $group_name =~ s/\[project\]/$cam_uc/g;

            $log_txt .= "Updating group '$group_name_old' to '$group_name' in '$env_name'\n";

            $group_id{$group_name} =
                $har_db->get_user_group_id($group_name)
                unless $group_id{$group_name};

            my $group_process_id_new = $group_id{$group_name};

            if ($group_process_id_new) {
                my %where = ( 'envobjid' => $env_id, 'usrgrpobjid' => $group_process_id_new );
                my $delete_row = Baseliner->model('Harvest::Harenvironmentaccess')->search(%where);
                $delete_row->delete;

                %where = ( 'envobjid' => $env_id, 'usrgrpobjid' => $group_process_id_old );
                my %values = (
                    'usrgrpobjid'   => $group_process_id_new,
                    'secureaccess'  => 'N',
                    'updateaccess'  => 'N',
                    'viewaccess'    => 'Y',
                    'executeaccess' => 'Y'
                );
                my $update_row = Baseliner->model('Harvest::Harenvironmentaccess')->search(%where);
                $update_row->update( \%values );

                #TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
            } 
        }
        $log->info( "Cambio de permisos en aplicaciones terminado OK.", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        $log->error( "ERROR en cambio de permisos en aplicaciones.",
            $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

# cambia los permisos de acceso a estados de [project][-XX] a cam_uc[-XX]
sub chg_permissions_states {
    my ($self, $udpverbose) = @_;

    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my %group_id;
    my $log_txt = ();

    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );
    
    try {
        my %states = $har_db->db->hash( "
            SELECT s.stateobjid 
                    || '-' 
                    || ug.usrgrpobjid, 
                   e.envobjid, 
                   s.stateobjid, 
                   TRIM(environmentname), 
                   TRIM(statename), 
                   ug.usrgrpobjid, 
                   TRIM(ug.usergroupname), 
                   TRIM(ug.usergroupname) 
            FROM   harenvironment e, 
                   harstateaccess sa, 
                   harstate s, 
                   harusergroup ug 
            WHERE  e.envobjid = s.envobjid 
                   AND s.stateobjid = sa.stateobjid 
                   AND ug.usrgrpobjid = sa.usrgrpobjid 
                   AND TRIM(envisactive)<>'T' 
                   AND ug.usergroupname LIKE '%[project]%' 
            ORDER  BY 2 " );

        foreach my $key ( keys %states ) {
            my ( $env_id, $state_id, $env_name, $state_name, $group_id_old, $group_name,
                $group_name_old )
                = @{ $states{$key} };
            my ( $cam, $cam_uc ) = get_cam_uc($env_name);

            $group_name =~ s/\[project\]/$cam_uc/g;
            $log_txt
                .= "Updating group '$group_id_old' to '$group_name' in '$env_name:$state_name'\n";
            $group_id{$group_name} =
                $har_db->get_user_group_id($group_name)
                unless $group_id{$group_name};

            my $group_id_new = $group_id{$group_name};

            if ($group_id_new) {

                # Delete
                my %where = ( 'stateobjid' => $state_id, 'usrgrpobjid' => $group_id_new );
                my $delete_row = Baseliner->model('Harvest::Harstateaccess')->search(%where);
                $delete_row->delete;

                # Update
                %where = ( 'stateobjid' => $state_id, 'usrgrpobjid' => $group_id_old );
                my %values = (
                    'usrgrpobjid'     => $group_id_new,
                    'updateaccess'    => 'N',
                    'updatepkgaccess' => 'Y'
                );
                my $update_row = Baseliner->model('Harvest::Harstateaccess')->search(%where);
                $update_row->update( \%values );
                #TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
            }
        }
        $log->info( "LoadApplication - Successful change of states.", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        $log->error( "ERROR en cambio de permisos en estados.", $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

# cambia los permisos de acceso a procesos de estado de [project][-XX] a cam_uc[-XX]
sub chg_permissions_processes {
    my ( $self, $udpverbose ) = @_;
    my $log_txt = ();
    my %group_id;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    try {
        my %processes = $har_db->db->hash("
            SELECT p.processobjid 
                    || '-' 
                    || ug.usrgrpobjid, 
                   e.envobjid, 
                   s.stateobjid, 
                   p.processobjid, 
                   TRIM(environmentname), 
                   TRIM(statename), 
                   TRIM(processname), 
                   ug.usrgrpobjid, 
                   TRIM(ug.usergroupname), 
                   TRIM(ug.usergroupname), 
                   sp.executeaccess 
            FROM   harenvironment e, 
                   harstateprocessaccess sp, 
                   harstate s, 
                   harstateprocess p, 
                   harusergroup ug 
            WHERE  e.envobjid = s.envobjid 
                   AND s.stateobjid = sp.stateobjid 
                   AND s.envobjid = e.envobjid 
                   AND ug.usrgrpobjid = sp.usrgrpobjid 
                   AND sp.processobjid = p.processobjid 
                   AND TRIM(envisactive)<>'T' 
                   AND ug.usergroupname LIKE '%[project]%' 
            ORDER  BY 2 ");

        foreach my $key ( keys %processes ) {
            my ($env_id,         $state_id,     $process_id,           $env_name,
                $state_name,     $process_name, $group_process_id_old, $group_name,
                $group_name_old, $exec
            ) = @{ $processes{$key} };

            my ( $cam, $cam_uc ) = get_cam_uc($env_name);

            $group_name =~ s/\[project\]/$cam_uc/g;

            if ( $exec eq "N" ) {
                $log_txt
                    .= "Deleting group '$group_name_old' in '$env_name:$state_name:$process_name'\n";

                my %where = (
                    'processobjid'  => $process_id,
                    'usrgrpobjid'   => $group_process_id_old,
                    'executeaccess' => 'N'
                );
                my $delete_row = Baseliner->model('Harvest::Harstateprocessaccess')->search(%where);
                $delete_row->delete;
            }
            else {
                $log_txt
                    .= "Updating group '$group_name_old' to '$group_name' in '$env_name:"
                        . "$state_name:$process_name'\n";
                $group_id{$group_name} =
                    Baseliner->model('LoadApplication')->get_user_group_id($group_name)
                    unless $group_id{$group_name};
                my $group_process_id_new = $group_id{$group_name};
                if ($group_process_id_new) {
                    my %where = (
                        'processobjid' => $process_id,
                        'usrgrpobjid'  => $group_process_id_new
                    );
                    #Update
                    my $delete_row =
                        Baseliner->model('Harvest::Harstateprocessaccess')->search(%where);
                    $delete_row->delete;

                    #Delete
                    %where = (
                        'processobjid' => $process_id,
                        'usrgrpobjid'  => $group_process_id_old
                    );
                    my %values = ( 'usrgrpobjid' => $group_process_id_new, 'executeaccess' => 'Y' );
                    #TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
                }
                else {
                    #$log_txt
                    #    .= "ERROR: Grupo '$group_name' no encontrado. ¿Se ha cargado el cam_uc "
                    #    . "'$cam_uc' desde LDAP/LDIF?\n";

                    $log_txt
                        .= "ERROR: Group '$group_name' not found. Has '$cam_uc' been loaded from "
                        . "LDAP/LDIF?\n";
                }
            }
        }
        $log->info( "Change of process permissions finished. OK.", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        #logerr( "ERROR en cambio de permisos en procesos.", $log_txt . "\n" . shift() );

        $log->error( "ERROR changing process permissions.", $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

# Cambia el nombre por defecto de los paquetes con [project] a cam_uc
sub chg_default_package {
    my ( $self, $udpverbose ) = @_;
    my $log_txt = ();
    my $har_db  = BaselinerX::Ktecho::Harvest::DB->new;
    my $log     = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    try {
        # Ahora cambio los nombres de paquete
        my %packages = $har_db->db->hash( "
            SELECT p.processobjid, 
                   e.envobjid, 
                   s.stateobjid, 
                   TRIM(environmentname), 
                   TRIM(statename), 
                   TRIM(p.processname), 
                   TRIM(cp.defaultpkgformname), 
                   TRIM(cp.defaultpkgformname) 
            FROM   harenvironment e, 
                   harstate s, 
                   harstateprocess p, 
                   harcrpkgproc cp 
            WHERE  e.envobjid = s.envobjid 
                   AND s.stateobjid = p.stateobjid 
                   AND cp.processobjid = p.processobjid 
                   AND TRIM(envisactive)<>'T' 
                   AND cp.defaultpkgformname LIKE '%[project]%' 
            ORDER  BY 2 " );

        foreach my $process_id ( keys %packages ) {
            my ( $env_id, $state_id, $env_name, $state_name, $process_name, $default_package_new,
                $default_package_old )
                = @{ $packages{$process_id} };
            my ( $cam, $cam_uc ) =
                Baseliner->model('LoadApplication')->get_user_group_id($env_name);

            $default_package_new =~ s/\[project\]/$cam_uc/g;
            #$log_txt .= "Actualizando nombre de paquete por defecto '$default_package_old' a "
            #    . "'$default_package_new' en '$env_name:$state_name:$process_name'\n";

            $log_txt
                .= "Updating default package name '$default_package_old' to '$default_package_new' "
                . "in '$env_name:$state_name:$process_name'\n";

            $default_package_new =~ s/\'/\'\'/g;

            my %where  = ( 'processobjid'       => $process_id );
            my %values = ( 'defaultpkgformname' => $default_package_new );
            my $update_row = Baseliner->model('Harvest::Harcrpkgproc')->search(%where);
            $update_row->update( \%values );
            #TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
        }
        #loginfo( "Cambio de nombres de paquetes por defecto terminado OK.", $log_txt )
        $log->info( "Change of default package name finished (OK).", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        #logerr( "ERROR en cambio nombres de paquetes por defecto .", $log_txt . "\n" . shift() );
        $log->error( "ERROR changing default package name.", $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

##########################################################################################
## Funciones de cambio de plantillas. 
##   Se intentará renombrar los grupos actuales a [project][-XX]
##    si el nuevo nombre de grupo no existe 
##   (pe. de 'Desarrollo' a '[project]ollo') se borrará el grupo del permiso.
##
sub chg_permissions_application_templates {
    my ( $self, $udpverbose ) = @_;
	my $log_txt=();
	my %group_id;
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    try {
        my %envs = $har_db->db->hash( "
            SELECT e.envobjid 
                    || '-' 
                    || ug.usrgrpobjid, 
                   e.envobjid, 
                   TRIM(environmentname), 
                   ug.usrgrpobjid, 
                   TRIM(ug.usergroupname), 
                   TRIM(ug.usergroupname) 
            FROM   harenvironment e, 
                   harenvironmentaccess ea, 
                   harusergroup ug 
            WHERE  e.envobjid = ea.envobjid 
                   AND ug.usrgrpobjid = ea.usrgrpobjid 
                   AND TRIM(environmentname) LIKE '\\_%' ESCAPE '\\' 
                   AND TRIM(envisactive) = 'T' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'PUBLIC%' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'ADMINIST%' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'RPT-%' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'SCM%' 
                   AND NOT TRIM(ug.usergroupname) LIKE '%[project]%' 
            ORDER  BY 2 " );

        foreach my $key ( keys %envs ) {
            my ( $env_id, $env_name, $group_process_id_old, $group_name, $group_name_old ) =
                @{ $envs{$key} };
            my ( $cam, $cam_uc ) = get_cam_uc($env_name);

            $group_name = "[project]" . substr( $group_name, 3 );
            $log_txt .= "Updating group '$group_name_old' to '$group_name' in '$env_name'\n";
            $group_id{$group_name} =
                Baseliner->model('LoadApplication')->get_user_group_id($group_name)
                unless $group_id{$group_name};
            my $group_process_id_new = $group_id{$group_name};
            if ($group_process_id_new) {
                #Delete
                my %where = ( 'envobjid' => $env_id, 'usrgrpobjid' => $group_process_id_new );
                my $delete_row = Baseliner->model('Harvest::Harenvironmentaccess')->search(%where);
                $delete_row->delete;

                #Update
                %where = ( 'envobjid' => $env_id, 'usrgrpobjid' => $group_process_id_old );
                my %values = (
                    'usrgrpobjid'   => $group_process_id_new,
                    'secureaccess'  => 'N',
                    'updateaccess'  => 'N',
                    'viewaccess'    => 'Y',
                    'executeaccess' => 'Y'
                );
                # TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
            }
            else {
                $log_txt .= "Grupo '$group_name' inexistente. Borrado.\n";
                $log_txt .= "Group '$group_name' does not exist. Deleted.\n";

                my %where = ( 'envobjid' => $env_id, 'usrgrpobjid' => $group_process_id_old );
                my $delete_row = Baseliner->model('Harvest::Harenvironmentaccess')->search(%where);
                $delete_row->delete;
            }
        }
        #loginfo( "Cambio de permisos en aplicaciones de plantillas terminado OK.", $log_txt )

        $log->info( "Change of application permissions in templates finished OK.", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        #logerr( "ERROR en cambio de permisos en plantillas.", $log_txt . "\n" . shift() );
        $log->error( "Error changing permissions in templates.", $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

sub chg_permissions_states_templates {
    my ( $self, $udpverbose ) = @_;
    my %group_id;
    my $log_txt = ();
    my $har_db  = BaselinerX::Ktecho::Harvest::DB->new;
    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );

    try {
        my %states = $har_db->db->hash( "
            SELECT s.stateobjid 
                    || '-' 
                    || ug.usrgrpobjid, 
                   e.envobjid, 
                   s.stateobjid, 
                   TRIM(environmentname), 
                   TRIM(statename), 
                   ug.usrgrpobjid, 
                   TRIM(ug.usergroupname), 
                   TRIM(ug.usergroupname) 
            FROM   harenvironment e, 
                   harstateaccess sa, 
                   harstate s, 
                   harusergroup ug 
            WHERE  e.envobjid = s.envobjid 
                   AND s.stateobjid = sa.stateobjid 
                   AND ug.usrgrpobjid = sa.usrgrpobjid 
                   AND TRIM(environmentname) LIKE '\\_%' ESCAPE '\\' 
                   AND TRIM(envisactive) = 'T' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'PUBLIC%' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'ADMINIST%' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'RPT-%' 
                   AND NOT Upper(TRIM(ug.usergroupname)) LIKE 'SCM%' 
                   AND NOT TRIM(ug.usergroupname) LIKE '%[project]%' 
            ORDER  BY 2 " );

        foreach my $key ( keys %states ) {
            my ( $env_id, $state_id, $env_name, $state_name, $group_process_id_old, $group_name,
                $group_name_old )
                = @{ $states{$key} };
            my ( $cam, $cam_uc ) = Baseliner->model('LoadApplication')->getcam_uc($env_name);
            $group_name = "[project]" . substr( $group_name, 3 );
            $log_txt
            #   .= "Actualizando grupo '$group_name_old' a '$group_name' en '$env_name:$state_name'\n";
                .= "Updating group '$group_name_old' to '$group_name' in '$env_name:$state_name'\n";
            $group_id{$group_name} =
                $har_db->get_user_group_id($group_name)
                unless $group_id{$group_name};
            my $group_process_id_new = $group_id{$group_name};

            if ($group_process_id_new) {
                #Delete
                my %where = ( 'stateobjid' => $state_id, 'usrgrpobjid' => $group_process_id_new );
                my $delete_row = Baseliner->model('Harvest::Harstateaccess')->search(%where);
                $delete_row->delete;

                #Update
                %where = ( 'stateobjid' => $state_id, 'usrgrpobjid' => $group_process_id_old );
                my %values = (
                    'usrgrpobjid'     => $group_process_id_new,
                    'updateaccess'    => 'N',
                    'updatepkgaccess' => 'Y'
                );
                my $update_row = Baseliner->model('Harvest::Harstateaccess')->search(%where);
                $update_row->update( \%values );
                #TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
            }
            else {
                #$log_txt .= "Grupo '$group_name' inexistente. Borrado.\n";
                $log_txt .= "Group '$group_name' does not exist. Deleted.\n";

                my %where = ( 'stateobjid' => $state_id, 'usrgrpobjid' => $group_process_id_old );
                my $delete_row = Baseliner->model('Harvest::Harstateaccess')->search(%where);
                $delete_row->delete;
            }
        }
        # loginfo( "Cambio de permisos en estados de plantillas terminado OK.", $log_txt )
        $log->info( "Cambio de permisos en estados de plantillas terminado OK.", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        #logerr( "ERROR en cambio de permisos en estados de plantillas.",
        $log->error( "ERROR changing template state permissions.",
            $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

sub chg_permissions_processes_templates {
    my ( $self, $udpverbose ) = @_;
    my $log_txt = ();
    my %group_id;
    my $log = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );
    my $har_db = BaselinerX::Ktecho::Harvest::DB->new;

    try {
        # Antes de empezar, borro los permisos de procesos que estén a executeaccess='N' en 
        #plantillas y projects
        $har_db->db->do( "
            DELETE FROM harstateprocessaccess sp 
            WHERE  TRIM(sp.executeaccess) = 'N' 
                   AND EXISTS (SELECT * 
                               FROM   harenvironment e, 
                                      harstate s 
                               WHERE  e.envobjid = s.envobjid 
                                      AND sp.stateobjid = s.stateobjid) " );

        # Proceso los permisos que no son [project]...
        my %processes = $har_db->db->hash( "
            SELECT p.processobjid 
                    || '-' 
                    || ug.usrgrpobjid, 
                   e.envobjid, 
                   s.stateobjid, 
                   p.processobjid, 
                   TRIM(environmentname), 
                   TRIM(statename), 
                   TRIM(processname), 
                   ug.usrgrpobjid, 
                   TRIM(ug.usergroupname), 
                   TRIM(ug.usergroupname) 
            FROM   harenvironment e, 
                   harstate s, 
                   harstateprocessaccess sp, 
                   harstateprocess p, 
                   harusergroup ug 
            WHERE  e.envobjid = s.envobjid 
                   AND s.stateobjid = sp.stateobjid 
                   AND sp.processobjid = p.processobjid 
                   AND ug.usrgrpobjid = sp.usrgrpobjid 
                   AND TRIM(environmentname) LIKE '\\_%' ESCAPE '\\' 
                   AND NOT EXISTS (SELECT 1 
                                   FROM   harusergroup ug2 
                                   WHERE  ug2.usrgrpobjid = ug.usrgrpobjid 
                                          AND ( Upper(TRIM(ug2.usergroupname)) LIKE 'RPT-%' 
                                                 OR Upper(TRIM(ug2.usergroupname)) LIKE 
                                                    'PUBLIC%' 
                                                 OR Upper(TRIM(ug2.usergroupname)) LIKE 
                                                    'ADMINIST%' 
                                                 OR Upper(TRIM(ug2.usergroupname)) LIKE 
                                                    'SCM%' 
                                                 OR TRIM(ug2.usergroupname) LIKE 
                                                    '%[project]%' )) 
                   AND TRIM(envisactive) = 'T' 
            ORDER  BY 2 " );

        foreach my $key ( keys %processes ) {
            my ($env_id,               $state_id,   $process_id,
                $env_name,             $state_name, $process_name,
                $group_process_id_old, $group_name, $group_name_old
            ) = @{ $processes{$key} };
            my ( $cam, $cam_uc ) = get_cam_uc($env_name);

            $group_name = "[project]" . substr( $group_name, 3 );
            #$log_txt .= "Actualizando grupo '$group_name_old' a '$group_name' en "
            #    . "'$env_name:$state_name:$process_name'\n";
            $log_txt .= "Updating group '$group_name_old' to '$group_name' in "
                . "'$env_name:$state_name:$process_name'\n";
            $group_id{$group_name} =
                $har_db->get_user_group_id($group_name)
                unless $group_id{$group_name};

            my $group_process_id_new = $group_id{$group_name};

            if ($group_process_id_new) {
                #Delete
                my %where = (
                    'processobjid' => $process_id,
                    'usrgrpobjid'  => $group_process_id_new
                );
                my $delete_row = Baseliner->model('Harvest::Harstateprocessaccess')->search(%where);
                $delete_row->delete;

                #Update
                %where = ( 'processobjid' => $process_id, 'usrgrpobjid' => $group_process_id_old );
                my %values = ( 'usrgrpobjid' => $group_process_id_new, 'executeaccess' => 'Y' );
                my $update_row = Baseliner->model('Harvest::Harstateprocessaccess')->search(%where);
                $update_row->update( \%values );
                #TODO or die "ERROR SQL($DBI::err): $DBI::errstr";
            }
            else {
                #$log_txt .= "Grupo '$group_name' inexistente. Borrado.\n";
                $log_txt .= "Group '$group_name' does not exist. Deleted.\n";

                my %where = (
                    'processobjid' => $process_id,
                    'usrgrpobjid'  => $group_process_id_old
                );
                my $delete_row = Baseliner->model('Harvest::Harstateprocessaccess')->search(%where);
                $delete_row->delete;
            }
        }
        #loginfo( "Cambio de permisos en procesos de plantillas terminado OK.", $log_txt )

        $log->info( "Change of template processes permissions OK.", $log_txt )
            if ( $log_txt && $udpverbose );
    }
    catch {
        #logerr( "ERROR en cambio de permisos en procesos de plantillas.",

        $log->error( "ERROR changing template processes permissions.",
            $log_txt . "\n" . shift() );
    };
    #TODO ocommit();
}

1;
