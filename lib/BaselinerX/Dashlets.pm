package BaselinerX::Dashlets;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;

register 'dashlet.job.last_jobs' => {
    form=> '/dashlets/last_jobs_config.js',
    name=> _locl('Last jobs by app'),
    icon=> '/static/images/icons/report_default.svg',
    js_file => '/dashlets/last_jobs.js'
};

register 'dashlet.job.list_jobs' => {
    form=> '/dashlets/list_jobs_config.js',
    name=> _locl('List jobs'),
    icon=> '/static/images/icons/report_default.svg',
    js_file => '/dashlets/list_jobs.js'
};

register 'dashlet.job.list_baseline' => {
    form=> '/dashlets/baselines_config.js',
    name=> _locl('List baselines'),
    icon=> '/static/images/icons/report_default.svg',
    js_file => '/dashlets/baselines.js'
};

register 'dashlet.job.chart' => {
    form=> '/dashlets/job_chart_config.js',
    name=> _locl('Job chart'),
    icon=> '/static/images/icons/chart_pie.svg',
    js_file => '/dashlets/job_chart.js'
};

register 'dashlet.job.day_distribution' => {
    form=> '/dashlets/job_distribution_day_config.js',
    name=> _locl('Job daily distribution'),
    icon=> '/static/images/icons/chart_line.svg',
    js_file => '/dashlets/job_distribution_day.js'
};

register 'dashlet.ci.graph' => {
    form=> '/dashlets/ci_graph_config.js',
    name=> _locl('CI Graph'),
    icon=> '/static/images/icons/ci-grey.svg',
    js_file => '/dashlets/ci_graph.js',
    no_boot => 1,
};

register 'dashlet.topic.number_of_topics' => {
    form=> '/dashlets/number_of_topics_chart_config.js',
    name=> _locl('Topics chart'),
    icon=> '/static/images/icons/chart_pie.svg',
    js_file => '/dashlets/number_of_topics_chart.js'
};

register 'dashlet.topic.list_topics' => {
    form=> '/dashlets/list_topics_config.js',
    name=> _locl('List topics'),
    icon=> '/static/images/icons/report_default.svg',
    js_file => '/dashlets/list_topics.js'
};

register 'dashlet.topic.topics_by_date_line' => {
    form=> '/dashlets/topics_by_date_line_config.js',
    name=> _locl('Topics time line'),
    icon=> '/static/images/icons/chart_curve.svg',
    js_file => '/dashlets/topics_by_date_line.js'
};

register 'dashlet.topic.topics_burndown' => {
    form=> '/dashlets/topics_burndown_config.js',
    name=> _locl('Topics burndown'),
    icon=> '/static/images/icons/chart_line.svg',
    js_file => '/dashlets/topics_burndown.js'
};

register 'dashlet.topic.topics_period_burndown' => {
    form=> '/dashlets/topics_period_burndown_config.js',
    name=> _locl('Topics period burndown'),
    icon=> '/static/images/icons/chart_line.svg',
    js_file => '/dashlets/topics_period_burndown.js'
};

register 'dashlet.topic.topics_burndown_ng' => {
    form=> '/dashlets/topics_burndown_config_ng.js',
    name=> _locl('Topics burndown NG'),
    icon=> '/static/images/icons/chart_line.svg',
    js_file => '/dashlets/topics_burndown_ng.js'
};

register 'dashlet.topic.gauge' => {
    form=> '/dashlets/topics_gauge_config.js',
    name=> _locl('Topics gauge'),
    field_width => '80%',
    icon=> '/static/images/icons/gauge.svg',
    js_file => '/dashlets/topics_gauge_d3.js'
};

register 'dashlet.topic.topic_roadmap' => {
    form=> '/dashlets/topic_roadmap_config.js',
    name=> _locl('Topic Roadmap'),
    icon=> '/static/images/icons/roadmap.svg',
    js_file => '/dashlets/topic_roadmap.js',
    no_boot => 1,
};

register 'dashlet.topic.calendar' => {
    form=> '/dashlets/calendar_config.js',
    name=> _locl('Calendar'),
    icon=> '/static/images/icons/calendar.svg',
    js_file => '/dashlets/calendar.js',
    no_boot => 1,
};

register 'dashlet.iframe' => {
    form=> '/dashlets/iframe_config.js',
    name=> _locl('Internet frame'),
    icon=> '/static/images/icons/webservice.svg',
    js_file => '/dashlets/iframe.js'
};

register 'dashlet.email' => {
    form=> '/dashlets/emails_config.js',
    name=> _locl('Email messages'),
    icon=> '/static/images/icons/envelope.svg',
    js_file => '/dashlets/emails.js'
};

register 'dashlet.html' => {
    form=> '/dashlets/html_config.js',
    name=> 'HTML',
    icon=> '/static/images/icons/html.svg',
    js_file => '/dashlets/html.js',
    no_boot => 1,
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
