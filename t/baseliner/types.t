use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup; }

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

done_testing;

sub _validate_type {
    my ($isa, $value) = @_;

    my $type_constraint = find_type_constraint($isa) or die "Can't find type $isa";

    if ($type_constraint->coercion) {
        $value = $type_constraint->coerce($value);
    }

    return $type_constraint->validate($value);
}
