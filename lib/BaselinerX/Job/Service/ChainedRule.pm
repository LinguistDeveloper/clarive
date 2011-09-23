package BaselinerX::Job::Service::ChainedRule;
use Baseliner::Plug;
use Baseliner::Utils;
use Carp;
use Try::Tiny;
use utf8;
use Data::Dumper;

with 'Baseliner::Role::Service';

register
  'service.job.runner.chained.rule' => {name    => 'Chained Rule Runner',
                                        config  => 'config.job',
                                        handler => \&launch,};

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
  sub { shift @data } }

sub exists_chain {
  # True or false depending on the existance of the
  # chain with the given chain ID.
  my $ref = Baseliner->model('Baseliner::BaliChain')
              ->search({id => shift})->first;
  ref $ref ? 1 : 0 }

sub launch {
  my ($self, $c, $config) = @_;
  my $job = $c->stash->{job};
  my $log = $job->logger;
  my $data = $job->job_data;
  $log->debug("Initializing Rule-Chain Runner with PID: $data->{pid}");

  my $chain_id = 3;    # FIXME

  # Checks if chain exists..
  _throw("Missing Job Chain with ID: $chain_id")
    unless exists_chain $chain_id;  # Why do we have to check?
                                    # We have all we need in BaliChainedRule
                                    # anyway...

  # We need the step!
  _throw("Missing Job Chain Step") unless exists $job->job_stash->{step};
  my $step = $job->job_stash->{step};

  my $chain = chain_dsl( $chain_id, $step );

  sub stash {
    # Lets state change during chain iteration passing parameters to the
    # current job stash.  Usage: stash var => 'value'
    no warnings;   # $job will not stay shared
    @_ > 0 
      ? $job->job_stash({%{$job->job_stash}, @_})
      : $job->job_stash }

  # Iterate every element in the chain until it runs out, if the DSL happens
  # to be Perl eval its code (if active).
  RUNNER: while (1) {
    my $rule = $chain->() // last RUNNER;
    if (   $rule->{active} == 1
        && $rule->{dsl} =~ m/perl/i) {
      $log->debug("Running Rule: $rule->{name} ($rule->{description})");
      try { eval $rule->{dsl_code} } catch { _throw shift } } }
  return }

1
