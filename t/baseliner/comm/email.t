use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MonkeyMock;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils qw(mock_time);

use File::Basename qw(basename);
use Scalar::Util ();
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

subtest 'send: does not fail when message send fails' => sub {
    my $msg = Test::MonkeyMock->new;
    $msg->mock( send   => sub { die 'error' } );
    $msg->mock( attach => sub { } );

    my $comm = _build_comm(msg => $msg);
    $comm->mock( _build_msg => sub { $msg } );

    my $result = $comm->send(
        from    => 'me@localhost',
        to      => 'you@localhost',
        subject => 'hi',
        body    => 'body',
    );
    is $result, undef;
};

subtest 'group_queue: groups queue' => sub {
    _setup();

    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {   active        => '1',
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
            'path'         => undef
        },
        id_list => [ re(qr/^\d+$/), re(qr/^\d+$/) ],
        };
};

subtest 'process_queue: sends emails' => sub {
    _setup();

    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {   active        => '1',
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

    $comm->process_queue( $c, { max_message_size => 1024 } );

    my ($msg) = $comm->mocked_call_args('_send');

    $msg = $msg->as_string;

    like $msg, qr/To: clarive\@bar\.com,another\@bar\.com/;
    like $msg, qr/From: from\@me\.com/;
    like $msg, qr/Subject: =\?utf-8\?B\?U3ViamVjdA==\?=/;
};

subtest 'process_queue: skips unresolved addresses' => sub {
    _setup();

    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'unknown user',
                },
                {   active        => '1',
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

    $comm->process_queue( $c, { max_message_size => 1024 } );

    my ($msg) = $comm->mocked_call_args('_send');

    $msg = $msg->as_string;

    like $msg, qr/To: clarive\@bar\.com,root\@bar\.com/;
};

subtest 'process_queue: builds emails without attachment if size is too big' => sub {
    _setup();

    my $tmp      = tempdir();
    my $filename = "$tmp/foo";
    TestUtils->write_file( 'foo', $filename );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 0 );
    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            attach  => $filename,
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {   active        => '1',
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

    $comm->process_queue( $c, { max_message_size => 1024 } );

    my ($msg) = $comm->mocked_call_args('_send');

    $msg = $msg->as_string;

    unlike $msg, qr/filename="foo"/;
};

subtest 'process_queue: builds emails without attachment if not exist' => sub {
    _setup();

    my $tmp      = tempdir();
    my $filename = "$tmp/foo";
    TestUtils->write_file( 'foo', $filename );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );
    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            attach  => '/unknown/file',
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                },
                {   active        => '1',
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

    $comm->process_queue( $c, { max_message_size => 1024 } );

    my ($msg) = $comm->mocked_call_args('_send');

    $msg = $msg->as_string;

    unlike $msg, qr/filename="file"/;
};

subtest 'process_queue: message is marked as received when send is successful' => sub {
    _setup();

    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                }
            ],
        }
    );

    my $c = _mock_c();

    my $comm = _build_comm();
    $comm = Test::MonkeyMock->new($comm);
    $comm->mock( _send => sub { return '1' } );

    mock_time '2016-01-01 00:00:00', sub {
        $comm->process_queue( $c, { max_message_size => 1024 } );
    };
    my $msg = mdb->message->find_one;

    is $msg->{queue}[0]->{received}, '2016-01-01 00:00:00';
};

subtest 'process_queue: message is not marked as received when send failed' => sub {
    _setup();

    mdb->message->insert(
        {   active  => '1',
            sender  => 'from@me.com',
            subject => 'Subject',
            body    => "hi there!",
            queue   => [
                {   active        => '1',
                    attempts      => '0',
                    carrier       => 'email',
                    carrier_param => 'to',
                    id            => 356247,
                    username      => 'clarive@bar.com',
                }
            ],
        }
    );
    my $c = _mock_c();

    my $comm = _build_comm();
    $comm = Test::MonkeyMock->new($comm);
    $comm->mock( _send => sub { } );

    $comm->process_queue( $c, { max_message_size => 1024 } );

    my $msg = mdb->message->find_one;

    is $msg->{queue}[0]->{received}, undef;
};

subtest 'send: sends attachments if the path is a file' => sub {
    _setup();

    my $tmp      = tempdir();
    my $filename = "$tmp/foo";
    my $comm     = _build_comm();

    TestUtils->write_file( 'foo', $filename );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $filename } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/filename="foo"/;
};

subtest 'send: builds correct email attaching a directory' => sub {
    _setup();

    my $tmp  = tempdir();
    my $dir  = basename($tmp);
    my $comm = _build_comm();
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $tmp } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/filename="$dir.zip"/;
};

subtest 'send: renames the attachment' => sub {
    _setup();

    my $tmp      = tempdir();
    my $filename = "$tmp/foo";
    my $comm     = _build_comm();

    TestUtils->write_file( 'foo', $filename );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $filename, filename => 'bar' } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/filename="bar"/;
};

subtest 'send: adds extension zip if the attachment has not extension in filename' => sub {
  _setup();

    my $tmp  = tempdir();
    my $dir  = basename($tmp);
    my $comm = _build_comm();
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $tmp, filename => 'bar' } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $msg_string = $msg->as_string;

    like $msg_string, qr/filename="bar.zip"/;
};

subtest 'send: throws an error when attachment is not a hash' => sub {
    _setup();

    my $tmp      = tempdir();
    my $filename = "$tmp/foo";
    my $comm     = _build_comm();

    like exception {
        $comm->send(
            from    => 'me@localhost',
            subject => 'Hi there!',
            body    => 'Hello',
            to      => 'you@localhost,foo@bar',
            attach  => [ '2', '3' ]

        );
    }, qr/Error: attachment is not a hash but a 2/;
};

subtest 'send: sends directories using a temporal filehandle' => sub {
  _setup();

    my $tmp  = tempdir();
    my $dir  = basename($tmp);
    my $comm = _build_comm();
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $tmp } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    my $fh = $msg->{Parts}[2]->{FH};
    my $reftype = Scalar::Util::reftype($fh);

    ok ($reftype eq 'IO' or $reftype eq 'GLOB' && *{$fh}{IO});
};

subtest 'send: adds content_type to the attachment when the path is a directory' => sub {
    _setup();

    my $tmp  = tempdir();
    my $dir  = basename($tmp);
    my $comm = _build_comm();
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $tmp } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    is $msg->{Parts}[2]->{Attrs}->{'content-type'}, 'application/zip';
};

subtest 'send: adds content_type to the attachment when the path is a text file' => sub {
    _setup();

    my $tmp      = tempdir();
    my $filename = "$tmp/foo";
    my $comm     = _build_comm();

    TestUtils->write_file( 'foo', $filename );
    BaselinerX::Type::Model::ConfigStore->new->set( key => 'config.comm.email.max_attach_size', value => 1024 * 1024 );

    $comm->send(
        from    => 'me@localhost',
        subject => 'Hi there!',
        body    => 'Hello',
        to      => 'you@localhost',
        attach  => [ { path => $filename } ]
    );

    my ($msg) = $comm->mocked_call_args('_send');

    is $msg->{Parts}[2]->{Attrs}->{'content-type'}, 'text/plain';
};

sub _mock_c {
    my $c = Test::MonkeyMock->new;
    $c->mock( config => sub { {} } );
    return $c;
}

sub _build_comm {
    my (%params) = @_;

    my $comm = Baseliner::Comm::Email->new(%params);

    $comm = Test::MonkeyMock->new($comm);
    $comm->mock( _init_connection    => sub { } );
    $comm->mock( _send               => sub { } );
    $comm->mock( _path_to_about_icon => sub { 'root/static/images/logo/about_email.jpg' } );

    return $comm;
}

sub _setup {
    mdb->message->drop;
    mdb->config->drop;
}

done_testing;
