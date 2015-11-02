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
    _setup();

    my $rule = _build_rule();

    my $vresult = $rule->validate('foo');

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds not valid result when ci with wrong isa' => sub {
    _setup();

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule( isa_check => 'foobar' );

    my $vresult = $rule->validate( $ci->mid );

    is_deeply $vresult, { is_valid => 0, error => 'INVALID' };
};

subtest 'builds valid result when known ci' => sub {
    _setup();

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule();

    my $vresult = $rule->validate( $ci->mid );

    ok $vresult->{is_valid};
};

subtest 'builds valid result when known ci and isa' => sub {
    _setup();

    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule( isa_check => 'BaselinerX::CI::GitRepository' );

    my $vresult = $rule->validate( $ci->mid );

    ok $vresult->{is_valid};
};

subtest 'returns loaded ci' => sub {
    _setup();
    
    my $ci = ci->GitRepository->new;
    $ci->save;

    my $rule = _build_rule( isa_check => 'BaselinerX::CI::GitRepository' );

    my $vresult = $rule->validate( $ci->mid );

    my $value = $vresult->{value};

    is $value->mid, $ci->mid;
};

done_testing;

sub _build_rule {
    return Baseliner::Validator::valid_ci->new(@_);
}

sub _setup {
    Baseliner::Core::Registry->clear();
    TestUtils->register_ci_events();
    TestUtils->cleanup_cis;
}
