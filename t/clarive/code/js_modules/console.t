use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;

use Encode ();
use Capture::Tiny qw(capture);

use_ok 'Clarive::Code::JS';

subtest 'console.log: prints message' => sub {
    my $code = _build_code( lang => 'js' );

    my $stdout = capture {
        $code->eval_code(<<'EOF');
        var con = require('cla/console');

        con.log('hello');
EOF
    };

    is $stdout, qq/hello\n/;
};

subtest 'console.log: prints message with unicode' => sub {
    my $code = _build_code( lang => 'js' );

    my $program = <<"EOF";
        var con = require('cla/console');

        var msg = "привет";

        con.log(msg + ' ' + msg.length);
EOF

    my $stdout = capture { $code->eval_code($program) };

    is $stdout, Encode::encode( 'UTF-8', "привет 6\n" );
};

subtest 'console.log: prints object stringified' => sub {
    my $code = _build_code( lang => 'js' );

    my $stdout = capture {
        $code->eval_code(<<'EOF');
        var con = require('cla/console');

        con.log({aa:11});
EOF
    };

    is $stdout, qq/{"aa":11}\n/;
};

subtest 'console.warn: prints message to STDERR' => sub {
    my $code = _build_code( lang => 'js' );

    my ( undef, $stderr ) = capture {
        $code->eval_code(<<'EOF');
        var con = require('cla/console');

        con.warn('hello');
EOF
    };

    is $stderr, qq/hello\n/;
};

subtest 'console.warn: prints object stringified to STDERR' => sub {
    my $code = _build_code( lang => 'js' );

    my ( undef, $stderr ) = capture {
        $code->eval_code(<<'EOF');
        var con = require('cla/console');

        con.warn({aa:11});
EOF
    };

    is $stderr, qq/{"aa":11}\n/;
};

subtest 'console.assert: prints not output when assert is true' => sub {
    my $code = _build_code( lang => 'js' );

    my ($stdout) = capture {
        $code->eval_code(
            q{
        var console = require('cla/console');

        console.assert(1 === 1, 'Oh my god %d', 10);
    }
          )
    };

    is $stdout, '';
};

subtest 'console.assert: prints output when assert is false' => sub {
    my $code = _build_code( lang => 'js' );

    my ($stdout) = capture {
        $code->eval_code(
            q{
        var console = require('cla/console');

        console.assert(false, 'Oh my god %d', 10);
    }
        );
    };

    like $stdout, qr/Oh my god 10/;
};

done_testing;

sub _build_code {
    Clarive::Code::JS->new(@_);
}
