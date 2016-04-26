use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Baseliner::Utils qw(_slurp);

use_ok 'Clarive::Code::JS';

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

done_testing;

sub _setup {
    TestUtils->setup_registry();
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}

