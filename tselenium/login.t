use strict;
use warnings;
use lib 'tselenium/lib';

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

subtest 'shows an error when no password or username' => sub {
    $driver->get_fresh('localhost:3000');

    $driver->wait_for_element_visible('.ui-button-login button')->click;

    my $error_message = $driver->wait_for_element_visible('div.x-form-invalid-msg');

    ok $error_message;
    like $error_message->get_text, qr/This field is required/;
};

subtest 'shows an error when invalid user' => sub {
    $driver->get_fresh('localhost:3000');

    $driver->wait_for_element_visible('input[name=login]')->send_keys('unknown user');
    $driver->wait_for_element_visible('input[name=password]')->send_keys('unknown password');

    $driver->wait_for_element_visible('.ui-button-login button')->click;

    my $error_message = $driver->wait_for_element_visible('div.x-form-invalid-msg');

    ok $error_message;
    like $error_message->get_text, qr/Invalid User or Password/;
};

subtest 'shows an error when correct user but wrong password' => sub {

    # TODO

    ok 1;
};

subtest 'successfully logins with correct credentials' => sub {

    # TODO

    ok 1;
};

$driver->quit;

done_testing;
