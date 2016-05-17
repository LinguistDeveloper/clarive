use strict;
use warnings;

use Test::More;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use_ok 'Clarive::Code::JS';

subtest 'process.argv: returns ARGV' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    local @ARGV = ('foo');

    my $ret = $code->eval_code( <<'EOF', {} );
        process.argv();
EOF

    is_deeply $ret, ['foo'];
};

subtest 'process.pid: returns pid' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        process.pid();
EOF

    like $ret, qr/^\d+$/;
};

subtest 'process.title: returns title' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        process.title();
EOF

    my $file = __FILE__;
    like $ret, qr/$file/;
};

subtest 'process.os: returns os' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        process.os();
EOF

    my $os = $^O;
    like $ret, qr/$os/;
};

subtest 'process.os: returns arch' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    my $ret = $code->eval_code( <<'EOF', {} );
        process.arch();
EOF

    like $ret, qr/64|32/;
};

subtest 'process.env: returns ENV' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    local $ENV{FOO} = 'bar';

    my $ret = $code->eval_code( <<'EOF', {} );
        process.env().FOO;
EOF

    is $ret, 'bar';
};

subtest 'process.env: returns ENV by key' => sub {
    _setup();

    my $code = _build_code( lang => 'js' );

    local $ENV{FOO} = 'bar';

    my $ret = $code->eval_code( <<'EOF', {} );
        process.env('FOO');
EOF

    is $ret, 'bar';
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;
}

sub _build_code {
    Clarive::Code::JS->new(@_);
}
