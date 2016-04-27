use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use BaselinerX::Type::Menu;
use BaselinerX::Type::Service;

use_ok 'Clarive::Code::JS';

subtest 'cla.register: registers a menu' => sub {
    _setup();

    Baseliner::Core::Registry->add_class( undef, 'menu' => 'BaselinerX::Type::Menu' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var reg = require('cla/reg');
        reg.register('menu.test',{ name: 'FooMenu' });
    }
    );
    is( Baseliner::Core::Registry->get('menu.test')->name, 'FooMenu' );
};

subtest 'launch: registers and launches a service' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var reg = require('cla/reg');
        reg.register('service.test',{
            name: 'FooService',
            handler: function(){ return 99 }
        });
        reg.launch('service.test');
    }
    );

    is $ret, 99;
    is( Baseliner::Core::Registry->get('service.test')->name, 'FooService' );
};

subtest 'launch: launches a service with stash' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var reg = require('cla/reg');
        reg.register('service.test',{
            name: 'FooService',
            data : { foo: '123'},
            handler: function(config) { return config.stash() }
        });
        reg.launch('service.test', {stash: {foo: 'bar'}});
    }
    );

    is $ret->{foo}, 'bar';
};

subtest 'launch: launches a service with stash from outside' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var reg = require('cla/reg');
        reg.register('service.test',{
            name: 'FooService',
            data : { foo: '123'},
            handler: function(config) { return config.stash() }
        });
        reg.launch('service.test');
    }, {foo => 'bar'}
    );

    is $ret->{foo}, 'bar';
};

done_testing;

sub _setup {
    TestUtils->setup_registry('BaselinerX::Type::Service');
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
