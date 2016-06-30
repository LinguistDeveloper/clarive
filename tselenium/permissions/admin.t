use strict;
use warnings;

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsAdmin');

subtest 'cannot see server info without permission' => sub {
    $driver->login('can_see_menu', 'password');

    $driver->wait_for_extjs_component('.ui-menu-help')->elem->click;
    $driver->wait_for_extjs_component('.ui-menu-about')->elem->click;

    $driver->wait_for_element_visible('.logo');

    ok $driver->element_not_visible('.about-environment');
};

subtest 'can see server info with permission' => sub {
    $driver->login('can_see_server_info', 'password');

    $driver->wait_for_extjs_component('.ui-menu-help')->elem->click;
    $driver->wait_for_extjs_component('.ui-menu-about')->elem->click;

    $driver->wait_for_element_visible('.logo');

    ok $driver->element_visible('.about-environment');
};

subtest 'cannot admin config list without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin config list with permission' => sub {
    $driver->login('can_admin_config_list', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-config_list');
};

subtest 'cannot admin daemons without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin daemons with permission' => sub {
    $driver->login('can_admin_daemon', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-daemon');
};

subtest 'cannot admin events without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin events with permission' => sub {
    $driver->login('can_admin_event', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-events');
};

subtest 'cannot admin notifications without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin notifications with permission' => sub {
    $driver->login('can_admin_notification', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-notifications');
};

subtest 'cannot admin roles without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin roles with permission' => sub {
    $driver->login('can_admin_role', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-role');
};

subtest 'cannot admin rules without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin rules with permission' => sub {
    $driver->login('can_admin_rule', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-rule');
};

#subtest 'can admin only allowed rules with permission' => sub {
#    $driver->login('can_admin_rule_by_id', 'password');
#
#    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;
#    $driver->wait_for_extjs_component('.ui-menu-rule')->elem->click;
#
#    my $elem = $driver->wait_for_extjs_component('.ui-comp-rules-grid');
#
#    is $elem->eval('return cmp.store.getCount()'), 1;
#};
#
#subtest 'cannot create rules when only allowed specific rules with permission' => sub {
#    $driver->login('can_admin_rule_by_id', 'password');
#
#    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;
#    $driver->wait_for_extjs_component('.ui-menu-rule')->elem->click;
#
#    $driver->wait_for_extjs_component('.ui-comp-rules-grid');
#
#    ok !$driver->find_extjs_component('.ui-comp-rule-create')->is_enabled;
#};

subtest 'cannot admin scheduler without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin scheduler with permission' => sub {
    $driver->login('can_admin_scheduler', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-scheduler');
};

subtest 'cannot admin semaphores without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin semaphores with permission' => sub {
    $driver->login('can_admin_semaphore', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-semaphore');
};

subtest 'cannot admin system messages without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin system messages with permission' => sub {
    $driver->login('can_admin_sms', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-sms');
};

subtest 'cannot upgrade without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can do upgrades with permission' => sub {
    $driver->login('can_upgrade', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-upgrade');
};

subtest 'cannot admin categories without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-admin');
};

subtest 'can admin categories with permission' => sub {
    $driver->login('can_admin_categories', 'password');

    $driver->wait_for_extjs_component('.ui-menu-admin')->elem->click;

    ok $driver->element_visible('.ui-menu-topic');
};

$driver->quit;

done_testing;
