use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup }

use_ok 'Baseliner::Comm::Email';

subtest 'builds correct email' => sub {
    my $comm = _build_comm();

    $comm->send( from => 'me@localhost', subject => 'Hi there!', body => 'Hello', to => 'you@localhost' );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/To: you\@localhost/;
};

subtest 'builds correct email with unicode' => sub {
    my $comm = _build_comm();

    $comm->send(
        from    => 'me@localhost',
        subject => 'Привет!',
        body    => 'Как дела?',
        to      => 'you@localhost'
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr#Subject: \Q=?utf-8?B?0J/RgNC40LLQtdGCIQ==?=\E#;
};

sub _build_comm {
    my $comm = Baseliner::Comm::Email->new(@_);

    $comm = Test::MonkeyMock->new($comm);
    $comm->mock( _init_connection    => sub { } );
    $comm->mock( _send               => sub { } );
    $comm->mock( _path_to_about_icon => sub { 'root/static/images/about.png' } );

    return $comm;
}

done_testing;
