package BaselinerX::Events;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;

register 'event.repository.create' => {
    text => 'user %1 created the repository %2',
    vars => [qw/username repository/],
};

register 'event.repository.update' => {
    text => 'user %1 updated the repository %2',
    vars => [qw/username title repository commit diff mid/],  #   mid=revision-mid, diff=diff text, commit=object for commit
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
