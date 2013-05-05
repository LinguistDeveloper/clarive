package Baseliner::Core::Request;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use Try::Tiny;

BEGIN {  extends 'Catalyst::Controller' }
register 'action.job.view_requests' => { name=>'View Requests' };

register 'menu.job.requests' => {
    label    => _loc('Requests'),
    url_comp => '/requests/main',
    actions  => ['action.job.view_requests'],
    title    => _loc('Requests')
};

1;
