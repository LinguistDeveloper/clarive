use strict;
use warnings;

use Test::More;

use TestDriver;
use Selenium::ActionChains;

my $driver = TestDriver->new;

$driver->setup('TestPermissionsTopic');

subtest 'cannot view topics without permission' => sub {
    $driver->login('can_see_menu', 'password');

    ok $driver->element_not_visible('.ui-menu-topic');
};

subtest 'can view topics menu with permission' => sub {
    $driver->login('can_see_topics', 'password');

    ok $driver->element_visible('.ui-menu-topic');
};

subtest 'can view only allowed topics with permission' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $elem = $driver->wait_for_extjs_component('#topics-grid');

    my $elems = $elem->eval('var data = []; cmp.store.data.each(function(item) { data.push(item.data) }); return data');

    is @$elems, 2;
    my @categories = map { $_->{category_name} } @$elems;
    is $categories[0], 'Changeset';
    is $categories[1], 'Changeset';
};

subtest 'cannot create topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    $driver->wait_for_extjs_component('#topics-grid');

    ok !$driver->element_present('#topics-grid .ui-btn-create');
};

subtest 'can create topic with permissions' => sub {
    $driver->login('can_create_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    $driver->wait_for_extjs_component('#topics-grid');

    ok $driver->element_present('#topics-grid .ui-btn-create');
};

subtest 'cannot edit topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok !$driver->find_extjs_component('.ui-topic-panel .ui-btn-edit')->is_displayed;
};

subtest 'can edit topic with permissions' => sub {
    $driver->login('can_edit_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok $driver->find_extjs_component('.ui-topic-panel .ui-btn-edit')->is_displayed;
};

subtest 'cannot delete topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok !$driver->find_extjs_component('.ui-topic-panel .ui-btn-delete')->is_displayed;
};

subtest 'can delete topic with permissions' => sub {
    $driver->login('can_delete_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok $driver->find_extjs_component('.ui-topic-panel .ui-btn-delete')->is_displayed;
};

subtest 'cannot comment on topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok !$driver->find_extjs_component('.ui-topic-panel .ui-btn-comment-add')->is_displayed;
};

subtest 'can comment on topic with permissions' => sub {
    $driver->login('can_comment_on_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok $driver->find_extjs_component('.ui-topic-panel .ui-btn-comment-add')->is_displayed;
};

subtest 'cannot view comments on topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok !$driver->find_element_by_class('ui-topic-tab-discussion')->is_displayed;
};

subtest 'can view comments on topic with permissions' => sub {
    $driver->login('can_comment_on_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok $driver->find_element_by_class('ui-topic-tab-discussion')->is_displayed;
};

subtest 'cannot view acivity on topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok !$driver->find_element_by_class('ui-topic-tab-activity')->is_displayed;
};

subtest 'can view activity on topic with permissions' => sub {
    $driver->login('can_see_activity', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok $driver->find_element_by_class('ui-topic-tab-activity')->is_displayed;
};

subtest 'cannot view jobs on topic without permissions' => sub {
    $driver->login('can_see_topics', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok !$driver->find_element_by_class('ui-topic-tab-jobs')->is_displayed;
};

subtest 'can view jobs on topic with permissions' => sub {
    $driver->login('can_see_topic_jobs', 'password');

    $driver->wait_for_extjs_component('.ui-menu-topic')->elem->click;

    $driver->wait_for_extjs_component('.ui-menu-topics')->elem->click;

    my $grid = $driver->wait_for_extjs_component('#topics-grid');

    $grid->eval('cmp.getSelectionModel().selectFirstRow()');

    my $row = $driver->find_element_by_class('x-grid3-row-selected');

    my $action_chains = Selenium::ActionChains->new(driver => $driver);
    $action_chains->double_click($row);
    $action_chains->perform;

    $driver->wait_for_extjs_component('.ui-topic-panel');

    ok $driver->find_element_by_class('ui-topic-tab-jobs')->is_displayed;
};

$driver->quit;

done_testing;
