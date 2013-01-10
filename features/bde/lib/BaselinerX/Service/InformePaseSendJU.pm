#INFORMACIÃ“N DEL CONTROL DE VERSIONES
#
#	CAM .............................. SCM
#	Pase ............................. N.TEST0000057263
#	Fecha de pase .................... 2012/01/23 17:13:55
#	UbicaciÃ³n del elemento ........... /SCM/FICHEROS/UNIX/baseliner/features/bde/lib/BaselinerX/Service/InformePaseSendJU.pm
#	VersiÃ³n del elemento ............. 1
#	Propietario de la version ........ q74613x (Q74613X - ERIC LORENZANA CANALES)

package BaselinerX::Service::InformePaseSendJU;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Baseliner::Sugar;
use DateTime;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.informepase.send_ju' => {name    => 'Send Mail JU',
                                           handler => \&main};

sub main {
  my ($self, $c, $config) = @_;

  # El provider por defecto.
  my $provider = 'informepase.ju_email';
  my $p_model = Baseliner->model('Permissions');

  # Tenemos que filtrar también por fecha, para que vaya un poco más rápido esto.
  my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
  $Year  += 1900;
  $Month += 1;
  $Month = '0' . $Month if $Month < 10;
  $Day   = '0' . $Day if $Day < 10;
  my $item = "$Year$Month$Day";

  my $sdt = parse_dt( '%Y-%m-%d %H:%M', "$Year-$Month-$Day $Hour:$Minute"  );
  $sdt->{locale} = DateTime::Locale->load( 'en' ); # day names in local language

  # Cogemos todos los datos de los jobs que se han lanzado hoy.
  my @data_store = map  { Baseliner->model('Repository')->get(ns => $_) }
                   map  { "$provider/$_"} # Add the provider again :D
                   grep /^$item/,  # Filtramos por fecha.
                   map  { _pathxs $_, 1 } Baseliner->model('Repository')->list(provider => $provider);

  # # Cogemos un listado de la aplicaciones que han sido distribuidas hoy.
  # my @cams = sort { $a lt $b } _unique map { map { $_ } @{$_->{cam_list}} } @data_store;

  # Construimos users con key: username, values: [data].

  my %users;
  my %jobs;
  my %cams;
  for my $data (@data_store) {
    my @_users = build_users($data->{environment}, @{$data->{cam_list}});
    for my $user (@_users) {
      my $mail = $p_model->user_address_for_action(username=>$user, action=>'action.informepase.ju_mail', bl=>$data->{environment}, cam=>$data->{cam_list});
      next unless $mail;
      unless ( $jobs{$mail}{$data->{job_id}} ) {
        push @{$users{$mail}}, $data ;
        push @{$cams{$mail}}, @{$data->{cam_list}};
        $jobs{$mail}{$data->{job_id}}=1;
      }
    }
  }
  unless (keys %users) {
    _log "No he encontrado usuarios con accion 'action.informepase.ju_mail'.";
    return;
  }

  # Enviamos mails.
  my $mailcfg  = config_get( 'config.comm.email' );

  my $m_sender = Baseliner->model('Messaging');
  for my $username (keys %users) {
    $m_sender->notify(to              => {users => [$username]},
                      subject         => "Informe SCM de Pases Changeman - $Day/$Month/$Year",
                      sender          => $mailcfg->{from},
                      carrier         => 'email',
                      template        => 'email/analysis_informepase_ju.html',
                      template_engine => 'mason',
                      vars            => {
                          mail_data   => $users{$username},
                          url         => _notify_address(),
                      	  message     => _loc("Report of jobs made on %1 %2",_loc($sdt->day_name),"$Day/$Month/$Year"),
                      	  to          => [$username],
                      	  cams        => join ", ",_unique @{$cams{$username}}
                      });
  }
}

sub build_users {
  my ($environment, @projects) = @_;
  my $p_model = Baseliner->model('Permissions');
  _unique map { 
    $p_model->list(action      => 'action.informepase.ju_mail',
                   ns          => "project/$_",
                   bl          => $environment,
                   givemeusers => $environment
                   )
  } map { cam_to_projectid $_ } @projects;
}

1;
