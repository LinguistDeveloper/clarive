use strict;
use warnings;

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use boolean;
use Capture::Tiny qw(capture);
use Clarive::mdb;

subtest 'run_start: throws when migrations are needed' => sub {
    _setup();

    like exception { _build_cmd() }, qr/Migrations are not up to date/;
};

subtest 'run_start: runs migrations when --migrate-yes flag' => sub {
    _setup();

    capture {
        _build_cmd( opts => { args => { 'migrate-yes' => 1 } } );
    };

    my $clarive = mdb->clarive->find_one;
    ok($clarive);
    ok scalar @{ $clarive->{migration}->{patches} };
};

subtest 'run_start: runs migrations automatically when empty database' => sub {
    _setup( empty => 1 );

    capture {
        _build_cmd();
    };

    my $clarive = mdb->clarive->find_one;
    ok($clarive);
    ok scalar @{ $clarive->{migration}->{patches} };

    ok !exists $clarive->{empty};
};

sub _setup {
    my (%params) = @_;

    mdb->clarive->drop;

    mdb->clarive->insert( { initialized => true, migration => { version => '0100' }, %params } );
}

sub _build_cmd {
    my (%params) = @_;

    return TestCmd->new( app => $Clarive::app, opts => {}, %params );
}

done_testing;

package TestCmd;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

BEGIN { with 'Clarive::Role::CheckMigrations' }

sub BUILD {
    my $self = shift;

    $self->check_migrations;
}
