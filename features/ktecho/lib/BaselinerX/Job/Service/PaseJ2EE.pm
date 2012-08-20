package BaselinerX::Job::Service::PaseJ2EE;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Comm::Balix;
use feature 'say';
use Try::Tiny;
use 5.010;
with 'Baseliner::Role::Service';

register 'service.script.j2ee.pase' => {
  name    => 'J2EE Post',
  config  => 'config.script.j2ee.pase',
  handler => \&index
};

register 'config.script.j2ee.pase' => {
  name     => "Configuración scripts 'LOG' para J2EE",
  metadata => [
    {id => 'sufijo', name => 'Sufijo',     default => 'POST'},
    {id => 'nature', name => 'Naturaleza', default => 'J2EE'}
  ]
};

sub index {
  my ($self, $c, $config) = @_;

  my $sleeep = 2;

  say 'Iniciando Pase Naturaleza J2EE';
  say 'Compilación';
  say 'Generación de EAR';

  my $sem = 'bde.j2ee.deploy';
  my $bl  = 'TEST';
  my $who = 'SCT - N.TEST-0000014532 - J2EE';

  my $config_ref = {sem => $sem, bl => $bl, who => $who};

  my $sm = Baseliner->model('Semaphores');
  sleep $sleeep;

  _log "Requested semaphore client for " . "sem=" 
    . $sem . ", bl=" 
    . $bl . " who="
    . $who;
  sleep $sleeep;

  $sem = $sm->request(%{$config_ref});

  _log "Granted semaphore client for " . "sem=" 
    . $sem . ", bl=" 
    . $bl . " who="
    . $who;
  sleep $sleeep;

  _log "Releasing semaphore client for " . "sem=" 
    . $sem . ", bl=" 
    . $bl . " who="
    . $who;
  sleep $sleeep;

  say 'Despliegue';
  sleep $sleeep;

  $sem->release;

  say 'Finalizando pase J2EE.';
  sleep $sleeep;

  return;
}

1;
