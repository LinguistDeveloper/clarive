package BaselinerX::Job::Service::AddReportData;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Try::Tiny;
use Time::Interval;

with 'Baseliner::Role::Service';

register 'service.baseliner.job.add_report_data' => {name    => 'Puts job data into BALI_JOB_REPORT',
                                                     handler => \&main};
register 'action.bde.receive.generate_reports_error' => { name=>'Notify when an error acurred during reports generation' };


{
  package Month::Convert;
  use 5.010;
  use Baseliner::Plug;
  use Baseliner::Utils;
  use Moose;

  has 'months', is => 'ro', isa => 'ArrayRef', lazy_build => 1;

  sub _build_months {
    [[1,  'Enero'],
     [2,  'Febrero'],
     [3,  'Marzo'],
     [4,  'Abril'],
     [5,  'Mayo'],
     [6,  'Junio'],
     [7,  'Julio'],
     [8,  'Agosto'],
     [9,  'Septiembre'],
     [10, 'Octubre'],
     [11, 'Noviembre'],
     [12, 'Diciembre']];
  }
  
  sub month_int_to_str {
    my ($self, $int) = @_;
    my $months = $self->months;
    for my $aref (@$months) {
      return $aref->[1] if $aref->[0] == $int;
    }
  }
  
  sub month_str_to_int {
    my ($self, $str) = @_;
    my $months = $self->months;
    for my $aref (@$months) {
      return $aref->[0] if $aref->[1] eq $str;
    }
  }
}

sub main {
  my ($self, $c, $config) = @_;
  my $job        = $c->stash->{job};
  my $log        = $job->logger;
  my $job_name   = $job->job_data->{name};

  $log->info(_loc("Generating reports...") );
  try {
      $self->GenerateReport_1($c,$config);
      $self->GenerateReport_2($c,$config);
  } catch {
      my $message=$_;
      my $action = "action.bde.receive.generate_reports_error";

      notify_error(_loc("Error during report generation"), $message, $action);
  };
  $log->info(_loc("Reports generated") );
}

sub GenerateReport_1 {
  my ($self, $c, $config) = @_;
  my $job        = $c->stash->{job};
  my $log        = $job->logger;
  my $elements   = $job->job_stash->{elements}->{elements};
  my $job_name   = $job->job_data->{name};
  my $job_owner  = $job->job_data->{username};
  my $bl         = $job->job_data->{bl};
  my $start_time = $job->job_data->{starttime};
  my $end_time   = $job->job_data->{endtime};
  my $status     = $job->job_data->{status};
  my $duration   = convertInterval %{getInterval $start_time, $end_time}, ConvertTo => 'seconds';
  my @natures_with_subapps = @{_bde_conf 'natures_with_subapps'};
  # Consider getting from bali job items instead.
  my @natures = _unique map { $_->{name} } 
                grep $_->can_i_haz_nature($elements), 
                map  { Baseliner::Core::Registry->get($_) } $c->registry->starts_with('nature');
  # Capture the providers so we can identify whether it is a ZOS job.
  my $is_zos_p = 'namespace.changeman.package' ~~ _unique map { $_->{provider} } @{$job->job_stash->{contents}};
  my $month_converter = Month::Convert->new;
  my $addf = sub {
    my ($hashref) = @_; 
    $_->{job_name}    = $job_name;
    $_->{environment} = $bl;
    $_->{urgent}      = substr($job_name, 0, 1) eq 'U' ? 1 : 0;
    $_->{year}        = [split_date $start_time]->[0];
    $_->{month}       = [split_date $start_time]->[1];
    $_->{day}         = [split_date $start_time]->[2];
    $_->{start_time}  = $start_time;
    $_->{end_time}    = $end_time;
    $_->{quarter}     = month_to_quarter [split_date $start_time]->[1];
    $_->{duration}    = $duration;
    $_->{status}      = $status eq 'RUNNING' ? 'FINISHED' : $status; # This is the last step anyway so let's assume everything's fine
    $_->{month_str}   = $month_converter->month_int_to_str($_->{month});
    $_->{username}    = $job_owner;
    $_;
  };
  my @data = $is_zos_p ? $self->build_changeman_data($addf, map { _pathxs $_, 1 } grep {$_} map { $_->{application} } @{$job->job_stash->{contents}}, $job )
                       : map  { $addf->($_) } # Add the rest of the stuff
                         grep { $_->{technology} ~~ @natures } # Remove unwanted natures, get only those that are registered
                         map +{project => $_->[0], subapplication => $_->[1], technology => $_->[2]}, # Hashify!
                         map  { [split '#', $_] } _unique map { join '#', @{$_} } # Remove duplicates
                         map  { $self->data_tuple($_->{fullpath}, @natures_with_subapps) } @{$elements}; # Make tuple
  my $m = Baseliner->model('Baseliner::BaliJobReport');
  $m->create($_) for @data;
  return;
}

sub build_changeman_data {
  my ($self, $addf, @applications, $job) = @_;
  map { $addf->($_) } map +{project => $_, subapplication => '', technology => 'ZOS', statename => Baseliner->model('Baseliner::BaliBaseline')->search({bl=>$job->job_data->{bl}})->first->name ,origin => uc ( $job->job_stash->{origin}||'baseliner' ) }, @applications;
}

sub data_tuple {
  my ($self, $pathfullname, @natures_with_subapps) = @_;
  my $cam      = _pathxs $pathfullname, 1;
  my $nature   = _pathxs $pathfullname, 2;
  my $sub_appl = $nature ~~ @natures_with_subapps ? _pathxs $pathfullname, 3 : q{};
  [$cam, $sub_appl, $nature];
}

1;
