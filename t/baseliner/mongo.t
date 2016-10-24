use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Time::HiRes qw(usleep);
use POSIX ":sys_wait_h";

use_ok 'Baseliner::Mongo';

subtest 'seq: creates autoincrementing sequence' => sub {
    _setup();

    my $mdb = _build_mdb();

    my @seq;
    push @seq, $mdb->seq('col') for 1 .. 5;

    is_deeply \@seq, [ 1 .. 5 ];
};

subtest 'seq: sets sequence' => sub {
    _setup();

    my $mdb = _build_mdb();

    is $mdb->seq( 'col', 5 ), 5;
    is $mdb->seq('col'), 6;
};

subtest 'seq: sets sequence in parallel' => sub {
    _setup();

    my %pids;

    my $forks = 5;

    for ( 1 .. $forks ) {
        my $pid = fork;

        if ($pid) {
            $pids{$pid}++;
        }
        else {
            my $mdb = _build_mdb();

            usleep(10_000 * int(rand(10)));

            $mdb->seq('col');

            exit 0;
        }
    }

    while (%pids) {
        my $pid = waitpid( -1, WNOHANG );
        next if $pid < 0 || $pid == 0;

        delete $pids{$pid};
    }

    my $mdb = _build_mdb();

    is $mdb->seq('col'), $forks + 1;
};

done_testing;

sub _setup {
    mdb->master_seq->drop;
    mdb->index_all('master_seq');
}

sub _build_mdb {
    Baseliner::Mongo->new;
}
