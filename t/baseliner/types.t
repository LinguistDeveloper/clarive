use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
use TestUtils;
BEGIN { TestEnv->setup; }

use BaselinerX::CI::GitRepository;
use Moose::Util::TypeConstraints;

use_ok 'Baseliner::Types';

subtest 'TimeStr' => sub {
    like _validate_type('TimeStr', 'abc'), qr/Validation failed/;
    like _validate_type('TimeStr', '99:99:99'), qr/Validation failed/;
    like _validate_type('TimeStr', '99:99'), qr/Validation failed/;

    ok !defined _validate_type('TimeStr', '10:10');
    ok !defined _validate_type('TimeStr', '10:10:10');
};

subtest 'DateStr' => sub {
    like _validate_type('DateStr', 'abc'), qr/Validation failed/;
    like _validate_type('DateStr', '2015-99-99'), qr/Validation failed/;

    ok !defined _validate_type('DateStr', '2015-01-01');
};

subtest 'GitBranch' => sub {
    like _validate_type('GitBranch', '../hello'), qr/Validation failed/;

    ok !defined _validate_type('GitBranch', '6.2#123-fix');
};

subtest 'GitTag' => sub {
    like _validate_type('GitTag', '../hello'), qr/Validation failed/;

    ok !defined _validate_type('GitTag', 'TEST');
};

subtest 'GitCommit' => sub {
    like _validate_type('GitCommit', 'foo-bar'), qr/Validation failed/;

    ok !defined _validate_type('GitCommit', 'abc123');
};

subtest 'PositiveInt' => sub {
    like _validate_type('PositiveInt', '-1'), qr/Validation failed/;

    ok !defined _validate_type('PositiveInt', '0');
    ok !defined _validate_type('PositiveInt', '15');
};

subtest 'ExistingCI' => sub {
    mdb->master->drop;
    mdb->master_doc->drop;
    mdb->master_rel->drop;

    TestUtils->setup_registry(qw/ BaselinerX::CI BaselinerX::Type::Event /);

    like _validate_type('ExistingCI', '123'), qr/Validation failed/;

    BaselinerX::CI::GitRepository->new( id => '123')->save;

    like _validate_type('ExistingCI', '123'), qr/Validation failed/;
};

done_testing;

sub _validate_type {
    my ($isa, $value) = @_;

    my $type_constraint = find_type_constraint($isa) or die "Can't find type $isa";

    if ($type_constraint->coercion) {
        $value = $type_constraint->coerce($value);
    }

    return $type_constraint->validate($value);
}
