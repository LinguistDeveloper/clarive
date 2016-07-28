use strict;
use warnings;

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsUser');

subtest 'cannot change user password without permission' => sub {
    $driver->login('nobody', 'password');

    $driver->toggle_user_menu;

    ok $driver->element_not_visible('.ui-user-menu-change-password');
};

subtest 'can change user password with permission' => sub {
    $driver->login('can_change_password', 'password');

    $driver->toggle_user_menu;

    ok $driver->element_visible('.ui-user-menu-change-password');
};

subtest 'cannot surrogate without permission' => sub {
    $driver->login('nobody', 'password');

    $driver->toggle_user_menu;

    ok $driver->element_not_visible('.ui-user-menu-surrogate');
};

subtest 'can surrogate with permission' => sub {
    $driver->login('can_surrogate', 'password');

    $driver->toggle_user_menu;

    ok $driver->element_visible('.ui-user-menu-surrogate');
};

subtest 'cannot see menu without permission' => sub {
    $driver->login('nobody', 'password');

    ok $driver->element_not_visible('.bali-main-menu');
};

subtest 'can see menu with permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_visible('.bali-main-menu');
};

$driver->quit;

done_testing;
