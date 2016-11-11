use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use POSIX ":sys_wait_h";
use Time::HiRes qw(usleep);

use_ok 'Baseliner::Cache';

subtest 'set: sets cache value' => sub {
    _setup();

    my $cache = _build_cache();

    $cache->set( 'foo', 'bar' );

    is( $cache->get('foo'), 'bar' );
};

subtest 'set: works around mongo bug when inserting values in parallel' => sub {
    _setup();

    my $cache = _build_cache();

    for ( 1 .. 10 ) {
        my $key = 'foo' . $_;

        $cache->remove($key);

        my %pids;
        for ( 1 .. 5 ) {
            my $pid = fork;

            if ($pid) {
                $pids{$pid}++;
            }
            else {
                eval { mdb->disconnect };

                usleep 10_000 * int( rand(10) );

                $cache->set( $key, 'bar' );

                exit 0;
            }
        }

        my $last;
        while (%pids) {
            my $pid = waitpid(-1, WNOHANG);
            next if $pid < 0 || $pid == 0;

            delete $pids{$pid};

            $last = $?;

            my $diag;
            if ( $? == -1 ) {
                $diag = "failed to execute: $!";
            }
            elsif ( $? & 127 ) {
                $diag = sprintf "child died with signal %d, %s coredump", ( $? & 127 ),
                  ( $? & 128 ) ? 'with' : 'without';
            }
            elsif ($?) {
                $diag = sprintf "child exited with value %d", $? >> 8;
            }

            ok !$?, $diag;

        }

        is( $cache->get($key), 'bar' );

        last if $last;
    }
};

done_testing;

sub _setup {
    _build_cache()->clear;
}

sub _build_cache {
    Baseliner::Cache->new;
}
