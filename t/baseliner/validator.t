use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }

use Baseliner::Validator;

subtest 'validates required missing fields' => sub {
    my $validator = _build_validator();

    $validator->add_field('foo');

    my $vresult = $validator->validate;

    is_deeply $vresult, { is_valid => 0, errors => { foo => 'REQUIRED' }, validated_params => {} };
};

subtest 'validates required empty fields' => sub {
    my $validator = _build_validator();

    $validator->add_field('foo');

    my $vresult = $validator->validate( { foo => '' } );

    is_deeply $vresult, { is_valid => 0, errors => { foo => 'REQUIRED' }, validated_params => {} };
};

subtest 'validates required empty fields when arrays' => sub {
    my $validator = _build_validator();

    $validator->add_field('foo');

    my $vresult = $validator->validate( { foo => [] } );

    is_deeply $vresult, { is_valid => 0, errors => { foo => 'REQUIRED' }, validated_params => {} };
};

subtest 'validates required empty fields when arrays of empty values' => sub {
    my $validator = _build_validator();

    $validator->add_field('foo');

    my $vresult = $validator->validate( { foo => [undef, ''] } );

    is_deeply $vresult, { is_valid => 0, errors => { foo => 'REQUIRED' }, validated_params => {} };
};

subtest 'validates fields with defaults' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', default => 10 );

    my $vresult = $validator->validate;

    is_deeply $vresult, { is_valid => 1, errors => {}, validated_params => { foo => 10 } };
};

subtest 'does not validate rules when empty' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Int', default => '' );

    my $vresult = $validator->validate;

    is_deeply $vresult, { is_valid => 1, errors => {}, validated_params => { foo => '' } };
};

subtest 'validates fields with defaults as empty string' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', default => '' );

    my $vresult = $validator->validate;

    is_deeply $vresult, { is_valid => 1, errors => {}, validated_params => { foo => '' } };
};

subtest 'validates fields with defaults as zero' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', default => 0 );

    my $vresult = $validator->validate;

    is_deeply $vresult, { is_valid => 1, errors => {}, validated_params => { foo => 0 } };
};

subtest 'validates against the isa' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Int' );

    my $vresult = $validator->validate( { foo => 'abc' } );

    cmp_deeply $vresult,
      {
        is_valid         => 0,
        errors           => { foo => re(qr/Validation failed for 'Int' with value "?abc"?/) },
        validated_params => {}
      };
};

subtest 'validates against the isa subtype' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'TimeStr' );

    my $vresult = $validator->validate( { foo => 'abc' } );

    cmp_deeply $vresult,
      {
        is_valid         => 0,
        errors           => { foo => re(qr/Validation failed for 'TimeStr' with value "?abc"?/) },
        validated_params => {}
      };
};

subtest 'validates against the isa alternatives' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Int|ArrayRef' );

    my $vresult = $validator->validate( { foo => 'abc' } );
    is $vresult->{is_valid}, 0;

    $vresult = $validator->validate( { foo => 1 } );
    is $vresult->{is_valid}, 1;

    $vresult = $validator->validate( { foo => [1] } );
    is $vresult->{is_valid}, 1;
};

subtest 'validates with coersion' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'BoolCheckbox' );

    my $vresult = $validator->validate( { foo => 'on' } );

    is $vresult->{validated_params}->{foo}, 1;
};

subtest 'validates with forcing value on error' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Int', default => 0, default_on_error => 1 );

    my $vresult = $validator->validate( { foo => 'on' } );

    is $vresult->{is_valid}, 1;
    is $vresult->{validated_params}->{foo}, 0;
};

subtest 'validates with more than one value in the array' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Str|ArrayRef' );

    my $vresult = $validator->validate( { foo => [ 1, 2, 3 ] } );

    is $vresult->{is_valid}, 1;
    my $foo = $vresult->{validated_params}->{foo};
    is scalar @$foo, 3;

};

subtest 'validates with arrayref of elements' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Int|ArrayRef[Int]' );

    my $vresult = $validator->validate( { foo => [ 1, 'abc', 3 ] } );

    is $vresult->{is_valid}, 0;
};

subtest 'validates coercion failures' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'ArrayJSON' );

    my $vresult = $validator->validate( { foo => 'abc' } );

    is $vresult->{is_valid}, 0;
    like $vresult->{errors}->{foo}, qr/Coercion failed/;
};

done_testing;

sub _build_validator {
    return Baseliner::Validator->new;
}
