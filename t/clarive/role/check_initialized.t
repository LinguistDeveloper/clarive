use strict;
use warnings;

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use Clarive::mdb;

subtest 'run_start: throws when initialization is needed' => sub {
    _setup();

    mdb->event->insert( { foo => 'bar' } );

    like exception { _build_cmd() }, qr/System is not initialized/;
};

subtest 'run_start: runs initialization when --init flag' => sub {
    _setup();

    _build_cmd( opts => { args => { init => 1 } } );

    ok( mdb->clarive->find_one );
};

subtest 'run_start: runs initialization automatically when empty database' => sub {
    _setup();

    _build_cmd();

    ok( mdb->clarive->find_one );
};

sub _setup {
    my (%params) = @_;

    my @collections = mdb->db->collection_names;
    mdb->$_->drop for @collections;
}

sub _build_cmd {
    my (%params) = @_;

    return TestCmd->new( app => $Clarive::app, opts => {}, %params );
}

done_testing;

package TestCmd;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

BEGIN { with 'Clarive::Role::CheckInitialized' }

sub BUILD {
    my $self = shift;

    $self->check_initialized;
}
