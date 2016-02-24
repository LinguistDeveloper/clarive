use strict;
use warnings;
use lib 'tselenium/lib';

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

subtest 'invalid username/password' => sub {
    $driver->get_fresh('localhost:3000');

    $driver->wait_for('@loginButton')->send_keys('foo');
    $driver->wait_for('input[name=password]')->send_keys('bar');

    $driver->pause(500);

    $driver->wait_for('.ui-button-login button')->click;

    $driver->pause(500);

    ok $driver->find_element_by_css('input[name=login].x-form-invalid')->is_displayed;
};

$driver->quit;

done_testing;
