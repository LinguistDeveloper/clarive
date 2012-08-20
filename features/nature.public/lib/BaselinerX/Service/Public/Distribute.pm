package BaselinerX::Service::Public::Distribute;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.public.distribute' => {
                                         name    => 'Distribute Public Application',
                                         handler => \&index
                                        };

# $Sufijo  : normalmente, "PUBLICO"; o desde dónde empieza la estructura de PUBLICO
# $release : el nombre de paquete y raíz de directorio en el env PUBLICO
# @tipo    : las naturalezas de PUBLICO, normalmente "J2EE" y/o ".NET", que serán convertidos en carpetas
sub pubDist
{
    my ($self, $c, $config) = @_;
    my $PaseDir         = $config->{path};
    my $EnvironmentName = $config->{env_name};
    my $Entorno         = $config->{env};
    my $Sufijo          = $config->{suffix};
    my $release         = $config->{release};
    my @tipos           = @{$config->{tipos}};
    my $job             = $c->stash->{job} || _throw "No se ha encontrado información del Job";
    my $log             = $job->logger;
    my $Pase            = $job->job_data->{name} || _throw "no he podido encontrar el pase";

    my ($cam, $CAM) = get_cam_uc($EnvironmentName);

    my $rootdir        = "$PaseDir/$CAM/$Sufijo";
    my $apl_publico    = _bde_conf 'apl_publico';
    my $state_publico  = _bde_conf 'state_publico';
    my $staunixdir     = _bde_conf 'staunixdir';
    my $staunixuser    = _bde_conf 'staunixuser';
    my $gnutar         = _bde_conf 'gnutar';
    my $staunix        = _bde_conf 'staunix';
    my $staunixport    = _bde_conf 'staunixport';
    my $tardestinosaix = _bde_conf 'tardestinosaix';
    my $har_db         = BaselinerX::CA::Harvest::DB->new;

    # creo el paquete en PUBLICO
    # createPackage($apl_publico, $state_publico, "$release-$Entorno");
    $c->launch('service.create_package', data => {env => $apl_publico, sta => $state_publico, pkg => "$release-$Entorno"});

    foreach my $tipo (@tipos)
    {
        $log->info("Actualizando aplicación PUBLICO con release $CAM:$release ($tipo). Espere...");
        ##ci a PUBLICO
        my $ViewPath = "/$apl_publico/$CAM/$tipo/$Entorno";
        my $ciDir    = "$rootdir/checkin";
        my @RET      = `mkdir -p "$ciDir" 2>/dev/null; mv "$rootdir/$tipo" "$ciDir/$release" `;
        $log->debug(qq{Renombrada carpeta "$rootdir/$tipo" a "$ciDir/$release" }, join('', @RET));
        $self->checkin_publico(
                               $log,
                               path     => $ciDir,
                               entorno  => $Entorno,
                               viewpath => $ViewPath,
                               project  => $apl_publico,
                               state    => $state_publico,
                               release  => $release,
                               desc     => "Creado por el pase $Pase"
                              );

        ##creo snapshot

        ##copia a staging
        if ($Entorno ne "PROD")
        {
            $log->info("Entorno '$Entorno': no se distribuirá la release pública a Staging.");
        }
        else
        {
            my $sta_unix = $staunixdir;
            my $sta_user = $staunixuser;
            my $pubname  = _bde_conf 'pubname';
            @RET = `cd '$ciDir' ; $gnutar -cvf '$release'.tar *`;
            my $RC = $?;
            $log->debug("TAR del directorio de la aplicación pública RC=$RC.", join('', @RET));
            foreach my $sta_maq (split(/,/, $staunix))
            {
                my $harax = _balix(host => $sta_maq, port => $staunixport);
                $log->info("Enviando el fichero de release pública a Staging-$tipo (servidor <b>$sta_maq</b>). Espere...");
                my ($RC, $RET) = $harax->execute("rm -f '$sta_unix/$pubname/${release}.tar'");
                ($RC, $RET) = $harax->sendFile("$ciDir/$release.tar", "$sta_unix/$pubname/${release}.tar");
                if ($RC ne 0)
                {
                    _throw "ERROR: no he podido enviar el fichero de release a staging '$sta_unix/$pubname/${release}.tar'. Verifique el espacio en disco. $RET";
                }
                else
                {
                    $log->info("Envío del fichero de release pública a Staging-$tipo finalizado RC=$RC", $RET);
                }
                ($RC, $RET) = $harax->execute("chown $sta_user '$sta_unix/$pubname/${release}.tar'");

                $log->info("Decomprimiendo el fichero de release. Espere...");

                ## GESTIONAMOS LOS LA VARIABLE DEL TAR A UTILIZAR .
                my $tarExecutable;
                ($RC, $RET) = $harax->executeas($sta_user, qq{ ls '$tardestinosaix' });
                if ($RC ne 0)
                {    # No tenemos tar especial en esta máquina, así que nos llevamos uno
                    $log->debug("Esta máquina no dispone de tar especial de IBM. Usaremos el tar de la máquina.", $RET);
                    $tarExecutable = "tar";
                }
                else
                {
                    $log->debug("Esta máquina dispone de tar especial de IBM. Lo usamos.", $RET);
                    $tarExecutable = $tardestinosaix;
                }
                ($RC, $RET) = $harax->executeas($sta_user, "cd '$sta_unix/$pubname'; rm -Rf './${release}' ; $tarExecutable xvf '${release}'.tar");
                if ($RC ne 0)
                {
                    _throw "ERROR: no he podido descomprimir el fichero en staging '$sta_unix/$pubname/${release}.tar'. Verifique el espacio en disco: $RET";
                }
                else
                {
                    $log->info("TAR finalizado RC=$RC", $RET);
                }
                ($RC, $RET) = $harax->executeas($sta_user, "rm -f '$sta_unix/$pubname/${release}.tar'");
                $harax->end();
            }
        }
    }
}

sub checkin_publico
{
    my $self = shift;
    my $log  = shift;
    my %p    = @_;
    my ($filepath, $Viewpath, $EnvironmentName, $Statename, $Release, $Desc, $Entorno) = ($p{path}, $p{viewpath}, $p{project}, $p{state}, $p{release}, $p{desc}, $p{entorno});
    my $har_db = BaselinerX::CA::Harvest::DB->new;
    ## package - si no existe, lo creará
    my $PackageName   = "$Release-$Entorno";
    my $apl_publico   = _bde_conf 'apl_publico';
    my $state_publico = _bde_conf 'state_publico';
    my $loghome       = _bde_conf 'loghome';
    my $broker        = _har_conf 'broker';
    my $haruser       = _har_conf 'user';
    my $harpwd        = _har_conf 'harpwd';

    # createPackage($apl_publico, $state_publico, $PackageName);
    Baseliner->launch('service.create_package', data => {env => $apl_publico, sta => $state_publico, pkg => $PackageName});

    ## verifica si el paquete está en el estado que tiene que estar
    my ($pkgenv, $pkgstate) = $har_db->get_package_info($PackageName);
    if ($pkgenv eq $apl_publico)
    {
        if ($pkgstate eq 'Obsoleto')
        {
            $log->warn("Paquete '$PackageName' está Obsoleto. Procedo a devolverlo al estado $state_publico.");
            my ($rc, $ret) = promote_packages(tipo => 'demote', project => $apl_publico, state => 'Obsoleto', packages => [$PackageName]);
            if ($rc ne 0)
            {
                $log->err("Error al intentar devolver el paquete '$PackageName' de 'Obsoleto' a '$state_publico' en el proyecto '$apl_publico'", $ret);
                _throw "Error durante el checkin de elementos públicos.";
            }
            else
            {
                $log->debug("Promoción de paquetes OK en $apl_publico:Obsoleto (RC=$rc)", $ret);
            }
            ($pkgenv, $pkgstate) = $har_db->get_package_info($PackageName);    ## vuelvo a verificar, por si acaso
        }
        elsif ($pkgstate eq 'Borrado')
        {                                                                      ##miro tambien por si está en Borrado , tambien hay que devolverlo a público
            $log->warn("Paquete '$PackageName' está Borrado. Procedo a devolverlo al estado Obsoleto}.");
            my ($rc, $ret) = promote_packages(tipo => 'demote', project => $apl_publico, state => 'Borrado', packages => [$PackageName]);
            if ($rc ne 0)
            {
                $log->err("Error al intentar devolver el paquete '$PackageName' de 'Borrado' a '$state_publico' en el proyecto '$apl_publico'", $ret);
                _throw "Error durante el checkin de elementos públicos.";
            }
            else
            {
                $log->debug("Promoción de paquetes OK en $apl_publico:Cerrado a Obsoleto (RC=$rc)", $ret);
            }

            ($pkgenv, $pkgstate) = $har_db->get_package_info($PackageName);    ## vuelvo a verificar, para ver si está en Obsoleto

            if ($pkgstate eq 'Obsoleto')
            {
                $log->warn("Paquete '$PackageName' está Obsoleto. Procedo a devolverlo al estado $state_publico.");
                my ($rc, $ret) = promote_packages(tipo => 'demote', project => $apl_publico, state => 'Obsoleto', packages => [$PackageName]);
                if ($rc ne 0)
                {
                    $log->err("Error al intentar devolver el paquete '$PackageName' de 'Obsoleto' a '$state_publico' en el proyecto '$apl_publico'", $ret);
                    _throw "Error durante el checkin de elementos públicos.";
                }
                else
                {
                    $log->debug("Promoción de paquetes OK en $apl_publico:Obsoleto a Público (RC=$rc)", $ret);
                }
            }
        }
        ($pkgenv, $pkgstate) = $har_db->get_package_info($PackageName);    ## vuelvo a verificar, por si acaso
        if ($pkgstate ne $state_publico)
        {
            $log->err("Paquete '$PackageName' no encontrado en el estado '$state_publico' de la aplicación '$apl_publico'" . ($pkgstate ? " sino en '$pkgstate' " : ""));
            _throw "Error durante el checkin de elementos públicos.";
        }
    }
    else
    {
        $log->err("Paquete '$PackageName' no encontrado en la aplicación '$apl_publico'");
        _throw "Error durante el checkin de elementos públicos.";
    }
    ## checkin
    my $logfile = "$loghome/hco$$-" . ahora() . ".log";
    my ($rc, $ret, @RET);
    ## hay que borrar las versiones anteriores antes de hacer checkin en TEST
    if ($p{entorno} =~ /TEST/i)
    {
        my $vp      = "$Viewpath/$Release";                       ## este viewpath es distinto, porque la variable viewpath no incluye la release
        my $logfile = "$loghome/hdv-pub$$-" . ahora() . ".log";
        $log->debug("Entorno TEST: se borrarán las versiones anteriores en el path '$vp'. Espere...");
        my ($ret, $rc);
        ## borro el view path recursivo - pero hdv sólo borra las últimas versiones, por lo que hay que borrar varias veces
        do
        {
            my @RET = `hdv -o "$logfile" -b "$broker" $haruser $harpwd -en "$EnvironmentName" -st "$Statename" -vp '$vp' -s "*"`;
            $rc = $?;
            $ret .= $har_db->captura_log($logfile, @RET);
        } while ($rc eq 0);                                       ## hdv da un 3 cuando ya no hay nada en el view path
        $log->debug("Resultado del borrado de versiones anteriores de la release en '$vp'", $ret);
    }
    $log->debug("Inicio checkin de ficheros Publicos...", qq{hco -b "$broker" $haruser -en "$EnvironmentName" -st "$Statename" -p "$PackageName" -vp "$Viewpath" -ro -o "$logfile" -cp "$filepath" -s "*" \n} . qq{hci -b "$broker" $haruser -en "$EnvironmentName" -st "$Statename" -p "$PackageName" -vp "$Viewpath" -op as -ur -nd -de "$Desc" -o "$logfile" -cp "$filepath" -s "*"});

    @RET = `hcrtpath -b $broker $haruser  $harpwd -en "$EnvironmentName" -st "$Statename" -rp "$Viewpath" -o "$logfile" `;

    $ret = $har_db->captura_log($logfile, @RET);

    $log->debug("Creación del viewpath '$Viewpath' en $EnvironmentName->$Statename (RC=$?)", $ret);

    @RET = `hco -b "$broker" $haruser $harpwd -en "$EnvironmentName" -st "$Statename" -p "$PackageName" -vp "$Viewpath" -ro -o "$logfile" -cp "$filepath" -s "*"`;

    $ret = $har_db->captura_log($logfile, @RET);

    $log->debug("Checkout de reservas para hacer el checkin de PUBLICO (RC=$?).", $ret);

    @RET = `hci -b "$broker" $haruser $harpwd -en "$EnvironmentName" -st "$Statename" -p "$PackageName" -vp "$Viewpath" -op pc -ur -nd -de "$Desc" -o "$logfile" -cp "$filepath" -s "*"`;

    $rc = $?;

    if ($rc eq 0)
    {
        $log->info("Checkin a '$EnvironmentName' de '$filepath' a '$Viewpath' ok.", $ret . $har_db->captura_log($logfile, @RET));
    }
    else
    {
        $log->err("Checkin a '$EnvironmentName' de '$filepath' a '$Viewpath' ha fallado.", $har_db->captura_log($logfile, @RET));
        _throw "Error durante el checkin de elementos públicos.";
    }

    #soltar ficheros con reserva
    $har_db->delete_R_versions($EnvironmentName, $PackageName);
    $log->debug("Release de las reservas realizadas en el paquete.");
}

1;
