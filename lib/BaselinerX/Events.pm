package BaselinerX::Events;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;

register 'event.repository.create' => {
    text => 'user %1 created the repository %2',
    vars => [qw/username repository/],
};

register 'event.repository.update' => {
    text => 'user %1 updated the repository %2',
    vars => [qw/username repository commit diff mid/],  #   mid=revision-mid, diff=diff text, commit=object for commit
};

1;
