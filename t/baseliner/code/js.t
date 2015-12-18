use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::Utils qw(_slurp);
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

subtest 'dispatches to fs: open/write/close' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
    var fh = Cla.FS.openFile("$tempdir/foo", "w");
    fh.write("foobar");
    fh.close();
EOF

    my $data = _slurp "$tempdir/foo";

    is $data, 'foobar';
};

subtest 'dispatches to fs: open/read/close' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    open my $fh, '>', "$tempdir/foo";
    print $fh 'foobar';
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
    var fh = Cla.FS.openFile("$tempdir/foo");
    var data = fh.readLine("foobar");
    fh.close();

    data;
EOF

    is $ret, 'foobar';
};

subtest 'dispatches to fs: slurp' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    open my $fh, '>', "$tempdir/foo";
    print $fh 'foobar', "\n", 'newline';
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
    Cla.FS.slurp("$tempdir/foo");
EOF

    is $ret, "foobar\nnewline";
};

subtest 'dispatches to fs: createDir' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
    Cla.FS.createDir("$tempdir/foo");
EOF

    ok -d "$tempdir/foo";
};

subtest 'dispatches to fs: walk directory' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
    var dirs = [];
    var files = [];

    Cla.FS.createDir("$tempdir/dir1");
    Cla.FS.createDir("$tempdir/dir2");
    Cla.FS.createFile("$tempdir/file1");
    Cla.FS.createFile("$tempdir/file2");

    var dir = Cla.FS.openDir("$tempdir");
    while (file = dir.readDir()) {
        if (file.indexOf(".") == 0) {
            continue;
        }

        if (Cla.FS.isDir(Cla.Path.join(dir.path, file))) {
            dirs.push(file)
        }
        else if (Cla.FS.isFile(Cla.Path.join(dir.path, file))) {
            files.push(file)
        }
    }
    dir.close();

    [dirs, files]
EOF

    is_deeply $ret, [ [qw/dir2 dir1/], [qw/file2 file1/] ];
};

subtest 'dispatches to fs: delete dir and file' => sub {
    _setup();

    my $tempdir = tempdir();

    mkdir "$tempdir/dir";
    system("touch $tempdir/file");

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
    Cla.FS.deleteDir("$tempdir/dir");
    Cla.FS.deleteFile("$tempdir/file");
EOF

    ok !-d "$tempdir/dir";
    ok !-f "$tempdir/file";
};

subtest 'dispatches to path' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    is $code->eval_code(q{Cla.Path.basename('/foo/bar.baz')}),    'bar.baz';
    is $code->eval_code(q{Cla.Path.dirname('/foo/bar.baz')}),     '/foo';
    is $code->eval_code(q{Cla.Path.extname('/foo/bar.baz')}),     '.baz';
    is $code->eval_code(q{Cla.Path.extname('/foo/bar.daz.baz')}), '.baz';
    is $code->eval_code(q{Cla.Path.extname('.foo')}),             '';
    is $code->eval_code(q{Cla.Path.join('foo', 'bar', 'baz')}),   'foo/bar/baz';
};

subtest 'dispatches to CI instance' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(q/var ci = Cla.CI.load('123'); ci.name()/);

    is $ret, 'New';
};

subtest 'dispatches to CI attribute method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q/var ci = new Cla.CI.Status({'mid': '123'}); ci.icon()/);

    like $ret, qr{static/images};
};

subtest 'dispatches to CI method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q/var ci = new Cla.CI.Status({'mid': '123'}); ci.delete()/);

    ok !mdb->master->find_one( { mid => '123' } );
};

subtest 'dispatches to CI method returning object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my @ret = $code->eval_code(q/var ci = new Cla.CI.Status({'mid': '123'}); ci.searchCis()/);

    is scalar @ret, 1;
    is $ret[0]->{mid}, '123';
};

subtest 'dispatches to toJSON' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    is $code->eval_code(q/toJSON('')/), '';
    is $code->eval_code(q/toJSON('foo')/), 'foo';
    is $code->eval_code(q/toJSON([1, 2, 3])/), qq/[\n   1,\n   2,\n   3\n]\n/;
    is $code->eval_code(q/toJSON({"foo":"bar"})/), qq/{\n   "foo" : "bar"\n}\n/;

    is $code->eval_code(q/toJSON([1, [2, 3], 4])/), qq/[\n   1,\n   [\n      2,\n      3\n   ],\n   4\n]\n/;
};

subtest 'dispatches to stash' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stash = {};
    $code->eval_code(q/Cla.stash('foo', 'bar')/, $stash);

    is_deeply $stash, {foo => 'bar'};

    is $code->eval_code(q/Cla.stash('foo')/, $stash), 'bar';

    is_deeply $code->eval_code(q/Cla.stash()/, $stash), $stash;

};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    mdb->test_collection->drop;
}

sub _build_code {
    Baseliner::Code::JS->new(@_);
}
