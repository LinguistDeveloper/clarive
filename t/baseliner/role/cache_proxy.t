use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestEnv;

TestEnv->setup;

sub Clarive::config { {} }

use Clarive::cache;

subtest 'works transparently when cache is off' => sub {
    local $Clarive::_no_cache   = 1;
    local $Baseliner::_no_cache = 1;

    my $object = TestCachee->new;

    is $object->foo, 'bar';
};

subtest 'works transparently with cache' => sub {
    no warnings 'redefine';

    local $Clarive::_no_cache   = 0;
    local $Baseliner::_no_cache = 0;

    my $store = {};
    local *Clarive::config = sub {
        {
            cache        => 'memory',
            cache_config => {
                datastore => $store
            }
        };
    };

    cache->setup;

    my $object = TestCachee->new;

    is $object->foo('arg'), 'bar';

    is $object->called, 1;

    ok $store->{Default}->{'{"d":"test","p":{"foo":"arg"}}'};

    is $object->foo('arg'), 'bar';
    is $object->called, 1;
};

subtest 'invalidates cache on different args' => sub {
    no warnings 'redefine';

    local $Clarive::_no_cache   = 0;
    local $Baseliner::_no_cache = 0;

    my $store = {};
    local *Clarive::config = sub {
        {
            cache        => 'memory',
            cache_config => {
                datastore => $store
            }
        };
    };

    cache->setup;

    my $object = TestCachee->new;

    is $object->foo('arg'), 'bar';
    is $object->called, 1;

    is $object->foo('arg2'), 'bar';
    is $object->called, 2;
};

done_testing;

package TestCachee;
use Moose;

sub foo {
    my $self = shift;

    $self->called( $self->called + 1 );

    return 'bar';
}

BEGIN {
    has called => ( is => 'rw', default => 0 );

    with 'Baseliner::Role::CacheProxy' => {
        methods      => [qw/foo/],
        cache_key_cb => sub {
            shift;
            my ($foo) = @_;

            { d => 'test', p => { foo => $foo } };
        }
    };
}

1;
