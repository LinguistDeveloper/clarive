use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use BaselinerX::CI::status;

use_ok 'Clarive::Code::JS';

subtest 'ci.getClass: throws when no class passed' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        var ci = require("cla/ci");
        ci.getClass(); }
          )
    }, qr/Missing parameter `classname`/;
};

subtest 'ci.getClass: throws when unknown class passed' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        var ci = require("cla/ci");
        ci.getClass('Unknown'); }
          )
    }, qr/Could not find a CI class named `Unknown`/;
};

subtest 'ci.build: throws when no class passed' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        var ci = require("cla/ci");
        ci.build(); }
          )
    }, qr/Missing parameter `classname`/;
};

subtest 'ci.build: throws when unknown class passed' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        var ci = require("cla/ci");
        ci.build('Unknown'); }
          )
    }, qr/Could not find a CI class named `Unknown`/;
};

subtest 'ci.build: builds an object with default values' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name", {
            has: { value: { is:'rw', isa:'Str', default: 'xxx' } },
        });

        var obj = ci.build("$class_name");
        obj.value();
    }
    );

    is $ret, 'xxx';
};

subtest 'ci.build: builds an object with custom values' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name", {
            has: { value: { is:'rw', isa:'Str', default: 'xxx' } },
        });

        var obj = ci.build("$class_name", {value: 'yyy'});
        obj.value();
    }
    );

    is $ret, 'yyy';
};

subtest 'ci.createClass: throws when no class passed' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        var ci = require("cla/ci");
        ci.createClass(); }
          )
    }, qr/Missing parameter `classname`/;
};

subtest 'ci.load: loads ci from database' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(
        q{
        var ci = require("cla/ci");
        var obj = ci.load('123'); obj.name()}
    );

    is $ret, 'New';
};

subtest 'dispatches to CI attribute method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status'); (new Status({'mid': '123'})).icon()}
    );

    like $ret, qr{static/images};
};

subtest 'dispatches to CI method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(
        q{
        var ci = require("cla/ci");
        var obj = ci.load('123');
        obj.delete();
    }
    );

    ok !mdb->master->find_one( { mid => '123' } );
};

subtest 'dispatches CI set method with argument' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(
        q{
        var ci = require("cla/ci");
        var obj = ci.load('123');
        obj.name('joe');
        obj.name();
    }
    );

    is $ret, 'joe';
};

subtest 'dispatches to CI method returning object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my @ret = $code->eval_code(
        q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status');
        var obj = (new Status).searchCis(); obj.mid()}
    );

    is scalar @ret, 1;
    is $ret[0], '123';
};

subtest 'ci.createClass: throws when class already exists' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code(
            q{
        var ci = require("cla/ci");
        ci.createClass('status'); }
          )
    }, qr/Class `status` already exists/;
};

subtest 'ci.createClass: creates a new class' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name");

        var obj = ci.build("$class_name", { name: 'bob' });
        obj.name();
    }
    );

    is $ret, 'bob';
};

subtest 'ci.createClass: creates a new class with default icon' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name");

        var obj = ci.build("$class_name");
        obj.icon();
    }
    );

    like $ret, qr/ci.svg/;
};

subtest 'ci.createClass: creates a new class with custom icon' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name", {
            icon: 'my-icon.svg'
        });

        var obj = ci.build("$class_name");
        obj.icon();
    }
    );

    is $ret, 'my-icon.svg';
};

subtest 'ci.createClass: creates a new class with superclass' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name",{
            superclasses: ['Variable']
        });
        var obj = ci.build('$class_name', { name: 'bob' });

        obj.name();
    }
    );

    is $ret, 'bob';
};

subtest 'ci.createClass: creates a new class with roles' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name",{
            roles: ['Item']
        });
        var obj = ci.build('$class_name', { name: 'bob' });

        obj.meta().doesRole('Baseliner::Role::CI::Item');
    }
    );

    ok $ret;
};

subtest 'ci.createClass: creates a new class with attributes' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name",{
            has: { password: { is:'rw', isa:'Str', default: 'xxx' } },
        });
        var obj = ci.build('$class_name', { name: 'bob' });

        obj.password();
    }
    );

    is $ret, 'xxx';
};

subtest 'ci.createClass: creates a new class with methods' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $class_name = 'JsCiTest' . _random_string();

    my $ret = $code->eval_code(
        qq{
        var ci = require('cla/ci');
        ci.createClass("$class_name", {
            has: { attr: { is:'rw', isa:'Str' } },
            methods: {
                connect: function(arg) { return this.attr() + ' ' + arg + '=123' }
            }
        });
        var obj = ci.build('$class_name', {attr: 'attr'});

        obj.connect('arg');
    }
    );

    is $ret, 'attr arg=123';
};

subtest 'ci.isLoaded: returns true when class is loaded' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    ok $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.isLoaded('status');
    }
    );
};

subtest 'ci.isLoaded: returns false when class is not loaded' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    ok !$code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.isLoaded('Unknown');
    }
    );
};

subtest 'ci.listClasses: lists ci classes' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.listClasses();
    }
    );

    ok grep { $_ eq 'Status' } @$ret;
};

subtest 'ci.listClasses: lists ci classes filtering by role' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.listClasses('Baseliner::Role::CI::Internal');
    }
    );

    is_deeply $ret, ['Status'];
};

subtest 'ci.find: finds any ci document' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.find({mid: '123'}).next().name;
    }
    );

    is $ret, 'New';
};

subtest 'ci.find: finds ci document of specific class' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.find('status', {mid: '123'}).next().name;
    }
    );

    is $ret, 'New';
};

subtest 'ci.findCi: finds any ci' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.findCi({mid: '123'}).next().name();
    }
    );

    is $ret, 'New';
};

subtest 'ci.findCi: finds ci of specific class' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');

        ci.findCi('status', {mid: '123'}).next().name();
    }
    );

    is $ret, 'New';
};

subtest 'ci.findOne: finds any ci' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.findOne({mid: '123'}).name;
    }
    );

    is $ret, 'New';
};

subtest 'ci.findOne: finds ci of specific class' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.findOne('status', {mid: '123'}).name;
    }
    );

    is $ret, 'New';
};

subtest 'ci.findOneCi: finds any ci' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.findOneCi({mid: '123'}).name();
    }
    );

    is $ret, 'New';
};

subtest 'ci.findOneCi: returns undefined when cannot find ci' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.findOneCi({mid: '123'});
    }
    );

    ok !defined $ret;
};

subtest 'ci.findOneCi: finds ci of specific class' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.findOneCi('status', {mid: '123'}).name();
    }
    );

    is $ret, 'New';
};

subtest 'ci.delete: deletes ci' => sub {
    _setup();

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(
        q{
        var ci = require('cla/ci');
        ci.delete('123');
    }
    );

    is $ret, 1;
    ok exception { ci->new('123') }, qr/Master row not found for mid 123/;
};

done_testing;

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Service',
        'BaselinerX::Type::Statement',
        'BaselinerX::CI',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis;

    mdb->rule->drop;

    mdb->test_collection->drop;
}

sub _random_string {
    my $s = '';
    $s .= int( rand(1000) ) for 1 .. 12;
    return $s;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
