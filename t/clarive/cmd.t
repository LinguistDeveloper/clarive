use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use Capture::Tiny qw(capture_merged);

use TestEnv;

use Cwd ();
my $root;
my $app;

BEGIN {
    use File::Basename qw(dirname);
    $root = Cwd::realpath( dirname(__FILE__) );

    $app = TestEnv->setup();
}

use_ok 'Clarive::Cmd';
use_ok 'Clarive::App';

subtest 'is_strict: check for strictness' => sub {

    { package Clarive::Cmd::TestStrict;
        use Mouse;
        extends 'Clarive::Cmd';
        with 'Clarive::CmdStrict';
    }

    ok( Clarive::Cmd::TestStrict->is_strict );
};

subtest 'command_name: parse cmd name' => sub {

    { package Clarive::Cmd::TestCmdName;
        use Mouse;
        extends 'Clarive::Cmd';
        with 'Clarive::CmdStrict';
    }

    my $ret = Clarive::Cmd::TestCmdName->command_name;

    is $ret, 'TestCmdName';
};

subtest 'check_cli_options: no exist' => sub {

    { package Clarive::Cmd::TestCmdNoExist;
        use Mouse;
        extends 'Clarive::Cmd';
        with 'Clarive::CmdStrict';
    }

    my @ret = Clarive::Cmd::TestCmdNoExist->check_cli_options( args=>{'foo'=>''} );

    is_deeply \@ret, ['foo'];
};

subtest 'check_cli_options: exists' => sub {

    { package Clarive::Cmd::TestCmd;
        use Mouse;
        extends 'Clarive::Cmd';
        with 'Clarive::CmdStrict';
        has 'foo' => qw(is rw);
    }

    my @ret = Clarive::Cmd::TestCmd->check_cli_options( args=>{'foo'=>''} );

    is @ret, 0;
};

subtest 'cli_options: is ok' => sub {

    { package Clarive::Cmd::TestCmdPrint;
        use Mouse;
        extends 'Clarive::Cmd';
        has 'bar' => qw(is rw);
    }

    my $ret = Clarive::Cmd::TestCmdPrint->cli_options;

    like $ret, qr/--bar/;
};

subtest 'load_package_for_command' => sub {

    { package Clarive::Cmd::TestGetPackage;
        use Mouse;
        extends 'Clarive::Cmd';
    }

    my $ret = Clarive::Cmd->load_package_for_command( 'TestGetPackage' );

    is $ret, 'Clarive::Cmd::TestGetPackage';
};

subtest 'load_command: from package' => sub {

    { package Clarive::Cmd::TestGetPackage2;
        use Mouse;
        extends 'Clarive::Cmd';
        sub run {}
    }

    my ( $pkg, $runsub ) = Clarive::Cmd->load_command( $app, 'TestGetPackage2' );

    is $pkg, 'Clarive::Cmd::TestGetPackage2';
    is $runsub, 'run';
};

subtest 'load_command: subcommand' => sub {

    { package Clarive::Cmd::TestGetPackage3;
        use Mouse;
        extends 'Clarive::Cmd';
        sub run_foo {}
    }

    my $opts = {};

    my ( $pkg, $runsub ) = Clarive::Cmd->load_command( $app, 'TestGetPackage3-foo', $opts );

    is $pkg, 'Clarive::Cmd::TestGetPackage3';
    is $runsub, 'run_foo';
};

subtest 'list_subcommands' => sub {

    { package Clarive::Cmd::TestSubCmds;
        use Mouse;
        extends 'Clarive::Cmd';
        has 'bar' => qw(is rw);
        sub run {}
        sub run_foo {}
        sub run_baz {}
    }

    my @subcmds = Clarive::Cmd::TestSubCmds->list_subcommands;

    is_deeply \@subcmds, [ 'TestSubCmds-baz', 'TestSubCmds-foo'];
};

subtest 'help_doc: returns doc file' => sub {

    { package Clarive::Cmd::TestShowHelp;
        use Mouse;
        extends 'Clarive::Cmd';
        has 'bar' => qw(is rw);
    }

    my $ret = Clarive::Cmd::TestShowHelp->help_doc( home=>"$root/../data/app-base/app-home" );

    like $ret, qr/showhelp body/;
};

done_testing;

sub _build_cmd {
    Clarive::Cmd->new(@_);
}
