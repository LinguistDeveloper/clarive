package BaselinerX::CI;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::Registry ':dsl';

register 'event.ci.create' => {
    description => _locl('New CI'),
    vars => ['username', 'mid', 'ci']
};

register 'event.ci.update' => {
    description => _locl('Update CI'),
    vars => ['username', 'old_ci', 'new_ci', 'mid']
};

register 'event.ci.delete' => {
    description => _locl('Delete CI'),
    vars => ['username', 'mid', 'ci']
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
