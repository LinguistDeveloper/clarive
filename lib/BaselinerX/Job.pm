package BaselinerX::Job;
use Baseliner::Plug;
use Baseliner::Utils;
use DateTime;
use YAML;

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
        # { id=>'runner', label => 'Registry Entry to run', type=>'text', default=>sub { Baseliner->config->{job_runner} || 'service.job.runner.simple.chain' } },
        { id=>'runner', label => 'Registry Entry to run', type=>'text', default=>sub { Baseliner->config->{job_runner} || 'service.job.runner.chained.rule' } }, # Eric
        { id=>'comment', label => 'Comment', type=>'text' },
        { id=>'check_rfc', label => 'Check RFC on creation', type=>'text', default=>0 },
        { id=>'step', label => 'Which phase of the job, pre, post or run', default => 'RUN' },
        { id=>'normal_window', label => 'Normal Window Name', default => 'normal' },
        { id=>'emer_window', label => 'Emergency Window Name', default => 'emergency' },
        { id=>'expiry_time', label => 'Time to expiry a job in hours', type=>'hash', default=>'{ normal=>24, emergency=>24 }' }, 
    ],
    relationships => [ { id=>'natures', label => 'Technologies', type=>'list', config=> 'config.tech' },
        { id=>'releases', label => 'Releases', type=>'list', config=> 'config.release' },
        { id=>'apps', label => 'Applications', type=>'list', config=> 'config.app' },
        { id=>'rfcs', label => 'RFCs', type=>'list', config=>'config.rfc' },
    ],
};

register 'menu.job' => { label => 'Jobs' };

register 'action.job.create' => {name => 'Create New Jobs'};

register 'menu.job.create' => {label   => 'Create a new Job',
                               url     => '/job/create',
                               title   => 'New Job',
                               icon    => '/static/images/star_on.gif',
                             # actions => ['action.job.create'],
                               action  => 'action.job.create'};

#register 'menu.job.list' => { label => 'List Current Jobs', url=>'/maqueta/list.mas', title=>'Job Monitor' };
#register 'menu.job.exec' => { label => 'Exec Current Jobs', url_run=>'/maqueta/list.mas', title=>'Job Monitor' };
#register 'menu.job.hist' => { label => 'Historical Data', handler => 'function(){ Ext.Msg.alert("Hello"); }' };
register 'menu.job.list' => { label => 'Monitor', url_comp => '/job/monitor', title=>'Monitor', icon=>'/static/images/icons/television.gif' };
#register 'menu.job.hist.all' => { label => 'List all Jobs', url=>'/core/registry', title=>'Registry'  };

register 'portlet.monitor' => { name=>'Job Monitor', url_comp=>'/job/monitor_portlet', url_max=>'/job/monitor', active=>1 };
#register 'portlet.guin' => { name=>'Job Monitor', url=>'/site/guin.html', url_max=>'/site/guin.html', active=>1 };

register 'service.job.new' => {
    name => 'Schedule a new job',
    config => 'config.job',
    handler => sub {
        my ($self, $c, $config) = @_;
        $c->model('Jobs')->create( $config );
    }
};



1;
