use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;

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

    is_deeply $vresult,
      { is_valid => 0, errors => { foo => q/Validation failed for 'Int' with value abc/ }, validated_params => {} };
};

subtest 'validates against the isa subtype' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'TimeStr' );

    my $vresult = $validator->validate( { foo => 'abc' } );

    is_deeply $vresult,
      { is_valid => 0, errors => { foo => q/Validation failed for 'TimeStr' with value abc/ }, validated_params => {} };
};

subtest 'validates with coersion' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'BoolCheckbox' );

    my $vresult = $validator->validate( { foo => 'on' } );

    is $vresult->{validated_params}->{foo}, 1;
};

subtest 'validates with forcing value on error' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', isa => 'Int', default => 5, default_on_error => 1 );

    my $vresult = $validator->validate( { foo => 'on' } );

    is $vresult->{is_valid}, 1;
    is $vresult->{validated_params}->{foo}, 5;
};

done_testing;

sub _build_validator {
    return Baseliner::Validator->new;
}

1;
