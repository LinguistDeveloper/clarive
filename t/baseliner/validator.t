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

    $validator->add_field( 'foo', rules => 'pos_int', default => '' );

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

subtest 'validates against the rule' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', rules => 'test' );

    my $vresult = $validator->validate( { foo => 'bar' } );

    is_deeply $vresult, { is_valid => 0, errors => { foo => 'INVALID' }, validated_params => {} };
};

subtest 'returns modified value' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', rules => 'test' );

    my $vresult = $validator->validate( { foo => '123' } );

    is_deeply $vresult, { is_valid => 1, errors => {}, validated_params => { foo => '321' } };
};

subtest 'validates against the rule with args' => sub {
    my $validator = _build_validator();

    $validator->add_field( 'foo', rules => { 'test' => { len => 2 } } );

    my $vresult = $validator->validate( { foo => '123' } );

    is_deeply $vresult, { is_valid => 0, errors => { foo => 'INVALID' }, validated_params => {} };
};

done_testing;

sub _build_validator {
    return Baseliner::Validator->new;
}

package Baseliner::Validator::test;
use Moo;
BEGIN { extends 'Baseliner::Validator::Base' }

BEGIN { has len => ( is => 'ro' ) }

sub validate {
    my $self = shift;
    my ($foo) = @_;

    return $self->_build_not_valid unless $foo =~ m/^\d+$/;
    return $self->_build_not_valid if $self->len && length($foo) > $self->len;
    return $self->_build_valid( value => join '', reverse split //, $foo );
}

1;
