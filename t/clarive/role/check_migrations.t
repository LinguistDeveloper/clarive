use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;

TestEnv->setup;

use boolean;
use Clarive::mdb;

subtest 'run_start: throws when migrations are needed' => sub {
    _setup();

    like exception { _build_cmd() }, qr/Migrations are not up to date/;
};

sub _setup {
    my (%params) = @_;

    mdb->clarive->drop;

    mdb->clarive->insert( { initialized => true, migration => { version => '0100' } } ) unless $params{no_system_init};
}

sub _build_cmd {
    my (%params) = @_;

    return TestCmd->new( app => $Clarive::app, opts => {} );
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
