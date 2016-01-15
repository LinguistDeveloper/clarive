use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use Capture::Tiny qw(capture);
use Clarive::Cmd::profile;

subtest 'run: prints profile' => sub {
    my $cmd = _build_cmd();

    my $output = capture { $cmd->run };

    like $output, qr/export CLARIVE_BASE/;
    like $output, qr/export CLARIVE_ENV/;
    like $output, qr/export PATH/;
    like $output, qr/export CLARIVE_HOME/;
};

sub _build_cmd {
    my (%params) = @_;

    return Clarive::Cmd::profile->new( app => $Clarive::app, opts => {} );
}

done_testing;
