use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;

use Baseliner::Validator::git_branch;

subtest 'builds not valid result' => sub {
    my $rule = _build_rule();

    my $vresult = $rule->validate('../foo/bar');

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds valid result' => sub {
    my $rule = _build_rule();

    my $vresult = $rule->validate('6.2#123-fix');

    is_deeply $vresult, { is_valid => 1 };
};

done_testing;

sub _build_rule {
    return Baseliner::Validator::git_branch->new(@_);
}
