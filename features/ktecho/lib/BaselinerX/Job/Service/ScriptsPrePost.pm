package BaselinerX::Job::Service::ScriptsPrePost;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Comm::Balix;
use Try::Tiny;
use 5.010;
with 'Baseliner::Role::Service';

register 'service.script.j2ee.pre' => {
    name   => 'J2EE Pre',
    config => 'config.script.j2ee.pre',
    handler => \&index
};

register 'config.script.j2ee.pre' => {
    name     => 'Configuración scripts \'PRE\' para J2EE',
    metadata => [
        { id => 'sufijo', name => 'Sufijo',     default => 'PRE'  },
        { id => 'nature', name => 'Naturaleza', default => 'J2EE' }
    ]
};

register 'service.script.j2ee.post' => {
    name   => 'J2EE Post',
    config => 'config.script.j2ee.post',
    handler => \&index
};

register 'config.script.j2ee.post' => {
    name     => 'Configuración scripts \'POST\' para J2EE',
    metadata => [
        { id => 'sufijo', name => 'Sufijo',     default => 'POST' },
        { id => 'nature', name => 'Naturaleza', default => 'J2EE' }
    ]
};

#sub daemon {
#    my ( $self, $c, $config ) = @_;
#
#    my $frequency = $config->{frequency};
#    _log "Starting approval daemon with frequency ${frequency}s";
#    for ( 1 .. 200 ) {
#        $self->check_approvals( $c, $config );
#
#        # enforce pending
#        Baseliner->model('Request')->enforce_pending;
#
#        # make sure all requests have a project relationship
#        sleep $frequency;
#    }
#    _log 'Approval deamon stopping.';
#}

sub index {
    my ( $self, $c, $config ) = @_;

    my $job      = $c->stash->{job};
    my $log      = $job->{log};
    my $prepost  = $config->{sufijo};
    my $sufijo   = $config->{nature};
    my $env_name = $job->job_stash->{project} || 'SCT';     # XXX hard-coded XXX
    my $env      = $job->job_stash->{entorno} || 'TEST';    # XXX hard-coded XXX

    my $inf_db = BaselinerX::Ktecho::Inf::DB->new;

    my $config_bde      = Baseliner->model('ConfigStore')->get('config.bde');
    my $STAWINPORT      = $config_bde->{stawinport};
    my $PREPOST_TIMEOUT = $config_bde->{prepost_timeout} || 3600;

    my ( $cam, $cam_uc ) = get_cam_uc($env_name);

    my %SCRIPTS = $c->model('ScriptsPrePost')->get_script_list(
        {   cam     => $cam_uc,
            env     => $env,
            sufijo  => $sufijo,
            prepost => $prepost
        }
    );

    if ( !%SCRIPTS ) {
        $log->debug( "No hay scripts $prepost para esta aplicación ($cam_uc) definidos en el "
                . "formulario de paquete." );
        return;
    }
    my $cnt = 0;

    foreach my $key ( sort keys %SCRIPTS ) {
        $cnt++;
        my ( $exec, $maq, $usu, $block, $os, $errcode ) = @{ $SCRIPTS{$key} };
        if ( $maq eq q{} ) {
            if ( $block =~ m/^s/ix ) {
                $log->error("nombre de servidor '$maq' inválido (bloqueo=$block)");
                warn "Error durante la ejecución de scripts $prepost.";
            }
            else {
                $log->warn( "nombre de servidor '$maq' inválido (bloqueo=$block - script "
                        . "descartado)" );
                next;
            }
        }
        if ( ( $usu !~ m/$cam_uc/ix ) && $os ne "WIN" ) {
            if ( $block =~ m/^s/ix ) {
                $log->error( "Script $prepost $cnt: Nombre de usuario '$usu' no contiene el cam "
                        . "$cam_uc. Posible brecha de seguridad (bloqueo=$block)" );
                warn "Error durante la ejecución de scripts $prepost.";
            }
            else {
                $log->warn( "Script $prepost $cnt: Nombre de usuario '$usu' no contiene el cam "
                        . "$cam_uc. Posible brecha de seguridad (bloqueo=$block)" );
                next;
            }
        }
        my ($puerto) = ();
        if ( $os eq "WIN" ) {
            $puerto = $STAWINPORT;
        }
        else {
            my @array = ('HARAX_PORT');
            ($puerto) = $inf_db->get_unix_server_info( $maq, \@array );
        }
        if ( $puerto eq q{} ) {
            if ( $block =~ m/^s/ix ) {
                $log->error( "nombre de servidor '$maq' inválido o puerto no encontrado en la lista"
                        . "de servidores de infraestructura (bloqueo=$block)" );
                warn "Error durante la ejecución de scripts $prepost.";
            }
            else {
                $log->warn( "nombre de servidor '$maq' inválido o puerto no encontrado en la lista"
                        . "de servidores de infraestructura (bloqueo=$block)" );
                next;
            }
        }
        my $resolver = BaselinerX::Ktecho::Inf::Resolver->new(
            {   entorno => $env,
                cam     => $cam_uc,
                sub_apl => q{}
            }
        );

        $exec =~ s/\$\{pase\}/consiste en lanzar aros/x;
        $exec =~ s/\$\{naturaleza\}/$sufijo/x;
        $exec =~ s/\$\{orden\}/$cnt/x;
        $exec =~ s/\$\{block\}/$block/x;
        $exec = $resolver->get_solved_value($exec);
        $exec =~ s/consiste en lanzar aros/\$\{pase\}/x;
        $log->debug("Ignorando resolución \${pase}...");
        $log->info("Script $prepost $cnt: inicio ejecución $maq:$exec...");

        my $port = 49164;
        $os = ( $os eq 'WIN' ? 'win' : q{} );
        my $key =
            'SmsuSVVqa0lVNzY1NHJKaC4rODc4N2Rmai4uMTklZGtqc2ExMTo5OCwsMUBqaHJ1KGhqaEh0MmpFcWF4eng=';

        my $balix = BaselinerX::Comm::Balix->new(
            host    => $maq,
            port    => $port,
            key     => $key,
            os      => $os,
            timeout => 10
        ) or warn "Error al abrir la conexión con agente en $maq:$puerto";

    #        my $harax = Harax->open( $maq, $puerto, ( $os eq "WIN" ? "win" : q{} ) )
    #            or { throw distException "Error al abrir la conexión con agente en $maq:$puerto" };

        local $SIG{ALRM} = sub { die "Timeout0\n" };
        try {
            my ( $RC, $RET ) = ();

            print "Tiempo máximo de ejecución de script: $PREPOST_TIMEOUT segundos. \n";
            $log->debug("Tiempo máximo de ejecución de script: $PREPOST_TIMEOUT segundos.");

 #            eval {
 #                $SIG{ALRM} = sub {
 #                    die "Timeout. Se ha sobrapasado el tiempo fijado ($PREPOST_TIMEOUT) para la  "
 #                        . "ejecución del script. Si necesita aumentar este tiempo pongase en  "
 #                        . "contacto con Arquitecturas.\n";
 #                }; }

            local $SIG{ALRM} = sub { die "Timeout1\n" };

            eval {
                local $SIG{ALRM} = sub { die "Timeout2\n" };
                alarm $PREPOST_TIMEOUT;

                if ( $os eq "WIN" ) {
                    ( $RC, $RET ) = $balix->execute($exec);
                    warn"ejecutando en Windows";
                    warn $RC;
                }
                else {
                    ( $RC, $RET ) = $balix->executeas( $usu, $exec );
                    $RC = $RC >> 8;
                    warn "Ejecutando en Linux";
                    warn $RC;
                }

                warn $RET;

                alarm 0;
            };

            # Este es el catch
            if ($@) {
                if ( $@ =~ m/Timeout/i ) {
                    print "Se ha producido un error durante la ejecución del script $maq:$exec "
                        . "(RC=$RC, Err>=$errcode): $@\n";
                    $log->error(
                        "Se ha producido un error durante la ejecución del script "
                            . "$maq:$exec (RC=$RC, Err>=$errcode): $@ ",
                        $RET
                    );
                    die;
                }
                else {
                    print "2 Se ha producido un error durante la ejecución del script $maq:$exec "
                        . "(RC=$RC, Err>=$errcode): $@\n";
                    $log->error(
                        "2 Se ha producido un error durante la ejecución del script "
                            . "$maq:$exec (RC=$RC, Err>=$errcode): $@ ",
                        $RET
                    );
                    die;
                }
            }
            else {
                alarm 0;
                print "NO Se ha producido un error durante la ejecución del script $maq:$exec "
                    . "(RC=$RC, Err>=$errcode): $@\n";
                $log->debug( "NO Se ha producido un error durante la ejecución del script "
                        . "$maq:$exec (RC=$RC, Err>=$errcode): $@ ", $RET
                );
            }

            if ( $RC >= $errcode ) {
                if ( $block =~ /^s/i ) {
                    $log->error(
                        "Script $prepost $cnt (bloqueo=$block): Error durante la ejecución"
                            . "de $maq:$exec (RC=$RC, Err>=$errcode) ",
                        $RET
                    );
                    warn "Error durante la ejecución de scripts $prepost.";
                }
                else {
                    $log->warn(
                        "Script $prepost $cnt (bloqueo=$block): Error durante la ejecución"
                            . "de $maq:$exec (RC=$RC, Err>=$errcode)",
                        $RET
                    );
                }
            }
            else {
                if ( $errcode > 1 ) {    ## warning, si es el caso: 1 <= $RC < $errcode
                    $log->warn(
                        "Script $prepost $cnt $maq:$exec: terminado con warning (RC=$RC, "
                            . "Warn<$errcode).",
                        $RET
                    );
                }
                else {
                    $log->info( "Script $prepost $cnt $maq:$exec: OK.", $RET );
                }
            }
        }
        catch {
            alarm 0;
            $balix->end();
            warn "Error durante la ejecución de los scripts: " . shift();
        };
    }

    return;
}

1;
