use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestEnv;

TestEnv->setup;

use Baseliner::Core::Registry ':dsl';

subtest 'registers with dsl' => sub {
    _setup();

    register key => { foo => 'bar' };

    my $registry = _registry();

    ok $registry->get('key');
    is $registry->get('key')->foo, 'bar';
};

subtest 'registers with method' => sub {
    _setup();

    _registry()->add( 'main', key => { foo => 'bar' } );

    my $registry = _registry();

    ok $registry->get('key');
    is $registry->get('key')->foo, 'bar';
};

subtest 'registers class with dsl' => sub {
    _setup();

    register_class key => 'ClassName';

    my $registry = _registry();

    is $registry->classes->{key}, 'ClassName';
};

subtest 'registers with method' => sub {
    _setup();

    _registry()->add_class( undef, key => 'ClassName' );

    my $registry = _registry();

    is $registry->classes->{key}, 'ClassName';
};

sub _registry {
    return Baseliner::Core::Registry->new;
}

sub _setup {
    Baseliner::Core::Registry->clear;

    Baseliner::Core::Registry->add_class(undef, 'key' => 'TestRegistry');
}

done_testing;

sub new {
    my $class = shift;
    my %params = @_ == 1 ? %{ $_[0] } : @_;

    my $self = {%params};
    bless $self, $class;

    return $self;
}
sub foo { shift->{foo} }

package TestRegistry;
use Moo;
BEGIN { has foo => ( is => 'ro' ) }
