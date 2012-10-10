package BaselinerX::Events;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;

register 'event.repository.update' => {
    text => 'user %1 updated the repository %2',
    vars => ['username', 'repository'],
};

1;
