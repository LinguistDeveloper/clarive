use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils;
use TestSetup;

use_ok 'Baseliner::Model::Daemons';

subtest 'service_start: starts service with correct env parameter' => sub {
    _setup();

    local $ENV{BASELINER_PERL_OPTS} = 'options';
    my $proc = Test::MonkeyMock->new;
    $proc->mock( pid => sub { 123 } );

    my $model = _build_daemons( proc => $proc );

    my @started = $model->service_start(
        id      => '16953',
        service => 'service.job.daemon',
        disp_id => 'localhost.localdomain',
        params  => { '--env' => 'acmebank' },
    );

    cmp_deeply \@started,
      [
        {
            service => 'service.job.daemon',
            pid     => 123,
            disp_id => 'localhost.localdomain',
            owner   => ignore(),
        },
      ];

    my ($cmd) = $model->mocked_call_args('_create_background_proccess');
    like $cmd, qr/service.job.daemon --env acmebank --id localhost.localdomain/;
};

done_testing;

sub _setup {
    my (%params) = @_;
}

sub _build_daemons {
    my (%params) = @_;

    my $proc = $params{proc};

    my $cmd = Baseliner::Model::Daemons->new;
    $cmd = Test::MonkeyMock->new($cmd);
    $cmd->mock( _create_background_proccess => sub { $proc } );

    return $cmd;
}
