use strict;
use warnings;

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsExplorerCI');

subtest 'cannot see ci in lifecycle panel without permission' => sub {
    $driver->login('can_see_lifecycle', 'password');

    ok $driver->element_not_visible('.ui-explorer-ci');
};

subtest 'can see cis in lifecycle panel with permission' => sub {
    $driver->login('can_view_ssh_agent_ci', 'password');

    ok $driver->element_visible('.ui-explorer-ci');
};

subtest 'can see ci in lifecycle panel with permission' => sub {
    $driver->login('can_view_ssh_agent_ci', 'password');

    $driver->find_extjs_component('.ui-explorer-ci')->elem->click;

    $driver->wait_for_element_by_jquery('.ui-explorer-ci-Agent img.x-tree-elbow-end-plus')->click;

    $driver->wait_for_element_by_jquery('.ui-explorer-ci-ssh_agent')->click;

    $driver->wait_for_extjs_component('.ui-ci-grid');

    $driver->wait_for_element_by_jquery('.ui-ci-edit')->click;

    $driver->wait_for_extjs_component('.ui-ci-panel');

    is $driver->wait_for_element_by_jquery('.ui-ci-form-btn-edit button')->get_text, 'View';
};

subtest 'cannot edit ci without permission' => sub {
    $driver->login('can_view_ssh_agent_ci', 'password');

    $driver->find_extjs_component('.ui-explorer-ci')->elem->click;

    $driver->wait_for_element_by_jquery('.ui-explorer-ci-Agent img.x-tree-elbow-end-plus')->click;

    $driver->wait_for_element_by_jquery('.ui-explorer-ci-ssh_agent')->click;

    $driver->wait_for_extjs_component('.ui-ci-grid');

    $driver->wait_for_element_by_jquery('.ui-ci-edit')->click;

    $driver->wait_for_extjs_component('.ui-ci-panel');

    isnt $driver->wait_for_element_by_jquery('.ui-ci-form-btn-edit button')->get_text, 'Edit';
};

subtest 'can edit ci with permission' => sub {
    $driver->login('can_edit_ssh_agent_ci', 'password');

    $driver->find_extjs_component('.ui-explorer-ci')->elem->click;

    $driver->wait_for_element_by_jquery('.ui-explorer-ci-Agent img.x-tree-elbow-end-plus')->click;

    $driver->wait_for_element_by_jquery('.ui-explorer-ci-ssh_agent')->click;

    $driver->wait_for_extjs_component('.ui-ci-grid');

    $driver->wait_for_element_by_jquery('.ui-ci-edit')->click;

    $driver->wait_for_extjs_component('.ui-ci-panel');

    is $driver->wait_for_element_by_jquery('.ui-ci-form-btn-edit button')->get_text, 'Edit';
};

$driver->quit;

done_testing;
