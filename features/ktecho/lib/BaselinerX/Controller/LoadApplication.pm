package BaselinerX::Controller::LoadApplication;
use Baseliner::Plug;
use Baseliner::Utils;
use Catalyst::Log;
use BaselinerX::Comm::Balix;
use 5.010;
use strict;
use warnings;
#use threads;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

sub index : Local  {
    my ( $self, $c ) = @_;
    my $log    = Catalyst::Log->new( 'info', 'debug', 'warn', 'error' );
    my $inf_db = BaselinerX::Ktecho::INF::DB->new;

    undef my %where;
    undef my %args;

    #threads->self->detach();
    $c->model('LoadApplication')->process_name('aplicaciones');

    $log->info("-------------------------");
    $log->info("Starting application load");
    $log->info("-------------------------");

    #Get env variables
    my $config_harvest = Baseliner->model('ConfigStore')->get('config.harvest');
    my $config_bde     = Baseliner->model('ConfigStore')->get('config.bde');

    my $freq             = $config_harvest->{alta_frecuencia};
    my $broker           = $config_harvest->{broker};
    my $harvest_user     = $config_harvest->{user};
    my $harvest_password = $config_harvest->{password};
    my $inf_data         = $config_bde->{inf_data};
    my $loghome          = $config_bde->{loghome};
    my $templates        = $config_bde->{templates};
    my $udpverbose       = $config_bde->{udpverbose};

    while (1) {
        #oconn();
        #TODO logstart("HARDIST", "INT","1");

        print BaselinerX::Comm::Balix::ahora()." - AltaAplicación: Comprobación de Aplicaciones a crear... \n";
        $log->debug("LoadApplication: Checking applications to create...");

        # Query de las aplicaciones en inf_data con crear=Si y que no estén en
        # Harvest
        my @envs = $c->model('LoadApplication')->get_query_applications($inf_data);

        foreach my $cam ( @envs ) {
            my $is_public_string = $c->model('LoadApplication')->_scm_apl_many(
                {   column_name => 'SCM_APL_PUBLICA',
                    cam         => $cam,
                    inf_data    => $inf_data
                }
            );
            my $create = $c->model('LoadApplication')->_scm_apl_many(
                {   column_name => 'SCM_APL_CREAR',
                    cam         => $cam,
                    inf_data    => $inf_data
                }
            );
            my $sistemas = $c->model('LoadApplication')->_scm_apl_many(
                {   column_name => 'SCM_APL_SISTEMAS',
                    cam         => $cam,
                    inf_data    => $inf_data
                }
            );

            my $is_public        = $c->model('LoadApplication')->set_is_public($is_public_string);
            my $is_sistemas      = $c->model('LoadApplication')->set_is_sistemas($sistemas);

            if ( $create eq "Si" ) {

                # TODO logprintmode 1;  ##para que  escriba en log y en stdout
                # simultaneamente

                my $already_exists_ref =
                    $c->model('LoadApplication')->get_query_already_exists( $cam, $is_public );
                my @already_exists = @{$already_exists_ref};

                if (   ( $is_public && @already_exists > 0 )
                    or ( !$is_public && @already_exists > 1 ) )
                {

                    print ahora()
                        . "AltaAplicación: Aplicación ya existe en Harvest: $cam "
                        . "(Pública=$is_public_string):\n-->"
                        . join( "\n-->", @already_exists ) . "\n";

                    #loginfo "AltaAplicación: Aplicación ya existe en Harvest: $cam " .
                    #"(Pública=$is_public_string):\n-->".join("\n-->",@already_exists)."\n";

                    $log->info(
                        "LoadApplication: Application already exists in Harvest: $cam
                        (Public=$is_public_string):\n-->" . join( "\n-->", @already_exists ) . "\n"
                    );

                    %args = (
                        'cam'      => $cam,
                        'status'   => "Creado",
                        'inf_data' => $inf_data
                    );

                    $c->model('LoadApplication')->$inf_db->set_inf_scm_status( \%args );
                }
                else {
                    # Nota:  Esto es muuuuy cutre.  Si tengo tiempo ya pensaré
                    # alguna forma de dejarlo a mitad de código.
                    try {
                        #loginfo "AltaAplicación: Inicio: $cam (Pública=$is_public_string)";
                        $log->info("LoadApplication: Start: $cam (Public=$is_public_string)");

                        if ($is_public) {
                            # PUBLICA

                            %args = (
                                'cam'                  => $cam,
                                'repository_sufix'     => q//,
                                'repository_directory' => "publica",
                                'loghome'              => $loghome,
                                'broker'               => $broker,
                                'harvest_user'         => $harvest_user,
                                'harvest_password'     => $harvest_password,
                                'templates'            => $templates
                            );

                            $c->model('LoadApplication')->create_repository( \%args );

                            %args = (
                                'cam'              => $cam,
                                'env_sufix'        => q//,
                                'env_template'     => "_PUBLICO",
                                'loghome'          => $loghome,
                                'broker'           => $broker,
                                'harvest_user'     => $harvest_user,
                                'harvest_password' => $harvest_password
                            );

                            if ( $c->model('LoadApplication')->create_application( \%args ) == 0 ) {
                                %args = (
                                    'cam'              => $cam,
                                    'loghome'          => $loghome,
                                    'broker'           => $broker,
                                    'harvest_user'     => $harvest_user,
                                    'harvest_password' => $harvest_password
                                );

                                $c->model('LoadApplication')->associate_apl_repository( \%args );
                            }
                        }
                        elsif ($is_sistemas) {
                            ## SISTEMAS

                            %args = (
                                'cam'                  => $cam,
                                'repository_sufix'     => q//,
                                'repository_directory' => "sistemas",
                                'loghome'              => $loghome,
                                'broker'               => $broker,
                                'harvest_user'         => $harvest_user,
                                'harvest_password'     => $harvest_password,
                                'templates'            => $templates
                            );

                            $c->model('LoadApplication')->create_repository( \%args );

                            %args = (
                                'cam'              => $cam,
                                'env_sufix'        => q//,
                                'env_template'     => "_BDE_SIS",
                                'loghome'          => $loghome,
                                'broker'           => $broker,
                                'harvest_user'     => $harvest_user,
                                'harvest_password' => $harvest_password
                            );

                            if ( $c->model('LoadApplication')->create_application( \%args ) == 0 ) {
                                %args = (
                                    'cam'              => $cam,
                                    'loghome'          => $loghome,
                                    'broker'           => $broker,
                                    'harvest_user'     => $harvest_user,
                                    'harvest_password' => $harvest_password
                                );

                                $c->model('LoadApplication') ->associate_apl_repository( $cam, $cam );
                            }
                        }
                        else {
                            ## NORMAL
                            %args = (
                                'cam'                  => $cam,
                                'repository_sufix'     => q//,
                                'repository_directory' => "normal",
                                'loghome'              => $loghome,
                                'broker'               => $broker,
                                'harvest_user'         => $harvest_user,
                                'harvest_password'     => $harvest_password,
                                'templates'            => $templates
                            );

                            $c->model('LoadApplication')->create_repository( \%args );

                            %args = (
                                'cam'              => $cam,
                                'env_sufix'        => q//,
                                'env_template'     => "_BDE",
                                'loghome'          => $loghome,
                                'broker'           => $broker,
                                'harvest_user'     => $harvest_user,
                                'harvest_password' => $harvest_password
                            );

                            try {
                                if ( $c->model('LoadApplication')->create_application( \%args ) == 0 ) {
                                    %args = (
                                        'cam'              => $cam,
                                        'loghome'          => $loghome,
                                        'broker'           => $broker,
                                        'harvest_user'     => $harvest_user,
                                        'harvest_password' => $harvest_password
                                    );

                                    $c->model('LoadApplication')
                                        ->associate_apl_repository( $cam, $cam );
                                }
                            }
                            catch {
                                #logerr "AltaAplicación $cam: error: " . shift();
                                $log->debug( "LoadApplication: $cam: error: " . shift() );
                            }
                        }

                        #loginfo "AltaAplicación: Fin OK: $cam (Pública=$is_public_string)";
                        $log->info(
                            "LoadApplication: Finish OK: $cam (Public=$is_public_string)");

                        %args = (
                            'cam'      => $cam,
                            'status'   => "Creado",
                            'inf_data' => $inf_data
                        );

                        $c->model('LoadApplication')->$inf_db->set_inf_scm_status( \%args );

                        #ocommit();
                    }
                    catch {
                        my $exception = shift();

                        #logerr "AltaAplicación $cam: Fin con Error: $ex";
                        $log->info("LoadApplication: $cam: Finished with Error: $exception");
                    };
                }
            }; 

            ## cambios de [project] a cam
            $c->model('LoadApplication')->chg_permissions_application($udpverbose);
            $c->model('LoadApplication')->chg_permissions_states($udpverbose);
            $c->model('LoadApplication')->chg_permissions_states($udpverbose);
            $c->model('LoadApplication')->chg_permissions_processes($udpverbose);
            $c->model('LoadApplication')->chg_default_package($udpverbose);

            ## cambios de cam a [project]
            $c->model('LoadApplication')->chg_permissions_application_templates($udpverbose);
            $c->model('LoadApplication')->chg_permissions_states_templates($udpverbose);
            $c->model('LoadApplication')->chg_permissions_processes_templates($udpverbose);

            print BaselinerX::Comm::Balix::ahora()
                . " - $cam - AltaAplicación: proceso concluído. Nuevo intento en $freq segundos.\n";

            $log->debug("LoadApplication: Process concluded. New try in $freq seconds.");

            #oclose();
            sleep $freq;

            print BaselinerX::Comm::Balix::ahora()." - AltaAplicación: Nuevo intento. \n";
        } # --- end foreach
    } # --- end while

    return;
}

1;
