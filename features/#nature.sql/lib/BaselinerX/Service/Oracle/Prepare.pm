package BaselinerX::Service::Oracle::Prepare;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Data::Dumper;
use Moose;
use Try::Tiny;
use utf8;

has 'suffix',  is => 'ro', isa => 'Str', default => 'ORACLE';
has 'release', is => 'rw', isa => 'Str', default => q{};

with 'Baseliner::Role::Service';

register 'service.oracle.prepare' => {
  name    => 'Oracle Prepare',
  handler => \&main
};

sub main {
  my ($self, $c, $config) = @_;
  my $job      = $c->stash->{job};
  my $bl       = $job->job_data->{bl};
  my $log      = $job->logger;
  my $SQA      = $job->job_stash->{pase_no_dist} || 0;
  my $job_name = $job->job_data->{name};
  my $job_path = $job->job_stash->{path};
  my @sql_elements = 
    $self->sql_elements($job->job_stash->{elements}->{elements});
  my @envs;

  # $log->debug("Oracle Elements: " . Dumper \@sql_elements);

  if (scalar @sql_elements) {
    $log->debug("Listado elementos de pase ORACLE: " . 
                join(', ', map($_->{fullpath},
                               grep($_->{fullpath} =~ /oracle/i, 
                                    @sql_elements))));
  }
  else {
    _throw "No existen elementos ORACLE. Puede que no haya ficheros para distribuir o no esté configurado un determinado tipo de pase";
  }

  if ($SQA) {
    my $nature_no_dist = $job->job_stash->{nature_no_dist};
    if ($nature_no_dist eq $self->suffix) {
      $log->info("Naturaleza $self->suffix omitida para el pase. Sólo $nature_no_dist");
      return 1;
    }
    $log->debug("Filtrando elementos del pase para la naturaleza $nature_no_dist");
    # TODO filter elements.
  }

  if (scalar @sql_elements) {
    $log->info("Inicio distribución de elementos ORACLE");
    for my $href (@{$job->job_stash->{contents}}) {
      my $data            = $href->{data};
      my $environmentname = $data->{environmentname};
      my $packagename     = $data->{packagename};
      push @envs, $environmentname;
      unless ($SQA) {
        # $log->debug("Ahora debería estar dentro...");  # XXX
        my @packagegroups = BaselinerX::CA::Harvest::DB
                             ->pkggrpname_packagename($packagename);
        unless ($self->release) {  # Don't bother the DB if we already have one.
          $self->release = shift @packagegroups if $bl eq "PROD"
                                                && scalar @packagegroups;
        }                                      
        unless ($self->any_ora_nets(_cam $environmentname)) {
          $log->error("En el formulario de Infraestructura de $environmentname no se indica que se use Oracle, por tanto se desconoce la Instancia a la que distribuir");
          return;
        }
      }
    }
    for my $env (@envs) {
      my $cam = _cam($env);
      unless ($SQA) {
        if (is_backout($job_name) && $bl eq 'PROD') {
          try {
            BaselinerX::Model::Oracle::Distribution
             ->restoreSQL($env, $bl, $self->suffix, $job_name, $job_path);
          }
          catch {
            unless (_restore($cam)) {  # Don't restore.
              _throw "Pase de backout terminado por no disponer del backup de la versión anterior (aplicación $cam configurada para no permitir marcha atrás sin backup anterior)";
            }
            else {
              $log->warn("Backout no ha podido utilizar backup de la aplicación $cam. La marcha atrás continúa recompilando versión anterior en Harvest.\n" . shift());
            }
          };
        }
      }
      my $co_state;  # Here I am... Would you send me an angel... (8)
    }
  }
  else {
    $log->info("No hay elementos ORACLE.");
  }
  return;
}

sub sql_elements {
  my ($self, $ls) = @_;
  filter_elements(elements => $ls, 
                  suffix   => $self->suffix);
}

### any_ora_nets : Str -> Bool
sub any_ora_nets {
  my ($self, $cam) = @_;
  my $inf = inf $cam;
  scalar @{$inf->nets_oracle} ? 1 : 0;
}

sub is_backout {
  my ($self, $job) = @_;
  substr($job, 0, 1) eq 'B' ? 1 : 0;
}

sub _restore {
  my ($self, $cam) = @_;
  my $inf = inf $cam;
  $inf->get_inf(undef, [{column_name => 'SCM_SEGUIR_SIN_BACKUP'}]) =~ /si/i
    ? 1 : 0;
}

1;
