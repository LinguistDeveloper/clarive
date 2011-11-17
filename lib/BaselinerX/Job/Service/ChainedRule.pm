package BaselinerX::Job::Service::ChainedRule;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Carp;
use Data::Dumper;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register
  'service.job.runner.chained.rule' => {name    => 'Chained Rule Runner',
                                        config  => 'config.job',
                                        handler => \&launch};

sub table {'Baseliner::BaliChainedRule'}

sub chain_dsl {
  # Iterate chained rule sequence for a given chain-id
  # and step, returning a hashref with all its
  # attributes.
  my ($id, $step) = @_;
  my $where = {step     => $step,
               chain_id => $id};
  my $args  = {order_by => 'seq'};
  my $rs    = Baseliner->model(table)->search($where, $args);
  rs_hashref($rs);
  my @data = $rs->all;
  sub { shift @data || last }
}

sub exists_chain {
  # True or false depending on the existance of the
  # chain with the given chain ID.
  my $ref = Baseliner->model('Baseliner::BaliChain')
              ->search({id => shift})->first;
  ref $ref ? 1 : 0;
}

sub cdr { shift; @_ }

sub proper_ns { # Str -> Maybe[Str]
  join '', cdr split '', $_[0];
}

sub launch {
  my ($self, $c, $config) = @_;
  my $job  = $c->stash->{job};
  my $log  = $job->logger;
  my $data = $job->job_data;
  $log->debug("Initializing Rule-Chain Runner with PID: $data->{pid}");

  # This identifies whether every step in the chain will generate a semaphore
  # request.
  my $sem_chain = _bde_conf 'chain.sem';

  my $chain_id = 3;  # FIXME

  my $step = exists $job->job_stash->{step} 
               ? $job->job_stash->{step} 
               : 'PRE';

  my $chain = chain_dsl($chain_id, $step);

  sub stash {
    no warnings;
    # Lets state change during chain iteration passing parameters to the
    # current job stash.  Usage: stash var => 'value'
    @_ > 0 ? $job->job_stash({%{$job->job_stash}, @_})
           : $job->job_stash;
  }

  sub run { no warnings; $c->launch($_[0]) }

  sub eval_row {
    no warnings;
    my $row = shift;
    my $sem_model = Baseliner->model('Semaphores');
    my $sem = $sem_chain
      ? $sem_model->request(sem    => $row->{service},
                            bl     => $job->{job_data}->{bl},
                            who    => $job->{job_data}->{name},
                            active => 0)
      : q{};

    eval qq| sub service { \$row->{service} } $row->{dsl_code}; |;
    $sem->release if $sem;
    _throw $@ if $@ && _bde_conf('kill_chain');
  }

  # Iterate every element in the chain until it runs out, if the DSL happens
  # to be Perl eval its code (if active).
  RUNNER:
  while (1) { 
    my $rule = $chain->();
    if ($rule->{active} == 1 && $rule->{dsl} =~ m/perl/i) {
      eval_row($rule) if $rule->{ns} eq '/'              #    generic namespace
                      || proper_ns($rule->{ns})          # OR ns without '/'
                         ~~                              #    belongs to
                         @{$job->job_stash->{natures}};  #    the list of natures
    } 
  }
  return; 
}

1;
