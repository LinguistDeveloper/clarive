package BaselinerX::Comm::MVSConfig;
use Baseliner::Plug;
use Baseliner::Utils;

register 'config.JES' => {
    metadata => [
       { id=>'interval', label=>'Interval in seconds to wait for the next attempt', default => '10' },
       { id=>'attempts', label=>'Number of attempts to retrieve the job output', default => '5'},
       { id=>'nopurge', label=>'0->purge jobs when retrieved, 1->do not purge', default => '0'},
    ]
};

1;