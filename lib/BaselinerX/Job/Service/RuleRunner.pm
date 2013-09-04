package BaselinerX::Job::Service::RuleRunner;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Carp;
use Try::Tiny;
use utf8;

with 'Baseliner::Role::Service';

register 'service.job.runner.rule' => { name => 'Rule Job Runner', config => 'config.job', handler => \&rule_runner, };

has 'job_log' => is=>'rw', isa=>'Any';

sub rule_runner {
    my ($self,$c, $config)=@_;

    my $job = $c->stash->{job};
    my $id_rule = $job->row->id_rule;
    my $job_stash = $job->job_stash;
    my $log = $job->logger;
    $self->job_log( $log );

    my $step = $job->step;
    _throw "Missing job chain step" unless $step;

    $log->debug( _loc('Starting Rule Runner, STEP=%1, PID=%2, RULE_ID', $step, $job->job_data->{pid} ) );

    my $ret = Baseliner->model('Rules')->run_single_rule( 
        id_rule=>$id_rule, 
        logging => 1,
        stash=>{ 
            %$job_stash, 
            job_step=>$step,
        });
}

1;
