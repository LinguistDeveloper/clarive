package BaselinerX::Nature;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' };

register 'menu.nature' => { label => _loc('Nature') };

1;

