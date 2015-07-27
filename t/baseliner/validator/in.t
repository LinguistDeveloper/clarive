use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;

use Baseliner::Validator::in;

subtest 'builds not valid result' => sub {
    my $rule = _build_rule(in => [qw/foo bar/]);

    my $vresult = $rule->validate('baz');

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds valid result' => sub {
    my $rule = _build_rule(in => [qw/foo bar/]);

    my $vresult = $rule->validate('foo');

    is_deeply $vresult, { is_valid => 1 };
};

done_testing;

sub _build_rule {
    return Baseliner::Validator::in->new(@_);
}
