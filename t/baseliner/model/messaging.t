use strict;
use warnings;

use Test::More;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestSetup;

use_ok 'Baseliner::Model::Messaging';

subtest 'notify: adds the attach path in message' => sub {
    _setup();

    my $model = _build_model();

    my $output = $model->notify( carrier => 'email', attach => 'tmp/foo', subject => 'bar' );
    my @msg = mdb->message->find->all;

    is $msg[0]->{attach}, 'tmp/foo';
};

subtest 'notify: adds the new filename in message' => sub {
    _setup();

    my $model = _build_model();

    my $output = $model->notify( carrier => 'email', attach => 'tmp/foo', subject => 'bar', attach_filename => 'bar' );
    my @msg = mdb->message->find->all;

    is $msg[0]->{attach_filename}, 'bar';
};

subtest 'create: adds the filename in the message' => sub {
    _setup();

    my $model = _build_model();

    my $output = $model->create( carrier => 'email', can_attach => '1', subject => 'bar', attach_filename => 'bar' );
    my @msg = mdb->message->find->all;

    is $msg[0]->{attach_filename}, 'bar';
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
    TestUtils->cleanup_cis;
    mdb->message->drop;
}

sub _build_model {
    return Baseliner::Model::Messaging->new();
}
