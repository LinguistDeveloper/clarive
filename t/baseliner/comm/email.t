use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::MonkeyMock;
use TestEnv;
BEGIN { TestEnv->setup }

use_ok 'Baseliner::Comm::Email';

subtest 'send: builds correct email' => sub {
    my $comm = _build_comm();

    $comm->send( from => 'me@localhost', subject => 'Hi there!', body => 'Hello', to => 'you@localhost' );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/To: you\@localhost/;
};

subtest 'send: builds correct email with several recipients' => sub {
    my $comm = _build_comm();

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost,foo@bar'
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/To: you\@localhost,foo\@bar/;
};

subtest 'send: builds correct email with unicode' => sub {
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

subtest 'group_queue: groups queue' => sub {
    _setup();

    mdb->message->insert(
        {
            active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'another@bar.com',
                }
            ],
        }
    );

    my $comm = _build_comm();

    my %email = $comm->group_queue( { max_message_size => 1024 } );

    my ($key)   = keys %email;
    my ($value) = values %email;

    like $key, qr/^[a-f0-9]+$/;

    cmp_deeply $value,
      {
        body    => 'hi there!',
        from    => 'from@me.com',
        to      => [ 'clarive@bar.com', 'another@bar.com' ],
        subject => 'Subject',
        attach  => {
            'content_type' => undef,
            'filename'     => undef,
            'data'         => undef
        },
        id_list => [ re(qr/^\d+$/), re(qr/^\d+$/) ],
      };
};

subtest 'process_queue: sends emails' => sub {
    _setup();

    mdb->message->insert(
        {
            active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'another@bar.com',
                }
            ],
        }
    );

    my $comm = _build_comm();

    my $c = _mock_c();

    $comm->process_queue($c, {max_message_size => 1024});

    my ($msg) = $comm->mocked_call_args('_send');

    $msg = $msg->as_string;

    like $msg, qr/To: clarive\@bar\.com,another\@bar\.com/;
    like $msg, qr/From: from\@me\.com/;
    like $msg, qr/Subject: =\?utf-8\?B\?U3ViamVjdA==\?=/;
};

subtest 'process_queue: skips unresolved adresses' => sub {
    _setup();

    mdb->message->insert(
        {
            active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'unknown user',
                },
                {
                    active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'root@bar.com',
                },
            ],
        }
    );

    my $comm = _build_comm();

    my $c = _mock_c();

    $comm->process_queue($c, {max_message_size => 1024});

    my ($msg) = $comm->mocked_call_args('_send');

    $msg = $msg->as_string;

    like $msg, qr/To: clarive\@bar\.com,root\@bar\.com/;
};

sub _mock_c {
    my $c = Test::MonkeyMock->new;
    $c->mock( config => sub { {} } );
    return $c;
}

sub _build_comm {
    my $comm = Baseliner::Comm::Email->new(@_);

    $comm = Test::MonkeyMock->new($comm);
    $comm->mock( _init_connection    => sub { } );
    $comm->mock( _send               => sub { } );
    $comm->mock( _path_to_about_icon => sub { 'root/static/images/about.png' } );

    return $comm;
}

sub _setup {
    mdb->message->drop;
}

done_testing;
