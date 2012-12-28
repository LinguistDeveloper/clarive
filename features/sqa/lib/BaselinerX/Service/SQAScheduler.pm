package BaselinerX::Service::SQAScheduler;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Class::Date qw/date now/;

with 'Baseliner::Role::Service';

register 'service.sqa.scheduler' => {
  name    => '',
  handler => \&daemon,
  config => 'config.sqa.scheduler'
};

sub daemon {
  my ($self, $c, $config) = @_;
  
  _log "SQA SCHEDULER: Starting";
  for ( 1 .. $config->{iterations} ) {
  	_log "SQA SCHEDULER: Running iteration $_ of $config->{iterations}";
    $self->run_once();
    _log "SQA SCHEDULER: Sleeping $config->{frequency} seconds";
    sleep $config->{frequency};
  }
}
register 'service.sqa.scheduler_once' => {
  name    => '',
  handler => \&run_once,
  config => 'config.sqa.scheduler'
};

sub run_once {
  my ($self, $c, $config) = @_;
  my @tests = $self->load_tests;
  for my $test (@tests) {
    _log 'Launching SQA analysis with parameters ' . Data::Dumper::Dumper $test;
    Baseliner->model('BaselinerX::Model::SQA')->request_analysis(%$test);
    my $now = now;
    my $rs = Baseliner->model('Baseliner::BaliSqaPlannedTest')->find($test->{id});

    my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Year += 1900;
	$Month +=1;
    
    my ($hora, $minutos) = split ":", $rs->scheduled;		

	my $nextDate = Class::Date->new( [$Year,$Month,$Day,$hora, $minutos] ) + "1D";
	
    $rs->update({last_exec => $now, next_exec => $nextDate });
  }
  return;
}

sub load_tests {
  my ($self, $c, $config) = @_;
  
  my $now= now;
  my $rs = Baseliner->model('Baseliner::BaliSqaPlannedTest')->search( { active => '1', next_exec => {"<=", $now} } );
  rs_hashref($rs);
  my @data = $rs->all;

  ## Return a proper structure for request_analysis.
  map +{id         => $_->{id},
        project    => $_->{project},
        subproject => $_->{subapl},
        nature     => $_->{nature},
        user       => $_->{username},
        bl         => $_->{bl}}, @data;
}
1;
