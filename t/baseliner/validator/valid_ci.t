use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;
use TestUtils;

TestEnv->setup;

use Clarive::ci;
use Baseliner::Core::Registry;
use Baseliner::Validator::valid_ci;

subtest 'builds not valid result when unknown ci' => sub {
    TestUtils->cleanup_cis;

    my $rule = _build_rule();

    my $vresult = $rule->validate('foo');

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds not valid result when ci with wrong isa' => sub {
    TestUtils->cleanup_cis;

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule( isa => 'foobar' );

    my $vresult = $rule->validate( $ci->mid );

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds valid result when known ci' => sub {
    TestUtils->cleanup_cis;

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule();

    my $vresult = $rule->validate( $ci->mid );

    ok $vresult->{is_valid};
};

subtest 'builds valid result when known ci and isa' => sub {
    TestUtils->cleanup_cis;

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule( isa => 'BaselinerX::CI::GitRepository' );

    my $vresult = $rule->validate( $ci->mid );

    ok $vresult->{is_valid};
};

subtest 'returns loaded ci' => sub {
    TestUtils->cleanup_cis;

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule( isa => 'BaselinerX::CI::GitRepository' );

    my $vresult = $rule->validate( $ci->mid );

    my $value = $vresult->{value};

    is $value->mid, $ci->mid;
};

done_testing;

sub _build_rule {
    return Baseliner::Validator::valid_ci->new(@_);
}
