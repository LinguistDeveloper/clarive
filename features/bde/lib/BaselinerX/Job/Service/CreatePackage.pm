package BaselinerX::Job::Service::CreatePackage;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use utf8;

with 'Baseliner::Role::Service';

register 'service.create_package' => {
                                      name    => 'Create Package',
                                      handler => \&index
                                     };

sub index
{
    my ($self, $c, $config) = @_;
    my $job     = $c->stash->{job};
    my $log     = $job->logger;
    my $env     = $config->{env};
    my $sta     = $config->{sta};
    my $pkg     = $config->{pkg};
    my $har_db  = BaselinerX::CA::Harvest::DB->new;
    my $loghome = _bde_conf 'loghome';
    my $broker  = _har_conf 'broker';
    my $haruser = _har_conf 'user';
    my $harpwd  = _har_conf 'harpwd';
    my $logfile = "$loghome/hpphdp$$-" . ahora . ".log";
    $log->debug(qq{Creando paquete de release en harvest}, qq{hcp -b $broker $haruser -en "$env" -st "$sta" -o "$logfile" "$pkg"});
    my @RET    = `hcp -b $broker $haruser $ENV{HARPWD} -en "$env" -st "$sta" -o "$logfile" '$pkg'`;
    my $RC     = $?;
    my $logtxt = $har_db->captura_log($logfile, @RET);

    if ($RC eq 0)    # OK
    {
      # $log->info("Paquete '$pkg' creado en el estado '$sta' de la aplicación '$apl'.", $logtxt);
        $log->info("Paquete '$pkg' creado en el estado '$sta'.", $logtxt);
        return 0;
    }
    else             # KO
    {
        if ($logtxt =~ /E03020005/)    # El paquete ya existía.
        {
            $log->warn("Aviso: el paquete '$pkg' ya existe en $env:$sta. Se actualizará su contenido.");
            return 1;
        }
        else
        {
          # $log->err("Error al crear el paquete '$pkg' en el estado '$sta' de la aplicación '$apl'.", $logtxt);
            $log->err("Error al crear el paquete '$pkg' en el estado '$sta'.", $logtxt);
            _throw "no se ha podido crear el paquete de la release en la aplicación pública.";
            return 2;
        }
    }
}

1;
