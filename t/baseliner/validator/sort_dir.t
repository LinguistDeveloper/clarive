use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;

use Baseliner::Validator::sort_dir;

subtest 'builds not valid result' => sub {
    my $rule = _build_rule();

    my $vresult = $rule->validate('hello');

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds valid result' => sub {
    my $rule = _build_rule();

    my $vresult = $rule->validate('ASC');

    is_deeply $vresult, { is_valid => 1 };
};

done_testing;

sub _build_rule {
    return Baseliner::Validator::sort_dir->new(@_);
}
