use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup }

use_ok 'Baseliner::CommandRunner';

subtest 'run: runs a simple command' => sub {
    my $runner = _build_command_runner();

    my $ret = $runner->run('date');

    cmp_deeply $ret,
      {
        exit_code     => 0,
        stderr_output => '',
        stdout_output => re(qr/\d\d:\d\d:\d\d/),
        output        => re(qr/\d\d:\d\d:\d\d/),
      };
};

subtest 'run: calls a callback with output' => sub {
    my $output = '';
    my $runner = _build_command_runner( output_cb => sub { $output .= $_[0] } );

    $runner->run('date');

    like $output, qr/\d\d:\d\d:\d\d/;
};

subtest 'run: calls a callback with stdout/stderr_output' => sub {
    my $stdout_output = '';
    my $stderr_output = '';
    my $runner        = _build_command_runner(
        stdout_output_cb => sub { $stdout_output .= $_[0] },
        stderr_output_cb => sub { $stderr_output .= $_[0] },
    );

    $runner->run('date');

    is $stderr_output,   '';
    like $stdout_output, qr/\d\d:\d\d:\d\d/;
};

#subtest 'run: runs a command with timeout' => sub {
#    my $runner = _build_command_runner( timeout => 0.2 );
#
#    like exception { $runner->run('sleep 10') }, qr/timeout/;
#};

done_testing;

sub _build_command_runner {
    return Baseliner::CommandRunner->new(@_);
}
