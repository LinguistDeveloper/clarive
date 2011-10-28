package BaselinerX::Controller::CargaFTP;
use Baseliner::Plug;
use Baseliner::Utils;
use v5.10;
use Catalyst::Log;
use Data::Dumper;
BEGIN { extends 'Catalyst::Controller' }

#register 'menu.admin.cargaldif' => {
#    label => 'Carga usuarios',
#    url   => 'cargaftp/iniciar',
#    title => 'Carga usuarios',
#    icon  => 'static/images/scm/icons/approve_16.png'
#};

sub iniciar : Local {
    my ( $self, $c ) = @_;

=begin  BlockComment  # BDE Variables

    my $config_whoami    = $c->model('ConfigStore')->get('config.bde.whoami');
    my $config_perl_temp = $c->model('ConfigStore')->get('config.bde.perltemp');
    my $config_broker    = $c->model('ConfigStore')->get('config.bde.broker');
    my $config_udp_home  = $c->model('ConfigStore')->get('config.bde.udp_home');
    my $config_ldif      = $c->model('ConfigStore')->get('config.bde.ldif');
    my $config_harvest   = $c->model('ConfigStore')->get('config.bde.harvest');

    my $whoami    = $config_whoami->{whoami};
    my $perl_temp = $config_perl_temp->{perl_temp};
    my $broker    = $config_broker->{broker};
    my $udp_home  = $config_udp_home->{udp_home};
    my ( $ftp_server, $ldif_remote_directory, $ldif_home_directory ) =
       $config_ldif->{qw/ ldifmaq ldifremdir ldifhome /};
    my ( $harvest_user, $harvest_password ) = $config_harvest->{qw/ user password /};

=end    BlockComment  # BDE Variables

=cut

    #XXX
    my $whoami                = 'q73898x';
    my $perl_temp             = '/home/aps/scm/servidor/tmp';
    my $broker                = 'alfsv053';
    my $udp_home              = '/home/aps/scm/servidor/udp';
    my $ftp_server            = 'prue';
    my $ldif_remote_directory = '/tmp/eric/ficheros';
    my $ldif_home_directory   = '/tmp/eric/ldif';
    my $harvest_user          = '-eh /home/aps/scm/servidor/harvest/hserverauth_new.dfo';
    my $harvest_password      = '0211rucu';

    #XXX Por si acaso...
    $harvest_user     = undef;
    $harvest_password = undef;

    my $fusr = $c->model('CargaFTP')->set_fusr($perl_temp);

    $c->log->debug("set_fusr OK");

    #TODO $c->model('CargaFTP')->semUpMail('Ldiff');

    my $all_users_result = $c->model('CargaFTP')->all_users();
    my %users_beginning  = %{$all_users_result};

    $c->log->debug("all_users OK");

    my $secret = $c->model('CargaFTP')->set_ticket( $ftp_server, $whoami );
    $c->log->debug("set_ticket OK");

    my %est_con_ftp_args = (
        'secret'                => $secret,
        'ftp_server'            => $ftp_server,
        'whoami'                => $whoami,
        'ldif_remote_directory' => $ldif_remote_directory,
        'ldif_home_directory'   => $ldif_home_directory
    );

    #$c->model('CargaFTP')->establecer_conexion_ftp( \%est_con_ftp_args );

    # FICHEROS DESCARGADOS

    # Nota: Tal vez haga falta pasarlo a hash. El original era %GruposInfRpt
    my $set_grupos_inf_rpt_result = $c->model('CargaFTP')->set_grupos_inf_rpt();
    my %users                     = %{$set_grupos_inf_rpt_result};

    $c->log->debug("set_grupos_inf_rpt OK");

    my $con_fic_dir_result =
        $c->model('CargaFTP')->concatenar_ficheros_directorio($ldif_home_directory);

    my $group_name   = $con_fic_dir_result->{group_name};
    my $user         = $con_fic_dir_result->{user};
    my %groups       = %{ $con_fic_dir_result->{groups} };
    my %user_group   = %{ $con_fic_dir_result->{user_group} };
    my %user_group_2 = %{ $con_fic_dir_result->{user_group_2} };

    $c->log->debug("concatenar_ficheros_directorio OK");

    $c->model('CargaFTP')->create_groups( $group_name, \%groups );

    $c->log->debug("create_groups OK");

    my $create_users_args = {
        'fusr'         => $fusr,
        'user'         => $user,
        'user_group'   => \%user_group,
        'user_group_2' => \%user_group_2
    };

    $c->model('CargaFTP')->create_users($create_users_args);

    $c->log->debug("create_users OK");

    my $delete_users_args = {
        'user_group'            => \%user_group,
        'broker'                => $broker,
        'harvest_user'          => $harvest_user,
        'harvest_password'      => $harvest_password,
        'udp_home'              => $udp_home,
        'ldif_home_directory'   => $ldif_home_directory,
        'ldif_remote_directory' => $ldif_remote_directory,
        'fusr'                  => $fusr
    };

    $c->model('CargaFTP')->delete_users($delete_users_args);

    $c->log->debug("delete_users OK");

    return;
}

1;
