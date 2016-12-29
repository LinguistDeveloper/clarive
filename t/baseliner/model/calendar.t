use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestSetup;

use_ok 'Baseliner::Model::Calendar';

subtest 'delete_multi: deletes calendars and windows' => sub {
    _setup();

    mdb->calendar->insert( { id => '1' } );
    mdb->calendar_window->insert( { id_cal => '1' } );

    mdb->calendar->insert( { id => '2' } );
    mdb->calendar_window->insert( { id_cal => '2' } );

    mdb->calendar->insert( { id => '3' } );
    mdb->calendar_window->insert( { id_cal => '3' } );

    my $model = _build_model();

    $model->delete_multi( ids => [ 1, 2 ] );

    is( mdb->calendar->count,                     1 );
    is( mdb->calendar->find_one->{id},            3 );
    is( mdb->calendar_window->find_one->{id_cal}, 3 );
};

done_testing;

sub _build_model {
    Baseliner::Model::Calendar->new;
}

sub _setup {
    mdb->calendar->drop;
    mdb->calendar_window->drop;
}
