use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::Fatal;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils;

use_ok 'Baseliner::CI';

subtest 'new: throws when no args' => sub {
    _setup();

    like exception { Baseliner::CI->new('123') }, qr/Master row not found for mid 123/;
};

subtest 'new: from numeric mid' => sub {
    _setup();

    mdb->master->insert( { mid => '123', collection => 'status', yaml => '---' } );

    my $ci = Baseliner::CI->new('123');

    ok $ci;
    isa_ok $ci, 'BaselinerX::CI::status';
};

subtest 'new: from compound mid' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', collection => 'status', yaml => '---' } );

    my $ci = Baseliner::CI->new('status-123');

    ok $ci;
    isa_ok $ci, 'BaselinerX::CI::status';
};

subtest 'new: from record' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', collection => 'status', yaml => '---' } );

    my $other_ci =
      Baseliner::CI->new( { mid => 'status-123', collection => 'status', ci_class => 'BaselinerX::CI::status' } );

    my $ci = Baseliner::CI->new($other_ci);

    ok $ci;
    isa_ok $ci, 'BaselinerX::CI::status';
};

subtest 'new: from another ci' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', collection => 'status', yaml => '---' } );

    my $other_ci = Baseliner::CI->new('status-123');

    my $ci = Baseliner::CI->new($other_ci);

    ok $ci;
    isa_ok $ci, 'BaselinerX::CI::status';
};

subtest 'new: from name' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', name => 'status', collection => 'status', yaml => '---' } );

    my $ci = Baseliner::CI->new('name:status');

    ok $ci;
    isa_ok $ci, 'BaselinerX::CI::status';
};

subtest 'new: from moniker' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', name => 'status', moniker => 'Status', collection => 'status', yaml => '---' } );

    my $ci = Baseliner::CI->new('moniker:Status');

    ok $ci;
    isa_ok $ci, 'BaselinerX::CI::status';
};

#subtest 'new: from array' => sub {
#    _setup();
#
#    mdb->master->insert( { mid => 'status-123', collection => 'status', yaml => '---' } );
#    mdb->master->insert( { mid => 'status-321', collection => 'status', yaml => '---' } );
#
#    my @cis = Baseliner::CI->new(['status-123', 'status-321']);
#
#    is @cis, 2;
#};

subtest 'new: from search' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', name => 'Status1', collection => 'status', yaml => '---' } );
    mdb->master->insert( { mid => 'status-321', name => 'Status2', collection => 'status', yaml => '---' } );

    my $ci = Baseliner::CI->new(name => 'Status1');

    ok $ci;
    is $ci->mid, 'status-123';
};

subtest 'new: from search returns undef when not found' => sub {
    _setup();

    mdb->master->insert( { mid => 'status-123', name => 'Status1', collection => 'status', yaml => '---' } );

    my $ci = Baseliner::CI->new(name => 'Unknown');

    ok !defined $ci;
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;
}
