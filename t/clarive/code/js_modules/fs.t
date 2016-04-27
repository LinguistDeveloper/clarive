use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::Utils qw(_slurp);

use_ok 'Clarive::Code::JS';

our $close_override;

BEGIN {
    no strict;
    $close_override      = sub (;*) { no strict; CORE::close($_[0]) };
    *CORE::GLOBAL::close = sub (;*) { no strict; goto $close_override };
}

subtest 'fs.openFile: throws when no filename passed' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.openFile();
EOF
    }, qr/Error: file required/;
};

subtest 'fs.openFile: throws when cannot open file' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.openFile("unknown");
EOF
    }, qr/Error: Cannot open file/;
};

subtest 'fs.openFile: returns functional write file handle' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo", "w");
        fh.write("foobar");
        fh.close();
EOF

    my $data = _slurp "$tempdir/foo";

    is $data, 'foobar';
};

subtest 'fs.openFile: returns functional read file handle' => sub {
    _setup();

    my $tempdir = tempdir();

    open my $fh, '>', "$tempdir/foo";
    print $fh 'foobar';
    close $fh;

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo", "r");
        var chunk = fh.readChunk(6);
        fh.close();
        chunk;
EOF

    is $ret, 'foobar';
};

subtest 'fs.openFile: returns functional read file handle by default' => sub {
    _setup();

    my $tempdir = tempdir();

    open my $fh, '>', "$tempdir/foo";
    print $fh 'foobar';
    close $fh;

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo");
        var chunk = fh.readChunk(6);
        fh.close();
        chunk;
EOF

    is $ret, 'foobar';
};

subtest 'fs.openFile: fails when unknown file mode' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("some-file", "rw");
EOF
    }, qr/Error: Unknown mode/;
};

subtest 'fs.openFile: open/read/close raw data' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $bytes = Encode::encode( 'UTF-8', 'привет' );

    open my $fh, '>', "$tempdir/foo";
    print $fh $bytes;
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo", 'r', 'raw');
        var data = fh.readLine();
        fh.close();

        data.length;
EOF

    is $ret, length $bytes;
};

subtest 'fs.openFile: open/read/close with UTF-8 mode by default' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $bytes = Encode::encode( 'UTF-8', 'привет' );

    open my $fh, '>', "$tempdir/файл";
    print $fh $bytes;
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/файл");
        var data = fh.readLine();
        fh.close();

        [ data, data.length ];
EOF

    is_deeply $ret, [ 'привет', length 'привет' ];
};

subtest 'fs.close: throws when cannot close file' => sub {
    _setup();

    my $tempdir = tempdir();

    local $close_override = sub { 0 };

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo", "w");
        fh.close();
EOF
    }, qr/Error: Cannot close file/;
};

subtest 'fs.eof: returns eof flag' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file( "hello", "$tempdir/foo" );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo");
        fh.readLine();
        var eof = fh.eof();
        fh.close();
        eof === true;
EOF

    ok $ret;
};

subtest 'fs.fileno: returns fileno' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file( "hello", "$tempdir/foo" );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/foo");
        var fileno = fh.fileno();
        fh.close();
        fileno;
EOF

    like $ret, qr/^\d+$/;
};

subtest 'fs.stat: returns stat info' => sub {
    _setup();

    my $tempdir = tempdir();
    TestUtils->write_file( "hello", "$tempdir/foo" );

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.stat("$tempdir/foo");
EOF

    cmp_deeply $ret,
      {
        'atime'   => re(qr/^\d+$/),
        'blksize' => re(qr/^\d+$/),
        'blocks'  => re(qr/^\d+$/),
        'ctime'   => re(qr/^\d+$/),
        'dev'     => re(qr/^\d+$/),
        'file'    => "$tempdir/foo",
        'gid'     => re(qr/^\d+$/),
        'ino'     => re(qr/^\d+$/),
        'mode'    => re(qr/^\d+$/),
        'mtime'   => re(qr/^\d+$/),
        'nlink'   => '1',
        'rdev'    => '0',
        'size'    => '5',
        'uid'     => re(qr/^\d+$/),
      };
};

subtest 'fs.readChunk: reads a chunk of specific length from a file' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $bytes = Encode::encode( 'UTF-8', 'привет' );

    open my $fh, '>', "$tempdir/файл";
    print $fh $bytes;
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        var fh = fs.openFile("$tempdir/файл");
        var data = fh.readChunk(6);
        fh.close();

        [ data, data.length ];
EOF

    is_deeply $ret, [ Encode::encode( 'UTF-8', 'при' ), 6 ];
};

subtest 'fs.slurp: throws when no file' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.slurp();
EOF
    }, qr/Error: file required/;
};

subtest 'fs.slurp: throws when cannot open file' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.slurp('unknown');
EOF
    }, qr/Error: Cannot open file/;
};

subtest 'fs.slurp: reads file into memory' => sub {
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

subtest 'fs.slurp: reads file with UTF-8 name into memory encoding to UTF-8 by default' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $filename = "$tempdir/файл";

    open my $fh, '>', $filename;
    print $fh Encode::encode( 'UTF-8', 'привет' );
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.slurp("$filename");
EOF

    is $ret, "привет";
};

subtest 'fs.slurp: reads file into memory with raw encoding' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $bytes = Encode::encode( 'UTF-8', 'привет' );

    open my $fh, '>', "$tempdir/foo";
    print $fh $bytes;
    close $fh;

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.slurp("$tempdir/foo", "raw");
EOF

    is $ret, $bytes;
};

subtest 'fs.slurp: throws when unknown encoding' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} )
        var fs = require("cla/fs");
        fs.slurp("foo", "koi8");
EOF
    }, qr/Unknown file encoding 'koi8'/;
};

subtest 'fs.createDir: creates new directory' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.createDir("$tempdir/foo");
EOF

    ok -d "$tempdir/foo";
};

subtest 'fs.createDir: returns boolean' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.createDir("$tempdir/foo") === true;
EOF

    ok $ret;
};

subtest 'fs.createDir: creates dir with UTF-8 name' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $dirname = "$tempdir/директория";

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.createDir("$dirname");
EOF

    ok -d $dirname;
};

subtest 'fs.iterateDir: throws when no directory' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.iterateDir("", function(file, path){});
EOF
    }, qr/Error: directory required/;
};

subtest 'fs.iterateDir: throws when no callback' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.iterateDir("some-dir");
EOF
    }, qr/Error: callback required/;
};

subtest 'fs.iterateDir: throws when callback is not a function' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.iterateDir("some-dir", 123);
EOF
    }, qr/Error: callback must be a function/;
};

subtest 'fs.iterateDir: throws when cannot open directory' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    like exception {
        $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.iterateDir("unknown", function(file, path){});
EOF
    }, qr/Error: Cannot open directory/;
};

subtest 'fs.iterateDir: walks the directories' => sub {
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
        fs.createFile("$tempdir/файл2");

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

    is_deeply [ sort @{ $ret->[0] } ], [qw/dir1 dir2/];
    is_deeply [ sort @{ $ret->[1] } ], [qw/file1 файл2/];
};

subtest 'fs.isDir: returns boolean' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.isDir("$tempdir") === true;
EOF

    ok $ret;
};

subtest 'fs.isFile: returns boolean' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.isFile("$tempdir") === false;
EOF

    ok $ret;
};

subtest 'fs.createFile: creates file' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createFile("$tempdir/file");
EOF

    ok -f "$tempdir/file";
};

subtest 'fs.createFile: throws when cannot create a file' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createFile("/file");
EOF
    }, qr/Error: Cannot create file/;
};

subtest 'fs.createFile: throws when cannot close a file' => sub {
    _setup();

    my $tempdir = tempdir();

    local $close_override = sub { 0 };

    my $code = _build_code( lang => 'js' );

    like exception { $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createFile("$tempdir/file");
EOF
    }, qr/Error: Cannot close file/;
};

subtest 'fs.createFile: creates file with UTF-8 content by default' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createFile("$tempdir/file", "привет");
EOF

    is do { local $/; open my $fh, '<:encoding(UTF-8)', "$tempdir/file"; <$fh> }, 'привет';
};

subtest 'fs.createFile: returns boolean' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createFile("$tempdir/file") === true;
EOF

    ok $ret;
};

subtest 'fs.createPath: creates path' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createPath("$tempdir/foo/bar/baz");
EOF

    ok -d "$tempdir/foo/bar/baz";
};

subtest 'fs.createPath: creates path with UTF-8 names' => sub {
    _setup();

    my $tempdir = tempdir();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");

        fs.createPath("$tempdir/один/два/три");
EOF

    ok -d "$tempdir/один/два/три";
};

subtest 'fs.deleteDir: deletes a directory' => sub {
    _setup();

    my $tempdir = tempdir();

    mkdir "$tempdir/dir";

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.deleteDir("$tempdir/dir");
EOF

    ok !-d "$tempdir/dir";
};

subtest 'fs.deleteFile: deletes a file' => sub {
    _setup();

    my $tempdir = tempdir();

    system("touch $tempdir/file");

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<"EOF", {} );
        var fs = require("cla/fs");
        fs.deleteFile("$tempdir/file");
EOF

    ok !-f "$tempdir/file";
};

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
