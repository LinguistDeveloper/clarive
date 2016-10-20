use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

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

done_testing;

sub _setup {
    mdb->master_seq->drop;
    mdb->index_all('master_seq');
}

sub _build_mdb {
    Baseliner::Mongo->new;
}
