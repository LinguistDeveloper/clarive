use strict;
use warnings;

use Test::More;

use TestDriver;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsJob');

subtest 'cannot see job monitor without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-job');
};

subtest 'cannot create new jobs without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-job');
};

subtest 'can create new jobs with permission' => sub {
    $driver->login('can_create_new_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    ok $driver->element_visible('.ui-menu-create');
};

subtest 'cannot change default pipeline without permission' => sub {
    $driver->login('can_create_new_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;
    $driver->wait_for_extjs_component('.ui-menu-create')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#new-job');

    ok $elem->eval('return cmp.getForm().findField("id_rule").hidden');
};

subtest 'can change default pipeline with permission' => sub {
    $driver->login('can_change_pipeline', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;
    $driver->wait_for_extjs_component('.ui-menu-create')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#new-job');

    ok !$elem->eval('return cmp.getForm().findField("id_rule").hidden');
};

subtest 'can see job monitor with permission' => sub {
    $driver->login('can_see_job_monitor', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    ok $driver->element_visible('.ui-menu-list');
};

subtest 'cannot see jobs without permission' => sub {
    $driver->login('can_see_job_monitor', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    is $elem->eval('return cmp.store.getCount()'), 0;
};

subtest 'can see jobs filtered by project with permission' => sub {
    $driver->login('can_see_project_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    is $elem->eval('return cmp.store.getCount()'), 2;
};

subtest 'can see jobs filtered by project and bl with permission' => sub {
    $driver->login('can_see_jobs_with_bl', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    is $elem->eval('return cmp.store.getCount()'), 1;
};

subtest 'cannot see advanced job menu without permission' => sub {
    $driver->login('can_see_project_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    $driver->wait_for_extjs_component_enabled('#full-log')->elem->click;

    $driver->wait_for_extjs_component_enabled('#job-log');

    ok $driver->element_not_visible('#advanced');
};

subtest 'can see advanced job menu with permission' => sub {
    $driver->login('can_see_advanced_job_menu', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    $driver->wait_for_extjs_component_enabled('#full-log')->elem->click;

    $driver->wait_for_extjs_component_enabled('#job-log');

    ok $driver->element_visible('#advanced');
};

subtest 'cannot run job in process without permission' => sub {
    $driver->login('can_see_project_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    $driver->wait_for_extjs_component_enabled('.ui-menu-tools')->elem->click;

    ok $driver->element_not_visible('.ui-run-in-process');
};

subtest 'can run job in process with permission' => sub {
    $driver->login('can_run_job_in_process', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    $driver->wait_for_extjs_component_enabled('.ui-menu-tools')->elem->click;

    ok $driver->element_visible('.ui-run-in-process');
};

subtest 'cannot restart job without permission' => sub {
    $driver->login('can_see_project_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    ok $driver->element_not_visible('.ui-btn-restart');
};

subtest 'can restart job with permission' => sub {
    $driver->login('can_restart_job', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    ok $driver->element_visible('.ui-btn-restart');
};

subtest 'cannot delete job without permission' => sub {
    $driver->login('can_see_project_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    ok $driver->element_not_visible('.ui-btn-cancel');
};

subtest 'can delete job with permission' => sub {
    $driver->login('can_delete_job', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-list')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#job-monitor-grid');

    $elem->eval('cmp.getSelectionModel().selectFirstRow();');

    ok $driver->element_visible('.ui-btn-cancel');
};

subtest 'cannot create job outside of time slots without permission' => sub {
    $driver->login('can_create_new_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-create')->elem->click;

    $driver->wait_for_extjs_component('#new-job');

    ok !$driver->find_extjs_component('.ui-chk-no-cal')->is_enabled;
    ok !$driver->find_extjs_component('.ui-btn-create')->is_enabled;
};

subtest 'can create job outside of time slots with permission' => sub {
    $driver->login('can_create_new_jobs_outside_of_slots', 'password');

    $driver->wait_for_extjs_component('.ui-menu-job')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-create')->elem->click;

    $driver->wait_for_extjs_component('#new-job');

    my $elem = $driver->wait_for_extjs_component_enabled('.ui-chk-no-cal');

    $elem->elem->click;

    ok $driver->wait_for_extjs_component_enabled('.ui-btn-create');
};

$driver->quit;

done_testing;
