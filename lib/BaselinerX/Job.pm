package BaselinerX::Job;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;

with 'Baseliner::Role::Service';

BEGIN { 
    ## Oracle needs this
    $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
}

register 'config.job.daemon' => {
    metadata=> [
        {  id=>'frequency', label=>'Job Server Frequency', type=>'int', default=>10 },
    ]
};

register 'config.job' => {
    metadata=> [
        { id=>'jobid', label => 'Job ID', type=>'text', width=>200 },
        { id=>'name', label => 'Job Name', type=>'text', width=>180 },
        { id=>'starttime', label => 'StartDate', type=>'text', },
        { id=>'username', label => 'Create', type=>'text', },
        { id=>'maxstarttime', label => 'MaxStartDate', type=>'text', },
        { id=>'endtime', label => 'EndDate', type=>'text' },
        { id=>'status', label => 'Status', type=>'text', default=>'READY' },
        { id=>'mask', label => 'Job Naming Mask', type=>'text', default=>'%s.%s-%08d' },
        { id=>'runner', label => 'Registry Entry to run', type=>'text', default=>sub { Baseliner->config->{job_runner} || 'service.job.runner.rule' } }, 
        { id=>'default_chain_id', label => 'Default Chain ID', type=>'text', default=>1 }, 
        { id=>'comment', label => 'Comment', type=>'text' },
        { id=>'check_rfc', label => 'Check RFC on creation', type=>'text', default=>0 },
        { id=>'step', label => 'Which phase of the job, pre, post or run', default => 'RUN' },
        { id=>'normal_window', label => 'Normal Window Name', default => 'N' },
        { id=>'emer_window', label => 'Emergency Window Name', default => 'U' },
        { id=>'expiry_time', label => 'Time to expiry a job in hours', type=>'hash', default=>'{ N=>"1D", U=>"1h" }' }, 
        { id=>'approval_expiry_time', label => 'Time to expiry a job in approval state', default=>'1D' }, 
        { id=>'approval_delay', label => 'Delay after start running job to allow approval', default=>'0h' },
    ],
    relationships => [ { id=>'natures', label => 'Technologies', type=>'list', config=> 'config.tech' },
        { id=>'releases', label => 'Releases', type=>'list', config=> 'config.release' },
        { id=>'apps', label => 'Applications', type=>'list', config=> 'config.app' },
        { id=>'rfcs', label => 'RFCs', type=>'list', config=>'config.rfc' },
    ],
};

register 'action.job.create' => { name=>'Create New Jobs' };
register 'action.job.resume' => { name=>'Resume Jobs' };
register 'action.job.cancel' => { name=>'Cancel Jobs' };
register 'action.job.approve_all' => { name=>'Approve/Reject any Job' };
register 'action.job.view_monitor' => { name=>'View job monitor' };

register 'menu.job' => { label => 'Jobs', index=>110, actions => ['action.job.%','action.calendar.%']};

register 'menu.job.create' => {
    label    => 'Create a new Job',
    url_comp => '/job/create',
    title    => 'New Job',
    icon     => '/static/images/icons/job.png',
    actions  => ['action.job.create'],
    index    => 10,
};
register 'menu.job.list' => {
    label    => 'Monitor',
    url_comp => '/job/monitor',
    title    => 'Monitor',
    icon     => '/static/images/icons/television.gif',
    actions  => ['action.job.view_monitor'],
    index    => 20,
};

register 'portlet.monitor' => { name=>'Job Monitor', url_comp=>'/job/monitor_portlet', url_max=>'/job/monitor', active=>1 };

register 'service.job.new' => {
    name => 'Schedule a new job',
    config => 'config.job',
    handler => sub {
        my ($self, $c, $config) = @_;
        $c->model('Jobs')->create( $config );
    }
};

register 'event.job.pre' => {
    text => 'PRE job step event',
    description => 'PRE job step event',
    vars => ['job_name', 'id_job', 'job_stash', 'job' ],
};

register 'event.job.run' => {
    text => 'RUN job step event',
    description => 'RUN job step event',
    vars => ['job_name', 'id_job', 'job_stash', 'job' ],
};

register 'event.job.post' => {
    text => 'post job step event',
    description => 'POST job step event',
    vars => ['job_name', 'id_job', 'job_stash', 'job' ],
};

# register 'menu.job.logs' => { label => _loc('Job Logs'), url_comp => '/job/log/list', title=>_loc('Job Logs') };
register 'config.job.log' => {
    metadata => [
        { id=>'job_id', label=>'Job', width=>200 },
        { id=>'log_id', label=>'Id', width=>80 },
        { id=>'lev', label=>_loc('Level'), width=>80 },
        { id=>'text', label=>_loc('Message'), width=>200 },
    ]
};

register 'event.job.new' => {
    description => 'New job',
    vars => ['username', 'bl', 'jobname', 'id_job'],
    notify => {
        scope => ['project','baseline'],
    }
};

register 'event.job.delete' => {
    description => 'Job deleted',
    vars => ['username', 'bl', 'jobname', 'id_job'],
    notify => {
        scope => ['project','bl'],
    }
};

register 'event.job.cancel' => {
    description => 'Job cancelled',
    vars => ['username', 'bl', 'jobname', 'id_job'],
    notify => {
        scope => ['project','bl'],
    }
};

register 'event.job.cancel_running' => {
    description => 'Running job cancelled',
    vars => ['username', 'bl', 'jobname', 'id_job'],
    notify => {
        scope => ['project','bl'],
    }
};


1;
