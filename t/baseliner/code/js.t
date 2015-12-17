use strict;
use warnings;

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use_ok 'Baseliner::Code::JS';

subtest 'evals js' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( '1 + 1', {} );

    is $ret, 2;
};

subtest 'dispatches to parseVars' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{Cla.parseVars('${my_var}')}, { my_var => 'hello' } );

    is $ret, 'hello';
};

subtest 'dispatches to DB insert' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
EOF

    my $doc = mdb->test_collection->find_one( { foo => 'bar' } );

    is $doc->{foo}, 'bar';
};

subtest 'dispatches to DB findOne' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    col.findOne({'foo':'bar'});
EOF

    is $ret->{foo}, 'bar';
};

subtest 'dispatches to DB find and cursor hasNext' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    var cursor = col.find();

    cursor.hasNext();
EOF

    is $ret, 1;
};

subtest 'dispatches to DB find and cursor count' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    var cursor = col.find();

    cursor.count();
EOF

    is $ret, 2;
};

subtest 'dispatches to DB find and cursor limit' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    var cursor = col.find();
    cursor.limit(1);

    cursor.count();
EOF

    is $ret, 2;
};

subtest 'dispatches to DB find and cursor skip' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    var cursor = col.find();
    cursor.skip(1);

    cursor.next();
EOF

    is $ret->{foo}, 'baz';
};

subtest 'dispatches to DB find and cursor sort' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':2});
    col.insert({'foo':1});

    var cursor = col.find();
    cursor.sort({'foo':1});

    cursor.next();
EOF

    is $ret->{foo}, 1;
};

subtest 'dispatches to DB find and cursor forEach' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
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

subtest 'dispatches to DB update' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    col.update({'foo':'bar'}, {'foo':'bar2'});
EOF

    my $doc = mdb->test_collection->find_one( { foo => 'bar2' } );

    ok $doc;
};

subtest 'dispatches to DB remove' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
    var db = new Cla.DB;
    var col = db.getCollection('test_collection');

    col.insert({'foo':'bar'});
    col.insert({'foo':'baz'});

    col.remove({'foo':'bar'});
EOF

    is $ret->{ok}, 1;
    my $doc = mdb->test_collection->find_one( { foo => 'bar' } );

    ok !$doc;
};

done_testing;

sub _setup {
    mdb->test_collection->drop;
}

sub _build_code {
    Baseliner::Code::JS->new(@_);
}
