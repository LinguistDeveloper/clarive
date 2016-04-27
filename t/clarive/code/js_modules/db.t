use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Try::Tiny;
use Baseliner::Utils qw(_slurp);
use BaselinerX::CI::generic_server;
use BaselinerX::CI::status;
use BaselinerX::Type::Menu;
use BaselinerX::Type::Service;

use_ok 'Clarive::Code::JS';

subtest 'db.getDatabase: connects to db' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var database = db.getDatabase('acmetest');

        database.getCollection('test_collection').insert({'foo':'bar'});
EOF

    my $doc = mdb->test_collection->find_one( { foo => 'bar' } );

    is $doc->{foo}, 'bar';
};

subtest 'db.seq: returns sequence' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");

        var ret = [];
        ret.push(db.seq('test_collection'));
        ret.push(db.seq('test_collection'));
        ret;
EOF

    is_deeply $ret, [1, 2];
};

subtest 'db.insert: inserts object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
EOF

    my $doc = mdb->test_collection->find_one( { foo => 'bar' } );

    is $doc->{foo}, 'bar';
};

subtest 'db.findOne: finds one object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        col.findOne({'foo':'bar'});
EOF

    is $ret->{foo}, 'bar';
};

subtest 'db.find: returns cursor with hasNext' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();

        cursor.hasNext();
EOF

    is $ret, 1;
};

subtest 'db.find: returns cursor with count' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();

        cursor.count();
EOF

    is $ret, 2;
};

subtest 'db.find: finds with limit' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();
        cursor.limit(1);

        cursor.count();
EOF

    is $ret, 2;
};

subtest 'db.find: finds with limit and applySkipLimit flag' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();
        cursor.limit(1);

        cursor.count({applySkipLimit:true});
EOF

    is $ret, 1;
};

subtest 'db.find: returns chainable cursor' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        db.getCollection('master_doc')
            .find()
            .fields({ bl: true, bls: true, _id: 1 })
            .limit(100)
            .all();
EOF

    is ref $ret, 'ARRAY';
};

subtest 'db.find: returns empty result from all' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        db.getCollection('test_collection').find().all();
EOF

    is_deeply $ret, [];
};

subtest 'db.find: returns cursor with next' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();
        cursor.skip(1);

        cursor.next();
EOF

    is $ret->{foo}, 'baz';
};

subtest 'db.find: finds with sorting' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':2});
        col.insert({'foo':1});

        var cursor = col.find();
        cursor.sort({'foo':1});

        cursor.next();
EOF

    is $ret->{foo}, 1;
};

subtest 'db.find: returns cursor with forEach' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();

        var results = [];
        cursor.forEach(function(entry) {
            results.push(entry);
        });

        results;
EOF

    is scalar @$ret, 2;
    is $ret->[0]->{foo}, 'bar';
    is $ret->[1]->{foo}, 'baz';
};

subtest 'db.find: ignores forEach when not a function' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        var cursor = col.find();

        var results = [];
        cursor.forEach(123);

        results;
EOF

    is scalar @$ret, 0;
};

subtest 'db.update: updates object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        col.update({'foo':'bar'}, {'foo':'bar2'});
EOF

    my $doc = mdb->test_collection->find_one( { foo => 'bar2' } );

    ok $doc;
};

subtest 'db.remove: removes object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.insert({'foo':'baz'});

        col.remove({'foo':'bar'});
EOF

    is $ret->{ok}, 1;
    my $doc = mdb->test_collection->find_one( { foo => 'bar' } );

    ok !$doc;
};

subtest 'db.drop: drops collection' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        var db = require("cla/db");
        var col = db.getCollection('test_collection');

        col.insert({'foo':'bar'});
        col.drop();
EOF

    my $cnt = mdb->test_collection->count;
    is $cnt, 0;
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    mdb->master_seq->drop;
    mdb->test_collection->drop;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
