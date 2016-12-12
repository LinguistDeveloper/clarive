use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code::JS';
use_ok 'Clarive::Code::JSModules::web';

subtest 'agent: returns functional web agent' => sub {
    _setup();

    _mock_build_ua( response => { success => 1, content => 'hello' } );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var web = require("cla/web");
        var agent = web.agent();

        agent.get('http://foo.bar');
EOF

    ok $ret->{success};
};

subtest 'agent: builds get request' => sub {
    _setup();

    my $mock = _mock_build_ua( response => { success => 1, content => 'hello' } );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var web = require("cla/web");
        var agent = web.agent();

        agent.get('http://foo.bar');
EOF

    my ($url) = $mock->mocked_call_args('get');
    is $url, 'http://foo.bar';
};

subtest 'agent: builds post request' => sub {
    _setup();

    my $mock = _mock_build_ua( response => { success => 1, content => 'hello' } );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var web = require("cla/web");
        var agent = web.agent();

        agent.post('http://foo.bar', {content: "hello"});
EOF

    my ( $url, $options ) = $mock->mocked_call_args('post');
    is $url, 'http://foo.bar';
    is_deeply $options, { content => 'hello' };
};

subtest 'agent: builds postForm request' => sub {
    _setup();

    my $mock = _mock_build_ua( response => { success => 1, content => 'hello' } );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var web = require("cla/web");
        var agent = web.agent();

        agent.postForm('http://foo.bar', {foo: "bar"});
EOF

    my ( $url, $options ) = $mock->mocked_call_args('post_form');
    is $url, 'http://foo.bar';
    is_deeply $options, { foo => 'bar' };
};

subtest 'agent: builds generic request' => sub {
    _setup();

    my $mock = _mock_build_ua( response => { success => 1, content => 'hello' } );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var web = require("cla/web");
        var agent = web.agent();

        agent.request('GET', 'http://foo.bar');
EOF

    my ( $method, $url ) = $mock->mocked_call_args('request');
    is $method, 'GET';
    is $url,    'http://foo.bar';
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _mock_build_ua {
    my (%params) = @_;

    my $mock = _mock_ua(%params);

    no warnings 'redefine';
    no strict 'refs';
    *{"Clarive::Code::JSModules::web::_build_ua"} = sub { $mock };

    return $mock;
}

sub _mock_ua {
    my (%params) = @_;

    my $mock = Test::MonkeyMock->new;
    $mock->mock( get       => sub { $params{response} } );
    $mock->mock( post      => sub { $params{response} } );
    $mock->mock( post_form => sub { $params{response} } );
    $mock->mock( request   => sub { $params{response} } );

    return $mock;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
