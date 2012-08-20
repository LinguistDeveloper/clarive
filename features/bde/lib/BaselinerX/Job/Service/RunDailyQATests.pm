package BaselinerX::Job::Service::RunDailyQATests;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Class::Date qw/date now/;

with 'Baseliner::Role::Service';

register 'service.baseliner.run.daily.qa.tests.daemon' => {
  name    => '',
  handler => \&daemon
};

sub current_hour {
  my $date = now;
  my $current_hour = $date->[3] . $date->[4];
  $current_hour;
}

sub hhmm {
  my ($self, $str) = @_;
  my $hhmm = join q{}, split ':', $str;
  $hhmm;
}

sub load_tests {
  my ($self) = @_;
  my $rs = Baseliner->model('Baseliner::BaliSqaPlannedTest')->search;
  rs_hashref($rs);
  my @data = $rs->all;
  my $current_hour = $self->current_hour;
  my $diff = (_bde_conf 'dailyqainterval') / 60;
  my @valid_tests = grep { $current_hour - $self->hhmm($_->{scheduled}) <= $diff }  # And the difference is <= than N minutes.
                    grep { $self->hhmm($_->{scheduled}) <= $current_hour         }  # Make sure it's still the time to run the test.
                    grep { $_->{active}                                          }  # Return active ones.
                    @data;
  _log 'Number of valid tests: ' . (scalar @valid_tests) . ' out of ' . (scalar @data) . ' records';
  ## Return a proper structure for request_analysis.
  map +{id         => $_->{id},
        project    => $_->{project},
        subproject => $_->{subapl},
        nature     => $_->{nature},
        user       => $_->{username},
        bl         => $_->{bl}}, @valid_tests;
}

sub init {
  my ($self) = @_;
  my @tests = $self->load_tests;
  for my $test (@tests) {
    _log 'Launching SQA analysis with parameters ' . Data::Dumper::Dumper $test;
    Baseliner->model('BaselinerX::Model::SQA')->request_analysis(%$test);
    my $now = sql_date();
    my $rs = Baseliner->model('Baseliner::BaliSqaPlannedTest')->search({id => $test->{id}});
    $rs->update({active => 0, last_exec => $now});
  }
  return;
}

sub daemon {
  my ($self) = @_;
  while (1) {
    $self->init();
    my $sleep = _bde_conf 'dailyqainterval';
    sleep $sleep;
  }
}

1;
