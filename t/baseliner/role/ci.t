use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
use TestUtils;

BEGIN { TestEnv->setup; }

use Clarive::ci;
use Baseliner::Core::Registry;
use Baseliner::Role::CI;

subtest 'returns true when deleting ci' => sub {
    _setup();

    my $ci = _build_ci();
    $ci->save;

    is $ci->delete, 1;
};

subtest 'returns false when deleting not loaded ci' => sub {
    _setup();

    my $ci = _build_ci();

    is $ci->delete, 0;
};

subtest 'returns false when deleting deleted ci' => sub {
    _setup();

    my $old_ci = _build_ci();
    my $mid = $old_ci->save;

    my $ci = ci->new($mid);

    $old_ci->delete;

    is(ci->delete($mid), 0);
};

done_testing;

sub _setup {
    Baseliner::Core::Registry->clear;
    TestUtils->cleanup_cis;
    TestUtils->register_ci_events;
}

sub _build_ci {
    BaselinerX::CI::TestClass->new(@_);
}

package BaselinerX::CI::TestClass;
use Moose;

sub icon {'123'}
BEGIN { with 'Baseliner::Role::CI'; }
