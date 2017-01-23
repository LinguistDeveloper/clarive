package BaselinerX::Job;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use DateTime;

with 'Baseliner::Role::Service';

BEGIN {
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}

register 'config.job.daemon' => {
    metadata=> [
        {  id=>'frequency', label=>_locl('Job Server Frequency'), type=>'int', default=>10 },
    ]
};

register 'config.job' => {
    metadata=> [
        { id=>'jobid', label => _locl('Job ID'), type=>'text', width=>200 },
        { id=>'name', label => _locl('Job Name'), type=>'text', width=>180 },
        { id=>'starttime', label => _locl('StartDate'), type=>'text', },
        { id=>'username', label => _locl('Create'), type=>'text', },
        { id=>'maxstarttime', label => _locl('MaxStartDate'), type=>'text', },
        { id=>'endtime', label => _locl('EndDate'), type=>'text' },
        { id=>'status', label => _locl('Status'), type=>'text', default=>'READY' },
        { id=>'mask', label => _locl('Job Naming Mask'), type=>'text', default=>'%s.%s-%08d' },
        { id=>'runner', label => _locl('Registry Entry to run'), type=>'text', default=>sub { Clarive->config->{job_runner} || 'service.job.runner.rule' } },
        { id=>'default_chain_id', label => _locl('Default Pipeline ID'), type=>'text', default=>1 },
        { id=>'comment', label => _locl('Comment'), type=>'text' },
        { id=>'check_rfc', label => _locl('Check RFC on creation'), type=>'text', default=>0 },
        { id=>'step', label => _locl('Which phase of the job, pre, post or run'), default => 'RUN' },
        { id=>'normal_window', label => _locl('Normal Window Name'), default => 'N' },
        { id=>'emer_window', label => _locl('Emergency Window Name'), default => 'U' },
        { id=>'expiry_time', label => _locl('Time to expiry a job in hours'), type=>'hash', default=>'{ N=>"1D", U=>"1h" }' },
        { id=>'approval_expiry_time', label => _locl('Time to expiry a job in approval state'), default=>'1D' },
        { id=>'approval_delay', label => _locl('Delay after start running job to allow approval'), default=>'0h' },
        { id=>'demote_to_bl', label => _locl('1 to offer demote to each bl in destination state'), default=>'0' },
        { id=>'changeset_comment_field', label => _locl('Changeset field to use as comment in monitor'), default=>'' }
    ],
    relationships => [ { id=>'natures', label => _locl('Technologies'), type=>'list', config=> 'config.tech' },
        { id=>'releases', label => _locl('Releases'), type=>'list', config=> 'config.release' },
        { id=>'apps', label => _locl('Applications'), type=>'list', config=> 'config.app' },
        { id=>'rfcs', label => _locl('RFCs'), type=>'list', config=>'config.rfc' }
    ],
};

register 'action.job.create' => { name=>_locl('Create New Jobs') };
register 'action.job.resume' => { name=>_locl('Resume Jobs'),
    bounds => [
        {
            key     => 'bl',
            name    => _locl('Environment'),
            handler => 'Baseliner::Model::Jobs=bounds_baselines',
        }
    ]
};
register 'action.job.cancel' => { name=>_locl('Cancel Jobs'),
    bounds => [
        {
            key     => 'bl',
            name    => _locl('Environment'),
            handler => 'Baseliner::Model::Jobs=bounds_baselines',
        }
    ]
};
register 'action.job.delete' => { name=>_locl('Delete Job'),
    bounds => [
        {
            key     => 'bl',
            name    => _locl('Environment'),
            handler => 'Baseliner::Model::Jobs=bounds_baselines',
        }
    ]
};
register 'action.job.approve_all' => { name=>_locl('Approve/Reject any Job') };
register 'action.job.view_monitor' => { name=>_locl('View job monitor') };

register 'menu.job' => { label => _locl('Jobs'), index=>110, actions => ['action.job.%','action.calendar.%']};

register 'menu.job.create' => {
    label    => _locl('New Job'),
    url_comp => '/job/create',
    title    => _locl('New Job'),
    icon     => '/static/images/icons/job.svg',
    actions  => ['action.job.create'],
    index    => 10,
};
register 'menu.job.list' => {
    label    => _locl('Monitor'),
    url_comp => '/job/monitor',
    title    => _locl('Monitor'),
    icon     => '/static/images/icons/television.svg',
    actions  => ['action.job.view_monitor'],
    index    => 20,
};

register 'service.job.new' => {
    name => _locl('Schedule a new job'),
    config => 'config.job',
    handler => sub {
        my ($self, $c, $config) = @_;
        $c->model('Jobs')->create( $config );
    }
};

register 'event.job.pre' => {
    text => _locl('PRE job step event'),
    description => _locl('PRE job step event'),
    vars => ['job_name', 'id_job', 'job_stash', 'job' ],
};

register 'event.job.run' => {
    text => _locl('RUN job step event'),
    description => _locl('RUN job step event'),
    vars => ['job_name', 'id_job', 'job_stash', 'job' ],
};

register 'event.job.post' => {
    text => _locl('POST job step event'),
    description => _locl('POST job step event'),
    vars => ['job_name', 'id_job', 'job_stash', 'job' ],
};

# register 'menu.job.logs' => { label => _loc('Job Logs'), url_comp => '/job/log/list', title=>_loc('Job Logs') };
register 'config.job.log' => {
    metadata => [
        { id=>'job_id', label=>_locl('Job'), width=>200 },
        { id=>'log_id', label=>_locl('Id'), width=>80 },
        { id=>'lev', label=>_loc('Level'), width=>80 },
        { id=>'text', label=>_loc('Message'), width=>200 },
    ]
};

register 'event.job.new' => {
    description => _locl('New job'),
    vars        => [ 'username', 'bl', 'jobname', 'id_job' ],
    notify      => { scope => [ 'project', 'bl' ], }
};

register 'event.job.delete' => {
    description => _locl('Job deleted'),
    vars        => [ 'username', 'bl', 'jobname', 'id_job' ],
    notify      => { scope => [ 'project', 'bl' ], }
};

register 'event.job.cancel' => {
    description => _locl('Job cancelled'),
    vars        => [ 'username', 'bl', 'jobname', 'id_job' ],
    notify      => { scope => [ 'project', 'bl' ], }
};

register 'event.job.cancel_running' => {
    description => _locl('Running job cancelled'),
    vars        => [ 'username', 'bl', 'jobname', 'id_job' ],
    notify      => { scope => [ 'project', 'bl' ], }
};

register 'event.job.unpaused' => {
    description => _locl('Job Unpaused'),
    vars        => [ 'username', 'self' ],
    notify      => { scope => ['project'] }
};

register 'event.job.paused' => {
    description => _locl('Job Paused'),
    vars        => ['self'],
    notify      => { scope => ['project'] }
};

register 'event.job.trapped' => {
    description => _locl('Job Trapped'),
    vars        => [ 'username', 'stash', 'output' ],
    notify      => { scope => ['project'] }
};

register 'event.job.untrapped' => {
    description => _locl('Job Untrapped'),
    vars        => [ 'comments', 'self' ],
    notify      => { scope => ['project'] }
};

register 'event.job.trappedpause' => {
    description => _locl('Job Trapped Pause'),
    vars        => [ 'comments', 'self' ],
    notify      => { scope => ['project'] }
};

register 'event.job.expired' => {
    description => _locl('Job Expired'),
    vars        => ['ci'],
    notify      => { scope => ['project'] }
};

register 'action.job.change_step_status' => {
    name    => _locl('Change job status on Post step'),
    extends => ['action.job.restart'],
    bounds  => [
        {   key     => 'bl',
            name    => 'Environment',
            handler => 'Baseliner::Model::Jobs=bounds_baselines',
        }
    ]
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
