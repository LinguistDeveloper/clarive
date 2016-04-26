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
use_ok 'Clarive::Code::JS';
use Clarive::Code::Utils;

subtest 'evals js' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( '1 + 1', {} );

    is $ret, 2;
};

subtest 'extend cla namespace' => sub {
    my $code = _build_code( lang => 'js' );

    $code->extend_cla({ foo=>js_sub{ 321 } });
    my $ret = $code->eval_code( 'cla.foo();', {});

    is $ret, 321;
};

subtest 'extend global namespace' => sub {
    my $code = _build_code( lang => 'js' );

    $code->global_ns({ foo=>js_sub{ 999 } });
    my $ret = $code->eval_code( 'foo();', {});

    is $ret, 999;
};

subtest 'save vm creates globals' => sub {
    my $code = _build_code( lang => 'js' );

    $code->save_vm(1);
    $code->eval_code( 'var x = 100;', {});
    my $ret = $code->eval_code( 'x', {});

    is $ret, 100;
};

subtest 'save_vm enclose_code protects against globals' => sub {
    my $code = _build_code( lang => 'js' );

    $code->save_vm(1);
    $code->enclose_code(1);
    $code->eval_code( 'var x = 100;', {});
    ok exception { $code->eval_code( 'x', {}) };
};

subtest 'enclose code doesnt return value' => sub {
    my $code = _build_code( lang => 'js' );

    $code->enclose_code(1);
    my $ret = $code->eval_code( '100', {});

    is $ret, undef;
};

subtest 'require module underscore' => sub {
    my $code = _build_code( lang => 'js' );

    my $arr = $code->eval_code( 'var _ = require("underscore"); _.each([1,2],function(){})', {} );

    is_deeply $arr, [1,2];
};

subtest 'dispatches to parseVars' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        cla.parseVars('${my_var}')}, { my_var => 'hello' } );

    is $ret, 'hello';
};

subtest 'dispatches to parseVars with local stash' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( q{
        cla.parseVars('${my_var}',{ "my_var":"hola" })}, { my_var => 'hello' } );

    is $ret, 'hola';
};

subtest 'parseVars without a stash' => sub {
    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( 'cla.parseVars("this is ${foo}")' );

    is $ret, 'this is ${foo}';
};

subtest 'dispatches to DB insert' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        db = require("cla/db");
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
        db = require("cla/db");
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
        var db = require("cla/db");
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
        var db = require("cla/db");
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

subtest 'chained DB cursor call' => sub {
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

subtest 'dispatches to DB find and cursor skip' => sub {
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

subtest 'dispatches to DB find and cursor sort' => sub {
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

subtest 'dispatches to DB find and cursor forEach' => sub {
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

subtest 'dispatches to DB update' => sub {
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

subtest 'dispatches to DB remove' => sub {
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

subtest 'dispatches to DB collection drop' => sub {
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

subtest 'dispatches to fs: open/write/close' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo", "w");
        fh.write("foobar");
        fh.close();
EOF

    my $data = _slurp("$tempdir/foo");

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
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo");
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
        var fs = require("cla/fs");
        fs.slurp("$tempdir/foo");
EOF

    is $ret, "foobar\nnewline";
};

subtest 'dispatches to fs: createDir' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.createDir("$tempdir/foo");
EOF

    ok -d "$tempdir/foo";
};

subtest 'dispatches to fs: walk directory' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var dirs = [];
        var files = [];

        fs.createDir("$tempdir/dir1");
        fs.createDir("$tempdir/dir2");
        fs.createFile("$tempdir/file1");
        fs.createFile("$tempdir/file2");

        fs.iterateDir("$tempdir",function(file,path){
            if (file.indexOf(".") == 0) {
                return;
            }

            if (fs.isDir(path)) {
                dirs.push(file)
            }
            else if (fs.isFile(path)) {
                files.push(file)
            }
        });

        [dirs, files]
EOF

    is_deeply [ sort @{$ret->[0]} ], [ qw/dir1 dir2/ ];
    is_deeply [ sort @{$ret->[1]} ], [ qw/file1 file2/ ];
};

subtest 'dispatches to fs: delete dir and file' => sub {
    _setup();

    my $tempdir = tempdir();

    mkdir "$tempdir/dir";
    system("touch $tempdir/file");

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.deleteDir("$tempdir/dir");
        fs.deleteFile("$tempdir/file");
EOF

    ok !-d "$tempdir/dir";
    ok !-f "$tempdir/file";
};

subtest 'dispatches to path' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    is $code->eval_code(q{
        var path = require("cla/path");
        path.basename('/foo/bar.baz')}),    'bar.baz';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.dirname('/foo/bar.baz')}),     '/foo';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.extname('/foo/bar.baz')}),     '.baz';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.extname('/foo/bar.daz.baz')}), '.baz';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.extname('.foo')}),             '';
    is $code->eval_code(q{
        var path = require("cla/path");
        path.join('foo', 'bar', 'baz')}),   'foo/bar/baz';
};

subtest 'dispatches to CI instance' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var obj = ci.load('123'); obj.name()});

    is $ret, 'New';
};

subtest 'dispatches to CI attribute method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status'); (new Status({'mid': '123'})).icon()});

    like $ret, qr{static/images};
};

subtest 'dispatches to CI method' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my $ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status'); (new Status({'mid': '123'})).delete()});

    ok !mdb->master->find_one( { mid => '123' } );
};

subtest 'dispatches to CI method returning object' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $status = TestUtils->create_ci( 'status', mid => '123', name => 'New' );

    my @ret = $code->eval_code(q{
        var ci = require("cla/ci");
        var Status = ci.getClass('Status'); 
        var obj = (new Status).searchCis(); obj.mid()});

    is scalar @ret, 1;
    is $ret[0], '123';
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
    $code->eval_code(q/cla.stash('foo', 'bar')/, $stash);

    is_deeply $stash, {foo => 'bar'};

    is $code->eval_code(q/cla.stash('foo')/, $stash), 'bar';

    is_deeply $code->eval_code(q/cla.stash()/, $stash), $stash;

};

subtest 'dispatches to stash pointers' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $stash = { foo=>{} };
    $code->eval_code(q{cla.stash('/foo/bar', 99)}, $stash);

    is_deeply $stash, {foo =>{ bar => 99 } };
};

subtest 'exceptions catch internal errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( q/throw new Error('error!')/) }, qr/error!/;
    ok !exception { $code->eval_code( q/try { throw new Error('error!') } catch(e) {}/) };
};

subtest 'exceptions catch external errors' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code(q{
            var fs = require("cla/fs");
            fs.openFile('unknown')}) }, qr/Cannot open file unknown/;
    ok !exception { $code->eval_code(q/try { fs.openFile('unknown') } catch(e) {}/) };
};

subtest 'returns js array' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{var x = [1,2,3]; x});

    is_deeply $ret,[1,2,3];
};

subtest 'returns js array from bare structure' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code(q{[1,2,3];});

    is_deeply $ret,[1,2,3];
};

subtest 'gets clarive Config' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    Clarive->app->config->{_tester99} = 99; 

    my $home = $code->eval_code(q{cla.config('_tester99')});

    is $home, 99;
};

subtest 'load yaml util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $hash = $code->eval_code(q{
        var util = require("cla/util");
        var yaml="---\nfoo: bar\n"; util.loadYAML(yaml)});

    is_deeply $hash, { foo=>'bar' };
};

subtest 'dump yaml util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $yaml = $code->eval_code(q{
        var util = require("cla/util");
        util.dumpYAML({ foo: 'bar' })});

    like $yaml, qr/foo: bar/;
};

subtest 'load json util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $hash = $code->eval_code(q{
        var util = require("cla/util");
        var json='{ "foo":"bar" }'; util.loadJSON(json)});

    is_deeply $hash, { foo=>'bar' };
};

subtest 'dump json util' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $json = $code->eval_code(q{
        var util = require("cla/util");
        util.dumpJSON({ foo: 'bar' })});

    like $json, qr/"foo"\s*:\s*"bar"/;
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    mdb->test_collection->drop;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
